--!nocheck
-- tests/smoke_owner_layout.luau (owner Studio save 2026-09-27, scripts/steps/post_zzz_owner_layout.luau). Joins the
-- "smoke" filter. The owner's hand placement survives the build:
--   1. every moved group carries OwnerLayout and, when the save is in the repo, every one of its parts stands where the
--      save has it (0.05 studs);
--   2. the gems and HeroBoard frame the owner deleted stay deleted;
--   3. the baseplate is the owner's three 2048-stud tiles.

local place = H.place()
local ws = place:GetService("Workspace")
local fs = H.fs

-- the step's own lists, read from its source (the test sandbox has no require)
local stepSrc = fs.readFile("scripts/steps/post_zzz_owner_layout.luau")
local step = { MOVES = {}, DELETES = {}, TOLERANCE = 0.05 }
step.OWNER_SAVE = string.match(stepSrc, 'Step%.OWNER_SAVE = "([^"]+)"')
for path in string.gmatch(string.match(stepSrc, "Step%.MOVES = (%b{})") or "", '"([^"]+)"') do
	table.insert(step.MOVES, path)
end
for rule in string.gmatch(string.sub(string.match(stepSrc, "Step%.DELETES = (%b{})") or "{}", 2, -2), "%b{}") do
	local entry = { root = string.match(rule, 'root = "([^"]+)"'), names = {}, deep = string.find(rule, "deep = true", 1, true) ~= nil }
	for name in string.gmatch(string.match(rule, "names = (%b{})") or "", '"([^"]+)"') do
		table.insert(entry.names, name)
	end
	table.insert(step.DELETES, entry)
end
T.check(step.OWNER_SAVE ~= nil and #step.MOVES == 9 and #step.DELETES == 5, "could not read post_zzz_owner_layout's lists (%d moves, %d deletes)",
	#step.MOVES, #step.DELETES)
local save = if step.OWNER_SAVE and fs.isFile(step.OWNER_SAVE) then H.roblox.deserializePlace(fs.readFile(step.OWNER_SAVE)) else nil

local function find(root, path)
	local segments = string.split(path, "/")
	local node = root:GetService(segments[1])
	for i = 2, #segments do
		node = node and node:FindFirstChild(segments[i])
	end
	return node
end

local function parts(root)
	local map = {}
	local function walk(inst, path)
		local seen = {}
		for _, child in ipairs(inst:GetChildren()) do
			local key = child.Name .. "<" .. child.ClassName .. ">"
			seen[key] = (seen[key] or 0) + 1
			local p = path .. "/" .. child.Name .. (if seen[key] > 1 then "#" .. seen[key] else "")
			if child:IsA("BasePart") then
				map[p] = child
			end
			walk(child, p)
		end
	end
	if root:IsA("BasePart") then
		map[""] = root
	end
	walk(root, "")
	return map
end

local off, compared = {}, 0
for _, path in ipairs(step.MOVES) do
	local inst = find(place, path)
	if T.check(inst ~= nil and inst:GetAttribute("OwnerLayout") == true, "%s must be placed by the owner layout (OwnerLayout)", path) and save then
		local saved = find(save, path)
		if T.check(saved ~= nil, "%s missing in the owner save", path) then
			local theirs = parts(saved)
			for p, part in pairs(parts(inst)) do
				local other = theirs[p]
				if other then
					compared += 1
					if (part.CFrame.Position - other.CFrame.Position).Magnitude > step.TOLERANCE then
						table.insert(off, path .. p)
					end
				end
			end
		end
	end
end
T.check(#off == 0, "%d part(s) off the owner's placement: %s", #off, table.concat(off, ", ", 1, math.min(#off, 4)))
T.check(save == nil or compared >= 200, "expected ~244 owner-placed parts compared with the save, got %d", compared)

local left = {}
for _, rule in ipairs(step.DELETES) do
	local root = find(place, rule.root)
	local names = {}
	for _, name in ipairs(rule.names) do
		names[name] = true
	end
	for _, d in ipairs(root and (if rule.deep then root:GetDescendants() else root:GetChildren()) or {}) do
		if names[d.Name] then
			table.insert(left, d:GetFullName())
		end
	end
end
T.check(#left == 0, "%d instance(s) the owner deleted are back: %s", #left, table.concat(left, ", ", 1, math.min(#left, 4)))

local tiles = {}
for _, child in ipairs(ws:GetChildren()) do
	if child.Name == "Baseplate" and child:IsA("BasePart") then
		table.insert(tiles, child)
	end
end
local okTiles = #tiles == 3
for _, tile in ipairs(tiles) do
	okTiles = okTiles and tile.Size.X <= 2048 and tile.Size.Z <= 2048
end
T.check(okTiles, "the baseplate must be the owner's three 2048-stud tiles (found %d)", #tiles)
