--!nocheck
-- tests/smoke_hublayout.luau (HUB LAYOUT pass 2026-09-26, scripts/steps/post_hub_zlayout.luau + ui_85_hero_park.luau +
-- scripts/inject/heropark.luau). Joins the "smoke" filter. Checks:
--   1. the Sell stand beside the main street at the stage-1 entrance: axis-aligned, facing the street (+Z), on its
--      bevelled pedestal, with its SELL signs and the glowing sell zone, prompts at the counter (<= 10 studs);
--   2. the Free Gift (board + chest + the GroupReward prompt on the lid) right in front of the spawn, facing +Z;
--   3. the HERO PARK in the south of the hub: inside its region, >= 3 studs from the hub walls, clear of the plots and the
--      street; fountain (coin prompt, water effects), the six stage Mythic statues (anchored, non-collidable rigs on
--      pedestals, plaques, View Hero prompts), benches, lamps, trees; nothing solid on the carpet; silent; built-in
--      particle textures;
--   4. the client script and the Hall of Heroes card are in the place and compile.

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
		T.check(look.Z > 0.9999 and math.abs(pivot.UpVector.Y - 1) < 1e-4, "Sell stand must be axis-aligned and face the street (+Z), look %s", tostring(look))
		T.check(p.X >= 50 and p.X <= 64 and p.Z <= -20 and p.Z >= -40, "Sell stand pivot (%.1f, %.1f) must stand south of the street at the stage-1 entrance", p.X, p.Z)

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
		T.check(mx.Z <= -16 and mx.X <= PLAN.SHOP_MAX_X, "Sell stand (X %.1f..%.1f Z %.1f..%.1f) must leave the street (|Z| <= 16) open and stay at X <= %d",
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
		T.check(look.Z > 0.9999, "Free Gift board must face the arriving players (+Z), look %s", tostring(look))
		local s = spawn.CFrame.Position
		local c = chest.WorldPivotData.Position
		T.check(flat(c, s) <= 35 and c.Z < s.Z, "Free Gift chest at (%.1f, %.1f) must stand in front of the spawn (<= 35 studs, spawn faces -Z)", c.X, c.Z)
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
-- 3. Hero Park
---------------------------------------------------------------------------------------------------
do
	local park = H.path(ws, "Hub/HeroPark")
	if T.check(park ~= nil and park:IsA("Model"), "Workspace.Hub.HeroPark (Model) missing") then
		local REGION = { minX = -95, maxX = 35, minZ = -208, maxZ = -160 }
		local mn, mx = H.groupAabb(park)
		T.check(mn.X >= REGION.minX and mx.X <= REGION.maxX and mn.Z >= REGION.minZ and mx.Z <= REGION.maxZ,
			"Hero Park X %.1f..%.1f Z %.1f..%.1f must stay inside X %d..%d Z %d..%d (clear of the HERO BOARD strip, the plots, the street)",
			mn.X, mx.X, mn.Z, mx.Z, REGION.minX, REGION.maxX, REGION.minZ, REGION.maxZ)
		local walls = H.path(ws, "WorldWalls/Hub")
		local nearWalls = {}
		for _, wall in ipairs(partsOf(walls)) do
			local a, b = H.aabb(wall)
			if overlapXZ(mn, mx, a, b, 3) then
				table.insert(nearWalls, wall.Name)
			end
		end
		T.check(walls ~= nil and #nearWalls == 0, "Hero Park must keep >= 3 studs from the hub walls: %s", list(nearWalls))

		local parts = partsOf(park)
		local loose, sounds, badTex, carpetBlock, plotHits = {}, 0, {}, {}, {}
		for _, part in ipairs(parts) do
			if not part.Anchored then
				table.insert(loose, part:GetFullName())
			end
			local a, b = H.aabb(part)
			local hit = touchesPlots(a, b, 0)
			if hit then
				table.insert(plotHits, part.Name .. " x " .. hit)
			end
			-- the avenue's walking line (carpet) and the path to the garden: nothing solid above ankle height
			if part.CanCollide and b.Y > groundY + 0.5 and a.X < 33 and b.X > -67 and a.Z < -181.5 and b.Z > -186.5 then
				-- (the fountain and the trophy stand at the two ends of the walk: players walk around them)
				if part:FindFirstAncestor("Fountain") == nil and part:FindFirstAncestor("Garden") == nil then
					table.insert(carpetBlock, part:GetFullName())
				end
			end
		end
		for _, d in ipairs(park:GetDescendants()) do
			if d:IsA("Sound") then
				sounds += 1
			elseif d:IsA("ParticleEmitter") then
				local uri = H.uri(d, "TextureContent")
				if not (uri and string.sub(uri, 1, 11) == "rbxasset://") then
					table.insert(badTex, d:GetFullName())
				end
			end
		end
		T.check(#loose == 0, "Hero Park: every part anchored (%s)", list(loose))
		T.check(sounds == 0 and #badTex == 0, "Hero Park must be silent (%d sounds) with built-in particle textures (%s)", sounds, list(badTex))
		T.check(#plotHits == 0, "Hero Park parts intersect the plots: %s", list(plotHits))
		T.check(#carpetBlock == 0, "Hero Park: solid parts block the carpet / garden path: %s", list(carpetBlock))

		-- fountain
		local fountain = park:FindFirstChild("Fountain")
		local coinHost = fountain and fountain:FindFirstChild("CoinPrompt")
		local coinPrompt = coinHost and coinHost:FindFirstChildOfClass("ProximityPrompt")
		local splash = fountain and fountain:FindFirstChild("SplashPoint")
		local running = 0
		for _, d in ipairs(fountain and fountain:GetDescendants() or {}) do
			if d:IsA("ParticleEmitter") and d.Enabled and d.Rate > 0 then
				running += 1
			end
		end
		T.check(coinPrompt ~= nil and coinPrompt.ActionText == "Toss a Coin" and coinPrompt.Enabled and not coinPrompt.RequiresLineOfSight
			and coinPrompt.MaxActivationDistance >= 10, "Hero Fountain needs its \"Toss a Coin\" prompt")
		T.check(splash ~= nil and splash:FindFirstChild("CoinSplash") ~= nil and splash:FindFirstChild("CoinRing") ~= nil and splash.CoinSplash.Rate == 0,
			"Hero Fountain needs its burst-only coin splash emitters (SplashPoint.CoinSplash / CoinRing)")
		T.check(running >= 8 and fountain:FindFirstChild("Water") ~= nil and fountain:FindFirstChild("Rim") ~= nil and fountain.Rim.CanCollide,
			"Hero Fountain needs its water, solid rim and running water effects (%d emitters)", running)

		-- statues: the Mythic hero of every stage
		local statues = park:FindFirstChild("Statues")
		local missing, bad = {}, {}
		for _, stage in ipairs(PLAN.STAGES) do
			local heroId = nil
			for _, hero in ipairs(PLAN.HEROES) do
				if hero[3] == stage.number and hero[4] == "Mythic" then
					heroId = hero[1]
					break
				end
			end
			local statue = heroId and statues and statues:FindFirstChild("Statue_" .. heroId)
			if statue == nil then
				table.insert(missing, tostring(heroId or ("stage " .. stage.number)))
				continue
			end
			local rig = statue:FindFirstChild("Hero")
			local host = statue:FindFirstChild("InfoPrompt")
			local prompt = host and host:FindFirstChildOfClass("ProximityPrompt")
			local plaque = statue:FindFirstChild("Plaque")
			local cap = statue:FindFirstChild("PedestalCap")
			local rigParts = partsOf(rig)
			local solid, minY = 0, math.huge
			for _, part in ipairs(rigParts) do
				if part.CanCollide or not part.Anchored then
					solid += 1
				end
				if part.Transparency < 1 then
					local a = H.aabb(part)
					minY = math.min(minY, a.Y)
				end
			end
			local capTop = nil
			if cap then
				local _, top = H.aabb(cap)
				capTop = top
			end
			-- the plaque names the hero ("Venom (Anti-Hero)" -> "VENOM")
			local display = PLAN.HERO_BY_ID[heroId] and PLAN.HERO_BY_ID[heroId].displayName or heroId
			local plaqueName = string.upper((string.gsub(display, "%s*%b()", "")))
			if not (rig and #rigParts >= 5 and solid == 0 and rig:GetAttribute("HeroId") == nil and prompt and prompt.ActionText == "View Hero"
				and host:GetAttribute("HeroId") == heroId and plaque and H.has(labelsOf(plaque), plaqueName)
				and cap and cap.CanCollide and capTop and math.abs(minY - capTop.Y) < 0.35) then
				table.insert(bad, heroId)
			end
		end
		T.check(statues ~= nil and #missing == 0, "Hero Park statues missing: %s", list(missing))
		T.check(#bad == 0, "Hero Park statues must be anchored, non-collidable rigs standing on a solid pedestal with a plaque and a View Hero prompt: %s", list(bad))

		-- props
		local seats, lamps, trees = 0, 0, 0
		for _, d in ipairs(park:GetDescendants()) do
			if d:IsA("Seat") then
				seats += 1
			elseif d:IsA("Model") and string.sub(d.Name, 1, 5) == "Lamp_" and d:FindFirstChildWhichIsA("PointLight", true) then
				lamps += 1
			elseif d:IsA("Model") and string.sub(d.Name, 1, 5) == "Tree_" then
				trees += 1
			end
		end
		T.check(seats >= 8 and lamps >= 12 and trees >= 12, "Hero Park props: %d benches, %d lamps, %d trees (>= 8 / 12 / 12)", seats, lamps, trees)
		local arch = park:FindFirstChild("Arch")
		T.check(arch ~= nil and H.has(labelsOf(arch), "HERO PARK") and park:FindFirstChild("Garden") ~= nil and park.Garden:FindFirstChild("TrophyPrompt") ~= nil,
			"Hero Park needs its HERO PARK arch and the Champions' garden trophy")
	end
end

---------------------------------------------------------------------------------------------------
-- 4. Client script + Hall of Heroes card
---------------------------------------------------------------------------------------------------
do
	local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local client = sps and H.path(sps, "Game/HeroPark")
	local src = client and client.Source or ""
	local okCompile = client ~= nil and pcall(H.luau.compile, src)
	T.check(client ~= nil and client:IsA("LocalScript") and okCompile and H.has(src, "CoinPrompt = function") and H.has(src, "InfoPrompt = function")
		and H.has(src, "PromptTriggered") and H.has(src, "\"HeroParkCard\"") and H.has(src, "Message.Top")
		and not H.has(src, "FireServer") and not H.has(src, "InvokeServer"),
		"StarterPlayerScripts.Game.HeroPark must be injected, compile and stay client-only (coin toss, statue card)")
	local card = H.path(place:GetService("StarterGui"), "HeroParkCard/Card")
	local close = card and card:FindFirstChild("Close")
	local glyph = close and close:FindFirstChild("TextButton")
	local okCard = card ~= nil and not card.Visible and glyph ~= nil and glyph:IsA("ImageLabel") and card:FindFirstChild("SpHeaderBand") ~= nil
	for _, name in ipairs({ "Portrait", "HeroName", "Stage", "Bio", "OkButton" }) do
		okCard = okCard and card:FindFirstChild(name) ~= nil
	end
	T.check(okCard and H.path(card, "Rarity/Label") ~= nil, "StarterGui.HeroParkCard.Card (kit window: band, close, portrait, facts, OK) missing")
	for _, path in ipairs({ "scripts/steps/post_hub_zlayout.luau", "scripts/steps/ui_85_hero_park.luau" }) do
		local ok = H.fs.isFile(path) and pcall(H.luau.compile, H.fs.readFile(path))
		T.check(ok, "%s must exist and compile", path)
	end
end
