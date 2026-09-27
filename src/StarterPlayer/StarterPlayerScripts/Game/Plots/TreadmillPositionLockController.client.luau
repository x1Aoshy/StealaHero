-- StarterPlayer.StarterPlayerScripts.Game.Plots.TreadmillPositionLockController
-- Treadmill lock (CONTRACTS_PHASE3 D7; owner: "when I stand on the treadmill it must lock me in place
-- facing forward with Roblox's default run animation"). Base-place Source == the previous src mirror
-- (rule 4, verified), so this file replaces it and scripts/inject/treadmill.luau injects it (create=false).
--
-- While a treadmill session is active (Treadmills: ActiveTreadmillChanged(id), fired by
-- TreadmillGrindService when the HumanoidRootPart is over the owner's bought TreadmillBottom):
--   * the character is pinned to the belt centre X/Z (the treadmill's Root, fallback the plot's
--     TreadmillBottom: same centre and LookVector), easing in over ENTER_BLEND_SECONDS. Y is never
--     touched and vertical velocity is kept, so a jump still works: TreadmillUI's JumpRequest ->
--     Treadmills: RequestUnequip is the exit;
--   * it faces the console = Root.CFrame.LookVector (the skins are grounded with
--     TreadmillBottom's rotation and the build step asserts the console is on that side on every plot).
--     Humanoid.AutoRotate is held false (re-asserted every frame: the shift-lock GUI turns it back on);
--     horizontal and angular velocity are zeroed every frame;
--   * keyboard WASD/arrows and the gamepad left stick/D-pad are sunk at ContextActionPriority.High+1.
--     Jump and camera input are untouched (the SpeedPhone minigame takes Space / ButtonA only while its
--     game is focused, so an unfocused Space still jumps off). Controls:Disable() is NOT used (2026-08-25: it killed
--     jump-to-exit and the touch jump button). Touch thumbstick input cannot be sunk; the per-frame pin
--     and AutoRotate=false neutralise it;
--   * Roblox's DEFAULT run animation plays in place: R15 rbxassetid://913376220 (= run.RunAnim of the
--     default Animate script StealaHero ships), R6 rbxassetid://180426354. Velocity is ~0 while pinned,
--     so Animate would pick idle: the run track is played on the character's Animator at Action priority
--     (above Animate's Core tracks), Looped, speed clamp(WalkSpeed/16, 1, 2), re-played if stopped.
--     Tracks the local client plays on its own character replicate to every other client.
-- Everything is released (track stopped, AutoRotate restored, input unbound) when the session ends, when
-- the character dies / resets / is removed, and when the character is found far from the belt (teleported
-- or left the plot). The server ends a session at once on death / respawn, and after EXIT_GRACE_SECONDS
-- (1 s) off the belt otherwise; a runner back on the belt within that second gets no new
-- ActiveTreadmillChanged(id). So a released session re-binds, but only a LIVE character standing on the
-- belt again (the server's own isOnTreadmill footprint, inside LEAVE_DISTANCE): a respawned or teleported
-- character away from the belt is never pulled back onto it.
--
-- Camera: the treadmill video screen was removed (VISUAL_PASS_PLAN D4), so TreadmillCharacterPresentationController
-- (started by TreadmillUI on the same event) finds no VideoFeedScreen and leaves the camera to the player. This
-- lock runs after the camera (RenderPriority.Last+1) and before physics (PreSimulation).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Network = require(ReplicatedStorage.Library.Client.Network)
local PlotCmds = require(ReplicatedStorage.Library.Client.PlotCmds)
local RuntimeInstanceRegistry = require(ReplicatedStorage.Library.Modules.RuntimeInstanceRegistry)

local Treadmills = Constants.NETWORK_MAP.Treadmills
local LocalPlayer = Players.LocalPlayer

-- Roblox's default run animations (Roblox-owned: they load in any experience).
local DEFAULT_RUN_ANIMATION_R15 = "rbxassetid://913376220"
local DEFAULT_RUN_ANIMATION_R6 = "rbxassetid://180426354"
local RUN_FADE_SECONDS = 0.2
local MIN_RUN_PLAYBACK = 1
local MAX_RUN_PLAYBACK = 2
local ENTER_BLEND_SECONDS = 0.15 -- ease onto the belt centre instead of snapping
local LEAVE_DISTANCE = 12 -- studs from the belt centre: farther means teleported / left the plot

local MOVEMENT_BLOCK_ACTION = "TreadmillMovementBlock"
local MOVEMENT_KEYS = {
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right,
	Enum.KeyCode.Thumbstick1,
	Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight,
}

local function sinkMovementInput()
	return Enum.ContextActionResult.Sink
end

local movementBlocked = false
local function setMovementBlocked(blocked: boolean)
	if blocked == movementBlocked then
		return
	end
	movementBlocked = blocked
	if blocked then
		ContextActionService:BindActionAtPriority(
			MOVEMENT_BLOCK_ACTION,
			sinkMovementInput,
			false,
			Enum.ContextActionPriority.High.Value + 1,
			table.unpack(MOVEMENT_KEYS)
		)
	else
		ContextActionService:UnbindAction(MOVEMENT_BLOCK_ACTION)
	end
end

-- One run track per Humanoid, loaded once. A failed load is remembered (false) so it is neither retried
-- nor reported every frame.
local runTracks = setmetatable({}, { __mode = "k" }) -- Humanoid -> AnimationTrack | false

local function getRunTrack(humanoid: Humanoid): AnimationTrack?
	local cached = runTracks[humanoid]
	if cached ~= nil then
		return cached or nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil -- the engine adds it with the character; retried next frame
	end
	local animation = Instance.new("Animation")
	animation.Name = "TreadmillDefaultRun"
	animation.AnimationId = if humanoid.RigType == Enum.HumanoidRigType.R6
		then DEFAULT_RUN_ANIMATION_R6
		else DEFAULT_RUN_ANIMATION_R15
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		runTracks[humanoid] = false
		warn("[TreadmillPositionLock] Could not load the default run animation: " .. tostring(track))
		return nil
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	runTracks[humanoid] = track
	return track
end

local function runPlayback(humanoid: Humanoid): number
	return math.clamp((tonumber(humanoid.WalkSpeed) or 16) / 16, MIN_RUN_PLAYBACK, MAX_RUN_PLAYBACK)
end

-- The local player's plot TreadmillBottom: the plate TreadmillGrindService detects runners on.
local function getPlate(): BasePart?
	local slot = PlotCmds.GetMySlot()
	local plots = Workspace:FindFirstChild("Plots")
	local plot = if slot ~= nil and plots ~= nil then plots:FindFirstChild(tostring(slot)) else nil
	local bottom = plot and plot:FindFirstChild("TreadmillBottom")
	return if bottom and bottom:IsA("BasePart") then bottom else nil
end

-- Belt centre + forward (console) direction of the active treadmill.
local function resolveAnchor(treadmillId: string): (Vector3?, Vector3?)
	local model = RuntimeInstanceRegistry.Get("Treadmill", treadmillId)
	local root = model and model:FindFirstChild("Root")
	if root and root:IsA("BasePart") then
		return root.Position, root.CFrame.LookVector
	end
	local bottom = getPlate()
	if bottom then
		return bottom.Position, bottom.CFrame.LookVector
	end
	return nil, nil
end

-- True when the local character is alive and standing on the belt again: the same footprint as
-- TreadmillGrindService.isOnTreadmill (plate space: X/Z within size/2 + 1, Y within size/2 + 10), and
-- inside LEAVE_DISTANCE so the leave guard cannot release it again on the same frame.
local function isBackOnBelt(treadmillId: string): boolean
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and rootPart and rootPart:IsA("BasePart")) or humanoid.Health <= 0 then
		return false
	end
	local plate = getPlate()
	if plate == nil then
		return false
	end
	local position = rootPart.CFrame.Position
	local relative = plate.CFrame:PointToObjectSpace(position)
	local size = plate.Size
	if math.abs(relative.X) > size.X / 2 + 1 or math.abs(relative.Z) > size.Z / 2 + 1
		or math.abs(relative.Y) > size.Y / 2 + 10 then
		return false
	end
	local anchor = resolveAnchor(treadmillId)
	if anchor == nil then
		return false
	end
	local dx, dz = anchor.X - position.X, anchor.Z - position.Z
	return dx * dx + dz * dz <= LEAVE_DISTANCE * LEAVE_DISTANCE
end

type Session = {
	TreadmillId: string,
	Humanoid: Humanoid?,
	RootPart: BasePart?,
	SavedAutoRotate: boolean?,
	DiedConnection: RBXScriptConnection?,
	StartedAt: number,
	FromCFrame: CFrame?,
	Playback: number,
	Released: boolean,
}
local session: Session? = nil

-- Stops the run, restores AutoRotate and forgets the character.
local function releaseCharacter(s: Session, fade: number)
	local humanoid = s.Humanoid
	if s.DiedConnection then
		s.DiedConnection:Disconnect()
		s.DiedConnection = nil
	end
	if humanoid then
		local track = runTracks[humanoid]
		if track and track.IsPlaying then
			track:Stop(fade)
		end
		if s.SavedAutoRotate ~= nil and humanoid.Parent ~= nil then
			humanoid.AutoRotate = s.SavedAutoRotate
		end
	end
	s.Humanoid = nil
	s.RootPart = nil
	s.SavedAutoRotate = nil
	s.FromCFrame = nil
end

-- Ends the lock for this session without waiting for the server (death, reset, teleport, left the plot).
-- While the server session lasts, applyLock re-binds it once a live character is back on the belt.
local function releaseSession(s: Session, fade: number)
	s.Released = true
	releaseCharacter(s, fade)
	setMovementBlocked(false)
end

-- Binds the current character to a session that has none yet.
local function bindCharacter(s: Session): boolean
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and rootPart and rootPart:IsA("BasePart")) or humanoid.Health <= 0 then
		return false
	end
	s.Humanoid = humanoid
	s.RootPart = rootPart
	s.SavedAutoRotate = humanoid.AutoRotate
	s.StartedAt = os.clock()
	s.FromCFrame = rootPart.CFrame
	s.Playback = 0
	s.DiedConnection = humanoid.Died:Connect(function()
		if session == s and not s.Released then
			releaseSession(s, 0)
		end
	end)
	return true
end

local function applyLock()
	local s = session
	if s == nil then
		return
	end
	if s.Released then
		-- Released, but the server still runs the session: lock again only a live character that is
		-- back on the belt (never pull one back from the spawn or a teleport).
		if not isBackOnBelt(s.TreadmillId) or not bindCharacter(s) then
			return
		end
		s.Released = false
		setMovementBlocked(true)
	elseif s.Humanoid == nil and not bindCharacter(s) then
		return
	end
	local humanoid = s.Humanoid :: Humanoid
	local rootPart = s.RootPart :: BasePart
	if humanoid.Parent == nil or rootPart.Parent == nil or humanoid.Health <= 0 then
		releaseSession(s, 0)
		return
	end

	local anchor, look = resolveAnchor(s.TreadmillId)
	if anchor == nil or look == nil then
		return
	end
	local current = rootPart.CFrame
	local position = current.Position
	local dx, dz = anchor.X - position.X, anchor.Z - position.Z
	if dx * dx + dz * dz > LEAVE_DISTANCE * LEAVE_DISTANCE then
		releaseSession(s, RUN_FADE_SECONDS) -- teleported or left the plot: the server ends the session
		return
	end
	local forward = Vector3.new(look.X, 0, look.Z)
	if forward.Magnitude < 1e-3 then
		forward = Vector3.new(current.LookVector.X, 0, current.LookVector.Z)
		if forward.Magnitude < 1e-3 then
			return
		end
	end
	forward = forward.Unit

	-- Facing built with fromMatrix (right, up, back): LookVector = forward.
	local pinned = Vector3.new(anchor.X, position.Y, anchor.Z)
	local target = CFrame.fromMatrix(pinned, forward:Cross(Vector3.yAxis), Vector3.yAxis, -forward)
	local alpha = math.clamp((os.clock() - s.StartedAt) / ENTER_BLEND_SECONDS, 0, 1)
	if alpha < 1 and s.FromCFrame then
		local blended = s.FromCFrame:Lerp(target, alpha)
		rootPart.CFrame = blended.Rotation + Vector3.new(blended.Position.X, position.Y, blended.Position.Z)
	else
		rootPart.CFrame = target
	end
	local velocity = rootPart.AssemblyLinearVelocity
	rootPart.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0) -- vertical kept: jumping exits
	rootPart.AssemblyAngularVelocity = Vector3.zero

	if humanoid.AutoRotate then
		humanoid.AutoRotate = false -- re-asserted: the shift-lock GUI turns it back on when it releases
	end

	local track = getRunTrack(humanoid)
	if track then
		local playback = runPlayback(humanoid)
		if not track.IsPlaying then
			track:Play(RUN_FADE_SECONDS, 1, playback)
			s.Playback = playback
		elseif playback ~= s.Playback then
			track:AdjustSpeed(playback)
			s.Playback = playback
		end
	end
end

local function beginSession(treadmillId: string)
	local s = session
	if s and s.TreadmillId == treadmillId and not s.Released then
		return
	end
	if s then
		releaseCharacter(s, RUN_FADE_SECONDS)
	end
	session = {
		TreadmillId = treadmillId,
		Humanoid = nil,
		RootPart = nil,
		SavedAutoRotate = nil,
		DiedConnection = nil,
		StartedAt = os.clock(),
		FromCFrame = nil,
		Playback = 0,
		Released = false,
	}
	setMovementBlocked(true)
	applyLock()
end

local function endSession()
	local s = session
	session = nil
	setMovementBlocked(false)
	if s then
		releaseCharacter(s, RUN_FADE_SECONDS)
	end
end

Network.Fired(Treadmills.ACTIVE_TREADMILL_EVENT):Connect(function(treadmillId: string?)
	if treadmillId ~= nil then
		beginSession(treadmillId)
	else
		endSession()
	end
end)

LocalPlayer.CharacterRemoving:Connect(function(character)
	local s = session
	if s and not s.Released and (s.Humanoid == nil or s.Humanoid:IsDescendantOf(character)) then
		releaseSession(s, 0)
	end
end)

-- Before physics (stops the humanoid from building velocity or turning) and after the camera
-- (what is rendered is always the locked pose).
RunService.PreSimulation:Connect(applyLock)
RunService:BindToRenderStep("TreadmillPositionLock", Enum.RenderPriority.Last.Value + 1, applyLock)
