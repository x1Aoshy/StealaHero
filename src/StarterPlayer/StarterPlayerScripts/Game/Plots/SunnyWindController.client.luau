-- Animate only nearby equipped Sunny pens. One scheduler for all ships; no remote traffic.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Wind = require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules"):WaitForChild("SunnyWind"))
local rigs = {}
local clock = 0

local function restore(rig)
	local origin = rig.origin.WorldCFrame
	for part, entry in pairs(rig.parts) do
		if part.Parent then
			part.CFrame = origin * entry.rest
		end
	end
	rig.moving = false
end

local function remove(model)
	local rig = rigs[model]
	if rig == nil then return end
	if rig.origin.Parent then restore(rig) end
	for _, connection in ipairs(rig.connections) do connection:Disconnect() end
	rigs[model] = nil
end

local function track(model)
	if rigs[model] or not model:IsA("Model") or not model:IsDescendantOf(workspace) then return end
	local origin = model:FindFirstChild("SunnyOrigin", true)
	if not origin or not origin:IsA("Attachment") then return end
	local rig = { origin = origin, parts = {}, connections = {}, nextUpdate = 0, moving = false,
		phase = (origin.WorldPosition.X * 0.17 + origin.WorldPosition.Z * 0.11) % (2 * math.pi) }
	rigs[model] = rig
	local function add(part)
		if not part:IsA("BasePart") then return end
		local group, rest = part:GetAttribute("SunnyGroup"), part:GetAttribute("SunnyRest")
		if (group == "Hull" or Wind.Pivots[group] ~= nil) and typeof(rest) == "CFrame" then
			rig.parts[part] = { group = group, rest = rest }
		end
	end
	for _, part in ipairs(model:GetDescendants()) do add(part) end
	table.insert(rig.connections, model.DescendantAdded:Connect(add))
	table.insert(rig.connections, model.DescendantRemoving:Connect(function(part) rig.parts[part] = nil end))
	table.insert(rig.connections, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then remove(model) end
	end))
end

CollectionService:GetInstanceAddedSignal(Wind.Tag):Connect(track)
CollectionService:GetInstanceRemovedSignal(Wind.Tag):Connect(remove)
-- Replication may deliver the tag before the attachment. Atomic models normally arrive together;
-- this also handles delayed insertion without an unbounded wait or full Workspace polling.
workspace.DescendantAdded:Connect(function(instance)
	if instance:IsA("Attachment") and instance.Name == "SunnyOrigin" then
		local model = instance:FindFirstAncestorOfClass("Model")
		if model and CollectionService:HasTag(model, Wind.Tag) then task.defer(track, model) end
	elseif instance:IsA("Model") and CollectionService:HasTag(instance, Wind.Tag) then
		task.defer(track, instance)
	end
end)
for _, model in ipairs(CollectionService:GetTagged(Wind.Tag)) do track(model) end

RunService.Heartbeat:Connect(function(dt)
	clock += dt
	if next(rigs) == nil then return end
	local camera = workspace.CurrentCamera
	if camera == nil then return end
	local now = workspace:GetServerTimeNow()
	for model, rig in pairs(rigs) do
		if clock < rig.nextUpdate then continue end
		local origin = rig.origin.WorldCFrame
		local distance = (origin.Position - camera.CFrame.Position).Magnitude
		local interval = Wind.Interval(distance)
		if interval == nil or model:GetAttribute("SunnyWindEnabled") == false then
			if rig.moving then restore(rig) end
			rig.nextUpdate = clock + 0.25
			continue
		end
		rig.nextUpdate = clock + interval
		local configured = model:GetAttribute("SunnyWindStrength")
		local strength = if type(configured) == "number" and configured == configured then configured else 1
		local poses = Wind.Sample(now, rig.phase, strength)
		for part, entry in pairs(rig.parts) do
			if part.Parent then part.CFrame = origin * poses[entry.group] * entry.rest end
		end
		rig.moving = true
	end
end)
