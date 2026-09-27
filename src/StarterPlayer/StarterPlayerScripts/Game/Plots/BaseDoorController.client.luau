-- StarterPlayerScripts.Game.Plots.BaseDoorController (LocalScript, injected by scripts/inject/basedoors.luau)
-- Automatic base doors (owner 2026-09-26: "make sure the doors open ... for all the bases ... when you go up").
-- Every plot with the build's gate data (scripts/steps/post_zzz_base_doors.luau: GateOrigin / GateOutward /
-- GateRight + DoorGeometry_<Key>) gets the door of its current look (the plot's BaseTheme attribute, "" = the plain
-- pen), built here on the client by ReplicatedStorage.Library.Modules.BaseDoors in Workspace.ClientBaseDoors and
-- rebuilt when the owner equips another theme. The StarterPen's own gate leaves are hidden locally
-- (LocalTransparencyModifier) because the new door takes their place.
--   * ~10 Hz (BaseDoors.CHECK_INTERVAL): every door within FAR_DISTANCE (150) studs of the camera checks whether ANY
--     player's character is within TRIGGER_RADIUS (10) studs of its centre (so every client shows the same thing); a
--     door opens at once and closes CLOSE_DELAY (2.5) s after the last one left (BaseDoors.Update).
--   * Motion: one Heartbeat connection, alive only while a door moves; the eased CFrame / size pose of every moving
--     door each frame (BaseDoors.Advance + Ease + door:Pose). A door that drifts out of range snaps to its end pose.
--   * Sound: a quiet whitelisted Library.Audio cue at the door (rolls off within BaseDoors.SOUND_RANGE studs).
-- Client-only visuals: nothing is sent to the server; every part is Anchored with CanCollide / CanQuery / CanTouch off.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BaseDoors = require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules"):WaitForChild("BaseDoors"))

local FOLDER_NAME = "ClientBaseDoors"
local GATE_LEAVES = { "GateLeft", "GateRight" }

local Audio = nil
task.spawn(function()
	-- Library.Audio waits for a few folders on require: never let that hold the doors back
	local ok, module = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Audio"))
	end)
	if ok and type(module) == "table" then
		Audio = module
	end
end)

local folder = Workspace:FindFirstChild(FOLDER_NAME)
if folder == nil then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace
end

local records = {} -- [plot] = { plot, key, door, state, connections }
local animating = {} -- [record] = true
local heartbeat = nil

local function hideStarterGate(plot)
	local toUpdate = plot:FindFirstChild("ToUpdate")
	local pen = toUpdate and toUpdate:FindFirstChild("StarterPen")
	local gate = pen and pen:FindFirstChild("Gate")
	for _, name in ipairs(GATE_LEAVES) do
		local leaf = gate and gate:FindFirstChild(name)
		for _, d in ipairs(leaf and leaf:GetDescendants() or {}) do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 1
			end
		end
	end
end

local function poseRecord(record)
	local door = record.door
	if door then
		door:Pose(BaseDoors.Ease(door.style.Ease, record.state.alpha))
	end
end

local function step(dt)
	for record in pairs(animating) do
		local door = record.door
		if door == nil or record.plot.Parent == nil then
			animating[record] = nil
			continue
		end
		local moving = BaseDoors.Advance(record.state, dt, door.style)
		poseRecord(record)
		if not moving then
			animating[record] = nil
		end
	end
	if next(animating) == nil and heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

local function startAnimating(record)
	animating[record] = true
	if heartbeat == nil then
		heartbeat = RunService.Heartbeat:Connect(step)
	end
end

-- Snaps a door to the end of its current move (it left the camera's range mid-move).
local function settle(record)
	record.state.alpha = if record.state.open then 1 else 0
	animating[record] = nil
	poseRecord(record)
end

local function playCue(record, event)
	local door = record.door
	local cues = door and door.style.Sound
	local cue = cues and cues[if event == "open" then "Open" else "Close"]
	if Audio == nil or cue == nil or type(Audio.SPEEDSTERS_AUDIO) ~= "table" then
		return
	end
	local id = Audio.SPEEDSTERS_AUDIO[cue.Id]
	if id then
		pcall(Audio.Play, id, CFrame.new(door.centre), cue.Speed, cue.Volume, BaseDoors.SOUND_RANGE)
	end
end

local function rebuild(record)
	local plot = record.plot
	local key = BaseDoors.StyleKey(plot:GetAttribute("BaseTheme"))
	if record.door and record.key == key then
		return
	end
	if record.door then
		record.door:Destroy()
		record.door = nil
	end
	local frame = BaseDoors.GateFrame(plot)
	if frame == nil then
		return
	end
	local ok, door = pcall(BaseDoors.Build, key, BaseDoors.ReadGeometry(plot, key), frame, folder)
	if not ok then
		warn(string.format("[BaseDoors] door %s for plot %s failed: %s", key, plot.Name, tostring(door)))
		return
	end
	door.model.Name = "BaseDoor_" .. plot.Name
	record.door, record.key = door, key
	poseRecord(record)
	hideStarterGate(plot)
end

local untrack

local function track(plot)
	if records[plot] or not plot:IsA("Model") then
		return
	end
	if typeof(plot:GetAttribute(BaseDoors.ATTR.Origin)) ~= "Vector3" then
		return
	end
	local record = { plot = plot, state = BaseDoors.NewState(), connections = {} }
	records[plot] = record
	table.insert(record.connections, plot:GetAttributeChangedSignal("BaseTheme"):Connect(function()
		rebuild(record)
	end))
	table.insert(record.connections, plot.AncestryChanged:Connect(function()
		if not plot:IsDescendantOf(Workspace) then
			untrack(plot)
		end
	end))
	rebuild(record)
end

function untrack(plot)
	local record = records[plot]
	if record == nil then
		return
	end
	records[plot] = nil
	animating[record] = nil
	for _, connection in ipairs(record.connections) do
		connection:Disconnect()
	end
	if record.door then
		record.door:Destroy()
		record.door = nil
	end
end

-- Character root positions of every player (the trigger does not care whose base it is).
local function characterRoots()
	local roots = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
		if root and root:IsA("BasePart") then
			table.insert(roots, root.Position)
		end
	end
	return roots
end

local function checkDoors()
	local camera = Workspace.CurrentCamera
	if camera == nil or next(records) == nil then
		return
	end
	local eye = camera.CFrame.Position
	local roots = characterRoots()
	local now = os.clock()
	for _, record in pairs(records) do
		local door = record.door
		if door == nil then
			continue
		end
		if (door.centre - eye).Magnitude > BaseDoors.FAR_DISTANCE then
			if animating[record] then
				settle(record)
			end
			continue
		end
		local event = BaseDoors.Update(record.state, now, BaseDoors.AnyWithin(door.centre, roots, BaseDoors.TRIGGER_RADIUS))
		if event then
			playCue(record, event)
			startAnimating(record)
		elseif record.state.alpha ~= (if record.state.open then 1 else 0) and not animating[record] then
			startAnimating(record) -- came back into range mid-move
		end
	end
end

local plots = Workspace:WaitForChild("Plots")
plots.ChildAdded:Connect(function(plot)
	task.defer(track, plot)
end)
plots.ChildRemoved:Connect(untrack)
for _, plot in ipairs(plots:GetChildren()) do
	track(plot)
end

task.spawn(function()
	while true do
		task.wait(BaseDoors.CHECK_INTERVAL)
		local ok, err = pcall(checkDoors)
		if not ok then
			warn("[BaseDoors] check failed: " .. tostring(err))
		end
	end
end)
