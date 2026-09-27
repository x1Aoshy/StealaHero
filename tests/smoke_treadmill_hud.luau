--!nocheck
-- tests/smoke_treadmill_hud.luau (owner 2026-09-27: "on the treadmill the effect that hides the UI goes crazy, there are
-- logic fights"). Joins the "smoke" filter. Pins the fix:
--   1. BranchControllers.MenuMotionController (slides the HUD groups away while a menu is open) no longer re-hides every
--      group whenever anything is parented to PlayerGui. On the treadmill SpeedGainAnimation.ShowPlusOne adds a "+N"
--      BillboardGui to PlayerGui every 0.1-0.25 s, and each one restarted the Back-In hide tween, so the HUD crept back
--      and jittered under the speed shop. Sandboxed: a menu opens (one tween per group), 60 treadmill billboards and
--      unrelated ScreenGuis arrive (no tween), a respawned ShiftLockButton is sent away alone, the menu closes (one
--      tween back per group, each group ends where it was authored).
--   2. GUI.TreadmillUI.Visibility (hides Money / FriendBoost / Backpack / side buttons for the session) owns those values
--      for the whole session: Apply is idempotent, a mid-session write that shows one (GUI.FriendBoost on PlayerAdded,
--      HideImportantUI:UnHide on BackpackGui) is undone and becomes the value restored at the exit, the exit restores
--      once and leaves BackpackGui to HideImportantUI while HideUI is locked. Sandboxed with mock modules.

local place = H.place()
local sg = place:GetService("StarterGui")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts
local Enum = H.roblox.Enum
local UDim2 = H.roblox.UDim2
local Vector2 = H.roblox.Vector2

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end

-- A signal with Connect / Once / Disconnect (the handlers run immediately, like Immediate signal behaviour).
local function newSignal()
	local signal = { handlers = {} }
	function signal:Connect(fn)
		local entry = { fn = fn }
		table.insert(self.handlers, entry)
		local connection = { Connected = true }
		function connection.Disconnect()
			connection.Connected = false
			local index = table.find(signal.handlers, entry)
			if index then
				table.remove(signal.handlers, index)
			end
		end
		return connection
	end
	function signal:Once(fn)
		local connection
		connection = self:Connect(function(...)
			connection.Disconnect()
			fn(...)
		end)
		return connection
	end
	function signal:Fire(...)
		for _, entry in ipairs(table.clone(self.handlers)) do
			entry.fn(...)
		end
	end
	return signal
end

-- A stand-in Instance: properties fire GetPropertyChangedSignal when they change, children are found by name (also
-- through indexing, like Roblox), attributes are kept. `log` (optional) records every property change.
local GUI_OBJECT = { Frame = true, ImageButton = true, TextButton = true, ImageLabel = true, TextLabel = true }
local function fake(className, name, props, log)
	local store = { Name = name, ClassName = className }
	for k, v in pairs(props or {}) do
		store[k] = v
	end
	local children, attributes, signals = {}, {}, {}
	local methods = {}
	local inst = setmetatable({}, {
		__index = function(_, key)
			if methods[key] ~= nil then
				return methods[key]
			end
			if store[key] ~= nil then
				return store[key]
			end
			return methods.FindFirstChild(nil, key)
		end,
		__newindex = function(self, key, value)
			if store[key] == value then
				return
			end
			store[key] = value
			if log then
				table.insert(log, { inst = self, key = key, value = value })
			end
			if signals[key] then
				signals[key]:Fire()
			end
		end,
		__tostring = function()
			return name
		end,
	})
	function methods.IsA(_, class)
		return class == className or (class == "GuiObject" and GUI_OBJECT[className] == true)
			or (class == "LayerCollector" and (className == "ScreenGui" or className == "BillboardGui"))
	end
	function methods.FindFirstChild(_, childName)
		for _, c in ipairs(children) do
			if c.Name == childName then
				return c
			end
		end
		return nil
	end
	function methods.GetChildren()
		return table.clone(children)
	end
	function methods.GetAttribute(_, key)
		return attributes[key]
	end
	function methods.SetAttribute(_, key, value)
		attributes[key] = value
	end
	function methods.GetPropertyChangedSignal(_, key)
		signals[key] = signals[key] or newSignal()
		return signals[key]
	end
	function methods.WaitForChild(self, childName)
		return self:FindFirstChild(childName)
	end
	function methods.Add(self, child)
		table.insert(children, child)
		child.Parent = self
		return child
	end
	function methods.Remove(_, child)
		local index = table.find(children, child)
		if index then
			table.remove(children, index)
		end
		child.Parent = nil
	end
	return inst
end

---------------------------------------------------------------------------------------------------
-- 1. MenuMotionController
---------------------------------------------------------------------------------------------------
local motion = H.path(sps, "BranchControllers/MenuMotionController")
local motionSrc = src(motion)
if T.check(motion ~= nil, "BranchControllers.MenuMotionController missing") then
	T.check(pcall(H.luau.compile, motionSrc, { optimizationLevel = 2 }), "MenuMotionController does not compile")
	T.check(H.has(motionSrc, "if hudHidden and isHudGui(child) then") and H.has(motionSrc, "task.defer(hideAddedGroups, child)"),
		"MenuMotionController's PlayerGui.ChildAdded must only look at a recreated HUD ScreenGui")
	T.check(not H.has(motionSrc, "hudHidden = false\n\t\t\t\tsetHudHidden(anyMenuOpen())"),
		"MenuMotionController must not reset and re-hide every group on PlayerGui.ChildAdded (the treadmill's +N billboards)")
	T.check(H.has(motionSrc, "local function moveTo(object, info, goal, restart)") and H.has(motionSrc, "if running and current.goal == goal then"),
		"MenuMotionController must never restart a tween already heading to the same goal")
end

do
	local tweens, deferred = {}, {}
	local function flush()
		local guard = 0
		while #deferred > 0 and guard < 1000 do
			guard += 1
			local job = table.remove(deferred, 1)
			job.fn(table.unpack(job.args))
		end
	end
	local function playing()
		local n = 0
		for _, tween in ipairs(tweens) do
			if tween.PlaybackState == Enum.PlaybackState.Playing then
				n += 1
			end
		end
		return n
	end
	local function finishAll()
		for _, tween in ipairs(tweens) do
			if tween.PlaybackState == Enum.PlaybackState.Playing then
				tween.object.Position = tween.goal
				tween.PlaybackState = Enum.PlaybackState.Completed
				tween.Completed:Fire(Enum.PlaybackState.Completed)
			end
		end
	end
	local TweenService = {}
	function TweenService.Create(_, object, _info, goal)
		local tween = { object = object, goal = goal.Position, PlaybackState = Enum.PlaybackState.Begin, Completed = newSignal() }
		function tween.Play(self)
			self.PlaybackState = Enum.PlaybackState.Playing
		end
		function tween.Cancel(self)
			if self.PlaybackState == Enum.PlaybackState.Playing or self.PlaybackState == Enum.PlaybackState.Begin then
				self.PlaybackState = Enum.PlaybackState.Cancelled
				self.Completed:Fire(Enum.PlaybackState.Cancelled)
			end
		end
		table.insert(tweens, tween)
		return tween
	end

	local playerGui = fake("PlayerGui", "PlayerGui")
	local childAdded = newSignal()
	rawset(playerGui, "ChildAdded", childAdded)
	local function parentToPlayerGui(child)
		playerGui:Add(child)
		childAdded:Fire(child)
	end

	local tab = { open = nil, openListeners = {}, closeListeners = {} }
	local TabController = {
		IsOpen = function(name)
			if name == nil then
				return tab.open ~= nil
			end
			return tab.open == name
		end,
		AddOpenListener = function(fn)
			table.insert(tab.openListeners, fn)
		end,
		AddCloseListener = function(fn)
			table.insert(tab.closeListeners, fn)
		end,
	}
	local TAB_MODULE = {}
	local localPlayer = { WaitForChild = function()
		return playerGui
	end }
	local services = {
		Players = { LocalPlayer = localPlayer },
		ReplicatedStorage = { Library = { Client = { TabController = TAB_MODULE } } },
		TweenService = TweenService,
	}
	local chunk, err = H.sandbox(motionSrc, {
		game = { GetService = function(_, name)
			return services[name]
		end },
		require = function(module)
			if module == TAB_MODULE then
				return TabController
			end
			error("unexpected require")
		end,
		task = { defer = function(fn, ...)
			table.insert(deferred, { fn = fn, args = table.pack(...) })
		end },
		TweenInfo = { new = function()
			return {}
		end },
		Instance = { new = function(className)
			return fake(className, className)
		end },
		Enum = Enum,
		UDim2 = UDim2,
		warn = function() end,
	}, "MenuMotionController")

	local controller = nil
	if T.check(chunk ~= nil, "MenuMotionController sandbox: %s", tostring(err)) then
		local ok, result = pcall(chunk)
		if T.check(ok and type(result) == "table", "MenuMotionController did not load: %s", tostring(result)) then
			controller = result
		end
	end

	if controller then
		-- the HUD as the build authors it (positions from StarterGui, so the edges are the real ones)
		local authored = {} -- [object] = UDim2
		local screenGuis = {}
		local function makeGroup(screen, entry)
			local template = H.path(sg, entry[1] .. "/" .. entry[2])
			local object = fake("Frame", entry[2], {
				Position = template and template.Position or UDim2.fromScale(0.5, 0.5),
				AnchorPoint = template and template.AnchorPoint or Vector2.new(0.5, 0.5),
				Size = template and template.Size or UDim2.fromScale(0.1, 0.1),
			})
			screen:Add(object)
			authored[object] = object.Position
			return object
		end
		for _, entry in ipairs(controller.HUD_GROUPS) do
			local screen = screenGuis[entry[1]]
			if screen == nil then
				screen = fake("ScreenGui", entry[1])
				screenGuis[entry[1]] = screen
				playerGui:Add(screen)
			end
			makeGroup(screen, entry)
		end
		local groupCount = #controller.HUD_GROUPS
		local function groups()
			local list = {}
			for _, entry in ipairs(controller.HUD_GROUPS) do
				local screen = playerGui:FindFirstChild(entry[1])
				table.insert(list, screen and screen:FindFirstChild(entry[2]))
			end
			return list
		end
		local function setTab(name)
			local listeners = if name then tab.openListeners else tab.closeListeners
			tab.open = name
			for _, fn in ipairs(listeners) do
				fn(name)
			end
		end

		local okStart, startErr = pcall(controller.Start, controller)
		T.check(okStart, "MenuMotionController:Start failed in the sandbox: %s", tostring(startErr))
		flush()
		T.check(#tweens == 0 and not controller.IsHudHidden(), "no menu open: the HUD must not move (%d tweens)", #tweens)

		-- the treadmill speed shop opens: every group leaves once
		setTab("TreadmillSpeedShop")
		flush()
		T.check(controller.IsHudHidden() and #tweens == groupCount and playing() == groupCount,
			"opening a menu must start exactly one hide tween per HUD group (%d tweens for %d groups)", #tweens, groupCount)
		local hideGoals = {}
		for _, object in ipairs(groups()) do
			local rest = object:GetAttribute("SpHudRestPosition")
			T.check(rest == authored[object], "%s must remember its authored Position while away", tostring(object))
		end
		for _, tween in ipairs(tweens) do
			hideGoals[tween.object] = tween.goal
		end

		-- the treadmill keeps parenting "+N" billboards to PlayerGui (every speed step), plus unrelated ScreenGuis:
		-- the hide tweens in flight must not be restarted
		local function treadmillSpam(count)
			for i = 1, count do
				parentToPlayerGui(fake("BillboardGui", "PlusOne"))
				if i % 10 == 0 then
					parentToPlayerGui(fake("ScreenGui", "SpeedGainPopup" .. i))
				end
			end
			flush()
		end
		local before = #tweens
		treadmillSpam(30)
		T.check(#tweens == before and playing() == groupCount,
			"treadmill billboards mid-hide must not restart the hide tweens (%d new tweens, %d still playing)", #tweens - before, playing())
		finishAll()
		for object, goal in pairs(hideGoals) do
			T.check(object.Position == goal, "%s must end its hide at the away position", tostring(object))
		end
		before = #tweens
		treadmillSpam(30)
		controller._refresh()
		controller._refresh()
		flush()
		T.check(#tweens == before and controller.IsHudHidden(),
			"with the HUD away, billboards and repeated refreshes must not move anything (%d new tweens)", #tweens - before)

		-- respawn while the menu is open: the recreated ShiftLockButton (ResetOnSpawn) is sent away, alone
		local oldShift = playerGui:FindFirstChild("ShiftLockButton")
		if oldShift then
			playerGui:Remove(oldShift)
		end
		local newShift = fake("ScreenGui", "ShiftLockButton")
		local shiftButton = makeGroup(newShift, { "ShiftLockButton", "ImageButton" })
		before = #tweens
		parentToPlayerGui(newShift)
		flush()
		local added = #tweens - before
		T.check(added == 1 and tweens[#tweens].object == shiftButton,
			"a respawned HUD ScreenGui must send only its own fresh group away (%d new tweens)", added)
		finishAll()

		-- the menu closes: every group comes back once, to where it was authored
		before = #tweens
		setTab(nil)
		flush()
		T.check(not controller.IsHudHidden() and #tweens - before == groupCount,
			"closing the menu must start exactly one show tween per HUD group (%d for %d groups)", #tweens - before, groupCount)
		treadmillSpam(20)
		T.check(#tweens - before == groupCount, "billboards after the menu closed must not move the HUD (%d tweens)", #tweens - before - groupCount)
		finishAll()
		for _, object in ipairs(groups()) do
			T.check(object.Position == authored[object] and object:GetAttribute("SpHudRestPosition") == nil,
				"%s must be back at its authored Position (rest attribute cleared)", tostring(object))
		end

		-- idempotent moves: a second request for the same goal while a tween runs, or with the object already there
		if T.check(type(controller._moveTo) == "function" and type(controller._isHudGui) == "function",
			"MenuMotionController must expose the _moveTo / _isHudGui test hooks") then
			local probe = fake("Frame", "Probe", { Position = UDim2.fromScale(0.2, 0.2) })
			before = #tweens
			controller._moveTo(probe, {}, UDim2.fromScale(0.2, 1.4))
			controller._moveTo(probe, {}, UDim2.fromScale(0.2, 1.4))
			T.check(#tweens - before == 1, "moveTo must not restart a tween already heading to the same goal")
			finishAll()
			controller._moveTo(probe, {}, UDim2.fromScale(0.2, 1.4))
			T.check(#tweens - before == 1, "moveTo must not tween an object already at its goal")
			T.check(controller._isHudGui(fake("ScreenGui", "Money")) and not controller._isHudGui(fake("BillboardGui", "PlusOne"))
				and not controller._isHudGui(fake("ScreenGui", "SpeedGainPopup")), "only the HUD groups' ScreenGuis are HUD ScreenGuis")
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 2. TreadmillUI.Visibility
---------------------------------------------------------------------------------------------------
local visibility = H.path(sps, "GUI/TreadmillUI/Visibility")
local visSrc = src(visibility)
if T.check(visibility ~= nil, "GUI.TreadmillUI.Visibility missing") then
	T.check(pcall(H.luau.compile, visSrc, { optimizationLevel = 2 }), "TreadmillUI.Visibility does not compile")
	T.check(H.has(visSrc, "TREADMILL HUD patch") and H.has(visSrc, "local function guardHidden(")
		and H.has(visSrc, "guardHidden(FriendBoost, \"Visible\"") and H.has(visSrc, "guardHidden(v10, \"Enabled\"")
		and H.has(visSrc, "releaseGuards()") and H.has(visSrc, "not isHideUILocked()"),
		"TreadmillUI.Visibility must own what it hides for the whole session (guards, one restore, HideUI rule)")
	local visCode = string.gsub(visSrc, "%-%-[^\n]*", "") -- code only (the header explains the TOPBAR patch)
	T.check(not H.has(visCode, "TopbarStandard"),
		"TreadmillUI.Visibility must keep leaving the TopbarPlus container alone (TOPBAR patch)")
end
T.check(H.has(H.fs.readFile("scripts/inject/topbar.luau"), "GUI/TreadmillUI/Visibility"),
	"scripts/inject/topbar.luau must keep injecting TreadmillUI.Visibility")

do
	local log = {}
	local function obj(className, name, props)
		return fake(className, name, props, log)
	end
	local moneyGui = obj("ScreenGui", "Money")
	local bottom = moneyGui:Add(obj("Frame", "Bottom"))
	local frame = bottom:Add(obj("Frame", "Frame"))
	local money = frame:Add(obj("Frame", "Money", { Visible = true }))
	local friendBoost = frame:Add(obj("Frame", "FriendBoost", { Visible = true }))
	local offline = obj("ScreenGui", "OfflineMoneyInPlot")
	local topBar = offline:Add(obj("Frame", "TopBar", { Visible = true }))
	local backpack = obj("ScreenGui", "BackpackGui", { Enabled = true })
	local elements = obj("ScreenGui", "Elements")
	local left = elements:Add(obj("Frame", "Left"))
	local tools = left:Add(obj("Frame", "Tools"))
	local shop = tools:Add(obj("Frame", "Shop", { Visible = true }))
	local index = tools:Add(obj("Frame", "Index", { Visible = true }))
	local rebirth = tools:Add(obj("Frame", "Rebirth", { Visible = false }))
	local speedShop = tools:Add(obj("Frame", "TreadmillSpeedShop", { Visible = false }))
	local doubleSpeed = tools:Add(obj("Frame", "DoubleYourSpeed", { Visible = false }))
	local right = elements:Add(obj("Frame", "Right", { Visible = true }))
	elements:Add(obj("Frame", "Tabs", { Visible = true }))

	local hideUILocked = false
	local unequips, closes, friendRefreshes = 0, 0, 0
	local modules = {
		GUI = {
			Money = function()
				return moneyGui
			end,
			OfflineMoneyInPlot = function()
				return offline
			end,
			Backpack = function()
				return backpack
			end,
			SideButtons = function()
				return elements
			end,
		},
		Types = {},
		Player = { Optional = { Humanoid = function()
			return { UnequipTools = function()
				unequips += 1
			end }
		end } },
		TabController = {
			IsOpen = function()
				return false
			end,
			CloseTab = function()
				closes += 1
			end,
		},
		Variables = { Locks = { HideUI = { IsLocked = function()
			return hideUILocked
		end } } },
		Friends = { CacheUpdated = { Fire = function()
			friendRefreshes += 1
		end } },
	}
	local S = {}
	for key in pairs(modules) do
		S[key] = { module = key }
	end
	local rs = { Library = {
		Client = { GUI = S.GUI, TabController = S.TabController },
		Types = { GUI = S.Types },
		Player = S.Player,
		Variables = S.Variables,
		Functions = { GetFriendCountInServer = S.Friends },
	} }
	local chunk, err = H.sandbox(visSrc, {
		game = { GetService = function(_, name)
			if name == "ReplicatedStorage" then
				return rs
			end
			return { LocalPlayer = {} }
		end },
		require = function(sentinel)
			local module = type(sentinel) == "table" and sentinel.module and modules[sentinel.module]
			if module == nil then
				error("unexpected require")
			end
			return module
		end,
	}, "TreadmillUI.Visibility")
	local Visibility = nil
	if T.check(chunk ~= nil, "TreadmillUI.Visibility sandbox: %s", tostring(err)) then
		local ok, result = pcall(chunk)
		if T.check(ok and type(result) == "table" and type(result.Apply) == "function", "TreadmillUI.Visibility did not load: %s", tostring(result)) then
			Visibility = result
		end
	end

	if Visibility then
		local function changes()
			local n = #log
			table.clear(log)
			return n
		end
		changes()

		-- session start: everything the treadmill hides goes away once, the two treadmill buttons show
		Visibility.Apply(true)
		T.check(not backpack.Enabled and not money.Visible and not friendBoost.Visible and not topBar.Visible and not right.Visible
			and not shop.Visible and not index.Visible and speedShop.Visible and doubleSpeed.Visible and unequips == 1,
			"Apply(true) must hide the HUD the treadmill hides and show the treadmill buttons")
		changes()
		Visibility.Apply(true)
		T.check(changes() == 0 and unequips == 1, "a repeated Apply(true) must change nothing")

		-- mid-session writes by the elements' own scripts
		friendBoost.Visible = true -- GUI.FriendBoost: a friend joined
		backpack.Enabled = true -- HideImportantUI:UnHide / TrappedBackpackLock
		index.Visible = true
		T.check(not friendBoost.Visible and not backpack.Enabled and not index.Visible,
			"a mid-session write must not bring a treadmill-hidden element back (FriendBoost %s, Backpack %s)",
			tostring(friendBoost.Visible), tostring(backpack.Enabled))

		-- session end: each value restored once, FriendBoost's owner asked to re-apply its own state
		changes()
		Visibility.Apply(false)
		T.check(backpack.Enabled and money.Visible and friendBoost.Visible and topBar.Visible and right.Visible and shop.Visible
			and index.Visible and not rebirth.Visible and not speedShop.Visible and not doubleSpeed.Visible,
			"Apply(false) must restore the HUD (the treadmill buttons hide again, a hidden button stays hidden)")
		T.check(friendRefreshes == 1, "the exit must ask GUI.FriendBoost to re-apply its state once (%d)", friendRefreshes)
		local restored = changes()
		T.check(restored > 0 and restored <= 9, "the exit must write each restored value once (%d writes)", restored)
		Visibility.Apply(false)
		T.check(changes() == 0 and friendRefreshes == 1, "a repeated Apply(false) must change nothing")
		friendBoost.Visible = false -- after the session its owner is free again
		T.check(not friendBoost.Visible, "the guards must be released when the session ends")
		friendBoost.Visible = true

		-- a session ending while HideUI is locked (egg carry, admin cutscene): BackpackGui stays with HideImportantUI
		Visibility.Apply(true)
		hideUILocked = true
		Visibility.Apply(false)
		T.check(not backpack.Enabled and money.Visible, "the exit must leave BackpackGui off while HideUI is locked")
		hideUILocked = false
		T.check(closes == 0, "Apply(false) must only close the speed shop when it is open (%d closes)", closes)
	end
end
