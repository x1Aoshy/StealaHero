-- scripts/apply_speedters_ui.luau
-- Build step 14 ("ui"): the structural base that the Speedsters Escape UI port builds on. The port itself is
-- scripts/steps/ui_*.luau (step 14b), which uses scripts/lib/speedsters_ui_kit.luau.
--
-- Phase 3 (CONTRACTS_PHASE3 D1) replaced the earlier navy concept with the real Speedsters materials. This step no
-- longer paints anything:
--   * no #182644 panels on windows, popups, tabs or value cards;
--   * no px strokes, px corners or stroke normalising (buttonPass / strokePass);
--   * no FredokaOne on every text (fontPass). The ui_* steps set fonts per role.
-- What remains, and why:
--   1. Tabs.GrowingEggs: egg Icon hidden, "EGGS" label.            (tests U9/U10; the HUD skin reuses the label)
--   2. Tabs.Pets: paw Vector hidden, Speedsters HeroIcon, "HERO INDEX" label.  (tests U10/U11; SAH branding)
--   3. Left.Tools Index/Shop: visual content re-aligned onto the click box, Speedsters HeroIcon/ShopIcon,
--      "Hero Index"/"Shop" labels.                                    (test U12; the sidebar skin builds on it)
--   4. Money/SpeedValue cards:
--        - Speedsters CurrencyIcon and SpeedtersShoe;
--        - rows fitted inside the card box (scale UIPadding);
--        - gold money text and cyan CurrentBoost.                     (test U13; the currency-counter skin builds on it)
--   5. Index window title text "Hero Index".                          (content, not style)
-- The labels added or kept above get the Speedsters label recipe from the kit (FredokaOne + a Contextual
-- ScaledSize #0b1b3d outline). The kit is idempotent, so the ui_* steps can restyle them again.
--
-- D2 notes:
--   * Tabs.GrowingEggs.Icon and Tabs.Pets.Vector keep Visible=false. No script drives them; tests U9/U11 assert it.
--     They are also made transparent, so either check holds.
--   * Every other hide uses transparency only.
--   * SpeedValue.CurrentBoost.Shadow TextColor3 is script-owned (TreadmillUI:76) and is not written.
--   * Workspace (plot signs) belongs to scripts/steps/plots.luau and is never touched here.

local roblox = require("@lune/roblox")
local Kit = require("./lib/speedsters_ui_kit")

local Instance = roblox.Instance
local Color3 = roblox.Color3
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum

-- CurrentBoost cyan (#00e5ff) is asserted by tests/test_ui_styling.luau U13. The money gold is the Speedsters
-- accent (Kit.Colors.accentGold #ffcc00).
local SPEED_CYAN = Color3.fromRGB(0, 229, 255)

-- Exemplar paths in the Speedsters place (materials.json sourcePaths).
local SP_INDEX_ICON = "StarterGui.Mainhud.LeftSideBar.Index.Icon"
local SP_SHOP_ICON = "StarterGui.Mainhud.LeftSideBar.Shop.Icon"
local SP_TROPHY_ICON = "StarterGui.Mainhud.Rebith/trof.Icon"
local SP_SHOE_BUTTON = "StarterGui.WalkSpeedSelectorHUD.SelectorHolder.WalkSpeedModeButton"

-- Steal a Hero's own egg sticker (the art the base place puts on Elements.Tabs.GrowingEggs.Icon). Speedsters
-- Escape has no egg icon in materials.json, so this is the game's own art.
local EGG_ICON = 96783034607256

-- Icon-first tab face, shared with scripts/steps/ui_30_hud.luau (which owns the final look): the icon dominates
-- the top of the tab and the word is a small caption underneath.
local TAB_ICON_SIZE = UDim2.new(0.72, 0, 0.62, 0)
local TAB_ICON_POSITION = UDim2.new(0.5, 0, 0.4, 0)
local TAB_CAPTION_SIZE = UDim2.new(0.92, 0, 0.24, 0)
local TAB_CAPTION_POSITION = UDim2.new(0.5, 0, 0.845, 0)

local findChild = Kit.findChild

local function newTextLabel(name, parent)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = ""
	label.FontFace = Kit.Fonts.body
	label.Parent = parent
	return label
end

-- A Speedsters icon cloned from the Speedsters place (whole subtree), or a plain ImageLabel with the same image.
-- Any previous copy (our own node from an earlier run) is replaced.
local function makeIcon(parent, name, spPlace, spPath, assetId)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local icon = Kit.cloneExemplar(spPlace, spPath)
	if icon == nil or not (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
		icon = Instance.new("ImageLabel")
		Kit.setImage(icon, assetId)
		icon.ScaleType = Enum.ScaleType.Fit
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = icon
	end
	icon.Name = name
	icon.BackgroundTransparency = 1
	return icon
end

---------------------------------------------------------------------------------------------------
-- HUD tabs and tools
---------------------------------------------------------------------------------------------------

-- ZIndex for new tab content (icon/label). It sits above the bevel/inlet overlays (Z0) and the hidden base icon
-- (Z1), and below the runtime badges (Notification/ReadyNotification/Badge, Z3 in the base place). Elements uses
-- Sibling ZIndexBehavior, so this only orders the tab's own children.
-- The word under a tab icon: one centred line, small, never wrapped.
local function placeTabCaption(label, text, zIndex)
	label.Size = TAB_CAPTION_SIZE
	label.Position = TAB_CAPTION_POSITION
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = false
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.AutomaticSize = Enum.AutomaticSize.None
	label.ZIndex = zIndex
	Kit.styleText(label, "sidebar")
	return label
end

local function tabContentZ(button)
	local z = 5
	for _, child in ipairs(button:GetChildren()) do
		if child:IsA("GuiObject") and (string.find(child.Name, "Notification", 1, true) or string.find(child.Name, "Badge", 1, true)) then
			z = math.min(z, child.ZIndex - 1)
		end
	end
	return math.max(z, 2)
end

-- Hides a base icon that the Speedsters icon replaces. Visible=false only where tests assert it (see header).
local function hideBaseIcon(icon, alsoInvisible)
	if not icon then
		return
	end
	Kit.hideDecoration(icon)
	if alsoInvisible then
		icon.Visible = false
	end
end

-- The base place draws the Index/Shop tool buttons' visible content (Frame, Label, Vector) 0.5-0.6 of a button
-- height below the button's own transparent click box. Move that content back onto the click box so the
-- visual and the hit area line up.
local function alignToolButtonContent(button)
	local visual = findChild(button, "Frame", "GuiObject")
	if not visual then
		return
	end
	local dy = visual.Position.Y.Scale - 0.5
	if math.abs(dy) < 0.05 then
		return
	end
	for _, name in ipairs({ "Frame", "Label", "Vector" }) do
		local child = findChild(button, name, "GuiObject")
		if child then
			local p = child.Position
			child.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale - dy, p.Y.Offset)
		end
	end
end

local function toolButton(button, iconName, spPlace, spPath, assetId, labelText)
	alignToolButtonContent(button)
	-- The Speedsters icon takes the place (and geometry) of the old Vector icon.
	local vector = findChild(button, "Vector", "GuiObject")
	local icon = makeIcon(button, iconName, spPlace, spPath, assetId)
	if vector then
		hideBaseIcon(vector, false)
		icon.AnchorPoint = vector.AnchorPoint
		icon.Position = vector.Position
		icon.Size = vector.Size
		icon.ZIndex = math.max(vector.ZIndex, 2)
	else
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 0, 0.5, 0)
		icon.Size = UDim2.new(0.35, 0, 0.8, 0)
		icon.ZIndex = 4
	end
	icon.Parent = button

	local label = findChild(button, "Label", "TextLabel")
	if label then
		label.Text = labelText
		Kit.styleText(label, "sidebar")
	end
end

---------------------------------------------------------------------------------------------------
-- Money / SpeedValue cards (structure only)
---------------------------------------------------------------------------------------------------

-- The base cards are transparent. Their rows ran past the card box: SpeedValue's row is ~1.5x the card width,
-- and Money's is a 1.551-wide container. The fit* functions size each row in scale units against the card's
-- padded content box, so a card skin (panel or counter) always contains its row.
local CARD_PAD_X = 0.035 -- UIPadding, fraction of the card width (~10 px at 1080p)
local CARD_PAD_Y = 0.07 -- UIPadding, fraction of the card height (~4 px at 1080p)
local CARD_ROW_MARGIN = 0.01 -- spare width left at the end of a fitted row

-- Scale padding, so it shrinks with the HUD on small screens instead of eating a phone-sized card.
local function padCard(card)
	local pad = card:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.Parent = card
	end
	pad.PaddingLeft = UDim.new(CARD_PAD_X, 0)
	pad.PaddingRight = UDim.new(CARD_PAD_X, 0)
	pad.PaddingTop = UDim.new(CARD_PAD_Y, 0)
	pad.PaddingBottom = UDim.new(CARD_PAD_Y, 0)
end

-- A TextScaled label with AutomaticSize could still grow past its box; fixed boxes keep the text inside.
local function fixTextBox(label)
	label.AutomaticSize = Enum.AutomaticSize.None
	for _, child in ipairs(label:GetChildren()) do
		if child:IsA("TextLabel") then
			child.AutomaticSize = Enum.AutomaticSize.None
		end
	end
end

local function listPaddingScale(card)
	local layout = card:FindFirstChildOfClass("UIListLayout")
	return if layout then layout.Padding.Scale else 0
end

-- SpeedValue row: shoe + padding + CurrentBoost. The base CurrentBoost is 1.2 card-widths wide. It now takes
-- what is left after the shoe, and TextScaled shrinks long values ("1.2K (x1.5)") to fit.
-- The shoe's own UIAspectRatioConstraint only makes it narrower than its nominal scale, never wider.
local function fitSpeedCard(card, shoe, valueLabel)
	local shoeScale = if shoe then shoe.Size.X.Scale else 0
	local width = 1 - shoeScale - listPaddingScale(card) - CARD_ROW_MARGIN
	valueLabel.Size = UDim2.new(width, 0, valueLabel.Size.Y.Scale, valueLabel.Size.Y.Offset)
	fixTextBox(valueLabel)
end

-- Money row: [coin icon] + value label. The card takes the same width as the speed card, so the two stack as a
-- tidy column. The invisible "Changes" container (money popups) follows the label in the row and now sits just
-- outside the card's right edge. Its absolute size is kept, so the popups look as before.
local function fitMoneyCard(card, valueLabel, icon, widthScale)
	local oldWidth = card.Size.X.Scale
	card.Size = UDim2.new(widthScale, card.Size.X.Offset, card.Size.Y.Scale, card.Size.Y.Offset)

	local rowPad = listPaddingScale(card)
	local iconScale = 0
	if icon then
		-- Square, 75% of the row height. The nominal width only bounds it (FitWithinMaxSize, height wins).
		iconScale = 0.18
		icon.Size = UDim2.new(iconScale, 0, 0.75, 0)
		icon.ScaleType = Enum.ScaleType.Fit
		local aspect = icon:FindFirstChildOfClass("UIAspectRatioConstraint")
		if not aspect then
			aspect = Instance.new("UIAspectRatioConstraint")
			aspect.Parent = icon
		end
		aspect.AspectRatio = 1
		aspect.AspectType = Enum.AspectType.FitWithinMaxSize
		aspect.DominantAxis = Enum.DominantAxis.Width
	end
	local width = 1 - iconScale - (if icon then rowPad else 0) - CARD_ROW_MARGIN
	valueLabel.Size = UDim2.new(width, 0, valueLabel.Size.Y.Scale, valueLabel.Size.Y.Offset)
	fixTextBox(valueLabel)

	-- Keep the popup container's pixel size. The base content box is an unpadded oldWidth card; the new one is
	-- padded.
	local changes = findChild(card, "Changes", "GuiObject")
	if changes and widthScale > 0 then
		local sx = changes.Size.X.Scale * oldWidth / (widthScale * (1 - 2 * CARD_PAD_X))
		local sy = changes.Size.Y.Scale / (1 - 2 * CARD_PAD_Y)
		changes.Size = UDim2.new(sx, changes.Size.X.Offset, sy, changes.Size.Y.Offset)
	end
end

-- The Speedsters shoe as an ImageLabel (the source is an ImageButton, and a button here would swallow clicks). The
-- base shoe image is hidden (transparency), so the two drawings never overlap.
local function addSpeedstersShoe(shoe, spPlace)
	local image = nil
	local aspectSource = nil
	local source = spPlace and Kit.findPath(spPlace, SP_SHOE_BUTTON)
	if source == nil and spPlace then
		local hud = Kit.findPath(spPlace, "StarterGui.WalkSpeedSelectorHUD")
		source = hud and hud:FindFirstChild("WalkSpeedModeButton", true)
	end
	if source and (source:IsA("ImageButton") or source:IsA("ImageLabel")) then
		image = Kit.imageId(source)
		aspectSource = source:FindFirstChildOfClass("UIAspectRatioConstraint")
	end
	image = image or Kit.Icons.speedometer

	local existing = shoe:FindFirstChild("SpeedtersShoe")
	if existing then
		existing:Destroy()
	end
	local speedstersShoe = Instance.new("ImageLabel")
	speedstersShoe.Name = "SpeedtersShoe"
	Kit.setImage(speedstersShoe, image)
	speedstersShoe.ScaleType = Enum.ScaleType.Fit
	speedstersShoe.BackgroundTransparency = 1
	speedstersShoe.AnchorPoint = Vector2.new(0.5, 0.5)
	speedstersShoe.Position = UDim2.new(0.5, 0, 0.5, 0)
	speedstersShoe.Size = UDim2.new(1, 0, 1, 0)
	speedstersShoe.ZIndex = shoe.ZIndex
	if aspectSource then
		aspectSource:Clone().Parent = speedstersShoe
	end
	speedstersShoe.Parent = shoe
	shoe.ImageTransparency = 1
	-- keep the "+" speed button inside the shoe above the new art
	for _, child in ipairs(shoe:GetChildren()) do
		if child:IsA("GuiButton") and child.ZIndex <= speedstersShoe.ZIndex then
			child.ZIndex = speedstersShoe.ZIndex + 1
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Entry point
---------------------------------------------------------------------------------------------------

local function applySpeedtersUi(place, spPlace)
	local starterGui = place:GetService("StarterGui")
	local done = {}
	if spPlace == nil then
		print("[UI Transform] Speedsters place not loaded: built-in Speedsters icon ids used for HeroIcon/ShopIcon/CurrencyIcon/shoe.")
	end

	local elements = starterGui:FindFirstChild("Elements")
	local tabs = elements and elements:FindFirstChild("Tabs")

	-- 1. GrowingEggs tab: ICON-FIRST. The base place's own egg sticker (the art on the hidden `Icon` child) is
	--    re-issued on an SpIcon layer and the word becomes a small caption under it.
	local eggsBtn = tabs and tabs:FindFirstChild("GrowingEggs")
	if eggsBtn then
		local baseIcon = eggsBtn:FindFirstChild("Icon")
		hideBaseIcon(baseIcon, true)
		local eggIcon = makeIcon(eggsBtn, "SpIcon", nil, nil, EGG_ICON)
		eggIcon.Size = TAB_ICON_SIZE
		eggIcon.Position = TAB_ICON_POSITION
		eggIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		eggIcon.ZIndex = tabContentZ(eggsBtn)
		eggIcon.Parent = eggsBtn
		local eggLabel = findChild(eggsBtn, "Label", "TextLabel") or newTextLabel("Label", eggsBtn)
		placeTabCaption(eggLabel, "EGGS", tabContentZ(eggsBtn))
		table.insert(done, "Tabs.GrowingEggs")
	end

	-- 2. Pets tab ("patita"): paw hidden, Speedsters Hero Index icon + a "HERO INDEX" caption
	local petsBtn = tabs and tabs:FindFirstChild("Pets")
	if petsBtn then
		hideBaseIcon(petsBtn:FindFirstChild("Vector"), true)
		local heroIcon = makeIcon(petsBtn, "HeroIcon", spPlace, SP_INDEX_ICON, Kit.Icons.index)
		heroIcon.Size = TAB_ICON_SIZE
		heroIcon.Position = TAB_ICON_POSITION
		heroIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		heroIcon.ZIndex = tabContentZ(petsBtn)
		heroIcon.Parent = petsBtn
		local petsLabel = findChild(petsBtn, "Label", "TextLabel") or newTextLabel("Label", petsBtn)
		placeTabCaption(petsLabel, "HERO INDEX", tabContentZ(petsBtn))
		table.insert(done, "Tabs.Pets")
	end

	-- 3. Left tools: Hero Index and Shop
	local left = elements and elements:FindFirstChild("Left")
	local tools = left and left:FindFirstChild("Tools")
	if tools then
		local indexTool = tools:FindFirstChild("Index")
		local indexBtn = indexTool and indexTool:FindFirstChild("Button")
		if indexBtn then
			toolButton(indexBtn, "HeroIcon", spPlace, SP_INDEX_ICON, Kit.Icons.index, "Hero Index")
			table.insert(done, "Tools.Index")
		end
		local shopTool = tools:FindFirstChild("Shop")
		local shopBtn = shopTool and shopTool:FindFirstChild("Button")
		if shopBtn then
			toolButton(shopBtn, "ShopIcon", spPlace, SP_SHOP_ICON, Kit.Icons.shop, "Shop")
			table.insert(done, "Tools.Shop")
		end
	end

	-- 4. Money and speed ("zapatito") cards: Speedsters icons + rows fitted inside the card box
	local moneyGui = starterGui:FindFirstChild("Money")
	local bottom = moneyGui and moneyGui:FindFirstChild("Bottom")
	local cards = bottom and bottom:FindFirstChild("Frame")
	if cards then
		local speedCard = cards:FindFirstChild("SpeedValue")
		local moneyCard = cards:FindFirstChild("Money")
		if moneyCard then
			padCard(moneyCard)
			local moneyLabel = findChild(moneyCard, "Money", "TextLabel")
			if moneyLabel then
				-- Money: MoneyUpdate writes only Text on the label and its Shadow face, so the colour is ours.
				moneyLabel.TextColor3 = Kit.Colors.accentGold
				local face = findChild(moneyLabel, "Shadow", "TextLabel")
				if face then
					face.TextColor3 = Kit.Colors.accentGold
				end
			end
			local coin = makeIcon(moneyCard, "CurrencyIcon", spPlace, SP_TROPHY_ICON, Kit.Icons.trophy)
			coin.LayoutOrder = -1
			coin.Parent = moneyCard
			if moneyLabel then
				local widthScale = if speedCard then speedCard.Size.X.Scale else moneyCard.Size.X.Scale
				fitMoneyCard(moneyCard, moneyLabel, coin, widthScale)
			end
			table.insert(done, "Money")
		end

		if speedCard then
			padCard(speedCard)
			local shoe = findChild(speedCard, "ImageLabel", "ImageLabel")
			if shoe then
				addSpeedstersShoe(shoe, spPlace)
			end
			local currentBoost = findChild(speedCard, "CurrentBoost", "TextLabel")
			if currentBoost then
				-- The depth layer only; its Shadow face's TextColor3 is script-owned (TreadmillUI:76).
				currentBoost.TextColor3 = SPEED_CYAN
				fitSpeedCard(speedCard, shoe, currentBoost)
			end
			table.insert(done, "SpeedValue")
		end
	end

	-- 5. Index window title
	local indexGui = starterGui:FindFirstChild("Index")
	local indexFrame = indexGui and indexGui:FindFirstChild("Index")
	local titleFrame = indexFrame and indexFrame:FindFirstChild("Title")
	if titleFrame then
		for _, child in ipairs(titleFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				child.Text = "Hero Index"
			end
		end
		table.insert(done, "Index title")
	end

	print(string.format("[UI Transform] Structural base for the Speedsters UI port: %s. No panel painting, px strokes or global font pass (Phase 3 D1: scripts/steps/ui_*.luau skin the UI with scripts/lib/speedsters_ui_kit.luau).",
		table.concat(done, ", ")))
	return { applied = done }
end

return applySpeedtersUi
