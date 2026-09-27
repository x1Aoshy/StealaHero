--!nonstrict
-- StarterPlayer.StarterPlayerScripts.Game.Tools.GearRagdollController (LocalScript, injected by
-- scripts/inject/gear.luau)
--
-- D2: a Bat hit ragdolls its victim (1.75 s, 3 s for an egg carrier; a villain catch uses the same path).
-- ServerScriptService.GearService validates the hit, swaps the victim's limb Motor6Ds for limited
-- BallSocketConstraints server-side (so every player sees the limp body), sets PlatformStand, and sends ONLY the
-- victim ReplicatedStorage.Network["Gear: Ragdoll"]:
--   { Action = "Start", Token, Duration, Velocity }  then  { Action = "End", Token }
-- This script runs on the victim's client, which owns its character's physics:
--   * Physics state (+ PlatformStand) so the Humanoid stops balancing, all animation tracks stopped;
--   * any limb joint the server has not swapped yet (latency, a server that only sent the event) is swapped
--     locally with the same joint frames and limits, and restored locally afterwards;
--   * limbs collide with the world (adjacent limbs never collide with each other), the root part does not;
--   * the knockback (Gekko TO DO 2, "smoother and more natural"): the server-computed velocity along the swing is
--     given to EVERY limb, not just the root, so the body travels as one instead of being dragged by the torso,
--     with a tumble that tips the head the way the body flies (plus a little random roll);
--   * recovery on "End" (or a local fallback timer if it never arrives): joints/collisions restored, then the body
--     is eased upright where it lies (feet on the floor, facing the way it lay) before GettingUp, instead of popping
--     up from the ground.
-- It only ever acts on the local player's own character, and it never sends anything to the server, so a client
-- cannot ragdoll anyone else. Death mid-ragdoll: local extras are cleaned, the body is not stood back up. A respawn
-- starts clean (everything created here lives in the old character).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REMOTE_NAME = "Gear: Ragdoll"
local SERVER_TAG = "GearRagdoll" -- attribute the server puts on its constraints/attachments (value = motor name)
local LOCAL_TAG = "GearRagdollLocal"
local END_FALLBACK_PADDING = 1.0 -- stand up on our own if the server's "End" is this late
local MAX_DURATION = 5 -- never trust a payload to keep us down longer than this
local TUMBLE_SPEED = 5 -- rad/s: the head tips the way the body flies
local TUMBLE_JITTER = 1.5 -- rad/s of random roll on top
local GET_UP_SECONDS = 0.22 -- ease from lying to standing

-- Same joint families, frames and limits as GearService (name match, axis, cone, twist lower, twist upper).
local JOINT_SPECS = {
	{ "Shoulder", "down", 95, -60, 60 },
	{ "Hip", "down", 55, -25, 25 },
	{ "Elbow", "hinge", 8, -5, 125 },
	{ "Knee", "hinge", 8, -120, 5 },
	{ "Wrist", "hinge", 20, -35, 35 },
	{ "Ankle", "hinge", 15, -30, 25 },
	{ "Waist", "up", 20, -25, 25 },
}
local DEFAULT_JOINT_SPEC = { "", "down", 30, -30, 30 }
local JOINT_AXIS_FRAMES = {
	down = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(0, 0, -1)),
	up = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 1, 0), Vector3.new(0, 0, -1)),
	hinge = CFrame.identity,
}

local active = nil -- { token, character, humanoid, root, motors, created, collisions, localSerial }
local serial = 0
local endRagdoll -- forward declaration (startRagdoll schedules it)

local function jointSpecFor(motorName)
	for _, spec in ipairs(JOINT_SPECS) do
		if string.find(motorName, spec[1], 1, true) then
			return spec
		end
	end
	return DEFAULT_JOINT_SPEC
end

-- The server's ragdoll pieces for this motor, if they already replicated: (socket?, noCollision?)
local function serverPiecesFor(motor)
	local parent = motor.Parent
	local socket, noCollide = nil, nil
	if parent then
		for _, child in ipairs(parent:GetChildren()) do
			if child:GetAttribute(SERVER_TAG) == motor.Name then
				if child:IsA("BallSocketConstraint") then
					socket = child
				elseif child:IsA("NoCollisionConstraint") then
					noCollide = child
				end
			end
		end
	end
	return socket, noCollide
end

local function isLimbMotor(motor, character, root)
	if not motor:IsA("Motor6D") then
		return false
	end
	local part0, part1 = motor.Part0, motor.Part1
	if not (part0 and part1) or part0 == root or part1 == root then
		return false
	end
	if motor.Name == "Root" or motor.Name == "RootJoint" or motor.Name == "Neck" then
		return false -- the root joint keeps the body on the root part; a loose Neck kills (Humanoid.RequiresNeck)
	end
	if motor:FindFirstAncestorOfClass("Tool") or part1:FindFirstAncestorOfClass("Tool") then
		return false
	end
	return part0:IsDescendantOf(character) and part1:IsDescendantOf(character)
end

local function track(state, instance)
	instance:SetAttribute(LOCAL_TAG, true)
	table.insert(state.created, instance)
	return instance
end

local function bodyParts(character)
	local parts = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored and not part:FindFirstAncestorOfClass("Tool") then
			table.insert(parts, part)
		end
	end
	return parts
end

local function startRagdoll(payload)
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) or humanoid.Health <= 0 then
		return
	end
	if active then
		endRagdoll(active, true) -- a newer ragdoll supersedes whatever is left of the previous one
	end

	serial += 1
	local state = {
		token = payload.Token,
		character = character,
		humanoid = humanoid,
		root = root,
		motors = {},
		created = {},
		collisions = {},
		localSerial = serial,
	}
	active = state

	humanoid.PlatformStand = true
	pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.Physics)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, playing in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(playing.Stop, playing, 0.1)
		end
	end

	-- joints: take the server's sockets, swap any limb motor it has not swapped yet
	for _, motor in ipairs(character:GetDescendants()) do
		if isLimbMotor(motor, character, root) then
			local serverSocket, serverNoCollide = serverPiecesFor(motor)
			if motor.Enabled and not serverSocket then
				local spec = jointSpecFor(motor.Name)
				local axisFrame = JOINT_AXIS_FRAMES[spec[2]] or CFrame.identity
				local attachment0 = track(state, Instance.new("Attachment"))
				attachment0.Name = "GearRagdollLocal0_" .. motor.Name
				attachment0.CFrame = motor.C0 * axisFrame
				attachment0.Parent = motor.Part0
				local attachment1 = track(state, Instance.new("Attachment"))
				attachment1.Name = "GearRagdollLocal1_" .. motor.Name
				attachment1.CFrame = motor.C1 * axisFrame
				attachment1.Parent = motor.Part1
				local socket = track(state, Instance.new("BallSocketConstraint"))
				socket.Name = "GearRagdollLocal_" .. motor.Name
				socket.Attachment0 = attachment0
				socket.Attachment1 = attachment1
				socket.LimitsEnabled = true
				socket.UpperAngle = spec[3]
				socket.TwistLimitsEnabled = true
				socket.TwistLowerAngle = spec[4]
				socket.TwistUpperAngle = spec[5]
				socket.Restitution = 0
				socket.MaxFrictionTorque = 15
				socket.Parent = motor.Parent
				motor.Enabled = false
				table.insert(state.motors, motor)
			end
			if not serverNoCollide then
				-- neighbouring limbs overlap at the joint: never let them push each other apart
				local noCollide = track(state, Instance.new("NoCollisionConstraint"))
				noCollide.Name = "GearRagdollNoCollide_" .. motor.Name
				noCollide.Part0 = motor.Part0
				noCollide.Part1 = motor.Part1
				noCollide.Parent = motor.Parent
			end
		end
	end

	-- collisions: the body lands on the floor, the invisible root box does not prop it up
	local parts = bodyParts(character)
	for _, part in ipairs(parts) do
		if not part:FindFirstAncestorOfClass("Accessory") then
			local wanted = part ~= root
			if part.CanCollide ~= wanted then
				state.collisions[part] = part.CanCollide
				part.CanCollide = wanted
			end
		end
	end

	-- the knockback (this client owns every limb, so the motion replicates): the whole body gets the same velocity,
	-- and a tumble that tips the head along the flight
	local velocity = payload.Velocity
	if typeof(velocity) == "Vector3" and velocity.Magnitude < 400 then
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		local random = Random.new()
		local spin = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-0.5, 0.5), random:NextNumber(-1, 1)) * TUMBLE_JITTER
		if flat.Magnitude > 0.01 then
			spin += Vector3.yAxis:Cross(flat.Unit) * TUMBLE_SPEED
		end
		for _, part in ipairs(parts) do
			part.AssemblyLinearVelocity = velocity
			part.AssemblyAngularVelocity = spin
		end
	end

	-- fallback recovery if the server's "End" never comes
	local duration = math.clamp(tonumber(payload.Duration) or 1.75, 0.2, MAX_DURATION)
	local mySerial = state.localSerial
	task.delay(duration + END_FALLBACK_PADDING, function()
		if active and active.localSerial == mySerial then
			endRagdoll(active)
		end
	end)
end

-- Upright CFrame for a body lying at `root`: on the floor under it (HipHeight above), facing the way it lay.
local function uprightCFrame(state)
	local root, humanoid = state.root, state.humanoid
	local heading = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if heading.Magnitude < 0.3 then
		-- lying on the back / front: the head points the way the body "faces" once up
		heading = Vector3.new(root.CFrame.UpVector.X, 0, root.CFrame.UpVector.Z)
	end
	heading = if heading.Magnitude > 0.01 then heading.Unit else Vector3.new(0, 0, -1)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { state.character }
	params.RespectCanCollide = true
	local origin = root.Position + Vector3.new(0, 3, 0)
	local hit = Workspace:Raycast(origin, Vector3.new(0, -12, 0), params)
	local standHeight = humanoid.HipHeight + root.Size.Y / 2
	local y = if hit then hit.Position.Y + standHeight else root.Position.Y + 1
	return CFrame.new(root.Position.X, y, root.Position.Z) * CFrame.Angles(0, math.atan2(-heading.X, -heading.Z), 0)
end

-- Restores joints / collisions; `quiet` skips standing up (superseded by a newer ragdoll).
function endRagdoll(state, quiet)
	if active ~= state then
		return
	end
	active = nil

	for _, motor in ipairs(state.motors) do
		if motor.Parent then
			motor.Enabled = true
		end
	end
	for _, instance in ipairs(state.created) do
		if instance.Parent then
			instance:Destroy()
		end
	end
	for part, canCollide in pairs(state.collisions) do
		if part.Parent then
			part.CanCollide = canCollide
		end
	end

	local humanoid, root, character = state.humanoid, state.root, state.character
	if quiet or not (humanoid.Parent and humanoid.Health > 0 and character == LocalPlayer.Character and root.Parent) then
		return
	end

	-- Ease upright where the body lies, then hand control back to the Humanoid.
	local ok, target = pcall(uprightCFrame, state)
	local from = root.CFrame
	local lastSet = from
	local startedAt = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local alpha = math.clamp((os.clock() - startedAt) / GET_UP_SECONDS, 0, 1)
		-- something else moved the body meanwhile (a teleport, e.g. the night reset sending players home): leave it
		local moved = root.Parent ~= nil and (root.Position - lastSet.Position).Magnitude > 6
		local finished = alpha >= 1 or not ok or moved or active ~= nil or not root.Parent or humanoid.Health <= 0
		if ok and not moved and active == nil and root.Parent then
			lastSet = from:Lerp(target, 1 - (1 - alpha) * (1 - alpha))
			root.CFrame = lastSet
			for _, part in ipairs(bodyParts(character)) do
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
		if finished then
			connection:Disconnect()
			if active == nil and humanoid.Parent and humanoid.Health > 0 then
				humanoid.PlatformStand = false
				pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.GettingUp)
			end
		end
	end)
end

local function onRagdollEvent(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.Action == "Start" then
		local ok, err = pcall(startRagdoll, payload)
		if not ok then
			warn("[GearRagdollController] ragdoll failed: " .. tostring(err))
			if active then
				endRagdoll(active)
			end
		end
	elseif payload.Action == "End" then
		if active and (payload.Token == nil or payload.Token == active.token) then
			local ok, err = pcall(endRagdoll, active)
			if not ok then
				warn("[GearRagdollController] get-up failed: " .. tostring(err))
			end
		end
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	-- the previous character (and everything created on it) is gone
	active = nil
end)

task.spawn(function()
	local network = ReplicatedStorage:WaitForChild("Network", 30)
	local remote = network and network:WaitForChild(REMOTE_NAME, 30)
	if not (remote and remote:IsA("RemoteEvent")) then
		warn("[GearRagdollController] ReplicatedStorage.Network[\"" .. REMOTE_NAME .. "\"] missing - bat hits will not ragdoll locally.")
		return
	end
	remote.OnClientEvent:Connect(onRagdollEvent)
end)
