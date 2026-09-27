--!nocheck
-- tests/smoke_hublayout.luau (HUB LAYOUT pass 2026-09-26, scripts/steps/post_hub_zlayout.luau). Joins the "smoke"
-- filter. Checks:
--   1. the Sell stand beside the main street at the stage-1 entrance: axis-aligned, facing the street (+Z), on its
--      bevelled pedestal, with its SELL signs and the glowing sell zone, prompts at the counter (<= 10 studs);
--   2. the Free Gift (board + chest + the GroupReward prompt on the lid) right in front of the spawn, facing +Z;
--   3. the HERO PARK (Hall of Heroes) is removed completely (owner 2026-09-27): no model, card, client script or source.

local place = H.place()
local ws = place.Workspace
local Vector3 = H.roblox.Vector3
local Enum = H.roblox.Enum
local PLAN = H.PLAN

local bp = ws:FindFirstChild("Baseplate")
local groundY = bp and bp.CFrame.Position.Y + bp.Size.Y / 2 or 2.05

local function list(t)
	return table.concat(t, ", ", 1, math.min(#t, 6))
end

local function partsOf(root)
	local out = {}
	if root == nil then
		return out
	end
	if root:IsA("BasePart") then
		table.insert(out, root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function union(a0, a1, b0, b1)
	if a0 == nil then
		return b0, b1
	end
	return Vector3.new(math.min(a0.X, b0.X), math.min(a0.Y, b0.Y), math.min(a0.Z, b0.Z)),
		Vector3.new(math.max(a1.X, b1.X), math.max(a1.Y, b1.Y), math.max(a1.Z, b1.Z))
end

local function overlapXZ(a0, a1, b0, b1, pad)
	pad = pad or 0
	return a0.X < b1.X + pad and a1.X > b0.X - pad and a0.Z < b1.Z + pad and a1.Z > b0.Z - pad
end

local function labelsOf(root)
	local texts = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") then
			table.insert(texts, d.Text)
		end
	end
	return table.concat(texts, " | ")
end

local function flat(a, b)
	return math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2)
end

-- visible / collidable plot parts (their exact boxes, not the whole-plot bounds)
local plotBoxes = {}
for _, plot in ipairs(ws:FindFirstChild("Plots") and ws.Plots:GetChildren() or {}) do
	for _, part in ipairs(partsOf(plot)) do
		if part.Transparency < 1 or part.CanCollide then
			local mn, mx = H.aabb(part)
			if mx.Y > groundY + 0.3 then
				table.insert(plotBoxes, { part:GetFullName(), mn, mx })
			end
		end
	end
end
local function touchesPlots(mn, mx, pad)
	for _, box in ipairs(plotBoxes) do
		if overlapXZ(mn, mx, box[2], box[3], pad) then
			return box[1]
		end
	end
	return nil
end

---------------------------------------------------------------------------------------------------
-- 1. Sell stand
---------------------------------------------------------------------------------------------------
do
	local stands = ws:FindFirstChild("Stands")
	local sell = stands and H.path(stands, "Models/Sell Stands")
	local sellAll = stands and H.path(stands, "Prompts/SellAll")
	local sellHeld = stands and H.path(stands, "Prompts/SellHeldAsset")
	if T.check(sell ~= nil and sellAll ~= nil and sellHeld ~= nil, "Stands.Models.Sell Stands / Prompts.SellAll / Prompts.SellHeldAsset missing") then
		local pivot = sell.WorldPivotData
		local look, p = pivot.LookVector, pivot.Position
		-- the owner moved the stand by hand in Studio (post_zzz_owner_layout marks it OwnerLayout): no placement rules
		local ownerPlaced = sell:GetAttribute("OwnerLayout") == true
		T.check(ownerPlaced or (look.Z > 0.9999 and math.abs(pivot.UpVector.Y - 1) < 1e-4), "Sell stand must be axis-aligned and face the street (+Z), look %s", tostring(look))
		T.check(ownerPlaced or (p.X >= 50 and p.X <= 64 and p.Z <= -20 and p.Z >= -40), "Sell stand pivot (%.1f, %.1f) must stand south of the street at the stage-1 entrance", p.X, p.Z)

		local pedestal, loose, solidPedestal, pedestalTop = 0, {}, true, -math.huge
		local zonePad, zoneOk = nil, false
		for _, part in ipairs(partsOf(sell)) do
			if not part.Anchored then
				table.insert(loose, part.Name)
			end
			if string.sub(part.Name, 1, 15) == "HubSellPedestal" and part.Name ~= "HubSellPedestalTrim" then
				pedestal += 1
				solidPedestal = solidPedestal and part.CanCollide
				local _, mx = H.aabb(part)
				pedestalTop = math.max(pedestalTop, mx.Y)
			elseif part.Name == "HubSellZonePad" then
				zonePad = part
			end
		end
		T.check(#loose == 0, "Sell stand parts must be anchored: %s", list(loose))
		T.check(pedestal >= 18 and solidPedestal and math.abs(pedestalTop - p.Y) < 0.05,
			"Sell stand needs its walkable bevelled pedestal (%d parts, top %.2f) under the stall (pivot Y %.2f)", pedestal, pedestalTop, p.Y)
		if zonePad then
			local emitter = zonePad:FindFirstChildWhichIsA("ParticleEmitter")
			local uri = emitter and H.uri(emitter, "TextureContent")
			zoneOk = emitter ~= nil and uri ~= nil and string.sub(uri, 1, 11) == "rbxasset://" and zonePad:FindFirstChildWhichIsA("PointLight") ~= nil
				and not zonePad.CanCollide and (zonePad.CFrame.Position - p):Dot(look) > 2
		end
		T.check(zoneOk, "Sell stand needs its glowing sell zone in front of the counter (HubSellZonePad: shimmer + light, non-collidable)")
		local texts = labelsOf(sell)
		T.check(H.has(texts, "SELL") and H.has(texts, "HEROES") and sell:FindFirstChild("HubSellPylonPost") ~= nil,
			"Sell stand needs its SELL stall sign and the SELL HEROES pylon")
		T.check(sell:FindFirstChild("HubStallGlow") == nil and sell:FindFirstChild("HubStallCounter") ~= nil,
			"Sell stall remodel kept (HubStallCounter) and its old glow disc replaced by the sell zone")

		for _, spec in ipairs({ { sellAll, "Sell Heroes", Enum.KeyCode.R }, { sellHeld, nil, Enum.KeyCode.E } }) do
			local part, prompt = spec[1], spec[1]:FindFirstChildOfClass("ProximityPrompt")
			local q = part.CFrame.Position
			T.check(prompt ~= nil and prompt.KeyboardKeyCode == spec[3] and (spec[2] == nil or prompt.ActionText == spec[2]),
				"%s prompt must keep its key / text", part.Name)
			T.check((q - p).Magnitude <= 10 and (q - p):Dot(look) > 1 and q.Y > p.Y + 1,
				"%s at %s must stand at the counter front (<= 10 studs from the stall, on the street side)", part.Name, tostring(q))
		end

		local mn, mx
		for _, root in ipairs({ sell, sellAll, sellHeld }) do
			local a, b = H.groupAabb(root)
			mn, mx = union(mn, mx, a, b)
		end
		T.check(mx.Z <= -16 and (ownerPlaced or mx.X <= PLAN.SHOP_MAX_X), "Sell stand (X %.1f..%.1f Z %.1f..%.1f) must leave the street (|Z| <= 16) open and stay at X <= %d",
			mn.X, mx.X, mn.Z, mx.Z, PLAN.SHOP_MAX_X)
		local hit = touchesPlots(mn, mx, 1)
		T.check(hit == nil, "Sell stand touches %s", tostring(hit))
	end
end

---------------------------------------------------------------------------------------------------
-- 2. Free Gift in front of the spawn
---------------------------------------------------------------------------------------------------
do
	local freeGift = H.path(ws, "Hub/FreeGift")
	local board = freeGift and freeGift:FindFirstChild("ClaimSign")
	local chest = freeGift and freeGift:FindFirstChild("GiftChest")
	local lid = chest and chest:FindFirstChild("Lid")
	local gift = H.path(ws, "__OBJECTS/GroupReward")
	local spawn = ws:FindFirstChild("SpawnLocation")
	if T.check(board ~= nil and chest ~= nil and lid ~= nil and gift ~= nil and spawn ~= nil, "Free Gift board / chest / lid / GroupReward / SpawnLocation missing") then
		local look = board.WorldPivotData.LookVector
		local ownerPlaced = board:GetAttribute("OwnerLayout") == true and chest:GetAttribute("OwnerLayout") == true
		T.check(ownerPlaced or look.Z > 0.9999, "Free Gift board must face the arriving players (+Z), look %s", tostring(look))
		local s = spawn.CFrame.Position
		local c = chest.WorldPivotData.Position
		T.check(ownerPlaced or (flat(c, s) <= 35 and c.Z < s.Z), "Free Gift chest at (%.1f, %.1f) must stand in front of the spawn (<= 35 studs, spawn faces -Z)", c.X, c.Z)
		local g, l = gift.CFrame.Position, lid.CFrame.Position
		T.check(flat(g, l) <= 1.5 and g.Y > l.Y and g.Y - l.Y <= 3, "__OBJECTS.GroupReward must stay on the chest lid (flat %.2f, up %.2f)", flat(g, l), g.Y - l.Y)
		local mn, mx = H.groupAabb(freeGift)
		T.check(mx.Z <= -16, "Free Gift reaches Z %.1f: the street (|Z| <= 16) stays open", mx.Z)
		local hit = touchesPlots(mn, mx, 1)
		T.check(hit == nil, "Free Gift touches %s", tostring(hit))
		local sell = H.path(ws, "Stands/Models/Sell Stands")
		if sell then
			-- at ground level: the collidable pieces of both (signs overhead do not block anyone)
			local function solidBox(root)
				local a, b
				for _, part in ipairs(partsOf(root)) do
					if part.CanCollide then
						local p0, p1 = H.aabb(part)
						a, b = union(a, b, p0, p1)
					end
				end
				return a, b
			end
			local a, b = solidBox(sell)
			local g0, g1 = solidBox(freeGift)
			T.check(a ~= nil and g0 ~= nil and not overlapXZ(g0, g1, a, b, 3),
				"Free Gift and the Sell stand must keep a >= 3 stud walkway between them")
		end
		local loose = {}
		for _, part in ipairs(partsOf(freeGift)) do
			if not part.Anchored then
				table.insert(loose, part.Name)
			end
		end
		T.check(#loose == 0 and gift.Anchored, "Free Gift parts must stay anchored: %s", list(loose))
	end
end

---------------------------------------------------------------------------------------------------
-- 3. The Hero Park (Hall of Heroes) is gone (owner 2026-09-27: "Remove the Heroes Hall area completely")
---------------------------------------------------------------------------------------------------
do
	local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local leftovers = {}
	if H.path(ws, "Hub/HeroPark") then
		table.insert(leftovers, "Workspace.Hub.HeroPark")
	end
	if place:GetService("StarterGui"):FindFirstChild("HeroParkCard") then
		table.insert(leftovers, "StarterGui.HeroParkCard")
	end
	if sps and H.path(sps, "Game/HeroPark") then
		table.insert(leftovers, "StarterPlayerScripts.Game.HeroPark")
	end
	for _, d in ipairs(ws:GetDescendants()) do
		if d:GetAttribute("HeroParkStatue") ~= nil then
			table.insert(leftovers, d:GetFullName())
			break
		end
	end
	for _, path in ipairs({ "scripts/inject/heropark.luau", "scripts/steps/ui_85_hero_park.luau", "src/StarterPlayer/StarterPlayerScripts/Game/HeroPark.client.luau" }) do
		if H.fs.isFile(path) then
			table.insert(leftovers, path)
		end
	end
	T.check(#leftovers == 0, "the Hero Park must be removed completely: %s", list(leftovers))
	T.check(pcall(H.luau.compile, H.fs.readFile("scripts/steps/post_hub_zlayout.luau")), "scripts/steps/post_hub_zlayout.luau must compile")
end
