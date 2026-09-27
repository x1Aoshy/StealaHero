--!nonstrict
-- StarterPlayer.StarterPlayerScripts.Game.Tools.BatCombatFx (LocalScript, injected by scripts/inject/gekko_combat.luau)
--
-- Owner 2026-09-24 (Gekko TO DO 2, "Bat Rework", Steal a Brainrot reference): the bat gets a real swing - a quick
-- wind-up, then a horizontal swing - and the hit lands only at the swing's contact moment, with proper feedback.
--
-- No animation asset is needed (the bats' HitAnim belongs to another creator and cannot load in this game): the swing
-- is procedural. For the swinging character this client overrides the Motor6D.Transform of the waist and the right
-- arm (shoulder, elbow, wrist) every frame in RunService.PreSimulation, i.e. after the Animator wrote its pose, blending
-- from that pose into the swing keyframes and back out, so walking / the tool-hold pose continue underneath. A white
-- trail follows the bat during the swing. Every client animates every swinging character:
--   * the local player's own swing starts on the click (Tool.Activated), with the same cooldown / state checks as the
--     server, so it feels instant; the server's echo of it is ignored;
--   * other players' swings come from the server: ReplicatedStorage.Network["Gear: BatFx"]
--     { Action = "Swing", Attacker, WindUp, Duration }.
-- The hit itself is decided by ServerScriptService.GearService at the contact moment (WindUp after the swing
-- started). A landed hit arrives as { Action = "Hit", Attacker, Victim, Position, Direction, Dropped }: an impact
-- burst at the victim (ReplicatedStorage.Assets.Particles.SlapVFX + Damage.Hitspark emitters, emitted once), a brief
-- white Highlight flash on the victim and the whitelisted pop sound through Library.Audio (SFX setting respected).
-- The camera shakes are sent by the server to the attacker and the victim (Game.CameraShake).
-- Hero weapons (payloads with a Weapon field, tools with a HeroWeaponId, owner 2026-09-27) are left to
-- BranchControllers.HeroWeaponController; this script keeps the classic bats.
-- This script only draws: it never sends anything to the server. Every piece it creates is local and short-lived, and
-- a missing optional piece (emitter folder, Audio module, motor) just skips that part of the effect.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REMOTE_NAME = "Gear: BatFx"
local CARRY_ATTRIBUTE = "CarryingEgg" -- AreaEggService: the player carries a stolen egg (no tools, no swings)
-- Mirrors of GearService (the server's payload values win for other players' swings).
local SWING_WINDUP = 0.18
local SWING_DURATION = 0.45
local LOCAL_COOLDOWN = 0.7 -- GearService MELEE_COOLDOWN
-- The server's echo of our own predicted swing is ignored for this long. Up to just under the local cooldown: no new
-- local swing can start inside it, so a slow connection (echo after 0.5 s) never replays the swing a second time.
local ECHO_WINDOW = LOCAL_COOLDOWN - 0.05
local HIT_SOUND = "rbxassetid://72264591133889" -- pop (audio whitelist)
local FLASH_SECONDS = 0.3
local BURST_LIFETIME = 1.5
local TRAIL_NAME = "BatSwingTrail"

-- Swing keyframes in degrees, each joint's rotation in its Part0's axes (X right, Y up, Z back):
--   Waist = yaw of the upper body (+ = to the left); Shoulder = yaw after pitch (pitch 90 = arm straight forward);
--   Elbow = bend (+ = forearm up when the arm is forward); Wrist = tilt (- = bat laid forward along the swing).
-- Times are fractions of the wind-up: READY at 0, WINDUP at 0.6, CONTACT at 1 (the server's hit moment), FOLLOW at
-- 1.5; after FOLLOW the swing blends back into the Animator's pose by the end of the swing.
local KEYFRAMES = {
	{ at = 0, waist = 0, pitch = 90, yaw = 0, elbow = 10, wrist = 0 }, -- READY (the tool-hold pose)
	{ at = 0.6, waist = -30, pitch = 110, yaw = -70, elbow = 5, wrist = -60 }, -- WINDUP: bat up and out to the right
	{ at = 1, waist = 5, pitch = 80, yaw = -5, elbow = 10, wrist = -65 }, -- CONTACT: arm and bat straight ahead
	{ at = 1.5, waist = 40, pitch = 70, yaw = 70, elbow = 25, wrist = -70 }, -- FOLLOW: through to the left
}
local BLEND_IN = 0.4 -- fraction of the wind-up to blend in from the Animator's pose

local stepSignal = RunService.Stepped
pcall(function()
	stepSignal = RunService.PreSimulation
end)

----------------------------------------------------------------------------------------------------
-- procedural swing
----------------------------------------------------------------------------------------------------

local swings = {} -- [character] = { startedAt, windUp, duration, joints = { [key] = entry }, trail }

local function motorNamed(character, name)
	local motor = character:FindFirstChild(name, true)
	if motor and motor:IsA("Motor6D") then
		return motor
	end
	return nil
end

local function jointEntry(motor)
	return { motor = motor, c0rot = motor.C0.Rotation, base = nil, written = nil }
end

local function findJoints(character)
	local joints = {}
	local waist = motorNamed(character, "Waist")
	local shoulder = motorNamed(character, "RightShoulder") or motorNamed(character, "Right Shoulder") -- R15 / R6
	local elbow = motorNamed(character, "RightElbow")
	local wrist = motorNamed(character, "RightWrist")
	if not waist and not elbow then
		-- R6: the whole torso turns on the root joint
		waist = motorNamed(character, "RootJoint")
	end
	joints.waist = waist and jointEntry(waist)
	joints.shoulder = shoulder and jointEntry(shoulder)
	joints.elbow = elbow and jointEntry(elbow)
	joints.wrist = wrist and jointEntry(wrist)
	return joints
end

-- Writes `rotation` (in the joint's Part0 axes) blended with the Animator's pose by `weight`. When the Animator did not
-- write this joint since our last frame, the pose underneath is the one we saw before (never our own output).
local function applyJoint(entry, rotation, weight)
	local motor = entry.motor
	if not motor.Parent or not motor.Enabled then
		return
	end
	local current = motor.Transform
	local base = if entry.written ~= nil and current == entry.written then (entry.base or CFrame.identity) else current
	entry.base = base
	local target = entry.c0rot:Inverse() * rotation * entry.c0rot
	local out = if weight >= 1 then target else base:Lerp(target, weight)
	motor.Transform = out
	entry.written = out
end

local function easeInOut(alpha)
	return alpha * alpha * (3 - 2 * alpha)
end

-- Keyframe values at `phase` (time / wind-up), eased per segment: slow into the wind-up, fast through contact.
local function poseAt(phase)
	local last = KEYFRAMES[#KEYFRAMES]
	if phase >= last.at then
		return last
	end
	for index = 2, #KEYFRAMES do
		local b = KEYFRAMES[index]
		if phase <= b.at then
			local a = KEYFRAMES[index - 1]
			local alpha = math.clamp((phase - a.at) / (b.at - a.at), 0, 1)
			alpha = if index == 3 then alpha * alpha else easeInOut(alpha) -- accelerate into the contact
			local pose = {}
			for key, value in pairs(b) do
				if key ~= "at" then
					pose[key] = a[key] + (value - a[key]) * alpha
				end
			end
			return pose
		end
	end
	return last
end

local function toolHandleOf(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			local handle = child:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				return handle
			end
		end
	end
	return nil
end

-- A white streak along the bat, created once per bat handle on this client and only enabled during the swing.
local function trailFor(character)
	local handle = toolHandleOf(character)
	if not handle then
		return nil
	end
	local existing = handle:FindFirstChild(TRAIL_NAME)
	if existing and existing:IsA("Trail") then
		return existing
	end
	local reach = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z) * 0.45
	local axis = if handle.Size.Y >= handle.Size.X and handle.Size.Y >= handle.Size.Z then Vector3.yAxis
		elseif handle.Size.Z >= handle.Size.X then Vector3.zAxis else Vector3.xAxis
	local tip = Instance.new("Attachment")
	tip.Name = TRAIL_NAME .. "Tip"
	tip.Position = axis * reach
	tip.Parent = handle
	local grip = Instance.new("Attachment")
	grip.Name = TRAIL_NAME .. "Grip"
	grip.Position = -axis * reach * 0.2
	grip.Parent = handle
	local trail = Instance.new("Trail")
	trail.Name = TRAIL_NAME
	trail.Attachment0 = grip
	trail.Attachment1 = tip
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.35),
	})
	trail.Lifetime = 0.16
	trail.MinLength = 0.05
	trail.LightEmission = 0.6
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = handle
	return trail
end

local function stopSwing(character)
	local swing = swings[character]
	if swing then
		swings[character] = nil
		if swing.trail and swing.trail.Parent then
			swing.trail.Enabled = false
		end
		-- hand every joint back exactly as the Animator left it (a joint no animation drives would otherwise keep
		-- the last, almost-faded swing frame)
		for _, entry in pairs(swing.joints) do
			local motor = entry.motor
			if motor.Parent and entry.written ~= nil and motor.Transform == entry.written then
				motor.Transform = entry.base or CFrame.identity
			end
		end
	end
end

local function playSwing(character, windUp, duration)
	if not character or not character.Parent or character:GetAttribute("Ragdolled") == true then
		return
	end
	local previous = swings[character]
	local joints = findJoints(character)
	if previous then
		-- a new swing continues from whatever the previous one last saw underneath
		for key, entry in pairs(joints) do
			local old = previous.joints[key]
			if old and old.motor == entry.motor then
				joints[key] = old
			end
		end
	end
	local okTrail, trail = pcall(trailFor, character)
	swings[character] = {
		startedAt = os.clock(),
		windUp = math.clamp(tonumber(windUp) or SWING_WINDUP, 0.05, 1),
		duration = math.clamp(tonumber(duration) or SWING_DURATION, 0.1, 2),
		joints = joints,
		trail = okTrail and trail or nil,
	}
end

local rad = math.rad

local function stepSwing(character, swing)
	local elapsed = os.clock() - swing.startedAt
	if elapsed >= swing.duration or not character.Parent or character:GetAttribute("Ragdolled") == true then
		stopSwing(character)
		return
	end
	local phase = elapsed / swing.windUp
	local lastAt = KEYFRAMES[#KEYFRAMES].at
	local weight
	if phase < BLEND_IN then
		weight = easeInOut(phase / BLEND_IN)
	elseif phase <= lastAt then
		weight = 1
	else
		local outStart = lastAt * swing.windUp
		weight = 1 - easeInOut(math.clamp((elapsed - outStart) / math.max(swing.duration - outStart, 0.01), 0, 1))
	end
	local pose = poseAt(phase)
	local joints = swing.joints
	if joints.waist then
		applyJoint(joints.waist, CFrame.Angles(0, rad(pose.waist), 0), weight)
	end
	if joints.shoulder then
		applyJoint(joints.shoulder, CFrame.Angles(0, rad(pose.yaw), 0) * CFrame.Angles(rad(pose.pitch), 0, 0), weight)
	end
	if joints.elbow then
		applyJoint(joints.elbow, CFrame.Angles(rad(pose.elbow), 0, 0), weight)
	end
	if joints.wrist then
		applyJoint(joints.wrist, CFrame.Angles(rad(pose.wrist), 0, 0), weight)
	end
	local trail = swing.trail
	if trail and trail.Parent then
		local on = phase >= 0.55 and phase <= 1.6
		if trail.Enabled ~= on then
			trail.Enabled = on
		end
	end
end

stepSignal:Connect(function()
	for character, swing in pairs(swings) do
		local ok, err = pcall(stepSwing, character, swing)
		if not ok then
			swings[character] = nil
			warn("[BatCombatFx] swing step failed: " .. tostring(err))
		end
	end
end)

----------------------------------------------------------------------------------------------------
-- hit feedback
----------------------------------------------------------------------------------------------------

local burstTemplates = nil -- array of ParticleEmitter templates, resolved once
local function getBurstTemplates()
	if burstTemplates then
		return burstTemplates
	end
	burstTemplates = {}
	local particles = ReplicatedStorage:FindFirstChild("Assets")
	particles = particles and particles:FindFirstChild("Particles")
	for _, folderName in ipairs({ "SlapVFX", "Damage" }) do
		local folder = particles and particles:FindFirstChild(folderName)
		for _, emitter in ipairs(folder and folder:GetChildren() or {}) do
			-- Damage holds a dark explosion too; only its hit spark fits a bonk
			if emitter:IsA("ParticleEmitter") and (folderName == "SlapVFX" or emitter.Name == "Hitspark") then
				table.insert(burstTemplates, emitter)
			end
		end
	end
	return burstTemplates
end

local function torsoOf(character)
	if not character then
		return nil
	end
	local part = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
	return if part and part:IsA("BasePart") then part else nil
end

-- The burst stays where the bat connected while the body flies off: a Terrain attachment at that point.
local function playBurst(position)
	local attachment = Instance.new("Attachment")
	attachment.Name = "BatHitBurst"
	attachment.Position = position -- Terrain attachments live in world space
	attachment.Parent = Workspace.Terrain
	for _, template in ipairs(getBurstTemplates()) do
		local emitter = template:Clone()
		emitter.Enabled = false
		emitter.LockedToPart = false
		emitter.Parent = attachment
		local count = tonumber(template:GetAttribute("EmitCount")) or 1
		pcall(emitter.Emit, emitter, math.clamp(math.floor(count), 1, 60))
	end
	task.delay(BURST_LIFETIME, function()
		attachment:Destroy()
	end)
end

local function playFlash(character)
	if not character or not character.Parent then
		return
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "BatHitFlash"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.1
	highlight.OutlineTransparency = 0
	highlight.Parent = character
	local tween = TweenService:Create(highlight, TweenInfo.new(FLASH_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	})
	tween.Completed:Connect(function()
		highlight:Destroy()
	end)
	tween:Play()
end

local Audio = nil
local audioLoaded = false
local function playHitSound(position)
	if not audioLoaded then
		audioLoaded = true
		local library = ReplicatedStorage:FindFirstChild("Library")
		local module = library and library:FindFirstChild("Audio")
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			Audio = if ok and type(result) == "table" then result else nil
		end
	end
	if Audio and type(Audio.Play) == "function" then
		pcall(Audio.Play, HIT_SOUND, position, { 0.8, 0.95 }, 1.2, 90)
	end
end

local function playHit(payload)
	local victim = payload.Victim
	local victimCharacter = if typeof(victim) == "Instance" and victim:IsA("Player") then victim.Character else nil
	local torso = torsoOf(victimCharacter)
	-- where this client sees the victim right now (the server's position is a little older)
	local position = if torso then torso.Position elseif typeof(payload.Position) == "Vector3" then payload.Position else nil
	if not position then
		return
	end
	local okBurst, errBurst = pcall(playBurst, position)
	if not okBurst then
		warn("[BatCombatFx] hit burst failed: " .. tostring(errBurst))
	end
	pcall(playFlash, victimCharacter)
	playHitSound(position)
end

----------------------------------------------------------------------------------------------------
-- the local player's own swings (instant) and the server's broadcasts
----------------------------------------------------------------------------------------------------

local lastLocalSwingAt = -math.huge

-- Library.Client.ToolGameplayGuard (the base game's safe-zone check), required on the first click.
local toolGameplayGuard = nil
local guardLoaded = false
local function getToolGameplayGuard()
	if not guardLoaded then
		guardLoaded = true
		local library = ReplicatedStorage:FindFirstChild("Library")
		local client = library and library:FindFirstChild("Client")
		local module = client and client:FindFirstChild("ToolGameplayGuard")
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			toolGameplayGuard = if ok and type(result) == "table" then result else nil
		end
	end
	return toolGameplayGuard
end

-- Hero weapons (HeroWeaponId attribute, owner 2026-09-27) are animated by BranchControllers.HeroWeaponController.
local function isBatTool(tool)
	return tool:IsA("Tool") and string.sub(tool.Name, -3) == "Bat" and tool:GetAttribute("HeroWeaponId") == nil
end

-- Same gates as GearService.onMeleeActivated, so a predicted swing is one the server accepts.
local function onLocalActivated(tool)
	local character = LocalPlayer.Character
	if not character or tool.Parent ~= character or os.clock() - lastLocalSwingAt < LOCAL_COOLDOWN then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or character:GetAttribute("Ragdolled") == true
		or character:GetAttribute("IsTrapped") == true or LocalPlayer:GetAttribute(CARRY_ATTRIBUTE) == true then
		return
	end
	local guard = getToolGameplayGuard()
	if guard and type(guard.IsLocalPlayerInGameplayArea) == "function" then
		local ok, inArea = pcall(guard.IsLocalPlayerInGameplayArea)
		if ok and inArea ~= true then
			return -- the Bat's own controller shows "Cannot use items in the safe zone!"
		end
	end
	lastLocalSwingAt = os.clock()
	playSwing(character, SWING_WINDUP, SWING_DURATION)
end

local hookedTools = setmetatable({}, { __mode = "k" })
local function hookTool(tool)
	if hookedTools[tool] or not isBatTool(tool) then
		return
	end
	hookedTools[tool] = true
	tool.Activated:Connect(function()
		onLocalActivated(tool)
	end)
end

local function watchContainer(container)
	if not container then
		return
	end
	for _, child in ipairs(container:GetChildren()) do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

local function onCharacterAdded(character)
	watchContainer(character)
	watchContainer(LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:WaitForChild("Backpack", 10))
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
	task.spawn(onCharacterAdded, LocalPlayer.Character)
end
task.spawn(getToolGameplayGuard) -- warm it up before the first click

local function onBatFx(payload)
	if type(payload) ~= "table" or payload.Weapon ~= nil then
		return -- a hero weapon's broadcast (BranchControllers.HeroWeaponController)
	end
	if payload.Action == "Swing" then
		local attacker = payload.Attacker
		if typeof(attacker) ~= "Instance" or not attacker:IsA("Player") then
			return
		end
		if attacker == LocalPlayer and os.clock() - lastLocalSwingAt < ECHO_WINDOW then
			return -- already playing our own predicted swing
		end
		if attacker == LocalPlayer then
			lastLocalSwingAt = os.clock()
		end
		playSwing(attacker.Character, payload.WindUp, payload.Duration)
	elseif payload.Action == "Hit" then
		playHit(payload)
	end
end

Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		stopSwing(player.Character)
	end
end)

task.spawn(function()
	local network = ReplicatedStorage:WaitForChild("Network", 30)
	local remote = network and network:WaitForChild(REMOTE_NAME, 30)
	if not (remote and remote:IsA("RemoteEvent")) then
		warn("[BatCombatFx] ReplicatedStorage.Network[\"" .. REMOTE_NAME .. "\"] missing - other players' bat swings will not animate.")
		return
	end
	remote.OnClientEvent:Connect(function(payload)
		local ok, err = pcall(onBatFx, payload)
		if not ok then
			warn("[BatCombatFx] " .. tostring(err))
		end
	end)
end)
