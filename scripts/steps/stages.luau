-- scripts/steps/stages.luau
-- Build step "stages" (owner STAGES, docs/STAGES_PLAN.md §1, §3, §4 and amendments A1/A2/A6/A7/A10). Runs after the
-- stage environments (scripts/steps/env_*.luau, which place the EggSpot markers and villain posts) and before the
-- hero builder. It turns the 9 legacy zones into the game plan's 6 stages:
--
--   1. Retires zones 7-9 (Abyss Ocean, Prehistoric, Cosmic): destroys their GuardAreas models, their
--      Workspace.Ground.ZoneFloor_* slabs and the divider past stage 6, and moves AdminAbuseEggSpawn into stage 1.
--      Directory.Areas._Index is left to HEROES (retired DropTables emptied, A1). Every script that reads zones
--      iterates what exists (GuardAreas children / Areas.Directory), so nothing yields on a missing zone.
--   2. Villain posts (A2): each kept zone's Guard is moved whole onto Workspace.StageEnvironments.<Key>.VillainPost,
--      facing -X (the hub).
--   3. Hidden eggs: each stage's nests are rebuilt, one per EggSpot marker
--      (Workspace.StageEnvironments.<Key>.EggSpots.EggSpot_<n>), as clones of the zone's own nest models (Root,
--      EggFitBounds, EggSpotBottom kept) seated on the marker, under GuardAreas.<Key>.Nests. A stage without markers
--      keeps its old nests (warning). The zone gets ActiveEggCount (6, One Piece 8) for AreaEggService's rotation.
--      D9 egg ring (docs/VISUAL_PASS_PLAN.md): the authored nests range from ~1.3 to ~11.5 studs, so a Hidden marker
--      (tucked behind a low cover rock) takes the compact templates and an open marker any template up to a ring-sized
--      footprint (NEST_MAX_FOOTPRINT); at runtime AreaEggService rescales every nest to its egg anyway.
--   4. Hub and gates (A6/A10): a stage-entrance arch at the start of every stage (Workspace.Hub.StageGates; the
--      owner removed the "STAGE n" sign panels and the hub "STAGES" progression board on 2026-09-23 - the gate
--      models keep their stage attributes), the Sell and Trails shops moved around the stage-1 entrance
--      (Workspace.Stands names kept), each zone's RequiredSpeedSign next to its gate and its ClosestExitPoint at the
--      gate's hub-side edge (clamped into its Bounds, see placeZoneSigns).
--
-- Stage and villain names are hard-coded from §1 (never read from hero data). Idempotent: absolute placements,
-- generated folders rebuilt from scratch on every run.

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Enum = roblox.Enum

local Step = {}

-- §1 of the plan, in stage order. colors = the stage's bright sign gradient.
Step.STAGES = {
	{ number = 1, key = "Forest", name = "The Avengers", villain = "Thanos", eggs = 6, startX = 72, colors = { "#ff3b3b", "#ffc93c" } },
	{ number = 2, key = "Lake", name = "Justice League", villain = "Darkseid", eggs = 6, startX = 169.5, colors = { "#1f63ff", "#27d8ff" } },
	{ number = 3, key = "Desert", name = "Spider-Verse", villain = "Carnage", eggs = 6, startX = 315.6, colors = { "#ff2f7d", "#8c3dff" } },
	{ number = 4, key = "Jungle", name = "My Hero Academia", villain = "Shigaraki", eggs = 6, startX = 526.5, colors = { "#18c94c", "#d6f23a" } },
	{ number = 5, key = "Snow", name = "Dragon Ball", villain = "Frieza", eggs = 6, startX = 762.5, colors = { "#ff7a00", "#ffd000" } },
	{ number = 6, key = "Volcano", name = "One Piece", villain = "Kaido", eggs = 8, startX = 1086.5, colors = { "#0a9bff", "#ffd966" } },
}
Step.RETIRED = { "Abyss Ocean", "Prehistoric", "Cosmic" }
Step.LAST_STAGE_END_X = 1471.5
Step.ADMIN_EGG_SPAWN_XZ = Vector2.new(120, -20) -- A1: stage 1's street

-- Hub layout (A6): everything hub-side stays at X <= 70, |Z| <= 15 stays open from the spawn to X 80.
Step.HUB_MAX_X = 70
Step.GATE1_X = 68 -- stage 1's arch stands at the hub edge and faces the hub
Step.PILLAR_SIZE = 3
Step.PILLAR_INNER_Z = 15.5 -- pillars at |Z| >= 15 (A6)
Step.PILLAR_HEIGHT = 24
Step.RSS_Z = 22 -- RequiredSpeedSign centre, just outside the north pillar
-- Shop targets by edges (the groups keep their authored -X facing): Trails north of the street between the
-- GearGivers (X <= 44.3) and the gate, Sell south of it next to the gate.
Step.TRAIL_SHOP = { maxX = 66.7, minZ = 20 }
Step.SELL_SHOP = { maxX = 67.5, maxZ = -20 }
-- D9: largest visible nest footprint (studs, max of X/Z) cloned onto a Hidden / open EggSpot marker; matches the cover
-- rock clearances of scripts/steps/post_scratch_layout.luau (hidden nest radius 1.4, open nest radius 2.5).
Step.NEST_MAX_FOOTPRINT = { hidden = 2.8, open = 5.0 }


local function log(fmt, ...)
	print(string.format("[stages] " .. fmt, ...))
end

local warnings = {}
local function warnf(fmt, ...)
	local message = string.format(fmt, ...)
	table.insert(warnings, message)
	print("[stages] WARNING: " .. message)
end

local function findPath(root, names)
	local node = root
	for _, name in ipairs(names) do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(name)
	end
	return node
end

---------------------------------------------------------------------------------------------------
-- Geometry helpers
---------------------------------------------------------------------------------------------------

-- World AABB of one part (rotation-aware).
local function partBounds(part)
	local cf, half = part.CFrame, part.Size * 0.5
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ext = Vector3.new(
		math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z
	)
	local p = cf.Position
	return p - ext, p + ext
end

-- World AABB of every BasePart in the given instances (and the instances themselves).
local function groupBounds(list)
	local mn, mx
	local function add(part)
		local a, b = partBounds(part)
		if not mn then
			mn, mx = a, b
		else
			mn = Vector3.new(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z))
			mx = Vector3.new(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z))
		end
	end
	for _, inst in ipairs(list) do
		if inst:IsA("BasePart") then
			add(inst)
		end
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") then
				add(d)
			end
		end
	end
	return mn, mx
end

local function boxesOverlap(aMin, aMax, bMin, bMax, eps)
	eps = eps or 0.05
	return aMin.X < bMax.X - eps and aMax.X > bMin.X + eps
		and aMin.Y < bMax.Y - eps and aMax.Y > bMin.Y + eps
		and aMin.Z < bMax.Z - eps and aMax.Z > bMin.Z + eps
end

-- Applies the rigid transform T to a whole subtree: every BasePart CFrame and every Model's WorldPivotData
-- (Lune persists WorldPivotData, not WorldPivot). Welds/Motor6Ds store relative offsets, so they stay valid.
local function transformTree(root, T)
	local function pivot(model)
		local ok, wp = pcall(function()
			return (model :: any).WorldPivotData
		end)
		if ok and typeof(wp) == "CFrame" then
			(model :: any).WorldPivotData = T * wp
		end
	end
	if root:IsA("BasePart") then
		root.CFrame = T * root.CFrame
	elseif root:IsA("Model") then
		pivot(root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = T * d.CFrame
		elseif d:IsA("Model") then
			pivot(d)
		end
	end
end

-- Yaw (radians) of a CFrame, the angle a CFrame.Angles(0, yaw, 0) would have.
local function yawOf(cf)
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

-- Rotation-only part of a CFrame.
local function rotationOf(cf)
	return CFrame.new(cf.Position):Inverse() * cf
end

-- Index of collidable parts (AABB) for overlap and walkable-surface checks.
local function buildCollidableIndex(ws, exclude)
	local index = {}
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BasePart") and d.CanCollide and d.Name ~= "Baseplate" and d.Name ~= "Terrain" then
			local skip = false
			for _, root in ipairs(exclude) do
				if d:IsDescendantOf(root) then
					skip = true
					break
				end
			end
			if not skip then
				local mn, mx = partBounds(d)
				table.insert(index, { part = d, min = mn, max = mx })
			end
		end
	end
	return index
end

local function overlapsIndex(index, mn, mx)
	for _, e in ipairs(index) do
		if boxesOverlap(mn, mx, e.min, e.max) then
			return e.part
		end
	end
	return nil
end

-- Top of the walkable surface under `pos` (the highest collidable top face within [pos.Y - below, pos.Y + above]),
-- or nil. The baseplate counts; a part's "top" is the face whose normal is most upward.
local function supportTopAt(index, baseplate, pos, below, above)
	local best = nil
	local function consider(top)
		if top >= pos.Y - below and top <= pos.Y + above and (best == nil or top > best) then
			best = top
		end
	end
	if baseplate then
		local mn, mx = partBounds(baseplate)
		if pos.X >= mn.X and pos.X <= mx.X and pos.Z >= mn.Z and pos.Z <= mx.Z then
			consider(mx.Y)
		end
	end
	for _, e in ipairs(index) do
		if pos.X >= e.min.X - 0.05 and pos.X <= e.max.X + 0.05 and pos.Z >= e.min.Z - 0.05 and pos.Z <= e.max.Z + 0.05 then
			local part = e.part
			local rel = part.CFrame:PointToObjectSpace(pos)
			local half = part.Size * 0.5
			local cf = part.CFrame
			local ay = { math.abs(cf.RightVector.Y), math.abs(cf.UpVector.Y), math.abs(cf.LookVector.Y) }
			-- inside the footprint on the two (most) horizontal local axes
			local inside
			if ay[2] >= ay[1] and ay[2] >= ay[3] then
				inside = math.abs(rel.X) <= half.X + 0.05 and math.abs(rel.Z) <= half.Z + 0.05
			elseif ay[1] >= ay[3] then
				inside = math.abs(rel.Y) <= half.Y + 0.05 and math.abs(rel.Z) <= half.Z + 0.05
			else
				inside = math.abs(rel.X) <= half.X + 0.05 and math.abs(rel.Y) <= half.Y + 0.05
			end
			if inside then
				consider(e.max.Y)
			end
		end
	end
	return best
end

---------------------------------------------------------------------------------------------------
-- 1. Retired zones (A1)
---------------------------------------------------------------------------------------------------

local function retireZones(place, ws, groundY)
	local guardAreas = findPath(ws, { "__OBJECTS", "Areas", "GuardAreas" })
	local ground = ws:FindFirstChild("Ground")
	local removed = {}
	local retiredModels = {}
	for _, key in ipairs(Step.RETIRED) do
		local zone = guardAreas and guardAreas:FindFirstChild(key)
		if zone then
			table.insert(retiredModels, zone)
		end
	end
	-- Object references into a retired zone would serialize as nil: report and clear them first.
	if #retiredModels > 0 then
		for _, d in ipairs(place:GetDescendants()) do
			if d:IsA("ObjectValue") and d.Value ~= nil then
				for _, zone in ipairs(retiredModels) do
					if (d.Value == zone or d.Value:IsDescendantOf(zone)) and not d:IsDescendantOf(zone) then
						warnf("%s pointed into retired zone %s; cleared", d:GetFullName(), zone.Name)
						d.Value = nil
					end
				end
			end
		end
	end
	for _, zone in ipairs(retiredModels) do
		table.insert(removed, "GuardAreas." .. zone.Name)
		zone:Destroy()
	end
	if ground then
		for _, key in ipairs(Step.RETIRED) do
			local floor = ground:FindFirstChild("ZoneFloor_" .. key)
			if floor then
				table.insert(removed, "Ground." .. floor.Name)
				floor:Destroy()
			end
		end
		-- dividers past stage 6 (ZoneDivider_7 between Abyss Ocean and Prehistoric); ZoneDivider_6 marks stage 6's end
		for _, d in ipairs(ground:GetChildren()) do
			if string.sub(d.Name, 1, 12) == "ZoneDivider_" and d:IsA("BasePart") and d.CFrame.Position.X > Step.LAST_STAGE_END_X + 5 then
				table.insert(removed, "Ground." .. d.Name)
				d:Destroy()
			end
		end
	end
	local adminSpawn = findPath(ws, { "__OBJECTS", "Areas", "AdminAbuseEggSpawn" })
	if adminSpawn and adminSpawn:IsA("BasePart") then
		local p = adminSpawn.CFrame.Position
		adminSpawn.CFrame = CFrame.new(Step.ADMIN_EGG_SPAWN_XZ.X, p.Y, Step.ADMIN_EGG_SPAWN_XZ.Y) * rotationOf(adminSpawn.CFrame)
		log("AdminAbuseEggSpawn moved (%.0f, %.1f, %.0f) -> (%.0f, %.1f, %.0f).", p.X, p.Y, p.Z, Step.ADMIN_EGG_SPAWN_XZ.X, p.Y, Step.ADMIN_EGG_SPAWN_XZ.Y)
	end
	log("Retired zones 7-9: removed %s.", #removed > 0 and table.concat(removed, ", ") or "nothing (already retired)")

	-- Anything collidable/visible left beyond stage 6 that is not the closing wall of ENV-B is reported.
	local leftovers = {}
	for _, d in ipairs(ws:GetChildren()) do
		if d ~= ws:FindFirstChild("StageEnvironments") and d.Name ~= "Baseplate" and d.Name ~= "Terrain" and d.Name ~= "Camera" then
			for _, p in ipairs(d:IsA("BasePart") and { d } or d:GetDescendants()) do
				if p:IsA("BasePart") and (p.CanCollide or p.Transparency < 1)
					and p.CFrame.Position.X > Step.LAST_STAGE_END_X + 5 and p.CFrame.Position.Y > groundY - 30 then
					table.insert(leftovers, p:GetFullName())
					if #leftovers >= 5 then
						break
					end
				end
			end
		end
	end
	if #leftovers > 0 then
		warnf("parts left past stage 6: %s", table.concat(leftovers, ", "))
	end
end

---------------------------------------------------------------------------------------------------
-- 2. Villain posts (A2)
---------------------------------------------------------------------------------------------------

local function postGuard(zone, stage, envModel, groundY)
	local guard = zone:FindFirstChild("Guard")
	if not guard or not guard:IsA("Model") then
		warnf("%s has no Guard model; villain post skipped", stage.key)
		return
	end
	local post = envModel and envModel:FindFirstChild("VillainPost")
	if not post or not post:IsA("BasePart") then
		warnf("%s: StageEnvironments.%s.VillainPost missing, the villain keeps its old post", stage.key, stage.key)
		return
	end
	local hrp = guard:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		hrp = guard.PrimaryPart
	end
	if not hrp then
		warnf("%s Guard has no HumanoidRootPart; villain post skipped", stage.key)
		return
	end
	local postPos = post.CFrame.Position
	local lift = postPos.Y - groundY
	if math.abs(lift) <= 1.5 then
		lift = 0 -- floor-level post (A2): keep the guard's height above the floor
	else
		warnf("%s VillainPost is %.1f studs off the floor; guard lifted with it", stage.key, lift)
	end
	local from = hrp.CFrame
	-- facing -X (the hub): CFrame.Angles(0, 90deg, 0) has LookVector (-1, 0, 0)
	local target = CFrame.new(postPos.X, from.Position.Y + lift, postPos.Z) * CFrame.Angles(0, math.rad(90), 0)
	transformTree(guard, target * from:Inverse())
	log("%s villain moved to its post (%.1f, %.1f, %.1f), facing -X.", stage.key, postPos.X, from.Position.Y + lift, postPos.Z)
end

---------------------------------------------------------------------------------------------------
-- 3. Nests on the EggSpot markers
---------------------------------------------------------------------------------------------------

local function nestModels(nestsFolder)
	local list = {}
	for _, c in ipairs(nestsFolder:GetChildren()) do
		local spot = c:IsA("Model") and c:FindFirstChild("EggSpotBottom")
		if spot and spot:IsA("BasePart") then
			table.insert(list, c)
		end
	end
	table.sort(list, function(a, b)
		local pa, pb = a.EggSpotBottom.CFrame.Position, b.EggSpotBottom.CFrame.Position
		if pa.X ~= pb.X then
			return pa.X < pb.X
		end
		return pa.Z < pb.Z
	end)
	return list
end

local function eggSpotMarkers(envModel)
	local folder = envModel and envModel:FindFirstChild("EggSpots")
	local list = {}
	for _, c in ipairs(folder and folder:GetChildren() or {}) do
		local n = tonumber(string.match(c.Name, "^EggSpot_(%d+)$"))
		if n and c:IsA("BasePart") then
			table.insert(list, { n = n, part = c })
		end
	end
	table.sort(list, function(a, b)
		return a.n < b.n
	end)
	return list
end

-- The part that defines a nest's floor pose: its PrimaryPart (Root), else EggSpotBottom.
local function nestReference(nest)
	local root = nest.PrimaryPart
	if root == nil then
		local r = nest:FindFirstChild("Root")
		root = if r and r:IsA("BasePart") then r else nil
	end
	return root or nest:FindFirstChild("EggSpotBottom")
end

local function stripUniqueIds(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:GetAttribute("_lemonadeUniqueId") ~= nil then
			d:SetAttribute("_lemonadeUniqueId", nil)
		end
	end
	if root:GetAttribute("_lemonadeUniqueId") ~= nil then
		root:SetAttribute("_lemonadeUniqueId", nil)
	end
end

-- Visible XZ footprint of a nest model (max of the X/Z extents of its visible parts).
local function nestFootprint(nest)
	local list = {}
	for _, d in ipairs(nest:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(list, d)
		end
	end
	local mn, mx = groupBounds(list)
	if not mn then
		return 0
	end
	return math.max(mx.X - mn.X, mx.Z - mn.Z)
end

-- Templates whose footprint fits `maxFootprint`; the smallest one when none does (D9, see NEST_MAX_FOOTPRINT).
local function templatesUpTo(templates, maxFootprint)
	local fit, smallest, smallestSize = {}, nil, math.huge
	for _, t in ipairs(templates) do
		local size = nestFootprint(t)
		if size <= maxFootprint then
			table.insert(fit, t)
		end
		if size < smallestSize then
			smallest, smallestSize = t, size
		end
	end
	if #fit == 0 then
		fit = { smallest }
	end
	return fit
end

local function buildNests(zone, stage, envModel, index, baseplate)
	local nestsFolder = zone:FindFirstChild("Nests")
	if not nestsFolder then
		warnf("%s has no Nests container; nests not rebuilt", stage.key)
		return 0, 0
	end
	local templates = nestModels(nestsFolder)
	local markers = eggSpotMarkers(envModel)
	if #markers == 0 then
		warnf("%s: no EggSpot markers (StageEnvironments.%s.EggSpots) yet, keeping its %d authored nests", stage.key, stage.key, #templates)
		return #templates, 0
	end
	if #templates == 0 then
		warnf("%s: no nest model to clone; EggSpot nests not built", stage.key)
		return 0, 0
	end

	local bounds = zone:FindFirstChild("Bounds")
	local placed, hidden = {}, 0
	local fresh = {}
	local hiddenTemplates = templatesUpTo(templates, Step.NEST_MAX_FOOTPRINT.hidden)
	local openTemplates = templatesUpTo(templates, Step.NEST_MAX_FOOTPRINT.open)
	local hiddenCount, openCount = 0, 0
	for _, marker in ipairs(markers) do
		local mcf = marker.part.CFrame
		local pos = mcf.Position
		local tooClose = nil
		for _, other in ipairs(placed) do
			local d = Vector2.new(pos.X - other.X, pos.Z - other.Z).Magnitude
			if d < 0.5 and math.abs(pos.Y - other.Y) < 0.5 then
				tooClose = "duplicate"
			elseif d < 3 and math.abs(pos.Y - other.Y) < 2 and tooClose == nil then
				tooClose = "close"
			end
		end
		if tooClose == "duplicate" then
			warnf("%s %s duplicates another EggSpot position; skipped", stage.key, marker.part.Name)
		else
			if tooClose == "close" then
				warnf("%s %s is less than 3 studs from another EggSpot", stage.key, marker.part.Name)
			end
			if mcf.UpVector.Y < 0.9 then
				warnf("%s %s is not upright; the nest keeps only its yaw", stage.key, marker.part.Name)
			end
			if bounds and bounds:IsA("BasePart") then
				local rel = bounds.CFrame:PointToObjectSpace(pos)
				if math.abs(rel.X) > bounds.Size.X * 0.5 or math.abs(rel.Z) > bounds.Size.Z * 0.5 then
					warnf("%s %s at (%.1f, %.1f, %.1f) is outside the zone Bounds", stage.key, marker.part.Name, pos.X, pos.Y, pos.Z)
				end
			end
			local support = supportTopAt(index, baseplate, pos, 0.35, 0.35)
			if support == nil then
				warnf("%s %s at (%.1f, %.1f, %.1f) has no walkable surface within 0.35 studs", stage.key, marker.part.Name, pos.X, pos.Y, pos.Z)
			end

			local template
			if marker.part:GetAttribute("Hidden") == true then
				hiddenCount += 1
				template = hiddenTemplates[((hiddenCount - 1) % #hiddenTemplates) + 1]
			else
				openCount += 1
				template = openTemplates[((openCount - 1) % #openTemplates) + 1]
			end
			local nest = template:Clone()
			local ref = nestReference(nest)
			local target = CFrame.new(pos) * CFrame.Angles(0, yawOf(mcf), 0) * rotationOf(ref.CFrame)
			transformTree(nest, target * ref.CFrame:Inverse())
			stripUniqueIds(nest)
			nest.Name = "NestModel"
			nest:SetAttribute("EggSpot", marker.part.Name)
			local isHidden = marker.part:GetAttribute("Hidden") == true
			nest:SetAttribute("Hidden", isHidden)
			if isHidden then
				hidden += 1
			end
			table.insert(fresh, nest)
			table.insert(placed, pos)
		end
	end

	if #fresh == 0 then
		warnf("%s: no usable EggSpot marker, keeping its %d authored nests", stage.key, #templates)
		return #templates, 0
	end
	for _, old in ipairs(templates) do
		old:Destroy()
	end
	local sum = Vector3.new(0, 0, 0)
	for _, nest in ipairs(fresh) do
		nest.Parent = nestsFolder
		sum += nest.EggSpotBottom.CFrame.Position
	end
	if nestsFolder:IsA("Model") and #fresh > 0 then
		nestsFolder.WorldPivotData = CFrame.new(sum / #fresh)
	end
	return #fresh, hidden
end

---------------------------------------------------------------------------------------------------
-- 4a. Shops around the stage-1 entrance
---------------------------------------------------------------------------------------------------

local function moveGroup(label, list, spec)
	if #list == 0 then
		warnf("%s: nothing to move", label)
		return nil, nil
	end
	local mn, mx = groupBounds(list)
	local dx, dz = 0, 0
	if spec.maxX then
		dx = spec.maxX - mx.X
	end
	if spec.minZ then
		dz = spec.minZ - mn.Z
	elseif spec.maxZ then
		dz = spec.maxZ - mx.Z
	end
	local T = CFrame.new(dx, 0, dz)
	for _, inst in ipairs(list) do
		transformTree(inst, T)
	end
	local nmn, nmx = groupBounds(list)
	log("%s moved by (%.1f, %.1f): X %.1f..%.1f, Z %.1f..%.1f.", label, dx, dz, nmn.X, nmx.X, nmn.Z, nmx.Z)
	return nmn, nmx
end

local function moveShops(ws)
	local stands = ws:FindFirstChild("Stands")
	if not stands then
		warnf("Workspace.Stands missing; shops not moved")
		return {}
	end
	local function collect(paths)
		local list = {}
		for _, p in ipairs(paths) do
			local inst = findPath(stands, p)
			if inst then
				table.insert(list, inst)
			else
				warnf("Workspace.Stands.%s missing", table.concat(p, "."))
			end
		end
		return list
	end
	local boxes = {}
	local sell = collect({ { "Models", "Sell Stands" }, { "Prompts", "SellAll" }, { "Prompts", "SellHeldAsset" } })
	local mn, mx = moveGroup("Sell shop (Sell Stands + SellAll + SellHeldAsset)", sell, Step.SELL_SHOP)
	if mn then
		table.insert(boxes, { name = "Sell shop", min = mn, max = mx })
	end
	local trail = collect({ { "Models", "GearShopStand" }, { "Pads", "TrailShop" } })
	mn, mx = moveGroup("Trails shop (GearShopStand + Pads.TrailShop)", trail, Step.TRAIL_SHOP)
	if mn then
		table.insert(boxes, { name = "Trails shop", min = mn, max = mx })
	end
	return boxes
end

---------------------------------------------------------------------------------------------------
-- 4b. Stage gates
---------------------------------------------------------------------------------------------------

-- North/south pillar centre |Z|: the first candidate whose pillar volume is clear of collidable parts.
local function choosePillarZ(index, gateX, side, groundY)
	local half = Step.PILLAR_SIZE / 2
	local base = Step.PILLAR_INNER_Z + half
	for _, extra in ipairs({ 0, 2, 4, 6, 8, 10 }) do
		local z = side * (base + extra)
		local mn = Vector3.new(gateX - half - 0.5, groundY + 0.2, z - half - 0.5)
		local mx = Vector3.new(gateX + half + 0.5, groundY + Step.PILLAR_HEIGHT, z + half + 0.5)
		local hit = overlapsIndex(index, mn, mx)
		if not hit then
			return math.abs(z), nil
		end
		if extra == 10 then
			return base, hit
		end
	end
	return base, nil
end

local function buildGate(folder, stage, gateX, index, groundY)
	local model = Instance.new("Model")
	model.Name = "StageGate_" .. stage.number
	model:SetAttribute("StageNumber", stage.number)
	model:SetAttribute("StageKey", stage.key)
	model:SetAttribute("StageName", stage.name)
	model:SetAttribute("VillainName", stage.villain)
	model:SetAttribute("ActiveEggs", stage.eggs)

	-- Owner 2026-09-23 ("quita estos aros"): no arch any more. The gate stays as an invisible marker Model (no
	-- parts): its attributes and pivot mark the stage entrance, and the pillar slots still place the zone's
	-- RequiredSpeedSign / ClosestExitPoint next to it.
	local zN, hitN = choosePillarZ(index, gateX, 1, groundY)
	local zS, hitS = choosePillarZ(index, gateX, -1, groundY)
	if hitN then
		warnf("gate %d north slot overlaps %s", stage.number, hitN:GetFullName())
	end
	if hitS then
		warnf("gate %d south slot overlaps %s", stage.number, hitS:GetFullName())
	end
	model.WorldPivotData = CFrame.new(gateX, groundY, 0)
	model.Parent = folder
	return model, zN, zS
end

---------------------------------------------------------------------------------------------------
-- 4d. Zone signs next to their gates (A10)
---------------------------------------------------------------------------------------------------

local function placeZoneSigns(zone, stage, gateX, pillarZ, index, groundY)
	local rss = zone:FindFirstChild("RequiredSpeedSign")
	if rss and rss:IsA("Model") then
		local mn, mx = groupBounds({ rss })
		local cx, cz = (mn.X + mx.X) / 2, (mn.Z + mx.Z) / 2
		local half = Vector3.new((mx.X - mn.X) / 2, 0, (mx.Z - mn.Z) / 2)
		local chosen, hit = nil, nil
		for _, z in ipairs({ pillarZ + Step.RSS_Z - (Step.PILLAR_INNER_Z + Step.PILLAR_SIZE / 2), -(pillarZ + Step.RSS_Z - (Step.PILLAR_INNER_Z + Step.PILLAR_SIZE / 2)), 28, -28 }) do
			local tmn = Vector3.new(gateX - half.X, groundY + 0.2, z - half.Z)
			local tmx = Vector3.new(gateX + half.X, groundY + (mx.Y - mn.Y), z + half.Z)
			hit = overlapsIndex(index, tmn, tmx)
			if not hit then
				chosen = z
				break
			end
		end
		if not chosen then
			chosen = Step.RSS_Z
			warnf("%s RequiredSpeedSign overlaps %s next to its gate", stage.key, hit and hit:GetFullName() or "?")
		end
		transformTree(rss, CFrame.new(gateX - cx, groundY - mn.Y, chosen - cz))
		log("%s RequiredSpeedSign next to gate %d at (%.1f, %.1f).", stage.key, stage.number, gateX, chosen)
	else
		warnf("%s has no RequiredSpeedSign", stage.key)
	end
	local exit = zone:FindFirstChild("ClosestExitPoint")
	if exit and exit:IsA("BasePart") then
		local p = exit.CFrame.Position
		-- The gate's hub-side edge on the main street, clamped into the zone Bounds: the base game's
		-- GuardEscapePrediction.ResolveExitDistance asserts that the point lies inside Bounds (XZ).
		local target = Vector3.new(gateX - Step.PILLAR_SIZE / 2 - 0.5, groundY + exit.Size.Y / 2, 0)
		local bounds = zone:FindFirstChild("Bounds")
		if bounds and bounds:IsA("BasePart") then
			local rel = bounds.CFrame:PointToObjectSpace(target)
			local hx, hz = math.max(bounds.Size.X / 2 - 0.5, 0), math.max(bounds.Size.Z / 2 - 0.5, 0)
			local clamped = bounds.CFrame:PointToWorldSpace(Vector3.new(math.clamp(rel.X, -hx, hx), rel.Y, math.clamp(rel.Z, -hz, hz)))
			target = Vector3.new(clamped.X, target.Y, clamped.Z)
		end
		exit.CFrame = CFrame.new(target) * rotationOf(exit.CFrame)
		log("%s ClosestExitPoint (%.1f, %.1f) -> gate %d hub-side edge (%.1f, %.1f).", stage.key, p.X, p.Z, stage.number, target.X, target.Z)
	else
		warnf("%s has no ClosestExitPoint", stage.key)
	end
end

---------------------------------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------------------------------

function Step.Apply(place, _spPlace, ctx)
	table.clear(warnings)
	local ws = place.Workspace
	local groundY = (ctx and ctx.groundY) or 2.05
	local baseplate = ws:FindFirstChild("Baseplate")
	local guardAreas = findPath(ws, { "__OBJECTS", "Areas", "GuardAreas" })
	assert(guardAreas, "[stages] Workspace.__OBJECTS.Areas.GuardAreas not found")
	local environments = ws:FindFirstChild("StageEnvironments")
	if not environments then
		warnf("Workspace.StageEnvironments missing (env steps not run?): no EggSpots, no villain posts")
	end

	-- 1. retire zones 7-9
	retireZones(place, ws, groundY)

	-- 2 + 3. villain posts, EggSpot nests, zone attributes
	local exclude = { guardAreas }
	local index = buildCollidableIndex(ws, exclude)
	local ground = ws:FindFirstChild("Ground")
	local summary = {}
	for _, stage in ipairs(Step.STAGES) do
		local zone = guardAreas:FindFirstChild(stage.key)
		if not zone then
			warnf("GuardAreas.%s missing; stage %d skipped", stage.key, stage.number)
		else
			local envModel = environments and environments:FindFirstChild(stage.key)
			if environments and not envModel then
				warnf("StageEnvironments.%s missing", stage.key)
			end
			postGuard(zone, stage, envModel, groundY)
			local nests, hidden = buildNests(zone, stage, envModel, index, baseplate)
			local active = math.min(stage.eggs, nests)
			zone:SetAttribute("StageNumber", stage.number)
			zone:SetAttribute("StageName", stage.name)
			zone:SetAttribute("ActiveEggCount", stage.eggs)
			zone:SetAttribute("EggSpotCount", nests)
			if nests < stage.eggs then
				warnf("%s has %d nests for %d active eggs; only %d eggs will be out", stage.key, nests, stage.eggs, active)
			end
			table.insert(summary, string.format("%d %s/%s: %d nests (%d hidden), %d active", stage.number, stage.name, stage.key, nests, hidden, active))
		end
		-- stage start from the themed floor slab when present
		local floor = ground and ground:FindFirstChild("ZoneFloor_" .. stage.key)
		if floor and floor:IsA("BasePart") then
			local mn = partBounds(floor)
			stage.floorStartX = mn.X
		end
	end
	for _, line in ipairs(summary) do
		log("Stage %s", line)
	end

	-- 4. hub: shops first (the gate/board checks must see them), then gates, board, zone signs
	local shopBoxes = moveShops(ws)

	local hub = ws:FindFirstChild("Hub")
	if not hub then
		hub = Instance.new("Folder")
		hub.Name = "Hub"
		hub.Parent = ws
	end
	for _, name in ipairs({ "StageGates", "ProgressionBoard" }) do
		local old = hub:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local gatesFolder = Instance.new("Folder")
	gatesFolder.Name = "StageGates"
	gatesFolder.Parent = hub

	index = buildCollidableIndex(ws, { guardAreas, hub })
	for _, stage in ipairs(Step.STAGES) do
		local gateX = if stage.number == 1 then Step.GATE1_X else (stage.floorStartX or stage.startX)
		local _, zN, zS = buildGate(gatesFolder, stage, gateX, index, groundY)
		log("Gate %d (%s) at X %.1f, pillars at Z +%.1f / -%.1f.", stage.number, stage.name, gateX, zN, zS)
		local zone = guardAreas:FindFirstChild(stage.key)
		if zone then
			placeZoneSigns(zone, stage, gateX, zN, index, groundY)
		end
	end


	-- 5. hub layout checks (A6): X <= 70, street |Z| <= 15 open, clear of spawn / gear givers / leaderboards / plots
	local hubItems = {}
	for _, b in ipairs(shopBoxes) do
		table.insert(hubItems, b)
	end
	local gate1 = gatesFolder:FindFirstChild("StageGate_1")
	if gate1 then
		for _, part in ipairs(gate1:GetChildren()) do
			if part:IsA("BasePart") and part.CanCollide then
				local mn, mx = partBounds(part)
				table.insert(hubItems, { name = "Gate 1 " .. part.Name, min = mn, max = mx })
			end
		end
		local forest = guardAreas:FindFirstChild("Forest")
		local rss = forest and forest:FindFirstChild("RequiredSpeedSign")
		if rss then
			local mn, mx = groupBounds({ rss })
			table.insert(hubItems, { name = "Forest RequiredSpeedSign", min = mn, max = mx })
		end
	end
	local keepOut = {}
	local function addKeepOut(name, inst)
		if inst then
			local mn, mx = groupBounds({ inst })
			if mn then
				table.insert(keepOut, { name = name, min = mn, max = mx })
			end
		end
	end
	addKeepOut("SpawnLocation", spawn)
	addKeepOut("GearGivers", ws:FindFirstChild("GearGivers"))
	addKeepOut("Leaderboards", findPath(ws, { "__OBJECTS", "Leaderboards" }))
	for _, plot in ipairs(ws:FindFirstChild("Plots") and ws.Plots:GetChildren() or {}) do
		addKeepOut("Plot " .. plot.Name, plot)
	end
	local problems = 0
	for i, item in ipairs(hubItems) do
		if item.max.X > Step.HUB_MAX_X + 0.05 then
			problems += 1
			warnf("%s reaches X %.1f (hub props must stay at X <= %d)", item.name, item.max.X, Step.HUB_MAX_X)
		end
		if item.min.Z < 15 and item.max.Z > -15 and item.min.Y < groundY + 12 then
			problems += 1
			warnf("%s intrudes into the main street (|Z| <= 15)", item.name)
		end
		for _, zone in ipairs(keepOut) do
			if boxesOverlap(item.min, item.max, zone.min, zone.max, 0.05) then
				problems += 1
				warnf("%s overlaps %s", item.name, zone.name)
			end
		end
		for j = i + 1, #hubItems do
			local other = hubItems[j]
			if not (string.sub(item.name, 1, 6) == "Gate 1" and string.sub(other.name, 1, 6) == "Gate 1")
				and boxesOverlap(item.min, item.max, other.min, other.max, 0.05) then
				problems += 1
				warnf("%s overlaps %s", item.name, other.name)
			end
		end
	end
	log("Hub layout check: %d problem(s).", problems)
	log("Done with %d warning(s).", #warnings)
end

return Step
