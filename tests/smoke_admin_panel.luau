--!nocheck
-- tests/smoke_admin_panel.luau (owner 2026-09-27: "an admin panel for the devs ... blocky like everything, pretty, not
-- AI-looking, no emojis; only user 767108248, the owners or people with Studio access; the icon in the topbar next to
-- Backpack and Settings, as 3D art"; round 12: economy and weapons as tabs inside the player section, wipe a player's
-- data, Taco Rain in every server, global announcements). Joins the "smoke" filter. Checks, against the built place:
--   1. the panel is ServerStorage.HeroAdminPanel (never StarterGui), a ScreenGui with ResetOnSpawn off, disabled, in the
--      ui_kit look (studded dark body, glossy band, SpTitle "ADMIN PANEL", the round X art, glossy buttons, square
--      corners, the stud texture only), the 5 tabs / pages (PLAYER, DUMMIES, EGGS, WORLD, SERVER), the PLAYER sub-tabs /
--      sub-pages (ACTIONS, ECONOMY, WEAPONS, DATA), the target bar (only on the tabs that use a target) and the toast;
--   2. every button's Command has a handler in HeroAdminService.COMMANDS (and every handler but Inspect a button), its
--      Arg* attributes are plain strings / numbers, every other GuiButton is a Tab / SubTab / Control the client wires
--      (no orphan button), every touch target is >= 62 design px tall (>= 44 px on a phone), the wipe / all-server /
--      self buttons carry their guards;
--   3. no text of the panel (labels, captions, attributes) and none of its scripts holds a non-ASCII character (emoji);
--   4. the 3D crown: ViewportFrame Crown3D with a Camera and a part-built model, anchored, no Neon;
--   5. the scripts are injected and compile: HeroAdminAccess (767108248, the owner and Studio checks), the Branch
--      services (remote, rate limit, log line, dummies, the cross-server topic, the text filter), the client (TopbarPlus
--      icon, viewport art, the remote), the announcement controller, and the remotes;
--   6. behaviour in a sandbox: the access rule (Studio / 767108248 / user owner / group owner rank 255 / others), and the
--      service's remote gate (non-admin refused and warned, rate limit, unknown command, bad target, bad arguments);
--   7. layout: for every tab the visible pieces (target bar, page, toast) never overlap and stay inside the content box;
--      inside every page / card nothing overlaps its siblings or leaves its parent (canvas included); phone fit;
--   8. the wipe: Library.Database.WipeProfile (the real module in a sandbox) resets a loaded profile to exactly a new
--      player's, saves it, and a stale write before the leave save never comes back; HeroAdminService.WipeData needs
--      the confirmed target id, kicks with the message, clears the leaderboards afterwards, is rate limited and refused
--      without access;
--   9. cross-server (HeroBroadcastService, sandboxed): an admin's publish, receiving runs the handler once (own echo /
--      duplicates / malformed payloads ignored, durations clamped), the MessagingService fallback, the announcement text
--      filtered (TextService) before any broadcast; HeroAdminService's all-server Taco Rain and Announce commands;
--  10. announcements: StarterGui.HeroAnnouncements (the banner) and BranchControllers.AnnouncementController (queue,
--      sanitising, durations) in a sandbox.

local place = H.place()
local roblox = H.roblox
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local ss = place:GetService("ServerStorage")
local starterGui = place:GetService("StarterGui")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end
local function first(list)
	return table.concat(list, ", ", 1, math.min(#list, 5))
end
local function compiles(inst)
	return inst ~= nil and pcall(H.luau.compile, src(inst))
end

-- 1. the window --------------------------------------------------------------------------------------------------
local gui = ss:FindFirstChild("HeroAdminPanel")
T.check(starterGui:FindFirstChild("HeroAdminPanel") == nil, "the admin panel must never be in StarterGui (non-admins would receive it)")
if not T.check(gui ~= nil and gui:IsA("ScreenGui"), "ServerStorage.HeroAdminPanel (ScreenGui) missing") then
	return
end
T.check(gui.ResetOnSpawn == false and gui.Enabled == false and gui.ScreenInsets == roblox.Enum.ScreenInsets.None,
	"HeroAdminPanel must be ResetOnSpawn off, disabled until opened, ScreenInsets None (IgnoreGuiInset)")
local window = gui:FindFirstChild("Window")
if not T.check(window ~= nil and window:IsA("Frame"), "HeroAdminPanel.Window missing") then
	return
end
local scale = window:FindFirstChild("SpPanelScale")
T.check(scale ~= nil and scale:IsA("UIScale"), "Window.SpPanelScale (the client's screen fit) missing")

local studs = window:FindFirstChild("SpStuds")
T.check(studs ~= nil and H.imageId(studs) == 6927295847 and studs.ImageTransparency <= 0.621, "the window body must carry the visible stud texture")
local bg = window:FindFirstChild("SpBackground")
T.check(bg == nil or bg.ImageTransparency >= 1, "the window art under the studs must be hidden (stud texture only)")
local band = window:FindFirstChild("SpHeaderBand")
T.check(band ~= nil and band:FindFirstChild("SpBandGradient") ~= nil and band:FindFirstChild("SpStuds") ~= nil and band:FindFirstChild("SpGloss") ~= nil,
	"the glossy header band (gradient, studs, gloss) missing")
local ink = window:FindFirstChild("SpStroke")
T.check(ink ~= nil and ink:IsA("UIStroke") and ink.Color == roblox.Color3.fromRGB(11, 27, 61), "the window's ink rim (SpStroke #0b1b3d) missing")
local title = window:FindFirstChild("SpTitle")
T.check(title ~= nil and title:IsA("TextLabel") and title.Text == "ADMIN PANEL", "the band title SpTitle 'ADMIN PANEL' missing")
local close = window:FindFirstChild("Close")
local closeArt = close and close:FindFirstChild("TextButton")
T.check(close ~= nil and close:IsA("GuiButton") and closeArt ~= nil and closeArt:IsA("ImageLabel") and H.imageId(closeArt) == 110882579806743
	and closeArt.ImageTransparency == 0 and closeArt.ImageColor3 == roblox.Color3.new(1, 1, 1),
	"the round red close must draw the bright X art 110882579806743 on its TextButton glyph (like the Index window)")
local emboss = close and close:FindFirstChild("SpEmboss")
T.check(closeArt ~= nil and (emboss == nil or emboss.ZIndex < closeArt.ZIndex) and close:FindFirstChild("SpCloseArt") == nil,
	"the close's dark emboss disc must sit UNDER the X (it dimmed it: owner round 10)")

local rounded, nonStud = {}, {}
local NON_STUD = { [116054484875156] = true, [86655919544454] = true, [130029461460330] = true, [118133511364596] = true,
	[123051839615959] = true, [117164658961906] = true, [125961309868308] = true, [106477372921851] = true }
local zero = roblox.UDim.new(0, 0)
for _, d in ipairs(gui:GetDescendants()) do
	if d:IsA("UICorner") and (d.TopLeftRadius ~= zero or d.TopRightRadius ~= zero or d.BottomLeftRadius ~= zero or d.BottomRightRadius ~= zero) then
		table.insert(rounded, d:GetFullName())
	elseif (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.ImageTransparency < 1 and NON_STUD[H.imageId(d) or 0] then
		table.insert(nonStud, d:GetFullName())
	end
end
T.check(#rounded == 0, "every corner of the panel must be square: %s", first(rounded))
T.check(#nonStud == 0, "no texture but the studs on the panel: %s", first(nonStud))

-- round 12 (owner 2026-09-27: "the economy and weapons parts can go in a tab inside the players section"): 5 top tabs,
-- the PLAYER section holds its sub-tabs, the target bar only where buttons act on the target
local tabs = window:FindFirstChild("Tabs")
local content = window:FindFirstChild("Content")
local pages = H.path(window, "Content/Pages")
local TABS = { "Player", "Dummies", "Eggs", "World", "Server" }
local USES_TARGET = { Player = true, Eggs = true }
local tabCount = 0
for _, d in ipairs(tabs and tabs:GetChildren() or {}) do
	if d:IsA("GuiButton") then
		tabCount += 1
	end
end
T.check(tabCount == #TABS, "the tab column must hold exactly the %d tabs (found %d)", #TABS, tabCount)
for _, id in ipairs(TABS) do
	local tab = tabs and tabs:FindFirstChild("Tab_" .. id)
	local page = pages and pages:FindFirstChild("Page_" .. id)
	T.check(tab ~= nil and tab:IsA("GuiButton") and tab:GetAttribute("Tab") == id and tab:FindFirstChild("SpFill") ~= nil,
		"glossy tab Tab_%s missing", id)
	T.check(tab ~= nil and (tab:GetAttribute("UsesTarget") == true) == (USES_TARGET[id] == true),
		"Tab_%s: UsesTarget must be %s (the target bar shows only where buttons act on the target)", id, tostring(USES_TARGET[id] == true))
	local kind = if id == "Player" then "Frame" else "ScrollingFrame"
	T.check(page ~= nil and page.ClassName == kind and page:GetAttribute("Tab") == id, "page Page_%s (%s) missing", id, kind)
	T.check(page ~= nil and page.Visible == (id == "Player"), "only the first page (PLAYER) may start visible (Page_%s)", id)
end
for _, old in ipairs({ "Weapons", "Economy" }) do
	T.check(tabs and tabs:FindFirstChild("Tab_" .. old) == nil and pages and pages:FindFirstChild("Page_" .. old) == nil,
		"WEAPONS / ECONOMY moved into PLAYER: Tab_%s / Page_%s must be gone", old, old)
end
local playerPage = pages and pages:FindFirstChild("Page_Player")
local subTabs = playerPage and playerPage:FindFirstChild("SubTabs")
local subPages = playerPage and playerPage:FindFirstChild("SubPages")
local SUB_TABS = { "Actions", "Economy", "Weapons", "Data" }
T.check(subTabs ~= nil and subTabs:GetAttribute("Selected") == "Actions" and subPages ~= nil,
	"Page_Player must hold the SubTabs strip (Selected = Actions) and SubPages")
for _, id in ipairs(SUB_TABS) do
	local tab = subTabs and subTabs:FindFirstChild("SubTab_" .. id)
	local page = subPages and subPages:FindFirstChild("SubPage_" .. id)
	T.check(tab ~= nil and tab:IsA("GuiButton") and tab:GetAttribute("SubTab") == id and tab:FindFirstChild("SpFill") ~= nil,
		"glossy sub-tab SubTab_%s missing", id)
	T.check(page ~= nil and page:IsA("ScrollingFrame") and page:GetAttribute("SubTab") == id and page.Visible == (id == "Actions"),
		"sub-page SubPage_%s missing (only ACTIONS starts visible)", id)
end
for _, path in ipairs({ "Content/TargetBar/Prev", "Content/TargetBar/Next", "Content/TargetBar/Me", "Content/TargetBar/TargetCard/PlayerName",
	"Content/TargetBar/TargetCard/Count", "Content/Toast/Text", "Content/Toast/Dot", "ModeBadge/Text", "DragHandle" }) do
	T.check(H.path(window, path) ~= nil, "Window.%s missing", path)
end
local caption = H.path(window, "Content/TargetBar/TargetCard/Caption")
T.check(caption ~= nil and caption.Text == "TARGET PLAYER", "the target card must say TARGET PLAYER (the selector must be obvious)")

-- the header row: the close sits fully inside the band, above the rest of the header, and nothing overlaps it (owner
-- round 10: "the X covers something")
local function rect(node)
	-- design px (every header node is placed in offsets, or in scale of the 820 x 500 window)
	local w = node.Size.X.Scale * 820 + node.Size.X.Offset
	local h = node.Size.Y.Scale * 500 + node.Size.Y.Offset
	local x = node.Position.X.Scale * 820 + node.Position.X.Offset - node.AnchorPoint.X * w
	local y = node.Position.Y.Scale * 500 + node.Position.Y.Offset - node.AnchorPoint.Y * h
	return { x = x, y = y, w = w, h = h }
end
local function overlaps(a, b)
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
local bandNode, badge = window:FindFirstChild("SpHeaderBand"), window:FindFirstChild("ModeBadge")
local drag, crown3d = window:FindFirstChild("DragHandle"), window:FindFirstChild("Crown3D")
if T.check(close and bandNode and badge and drag and crown3d and title, "header nodes missing") then
	local c, b = rect(close), rect(bandNode)
	local rim = 0.07 * c.w + 1 -- the close's ink rim (ScaledSize) spills out of its box
	T.check(c.x - rim >= b.x + 4 and c.x + c.w + rim <= b.x + b.w - 4 and c.y - rim >= b.y + 2 and c.y + c.h + rim <= b.y + b.h - 2,
		"the close (%.0f,%.0f %.0fx%.0f) must sit fully inside the band (%.0f,%.0f %.0fx%.0f) with its rim", c.x, c.y, c.w, c.h, b.x, b.y, b.w, b.h)
	T.check(c.w >= 44, "the close must stay a >= 44 px touch target (%.0f)", c.w)
	local clashes = {}
	for _, other in ipairs({ badge, drag, crown3d, title }) do
		if overlaps(c, rect(other)) then
			table.insert(clashes, "close/" .. other.Name)
		end
	end
	for _, other in ipairs({ drag, crown3d, title }) do
		if overlaps(rect(badge), rect(other)) then
			table.insert(clashes, "ModeBadge/" .. other.Name)
		end
	end
	T.check(#clashes == 0, "header overlaps: %s", table.concat(clashes, ", "))
	local topZ = 0
	for _, other in ipairs({ bandNode, badge, drag, crown3d, title }) do
		topZ = math.max(topZ, other.ZIndex)
	end
	T.check(close.ZIndex > topZ, "the close must be drawn above the header (ZIndex %d vs %d)", close.ZIndex, topZ)
end

-- PLAYER > ECONOMY: an amount box + GIVE / TAKE for money and for speed (owner round 10)
local economy = subPages and subPages:FindFirstChild("SubPage_Economy")
for _, spec in ipairs({ { "MoneyAmount", "GiveMoney", "TakeMoney" }, { "SpeedAmount", "GiveSpeed", "TakeSpeed" } }) do
	local box = economy and economy:FindFirstChild(spec[1], true)
	T.check(box ~= nil and box:IsA("TextBox") and box:GetAttribute("AmountInput") == true and box.ClearTextOnFocus == false
		and box:GetAttribute("ArgName") == "Amount", "SubPage_Economy.%s must be an amount TextBox", spec[1])
	for i = 2, 3 do
		local b = economy and economy:FindFirstChild(spec[i])
		T.check(b ~= nil and b:IsA("GuiButton") and b:GetAttribute("Command") == spec[i] and b:GetAttribute("InputFrom") == spec[1],
			"SubPage_Economy.%s must send the text of %s", spec[i], spec[1])
	end
end
T.check(economy ~= nil and economy:FindFirstChild("AddMoney1K") == nil, "the fixed +1K / +100K / +10M buttons must be gone")
local clientSource = H.normalize(gui:FindFirstChild("HeroAdminClient") and gui.HeroAdminClient.Source or "")
T.check(H.has(clientSource, "FocusLost:Connect(function(enterPressed)") and H.has(clientSource, 'args.Amount = string.sub(box.Text, 1, 32)'),
	"the client must send the typed amount and submit GIVE on Enter")

-- 2. commands -----------------------------------------------------------------------------------------------------
local service = H.path(sss, "BranchServices/HeroAdminService")
local serviceSrc = src(service)
local handlers = {}
for name in string.gmatch(serviceSrc, "\nCOMMANDS%.(%w+) = function") do
	handlers[name] = true
end
local used, missing, badArgs, small, flat, orphans = {}, {}, {}, {}, {}, {}
local CONTROLS = { Target = true, Scope = true, Close = true, Drag = true }
local buttons = 0
local byName = {}
for _, d in ipairs(gui:GetDescendants()) do
	local command = d:GetAttribute("Command")
	if command ~= nil then
		buttons += 1
		used[command] = true
		byName[d.Name] = d
		if not handlers[command] then
			table.insert(missing, d.Name .. ":" .. tostring(command))
		end
		for key, value in pairs(d:GetAttributes()) do
			if string.sub(key, 1, 3) == "Arg" and type(value) ~= "string" and type(value) ~= "number" then
				table.insert(badArgs, d.Name .. "." .. key)
			end
		end
		if not d:IsA("GuiButton") then
			table.insert(flat, d.Name)
		end
	end
	if d:IsA("GuiButton") then
		local control = d:GetAttribute("Control")
		if command == nil and d:GetAttribute("Tab") == nil and d:GetAttribute("SubTab") == nil and not CONTROLS[control] then
			table.insert(orphans, d:GetFullName())
		end
		if d.Name ~= "DragHandle" and d.Name ~= "Close" and d.Size.Y.Offset < 62 then
			table.insert(small, d.Name .. " " .. tostring(d.Size.Y.Offset))
		end
	end
end
T.check(buttons >= 50, "the panel must hold its command buttons (found %d)", buttons)
T.check(#missing == 0, "buttons whose command has no handler in HeroAdminService.COMMANDS: %s", first(missing))
T.check(#badArgs == 0 and #flat == 0, "command attributes must sit on GuiButtons with string / number args: %s %s", first(badArgs), first(flat))
T.check(#small == 0, "touch targets must be >= 62 design px tall (>= 44 px at the phone fit): %s", first(small))
T.check(#orphans == 0, "every GuiButton must be a command, a tab, a sub-tab or a wired control (orphans: %s)", first(orphans))
T.check(H.has(clientSource, 'GetAttribute("Control") == "Scope"') and H.has(clientSource, "Prev = function()")
	and H.has(clientSource, "Next = function()") and H.has(clientSource, "Me = function()") and H.has(clientSource, "close.Activated:Connect")
	and H.has(clientSource, 'drag = window:FindFirstChild("DragHandle")') and H.has(clientSource, 'type(tab:GetAttribute("SubTab")) == "string"'),
	"the client must wire every control (target arrows / ME, the scope toggle, close, drag) and the sub-tabs")
local unused = {}
for name in pairs(handlers) do
	if name ~= "Inspect" and not used[name] then
		table.insert(unused, name)
	end
end
table.sort(unused)
T.check(#unused == 0, "every command must have a button: %s", first(unused))
for _, name in ipairs({ "GiveAllWeapons", "GiveWeapon", "RemoveDevWeapons", "UnlockIndexWeapons", "GiveMoney", "TakeMoney", "ResetMoney",
	"GiveSpeed", "TakeSpeed", "TacoRainStart", "TacoRainStop", "Announce", "WipeData",
	"SetSpeed", "GiveEgg", "GrowEggs", "Teleport", "NightNow", "DayNow", "NormalCycle", "UnlockBaseThemes", "Release", "Respawn", "Heal",
	"GoTo", "Bring", "SpawnDummy", "ClearDummies", "Inspect" }) do
	T.check(handlers[name] == true, "HeroAdminService.COMMANDS.%s missing", name)
end
-- where every command lives now (the owner's layout)
local HOME = {
	Release = "SubPage_Actions", Respawn = "SubPage_Actions", Heal = "SubPage_Actions", GoTo = "SubPage_Actions", Bring = "SubPage_Actions",
	UnlockBaseThemes = "SubPage_Actions", GiveMoney = "SubPage_Economy", TakeMoney = "SubPage_Economy", ResetMoney = "SubPage_Economy",
	GiveSpeed = "SubPage_Economy", TakeSpeed = "SubPage_Economy", SetSpeed = "SubPage_Economy", GiveAllWeapons = "SubPage_Weapons",
	UnlockIndexWeapons = "SubPage_Weapons", RemoveDevWeapons = "SubPage_Weapons", GiveWeapon = "SubPage_Weapons", WipeData = "SubPage_Data",
	SpawnDummy = "Page_Dummies", ClearDummies = "Page_Dummies", GiveEgg = "Page_Eggs", GrowEggs = "Page_Eggs",
	TacoRainStart = "Page_World", TacoRainStop = "Page_World", Teleport = "Page_World", NightNow = "Page_World", DayNow = "Page_World",
	NormalCycle = "Page_World", Announce = "Page_Server",
}
local misplaced = {}
for command, home in pairs(HOME) do
	local found = false
	for _, d in ipairs(gui:GetDescendants()) do
		if d:GetAttribute("Command") == command then
			local node = d.Parent
			while node and node ~= gui do
				if node.Name == home then
					found = true
				end
				node = node.Parent
			end
		end
	end
	if not found then
		table.insert(misplaced, command .. " -> " .. home)
	end
end
table.sort(misplaced)
T.check(#misplaced == 0, "commands missing from their section: %s", first(misplaced))
local weaponCards = 0
for _, d in ipairs((subPages and subPages:FindFirstChild("SubPage_Weapons") or gui):GetChildren()) do
	if d:GetAttribute("Command") == "GiveWeapon" then
		weaponCards += 1
	end
end
T.check(weaponCards == 7, "the 7 hero weapons must each have a card in PLAYER > WEAPONS (found %d)", weaponCards)
-- the guards the buttons carry
local wipe = byName.WipeData
T.check(wipe ~= nil and wipe:GetAttribute("Confirm") == true and wipe:GetAttribute("ConfirmText") == "CONFIRM WIPE %s"
	and wipe:GetAttribute("ConfirmSeconds") == 4 and wipe:GetAttribute("SendTargetId") == true,
	"WIPE ALL DATA must need a second tap ('CONFIRM WIPE <name>' for 4 s) and send the confirmed target id")
local announceAll, announceServer = byName.AnnounceAll, byName.AnnounceServer
T.check(announceAll ~= nil and announceAll:GetAttribute("ArgScope") == "All" and announceAll:GetAttribute("Confirm") == true
	and announceAll:GetAttribute("InputFrom") == "AnnouncementText" and announceServer ~= nil and announceServer:GetAttribute("ArgScope") == "Server"
	and announceServer:GetAttribute("InputFrom") == "AnnouncementText", "SERVER must send the announcement box to this server / (two taps) all servers")
local announceBox = pages and pages:FindFirstChild("AnnouncementText", true)
T.check(announceBox ~= nil and announceBox:IsA("TextBox") and announceBox:GetAttribute("ArgName") == "Text" and announceBox:GetAttribute("MaxChars") == 150
	and announceBox:GetAttribute("AmountInput") == nil, "the announcement box must send Text, 150 characters at most, and never submit on Enter")
local scopeFrame = pages and H.path(pages, "Page_World/EventScope")
T.check(scopeFrame ~= nil and scopeFrame:GetAttribute("Selected") == "Server" and scopeFrame:FindFirstChild("ScopeServer") ~= nil
	and scopeFrame.ScopeServer:GetAttribute("ScopeValue") == "Server" and scopeFrame:FindFirstChild("ScopeAll") ~= nil
	and scopeFrame.ScopeAll:GetAttribute("ScopeValue") == "All", "WORLD must hold the scope toggle THIS SERVER / ALL SERVERS (default this server)")
local scoped = 0
for _, name in ipairs({ "TacoRain60", "TacoRain90", "TacoRainStop" }) do
	if byName[name] and byName[name]:GetAttribute("ScopeFrom") == "EventScope" then
		scoped += 1
	end
end
T.check(scoped == 3, "the Taco Rain buttons must obey the scope toggle (ScopeFrom = EventScope): %d / 3", scoped)
T.check(byName.GiveMeWeapons ~= nil and byName.GiveMeWeapons:GetAttribute("TargetSelf") == true, "DUMMIES' ARM YOURSELF must act on the caller")
T.check(H.has(clientSource, "args.ConfirmUserId = targetPlayer().UserId") and H.has(clientSource, "args.Scope = scope")
	and H.has(clientSource, 'button:GetAttribute("TargetSelf") == true then nil else targetUserId') and H.has(clientSource, "cancelConfirms()")
	and H.has(clientSource, "targetBar.Visible = usesTarget"), "the client must send the confirmed id, the scope, act on self and hide the bar")

-- 3. ASCII only ---------------------------------------------------------------------------------------------------
local nonAscii = {}
local function scan(label, value)
	if type(value) == "string" and string.find(value, "[\128-\255]") then
		table.insert(nonAscii, label)
	end
end
local banner = starterGui:FindFirstChild("HeroAnnouncements")
for _, root in ipairs({ gui, banner }) do
	for _, d in ipairs({ root, table.unpack(root and root:GetDescendants() or {}) }) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			scan(d:GetFullName(), d.Text)
			if d:IsA("TextBox") then
				scan(d:GetFullName() .. ".PlaceholderText", d.PlaceholderText)
			end
		elseif d:IsA("StringValue") then
			scan(d:GetFullName(), d.Value)
		end
		for key, value in pairs(d:GetAttributes()) do
			scan(d:GetFullName() .. "@" .. key, value)
		end
	end
end
local client = gui:FindFirstChild("HeroAdminClient")
local access = sss:FindFirstChild("HeroAdminAccess")
local broadcastModule = H.path(sss, "BranchServices/HeroBroadcastService")
local announcementModule = sps and H.path(sps, "BranchControllers/AnnouncementController")
for _, script in ipairs({ client, service, access, broadcastModule, announcementModule }) do
	if script then
		scan(script:GetFullName() .. " (source)", script.Source)
	end
end
T.check(#nonAscii == 0, "the panel's / banner's texts and scripts must be plain ASCII (no emoji): %s", first(nonAscii))

-- 4. the 3D crown -------------------------------------------------------------------------------------------------
local crown = window:FindFirstChild("Crown3D")
local model = crown and crown:FindFirstChild("HeroAdminCrown")
local parts, loose, neon = 0, 0, 0
for _, d in ipairs(model and model:GetDescendants() or {}) do
	if d:IsA("BasePart") then
		parts += 1
		if not d.Anchored then
			loose += 1
		end
		if d.Material == roblox.Enum.Material.Neon then
			neon += 1
		end
	end
end
T.check(crown ~= nil and crown:IsA("ViewportFrame") and crown:FindFirstChildOfClass("Camera") ~= nil and model ~= nil and parts >= 40,
	"Window.Crown3D must be a ViewportFrame with a Camera and the part-built crown (%d parts)", parts)
T.check(loose == 0 and neon == 0, "the crown's parts must be anchored and never Neon (%d loose, %d neon)", loose, neon)
T.check(typeof(crown and crown:GetAttribute("CrownCenter")) == "Vector3", "Crown3D must carry its orbit centre (CrownCenter)")

-- 5. scripts ------------------------------------------------------------------------------------------------------
local accessSrc = src(access)
T.check(access ~= nil and access:IsA("ModuleScript") and compiles(access), "ServerScriptService.HeroAdminAccess must be injected and compile")
T.check(H.has(accessSrc, "[767108248] = true") and H.has(accessSrc, "RunService:IsStudio()") and H.has(accessSrc, "Enum.CreatorType.User")
	and H.has(accessSrc, "player.UserId == creatorId") and H.has(accessSrc, "GetRankInGroup") and H.has(accessSrc, "GROUP_OWNER_RANK = 255"),
	"HeroAdminAccess must allow 767108248, the game's owner (user / group rank 255) and Studio")
T.check(not H.has(accessSrc, "4596856585") and not H.has(accessSrc, "ADMIN_USER_IDS"), "HeroAdminAccess must not reuse the old admin whitelists")
T.check(service ~= nil and service:IsA("ModuleScript") and compiles(service), "BranchServices.HeroAdminService must be injected and compile")
T.check(H.has(serviceSrc, 'REMOTE_NAME = "Admin: Command"') and H.has(serviceSrc, "RATE_PER_SECOND = 8")
	and H.has(serviceSrc, '"[HeroAdmin] %s %s -> %s"') and H.has(serviceSrc, "Access.IsAdmin(player)"),
	"HeroAdminService must gate Network['Admin: Command'] (admin re-check, 8/s, [HeroAdmin] log)")
T.check(H.has(serviceSrc, 'DUMMY_FOLDER = "HeroWeaponDummies"') and H.has(serviceSrc, 'DUMMY_TAG = "HeroWeaponDummy"')
	and H.has(serviceSrc, 'SetAttribute("DummyOwner"') and H.has(serviceSrc, "CreateHumanoidModelFromDescription")
	and H.has(serviceSrc, "pcall(root.SetNetworkOwner, root, nil)") and H.has(serviceSrc, "MAX_DUMMIES = 4"),
	"HeroAdminService must spawn tagged, server-owned training dummies (max 4) in Workspace.HeroWeaponDummies")
T.check(H.has(serviceSrc, 'GearName", HeroAdminService.DEV_PREFIX .. toolName') and H.has(serviceSrc, 'DEV_PREFIX = "Dev "'),
	"dev weapons must carry GearName 'Dev <tool>'")
T.check(H.has(serviceSrc, '"[HeroAdmin] WIPE %s (%d) resets the saved data of %s (%d)"') and H.has(serviceSrc, "WIPE_COOLDOWN = 15")
	and H.has(serviceSrc, 'WIPE_KICK_MESSAGE = "Your data was reset by an admin. Rejoin to start from zero."'),
	"HeroAdminService.WipeData must log, rate limit and kick with the owner's message")
-- the leaderboard stores a wipe clears are the ones those services write
local boardSrc, flappySrc = src(sss:FindFirstChild("LeaderboardService")), src(sss:FindFirstChild("FlappyService"))
T.check(H.has(boardSrc, '"Leaderboard_" .. stat .. "_" .. STORE_VERSION') and H.has(boardSrc, 'STORE_VERSION = "v1"')
	and H.has(flappySrc, 'STORE_NAME = "FlappyBest_v1"'), "LEADERBOARD_STORES must match LeaderboardService / FlappyService's store names")
local boardStats = {}
for _, d in ipairs(place:GetService("Workspace"):GetDescendants()) do
	local stat = d:GetAttribute("LeaderboardStat")
	if type(stat) == "string" and d:IsA("GuiObject") and d:FindFirstChild("Row01") then
		boardStats[stat] = true
	end
end
local unclearedStats = {}
for stat in pairs(boardStats) do
	if not H.has(serviceSrc, '"Leaderboard_' .. stat .. '_v1"') then
		table.insert(unclearedStats, stat)
	end
end
T.check(next(boardStats) ~= nil and #unclearedStats == 0, "a wipe must clear every HERO BOARD page's store (missing: %s)", first(unclearedStats))
T.check(client ~= nil and client:IsA("LocalScript") and compiles(client), "HeroAdminPanel.HeroAdminClient must be a compiling LocalScript")
local clientSrc = src(client)
T.check(H.has(clientSrc, "Modules.Packages.TopBarPlus") and H.has(clientSrc, "setOrder(ICON_ORDER)") and H.has(clientSrc, '"IconImage"')
	and H.has(clientSrc, "HeroAdminCrown3D") and H.has(clientSrc, 'REMOTE_NAME = "Admin: Command"') and H.has(clientSrc, 'ADMIN_ATTRIBUTE = "HeroAdmin"'),
	"the client must add the TopbarPlus icon with the 3D crown and invoke Network['Admin: Command']")
local remote = H.path(rs, "Network/Admin: Command")
T.check(remote ~= nil and remote:IsA("RemoteFunction"), "ReplicatedStorage.Network['Admin: Command'] must be a RemoteFunction")
local branchServer = sss:FindFirstChild("BranchServer")
T.check(branchServer ~= nil and H.has(src(branchServer), "BranchServices"), "BranchServer must start the BranchServices root the service lives in")
local broadcastSrc = src(broadcastModule)
T.check(broadcastModule ~= nil and broadcastModule:IsA("ModuleScript") and compiles(broadcastModule)
	and H.has(broadcastSrc, 'TOPIC = "HeroAdmin_Global"') and H.has(broadcastSrc, "MessagingService.SubscribeAsync")
	and H.has(broadcastSrc, "MessagingService.PublishAsync") and H.has(broadcastSrc, "FilterStringAsync")
	and H.has(broadcastSrc, "GetNonChatStringForBroadcastAsync") and H.has(broadcastSrc, "remote.OnServerEvent:Connect(function() end)"),
	"BranchServices.HeroBroadcastService must be injected: the cross-server topic, the TextService filter, a server -> client remote")
local tacoSrc = src(H.path(sss, "BranchServices/TacoRainService"))
T.check(H.has(broadcastSrc, "MIN_DURATION = " .. (string.match(tacoSrc, "MIN_DURATION = (%d+)") or "?"))
	and H.has(broadcastSrc, "MAX_DURATION = " .. (string.match(tacoSrc, "MAX_DURATION = (%d+)") or "?")),
	"HeroBroadcastService must clamp received durations like TacoRainService")
T.check(announcementModule ~= nil and announcementModule:IsA("ModuleScript") and compiles(announcementModule),
	"BranchControllers.AnnouncementController must be injected and compile")
local announceRemote = H.path(rs, "Network/Announcement: Show")
T.check(announceRemote ~= nil and announceRemote:IsA("RemoteEvent"), "ReplicatedStorage.Network['Announcement: Show'] must be a RemoteEvent")
local databaseSrc = src(H.path(sss, "Library/Database"))
T.check(H.has(databaseSrc, "function Database.WipeProfile(player)") and H.has(databaseSrc, "local payload = wipedPayloads[player]")
	and H.has(databaseSrc, "wipedPayloads[player] = nil"), "Library.Database must wipe a profile and freeze that session's saves")

-- 6. behaviour ----------------------------------------------------------------------------------------------------
local function fakeInstance(props)
	props.__instance = true
	return props
end
local sandboxTypeof = function(v)
	if type(v) == "table" and v.__instance then
		return "Instance"
	end
	return typeof(v)
end

local function loadAccess(opts)
	local playersService = fakeInstance({ Name = "Players" })
	local fakeGame = {
		CreatorId = opts.creatorId or 0,
		CreatorType = opts.creatorType or roblox.Enum.CreatorType.User,
		GetService = function(_, name)
			if name == "RunService" then
				return { IsStudio = function()
					return opts.studio == true
				end }
			end
			return playersService
		end,
	}
	local chunk, err = H.sandbox(accessSrc, { game = fakeGame, Enum = roblox.Enum, typeof = sandboxTypeof }, "HeroAdminAccess")
	if chunk == nil then
		return nil, err
	end
	local ok, module = pcall(chunk)
	return (if ok then module else nil), playersService
end

local function fakePlayer(playersService, userId, rank)
	return fakeInstance({
		Name = "P" .. tostring(userId), UserId = userId, Parent = playersService,
		IsA = function(_, class)
			return class == "Player"
		end,
		GetRankInGroup = function()
			if rank == "error" then
				error("HTTP 500")
			end
			return rank or 0
		end,
	})
end

local cases = {
	{ "Studio", { studio = true, creatorId = 1 }, 42, nil, true },
	{ "user 767108248", { creatorId = 1 }, 767108248, nil, true },
	{ "the game's owner", { creatorId = 555 }, 555, nil, true },
	{ "a stranger", { creatorId = 555 }, 42, nil, false },
	{ "an unpublished place's stranger", { creatorId = 0 }, 42, nil, false },
	{ "the owning group's owner (255)", { creatorId = 900, creatorType = roblox.Enum.CreatorType.Group }, 42, 255, true },
	{ "a group admin (254)", { creatorId = 900, creatorType = roblox.Enum.CreatorType.Group }, 42, 254, false },
	{ "a failed group read", { creatorId = 900, creatorType = roblox.Enum.CreatorType.Group }, 42, "error", false },
}
for _, case in ipairs(cases) do
	local module, playersService = loadAccess(case[2])
	if T.check(type(module) == "table" and type(module.IsAdmin) == "function", "HeroAdminAccess did not load in the sandbox: %s", tostring(playersService)) then
		local ok, result = pcall(module.IsAdmin, fakePlayer(playersService, case[3], case[4]))
		T.check(ok and result == case[5], "HeroAdminAccess.IsAdmin(%s) must be %s (got %s)", case[1], tostring(case[5]), tostring(result))
	end
end

do
	local isAdmin = true
	local now = 100
	local warnings = {}
	local fakeAccessModule = fakeInstance({ Name = "HeroAdminAccess" })
	local fakeAccess = {
		ATTRIBUTE = "HeroAdmin",
		IsAdmin = function()
			return isAdmin, "test"
		end,
		Forget = function() end,
	}
	local playersService = fakeInstance({
		Name = "Players",
		GetPlayerByUserId = function(_, id)
			return nil
		end,
		GetPlayers = function()
			return {}
		end,
	})
	local empty = fakeInstance({
		FindFirstChild = function()
			return nil
		end,
		FindFirstChildWhichIsA = function()
			return nil
		end,
		WaitForChild = function(_, name)
			return if name == "HeroAdminAccess" then fakeAccessModule else nil
		end,
	})
	local fakeGame = { GetService = function(_, name)
		return if name == "Players" then playersService else empty
	end }
	local chunk, err = H.sandbox(serviceSrc, {
		game = fakeGame, Enum = roblox.Enum, Color3 = roblox.Color3, Vector3 = roblox.Vector3, CFrame = roblox.CFrame,
		RaycastParams = { new = function()
			return {}
		end },
		typeof = sandboxTypeof,
		require = function(module)
			if module == fakeAccessModule then
				return fakeAccess
			end
			error("unexpected require")
		end,
		os = { clock = function()
			return now
		end, time = os.time },
		warn = function(message)
			table.insert(warnings, tostring(message))
		end,
		print = function() end,
	}, "HeroAdminService")
	local ok, mod = false, err
	if chunk then
		ok, mod = pcall(chunk)
	end
	if T.check(ok and type(mod) == "table" and type(mod._onInvoke) == "function", "HeroAdminService did not load in the sandbox: %s", tostring(mod)) then
		local caller = fakeInstance({ Name = "Dev", UserId = 767108248, Parent = playersService, FindFirstChildOfClass = function()
			return nil
		end })
		local function invoke(...)
			local results = table.pack(pcall(mod._onInvoke, caller, ...))
			return results[1], results[2], results[3], results[4]
		end
		local okCall, success, message = invoke("Inspect", nil, nil)
		T.check(okCall and success == true and message == "Dev", "an admin's Inspect must answer (got %s %s %s)", tostring(okCall), tostring(success), tostring(message))
		now += 1
		okCall, success, message = invoke("Warp", nil, nil)
		T.check(okCall and success == false and message == "Unknown command", "an unknown command must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("Heal", 1.5, nil)
		T.check(okCall and success == false and message == "Invalid target", "a fractional target id must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("Heal", 12345, nil)
		T.check(okCall and success == false and message == "That player is not in this server", "an absent target must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("GiveMoney", nil, { Amount = { 1 } })
		T.check(okCall and success == false and message == "Invalid arguments", "a table argument must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("GiveMoney", nil, { Amount = "-5M" })
		T.check(okCall and success == false and H.has(tostring(message), "Not an amount"), "a negative amount must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("TakeSpeed", nil, { Amount = "5Qi" })
		T.check(okCall and success == false and H.has(tostring(message), "Too big"), "an amount over the cap must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("GiveWeapon", nil, { Tool = "Admin Bat" })
		T.check(okCall and success == false and message == "Unknown weapon", "a tool outside the hero weapons must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke(string.rep("x", 40), nil, nil)
		T.check(okCall and success == false and message == "Invalid command", "an oversized command must be refused (got %s)", tostring(message))
		-- the amount parser (round 10: "a text box, with numbers and letters like 10m, 10B")
		if T.check(type(mod.ParseAmount) == "function", "HeroAdminService.ParseAmount missing") then
			local CASES = {
				{ "10m", 1e7 }, { "10M", 1e7 }, { "10 M", 1e7 }, { "2.5b", 2.5e9 }, { "2.5B", 2.5e9 }, { "1e12", 1e12 },
				{ "1E3", 1e3 }, { "1,000,000", 1e6 }, { "25k", 25000 }, { "+7K", 7000 }, { ".5k", 500 }, { "3t", 3e12 },
				{ "1qa", 1e15 }, { "1QA", 1e15 }, { "0.001Qi", 1e15 }, { "500", 500 }, { 250, 250 }, { "1.234", 1.23 },
				{ "-5", nil }, { "-10m", nil }, { "0", nil }, { "0.001", nil }, { "abc", nil }, { "10x", nil }, { "10mm", nil },
				{ "1e400", nil }, { "2qa", nil }, { "1qi", nil }, { "nan", nil }, { "inf", nil }, { "", nil }, { "1.2.3", nil },
				{ "5.", nil }, { "e5", nil }, { "1e", nil }, { 0 / 0, nil }, { math.huge, nil }, { -3, nil }, { true, nil },
				{ string.rep("9", 40), nil },
			}
			local wrong = {}
			for _, case in ipairs(CASES) do
				local okParse, value = pcall(mod.ParseAmount, case[1])
				local expected = case[2]
				local good = okParse and (if expected == nil then value == nil else (type(value) == "number" and math.abs(value - expected) <= expected * 1e-9))
				if not good then
					table.insert(wrong, string.format("%s -> %s (want %s)", tostring(case[1]), tostring(value), tostring(expected)))
				end
			end
			T.check(#wrong == 0, "ParseAmount: %d wrong: %s", #wrong, table.concat(wrong, "; ", 1, math.min(#wrong, 6)))
		end
		-- rate limit: 8 in the same instant, the 9th is refused
		now += 5
		local refused = 0
		for _ = 1, 9 do
			local _, s, m = invoke("Inspect", nil, nil)
			if s == false and m == "Too fast: wait a moment" then
				refused += 1
			end
		end
		T.check(refused == 1, "the rate limit must allow 8 calls per second and refuse the 9th (refused %d)", refused)
		-- a non-admin is refused and warned (once per window)
		now += 5
		isAdmin = false
		table.clear(warnings)
		okCall, success, message = invoke("GiveMoney", nil, { Amount = "1K" })
		local _, success2 = invoke("GiveMoney", nil, { Amount = "1K" })
		T.check(okCall and success == false and message == "Not allowed" and success2 == false, "a non-admin must be refused (got %s)", tostring(message))
		T.check(#warnings == 1 and H.has(warnings[1], "[HeroAdmin] refused Dev"), "a refused call must be warned once (%d warnings)", #warnings)
	end
end

-- 7. layout (round 12: "make it feel designed": one grid, nothing overlapping, nothing spilling) -----------------
do
	local CONTENT_W, CONTENT_H = 620, 410
	local PAGE_RIGHT = 600.5 -- 4 px inset + 596 px of content: the 6 px scroll bar stays clear
	local PHONE_FIT = 375 * 0.94 / 500 -- the client's fit on a 375 px tall landscape phone
	local function offsetOnly(node)
		return node.Size.X.Scale == 0 and node.Size.Y.Scale == 0 and node.Position.X.Scale == 0 and node.Position.Y.Scale == 0
	end
	local function box(node, dx, dy)
		return {
			x = (dx or 0) + node.Position.X.Offset - node.AnchorPoint.X * node.Size.X.Offset,
			y = (dy or 0) + node.Position.Y.Offset - node.AnchorPoint.Y * node.Size.Y.Offset,
			w = node.Size.X.Offset, h = node.Size.Y.Offset,
		}
	end
	local function inside(a, b)
		return a.x >= b.x - 0.5 and a.y >= b.y - 0.5 and a.x + a.w <= b.x + b.w + 0.5 and a.y + a.h <= b.y + b.h + 0.5
	end
	local function fmt(r)
		return string.format("(%.0f,%.0f %.0fx%.0f)", r.x, r.y, r.w, r.h)
	end
	-- (a) what each tab shows at once: its page, the toast, the target bar when the tab uses a target
	local targetBar = H.path(window, "Content/TargetBar")
	local toastNode = H.path(window, "Content/Toast")
	local contentBox = { x = 0, y = 0, w = CONTENT_W, h = CONTENT_H }
	T.check(content ~= nil and content.Size.X.Offset == CONTENT_W and content.Size.Y.Offset == CONTENT_H, "Window.Content must be %dx%d", CONTENT_W, CONTENT_H)
	T.check(targetBar ~= nil and targetBar.Visible == true, "the target bar starts visible (PLAYER is the first tab)")
	local tabProblems = {}
	for _, id in ipairs(TABS) do
		local page = pages and pages:FindFirstChild("Page_" .. id)
		if page and targetBar and toastNode then
			local shown = { { "Toast", box(toastNode) }, { page.Name, box(page, pages.Position.X.Offset, pages.Position.Y.Offset) } }
			if USES_TARGET[id] then
				table.insert(shown, { "TargetBar", box(targetBar) })
			end
			for i, a in ipairs(shown) do
				if not inside(a[2], contentBox) then
					table.insert(tabProblems, id .. ": " .. a[1] .. " outside Content " .. fmt(a[2]))
				end
				for j = i + 1, #shown do
					if overlaps(a[2], shown[j][2]) then
						table.insert(tabProblems, id .. ": " .. a[1] .. " / " .. shown[j][1])
					end
				end
			end
		end
	end
	T.check(#tabProblems == 0, "tab layout problems: %s", first(tabProblems))
	-- (b) every offset-placed node inside its parent (a scrolling page: its canvas), siblings never overlapping (but the
	-- alternatives: the pages, the sub-pages, and Content whose pieces are checked per tab above)
	local ALTERNATIVES = { Content = true, Pages = true, SubPages = true }
	local outside, clashes, pageSpill = {}, {}, {}
	local function walk(parent)
		local kids = {}
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("GuiObject") then
				if offsetOnly(child) and string.sub(child.Name, 1, 2) ~= "Sp" then
					table.insert(kids, child)
				end
				walk(child)
			end
		end
		if not (parent:IsA("GuiObject") and offsetOnly(parent)) then
			return
		end
		local limit = { x = 0, y = 0, w = parent.Size.X.Offset,
			h = if parent:IsA("ScrollingFrame") then math.max(parent.CanvasSize.Y.Offset, parent.Size.Y.Offset) else parent.Size.Y.Offset }
		for i, a in ipairs(kids) do
			local ra = box(a)
			if not inside(ra, limit) then
				table.insert(outside, a:GetFullName() .. " " .. fmt(ra))
			end
			if parent:IsA("ScrollingFrame") and ra.x + ra.w > PAGE_RIGHT then
				table.insert(pageSpill, a:GetFullName())
			end
			if not ALTERNATIVES[parent.Name] then
				for j = i + 1, #kids do
					if overlaps(ra, box(kids[j])) then
						table.insert(clashes, parent.Name .. ": " .. a.Name .. " / " .. kids[j].Name)
					end
				end
			end
		end
	end
	if content and tabs then
		walk(content)
		walk(tabs)
	end
	T.check(#outside == 0, "%d node(s) leave their parent: %s", #outside, first(outside))
	T.check(#clashes == 0, "%d overlapping sibling pair(s): %s", #clashes, first(clashes))
	T.check(#pageSpill == 0, "page content must stay in the 596 px column (clear of the scroll bar): %s", first(pageSpill))
	-- (c) these PLAYER sub-pages fit without scrolling; every button stays a thumb-sized target on a phone
	for _, id in ipairs({ "Actions", "Economy", "Data" }) do
		local page = subPages and subPages:FindFirstChild("SubPage_" .. id)
		T.check(page ~= nil and page.CanvasSize.Y.Offset <= page.Size.Y.Offset,
			"SubPage_%s must fit without scrolling (canvas %s, page %s)", id, tostring(page and page.CanvasSize.Y.Offset), tostring(page and page.Size.Y.Offset))
	end
	local smallest = math.huge
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("GuiButton") and d.Name ~= "DragHandle" and d.Name ~= "Close" then
			smallest = math.min(smallest, d.Size.Y.Offset)
		end
	end
	T.check(smallest * PHONE_FIT >= 44, "the smallest button (%d design px) must stay >= 44 px at the phone fit %.3f", smallest, PHONE_FIT)
end

-- sandbox helpers -------------------------------------------------------------------------------------------------
local function inst(props)
	props.__instance = true
	props.children = props.children or {}
	props.attributes = props.attributes or {}
	props.IsA = props.IsA or function(self, class)
		return self.ClassName == class
	end
	props.FindFirstChild = props.FindFirstChild or function(self, name)
		return self.children[name]
	end
	props.WaitForChild = props.WaitForChild or function(self, name)
		return self.children[name]
	end
	props.GetAttribute = function(self, key)
		return self.attributes[key]
	end
	props.SetAttribute = function(self, key, value)
		self.attributes[key] = value
	end
	return props
end
local function instTypeof(v)
	if type(v) == "table" and v.__instance then
		return "Instance"
	end
	return typeof(v)
end
local function deepEqual(a, b, path, diffs)
	if type(a) ~= type(b) then
		table.insert(diffs, path)
		return
	end
	if type(a) ~= "table" then
		if a ~= b then
			table.insert(diffs, path)
		end
		return
	end
	for k, v in pairs(a) do
		deepEqual(v, b[k], path .. "." .. tostring(k), diffs)
	end
	for k in pairs(b) do
		if a[k] == nil then
			table.insert(diffs, path .. "." .. tostring(k))
		end
	end
end

-- 8. the wipe ------------------------------------------------------------------------------------------------------
-- (a) the real Library.Database in a sandbox: a loaded profile wiped = a new player's, saved at once, frozen until leave
do
	local store, stats = {}, {}
	local playersService = inst({ ClassName = "Players", PlayerAdded = H.mockSignal(), PlayerRemoving = H.mockSignal(), GetPlayers = function()
		return {}
	end })
	local statsRemote = { FireClient = function(_, _player, data)
		table.insert(stats, data)
	end }
	local network = inst({ ClassName = "Folder", children = { ["New Stats"] = statsRemote } })
	local services = {
		Players = playersService,
		ReplicatedStorage = inst({ ClassName = "ReplicatedStorage", children = { Network = network } }),
		DataStoreService = { GetDataStore = function()
			return {
				GetAsync = function(_, key)
					return store[key]
				end,
				UpdateAsync = function(_, key, transform)
					store[key] = transform(store[key])
					return store[key]
				end,
				SetAsync = function(_, key, value)
					store[key] = value
				end,
			}
		end },
		RunService = { IsStudio = function()
			return false
		end },
	}
	local chunk, err = H.sandbox(databaseSrc, {
		game = { GetService = function(_, name)
			return services[name]
		end, BindToClose = function() end },
		task = { spawn = function(fn, ...)
			pcall(fn, ...)
		end, wait = function()
			error("sandbox: no waiting")
		end, delay = function() end },
		warn = function() end, print = function() end,
	}, "Database")
	local ok, db = false, err
	if chunk then
		ok, db = pcall(chunk)
	end
	if T.check(ok and type(db) == "table" and type(db.WipeProfile) == "function", "Library.Database did not load in the sandbox: %s", tostring(db)) then
		store["Player_42"] = {
			Money = 5000, SpeedPower = 123456, Rebirth = 3, EggInventory = { E1 = { AssetCategory = "Goku" } }, Inventory = { H1 = { Category = "Goku" } },
			Index = { Goku = true }, UnlockedBaseThemes = { Forest = true }, EquippedBaseTheme = "Forest", TimePlayed = 999, EggsHatched = 7,
			TreadmillUpgradeLevel = 4, BaseUpgradeLevel = 2, MoneyScaleVersion = 1, LastSeenAt = 1000,
		}
		local victim = inst({ ClassName = "Player", Name = "Victim", UserId = 42, Parent = playersService })
		playersService.PlayerAdded:Fire(victim)
		T.check(db.IsPlayerLoaded(victim) and db.Get(victim).Money == 5000, "the sandboxed Database must load the old save")
		local okWipe, saved, reason = pcall(db.WipeProfile, victim)
		local after = store["Player_42"]
		T.check(okWipe and saved == true and reason == nil, "WipeProfile must save at once (got %s %s %s)", tostring(okWipe), tostring(saved), tostring(reason))
		T.check(type(after) == "table" and after.Money == 2 and after.SpeedPower == 10 and after.Rebirth == 0 and next(after.EggInventory) == nil
			and next(after.Inventory) == nil and next(after.Index) == nil and next(after.UnlockedBaseThemes) == nil and after.EquippedBaseTheme == ""
			and after.TimePlayed == 0 and after.EggsHatched == 0 and after.TreadmillUpgradeLevel == 1 and after.BaseUpgradeLevel == 0
			and after.MoneyScaleVersion == 1 and after.LastSeenAt == 0,
			"the saved profile must be a brand new player's (money 2, speed 10, nothing owned, stamped, never seen)")
		T.check(db.Get(victim).Money == 2 and db.IsWiped(victim) and stats[#stats] == db.Get(victim),
			"the live profile must be the fresh one, flagged wiped, and sent to the client")
		-- a system still holding old state writes it back before the kick: never saved
		db.Set(victim, { Money = 777777, Index = { Goku = true } })
		playersService.PlayerRemoving:Fire(victim)
		T.check(store["Player_42"].Money == 2 and next(store["Player_42"].Index) == nil and not db.IsWiped(victim),
			"the leave save must write the frozen new-player payload, not a stale write (Money %s)", tostring(store["Player_42"].Money))
		-- rejoining = exactly what a never-seen player gets
		local back = inst({ ClassName = "Player", Name = "Victim", UserId = 42, Parent = playersService })
		local fresh = inst({ ClassName = "Player", Name = "Newbie", UserId = 43, Parent = playersService })
		playersService.PlayerAdded:Fire(back)
		playersService.PlayerAdded:Fire(fresh)
		local diffs = {}
		deepEqual(db.Get(back), db.Get(fresh), "profile", diffs)
		T.check(db.Get(back) ~= nil and #diffs == 0, "a wiped player who rejoins must load exactly a new player's profile (diffs: %s)", first(diffs))
		T.check(db.WipeProfile(inst({ ClassName = "Player", Name = "Ghost", UserId = 44, Parent = playersService })) == false,
			"WipeProfile must refuse a profile that is not loaded")
	end
end

-- (b) HeroAdminService with fakes: WipeData, the all-server Taco Rain, Announce
local adminEnv = {}
do
	local now = 1000
	local isAdmin = true
	local delays, kicked, removed, wipes, starts, stops, publishes, announces = {}, {}, {}, {}, {}, {}, {}, {}
	local wiped, globalHandlers = {}, {}
	local canPublish, publishOk, publishErr = true, true, nil
	local playersService = inst({ ClassName = "Players" })
	local function player(name, userId)
		return inst({ ClassName = "Player", Name = name, UserId = userId, Parent = playersService, FindFirstChildOfClass = function()
			return nil
		end, Kick = function(self, message)
			kicked[self.Name] = message
		end })
	end
	local caller, victim = player("Dev", 767108248), player("Victim", 42)
	playersService.GetPlayerByUserId = function(_, id)
		return if id == 42 then victim elseif id == 767108248 then caller else nil
	end
	playersService.GetPlayers = function()
		return { caller, victim }
	end
	local accessInst = inst({ ClassName = "ModuleScript", Name = "HeroAdminAccess" })
	local dbInst = inst({ ClassName = "ModuleScript", Name = "Database" })
	local tacoInst = inst({ ClassName = "ModuleScript", Name = "TacoRainService" })
	local broadcastInst = inst({ ClassName = "ModuleScript", Name = "HeroBroadcastService" })
	local remoteFn = inst({ ClassName = "RemoteFunction", Name = "Admin: Command" })
	local fakeAccess = { ATTRIBUTE = "HeroAdmin", IsAdmin = function()
		return isAdmin, "test"
	end, Forget = function() end }
	local fakeDb = {
		Get = function()
			return { Money = 10, SpeedPower = 10, EggInventory = {}, Inventory = {} }
		end,
		IsPlayerLoaded = function()
			return true
		end,
		WipeProfile = function(p)
			table.insert(wipes, p.Name)
			wiped[p] = true
			return true
		end,
		IsWiped = function(p)
			return wiped[p] == true
		end,
	}
	local fakeTaco = { MIN_DURATION = 15, MAX_DURATION = 300, DEFAULT_DURATION = 75,
		StartRain = function(duration)
			table.insert(starts, duration)
			return true, string.format("Taco Rain started: %d s", duration)
		end,
		StopRain = function(reason)
			table.insert(stops, reason)
			return true, "The Taco Rain is over"
		end,
	}
	local fakeBroadcast = {
		CanPublish = function()
			return canPublish, if canPublish then nil else "Wait 3 s between two all-server sends"
		end,
		Publish = function(kind, data, from)
			table.insert(publishes, { kind = kind, data = data, from = from })
			return publishOk, publishErr
		end,
		OnGlobal = function(kind, fn)
			globalHandlers[kind] = fn
		end,
		Announce = function(from, text, scope)
			table.insert(announces, { from = from, text = text, scope = scope })
			return true, "Announcement shown", nil
		end,
	}
	local modules = { [accessInst] = fakeAccess, [dbInst] = fakeDb, [tacoInst] = fakeTaco, [broadcastInst] = fakeBroadcast }
	local empty = inst({ ClassName = "Folder" })
	local services = {
		Players = playersService,
		ServerScriptService = inst({ ClassName = "ServerScriptService", children = {
			HeroAdminAccess = accessInst, Library = inst({ ClassName = "Folder", children = { Database = dbInst } }),
		} }),
		ReplicatedStorage = inst({ ClassName = "ReplicatedStorage", children = {
			Network = inst({ ClassName = "Folder", children = { ["Admin: Command"] = remoteFn } }),
		} }),
		DataStoreService = { GetOrderedDataStore = function(_, name)
			return { RemoveAsync = function(_, key)
				table.insert(removed, name .. ":" .. key)
			end }
		end },
	}
	local branchFolder = inst({ ClassName = "Folder", children = { TacoRainService = tacoInst, HeroBroadcastService = broadcastInst } })
	local chunk, err = H.sandbox(serviceSrc, {
		game = { GetService = function(_, name)
			return services[name] or empty
		end },
		script = inst({ ClassName = "ModuleScript", Name = "HeroAdminService", Parent = branchFolder }),
		Enum = roblox.Enum, Color3 = roblox.Color3, Vector3 = roblox.Vector3, CFrame = roblox.CFrame,
		RaycastParams = { new = function()
			return {}
		end },
		typeof = instTypeof,
		require = function(module)
			local value = modules[module]
			if value == nil then
				error("unexpected require")
			end
			return value
		end,
		os = { clock = function()
			return now
		end, time = os.time },
		task = { delay = function(seconds, fn, ...)
			table.insert(delays, { seconds = seconds, fn = fn, args = table.pack(...) })
		end, spawn = function(fn, ...)
			fn(...)
		end, wait = function() end },
		warn = function() end, print = function() end,
	}, "HeroAdminService")
	local ok, mod = false, err
	if chunk then
		ok, mod = pcall(chunk)
	end
	if T.check(ok and type(mod) == "table", "HeroAdminService did not load in the full sandbox: %s", tostring(mod)) then
		local function invoke(command, target, args)
			now += 1
			local results = table.pack(pcall(mod._onInvoke, caller, command, target, args))
			return results[1], results[2], results[3], results[4], results[5]
		end
		adminEnv = { invoke = invoke, mod = mod }
		-- WipeData --------------------------------------------------------------------------------------------------
		local okCall, success, message = invoke("WipeData", 42, nil)
		T.check(okCall and success == false and H.has(tostring(message), "not confirmed") and #wipes == 0,
			"WipeData without the confirmed id must be refused (got %s)", tostring(message))
		okCall, success = invoke("WipeData", 42, { ConfirmUserId = 999 })
		T.check(okCall and success == false and #wipes == 0, "WipeData with another player's id must be refused")
		okCall, success, message = invoke("WipeData", 42, { ConfirmUserId = 42 })
		T.check(okCall and success == true and wipes[1] == "Victim" and H.has(tostring(message), "wiped and saved"),
			"a confirmed WipeData must wipe the target (got %s %s)", tostring(success), tostring(message))
		T.check(#delays == 2 and delays[1].seconds == mod.WIPE_KICK_DELAY and kicked.Victim == nil, "the kick must wait for the answer to reach the panel")
		for _, pending in ipairs(delays) do
			pending.fn(table.unpack(pending.args, 1, pending.args.n))
		end
		T.check(kicked.Victim == "Your data was reset by an admin. Rejoin to start from zero.", "the wiped player must be kicked with the owner's message")
		T.check(#removed == #mod.LEADERBOARD_STORES and removed[1] == "Leaderboard_Networth_v1:42" and table.find(removed, "FlappyBest_v1:42") ~= nil,
			"their leaderboard rows must be removed once they are gone (%d)", #removed)
		okCall, success, message = invoke("WipeData", nil, { ConfirmUserId = 767108248 })
		T.check(okCall and success == false and H.has(tostring(message), "Wait"), "a second wipe inside WIPE_COOLDOWN must be refused (got %s)", tostring(message))
		now += mod.WIPE_COOLDOWN
		okCall, success, message = invoke("WipeData", 42, { ConfirmUserId = 42 })
		T.check(okCall and success == false and H.has(tostring(message), "already wiped"), "a player being kicked cannot be wiped twice (got %s)", tostring(message))
		okCall, success = invoke("WipeData", nil, { ConfirmUserId = 767108248 })
		T.check(okCall and success == true and wipes[2] == "Dev", "an admin may wipe themselves (Studio self-test)")
		now += mod.WIPE_COOLDOWN
		isAdmin = false
		okCall, success, message = invoke("WipeData", 42, { ConfirmUserId = 42 })
		T.check(okCall and success == false and message == "Not allowed" and #wipes == 2, "WipeData must be refused without admin access")
		isAdmin = true
		-- all-server Taco Rain -------------------------------------------------------------------------------------
		okCall, success = invoke("TacoRainStart", nil, { Duration = 60 })
		T.check(okCall and success == true and starts[#starts] == 60 and #publishes == 0, "a this-server Taco Rain must not publish")
		okCall, success, message = invoke("TacoRainStart", nil, { Duration = 90, Scope = "All" })
		local pub = publishes[1]
		T.check(okCall and success == true and starts[#starts] == 90 and pub ~= nil and pub.kind == "TacoRain" and pub.data.Action == "Start"
			and pub.data.Duration == 90 and pub.from == caller and H.has(tostring(message), "every server"),
			"an all-server Taco Rain must run here and publish Start / 90 s (got %s)", tostring(message))
		publishOk, publishErr = false, "cross-server messaging is unavailable (403)"
		local kind
		okCall, success, message, _, kind = invoke("TacoRainStart", nil, { Duration = 60, Scope = "All" })
		T.check(okCall and success == true and kind == "warn" and H.has(tostring(message), "THIS SERVER ONLY"),
			"when MessagingService fails the rain must stay here and say so (kind %s: %s)", tostring(kind), tostring(message))
		publishOk, publishErr = true, nil
		canPublish = false
		local before = #starts
		okCall, success, message = invoke("TacoRainStart", nil, { Duration = 60, Scope = "All" })
		T.check(okCall and success == false and #starts == before and H.has(tostring(message), "Wait"),
			"an all-server send inside its cooldown must be refused before anything runs (got %s)", tostring(message))
		canPublish = true
		okCall, success, message = invoke("TacoRainStart", nil, { Duration = 60, Scope = "Galaxy" })
		T.check(okCall and success == false and H.has(tostring(message), "Scope"), "an unknown scope must be refused")
		okCall, success = invoke("TacoRainStop", nil, { Scope = "All" })
		T.check(okCall and success == true and #stops == 1 and publishes[#publishes].data.Action == "Stop", "an all-server STOP must stop here and publish")
		pcall(mod.Init, mod)
		pcall(mod.Start, mod)
		T.check(remoteFn.OnServerInvoke == mod._onInvoke and globalHandlers.TacoRain == mod._runGlobalTacoRain,
			"HeroAdminService:Start must answer the remote and register the all-server Taco Rain handler")
		mod._runGlobalTacoRain({ Action = "Start", Duration = 9999, By = "OtherAdmin" })
		T.check(starts[#starts] == 300, "a received Start must be clamped to TacoRainService.MAX_DURATION (got %s)", tostring(starts[#starts]))
		mod._runGlobalTacoRain({ Action = "Stop", By = "OtherAdmin" })
		T.check(#stops == 2, "a received Stop must stop the rain here")
		-- Announce --------------------------------------------------------------------------------------------------
		local text = string.rep("a", 150)
		okCall, success = invoke("Announce", nil, { Text = text, Scope = "All" })
		T.check(okCall and success == true and announces[1] and announces[1].text == text and announces[1].scope == "All" and announces[1].from == caller,
			"Announce must hand the 150-character text and the scope to HeroBroadcastService.Announce")
		okCall, success, message = invoke("Announce", nil, { Text = string.rep("b", 700), Scope = "Server" })
		T.check(okCall and success == false and message == "Invalid arguments" and #announces == 1, "a text over 600 bytes must be refused by the argument check")
	end
end

-- 9. cross-server (the real HeroBroadcastService in a sandbox) ----------------------------------------------------
local function loadBroadcast(opts)
	opts = opts or {}
	local env = { log = {}, fired = {}, published = {}, subscribed = nil, now = 500, guid = 0 }
	env.messagingDown, env.publishDown, env.filterDown = opts.messagingDown, false, false
	local remote = inst({ ClassName = "RemoteEvent", Name = "Announcement: Show", OnServerEvent = H.mockSignal(), FireAllClients = function(_, payload)
		table.insert(env.log, "fire")
		table.insert(env.fired, payload)
	end })
	env.remote = remote
	local accessInst = inst({ ClassName = "ModuleScript", Name = "HeroAdminAccess" })
	local fakeAccess = { IsAdmin = function(p)
		return p.admin == true
	end }
	local services = {
		HttpService = {
			GenerateGUID = function()
				env.guid += 1
				return "guid-" .. env.guid
			end,
			JSONEncode = function(_, value)
				local n = 2
				for k, v in pairs(value) do
					n += #tostring(k) + #tostring(v) + 6
				end
				return string.rep("x", n)
			end,
		},
		MessagingService = {
			SubscribeAsync = function(_, topic, callback)
				if env.messagingDown then
					error("MessagingService: StudioAccessToApisNotAllowed")
				end
				env.topic = topic
				env.subscribed = callback
				return { Disconnect = function() end }
			end,
			PublishAsync = function(_, topic, payload)
				if env.publishDown then
					error("HTTP 403 (Forbidden)")
				end
				table.insert(env.log, "publish")
				table.insert(env.published, { topic = topic, payload = payload })
			end,
		},
		TextService = { FilterStringAsync = function(_, text, userId)
			table.insert(env.log, "filter")
			if env.filterDown then
				error("filter offline")
			end
			env.filteredFor = userId
			return { GetNonChatStringForBroadcastAsync = function()
				table.insert(env.log, "broadcastString")
				return "F<" .. text .. ">"
			end }
		end },
		Players = inst({ ClassName = "Players" }),
		ReplicatedStorage = inst({ ClassName = "ReplicatedStorage", children = {
			Network = inst({ ClassName = "Folder", children = { ["Announcement: Show"] = remote } }),
		} }),
		ServerScriptService = inst({ ClassName = "ServerScriptService", children = { HeroAdminAccess = accessInst } }),
	}
	local chunk, err = H.sandbox(broadcastSrc, {
		game = { GetService = function(_, name)
			return services[name]
		end },
		Enum = setmetatable({ TextFilterContext = { PublicChat = "PublicChat" } }, { __index = roblox.Enum }),
		typeof = instTypeof,
		require = function(module)
			if module == accessInst then
				return fakeAccess
			end
			error("unexpected require")
		end,
		os = { clock = function()
			return env.now
		end, time = os.time },
		task = { wait = function() end, spawn = function(fn, ...)
			fn(...)
		end, delay = function() end },
		warn = function() end, print = function() end,
	}, "HeroBroadcastService")
	local ok, mod = false, err
	if chunk then
		ok, mod = pcall(chunk)
	end
	env.mod = if ok then mod else nil
	env.err = if ok then nil else mod
	return env
end

do
	local env = loadBroadcast()
	local mod = env.mod
	if T.check(type(mod) == "table" and type(mod._onMessage) == "function", "HeroBroadcastService did not load in the sandbox: %s", tostring(env.err)) then
		local admin = inst({ ClassName = "Player", Name = "Dev", UserId = 767108248, admin = true })
		local stranger = inst({ ClassName = "Player", Name = "Random", UserId = 5, admin = false })
		pcall(mod.Init, mod)
		pcall(mod.Start, mod)
		T.check(env.topic == "HeroAdmin_Global" and type(env.subscribed) == "function" and env.remote.attributes.CrossServer == "ready",
			"Start must subscribe to HeroAdmin_Global and mark the link ready")
		local ran = {}
		mod.OnGlobal("TacoRain", function(data)
			table.insert(ran, data)
		end)
		-- publish from an admin
		local okPub = mod.Publish("TacoRain", { Action = "Start", Duration = 60 }, admin)
		local sent = env.published[1] and env.published[1].payload
		T.check(okPub == true and sent ~= nil and env.published[1].topic == "HeroAdmin_Global" and sent.V == 1 and sent.Kind == "TacoRain"
			and sent.Action == "Start" and sent.Duration == 60 and sent.Origin == mod.SERVER_ID and type(sent.Nonce) == "string" and sent.ById == 767108248,
			"an admin's publish must send the enveloped payload on HeroAdmin_Global")
		T.check(mod.Publish("TacoRain", { Action = "Stop" }, stranger) == false and #env.published == 1, "a non-admin must never publish")
		local okAgain, why = mod.Publish("TacoRain", { Action = "Stop" }, admin)
		T.check(okAgain == false and H.has(tostring(why), "Wait") and #env.published == 1, "a second publish inside GLOBAL_COOLDOWN must be refused")
		-- receiving
		env.subscribed({ Data = sent })
		T.check(#ran == 0, "a server must ignore its own echo (it already ran the action)")
		local function other(fields)
			local data = { V = 1, Kind = "TacoRain", Action = "Start", Duration = 60, Origin = "server-B", Nonce = "n-" .. tostring(env.now) .. tostring(math.random()),
				By = "OtherDev", ById = 1, At = os.time() }
			for k, v in pairs(fields or {}) do
				data[k] = v
			end
			return data
		end
		local good = other({ Duration = 9999, Nonce = "n1" })
		env.subscribed({ Data = good })
		T.check(#ran == 1 and ran[1].Duration == 300 and ran[1].Action == "Start", "a valid message must run once, its duration clamped to 300 (got %s)",
			tostring(ran[1] and ran[1].Duration))
		env.subscribed({ Data = good })
		T.check(#ran == 1, "a duplicate nonce must be ignored")
		local BAD = {
			{ "no data", nil },
			{ "not a table", "boom" },
			{ "wrong version", other({ V = 2 }) },
			{ "unknown kind", other({ Kind = "Nuke" }) },
			{ "unknown action", other({ Action = "Explode" }) },
			{ "NaN duration", other({ Duration = 0 / 0 }) },
			{ "string duration", other({ Duration = "60" }) },
			{ "stale", other({ At = os.time() - 100000 }) },
			{ "long origin", other({ Origin = string.rep("o", 100) }) },
			{ "missing nonce", other({ Nonce = false }) },
			{ "fractional sender", other({ ById = 1.5 }) },
			{ "long text", other({ Kind = "Announce", Action = false, Text = string.rep("t", 400) }) },
			{ "empty text", other({ Kind = "Announce", Action = false, Text = "   " }) },
		}
		local leaked = {}
		for _, case in ipairs(BAD) do
			local ranBefore, firedBefore = #ran, #env.fired
			local data = case[2]
			if type(data) == "table" and data.Nonce == false then
				data.Nonce = nil
			end
			if type(data) == "table" and data.Action == false then
				data.Action = nil
			end
			env.subscribed(if case[1] == "no data" then {} else { Data = data })
			if #ran ~= ranBefore or #env.fired ~= firedBefore then
				table.insert(leaked, case[1])
			end
		end
		T.check(#leaked == 0, "malformed cross-server payloads must be ignored: %s", first(leaked))
		env.subscribed({ Data = other({ Kind = "Announce", Action = nil, Text = "Hello\nfrom   B", Nonce = "a1" }) })
		local shown = env.fired[#env.fired]
		T.check(shown ~= nil and shown.Kind == "Global" and shown.Text == "Hello from B", "a received announcement must show as GLOBAL, cleaned (got %s)",
			tostring(shown and shown.Text))
		-- announcements: the filter runs before anything is shown or published
		table.clear(env.log)
		env.now += 100
		local okAnn, msg = mod.Announce(admin, "  Double   money\tnow ", "Server")
		local firedNow = env.fired[#env.fired]
		T.check(okAnn == true and env.log[1] == "filter" and env.log[2] == "broadcastString" and env.log[3] == "fire" and #env.log == 3
			and firedNow.Kind == "Server" and firedNow.Text == "F<Double money now>" and env.filteredFor == 767108248,
			"a this-server announcement: filtered from the admin, then fired (log %s, %s)", table.concat(env.log, ","), tostring(msg))
		table.clear(env.log)
		env.now += 100
		okAnn = mod.Announce(admin, "Taco weekend", "All")
		local pubAnn = env.published[#env.published].payload
		T.check(okAnn == true and env.log[1] == "filter" and table.find(env.log, "fire") > 2 and table.find(env.log, "publish") > 2
			and pubAnn.Kind == "Announce" and pubAnn.Text == "F<Taco weekend>" and env.fired[#env.fired].Kind == "Global",
			"an all-server announcement: filtered first, then shown here and published filtered (log %s)", table.concat(env.log, ","))
		table.clear(env.log)
		okAnn, msg = mod.Announce(admin, "again", "Server")
		T.check(okAnn == false and H.has(tostring(msg), "Wait") and #env.log == 0, "a second announcement inside ANNOUNCE_COOLDOWN must be refused")
		env.now += 100
		env.filterDown = true
		local firedBefore = #env.fired
		okAnn = mod.Announce(admin, "unfiltered?", "Server")
		T.check(okAnn == false and #env.fired == firedBefore, "when the filter fails nothing may be shown")
		env.filterDown = false
		env.now += 100
		table.clear(env.log)
		T.check(mod.Announce(stranger, "hi", "Server") == false and #env.log == 0, "a non-admin must never reach the filter or the remote")
		T.check(mod.Announce(admin, string.rep("z", 151), "Server") == false and #env.log == 0, "an announcement over 150 characters must be refused")
		T.check(mod.Announce(admin, "hi", "Galaxy") == false, "an unknown scope must be refused")
		-- fallback: MessagingService down
		env.publishDown = true
		env.now += 100
		local okFall, fallMsg, fallKind = mod.Announce(admin, "Maintenance soon", "All")
		T.check(okFall == true and fallKind == "warn" and H.has(tostring(fallMsg), "THIS server only") and env.fired[#env.fired].Text == "F<Maintenance soon>",
			"when MessagingService errors the announcement must still show here and say so (%s)", tostring(fallMsg))
		env.now += 100
		local okP, whyP = mod.Publish("TacoRain", { Action = "Start", Duration = 60 }, admin)
		T.check(okP == false and H.has(tostring(whyP), "unavailable"), "a failed publish must report the cross-server link unavailable")
	end
	local down = loadBroadcast({ messagingDown = true })
	if down.mod then
		pcall(down.mod.Init, down.mod)
		local okStart = pcall(down.mod.Start, down.mod)
		T.check(okStart and down.remote.attributes.CrossServer == "offline" and down.mod.IsReady() == false,
			"without MessagingService (Studio, no API access) Start must fall back quietly and mark the link offline")
	end
end

-- 10. announcements: the banner and its controller ---------------------------------------------------------------
do
	local bannerGui = starterGui:FindFirstChild("HeroAnnouncements")
	if T.check(bannerGui ~= nil and bannerGui:IsA("ScreenGui"), "StarterGui.HeroAnnouncements (ScreenGui) missing") then
		T.check(bannerGui.ResetOnSpawn == false and bannerGui.Enabled == true and bannerGui.DisplayOrder > 40
			and bannerGui.ScreenInsets == roblox.Enum.ScreenInsets.CoreUISafeInsets,
			"HeroAnnouncements: ResetOnSpawn off, enabled, above the HUD and the admin panel, inside the core UI safe area")
		local node = bannerGui:FindFirstChild("Banner")
		local limit = node and node:FindFirstChildOfClass("UISizeConstraint")
		T.check(node ~= nil and node:IsA("CanvasGroup") and node.Visible == false and node.GroupTransparency == 1
			and node.AnchorPoint == roblox.Vector2.new(0.5, 0) and node.Position.X.Scale == 0.5 and node.Position.Y.Scale == 0
			and node.AutomaticSize == roblox.Enum.AutomaticSize.Y and node.Size.X.Scale == 1 and node.Size.X.Offset < 0
			and limit ~= nil and limit.MaxSize.X <= 600, "the Banner must be a hidden top-centre CanvasGroup, screen-wide minus a margin, capped, auto height")
		local cardNode = node and node:FindFirstChild("Card")
		local kicker = cardNode and H.path(cardNode, "Content/Kicker")
		local body = cardNode and H.path(cardNode, "Content/Body")
		local studLayer = cardNode and cardNode:FindFirstChild("SpStuds")
		T.check(cardNode ~= nil and studLayer ~= nil and H.imageId(studLayer) == 6927295847 and cardNode:FindFirstChild("SpStroke") ~= nil
			and cardNode:FindFirstChild("Accent") ~= nil and cardNode:FindFirstChild("Timer") ~= nil,
			"the card must be the kit's studded dark body with the ink rim, the gold accent and the timer bar")
		T.check(kicker ~= nil and kicker.Text == "SERVER ANNOUNCEMENT" and body ~= nil and body.TextWrapped and not body.TextScaled
			and body.AutomaticSize == roblox.Enum.AutomaticSize.Y and body.RichText == false,
			"Kicker / Body: the label and the wrapping plain text that sizes the card")
		T.check(H.countClass(bannerGui, "LuaSourceContainer") == 0 and H.countClass(bannerGui, "Sound") == 0, "the banner is a template: no script, no sound")
	end
	local controllerSrc = src(announcementModule)
	T.check(H.has(controllerSrc, 'REMOTE_NAME = "Announcement: Show"') and H.has(controllerSrc, "remote.OnClientEvent:Connect(AnnouncementController.Push)")
		and H.has(controllerSrc, "GroupTransparency") and H.has(controllerSrc, '"UiDeviceProfile"') and not H.has(controllerSrc, "RichText = true"),
		"AnnouncementController must listen to the remote, fade the banner, size per device and never use rich text")
	local presented = {}
	local chunk, err = H.sandbox(controllerSrc, {
		game = { GetService = function()
			return inst({ ClassName = "Service" })
		end },
		TweenInfo = { new = function(...)
			return { ... }
		end },
		Enum = roblox.Enum,
		task = { spawn = function(fn, ...)
			fn(...)
		end, wait = function() end, defer = function() end },
		warn = function() end,
	}, "AnnouncementController")
	local ok, mod = false, err
	if chunk then
		ok, mod = pcall(chunk)
	end
	if T.check(ok and type(mod) == "table" and type(mod.Push) == "function", "AnnouncementController did not load in the sandbox: %s", tostring(mod)) then
		mod._present = function(item)
			table.insert(presented, item)
		end
		T.check(mod.Push({ Kind = "Server", Text = "Hello" }) == true and presented[1] and presented[1].Label == "SERVER ANNOUNCEMENT"
			and presented[1].Text == "Hello", "a server announcement must be shown with its label")
		T.check(mod.Push({ Kind = "Global", Text = "Hi\nall" }) == true and presented[2].Label == "GLOBAL ANNOUNCEMENT" and presented[2].Text == "Hi all",
			"a global announcement must be shown on one line")
		local rejected = 0
		local badList = table.pack(nil, "text", { Kind = "Evil", Text = "x" }, { Kind = "Server", Text = "   " }, { Kind = "Server", Text = 5 },
			{ Kind = "Server" }, { Kind = "Server", Text = string.rep("x", 900) })
		for i = 1, badList.n do
			if mod.Push(badList[i]) == false then
				rejected += 1
			end
		end
		T.check(rejected == 7 and #presented == 2, "malformed announcements must be ignored (%d / 7 rejected)", rejected)
		mod.Push({ Kind = "Server", Text = string.rep("y", 300) })
		T.check(utf8.len(presented[#presented].Text) == mod.MAX_CHARS, "an over-long text must be cut to MAX_CHARS")
		-- one at a time: what arrives while one shows waits in the queue (at most MAX_QUEUE, the oldest dropped)
		table.clear(presented)
		local reentered = false
		mod._present = function(item)
			table.insert(presented, item.Text)
			if not reentered then
				reentered = true
				for i = 1, 8 do
					mod.Push({ Kind = "Server", Text = "queued " .. i })
				end
			end
		end
		mod.Push({ Kind = "Server", Text = "first" })
		T.check(#presented == 1 + mod.MAX_QUEUE and presented[1] == "first" and presented[2] == "queued 4" and presented[#presented] == "queued 8",
			"announcements must queue in order, at most %d waiting (shown: %s)", mod.MAX_QUEUE, table.concat(presented, ", "))
		T.check(mod.DurationFor("hi") == mod.MIN_SECONDS and mod.DurationFor(string.rep("w", 150)) >= 8 and mod.DurationFor(string.rep("w", 150)) <= mod.MAX_SECONDS,
			"an announcement must stay ~8 s (longer texts a little longer, capped)")
	end
end
