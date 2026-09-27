--!nocheck
-- scripts/tools/diff_places.luau
-- Diffs two places instance by instance (path = names from the DataModel, "#k" for the k-th sibling of the same name
-- and class): added / removed instances and changed key properties (transforms, sizes, colors, GUI layout, script
-- Source). Used to port the owner's Studio edits of a compiled StealaHero.rbxl back into the build.
--   lune run scripts/tools/diff_places.luau <before.rbxl> <after.rbxl> [--services=Workspace,StarterGui] [--max=400]
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local args = process.args
local before = roblox.deserializePlace(fs.readFile(args[1]))
local after = roblox.deserializePlace(fs.readFile(args[2]))
local serviceFilter, maxLines = nil, 400
for i = 3, #args do
	local s = string.match(args[i], "^%-%-services=(.+)$")
	if s then
		serviceFilter = {}
		for _, name in string.split(s, ",") do
			serviceFilter[name] = true
		end
	end
	local m = string.match(args[i], "^%-%-max=(%d+)$")
	if m then
		maxLines = tonumber(m)
	end
end

local PROPS = {
	"CFrame", "Size", "Color", "Transparency", "Material", "Anchored", "CanCollide", "Shape",
	"Position", "AnchorPoint", "Visible", "ZIndex", "Text", "TextSize", "BackgroundTransparency", "BackgroundColor3",
	"ImageTransparency", "Image", "Enabled", "WorldPivotData", "MeshId", "TextureID", "Source", "Rate", "Texture",
	"Brightness", "Range", "ClockTime", "Scale", "Offset",
}

local function get(inst, prop)
	local ok, v = pcall(function()
		return inst[prop]
	end)
	return if ok then v else nil
end

local function index(root)
	local map, order = {}, {}
	local function walk(inst, path)
		local seen = {}
		for _, child in inst:GetChildren() do
			local key = child.Name .. "<" .. child.ClassName .. ">"
			seen[key] = (seen[key] or 0) + 1
			local p = path .. "/" .. child.Name .. (if seen[key] > 1 then "#" .. seen[key] else "")
			map[p] = child
			table.insert(order, p)
			walk(child, p)
		end
	end
	for _, service in root:GetChildren() do
		if serviceFilter == nil or serviceFilter[service.Name] then
			map[service.Name] = service
			table.insert(order, service.Name)
			walk(service, service.Name)
		end
	end
	return map, order
end

local function fmt(v)
	local t = typeof(v)
	if t == "CFrame" then
		local x, y, z = v.Position.X, v.Position.Y, v.Position.Z
		return string.format("CF(%.2f,%.2f,%.2f)", x, y, z)
	elseif t == "string" then
		return if #v > 40 then string.format("<%d chars>", #v) else string.format("%q", v)
	end
	return tostring(v)
end

local function same(a, b)
	if typeof(a) ~= typeof(b) then
		return false
	end
	if typeof(a) == "CFrame" then
		return (a.Position - b.Position).Magnitude < 1e-3 and a.LookVector:Dot(b.LookVector) > 0.99999 and a.UpVector:Dot(b.UpVector) > 0.99999
	elseif typeof(a) == "Vector3" then
		return (a - b).Magnitude < 1e-3
	elseif typeof(a) == "number" then
		return math.abs(a - b) < 1e-4
	end
	return a == b or tostring(a) == tostring(b)
end

local mapA, orderA = index(before)
local mapB, orderB = index(after)
local lines = 0
local function out(s)
	lines += 1
	if lines <= maxLines then
		print(s)
	end
end

local removed, added, changed = 0, 0, 0
for _, p in orderA do
	if mapB[p] == nil then
		local parent = string.match(p, "^(.*)/[^/]*$")
		if parent == nil or mapB[parent] ~= nil then -- report only the removed subtree root
			removed += 1
			out(string.format("- %s <%s> (%d desc)", p, mapA[p].ClassName, #mapA[p]:GetDescendants()))
		end
	end
end
for _, p in orderB do
	if mapA[p] == nil then
		local parent = string.match(p, "^(.*)/[^/]*$")
		if parent == nil or mapA[parent] ~= nil then
			added += 1
			out(string.format("+ %s <%s> (%d desc)", p, mapB[p].ClassName, #mapB[p]:GetDescendants()))
		end
	end
end
for _, p in orderA do
	local a, b = mapA[p], mapB[p]
	if b ~= nil and a.ClassName == b.ClassName then
		local diffs = {}
		for _, prop in PROPS do
			local va, vb = get(a, prop), get(b, prop)
			if va ~= nil and vb ~= nil and not same(va, vb) then
				table.insert(diffs, prop .. ": " .. fmt(va) .. " -> " .. fmt(vb))
			end
		end
		if #diffs > 0 then
			changed += 1
			out(string.format("~ %s <%s> %s", p, a.ClassName, table.concat(diffs, "; ")))
		end
	end
end
print(string.format("== %d removed subtrees, %d added subtrees, %d changed instances (%d lines)", removed, added, changed, lines))
