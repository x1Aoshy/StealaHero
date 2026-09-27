-- Execute the real LocalScript with service/signal doubles; no Roblox Studio claim.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local Wind = luau.load(fs.readFile("src/ReplicatedStorage/Library/Modules/SunnyWind.luau"),
	{environment = {CFrame = CFrame}})()
local function signal()
	local listeners = {}
	return {Connect = function(_, callback)
		local c = {active = true, callback = callback}
		function c:Disconnect() self.active = false end
		table.insert(listeners, c)
		return c
	end, Fire = function(_, ...)
		for _, c in ipairs(listeners) do if c.active then c.callback(...) end end
	end}
end
local now = 0
local ws = {CurrentCamera = {CFrame = CFrame.new(0, 0, 20)}, DescendantAdded = signal()}
function ws:GetServerTimeNow() return now end
local model = {Parent = ws, DescendantAdded = signal(), DescendantRemoving = signal(), AncestryChanged = signal(),
	attributes = {SunnyWindEnabled = true, SunnyWindStrength = 1}}
function model:IsA(class) return class == "Model" end
function model:IsDescendantOf(parent) return self.Parent == parent end
function model:GetAttribute(key) return self.attributes[key] end
local origin = {Name = "SunnyOrigin", Parent = {}, WorldCFrame = CFrame.new(), WorldPosition = Vector3.new()}
function origin:IsA(class) return class == "Attachment" end
function model:FindFirstChild(name) return if name == "SunnyOrigin" then origin else nil end
local parts = {}
for i, group in ipairs({"Hull", "Main", "Aft", "Flag"}) do
	local part = {Parent = model, CFrame = CFrame.new(i, 3, 0),
		attributes = {SunnyGroup = group, SunnyRest = CFrame.new(i, 3, 0)}}
	function part:IsA(class) return class == "BasePart" end
	function part:GetAttribute(key) return self.attributes[key] end
	table.insert(parts, part)
end
function model:GetDescendants() return parts end
local collection = {added = signal(), removed = signal()}
function collection:GetInstanceAddedSignal() return self.added end
function collection:GetInstanceRemovedSignal() return self.removed end
function collection:GetTagged() return {model} end
function collection:HasTag(node) return node == model end
local rs = {}
function rs:WaitForChild() return self end
local run = {Heartbeat = signal()}
local services = {CollectionService = collection, ReplicatedStorage = rs, RunService = run}
local game = {GetService = function(_, key) return services[key] end}
luau.load(fs.readFile("src/StarterPlayer/StarterPlayerScripts/Game/Plots/SunnyWindController.client.luau"), {
	environment = {game = game, workspace = ws, require = function() return Wind end,
		task = {defer = function(f, ...) f(...) end}},
})()
local function tick(dt) now += dt; run.Heartbeat:Fire(dt) end
local function near(a, b)
	local delta = a:ToObjectSpace(b)
	local _, angle = delta:ToAxisAngle()
	return delta.Position.Magnitude < 1e-4 and math.abs(angle) < 1e-4
end
tick(0.5)
for _, part in ipairs(parts) do
	assert(near(part.CFrame, Wind.Sample(now, 0, 1)[part.attributes.SunnyGroup] * part.attributes.SunnyRest), "motion mismatch")
end
local pose = parts[2].CFrame
tick(0.005)
assert(near(parts[2].CFrame, pose), "30 Hz throttle ignored")
ws.CurrentCamera.CFrame = CFrame.new(0, 0, 181)
tick(0.1)
for _, part in ipairs(parts) do assert(near(part.CFrame, part.attributes.SunnyRest), "far rig not restored") end
ws.CurrentCamera.CFrame = CFrame.new(0, 0, 20)
tick(0.3)
assert(not near(parts[2].CFrame, parts[2].attributes.SunnyRest), "near rig did not resume")
model.attributes.SunnyWindEnabled = false
tick(0.1)
assert(near(parts[2].CFrame, parts[2].attributes.SunnyRest), "disabled rig not restored")
model.attributes.SunnyWindEnabled = true
tick(0.3)
model.Parent = nil
model.AncestryChanged:Fire()
assert(near(parts[2].CFrame, parts[2].attributes.SunnyRest), "unequip did not restore")
tick(1)
assert(near(parts[2].CFrame, parts[2].attributes.SunnyRest), "removed rig is still animated")
model.Parent = ws
collection.added:Fire(model)
tick(0.5)
assert(not near(parts[2].CFrame, parts[2].attributes.SunnyRest), "re-equip did not resume")
print("Sunny LocalScript OK: motion, rate cap, distance pause/resume, disable, unequip cleanup, re-equip")
