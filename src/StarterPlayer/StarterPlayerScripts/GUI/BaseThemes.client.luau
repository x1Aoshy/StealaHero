-- StarterPlayerScripts.GUI.BaseThemes (LocalScript, owner BASES, Gekko TO DO #5 "Index Completion Rewards")
-- Drives the Index window's STAGE BASES page (built by scripts/steps/ui_75_base_themes.luau): one row per stage with
-- its base theme's progress (heroes of that stage discovered), a detail card with a 3D preview of the theme
-- (ReplicatedStorage.Assets.BaseThemes.<Key>, built by scripts/steps/post_zz_base_themes.luau) and the EQUIP /
-- EQUIPPED button. The server owns everything: IndexService unlocks a theme when its stage's Index is complete and
-- answers Network["BaseThemes: RequestEquip"](key | "") -> (ok, err?, equippedKey?); PlotService shows the equipped
-- theme on the owner's plot. This script only reads the replicated save (UnlockedBaseThemes, EquippedBaseTheme,
-- Index) and sends equip requests; a missing piece disables the page instead of erroring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local EQUIP_REMOTE = "BaseThemes: RequestEquip"
local BUTTON_NAME = "SpBasesButton"
local PAGE_NAME = "SpBaseThemesPage"

local COLORS = {
	locked = Color3.fromRGB(79, 86, 116),
	equip = Color3.fromRGB(43, 214, 60),
	equipped = Color3.fromRGB(255, 184, 28),
	unlockedPill = Color3.fromRGB(43, 170, 255),
	rowStroke = Color3.fromRGB(61, 74, 146),
	selectedStroke = Color3.fromRGB(255, 214, 64),
	barLocked = Color3.fromRGB(120, 130, 170),
}

local function optionalRequire(label, getModule)
	local ok, result = pcall(function()
		local module = getModule()
		return module and require(module)
	end)
	if ok and result ~= nil then
		return result
	end
	warn("[BaseThemes] " .. label .. " unavailable: " .. tostring(result))
	return nil
end

local Library = ReplicatedStorage:WaitForChild("Library")
local Client = Library:WaitForChild("Client")
local BaseThemes = optionalRequire("Directory.BaseThemes", function()
	return ReplicatedStorage:WaitForChild("Directory"):WaitForChild("BaseThemes", 15)
end)
local Network = optionalRequire("Library.Client.Network", function()
	return Client:WaitForChild("Network", 15)
end)
local Save = optionalRequire("Library.Client.Save", function()
	return Client:WaitForChild("Save", 15)
end)
local TabController = optionalRequire("Library.Client.TabController", function()
	return Client:FindFirstChild("TabController")
end)
local Message = optionalRequire("NotificationCmds.Message", function()
	local cmds = Client:FindFirstChild("NotificationCmds")
	return cmds and cmds:FindFirstChild("Message")
end)
local ButtonFX = optionalRequire("GUIFX.ButtonFX", function()
	local fx = Client:FindFirstChild("GUIFX")
	return fx and fx:FindFirstChild("ButtonFX")
end)

if not (BaseThemes and Network and Save) then
	warn("[BaseThemes] Stage bases page disabled (missing modules)")
	return
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local indexGui = playerGui:WaitForChild("Index", 60)
local root = indexGui and indexGui:WaitForChild("Index", 15)
local content = root and root:WaitForChild("Content", 15)
local toggle = root and root:WaitForChild(BUTTON_NAME, 15)
local page = content and content:WaitForChild(PAGE_NAME, 15)
local list = page and page:FindFirstChild("List")
local detail = page and page:FindFirstChild("Detail")
if not (toggle and page and list and detail) then
	warn("[BaseThemes] Stage bases page missing from the Index (scripts/steps/ui_75_base_themes.luau)")
	return
end

local toggleLabel = toggle:FindFirstChild("Label")
local badge = toggle:FindFirstChild("Badge")
local banner = detail:FindFirstChild("Banner")
local preview = detail:FindFirstChild("Preview")
local lock = preview and preview:FindFirstChild("Lock")
local equipButton = detail:FindFirstChild("EquipButton")
local equipLabel = equipButton and equipButton:FindFirstChild("Label")
local detailBar = detail:FindFirstChild("Bar")
local detailFill = detailBar and detailBar:FindFirstChild("Fill")

local selectedKey = BaseThemes.Order[1]
local pageOpen = false
local busy = false
local knownUnlocked = nil -- set of unlocked keys at the last render (nil before the first one)
local seenSinceOpen = {} -- keys unlocked while the page was closed (badge)

---------------------------------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------------------------------

local function setText(parent, name, text)
	local label = parent and parent:FindFirstChild(name)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function setGradient(node, theme)
	local gradient = node and node:FindFirstChild("Gradient")
	if gradient and gradient:IsA("UIGradient") then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Ui.Top),
			ColorSequenceKeypoint.new(0.5, theme.Ui.Mid),
			ColorSequenceKeypoint.new(1, theme.Ui.Bottom),
		})
	end
end

local function setFill(fill, fraction, color)
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		fill.BackgroundColor3 = color
		fill.Visible = fraction > 0
	end
end

local function playSfx(name)
	local folder = SoundService:FindFirstChild("SpeedstersSfx")
	local sound = folder and folder:FindFirstChild(name)
	if sound and sound:IsA("Sound") then
		pcall(function()
			sound:Play()
		end)
	end
end

local function notify(text, color)
	if Message and type(Message.Bottom) == "function" then
		pcall(Message.Bottom, { Message = text, Time = 2.5, Color = color })
	end
end

local function getSave()
	local ok, save = pcall(Save.Get, LocalPlayer)
	if ok and type(save) == "table" then
		return save
	end
	return nil
end

local function stateOf(save, key)
	local unlocked = save and type(save.UnlockedBaseThemes) == "table" and save.UnlockedBaseThemes[key] == true
	local equipped = unlocked and save.EquippedBaseTheme == key
	local found, total = BaseThemes.GetProgress(save and save.Index, key)
	return unlocked, equipped, found, total
end

---------------------------------------------------------------------------------------------------
-- 3D preview
---------------------------------------------------------------------------------------------------

local previewModels = {} -- key -> Model clone (parented to the viewport only while selected)
local previewCamera = nil
local orbitConnection = nil
local PREVIEW_TARGET = Vector3.new(0, 9, 10) -- the canonical pen is centred on the origin, gate toward -Z
local PREVIEW_OFFSET = Vector3.new(0, 40, -96)

local function showPreview(key)
	if not (preview and preview:IsA("ViewportFrame")) then
		return
	end
	if previewCamera == nil then
		previewCamera = Instance.new("Camera")
		previewCamera.FieldOfView = 40
		previewCamera.Parent = preview
		preview.CurrentCamera = previewCamera
	end
	for otherKey, model in pairs(previewModels) do
		if otherKey ~= key then
			model.Parent = nil
		end
	end
	local model = previewModels[key]
	if model == nil then
		local assets = ReplicatedStorage:FindFirstChild("Assets")
		local folder = assets and assets:FindFirstChild("BaseThemes")
		local source = folder and folder:FindFirstChild(key)
		if source then
			model = source:Clone()
			previewModels[key] = model
		end
	end
	if model then
		model.Parent = preview
	end
end

local function updateCamera(t)
	if previewCamera then
		local yaw = math.sin(t * 0.35) * 0.5
		local eye = PREVIEW_TARGET + (CFrame.Angles(0, yaw, 0) * PREVIEW_OFFSET)
		previewCamera.CFrame = CFrame.lookAt(eye, PREVIEW_TARGET)
	end
end

local function setOrbiting(on)
	if on and orbitConnection == nil then
		local start = os.clock()
		orbitConnection = RunService.RenderStepped:Connect(function()
			updateCamera(os.clock() - start)
		end)
	elseif not on and orbitConnection then
		orbitConnection:Disconnect()
		orbitConnection = nil
	end
	updateCamera(0)
end

---------------------------------------------------------------------------------------------------
-- render
---------------------------------------------------------------------------------------------------

local function renderRow(save, key)
	local theme = BaseThemes.Get(key)
	local row = list:FindFirstChild("Row_" .. key)
	if not (theme and row) then
		return
	end
	local unlocked, equipped, found, total = stateOf(save, key)
	setText(row, "Name", theme.Name)
	setText(row, "Sub", theme.Franchise)
	setText(row, "Count", string.format("%d/%d", found, total))
	local barNode = row:FindFirstChild("Bar")
	setFill(barNode and barNode:FindFirstChild("Fill"), if total > 0 then found / total else 0, if unlocked then theme.Ui.Mid else COLORS.barLocked)
	setGradient(row:FindFirstChild("Swatch"), theme)
	local state = row:FindFirstChild("State")
	if state and state:IsA("GuiObject") then
		state.BackgroundColor3 = if equipped then COLORS.equipped elseif unlocked then COLORS.unlockedPill else COLORS.locked
		setText(state, "Label", if equipped then "EQUIPPED" elseif unlocked then "UNLOCKED" else "LOCKED")
	end
	local stroke = row:FindFirstChild("SpStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = if key == selectedKey then COLORS.selectedStroke else COLORS.rowStroke
		stroke.Thickness = if key == selectedKey then 0.05 else 0.02
	end
end

local function renderDetail(save)
	local key = selectedKey
	local theme = BaseThemes.Get(key)
	if not theme then
		return
	end
	local unlocked, equipped, found, total = stateOf(save, key)
	setGradient(banner, theme)
	setText(banner, "Franchise", string.format("STAGE %d - %s", theme.Number, string.upper(theme.Franchise)))
	setText(banner, "Title", theme.Name)
	setText(detail, "Tagline", theme.Tagline)
	if unlocked then
		setText(detail, "Requirement", string.format("%s Index complete: %d/%d heroes!", theme.Franchise, found, total))
	else
		setText(detail, "Requirement", string.format("%s Index: %d/%d heroes found", theme.Franchise, found, total))
	end
	setFill(detailFill, if total > 0 then found / total else 0, if unlocked then theme.Ui.Mid else COLORS.barLocked)
	if lock and lock:IsA("GuiObject") then
		lock.Visible = not unlocked
	end
	if equipButton and equipButton:IsA("GuiObject") then
		equipButton.BackgroundColor3 = if equipped then COLORS.equipped elseif unlocked then COLORS.equip else COLORS.locked
	end
	if equipLabel and equipLabel:IsA("TextLabel") then
		equipLabel.Text = if busy then "..." elseif equipped then "EQUIPPED" elseif unlocked then "EQUIP" else "LOCKED"
	end
	showPreview(key)
end

local function render()
	local save = getSave()
	for _, key in ipairs(BaseThemes.Order) do
		renderRow(save, key)
	end
	renderDetail(save)

	if save == nil then
		return
	end
	-- new unlocks: celebrate, select it and flag the button until the page is opened
	local unlockedNow = {}
	for _, key in ipairs(BaseThemes.Order) do
		if stateOf(save, key) then
			unlockedNow[key] = true
			if knownUnlocked ~= nil and not knownUnlocked[key] then
				seenSinceOpen[key] = true
				selectedKey = key
				playSfx("WINNER")
			end
		end
	end
	knownUnlocked = unlockedNow
	-- the badge: a base waits to be equipped, or one was unlocked since the page was last opened
	local waiting = (save.EquippedBaseTheme == "" and next(unlockedNow) ~= nil) or next(seenSinceOpen) ~= nil
	if badge and badge:IsA("GuiObject") then
		badge.Visible = waiting and not pageOpen
	end
end

---------------------------------------------------------------------------------------------------
-- interaction
---------------------------------------------------------------------------------------------------

local function setPageOpen(open)
	pageOpen = open
	page.Visible = open
	if toggleLabel and toggleLabel:IsA("TextLabel") then
		toggleLabel.Text = if open then "HEROES" else "STAGE BASES"
	end
	if open then
		-- land on a freshly unlocked base, else the equipped one, else the next stage to complete
		local save = getSave()
		local fresh = next(seenSinceOpen)
		if fresh and BaseThemes.Get(fresh) then
			selectedKey = fresh
		elseif save and type(save.EquippedBaseTheme) == "string" and BaseThemes.Get(save.EquippedBaseTheme) then
			selectedKey = save.EquippedBaseTheme
		elseif save then
			for _, key in ipairs(BaseThemes.Order) do
				if not stateOf(save, key) then
					selectedKey = key
					break
				end
			end
		end
		table.clear(seenSinceOpen)
	end
	setOrbiting(open)
	render()
end

local function selectTheme(key)
	if BaseThemes.Get(key) then
		selectedKey = key
		playSfx("UI_CLICK")
		render()
	end
end

local function requestEquip()
	if busy then
		return
	end
	local save = getSave()
	local key = selectedKey
	local theme = BaseThemes.Get(key)
	local unlocked, equipped, found, total = stateOf(save, key)
	if not theme then
		return
	end
	if not unlocked then
		notify(string.format("Complete the Hero Index of %s to unlock this base (%d/%d)", theme.Franchise, found, total), Color3.fromRGB(255, 96, 96))
		return
	end
	busy = true
	render()
	local ok, success, err = pcall(Network.Invoke, EQUIP_REMOTE, if equipped then "" else key)
	busy = false
	if ok and success == true then
		playSfx(if equipped then "UI_POP" else "UPGRADE")
		notify(if equipped then "Back to the plain base" else theme.Name .. " base equipped!", if equipped then nil else Color3.fromRGB(255, 214, 64))
	else
		notify("Could not change the base: " .. tostring(if ok then err else success), Color3.fromRGB(255, 96, 96))
	end
	render()
end

if ButtonFX then
	for _, button in ipairs({ toggle, equipButton }) do
		if button and button:IsA("GuiButton") then
			pcall(ButtonFX, button)
		end
	end
end

toggle.Activated:Connect(function()
	playSfx("UI_CLICK")
	setPageOpen(not pageOpen)
end)

if equipButton and equipButton:IsA("GuiButton") then
	equipButton.Activated:Connect(requestEquip)
end

for _, key in ipairs(BaseThemes.Order) do
	local row = list:FindFirstChild("Row_" .. key)
	if row and row:IsA("GuiButton") then
		row.Activated:Connect(function()
			selectTheme(key)
		end)
	end
end

-- the Index always reopens on the hero grid
if TabController and TabController.Closed then
	pcall(function()
		TabController.Closed:Connect(function(name)
			if name == "Index" and pageOpen then
				setPageOpen(false)
			end
		end)
	end)
end

-- live data: unlocks, equips and discoveries
pcall(function()
	Save.ConnectForDataChanged({ "UnlockedBaseThemes", "EquippedBaseTheme", "Index" }, function()
		render()
	end)
end)

task.spawn(render)
