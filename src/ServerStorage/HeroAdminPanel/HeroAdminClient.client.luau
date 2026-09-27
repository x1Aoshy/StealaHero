-- ServerStorage.HeroAdminPanel.HeroAdminClient (LocalScript inside the Hero admin panel ScreenGui; the window is built
-- by scripts/steps/ui_85_admin_panel.luau and this source is copied in there)
-- Owner 2026-09-27: "an admin panel for the devs ... the admin icon goes in the topbar next to Backpack and Settings, and
-- make the icon 3D art". It only runs for admins: ServerScriptService.BranchServices.HeroAdminService clones the panel
-- into an admin's PlayerGui (ServerStorage never replicates), and every command is checked again on the server.
--   * topbar icon: a TopbarPlus v3 icon ("HeroAdminIcon", order 3: right after Backpack and Settings) that toggles the
--     panel (also F4). Its art is the panel's 3D crown (the part-built model in Window.Crown3D) cloned into a
--     ViewportFrame over the icon image, slowly orbiting with a gentle tilt; the base game's crown image under it only
--     shows if the viewport is missing. Shown while the Player attribute HeroAdmin is true.
--   * buttons: every GuiButton with a Command attribute invokes Network["Admin: Command"](Command, targetUserId,
--     { <Arg* attributes> }); Confirm = true buttons need a second tap within CONFIRM_SECONDS. The answer lands in the
--     Toast line (green / red dot) and the target card refreshes from the returned summary.
--   * target: the < > arrows cycle through the players in the server (ME = back to yourself); the card shows the
--     avatar, live money (leaderstats) and the summary (speed power, eggs, heroes, plot).
--   * tabs: Weapons / Economy / Eggs / World / Player / Server pages; Server shows the live Workspace attributes
--     ServerHz / ServerFrameMs / ServerMemoryMB (BranchServices.ServerStatsService), players, uptime and the next night.
--   * size: the 820 x 500 design is fitted with its UIScale (SpPanelScale) to 97 % x 94 % of the screen, never over
--     1.15; the smallest button (64 px) stays >= 44 px on a landscape phone. The band drags the window around.
--   * HUD: while open the panel counts as a menu for BranchControllers.MenuMotionController (the HUD slides away), by
--     adding its ScreenGui to that controller's POP_PANELS with a panel name it will never find (no pop animation).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local gui = script.Parent
local window = gui:WaitForChild("Window")
local fitScale = window:WaitForChild("SpPanelScale")
local tabsColumn = window:WaitForChild("Tabs")
local content = window:WaitForChild("Content")
local pages = content:WaitForChild("Pages")
local targetBar = content:WaitForChild("TargetBar")
local toastFrame = content:WaitForChild("Toast")

gui.IgnoreGuiInset = true -- the build writes ScreenInsets None; the window may use the whole screen height

local ADMIN_ATTRIBUTE = "HeroAdmin"
local REMOTE_NAME = "Admin: Command"
local ICON_NAME = "HeroAdminIcon"
local ICON_ORDER = 3 -- InventoryIcon is -5, the Settings gear ~1.0x (TopbarPlus creation order)
local TOGGLE_KEY = Enum.KeyCode.F4
local CONFIRM_SECONDS = 2.5
local STATS_EVERY = 0.5
local SPIN_HZ = 30
local DESIGN_W = gui:GetAttribute("DesignWidth") or 820
local DESIGN_H = gui:GetAttribute("DesignHeight") or 500
local MIN_FIT, MAX_FIT = 0.45, 1.15

local COLORS = {
	ok = Color3.fromRGB(43, 214, 60),
	error = Color3.fromRGB(232, 54, 61),
	warn = Color3.fromRGB(255, 182, 39),
	busy = Color3.fromRGB(47, 140, 255),
	idle = Color3.fromRGB(79, 86, 116),
	tabOn = Color3.fromRGB(255, 182, 39),
	tabOff = Color3.fromRGB(57, 66, 115),
	confirm = Color3.fromRGB(150, 22, 34),
	white = Color3.new(1, 1, 1),
	black = Color3.new(0, 0, 0),
	muted = Color3.fromRGB(183, 177, 228),
	gold = Color3.fromRGB(255, 211, 90),
}

local open = false
local baseScale = 1
local scaleTween = nil
local targetUserId = nil -- nil = yourself
local lastSummary = nil
local icon = nil
local menuMotion = nil

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

local function getRemote()
	local network = ReplicatedStorage:FindFirstChild("Network")
	local remote = network and network:FindFirstChild(REMOTE_NAME)
	return if remote and remote:IsA("RemoteFunction") then remote else nil
end

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx" }
local function compact(n)
	n = tonumber(n) or 0
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local magnitude = 0
	while n >= 1000 and magnitude < #SUFFIXES do
		n /= 1000
		magnitude += 1
	end
	return (if n >= 100 then string.format("%d", math.floor(n)) else string.format("%.3g", n)) .. SUFFIXES[magnitude]
end

local function clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%dh %02dm", seconds // 3600, (seconds % 3600) // 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function find(root, path)
	local node = root
	for name in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local function setText(node, value)
	if node and node:IsA("TextLabel") and node.Text ~= value then
		node.Text = value
	end
end

----------------------------------------------------------------------------------------------------
-- toast
----------------------------------------------------------------------------------------------------

local toastText = toastFrame:WaitForChild("Text")
local toastDot = toastFrame:WaitForChild("Dot")
local toastSerial = 0

local function toast(message, kind)
	toastSerial += 1
	local serial = toastSerial
	message = tostring(message or "")
	if #message > 160 then
		message = string.sub(message, 1, 157) .. "..."
	end
	toastText.Text = message
	toastDot.BackgroundColor3 = COLORS[kind] or COLORS.idle
	toastText.TextColor3 = if kind == "error" then Color3.fromRGB(255, 190, 190) else COLORS.white
	if kind == "ok" or kind == "error" then
		task.delay(8, function()
			if toastSerial == serial then
				toastDot.BackgroundColor3 = COLORS.idle
				toastText.TextColor3 = COLORS.muted
			end
		end)
	end
end

----------------------------------------------------------------------------------------------------
-- size, open / close, drag
----------------------------------------------------------------------------------------------------

local function fit()
	local camera = Workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	baseScale = math.clamp(math.min(size.X * 0.97 / DESIGN_W, size.Y * 0.94 / DESIGN_H), MIN_FIT, MAX_FIT)
	if scaleTween == nil then
		fitScale.Scale = baseScale
	end
	-- a dragged window keeps at least a quarter of itself (and so a piece of its band) on screen
	local shown = Vector2.new(DESIGN_W, DESIGN_H) * baseScale * 0.25
	local pos = window.Position
	local limitX = math.max(0, size.X / 2 - shown.X)
	local limitY = math.max(0, size.Y / 2 - shown.Y)
	window.Position = UDim2.new(0.5, math.clamp(pos.X.Offset, -limitX, limitX), 0.5, math.clamp(pos.Y.Offset, -limitY, limitY))
end

local function tweenScale(goal, info, done)
	if scaleTween then
		scaleTween:Cancel()
	end
	local tween = TweenService:Create(fitScale, info, { Scale = goal })
	scaleTween = tween
	tween.Completed:Once(function(state)
		if scaleTween == tween then
			scaleTween = nil
		end
		if state == Enum.PlaybackState.Completed and done then
			done()
		end
	end)
	tween:Play()
end

local function refreshMenuMotion()
	if menuMotion and type(menuMotion._refresh) == "function" then
		pcall(menuMotion._refresh)
	end
end

local refreshTarget -- defined below
local updateStats

local function setOpen(value)
	value = value == true
	if open == value then
		return
	end
	open = value
	if value then
		gui.Enabled = true
		fit()
		fitScale.Scale = baseScale * 0.9
		tweenScale(baseScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		refreshTarget(true)
		updateStats()
	else
		tweenScale(baseScale * 0.9, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), function()
			if not open then
				gui.Enabled = false
				fitScale.Scale = baseScale
				refreshMenuMotion() -- the HUD comes back once the panel is really gone
			end
		end)
	end
	if icon then
		pcall(function()
			if value and not icon.isSelected then
				icon:select()
			elseif not value and icon.isSelected then
				icon:deselect()
			end
		end)
	end
	refreshMenuMotion()
end

do
	local drag = window:FindFirstChild("DragHandle")
	local dragging, dragStart, startPos = nil, nil, nil
	if drag then
		drag.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, dragStart, startPos = input, input.Position, window.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End and dragging == input then
						dragging = nil
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging == nil then
				return
			end
			local mouseDrag = dragging.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseMovement
			if input == dragging or mouseDrag then
				local delta = input.Position - dragStart
				window.Position = UDim2.new(0.5, startPos.X.Offset + delta.X, 0.5, startPos.Y.Offset + delta.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1) then
				dragging = nil
				fit()
			end
		end)
	end
end

----------------------------------------------------------------------------------------------------
-- button feel: hover lightens, press darkens (any anchor point, no extra UIScale on the buttons)
----------------------------------------------------------------------------------------------------

local baseColors = setmetatable({}, { __mode = "k" }) -- [button] = resting colour
local hovered = setmetatable({}, { __mode = "k" })

local function restColor(button)
	local tab = button:GetAttribute("Tab")
	if type(tab) == "string" then
		return if tabsColumn:GetAttribute("Selected") == tab then COLORS.tabOn else COLORS.tabOff
	end
	return baseColors[button] or button.BackgroundColor3
end

local function paint(button, state)
	local color = restColor(button)
	if state == "hover" then
		color = color:Lerp(COLORS.white, 0.12)
	elseif state == "press" then
		color = color:Lerp(COLORS.black, 0.2)
	elseif state == "confirm" then
		color = COLORS.confirm
	end
	button.BackgroundColor3 = color
end

local function feel(button)
	if baseColors[button] == nil then
		baseColors[button] = button.BackgroundColor3
	end
	button.MouseEnter:Connect(function()
		hovered[button] = true
		if button:GetAttribute("Confirming") ~= true then
			paint(button, "hover")
		end
	end)
	button.MouseLeave:Connect(function()
		hovered[button] = nil
		if button:GetAttribute("Confirming") ~= true then
			paint(button, "rest")
		end
	end)
	button.MouseButton1Down:Connect(function()
		if button:GetAttribute("Confirming") ~= true then
			paint(button, "press")
		end
	end)
	button.MouseButton1Up:Connect(function()
		if button:GetAttribute("Confirming") ~= true then
			paint(button, if hovered[button] then "hover" else "rest")
		end
	end)
end

----------------------------------------------------------------------------------------------------
-- tabs
----------------------------------------------------------------------------------------------------

local function selectTab(id)
	tabsColumn:SetAttribute("Selected", id)
	for _, tab in ipairs(tabsColumn:GetChildren()) do
		if tab:IsA("GuiButton") then
			paint(tab, "rest")
			local label = tab:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then
				label.TextColor3 = COLORS.white
			end
		end
	end
	for _, page in ipairs(pages:GetChildren()) do
		if page:IsA("GuiObject") and page:GetAttribute("Tab") ~= nil then
			page.Visible = page:GetAttribute("Tab") == id
		end
	end
	if id == "Server" then
		updateStats()
	end
end

for _, tab in ipairs(tabsColumn:GetChildren()) do
	if tab:IsA("GuiButton") and type(tab:GetAttribute("Tab")) == "string" then
		feel(tab)
		tab.Activated:Connect(function()
			selectTab(tab:GetAttribute("Tab"))
		end)
	end
end
selectTab("Weapons")

----------------------------------------------------------------------------------------------------
-- target
----------------------------------------------------------------------------------------------------

local card = targetBar:WaitForChild("TargetCard")
local nameLabel = card:WaitForChild("PlayerName")
local infoLabel = card:WaitForChild("Info")
local avatar = find(card, "AvatarBack.Avatar")
local thumbnails = {} -- [UserId] = content string

local function targetPlayer()
	if targetUserId ~= nil then
		local other = Players:GetPlayerByUserId(targetUserId)
		if other then
			return other
		end
		targetUserId = nil
	end
	return player
end

local function moneyText(target)
	local stats = target:FindFirstChild("leaderstats")
	local money = stats and stats:FindFirstChild("Money")
	if money and (money:IsA("StringValue") or money:IsA("NumberValue") or money:IsA("IntValue")) then
		return if money:IsA("StringValue") then money.Value else compact(money.Value)
	end
	return if lastSummary and lastSummary.Money then compact(lastSummary.Money) else "--"
end

local function renderInfo()
	local target = targetPlayer()
	local parts = { "Money " .. moneyText(target) }
	local summary = lastSummary
	if summary and summary.UserId == target.UserId then
		if summary.SpeedPower then
			table.insert(parts, "Speed " .. compact(summary.SpeedPower))
		end
		if summary.Eggs then
			table.insert(parts, "Eggs " .. tostring(summary.Eggs))
		end
		if summary.Heroes then
			table.insert(parts, "Heroes " .. tostring(summary.Heroes))
		end
		table.insert(parts, if summary.Plot then "Plot " .. summary.Plot else "No plot")
	end
	setText(infoLabel, table.concat(parts, "   "))
end

local function setAvatar(target)
	if not avatar then
		return
	end
	local cached = thumbnails[target.UserId]
	if cached then
		avatar.Image = cached
		return
	end
	avatar.Image = ""
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
		end)
		if ok and type(image) == "string" then
			thumbnails[target.UserId] = image
			if targetPlayer() == target then
				avatar.Image = image
			end
		end
	end)
end

local inspectSerial = 0
local function inspect()
	local remote = getRemote()
	if remote == nil then
		return
	end
	inspectSerial += 1
	local serial = inspectSerial
	local wanted = targetUserId
	task.spawn(function()
		local ok, success, _message, summary = pcall(remote.InvokeServer, remote, "Inspect", wanted)
		if ok and success and serial == inspectSerial and type(summary) == "table" then
			lastSummary = summary
			renderInfo()
		end
	end)
end

refreshTarget = function(withInspect)
	local target = targetPlayer()
	local name = target.DisplayName
	if name ~= target.Name then
		name ..= "  @" .. target.Name
	end
	if target == player then
		name ..= "  (YOU)"
	end
	setText(nameLabel, name)
	setAvatar(target)
	if lastSummary and lastSummary.UserId ~= target.UserId then
		lastSummary = nil
	end
	renderInfo()
	if withInspect and open then
		inspect()
	end
end

local function sortedPlayers()
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		if a == player then
			return true
		elseif b == player then
			return false
		end
		return string.lower(a.Name) < string.lower(b.Name)
	end)
	return list
end

local function setTarget(target)
	targetUserId = if target == nil or target == player then nil else target.UserId
	refreshTarget(true)
	toast("Target: " .. targetPlayer().Name, "idle")
end

local function cycle(step)
	local list = sortedPlayers()
	if #list <= 1 then
		setTarget(player)
		toast("You are the only player in this server", "idle")
		return
	end
	local index = table.find(list, targetPlayer()) or 1
	index = (index - 1 + step) % #list + 1
	setTarget(list[index])
end

for name, action in pairs({ Prev = function() cycle(-1) end, Next = function() cycle(1) end, Me = function() setTarget(player) end }) do
	local node = targetBar:FindFirstChild(name)
	if node and node:IsA("GuiButton") then
		feel(node)
		node.Activated:Connect(action)
	end
end

Players.PlayerRemoving:Connect(function(leaving)
	if targetUserId ~= nil and leaving.UserId == targetUserId then
		targetUserId = nil
		task.defer(refreshTarget, true)
		toast(leaving.Name .. " left: target is you again", "warn")
	end
end)

----------------------------------------------------------------------------------------------------
-- commands
----------------------------------------------------------------------------------------------------

local busy = setmetatable({}, { __mode = "k" })
local confirmUntil = setmetatable({}, { __mode = "k" })

local function captionLabel(button)
	local label = button:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		return label
	end
	local inner = label and label:FindFirstChild("Text")
	return if inner and inner:IsA("TextLabel") then inner else nil
end

local originalCaptions = setmetatable({}, { __mode = "k" })
local function showCaption(button, value)
	local label = captionLabel(button)
	if label then
		if originalCaptions[button] == nil then
			originalCaptions[button] = label.Text
		end
		label.Text = value or originalCaptions[button]
	end
end

local function argsOf(button)
	local args = {}
	for key, value in pairs(button:GetAttributes()) do
		if #key > 3 and string.sub(key, 1, 3) == "Arg" then
			args[string.sub(key, 4)] = value
		end
	end
	return args
end

local function endConfirm(button)
	confirmUntil[button] = nil
	button:SetAttribute("Confirming", nil)
	showCaption(button, nil)
	paint(button, if hovered[button] then "hover" else "rest")
end

local function run(button)
	local command = button:GetAttribute("Command")
	if type(command) ~= "string" or busy[button] then
		return
	end
	if button:GetAttribute("Confirm") == true then
		local now = os.clock()
		if (confirmUntil[button] or 0) < now then
			local deadline = now + CONFIRM_SECONDS
			confirmUntil[button] = deadline
			button:SetAttribute("Confirming", true)
			showCaption(button, "TAP AGAIN")
			paint(button, "confirm")
			toast("Tap again to confirm: " .. tostring(originalCaptions[button] or command), "warn")
			task.delay(CONFIRM_SECONDS, function()
				if confirmUntil[button] == deadline then
					endConfirm(button)
				end
			end)
			return
		end
		endConfirm(button)
	end
	local remote = getRemote()
	if remote == nil then
		toast("The admin service is not running on this server", "error")
		return
	end
	busy[button] = true
	showCaption(button, "...")
	toast("Working...", "busy")
	local wanted = targetUserId
	local ok, success, message, summary = pcall(remote.InvokeServer, remote, command, wanted, argsOf(button))
	busy[button] = nil
	showCaption(button, nil)
	if not ok then
		toast("No answer from the server: " .. tostring(success), "error")
		return
	end
	toast(message, if success then "ok" else "error")
	if type(summary) == "table" and summary.UserId == targetPlayer().UserId then
		lastSummary = summary
		renderInfo()
	end
end

for _, node in ipairs(window:GetDescendants()) do
	if node:IsA("GuiButton") and type(node:GetAttribute("Command")) == "string" then
		feel(node)
		node.Activated:Connect(function()
			run(node)
		end)
	end
end

local close = window:FindFirstChild("Close")
if close and close:IsA("GuiButton") then
	close.Activated:Connect(function()
		setOpen(false)
	end)
end

----------------------------------------------------------------------------------------------------
-- weapon cards: names from Library.Modules.HeroWeapons, 3D portraits from Library.Client.WeaponPortrait
----------------------------------------------------------------------------------------------------

task.spawn(function()
	local library = ReplicatedStorage:WaitForChild("Library", 30)
	local modules = library and library:FindFirstChild("Modules")
	local heroWeapons = nil
	local weaponsModule = modules and modules:FindFirstChild("HeroWeapons")
	if weaponsModule then
		local ok, result = pcall(require, weaponsModule)
		heroWeapons = if ok and type(result) == "table" then result else nil
	end
	local portraitModule = library and find(library, "Client.WeaponPortrait")
	local portraits = nil
	if portraitModule then
		local ok, result = pcall(require, portraitModule)
		portraits = if ok and type(result) == "table" then result else nil
	end
	local page = pages:FindFirstChild("Page_Weapons")
	for _, cardNode in ipairs(page and page:GetChildren() or {}) do
		local tool = cardNode:GetAttribute("ArgTool")
		if type(tool) == "string" then
			if heroWeapons then
				local ok, weapon = pcall(function()
					return heroWeapons.WEAPONS[heroWeapons.BY_TOOL[tool]]
				end)
				if ok and type(weapon) == "table" then
					setText(cardNode:FindFirstChild("WeaponName"), string.upper(tostring(weapon.DisplayName)))
					setText(cardNode:FindFirstChild("Hero"), tostring(weapon.Hero))
				end
			end
			local portrait = cardNode:FindFirstChild("Portrait")
			if portraits and portrait and type(portraits.Mount) == "function" then
				pcall(portraits.Mount, portrait, tool)
			end
		end
	end
end)

----------------------------------------------------------------------------------------------------
-- server stats (Server page) + the dummy counter, only while the panel is open
----------------------------------------------------------------------------------------------------

local nightUtil = nil
task.spawn(function()
	local library = ReplicatedStorage:WaitForChild("Library", 30)
	local module = library and find(library, "Util.AreaEggResetTimeUtil")
	if module then
		local ok, result = pcall(require, module)
		nightUtil = if ok and type(result) == "table" then result else nil
	end
end)

local serverPage = pages:FindFirstChild("Page_Server")
local function stat(name, value, color)
	local tile = serverPage and serverPage:FindFirstChild("Stat_" .. name)
	local label = tile and tile:FindFirstChild("Value")
	if label and label:IsA("TextLabel") then
		setText(label, value)
		label.TextColor3 = color or COLORS.white
	end
end

updateStats = function()
	local hz = Workspace:GetAttribute("ServerHz")
	local hzColor = if type(hz) ~= "number" then COLORS.white elseif hz >= 55 then COLORS.ok elseif hz >= 40 then COLORS.warn else COLORS.error
	stat("ServerHz", if type(hz) == "number" then string.format("%.1f", hz) else "--", hzColor)
	local frameMs = Workspace:GetAttribute("ServerFrameMs")
	stat("FrameMs", if type(frameMs) == "number" then string.format("%.1f", frameMs) else "--",
		if type(frameMs) == "number" and frameMs > 50 then COLORS.warn else nil)
	local memory = Workspace:GetAttribute("ServerMemoryMB")
	stat("MemoryMB", if type(memory) == "number" then tostring(math.floor(memory)) else "--")
	stat("Players", string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers))
	stat("Uptime", clock(Workspace.DistributedGameTime))
	if nightUtil then
		local ok, text, color = pcall(function()
			local now = Workspace:GetServerTimeNow()
			if nightUtil.IsNight(now) then
				return "NIGHT " .. clock(nightUtil.GetPhaseTimeLeft(now)), COLORS.gold
			end
			return clock(nightUtil.GetPhaseTimeLeft(now)), nil
		end)
		if ok then
			stat("NextNight", text, color)
		end
	end
	local session = serverPage and find(serverPage, "SessionInfo.Text")
	setText(session, string.format("%s   |   Place version %d   |   Server %s   |   %s",
		if RunService:IsStudio() then "Studio test server" else "Live server", game.PlaceVersion,
		if game.JobId ~= "" then string.sub(game.JobId, 1, 8) else "local", "Your role: Hero admin"))
	local dummies = Workspace:FindFirstChild("HeroWeaponDummies")
	local count = 0
	for _, child in ipairs(dummies and dummies:GetChildren() or {}) do
		if child:IsA("Model") then
			count += 1
		end
	end
	setText(find(pages, "Page_Weapons.DummyCount"), string.format("%d / 4", count))
	renderInfo()
end

task.spawn(function()
	while gui.Parent do
		if open then
			updateStats()
		end
		task.wait(STATS_EVERY)
	end
end)

do
	local badge = find(window, "ModeBadge.Text")
	setText(badge, if RunService:IsStudio() then "STUDIO" else "LIVE SERVER")
end

----------------------------------------------------------------------------------------------------
-- the 3D crown: header + topbar, orbiting camera with a gentle tilt
----------------------------------------------------------------------------------------------------

local spinners = {}

local function addSpinner(viewport, speed, phase, active)
	local camera = viewport:FindFirstChildOfClass("Camera")
	if camera == nil then
		camera = Instance.new("Camera")
		camera.Parent = viewport
	end
	viewport.CurrentCamera = camera
	local center = viewport:GetAttribute("CrownCenter")
	local distance = viewport:GetAttribute("CrownDistance")
	local elevation = viewport:GetAttribute("CrownElevation")
	table.insert(spinners, {
		viewport = viewport, camera = camera, speed = speed, phase = phase or 0, active = active,
		center = if typeof(center) == "Vector3" then center else Vector3.new(0, 1.15, 0),
		distance = if type(distance) == "number" then distance else 6.4,
		elevation = if type(elevation) == "number" then elevation else math.rad(16),
	})
end

do
	local elapsed, sinceDraw = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		sinceDraw += dt
		if sinceDraw < 1 / SPIN_HZ then
			return
		end
		sinceDraw = 0
		for _, spin in ipairs(spinners) do
			if spin.viewport.Parent ~= nil and spin.active() then
				local yaw = spin.phase + elapsed * spin.speed
				local tilt = spin.elevation + math.sin(elapsed * 1.3 + spin.phase) * math.rad(4)
				spin.camera.CFrame = CFrame.new(spin.center) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-tilt, 0, 0)
					* CFrame.new(0, 0, spin.distance)
			end
		end
	end)
end

local headerCrown = window:FindFirstChild("Crown3D")
if headerCrown and headerCrown:IsA("ViewportFrame") then
	addSpinner(headerCrown, math.rad(40), 0, function()
		return open
	end)
end

----------------------------------------------------------------------------------------------------
-- topbar icon (TopbarPlus v3), next to Backpack and Settings
----------------------------------------------------------------------------------------------------

local function mountIconArt(newIcon)
	local ok, image = pcall(function()
		return newIcon:getInstance("IconImage")
	end)
	if not ok or typeof(image) ~= "Instance" or headerCrown == nil then
		return
	end
	local art = headerCrown:Clone()
	art.Name = "HeroAdminCrown3D"
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.fromScale(0.5, 0.5)
	art.Size = UDim2.fromScale(1.12, 1.12)
	art.ZIndex = image.ZIndex + 1
	art.Parent = image
	pcall(function()
		newIcon:modifyTheme({ "IconImage", "ImageTransparency", 1 })
	end)
	addSpinner(art, math.rad(26), 1.1, function()
		return newIcon.isEnabled ~= false
	end)
end

local function createIcon()
	local library = ReplicatedStorage:WaitForChild("Library", 30)
	local module = library and find(library, "Modules.Packages.TopBarPlus")
	if not (module and module:IsA("ModuleScript")) then
		warn("[HeroAdmin] TopbarPlus not found: the admin panel has no topbar icon (the panel still opens with F4)")
		return nil
	end
	local ok, Icon = pcall(require, module)
	if not ok or type(Icon) ~= "table" or type(Icon.new) ~= "function" then
		warn("[HeroAdmin] TopbarPlus failed to load: " .. tostring(Icon))
		return nil
	end
	local fallback = gui:FindFirstChild("FallbackIcon")
	local newIcon = Icon.new()
	newIcon:setName(ICON_NAME)
	if fallback and fallback:IsA("StringValue") and fallback.Value ~= "" then
		newIcon:setImage(fallback.Value)
	end
	newIcon:setImageScale(0.95)
	newIcon:setOrder(ICON_ORDER)
	newIcon:setCaption("Admin panel (F4)")
	newIcon.deselectWhenOtherIconSelected = false
	newIcon.toggled:Connect(function(isSelected)
		setOpen(isSelected)
	end)
	task.defer(mountIconArt, newIcon)
	return newIcon
end

local function applyAccess()
	local allowed = player:GetAttribute(ADMIN_ATTRIBUTE) == true
	if icon then
		pcall(icon.setEnabled, icon, allowed)
	end
	if not allowed then
		setOpen(false)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= TOGGLE_KEY or player:GetAttribute(ADMIN_ATTRIBUTE) ~= true then
		return
	end
	if icon == nil then
		setOpen(not open)
	end
	-- with a topbar icon, its own toggle key binding handles F4
end)

----------------------------------------------------------------------------------------------------
-- start
----------------------------------------------------------------------------------------------------

do
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local newCamera = Workspace.CurrentCamera
		if newCamera then
			newCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
			fit()
		end
	end)
	fit()
end

task.spawn(function()
	-- MenuMotionController (Branch client): count this panel as an open menu (see the header note)
	local scripts = player:WaitForChild("PlayerScripts", 30)
	local controllers = scripts and scripts:WaitForChild("BranchControllers", 30)
	local module = controllers and controllers:WaitForChild("MenuMotionController", 30)
	if module and module:IsA("ModuleScript") then
		local ok, controller = pcall(require, module)
		if ok and type(controller) == "table" and type(controller.POP_PANELS) == "table" then
			controller.POP_PANELS[gui.Name] = "HeroAdminNoPop"
			menuMotion = controller
			refreshMenuMotion()
		end
	end
end)

icon = createIcon()
if icon then
	pcall(icon.bindToggleKey, icon, TOGGLE_KEY)
end
applyAccess()
player:GetAttributeChangedSignal(ADMIN_ATTRIBUTE):Connect(applyAccess)
refreshTarget(false)
toast("Ready. Every button acts on the target player.", "idle")
