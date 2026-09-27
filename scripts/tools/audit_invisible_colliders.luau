--!nocheck
-- scripts/tools/audit_invisible_colliders.luau
-- Lists every invisible (Transparency >= 0.95) part that still collides (CanCollide = true) in a built place's Workspace,
-- grouped by its top-level container, so invisible walls that snag players and heroes can be found.
--
--   lune run scripts/tools/audit_invisible_colliders.luau [place.rbxl]      (default StealaHero.rbxl)
--
-- NPC pass 2026-09-26: every Workspace entry is classified. Legit: the stage map-edge walls (StageEnvironments
-- Boundary / EndWall.SideWalls, lined up with the visible walls, required by tests/suite_world), the villain Colliders
-- (Guards collision group: never collide with players) and base-place leftovers under the map (Y < -20). Anything else
-- is a STRAY and the exit code is 1. Also reported: near-invisible (0.8 <= T < 0.95) colliders in Workspace and
-- collidable parts of held gear tools (a held tool is part of the character). Templates in ServerStorage /
-- ReplicatedStorage are listed for review (they only matter when a script clones them into the world with
-- CanCollide on; tests/smoke_npc.luau and scripts/steps/post_zzzz_npc_colliders.luau cover the ones that did).

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local path = process.args[1] or "StealaHero.rbxl"
local place = roblox.deserializePlace(fs.readFile(path))
local ws = place:GetService("Workspace")

local LEGIT = {
	{ "^Workspace%.StageEnvironments%.[^%.]+%.Boundary%.", "stage map-edge wall" },
	{ "^Workspace%.StageEnvironments%.EndWall%.SideWalls%.", "stage map-edge wall" },
	{ "^Workspace%.__OBJECTS%.Areas%.GuardAreas%.[^%.]+%.Guard%.Collider$", "villain collider (Guards group)" },
}
local function classify(part)
	if not part:IsDescendantOf(ws) then
		return "template"
	end
	local name = part:GetFullName()
	for _, rule in ipairs(LEGIT) do
		if string.find(name, rule[1]) then
			return rule[2]
		end
	end
	if part.CFrame.Position.Y < -20 then
		return "under the map"
	end
	return nil
end

-- Workspace plus the runtime templates that get cloned into it (base themes, stage props, hub props).
local roots = { ws }
for _, service in ipairs({ "ServerStorage", "ReplicatedStorage" }) do
	local s = place:FindFirstChild(service)
	if s then
		table.insert(roots, s)
	end
end

local groups = {}
local total, stray = 0, 0
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency >= 0.95 and d.CanCollide then
			local chain = {}
			local node = d
			while node and node ~= root do
				table.insert(chain, 1, node.Name)
				node = node.Parent
			end
			table.insert(chain, 1, root.Name)
			local key = table.concat(chain, "/", 1, math.min(4, #chain - 1))
			groups[key] = groups[key] or {}
			table.insert(groups[key], d)
			total += 1
		end
	end
end

local keys = {}
for k in pairs(groups) do
	table.insert(keys, k)
end
table.sort(keys)
for _, k in ipairs(keys) do
	local list = groups[k]
	local label = classify(list[1])
	for _, p in ipairs(list) do
		if classify(p) == nil then
			label = nil
			stray += 1
		end
	end
	print(string.format("%-60s %4d  [%s]", k, #list, label or "STRAY"))
	for i = 1, math.min(6, #list) do
		local p = list[i]
		local pos = p.CFrame.Position
		print(string.format("    %-28s %-10s size (%.1f, %.1f, %.1f) at (%.1f, %.1f, %.1f)", p.Name, p.ClassName,
			p.Size.X, p.Size.Y, p.Size.Z, pos.X, pos.Y, pos.Z))
	end
end

local near = {}
for _, d in ipairs(ws:GetDescendants()) do
	if d:IsA("BasePart") and d.CanCollide and d.Transparency >= 0.8 and d.Transparency < 0.95 then
		table.insert(near, d:GetFullName() .. string.format(" (T=%.2f)", d.Transparency))
	end
end
local gear = {}
local gearTools = place:GetService("ReplicatedStorage"):FindFirstChild("GearTools")
for _, d in ipairs(gearTools and gearTools:GetDescendants() or {}) do
	if d:IsA("BasePart") and d.CanCollide then
		table.insert(gear, d:GetFullName())
	end
end
print(string.format("near-invisible (0.8 <= T < 0.95) colliders in Workspace: %d %s", #near, table.concat(near, ", ", 1, math.min(#near, 6))))
print(string.format("colliding gear tool parts: %d %s", #gear, table.concat(gear, ", ", 1, math.min(#gear, 6))))
print(string.format("TOTAL invisible colliders: %d (STRAY in Workspace: %d)", total, stray))
if stray > 0 then
	process.exit(1)
end
