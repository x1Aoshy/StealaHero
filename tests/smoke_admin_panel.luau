--!nocheck
-- tests/smoke_admin_panel.luau (owner 2026-09-27: "an admin panel for the devs ... blocky like everything, pretty, not
-- AI-looking, no emojis; only user 767108248, the owners or people with Studio access; the icon in the topbar next to
-- Backpack and Settings, as 3D art"). Joins the "smoke" filter. Checks, against the built place:
--   1. the panel is ServerStorage.HeroAdminPanel (never StarterGui), a ScreenGui with ResetOnSpawn off, disabled, in the
--      ui_kit look (studded dark body, glossy band, SpTitle "ADMIN PANEL", the round X art, glossy buttons, square
--      corners, the stud texture only), 6 tabs / 6 pages, the target bar and the toast;
--   2. every button's Command has a handler in HeroAdminService.COMMANDS (and every handler but Inspect a button), its
--      Arg* attributes are plain strings / numbers, every touch target is >= 62 design px tall (>= 44 px on a phone);
--   3. no text of the panel (labels, captions, attributes) and none of its scripts holds a non-ASCII character (emoji);
--   4. the 3D crown: ViewportFrame Crown3D with a Camera and a part-built model, anchored, no Neon;
--   5. the scripts are injected and compile: HeroAdminAccess (767108248, the owner and Studio checks), the Branch
--      service (remote, rate limit, log line, dummies), the client (TopbarPlus icon, viewport art, the remote), and
--      Network["Admin: Command"] is a RemoteFunction;
--   6. behaviour in a sandbox: the access rule (Studio / 767108248 / user owner / group owner rank 255 / others), and the
--      service's remote gate (non-admin refused and warned, rate limit, unknown command, bad target, bad arguments).

local place = H.place()
local roblox = H.roblox
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local ss = place:GetService("ServerStorage")
local starterGui = place:GetService("StarterGui")

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
local closeArt = close and close:FindFirstChild("SpCloseArt")
T.check(close ~= nil and close:IsA("GuiButton") and closeArt ~= nil and H.imageId(closeArt) == 110882579806743,
	"the round red close (X art 110882579806743) missing")

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

local tabs = window:FindFirstChild("Tabs")
local pages = H.path(window, "Content/Pages")
local TABS = { "Weapons", "Economy", "Eggs", "World", "Player", "Server" }
for _, id in ipairs(TABS) do
	local tab = tabs and tabs:FindFirstChild("Tab_" .. id)
	local page = pages and pages:FindFirstChild("Page_" .. id)
	T.check(tab ~= nil and tab:IsA("GuiButton") and tab:GetAttribute("Tab") == id and tab:FindFirstChild("SpFill") ~= nil,
		"glossy tab Tab_%s missing", id)
	T.check(page ~= nil and page:IsA("ScrollingFrame") and page:GetAttribute("Tab") == id, "page Page_%s missing", id)
end
for _, path in ipairs({ "Content/TargetBar/Prev", "Content/TargetBar/Next", "Content/TargetBar/Me", "Content/TargetBar/TargetCard/PlayerName",
	"Content/Toast/Text", "Content/Toast/Dot", "ModeBadge/Text", "DragHandle" }) do
	T.check(H.path(window, path) ~= nil, "Window.%s missing", path)
end

-- 2. commands -----------------------------------------------------------------------------------------------------
local service = H.path(sss, "BranchServices/HeroAdminService")
local serviceSrc = src(service)
local handlers = {}
for name in string.gmatch(serviceSrc, "\nCOMMANDS%.(%w+) = function") do
	handlers[name] = true
end
local used, missing, badArgs, small, flat = {}, {}, {}, {}, {}
local buttons = 0
for _, d in ipairs(gui:GetDescendants()) do
	local command = d:GetAttribute("Command")
	if command ~= nil then
		buttons += 1
		used[command] = true
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
	if d:IsA("GuiButton") and d.Name ~= "DragHandle" and d.Name ~= "Close" and d.Size.Y.Offset < 62 then
		table.insert(small, d.Name .. " " .. tostring(d.Size.Y.Offset))
	end
end
T.check(buttons >= 45, "the panel must hold its command buttons (found %d)", buttons)
T.check(#missing == 0, "buttons whose command has no handler in HeroAdminService.COMMANDS: %s", first(missing))
T.check(#badArgs == 0 and #flat == 0, "command attributes must sit on GuiButtons with string / number args: %s %s", first(badArgs), first(flat))
T.check(#small == 0, "touch targets must be >= 62 design px tall (>= 44 px at the phone fit): %s", first(small))
local unused = {}
for name in pairs(handlers) do
	if name ~= "Inspect" and not used[name] then
		table.insert(unused, name)
	end
end
table.sort(unused)
T.check(#unused == 0, "every command must have a button: %s", first(unused))
for _, name in ipairs({ "GiveAllWeapons", "GiveWeapon", "RemoveDevWeapons", "UnlockIndexWeapons", "AddMoney", "ResetMoney", "AddSpeed",
	"SetSpeed", "GiveEgg", "GrowEggs", "Teleport", "NightNow", "DayNow", "NormalCycle", "UnlockBaseThemes", "Release", "Respawn", "Heal",
	"GoTo", "Bring", "SpawnDummy", "ClearDummies", "Inspect" }) do
	T.check(handlers[name] == true, "HeroAdminService.COMMANDS.%s missing", name)
end
local weaponCards = 0
for _, d in ipairs((pages and pages:FindFirstChild("Page_Weapons") or gui):GetChildren()) do
	if d:GetAttribute("Command") == "GiveWeapon" then
		weaponCards += 1
	end
end
T.check(weaponCards == 7, "the 7 hero weapons must each have a card (found %d)", weaponCards)

-- 3. ASCII only ---------------------------------------------------------------------------------------------------
local nonAscii = {}
local function scan(label, value)
	if type(value) == "string" and string.find(value, "[\128-\255]") then
		table.insert(nonAscii, label)
	end
end
for _, d in ipairs({ gui, table.unpack(gui:GetDescendants()) }) do
	if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
		scan(d:GetFullName(), d.Text)
	elseif d:IsA("StringValue") then
		scan(d:GetFullName(), d.Value)
	end
	for key, value in pairs(d:GetAttributes()) do
		scan(d:GetFullName() .. "@" .. key, value)
	end
end
local client = gui:FindFirstChild("HeroAdminClient")
local access = sss:FindFirstChild("HeroAdminAccess")
for _, script in ipairs({ client, service, access }) do
	if script then
		scan(script:GetFullName() .. " (source)", script.Source)
	end
end
T.check(#nonAscii == 0, "the panel's texts and scripts must be plain ASCII (no emoji): %s", first(nonAscii))

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
T.check(client ~= nil and client:IsA("LocalScript") and compiles(client), "HeroAdminPanel.HeroAdminClient must be a compiling LocalScript")
local clientSrc = src(client)
T.check(H.has(clientSrc, "Modules.Packages.TopBarPlus") and H.has(clientSrc, "setOrder(ICON_ORDER)") and H.has(clientSrc, '"IconImage"')
	and H.has(clientSrc, "HeroAdminCrown3D") and H.has(clientSrc, 'REMOTE_NAME = "Admin: Command"') and H.has(clientSrc, 'ADMIN_ATTRIBUTE = "HeroAdmin"'),
	"the client must add the TopbarPlus icon with the 3D crown and invoke Network['Admin: Command']")
local remote = H.path(rs, "Network/Admin: Command")
T.check(remote ~= nil and remote:IsA("RemoteFunction"), "ReplicatedStorage.Network['Admin: Command'] must be a RemoteFunction")
local branchServer = sss:FindFirstChild("BranchServer")
T.check(branchServer ~= nil and H.has(src(branchServer), "BranchServices"), "BranchServer must start the BranchServices root the service lives in")

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
		okCall, success, message = invoke("AddMoney", nil, { Amount = { 1 } })
		T.check(okCall and success == false and message == "Invalid arguments", "a table argument must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("AddMoney", nil, { Amount = -5 })
		T.check(okCall and success == false and message == "Invalid amount", "a negative amount must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke("GiveWeapon", nil, { Tool = "Admin Bat" })
		T.check(okCall and success == false and message == "Unknown weapon", "a tool outside the hero weapons must be refused (got %s)", tostring(message))
		now += 1
		okCall, success, message = invoke(string.rep("x", 40), nil, nil)
		T.check(okCall and success == false and message == "Invalid command", "an oversized command must be refused (got %s)", tostring(message))
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
		okCall, success, message = invoke("AddMoney", nil, { Amount = 1000 })
		local _, success2 = invoke("AddMoney", nil, { Amount = 1000 })
		T.check(okCall and success == false and message == "Not allowed" and success2 == false, "a non-admin must be refused (got %s)", tostring(message))
		T.check(#warnings == 1 and H.has(warnings[1], "[HeroAdmin] refused Dev"), "a refused call must be warned once (%d warnings)", #warnings)
	end
end
