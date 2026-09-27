--!nocheck
-- tests/smoke_heroboard.luau (HEROBOARD 2026-09-26; joins the "smoke" filter): the ONE wall-mounted HERO BOARD that
-- replaced the four free-standing hub leaderboards (scripts/steps/post_leaderboards.luau retires them,
-- scripts/steps/post_x_hero_board.luau builds Workspace.Hub.HeroBoard) + its top-3 podium, filled at runtime by
-- ServerScriptService.LeaderboardService, pages switched per viewer by StarterPlayerScripts.Game.HeroBoard.
--   STEALAHERO_PLACE=<build> lune run tests/run_all_tests.luau smoke

local Enum = H.roblox.Enum
local V3 = H.roblox.Vector3
local place = H.place()
local ws = place:GetService("Workspace")
local sss = place:GetService("ServerScriptService")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

local WALL_FACE_X = 71.2 -- HubWall_EastSouth inner face
local REGION = { xMin = 40, zMin = -200, zMax = -95 } -- the board's reserved corner of the hub
local LANE_MOUTH = { -87, 85 } -- open east side of the hub (Z) toward the stages
local STATS = {
	{ "Networth", "TOTAL NETWORTH" }, { "SpeedPower", "TOTAL SPEED" }, { "TimePlayed", "IN-GAME TIME" }, { "EggsHatched", "EGGS HATCHED" },
}

local function list(t)
	return table.concat(t, ", ", 1, math.min(#t, 6))
end

local function grow(mn, mx, a, b)
	if mn == nil then
		return a, b
	end
	return V3.new(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z)), V3.new(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z))
end

-- 1. one board, the old four (and their dead UI) gone
local tagged, old = {}, {}
for _, d in ipairs(ws:GetDescendants()) do
	if d:GetAttribute("HeroBoard") == true then
		table.insert(tagged, d:GetFullName())
	end
	if d:IsA("Model") and string.match(d.Name, "^Leaderboard%d+$") then
		table.insert(old, d:GetFullName())
	end
end
local board = H.path(ws, "Hub/HeroBoard")
T.check(board ~= nil and board:IsA("Model") and #tagged == 1, "exactly one HERO BOARD (Workspace.Hub.HeroBoard, attribute HeroBoard) expected, found: %s", list(tagged))
T.check(#old == 0 and H.path(ws, "__OBJECTS/Leaderboards") == nil, "the old hub boards must be gone (Leaderboard1..4 / __OBJECTS.Leaderboards): %s", list(old))
if board == nil then
	return
end
T.check(board:GetAttribute("DefaultStat") == "Networth" and board:GetAttribute("PodiumStat") == "Networth" and board:GetAttribute("LeaderboardRows") == 10,
	"HeroBoard attributes: DefaultStat / PodiumStat Networth, LeaderboardRows 10")

-- the owner re-hung the board by hand in Studio (post_zzz_owner_layout marks it OwnerLayout, moved rigidly from the
-- save): the wall / region rules below give way to where they put it; the board still faces its own podium side
local ownerPlaced = board:GetAttribute("OwnerLayout") == true

-- 2. flush on HubWall_EastSouth's inner face, facing the hub, inside its corner of the hub
local wall = H.path(ws, "WorldWalls/Hub/HubWall_EastSouth")
local podium = board:FindFirstChild("Podium")
local mn, mx = nil, nil
local clipping = {}
for _, d in ipairs(board:GetDescendants()) do
	if d:IsA("BasePart") and not (podium and d:IsDescendantOf(podium)) then
		local a, b = H.aabb(d)
		mn, mx = grow(mn, mx, a, b)
		if b.X > WALL_FACE_X + 0.01 then
			table.insert(clipping, string.format("%s (X %.2f)", d.Name, b.X))
		end
	end
end
if ownerPlaced then
	T.check(mn ~= nil, "HeroBoard parts missing")
elseif T.check(wall ~= nil and mn ~= nil, "Workspace.WorldWalls.Hub.HubWall_EastSouth / board parts missing") then
	local wmn, wmx = H.aabb(wall)
	T.check(math.abs(wmn.X - WALL_FACE_X) <= 0.05, "HubWall_EastSouth inner face moved to X %.2f (the board hangs on X %.1f)", wmn.X, WALL_FACE_X)
	T.check(math.abs(mx.X - WALL_FACE_X) <= 0.05 and #clipping == 0,
		"HERO BOARD back must be flush on the wall (back X %.3f, face %.1f; parts past the face: %s)", mx.X, WALL_FACE_X, list(clipping))
	T.check(mn.Z >= wmn.Z and mx.Z <= wmx.Z and mx.Z < LANE_MOUTH[1] and mx.Y <= wmx.Y + 0.01,
		"HERO BOARD must hang on HubWall_EastSouth (Z %.1f..%.1f vs wall %.1f..%.1f, top %.2f vs %.2f)", mn.Z, mx.Z, wmn.Z, wmx.Z, mx.Y, wmx.Y)
	T.check(mn.X >= REGION.xMin and mn.Z >= REGION.zMin and mx.Z <= REGION.zMax,
		"HERO BOARD outside its region X >= %d, Z %d..%d (X %.1f..%.1f Z %.1f..%.1f)", REGION.xMin, REGION.zMin, REGION.zMax, mn.X, mx.X, mn.Z, mx.Z)
	local wide, tall = mx.Z - mn.Z, mx.Y - mn.Y
	T.check(wide >= 28 and tall >= 18, "HERO BOARD too small (%.1f x %.1f studs)", wide, tall)
end

-- 3. the screen: one SurfaceGui in the Free Gift / Sell style
local screen = board:FindFirstChild("Screen")
local gui = screen and screen:FindFirstChild("BoardGui")
local root = gui and gui:FindFirstChild("Board")
if not T.check(screen ~= nil and screen:IsA("BasePart") and gui ~= nil and gui:IsA("SurfaceGui") and root ~= nil,
	"HeroBoard.Screen > BoardGui (SurfaceGui) > Board missing") then
	return
end
T.check((ownerPlaced or screen.CFrame.LookVector:Dot(V3.new(-1, 0, 0)) > 0.999) and gui.Face == Enum.NormalId.Front, "the board screen must face -X (the hub)")
T.check(screen.Size.X >= 28 and screen.Size.X <= 34 and screen.Size.Y >= 17 and screen.Size.Y <= 23, "screen %.1f x %.1f studs (expected ~28-34 x 18-22)",
	screen.Size.X, screen.Size.Y)
T.check(gui.Enabled and gui.LightInfluence == 0 and gui.MaxDistance >= 200 and gui.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud
	and gui.PixelsPerStud >= 20 and gui.PixelsPerStud <= 60 and gui.ZIndexBehavior == Enum.ZIndexBehavior.Sibling,
	"BoardGui: Enabled, LightInfluence 0, MaxDistance >= 200, PixelsPerStud 20-60, Sibling (MaxDistance %s, pps %s)", tostring(gui.MaxDistance), tostring(gui.PixelsPerStud))
local title = root:FindFirstChild("Title")
T.check(root:FindFirstChild("SpHeaderBand") ~= nil and root:FindFirstChild("SpStuds") ~= nil and root:FindFirstChild("SpHeaderIcon") ~= nil
	and title ~= nil and title.Text == "HERO BOARD" and root:FindFirstChild("SpStroke") ~= nil,
	"Board must use the kit window look: studded body + rim, glossy header band, trophy icon, HERO BOARD title")
local badFonts = {}
for _, d in ipairs(board:GetDescendants()) do
	if d:IsA("TextLabel") then
		local okFont, family = pcall(function()
			return d.FontFace.Family
		end)
		if not (okFont and string.find(tostring(family), "FredokaOne", 1, true)) or (d.TextScaled and not d.TextWrapped) then
			table.insert(badFonts, d:GetFullName())
		end
	end
end
T.check(#badFonts == 0, "HERO BOARD labels must be FredokaOne with TextScaled + TextWrapped: %s", list(badFonts))

-- 4. four tabs + four pages (10 hidden rows each, an Empty label), only NETWORTH visible by default
local problems = {}
for index, spec in ipairs(STATS) do
	local stat = spec[1]
	local tab = H.path(root, "Tabs/Tab_" .. stat)
	local page = H.path(root, "List/Pages/Page_" .. stat)
	if not (tab and page) then
		table.insert(problems, stat .. ": tab / page missing")
		continue
	end
	local caption = tab:FindFirstChild("Caption")
	if tab:GetAttribute("LeaderboardStat") ~= stat or typeof(tab:GetAttribute("OnColor")) ~= "Color3" or typeof(tab:GetAttribute("OffColor")) ~= "Color3"
		or not (caption and string.gsub(caption.Text, "\n", " ") == spec[2]) or tab:FindFirstChild("Icon") == nil
		or H.path(root, "Tabs/Pointer_" .. stat) == nil then
		table.insert(problems, stat .. ": tab attributes / caption / icon / pointer")
	end
	local header = H.path(page, "Header/Title")
	if page:GetAttribute("LeaderboardStat") ~= stat or page.Visible ~= (stat == "Networth") or not (header and header.Text == spec[2]) then
		table.insert(problems, stat .. ": page attribute / default visibility / header")
	end
	-- the podium sign and plate colour follow the selected page (HeroBoard client)
	if page:GetAttribute("LeaderboardTitle") ~= spec[2] or typeof(page:GetAttribute("ValueColor")) ~= "Color3" then
		table.insert(problems, stat .. ": page LeaderboardTitle / ValueColor for the podium")
	end
	local rows = 0
	for i = 1, 10 do
		local row = page:FindFirstChild(string.format("Row%02d", i))
		if row and not row.Visible and H.path(row, "Rank/Label") and row:FindFirstChild("Avatar") and row:FindFirstChild("PlayerName") and row:FindFirstChild("Value") then
			rows += 1
		end
	end
	local empty = page:FindFirstChild("Empty")
	if rows ~= 10 or not (empty and empty:IsA("TextLabel") and empty.Visible) then
		table.insert(problems, string.format("%s: %d/10 hidden rows (Rank.Label, Avatar, PlayerName, Value), Empty label", stat, rows))
	end
	local _ = index
end
T.check(#problems == 0, "HERO BOARD tabs / pages: %s", list(problems))

-- 5. one invisible click part + ClickDetector laid exactly over each tab, just in front of the screen face
-- GUI rect of a node in canvas pixels (scale layout; UIAspectRatio / RelativeYY not used on the tab path)
local function rectOf(node, canvasW, canvasH)
	if node == gui then
		return 0, 0, canvasW, canvasH
	end
	local px, py, pw, ph = rectOf(node.Parent, canvasW, canvasH)
	local w = node.Size.X.Scale * pw + node.Size.X.Offset
	local h = node.Size.Y.Scale * ph + node.Size.Y.Offset
	return px + node.Position.X.Scale * pw + node.Position.X.Offset - node.AnchorPoint.X * w,
		py + node.Position.Y.Scale * ph + node.Position.Y.Offset - node.AnchorPoint.Y * h, w, h
end
local hits = {}
local hitFolder = board:FindFirstChild("TabButtons")
for _, spec in ipairs(STATS) do
	local stat = spec[1]
	local part = hitFolder and hitFolder:FindFirstChild("TabHit_" .. stat)
	local detector = part and part:FindFirstChildOfClass("ClickDetector")
	local tab = H.path(root, "Tabs/Tab_" .. stat)
	if not (part and part:IsA("BasePart") and detector and tab) then
		table.insert(hits, stat .. ": TabHit part / ClickDetector missing")
		continue
	end
	if not (part.Transparency >= 1 and not part.CanCollide and part.CanQuery and part.Anchored and part:GetAttribute("LeaderboardStat") == stat
		and detector.MaxActivationDistance >= 40) then
		table.insert(hits, stat .. ": must be invisible, non-collidable, queryable, anchored, LeaderboardStat, reach >= 40")
	end
	-- the part's front face projected onto the screen canvas vs the tab's GUI rect (1 stud = PixelsPerStud px)
	local pps = gui.PixelsPerStud
	local cw, ch = screen.Size.X * pps, screen.Size.Y * pps
	local tx, ty, tw, th = rectOf(tab, cw, ch)
	local u0, v0, u1, v1 = math.huge, math.huge, -math.huge, -math.huge
	local depth = -math.huge
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local p = part.CFrame * V3.new(sx * part.Size.X / 2, sy * part.Size.Y / 2, sz * part.Size.Z / 2)
				local lp = screen.CFrame:PointToObjectSpace(p)
				local u, v = (screen.Size.X / 2 - lp.X) * pps, (screen.Size.Y / 2 - lp.Y) * pps
				u0, u1, v0, v1 = math.min(u0, u), math.max(u1, u), math.min(v0, v), math.max(v1, v)
				depth = math.max(depth, lp.Z)
			end
		end
	end
	local tol = 0.1 * pps
	local face = -screen.Size.Z / 2
	if math.abs(u0 - tx) > tol or math.abs(u1 - (tx + tw)) > tol or math.abs(v0 - ty) > tol or math.abs(v1 - (ty + th)) > tol then
		table.insert(hits, string.format("%s: hit box %d,%d..%d,%d vs tab %d,%d..%d,%d px", stat, u0, v0, u1, v1, tx, ty, tx + tw, ty + th))
	end
	if not (depth < face and depth > face - 0.6) then
		table.insert(hits, string.format("%s: hit part must sit just in front of the screen face (back %.2f, face %.2f)", stat, depth, face))
	end
end
T.check(#hits == 0, "HERO BOARD tab click parts: %s", list(hits))

-- 6. the podium: 1st centre (tallest, gold), 2nd on the viewer's LEFT, 3rd on the viewer's RIGHT, off the wall
local pod = {}
if T.check(podium ~= nil and podium:GetAttribute("PodiumStat") == "Networth" and podium:GetAttribute("PodiumFollowsTab") == true,
	"HeroBoard.Podium (PodiumStat Networth, PodiumFollowsTab) missing") then
	local viewer = -screen.CFrame.LookVector -- a player facing the board looks this way
	local right = viewer:Cross(V3.new(0, 1, 0)).Unit
	local centre = screen.CFrame.Position
	local pmn, pmx = nil, nil
	for _, d in ipairs(podium:GetDescendants()) do
		if d:IsA("BasePart") then
			local a, b = H.aabb(d)
			pmn, pmx = grow(pmn, pmx, a, b)
		end
	end
	local spots = {}
	for rank = 1, 3 do
		local spot = podium:FindFirstChild("Spot" .. rank)
		local tier = spot and spot:FindFirstChild("Tier")
		local top = spot and spot:FindFirstChild("TierTop")
		local stand = spot and spot:FindFirstChild("Stand")
		local plate = spot and H.path(spot, "FrontFace/NamePlate")
		local name = plate and plate:FindFirstChild("PlayerName", true)
		local value = plate and plate:FindFirstChild("Value", true)
		local ordinal = plate and plate:FindFirstChild("Ordinal", true)
		if not (tier and top and stand and plate and name and value and ordinal) then
			table.insert(pod, "Spot" .. rank .. " incomplete (Tier, TierTop, Stand, FrontFace.NamePlate > Ordinal / PlayerName / Value)")
			continue
		end
		local _, tmx = H.aabb(top)
		local sp = stand.CFrame.Position
		spots[rank] = { top = tmx.Y, along = (sp - centre):Dot(right), stand = stand }
		if not (tier.Anchored and tier.CanCollide and top.CanCollide) then
			table.insert(pod, "Spot" .. rank .. " tier must be anchored and solid")
		end
		if not (stand.Transparency >= 1 and not stand.CanCollide and not stand.CanQuery and math.abs((sp.Y - stand.Size.Y / 2) - tmx.Y) < 0.02
			and stand.CFrame.LookVector:Dot(screen.CFrame.LookVector) > 0.95) then
			table.insert(pod, "Spot" .. rank .. " Stand must be an invisible anchor on the tier top facing the hub")
		end
		if name.Text ~= "???" or value.Text ~= "" or not (plate:IsA("SurfaceGui") and plate.Face == Enum.NormalId.Front and plate.LightInfluence == 0) then
			table.insert(pod, "Spot" .. rank .. " plate must show ??? until LeaderboardService fills it")
		end
	end
	if spots[1] and spots[2] and spots[3] then
		if not (spots[1].top > spots[2].top + 0.3 and spots[2].top > spots[3].top + 0.3) then
			table.insert(pod, string.format("tier heights must be 1st > 2nd > 3rd (%.2f, %.2f, %.2f)", spots[1].top, spots[2].top, spots[3].top))
		end
		if not (spots[2].along < spots[1].along - 3 and spots[3].along > spots[1].along + 3 and math.abs(spots[1].along) < 0.5) then
			table.insert(pod, string.format("1st must stand centred, 2nd on the viewer's left, 3rd on the right (%.1f / %.1f / %.1f)", spots[1].along,
				spots[2].along, spots[3].along))
		end
		-- room for a ~6-stud avatar on the 1st tier under the screen's bottom edge
		local screenBottom = centre.Y - screen.Size.Y / 2
		if screenBottom - spots[1].top < 6 then
			table.insert(pod, string.format("screen bottom %.1f leaves %.1f studs over the 1st tier: avatars would cover the rows", screenBottom,
				screenBottom - spots[1].top))
		end
	end
	if pmn and not ownerPlaced and not (pmx.X <= WALL_FACE_X - 2 and pmn.X >= REGION.xMin and pmn.Z >= REGION.zMin and pmx.Z <= REGION.zMax and pmx.Z < LANE_MOUTH[1]) then
		table.insert(pod, string.format("podium must stand a few studs off the wall inside the region (X %.1f..%.1f Z %.1f..%.1f)", pmn.X, pmx.X, pmn.Z, pmx.Z))
	end
	-- never a limb-named part on the podium (avatars only appear at runtime)
	for _, d in ipairs(podium:GetDescendants()) do
		if d:IsA("Humanoid") or d.Name == "HumanoidRootPart" or d.Name == "UpperTorso" then
			table.insert(pod, "baked avatar part " .. d:GetFullName())
			break
		end
	end
end
T.check(#pod == 0, "HERO BOARD podium: %s", list(pod))

-- 7. scripts: server fills pages + podium avatars, client switches pages; both injected and compiling
local service = sss:FindFirstChild("LeaderboardService")
local client = sps and H.path(sps, "Game/HeroBoard")
local manifest = H.fs.readFile("scripts/inject/leaderboards.luau")
if T.check(service ~= nil and service:IsA("Script") and client ~= nil and client:IsA("LocalScript") and H.has(manifest, "Game/HeroBoard")
	and H.has(manifest, "HeroBoard.client.luau"),
	"ServerScriptService.LeaderboardService (Script) and StarterPlayerScripts.Game.HeroBoard (LocalScript) must be injected") then
	local src, csrc = H.normalize(service.Source), H.normalize(client.Source)
	T.check(pcall(H.luau.compile, src) and pcall(H.luau.compile, csrc), "LeaderboardService / HeroBoard client must compile")
	T.check(H.has(src, "WaitForChild(\"HeroBoard\"") and H.has(src, "GetHumanoidDescriptionFromUserId") and H.has(src, "CreateHumanoidModelFromDescription")
		and H.has(src, "Enum.HumanoidRigType.R15") and H.has(src, "IsCollisionGroupRegistered") and H.has(src, "NPC_COLLISION_GROUP = \"NPCs\"")
		and H.has(src, "root.Anchored = true") and H.has(src, "d.CanCollide = false") and H.has(src, "DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None")
		and H.has(src, "mergedTop(stat, PODIUM_SIZE, live)") and H.has(src, "AVATAR_RETRY_SECONDS") and H.has(src, "motor.C0 = if rotation then base * rotation else base")
		and H.has(src, "RightShoulder") and H.has(src, "\"???\""),
		"LeaderboardService must stand every page's top 3 as posed R15 avatars (description + model APIs, anchored, NPCs group, no collisions, ??? plates)")
	-- owner 2026-09-27: the podium changes with the tabs (every page's set tagged PodiumStat, plates as Spot attributes the
	-- client writes; the server never writes a plate label nor hides an avatar)
	T.check(H.has(src, "SetAttribute(\"PodiumStat\", stat)") and H.has(src, "SetAttribute(\"Name_\" .. stat") and H.has(src, "SetAttribute(\"Value_\" .. stat")
		and not H.has(src, "spot.nameLabel") and not H.has(src, "LocalTransparencyModifier ="),
		"LeaderboardService must publish every page's podium (PodiumStat avatars, Name_/Value_ spot attributes) and leave the showing to the client")
	T.check(H.has(src, "Leaderboard_\" .. stat .. \"_\" .. STORE_VERSION") and H.has(src, "local STORE_VERSION = \"v1\"") and H.has(src, "math.log10(finite(value) + 1) * LOG_SCALE")
		and not H.has(src, "page.Visible") and not H.has(src, "__OBJECTS"),
		"LeaderboardService must keep the OrderedDataStore keys / log10 encoding and never switch a page (the client does)")
	T.check(H.has(csrc, "MouseClick") and H.has(csrc, "MouseHoverEnter") and H.has(csrc, "MouseHoverLeave") and H.has(csrc, "ClickDetector")
		and H.has(csrc, "page.Visible = visible") and H.has(csrc, "\"OnColor\"") and H.has(csrc, "TAP A TAB!"),
		"HeroBoard client must switch the visible page locally from the tab ClickDetectors (click, hover, touch wording)")
	T.check(H.has(csrc, "LocalTransparencyModifier") and H.has(csrc, "GetAttribute(\"PodiumStat\")") and H.has(csrc, "\"Name_\" .. selected")
		and H.has(csrc, "LeaderboardTitle") and H.has(csrc, "CYCLE_SECONDS") and H.has(csrc, "IDLE_SECONDS") and H.has(csrc, "applyPodium(pages[selected])"),
		"HeroBoard client must show the selected tab's podium (avatars, plates, sign) and auto-cycle the tabs while idle")
end
