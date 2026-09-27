--!nocheck
-- tests/smoke_netcode_mobile.luau (owner 2026-09-27: "accurate NPC and player hitboxes even when the server lags; smooth
-- network; phone players first; comfortable UI sizes on phone and console"). Joins the "smoke" filter. Checks:
--   1. bat hits are judged against the victim rewound to what the swinger saw (LagCompensationService.SeenBy);
--   2. villains write WalkSpeed at most every 0.2 s (small drifts) instead of up to every frame;
--   3. LeaderstatsService (sandbox): one pair of Database callbacks for everyone (it leaked two per join), Money text
--      flushed at most once a second, a leaving player's entry dropped;
--   4. UiScaleController (sandbox): phone / tablet / console / desktop profiles; its HUD targets exist in StarterGui;
--   5. PerfController's phone budget and the SceneryFar marks it relies on.

local place = H.place()
local sss = place:GetService("ServerScriptService")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts
local ws = place:GetService("Workspace")
local Vector2 = H.roblox.Vector2

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end

-- 1. bat
local gear = sss:FindFirstChild("GearService")
local gearSrc = src(gear)
T.check(H.has(gearSrc, "LagComp.SeenBy(otherRoot, player)") and H.has(gearSrc, "nowDistance <= range + MELEE_SEEN_SLACK")
	and pcall(H.luau.compile, gearSrc), "GearService must judge bat hits against the victim as the swinger saw them")

-- 2. villain WalkSpeed writes
local chase = H.path(sss, "Controllers/GuardChaseService")
T.check(H.has(src(chase), "local WALKSPEED_STEP, WALKSPEED_MIN_INTERVAL = 2, 0.2") and H.has(src(chase), "g.walkSpeedAt = now"),
	"GuardChaseService must throttle WalkSpeed replication")

-- 3. leaderstats
local lsModule = H.path(sss, "Controllers/LeaderstatsService")
if T.check(lsModule ~= nil, "Controllers.LeaderstatsService missing") then
	local loaded, fields = {}, {}
	local fakeDb = {
		OnLoaded = function(cb) table.insert(loaded, cb) end,
		OnFieldChanged = function(field, cb) fields[field] = fields[field] or {}; table.insert(fields[field], cb) end,
	}
	local removing = H.mockSignal()
	local spawned = {}
	local created = {}
	local function newValue(className)
		local v = { ClassName = className, Value = if className == "IntValue" then 0 else "", Parent = nil, Name = "" }
		table.insert(created, v)
		return v
	end
	local chunk = H.sandbox(lsModule.Source, {
		game = {
			GetService = function(_, name) return if name == "Players" then { PlayerRemoving = removing } else nil end,
			ServerScriptService = { Library = { Database = "DB" } },
		},
		require = function() return fakeDb end,
		Instance = { new = function(className) return newValue(className) end },
		task = { spawn = function(fn) table.insert(spawned, fn) end, wait = function() end },
	}, "LeaderstatsService")
	local ok, ls = pcall(chunk)
	if T.check(ok and type(ls) == "table", "LeaderstatsService did not load in the sandbox: %s", tostring(ls)) then
		local players = {}
		for i = 1, 3 do
			local p = { Name = "P" .. i, Parent = {}, FindFirstChild = function() return nil end }
			players[i] = p
			for _, cb in ipairs(loaded) do
				cb(p, { Money = 1500, Rebirth = 0 })
			end
		end
		T.check(#(fields.Money or {}) == 1 and #(fields.Rebirth or {}) == 1,
			"LeaderstatsService must register one Money / Rebirth callback in total (found %d / %d after 3 joins)", #(fields.Money or {}),
			#(fields.Rebirth or {}))
		-- two changes before a flush: only the latest is written, formatted
		fields.Money[1](players[1], 2000)
		fields.Money[1](players[1], 1234567)
		local money = nil
		for _, v in ipairs(created) do
			if v.ClassName == "StringValue" then
				money = v
				break
			end
		end
		T.check(money ~= nil and money.Value == "1.50K", "the Money text starts at the loaded value (%s)", tostring(money and money.Value))
		T.check(money ~= nil and money.Value == "1.50K", "Money changes wait for the flush (%s)", tostring(money and money.Value))
		ls._flush()
		T.check(money ~= nil and money.Value == "1.23M", "a flush writes only the latest Money value, formatted (%s)", tostring(money and money.Value))
		local folder = nil
		removing:Fire(players[2])
		local okFlush = pcall(ls._flush)
		T.check(okFlush, "a flush after a player left must not error")
		local _ = folder
	end
end

-- 4. device scale
local uiScale = H.path(sps, "BranchControllers/UiScaleController")
if T.check(uiScale ~= nil and pcall(H.luau.compile, src(uiScale)), "BranchControllers.UiScaleController missing or broken") then
	local state = { touch = false, keyboard = true, tenFoot = false, preferred = nil, viewport = Vector2.new(1920, 1080) }
	local enumPreferred = { Touch = "Touch", Gamepad = "Gamepad", KeyboardAndMouse = "KeyboardAndMouse" }
	local uis = setmetatable({}, { __index = function(_, k)
		if k == "PreferredInput" then
			if state.preferred == nil then error("no PreferredInput") end
			return state.preferred
		elseif k == "TouchEnabled" then return state.touch
		elseif k == "KeyboardEnabled" then return state.keyboard end
		return nil
	end })
	local chunk = H.sandbox(uiScale.Source, {
		game = { GetService = function(_, name)
			if name == "UserInputService" then return uis
			elseif name == "GuiService" then return { IsTenFootInterface = function() return state.tenFoot end }
			elseif name == "Workspace" then return setmetatable({}, { __index = function(_, k)
				if k == "CurrentCamera" then return { ViewportSize = state.viewport } end
				return nil
			end })
			end
			return {}
		end },
		Enum = setmetatable({ PreferredInput = enumPreferred }, { __index = H.roblox.Enum }),
		Vector2 = Vector2,
	}, "UiScaleController")
	local ok, controller = pcall(chunk)
	if T.check(ok and type(controller) == "table" and type(controller._detect) == "function", "UiScaleController did not load: %s", tostring(controller)) then
		local function profile(s)
			for k, v in pairs(s) do
				state[k] = v
			end
			return controller._detect()
		end
		T.check(profile({ preferred = "Touch", viewport = Vector2.new(844, 390) }) == "phone", "a touch phone (844x390) must be 'phone'")
		T.check(profile({ preferred = "Touch", viewport = Vector2.new(1180, 820) }) == "tablet", "a touch tablet (1180x820) must be 'tablet'")
		T.check(profile({ preferred = "Gamepad", viewport = Vector2.new(1920, 1080) }) == "console", "a gamepad-first client must be 'console'")
		T.check(profile({ preferred = "KeyboardAndMouse" }) == "desktop", "keyboard and mouse must be 'desktop'")
		state.preferred = nil -- (a nil in a table constructor is no key at all)
		T.check(profile({ touch = true, keyboard = false, viewport = Vector2.new(800, 360) }) == "phone",
			"without PreferredInput, a touch-only small screen must be 'phone'")
		T.check(profile({ touch = false, keyboard = true, tenFoot = true }) == "console", "a ten-foot interface must be 'console'")
		local sg = place:GetService("StarterGui")
		for _, target in ipairs(controller.TARGETS) do
			local node = sg:FindFirstChild(target[1])
			for _, name in ipairs(target[2]) do
				node = node and node:FindFirstChild(name)
			end
			T.check(node ~= nil and node:IsA("GuiObject") and (target[3].phone or 1) >= 1.1, "UiScaleController target %s.%s must exist (phone factor >= 1.1)",
				target[1], table.concat(target[2], "."))
		end
	end
end

-- 5. phone budget
local perf = H.path(sps, "BranchControllers/PerfController")
T.check(H.has(src(perf), "local function mobileBudget()") and H.has(src(perf), "SceneryFar") and H.has(src(perf), "MOBILE_EGG_VFX_RATE"),
	"PerfController must carry the phone budget")
local far = 0
for _, m in ipairs(ws:FindFirstChild("Scenery") and ws.Scenery:GetDescendants() or {}) do
	if m:IsA("Model") and m:GetAttribute("SceneryFar") == true then
		far += 1
	end
end
T.check(far >= 50, "the far woods must be marked SceneryFar for the phone budget (%d)", far)
