--!nocheck
-- scripts/steps/ui_75_base_themes.luau (owner BASES, Gekko TO DO #5 "Index Completion Rewards")
-- The Index window's "STAGE BASES" page: per stage, the exclusive base theme its Hero Index unlocks (progress, a 3D
-- preview, EQUIP / EQUIPPED). Built with the UI kit (scripts/lib/ui_kit.luau, theme "index") after ui_50_revamp
-- restyled the Index; nothing of the existing Index is moved, renamed or restyled. Driven at runtime by
-- StarterPlayerScripts.GUI.BaseThemes (src/StarterPlayer/StarterPlayerScripts/GUI/BaseThemes.client.luau); data from
-- ReplicatedStorage.Directory.BaseThemes, equip through Network["BaseThemes: RequestEquip"].
--
-- Nodes (StarterGui.Index.Index = the TabController root):
--   SpBasesButton               glossy gold TextButton on the header band, between the title and the X (z 103):
--     Label                     "STAGE BASES" (the client writes "HEROES" while the page is open)
--     Badge                     red dot, hidden (the client shows it while an unlocked base waits to be equipped)
--   Content.SpBaseThemesPage    Frame over Content.IndexPage (z 20, Active so clicks never reach the hero grid),
--                               hidden; UiKit.panel
--     List                      left column, UIListLayout of six rows
--       Row_<Key>               TextButton card (LayoutOrder = stage number):
--         Swatch (Gradient, Number), Name, Sub, State (Label), Bar (Fill), Count
--     Detail                    right card:
--       Banner (Gradient, Franchise, Title), Preview (ViewportFrame: Lock (Shackle, Body, Text)), Tagline,
--       Requirement, Bar (Fill), EquipButton (Label)
-- Lune: FontFace / the four UICorner radii / ImageContent through the kit; TextScaled labels also TextWrapped.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local UiKit = require("../lib/ui_kit")
local Kit = UiKit.Kit

local Color3 = roblox.Color3
local ColorSequence = roblox.ColorSequence
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local Enum = roblox.Enum

local Step = {}

Step.DIRECTORY_SOURCE = "src/ReplicatedStorage/Directory/BaseThemes.luau"
Step.BUTTON = "SpBasesButton"
Step.PAGE = "SpBaseThemesPage"

local T = UiKit.Themes.index
local WHITE = UiKit.WHITE
local INK = UiKit.INK
local GOLD = Kit.hex("#ffb81c")
local LOCKED = Kit.hex("#4f5674")
local TRACK = Kit.hex("#0b1030")

local function log(fmt, ...)
	print(string.format("[ui_75_base_themes] " .. fmt, ...))
end

local function loadDirectory()
	local chunk = luau.load(fs.readFile(Step.DIRECTORY_SOURCE), { debugName = Step.DIRECTORY_SOURCE, environment = { Color3 = Color3 } })
	return chunk()
end

local function frame(parent, name, zIndex, color, transparency)
	local node = UiKit.layer(parent, "Frame", name, zIndex)
	node.BackgroundColor3 = color or WHITE
	node.BackgroundTransparency = transparency or 0
	return node
end

-- progress bar: dark track + Fill (scale width written by the client)
local function bar(parent, anchor, position, size, color, zIndex)
	local track = frame(parent, "Bar", zIndex, TRACK, 0)
	UiKit.setBox(track, anchor, position, size)
	Kit.setCorner(track, 0.5)
	Kit.addStroke(track, { name = "SpStroke", color = INK, thickness = 0.12, mode = "Border" })
	local fill = frame(track, "Fill", zIndex + 1, color, 0)
	UiKit.setBox(fill, Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(0, 1))
	Kit.setCorner(fill, 0.5)
	Kit.addGradient(fill, { { 0, "#ffffff" }, { 1, "#b8b8b8" } }, 90, "SpGloss")
	return track, fill
end

local function themeGradient(node, theme)
	return Kit.addGradient(node, ColorSequence.new({
		roblox.ColorSequenceKeypoint.new(0, theme.Ui.Top),
		roblox.ColorSequenceKeypoint.new(0.5, theme.Ui.Mid),
		roblox.ColorSequenceKeypoint.new(1, theme.Ui.Bottom),
	}), 90, "Gradient")
end

local function buildRow(list, key, theme)
	local row = UiKit.layer(list, "TextButton", "Row_" .. key, 22)
	row.Text = ""
	row.AutoButtonColor = false
	row.Active = true
	row.Selectable = true
	row.LayoutOrder = theme.Number
	row.Size = UDim2.fromScale(1, 0.152)
	UiKit.card(row, { color = T.card, strokeColor = T.cardStroke, corner = 0.2, stroke = 0.02 })

	local swatch = frame(row, "Swatch", 23, WHITE, 0)
	UiKit.setBox(swatch, Vector2.new(0, 0.5), UDim2.fromScale(0.025, 0.5), UDim2.fromScale(0.16, 0.8))
	UiKit.aspect(swatch, 1)
	Kit.setCorner(swatch, 0.25)
	themeGradient(swatch, theme)
	Kit.addStroke(swatch, { name = "SpStroke", color = INK, thickness = 0.06, mode = "Border" })
	UiKit.text(swatch, "Number", tostring(theme.Number), "title", {
		size = UDim2.fromScale(0.8, 0.8), zIndex = 24, stroke = 0.12,
	})

	UiKit.text(row, "Name", theme.Name, "title", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.215, 0.1), size = UDim2.fromScale(0.52, 0.36),
		zIndex = 23, alignX = Enum.TextXAlignment.Left,
	})
	UiKit.text(row, "Sub", theme.Franchise, "body", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.215, 0.46), size = UDim2.fromScale(0.5, 0.24),
		zIndex = 23, alignX = Enum.TextXAlignment.Left, color = Kit.hex("#aeb8e8"),
	})
	bar(row, Vector2.new(0, 0), UDim2.fromScale(0.215, 0.74), UDim2.fromScale(0.52, 0.14), theme.Ui.Mid, 23)
	UiKit.text(row, "Count", "0/6", "number", {
		anchor = Vector2.new(0, 0.5), position = UDim2.fromScale(0.75, 0.81), size = UDim2.fromScale(0.22, 0.28),
		zIndex = 23, alignX = Enum.TextXAlignment.Left,
	})
	local state = frame(row, "State", 23, LOCKED, 0)
	UiKit.setBox(state, Vector2.new(1, 0), UDim2.fromScale(0.975, 0.1), UDim2.fromScale(0.24, 0.36))
	Kit.setCorner(state, 0.5)
	Kit.addStroke(state, { name = "SpStroke", color = INK, thickness = 0.08, mode = "Border" })
	UiKit.text(state, "Label", "LOCKED", "badge", { size = UDim2.fromScale(0.88, 0.7), zIndex = 24 })
	return row
end

local function buildDetail(page, first)
	local detail = frame(page, "Detail", 21, T.card, 0)
	UiKit.setBox(detail, Vector2.new(1, 0), UDim2.fromScale(0.988, 0.02), UDim2.fromScale(0.556, 0.96))
	UiKit.card(detail, { color = T.card, strokeColor = T.cardStroke, corner = 0.05, stroke = 0.012 })

	local banner = frame(detail, "Banner", 22, WHITE, 0)
	UiKit.setBox(banner, Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.02), UDim2.fromScale(0.96, 0.17))
	Kit.setCorner(banner, 0.28)
	themeGradient(banner, first)
	Kit.addStroke(banner, { name = "SpStroke", color = INK, thickness = 0.03, mode = "Border" })
	UiKit.studs(banner, 23, { corner = 0.28 })
	UiKit.text(banner, "Franchise", string.format("STAGE %d - %s", first.Number, string.upper(first.Franchise)), "body", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.04, 0.08), size = UDim2.fromScale(0.92, 0.32),
		zIndex = 24, alignX = Enum.TextXAlignment.Left,
	})
	UiKit.text(banner, "Title", first.Name, "title", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.04, 0.38), size = UDim2.fromScale(0.92, 0.54),
		zIndex = 24, alignX = Enum.TextXAlignment.Left, stroke = 0.09,
	})

	local preview = UiKit.layer(detail, "ViewportFrame", "Preview", 22)
	UiKit.setBox(preview, Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.205), UDim2.fromScale(0.96, 0.44))
	preview.BackgroundColor3 = Kit.hex("#7ec8ff")
	preview.BackgroundTransparency = 0
	preview.Ambient = Color3.fromRGB(170, 170, 185)
	preview.LightColor = Color3.fromRGB(255, 250, 240)
	preview.LightDirection = Vector3.new(-0.5, -1, 0.35)
	Kit.setCorner(preview, 0.07)
	Kit.addGradient(preview, { { 0, "#ffffff" }, { 1, "#b9d2ff" } }, 90, "SpSky")
	Kit.addStroke(preview, { name = "SpStroke", color = INK, thickness = 0.012, mode = "Border" })
	local lock = frame(preview, "Lock", 25, Kit.hex("#05081a"), 0.4)
	UiKit.setBox(lock)
	Kit.setCorner(lock, 0.07)
	local shackle = frame(lock, "Shackle", 26, WHITE, 1)
	UiKit.setBox(shackle, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.36), UDim2.fromScale(0.13, 0.26))
	UiKit.aspect(shackle, 0.8)
	Kit.setCorner(shackle, 0.5)
	Kit.addStroke(shackle, { name = "SpStroke", color = WHITE, thickness = 0.16, mode = "Border" })
	local body = frame(lock, "Body", 27, GOLD, 0)
	UiKit.setBox(body, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.2, 0.24))
	UiKit.aspect(body, 1.15)
	Kit.setCorner(body, 0.2)
	Kit.addStroke(body, { name = "SpStroke", color = INK, thickness = 0.06, mode = "Border" })
	UiKit.text(lock, "Text", "LOCKED", "title", { position = UDim2.fromScale(0.5, 0.8), size = UDim2.fromScale(0.8, 0.16), zIndex = 27 })

	UiKit.text(detail, "Tagline", first.Tagline, "body", {
		position = UDim2.fromScale(0.5, 0.685), size = UDim2.fromScale(0.92, 0.07), zIndex = 22, color = Kit.hex("#d7defc"),
	})
	UiKit.text(detail, "Requirement", string.format("%s Index: 0/6 heroes found", first.Franchise), "title", {
		position = UDim2.fromScale(0.5, 0.76), size = UDim2.fromScale(0.92, 0.07), zIndex = 22,
	})
	bar(detail, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.825), UDim2.fromScale(0.86, 0.045), first.Ui.Mid, 22)
	local button = UiKit.labelButton(detail, "EquipButton", "LOCKED", {
		color = LOCKED, anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.92), size = UDim2.fromScale(0.5, 0.115),
		corner = 0.35, zIndex = 23,
	})
	button.Selectable = true
	return detail
end

function Step.Apply(place)
	local directory = loadDirectory()
	local sg = place:GetService("StarterGui")
	local indexGui = sg:FindFirstChild("Index")
	local root = indexGui and indexGui:FindFirstChild("Index")
	local content = root and root:FindFirstChild("Content")
	assert(content and content:FindFirstChild("IndexPage"), "StarterGui.Index.Index.Content.IndexPage missing")

	-- the band button (between the left-aligned title and the X)
	local button = UiKit.labelButton(root, Step.BUTTON, "STAGE BASES", {
		color = GOLD, anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.74, -0.072), size = UDim2.fromScale(0.22, 0.096),
		corner = 0.4, zIndex = 103, stroke = 0.07,
	})
	button.Selectable = true
	local badge = frame(button, "Badge", 105, Kit.hex("#ff2d55"), 0)
	badge.SizeConstraint = Enum.SizeConstraint.RelativeYY
	UiKit.setBox(badge, Vector2.new(0.5, 0.5), UDim2.fromScale(0.97, 0.12), UDim2.fromScale(0.42, 0.42))
	Kit.setCorner(badge, 0.5)
	Kit.addStroke(badge, { name = "SpStroke", color = WHITE, thickness = 0.12, mode = "Border" })
	badge.Visible = false

	-- the page over the hero grid
	local page = UiKit.layer(content, "Frame", Step.PAGE, 20)
	UiKit.setBox(page)
	page.Visible = false
	page.Active = true -- clicks on the page never fall through to the hero entries under it
	UiKit.panel(page, { color = T.panel, transparency = 0, corner = 0.03, stroke = 0.006 })
	UiKit.studs(page, 20, { corner = 0.03 })

	local list = UiKit.layer(page, "Frame", "List", 21)
	list.BackgroundTransparency = 1
	UiKit.setBox(list, Vector2.new(0, 0), UDim2.fromScale(0.012, 0.02), UDim2.fromScale(0.41, 0.96))
	local layout = Kit.ensureChild(list, "UIListLayout", "UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.016, 0)
	for _, key in ipairs(directory.Order) do
		buildRow(list, key, directory.Themes[key])
	end
	buildDetail(page, directory.Themes[directory.Order[1]])

	log("Index STAGE BASES page: band button %s, page Content.%s with %d stage rows + detail (preview, EQUIP)",
		Step.BUTTON, Step.PAGE, #directory.Order)
end

return Step
