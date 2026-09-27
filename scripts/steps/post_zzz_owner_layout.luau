--!nocheck
-- scripts/steps/post_zzz_owner_layout.luau (owner Studio save 2026-09-27)
-- The owner re-arranged the compiled place in Studio and sent it back ("I passed you the rbxl with the position and
-- map changes I made: edit that new version"). The save is kept at OWNER_SAVE and this step replays its edits on every
-- build, reading the placements from the save itself (scripts/tools/diff_places.luau lists what changed):
--   * MOVES: the HeroBoard, the Free Gift sign + chest, the GroupReward prompt host, the Sell stand + its prompts, the
--     Gear shop stand + the Trail shop pad. Each is moved RIGIDLY (every part, model pivot) by the transform that takes
--     its pivot in this build to its pivot in the save, so later content changes inside them still land in place.
--   * DELETES: the gem accents the owner removed (fence gems on every plot pen, the Sell pylon gem, the gift chest gem),
--     the HeroBoard's decorative frame (back, frames, corners, studs, pillars, crown, trophy: the screen, trims, tabs
--     and podium stay) and the unused Gems row of the gear buy template.
--   * BASEPLATE: a Roblox part is capped at 2048 studs per axis, so the 10000 x 3000 baseplate loaded as a 2048 square;
--     the owner tiled it with three 2048 x 2048 baseplates. They are copied from the save.
-- Runs after every step that builds these objects (hub layout, hero board, base themes / doors) and before the NPC
-- collider pass. Idempotent. No save: logged and skipped.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Step = {}

Step.OWNER_SAVE = "assets/user_models/StealaHero_studio_save_20260927_0738.rbxl"

Step.MOVES = {
	"Workspace/Hub/HeroBoard",
	"Workspace/Hub/FreeGift/ClaimSign",
	"Workspace/Hub/FreeGift/GiftChest",
	"Workspace/__OBJECTS/GroupReward",
	"Workspace/Stands/Models/Sell Stands",
	"Workspace/Stands/Prompts/SellAll",
	"Workspace/Stands/Prompts/SellHeldAsset",
	"Workspace/Stands/Models/GearShopStand",
	"Workspace/Stands/Pads/TrailShop",
}

-- { root, names, deep }: children (or, deep, descendants) of root with one of these names are destroyed
Step.DELETES = {
	{ root = "Workspace/Plots", names = { "HubFenceGem" }, deep = true },
	{ root = "Workspace/Stands/Models/Sell Stands", names = { "HubSellPylonGem" }, deep = true },
	{ root = "Workspace/Hub/FreeGift/GiftChest", names = { "Gem" } },
	{
		root = "Workspace/Hub/HeroBoard",
		names = {
			"HeroBoardBack", "HeroBoardCorner", "HeroBoardCrown", "HeroBoardCrownGem", "HeroBoardCrownRim", "HeroBoardFrame",
			"HeroBoardGem", "HeroBoardLedge", "HeroBoardLedgeLip", "HeroBoardPillar", "HeroBoardPillarBase",
			"HeroBoardPillarCap", "HeroBoardPillarGem", "HeroBoardStud", "HeroBoardTrophyCup", "HeroBoardTrophyGem",
			"HeroBoardTrophyHandle", "HeroBoardTrophyPlinth", "HeroBoardTrophyRim", "HeroBoardTrophyStem",
		},
	},
	{ root = "ReplicatedStorage/Assets/Interface/Buy/GearTemplate/Buttons", names = { "Gems" } },
}

-- parts that ended further than this from the save's copy count as misplaced (logged)
Step.TOLERANCE = 0.05

local function findPath(place, path)
	local segments = string.split(path, "/")
	local node = place:GetService(segments[1])
	for i = 2, #segments do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(segments[i])
	end
	return node
end

local function pivotOf(inst)
	if inst:IsA("BasePart") then
		return inst.CFrame
	end
	local ok, pivot = pcall(function()
		return inst.WorldPivotData
	end)
	if ok and typeof(pivot) == "CFrame" then
		return pivot
	end
	local primary = inst:IsA("Model") and inst.PrimaryPart
	return primary and primary.CFrame or nil
end

local function moveRigid(inst, delta)
	local all = inst:GetDescendants()
	table.insert(all, inst)
	for _, d in ipairs(all) do
		if d:IsA("BasePart") then
			d.CFrame = delta * d.CFrame
		elseif d:IsA("Model") then
			local ok, pivot = pcall(function()
				return d.WorldPivotData
			end)
			if ok and typeof(pivot) == "CFrame" then
				d.WorldPivotData = delta * pivot
			end
		end
	end
end

-- relative path of every BasePart under `root` ("#k" for the k-th same-named sibling)
local function partsByPath(root)
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

function Step.Apply(place, _spPlace, _ctx)
	if not fs.isFile(Step.OWNER_SAVE) then
		print("[post_zzz_owner_layout] WARN owner save " .. Step.OWNER_SAVE .. " missing; owner layout not applied")
		return
	end
	local save = roblox.deserializePlace(fs.readFile(Step.OWNER_SAVE))

	-- deletes first, so the move check compares like with like
	local deleted = 0
	for _, rule in ipairs(Step.DELETES) do
		local root = findPath(place, rule.root)
		if root == nil then
			print("[post_zzz_owner_layout] WARN " .. rule.root .. " missing; delete rule skipped")
			continue
		end
		local names = {}
		for _, name in ipairs(rule.names) do
			names[name] = true
		end
		local victims = {}
		for _, d in ipairs(if rule.deep then root:GetDescendants() else root:GetChildren()) do
			if names[d.Name] then
				table.insert(victims, d)
			end
		end
		for _, d in ipairs(victims) do
			if d.Parent ~= nil then
				d:Destroy()
				deleted += 1
			end
		end
	end

	local moved, misplaced, compared = 0, 0, 0
	for _, path in ipairs(Step.MOVES) do
		local inst, saved = findPath(place, path), findPath(save, path)
		local from, to = inst and pivotOf(inst), saved and pivotOf(saved)
		if not (from and to) then
			print("[post_zzz_owner_layout] WARN " .. path .. " missing here or in the save; not moved")
			continue
		end
		moveRigid(inst, to * from:Inverse())
		inst:SetAttribute("OwnerLayout", true) -- placed by the owner: the old layout rules in the tests give way
		moved += 1
		local mine, theirs = partsByPath(inst), partsByPath(saved)
		for p, part in pairs(mine) do
			local other = theirs[p]
			if other then
				compared += 1
				if (part.CFrame.Position - other.CFrame.Position).Magnitude > Step.TOLERANCE then
					misplaced += 1
					if misplaced <= 5 then
						print(string.format("[post_zzz_owner_layout] WARN %s%s is %.2f studs off the save", path, p,
							(part.CFrame.Position - other.CFrame.Position).Magnitude))
					end
				end
			end
		end
	end

	-- baseplate tiles
	local ws = place:GetService("Workspace")
	local tiles = {}
	for _, child in ipairs(save:GetService("Workspace"):GetChildren()) do
		if child.Name == "Baseplate" and child:IsA("BasePart") then
			table.insert(tiles, child)
		end
	end
	if #tiles > 0 then
		for _, child in ipairs(ws:GetChildren()) do
			if child.Name == "Baseplate" and child:IsA("BasePart") then
				child:Destroy()
			end
		end
		for _, tile in ipairs(tiles) do
			tile:Clone().Parent = ws
		end
	end

	print(string.format(
		"[post_zzz_owner_layout] %d groups moved (%d/%d parts off the save), %d instances deleted, %d baseplate tiles",
		moved, misplaced, compared, deleted, #tiles))
end

return Step
