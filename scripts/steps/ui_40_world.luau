-- scripts/steps/ui_40_world.luau
-- Build step "ui_40_world" (Phase 3, owner UI-WORLD). Runs in the ui_* pass (step 14b) after the base UI
-- pass and the window/HUD steps. It re-skins the in-world and billboard GUIs with the real Speedsters Escape
-- materials (CONTRACTS_PHASE3 D1) through the shared kit (scripts/lib/speedsters_ui_kit.luau):
--
--   1. Plot + treadmill upgrade signs on every plot: Speedsters card panel on the sign face, GothamSSm titles,
--      family-coloured Upgrade button (the controller's red/green state channel kept), Robux price pill,
--      Speedsters "!" badge on CanUpgrade.
--   2. ReplicatedStorage.Assets.UI.PlotUpgrade FirstUpgrade / FirstUpgradeInfo templates (unlock button with
--      the Speedsters window-progress fill).
--   3. ReplicatedStorage.Assets.Extra.Data (hero data billboard): GothamSSm name, FredokaOne stats, price
--      gradient on the income row, ink ScaledSize outlines.
--   4. Money popups: Assets.Extra.Cash, Assets.MoneyChange, Assets.Billboards.OfflineCash.
--   5. Egg labels: StarterGui.AssetEggData (PlacedEggBillboard), StarterGui.AssetHoverData,
--      Assets.Billboards.NightEggTimeSkip.
--   6. Treadmill video screen: Speedsters button material on the share, swap and side buttons only.
--   7. StarterGui.ResetStartTimer and StarterGui.LikeBoardGui.
--   8. Custom proximity-prompt templates (StarterPlayerScripts.Game.ProximityPromptScript.*): fonts and ink
--      outlines only. ReplicatedStorage.Assets.Prompts holds plain ProximityPrompts (no GUI), so nothing there.
--   9. Plot Multiplier billboard label.
-- The PlayerPlotSign is styled by scripts/steps/plots.luau (same owner).
--
-- D2 rules followed everywhere: nothing protected is renamed, reclassed, destroyed or hidden with Visible;
-- no UIScale is added; script-owned properties are left to their scripts, e.g.
--   * Upgrade/FirstUpgrade BackgroundColor3 + UIGradient.Enabled are the controllers' affordability channel:
--     only the gradient's colours change and the authored colour the controllers cache is set;
--   * AssetEggData.DisplayName / NightEggTimeSkip.DisplayName: GradientSwap replaces every UIGradient, so none
--     is added there; Data.Rarity/Odds lose their UIGradients in ItemDisplay, so no gradient is added there;
--   * Assets.Extra.Cash: ActiveAssetIncomePopup writes Text on EVERY TextLabel descendant and fades every
--     UIStroke/ImageLabel descendant, so no descendant is added (the existing stroke/gradient are restyled);
--   * treadmill-screen buttons keep Image / ImageColor3 (LikeController, ImageColorPulse own them): the
--     Speedsters material goes on the button background + strokes, never on a child layer over the icon.
--
-- Lune persistence: FontFace / ImageContent / the four per-corner radii only (the kit enforces this).

local roblox = require("@lune/roblox")
local Kit = require("../lib/speedsters_ui_kit")

local Enum = roblox.Enum
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2

local World = {}

-- Outline thickness (ScaledSize, Contextual) for text floating in the 3D world. The authored window values
-- (titles 0.05, rows 0.06) read too thin over busy scenery; 0.07-0.08 stays inside the Speedsters range
-- (0.05-0.11, materials.md §2).
local WORLD_TITLE_STROKE = 0.07
local WORLD_LABEL_STROKE = 0.08

-- Sign-face card (SurfaceGui panels): Speedsters window material with a corner/stroke sized for a small face.
local SIGN_PANEL_SIZE = UDim2.fromScale(0.96, 0.94)
local SIGN_PANEL_CORNER = 0.08
local SIGN_PANEL_STROKE = 0.02

local function log(fmt, ...)
	print(string.format("[ui_40_world] " .. fmt, ...))
end

-- Child lookup by a list of names; every segment must match (optionally the leaf class via IsA).
local function path(root, names, className)
	local node = root
	for _, name in ipairs(names) do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(name)
	end
	if node ~= nil and className ~= nil and not node:IsA(className) then
		return nil
	end
	return node
end

-- Per-run bookkeeping: counts per section and the pieces that were missing in the base place.
local function newStats()
	local stats = { counts = {}, missing = {} }
	function stats.add(key, n)
		stats.counts[key] = (stats.counts[key] or 0) + (n or 1)
	end
	function stats.miss(what)
		table.insert(stats.missing, what)
	end
	return stats
end

local function hideCanvasDecor(button)
	-- SAH button bevel/inlet textures live in a CanvasGroup child (not a direct DECOR_NAMES child).
	local canvas = button:FindFirstChild("CanvasGroup")
	if canvas then
		for _, name in ipairs({ "InletTexture", "BevelEffect" }) do
			local decor = canvas:FindFirstChild(name)
			if decor then
				Kit.hideDecoration(decor)
			end
		end
	end
end

-- Lowest ZIndex among the GuiObject children of `parent` that the kit did not create (default 1).
local function minChildZ(parent)
	local minZ = nil
	for _, c in ipairs(parent:GetChildren()) do
		if c:IsA("GuiObject") and not Kit.isKitName(c.Name) then
			minZ = if minZ then math.min(minZ, c.ZIndex) else c.ZIndex
		end
	end
	return minZ or 1
end

-- Speedsters window material as a card on a SurfaceGui face: one ImageLabel SpBackground with the white
-- @0.15 fill AND the blocky art @0.15 (the Frame + Background pair of window.frame folded into one layer),
-- a scale corner and an ink hairline. Drawn below every other child of the SurfaceGui.
local function addSurfaceCard(surface, opts)
	opts = opts or {}
	local card = Kit.ensureChild(surface, "ImageLabel", Kit.Names.background)
	Kit.setImage(card, opts.art or Kit.Images.windowArt)
	card.ImageColor3 = Kit.Colors.white
	card.ImageTransparency = Kit.Sizes.window.artTransparency
	card.BackgroundColor3 = Kit.Colors.windowFill
	card.BackgroundTransparency = Kit.Sizes.window.fillTransparency
	card.BorderSizePixel = 0
	card.ScaleType = Enum.ScaleType.Crop -- wide faces: crop the art instead of stretching it
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = opts.size or SIGN_PANEL_SIZE
	card.Active = false
	card.ZIndex = minChildZ(surface) - 1
	Kit.setCorner(card, opts.corner or SIGN_PANEL_CORNER)
	Kit.addStroke(card, {
		name = Kit.Names.stroke, color = Kit.Colors.ink, mode = "Border",
		thickness = opts.strokeThickness or SIGN_PANEL_STROKE,
	})
	-- LightInfluence 0 + Brightness 2 over-exposes a white card; 1 renders the authored colours.
	surface.Brightness = 1
	return card
end

-- A button whose BackgroundColor3 + UIGradient.Enabled are a script's state channel (PlotUpgradeController,
-- TreadmillUpgrade: red when the player cannot afford the upgrade). The controller caches the authored
-- BackgroundColor3 and its first UIGradient, so:
--   * the authored colour becomes `authoredColor` (white by default: the gradient then reads true);
--   * that gradient keeps its instance/name/Enabled and gets the family fill colours (rotation 90);
--   * no base image or child layer is added (it would cover the scripted red state); the Speedsters look is
--     the gradient + family corner + SpStrokeLight/SpStrokeDark (kit "solid" mode, colours script-owned).
local function skinStateButton(button, famKey, opts)
	opts = opts or {}
	local fam = Kit.ButtonFamilies[famKey]
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = Kit.seq(opts.gradientStops or fam.fill)
		gradient.Rotation = fam.fillRotation
		gradient.Offset = Vector2.new(0, 0)
		gradient.Transparency = Kit.numberSeq(0)
	end
	button.BackgroundColor3 = opts.authoredColor or Kit.Colors.white
	button.BackgroundTransparency = 0
	Kit.skinButton(button, fam, {
		mode = "solid",
		scriptOwned = { BackgroundColor3 = true, BackgroundTransparency = true, UIGradient = true },
	})
	hideCanvasDecor(button)
	return gradient
end

-- Speedsters "!" badge (hud.badge) for the CanUpgrade BillboardGui: a round white Frame SpBadge tinted by the
-- badge gradient behind the existing "!" TextLabel (which becomes FredokaOne white with the #861416 outline).
-- The BillboardGui only has Enabled written by the controllers.
local function skinCanUpgradeBadge(billboard)
	local label = billboard:FindFirstChildWhichIsA("TextLabel")
	local badge = Kit.ensureChild(billboard, "Frame", "SpBadge")
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.5, 0.5)
	badge.Size = UDim2.fromScale(0.62, 0.62)
	badge.BackgroundColor3 = Kit.Colors.white
	badge.BackgroundTransparency = 0
	badge.BorderSizePixel = 0
	badge.ZIndex = (label and label.ZIndex or 1) - 1
	Kit.setCorner(badge, 0.9)
	Kit.addGradient(badge, Kit.Gradients.badge, 90, Kit.Names.fill)
	Kit.addStroke(badge, { name = Kit.Names.strokeDark, color = Kit.Colors.badgeStroke, thickness = 0.08, mode = "Border" })
	local aspect = Kit.ensureChild(badge, "UIAspectRatioConstraint", "UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	if label then
		-- Speedsters badge label: 1.1522 x 0.8461 of the badge, centred.
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(0.62 * 1.1522, 0.62 * 0.8461)
		label.BackgroundTransparency = 1
		Kit.styleText(label, "badge", { scaled = true })
	end
	return badge
end

---------------------------------------------------------------------------------------------------
-- 1. Plot + treadmill upgrade signs (Workspace.Plots.<n>.{PlotUpgrade,TreadmillUpgrade}.Sign)
---------------------------------------------------------------------------------------------------

-- Contract (PlotUpgradeController:79-105, GUI/TreadmillUpgrade:48-89): Sign BasePart; Sign.CanUpgrade
-- BillboardGui; Sign.SurfaceGui SurfaceGui with Info (PlotUpgrade only) / Level TextLabels and Frame GuiObject
-- holding the Upgrade + RobuxUpgrade GuiButtons, each with a Cost TextLabel.
local function skinUpgradeSign(sign, famKey, stats, label)
	local surface = Kit.findChild(sign, "SurfaceGui", "SurfaceGui")
	if surface == nil then
		stats.miss(label .. ".SurfaceGui")
		return
	end
	addSurfaceCard(surface)

	local info = Kit.findChild(surface, "Info", "TextLabel")
	if info then
		Kit.styleText(info, "title", { strokeThickness = WORLD_TITLE_STROKE })
	end
	local level = Kit.findChild(surface, "Level", "TextLabel")
	if level then
		Kit.styleText(level, "subtitle", { color = Kit.Colors.accentGreen, strokeThickness = WORLD_TITLE_STROKE })
	end

	local frame = surface:FindFirstChild("Frame")
	local upgrade = frame and Kit.findChild(frame, "Upgrade", "GuiButton")
	if upgrade then
		skinStateButton(upgrade, famKey)
		local cost = Kit.findChild(upgrade, "Cost", "TextLabel")
		if cost then
			Kit.styleText(cost, "buy", { strokeThickness = WORLD_LABEL_STROKE })
		end
		stats.add("upgrade buttons")
	else
		stats.miss(label .. ".SurfaceGui.Frame.Upgrade")
	end

	local robux = frame and Kit.findChild(frame, "RobuxUpgrade", "GuiButton")
	if robux then
		if robux:IsA("ImageButton") then
			Kit.skinButton(robux, "price_robux", { mode = "direct", adoptGradient = true })
		else
			Kit.skinButton(robux, "price_robux", { mode = "solid" })
		end
		hideCanvasDecor(robux)
		local cost = Kit.findChild(robux, "Cost", "TextLabel")
		if cost then
			-- The text is the Robux glyph (U+E002) + price: keep the authored font face so the glyph renders.
			Kit.styleText(cost, "price", {
				color = Kit.Colors.white, strokeColor = Kit.Colors.black, strokeThickness = WORLD_LABEL_STROKE,
				scriptOwned = { FontFace = true },
			})
		end
		stats.add("robux pills")
	end

	local canUpgrade = Kit.findChild(sign, "CanUpgrade", "BillboardGui")
	if canUpgrade then
		skinCanUpgradeBadge(canUpgrade)
		stats.add("upgrade badges")
	else
		stats.miss(label .. ".CanUpgrade")
	end
	stats.add("sign faces")
end

local function skinPlotSigns(place, stats)
	local plots = place.Workspace:FindFirstChild("Plots")
	if plots == nil then
		stats.miss("Workspace.Plots")
		return
	end
	for _, plot in ipairs(plots:GetChildren()) do
		for _, spec in ipairs({ { "PlotUpgrade", "buy_green" }, { "TreadmillUpgrade", "cyan_lock" } }) do
			local sign = path(plot, { spec[1], "Sign" }, "BasePart")
			if sign then
				skinUpgradeSign(sign, spec[2], stats, string.format("Plots.%s.%s.Sign", plot.Name, spec[1]))
			else
				stats.miss(string.format("Plots.%s.%s.Sign", plot.Name, spec[1]))
			end
		end
		-- 9. Multiplier billboard label (static; no script references it).
		local multiplier = path(plot, { "Multiplier", "Core", "Main" }, "BillboardGui")
		local text = multiplier and multiplier:FindFirstChildWhichIsA("TextLabel")
		if text then
			Kit.styleText(text, "number", { keepColor = true, strokeThickness = WORLD_LABEL_STROKE })
			stats.add("multiplier labels")
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 2. ReplicatedStorage.Assets.UI.PlotUpgrade templates (cloned by PlotUpgradeController:126-149)
---------------------------------------------------------------------------------------------------

local function skinPlotUpgradeTemplates(rs, stats)
	local folder = path(rs, { "Assets", "UI", "PlotUpgrade" })
	if folder == nil then
		stats.miss("Assets.UI.PlotUpgrade")
		return
	end

	-- FirstUpgrade (ImageButton): BackgroundColor3 red <-> authored and UIGradient.Enabled are the
	-- affordability channel; ProgressFill.Size is the money/cost ratio. The authored red becomes the
	-- Speedsters red, the gradient a white-based shade, the fill the Speedsters window-progress green.
	local first = Kit.findChild(folder, "FirstUpgrade", "ImageButton")
	if first then
		skinStateButton(first, "red", {
			authoredColor = Kit.ButtonFamilies.red.solid,
			gradientStops = Kit.ButtonFamilies.equip_grey.fill,
		})
		local fill = Kit.findChild(first, "ProgressFill", "Frame")
		if fill then
			Kit.skinBar(nil, fill, "window", { stroke = false })
			Kit.setCorner(fill, Kit.ButtonFamilies.red.corner)
		end
		local cost = Kit.findChild(first, "Cost", "TextLabel")
		if cost then
			Kit.styleText(cost, "buy", { strokeThickness = WORLD_LABEL_STROKE })
		end
		stats.add("plot upgrade templates")
	else
		stats.miss("Assets.UI.PlotUpgrade.FirstUpgrade")
	end

	-- FirstUpgradeInfo (Frame): "Unlock:" + the pulsing Icon (GetOrCreateUIScale owns its scale).
	local info = Kit.findChild(folder, "FirstUpgradeInfo", "Frame")
	if info then
		local text = Kit.findChild(info, "Info", "TextLabel")
		if text then
			Kit.styleText(text, "title", { strokeThickness = WORLD_TITLE_STROKE })
		end
		stats.add("plot upgrade templates")
	else
		stats.miss("Assets.UI.PlotUpgrade.FirstUpgradeInfo")
	end
end

---------------------------------------------------------------------------------------------------
-- 3. ReplicatedStorage.Assets.Extra.Data (ItemDisplay.CreateDataBillboard)
---------------------------------------------------------------------------------------------------

local function skinDataBillboard(rs, stats)
	local data = path(rs, { "Assets", "Extra", "Data" }, "BillboardGui")
	if data == nil then
		stats.miss("Assets.Extra.Data")
		return
	end
	-- Name: GothamSSm Bold white (RichText mutation colour spans are written by ItemDisplay).
	local name = Kit.findChild(data, "DisplayName", "TextLabel")
	if name then
		Kit.styleText(name, "title", { strokeThickness = WORLD_TITLE_STROKE })
	end
	-- Income: FredokaOne price row with the Speedsters price gradient (nothing replaces gradients here).
	local perSecond = Kit.findChild(data, "PerSecond", "TextLabel")
	if perSecond then
		Kit.styleText(perSecond, "price", {
			color = Kit.Colors.white, gradient = Kit.Gradients.price, strokeThickness = WORLD_LABEL_STROKE,
		})
	end
	-- Rarity/odds/mutation rows: FredokaOne + ink outline, white text. ItemDisplay destroys their UIGradients
	-- (Odds gets the rarity gradient) and destroys BaseMutation/Mutations on the clone: no gradient here.
	for _, rowName in ipairs({ "Rarity", "Odds", "BaseMutation" }) do
		local row = Kit.findChild(data, rowName, "TextLabel")
		if row then
			Kit.styleText(row, "row", { color = Kit.Colors.white, strokeThickness = WORLD_LABEL_STROKE })
		end
	end
	local padding = Kit.findChild(data, "Padding", "TextLabel")
	if padding then
		Kit.styleText(padding, "price", { keepColor = true, strokeThickness = WORLD_LABEL_STROKE })
	end
	stats.add("data billboards")
end

---------------------------------------------------------------------------------------------------
-- 4. Money popups
---------------------------------------------------------------------------------------------------

local function recolourGradient(gradient, stops, rotation)
	gradient.Color = Kit.seq(stops)
	gradient.Rotation = rotation
	gradient.Offset = Vector2.new(0, 0)
end

local function skinMoneyPopups(rs, stats)
	-- Assets.Extra.Cash (ActiveAssetIncomePopup): "+$123" over a hero. Restyle the existing Money label,
	-- its UIStroke and its UIGradient in place; add NO descendant (the popup rewrites every TextLabel's Text
	-- and fades every UIStroke / ImageLabel it finds).
	local cash = path(rs, { "Assets", "Extra", "Cash" }, "BillboardGui")
	local money = cash and Kit.findChild(cash, "Money", "TextLabel")
	if money then
		local stroke = Kit.findChild(money, "UIStroke", "UIStroke")
		assert(stroke == nil or stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual,
			"Assets.Extra.Cash.Money.UIStroke expected Contextual (reused as the outline)")
		Kit.styleText(money, "number", {
			color = Kit.Colors.white, strokeThickness = WORLD_TITLE_STROKE, stroke = stroke ~= nil,
		})
		local gradient = Kit.findChild(money, "UIGradient", "UIGradient")
		if gradient then
			recolourGradient(gradient, Kit.Gradients.price, 90)
			gradient.Enabled = true
		end
		stats.add("money popups")
	else
		stats.miss("Assets.Extra.Cash.Money")
	end

	-- Assets.MoneyChange (MoneyUpdate): the HUD +/- popup. Label Text/TextTransparency, Label.UIStroke
	-- Transparency, More/Less Enabled, Icon and UIScale are the script's; font, outline and the More/Less
	-- colours are ours.
	local change = path(rs, { "Assets", "MoneyChange" })
	local label = change and Kit.findChild(change, "Label", "TextLabel")
	if label then
		-- Same text recipe as UI-HUD's ui_30_hud (number kind, default 0.05 outline): the popup lives in the HUD.
		Kit.styleText(label, "number", { keepColor = true })
		local more = Kit.findChild(label, "More", "UIGradient")
		if more then
			recolourGradient(more, Kit.Gradients.price, 90)
		end
		local less = Kit.findChild(label, "Less", "UIGradient")
		if less then
			recolourGradient(less, Kit.Gradients.badge, 90)
		end
		stats.add("money popups")
	else
		stats.miss("Assets.MoneyChange.Label")
	end

	-- Assets.Billboards.OfflineCash (OfflineMoneyBucketPiles.ClaimVisual): the claim text colour is cached
	-- and tweened by the script, so only font + outline.
	local offline = path(rs, { "Assets", "Billboards", "OfflineCash" }, "BillboardGui")
	local offlineMoney = offline and Kit.findChild(offline, "Money", "TextLabel")
	if offlineMoney then
		Kit.styleText(offlineMoney, "number", { keepColor = true, strokeThickness = WORLD_TITLE_STROKE })
		stats.add("money popups")
	end
end

---------------------------------------------------------------------------------------------------
-- 5. Egg labels
---------------------------------------------------------------------------------------------------

local function skinEggLabels(place, rs, stats)
	local sg = place:GetService("StarterGui")

	-- StarterGui.AssetEggData (PlacedEggBillboard): Frame Visible/Position and CanvasGroup GroupTransparency
	-- are per-frame script state; DisplayName gets the rarity gradient through GradientSwap (which destroys
	-- every UIGradient on it), so only font + outline.
	local canvas = path(sg, { "AssetEggData", "Frame", "CanvasGroup" })
	if canvas then
		local name = Kit.findChild(canvas, "DisplayName", "TextLabel")
		if name then
			Kit.styleText(name, "title", { keepColor = true, strokeThickness = WORLD_TITLE_STROKE })
		end
		local timer = Kit.findChild(canvas, "RemainingHatchTime", "TextLabel")
		if timer then
			Kit.styleText(timer, "number", { keepColor = true, strokeThickness = WORLD_TITLE_STROKE })
		end
		stats.add("egg labels")
	else
		stats.miss("StarterGui.AssetEggData.Frame.CanvasGroup")
	end

	-- StarterGui.AssetHoverData (AssetHoverDataDisplay): Weight text, Gender image, Steal pill (its image
	-- colour and scale are scripted).
	local hover = path(sg, { "AssetHoverData", "Frame", "CanvasGroup" })
	if hover then
		local weight = Kit.findChild(hover, "Weight", "TextLabel")
		if weight then
			Kit.styleText(weight, "number", { keepColor = true, strokeThickness = WORLD_TITLE_STROKE })
		end
		local stealText = path(hover, { "Steal", "Text" }, "TextLabel")
		if stealText then
			Kit.styleText(stealText, "button", { color = Kit.Colors.warningRed, strokeThickness = WORLD_LABEL_STROKE })
		end
		stats.add("egg labels")
	else
		stats.miss("StarterGui.AssetHoverData.Frame.CanvasGroup")
	end

	-- Assets.Billboards.NightEggTimeSkip (NightEggTimeSkipAnimation): DisplayName goes through GradientSwap;
	-- the timer colours are the script's. Font + outline only.
	local night = path(rs, { "Assets", "Billboards", "NightEggTimeSkip" }, "BillboardGui")
	if night then
		for _, d in ipairs(night:GetDescendants()) do
			if d:IsA("TextLabel") then
				local kind = if d.Name == "DisplayName" then "title" elseif d.Name == "Multiplier" then "price" else "number"
				Kit.styleText(d, kind, { keepColor = true, strokeThickness = WORLD_TITLE_STROKE })
			end
		end
		stats.add("egg labels")
	end
end

---------------------------------------------------------------------------------------------------
-- 6. Treadmill video screen buttons (TreadmillVideoController / LikeController)
---------------------------------------------------------------------------------------------------

-- Speedsters sidebar button material without a covering layer: an opaque ink tile on the button's own
-- background, the sidebar corner and the per-button sidebar strokes (colour gradient ring + dark rim), which
-- carry the button's Speedsters colour. The icon stays the button's Image, drawn over the tile (Image /
-- ImageColor3 are scripted on LikeButton and pulsed on ButtonSwapRight; a child layer would render above the
-- icon). The tile is ink, not the bright sidebar colour, because every icon here is a light glyph tinted by
-- script: white (all), liked heart #ff5c7a (LikeController:429) and pulse red #ff0000 (ImageColorPulse via
-- TreadmillVideoController:1088) read at 16.9 / 5.7 / 4.2 : 1 on ink, but at 1.3-4 : 1 on the sidebar colours.
local function skinScreenButton(button, sidebarKey)
	local spec = Kit.Sidebar[sidebarKey]
	button.BackgroundColor3 = Kit.Colors.ink
	button.BackgroundTransparency = 0
	button.BorderSizePixel = 0
	if button:IsA("ImageButton") then
		button.ImageTransparency = 0 -- icons were drawn at 0.18-0.2 over the video; crisp on a tile
	end
	Kit.setCorner(button, Kit.Sizes.sidebarButton.corner)
	Kit.addStroke(button, {
		name = Kit.Names.strokeLight, color = Kit.Colors.white, thickness = spec.light.thickness,
		borderOffset = spec.light.offset, zIndex = spec.light.zIndex, gradient = spec.light.gradient,
		gradientRotation = spec.light.rotation,
	})
	Kit.addStroke(button, {
		name = Kit.Names.strokeDark, color = spec.dark.color, thickness = spec.dark.thickness,
		borderOffset = spec.dark.offset, zIndex = spec.dark.zIndex,
	})
	Kit.hideLegacyStrokes(button)
end

local function skinTreadmillScreens(place, stats)
	local sg = place:GetService("StarterGui")
	local buttons = {
		{ { "TreadmillScreenButtonShare", "Frame", "ShareButton" }, "Evolve" },
		{ { "TreadmillScreenButtonSwapLeft", "ButtonSwapLeft" }, "Ability" },
		{ { "TreadmillScreenButtonSwapRight", "ButtonSwapRight" }, "Ability" },
		{ { "TreadmillScreenSideButtons", "Frame", "Buttons", "LikeButton" }, "Shop" },
		{ { "TreadmillScreenSideButtons", "Frame", "Buttons", "CommentsButton" }, "Index" },
	}
	for _, entry in ipairs(buttons) do
		local button = path(sg, entry[1], "GuiButton")
		if button then
			skinScreenButton(button, entry[2])
			stats.add("screen buttons")
		else
			stats.miss("StarterGui." .. table.concat(entry[1], "."))
		end
	end
	-- Like / comment counts under the side buttons: sidebar label style (Text is scripted).
	for _, names in ipairs({
		{ "TreadmillScreenSideButtons", "Frame", "Buttons", "LikeButton", "LikeCount" },
		{ "TreadmillScreenSideButtons", "Frame", "Buttons", "CommentsButton", "CommentsCount" },
	}) do
		local count = path(sg, names, "TextLabel")
		if count then
			Kit.styleText(count, "sidebar", { keepColor = true })
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 7. ResetStartTimer + LikeBoardGui (StarterGui SurfaceGuis)
---------------------------------------------------------------------------------------------------

local function skinResetStartTimer(place, stats)
	local frame = path(place:GetService("StarterGui"), { "ResetStartTimer", "Frame" })
	if frame == nil then
		stats.miss("StarterGui.ResetStartTimer.Frame")
		return
	end
	-- Countdown "3, 2, 1": Text/Visible scripted, GUI.getOrCreateUIScale owns its scale.
	local countdown = Kit.findChild(frame, "TextLabel", "TextLabel")
	if countdown then
		Kit.styleText(countdown, "title", { strokeThickness = WORLD_TITLE_STROKE })
	end
	-- Night timer: TextColor3 / TextTransparency and its UIStroke Color / Transparency are tweened by the
	-- script. Font only; the stroke keeps its authored px thickness and colour channel.
	local night = Kit.findChild(frame, "NightTimer", "TextLabel")
	if night then
		Kit.setFont(night, "title")
		local stroke = night:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.LineJoinMode = Enum.LineJoinMode.Round
		end
	end
	stats.add("reset timer")
end

local function skinLikeBoard(place, stats)
	local gui = place:GetService("StarterGui"):FindFirstChild("LikeBoardGui")
	if gui == nil then
		return
	end
	-- Board background: a Speedsters window card inset on the face (a full-face layer must not get corners:
	-- full-screen objects stay square), below the transparent Background frame; the teal gradient bars are
	-- legacy decoration (hidden by transparency).
	addSurfaceCard(gui, { corner = 0.05, strokeThickness = 0.012 })
	local background = Kit.findChild(gui, "Background", "Frame")
	if background then
		for _, barName in ipairs({ "TopBar", "BottomBar" }) do
			local bar = Kit.findChild(background, barName, "GuiObject")
			if bar then
				Kit.hideDecoration(bar)
			end
		end
	end
	local main = Kit.findChild(gui, "MainFrame", "Frame")
	if main then
		local title = Kit.findChild(main, "Title", "TextLabel")
		if title then
			Kit.skinTitle(title)
		end
		local description = Kit.findChild(main, "Description", "TextLabel")
		if description then
			Kit.styleText(description, "subtitle", { keepColor = true })
		end
		local code = Kit.findChild(main, "CurrentCode", "TextLabel")
		if code then
			Kit.styleText(code, "number", { color = Kit.Colors.accentGold })
		end
		local progress = Kit.findChild(main, "Progress", "Frame")
		if progress then
			local track = Kit.findChild(progress, "Bar", "Frame")
			local fill = track and Kit.findChild(track, "Bar", "Frame")
			if track then
				Kit.skinBar(track, fill, "level")
			end
			for _, labelName in ipairs({ "Progress", "Percent" }) do
				local text = Kit.findChild(progress, labelName, "TextLabel")
				if text then
					Kit.styleText(text, "number", { keepColor = true })
				end
			end
			local nextReward = Kit.findChild(progress, "NextReward", "TextLabel")
			if nextReward then
				Kit.styleText(nextReward, "row", { keepColor = true })
			end
		end
		for _, d in ipairs(main:GetDescendants()) do
			if d:IsA("TextLabel") and d.Name == "Title" and d ~= title then
				Kit.styleText(d, "row", { keepColor = true }) -- reward slot captions
			end
		end
	end
	stats.add("like board")
end

---------------------------------------------------------------------------------------------------
-- 8. Custom proximity-prompt templates (ProximityPromptScript clones them per prompt Theme)
---------------------------------------------------------------------------------------------------

-- The prompt labels are not TextScaled and the script measures them from FontFace + TextSize, so only the
-- font and the outline colour change; the outlines keep their px thickness (a ScaledSize stroke on a fixed
-- TextSize label is not the authored Speedsters case). Transparencies stay authored: the script caches
-- them per descendant and fades to them.
local function skinPromptTemplates(place, stats)
	local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local promptScript = sps and path(sps, { "Game", "ProximityPromptScript" })
	if promptScript == nil then
		stats.miss("StarterPlayerScripts.Game.ProximityPromptScript")
		return
	end
	local function inkOutline(label, minThickness)
		for _, c in ipairs(label:GetChildren()) do
			if c:IsA("UIStroke") then
				c.Color = Kit.Colors.ink
				c.LineJoinMode = Enum.LineJoinMode.Round
				if c.StrokeSizingMode == Enum.StrokeSizingMode.FixedSize then
					c.Thickness = math.max(c.Thickness, minThickness)
				end
			end
		end
	end
	for _, template in ipairs(promptScript:GetChildren()) do
		local frame = template:IsA("BillboardGui") and Kit.findChild(template, "PromptFrame")
		if frame then
			local action = Kit.findChild(frame, "ActionText", "TextLabel")
			if action then
				Kit.setFont(action, "title")
				inkOutline(action, 1.5)
			end
			local object = Kit.findChild(frame, "ObjectText", "TextLabel")
			if object then
				Kit.setFont(object, "body")
				inkOutline(object, 1)
			end
			local keyText = path(frame, { "InputFrame", "Frame", "ButtonText" }, "TextLabel")
			if keyText then
				Kit.setFont(keyText, "title")
			end
			stats.add("prompt templates")
		end
	end
end

---------------------------------------------------------------------------------------------------

function World.Apply(place, spPlace, ctx)
	local rs = place:GetService("ReplicatedStorage")
	local stats = newStats()
	local failures = {}
	-- Independent sections: one failing must not skip the others; failures are re-raised at the end so a
	-- lenient build still reports this step as failed.
	for _, section in ipairs({
		{ "plot signs", function() skinPlotSigns(place, stats) end },
		{ "plot upgrade templates", function() skinPlotUpgradeTemplates(rs, stats) end },
		{ "data billboard", function() skinDataBillboard(rs, stats) end },
		{ "money popups", function() skinMoneyPopups(rs, stats) end },
		{ "egg labels", function() skinEggLabels(place, rs, stats) end },
		{ "treadmill screens", function() skinTreadmillScreens(place, stats) end },
		{ "reset timer", function() skinResetStartTimer(place, stats) end },
		{ "like board", function() skinLikeBoard(place, stats) end },
		{ "prompt templates", function() skinPromptTemplates(place, stats) end },
	}) do
		local ok, err = pcall(section[2])
		if not ok then
			table.insert(failures, section[1] .. ": " .. tostring(err))
			log("!! section '%s' failed: %s", section[1], tostring(err))
		end
	end

	local keys = {}
	for key in pairs(stats.counts) do
		table.insert(keys, key)
	end
	table.sort(keys)
	local parts = {}
	for _, key in ipairs(keys) do
		table.insert(parts, string.format("%s %d", key, stats.counts[key]))
	end
	log("Speedsters world GUIs: %s.", #parts > 0 and table.concat(parts, ", ") or "nothing styled")
	if #stats.missing > 0 then
		log("Not found in the base place (left as is): %s", table.concat(stats.missing, "; "))
	end
	if #failures > 0 then
		error("ui_40_world failed: " .. table.concat(failures, " | "))
	end
end

return World
