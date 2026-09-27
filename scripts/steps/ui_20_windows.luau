--!nocheck
-- scripts/steps/ui_20_windows.luau (owner UI-WINDOWS, Speedsters UI port phase 3)
-- Re-skins every window / popup ScreenGui of Steal a Hero with the real Speedsters Escape window material
-- (CONTRACTS_PHASE3 D1) using the shared kit (scripts/lib/speedsters_ui_kit.luau):
--   * window: white @0.15 fill + Speedsters Background art (106477372921851, Shop art 91870898439604, Gift art) + scale
--     UICorner 0.05 + ink hairline (0.007 ScaledSize #0b1b3d) on the painter; legacy InletTexture / BevelEffect /
--     DropShadow / Pattern / shadow / Glow hidden by transparency;
--   * title: GothamSSm Bold, white, Contextual ScaledSize ink outline, floated on the top edge where the window allows;
--   * header icon by meaning (shop, index, rebirth, settings, codes, gifts, trade, eggs...) tagged SpHeaderIcon=true
--     for the runtime bounce (Library.Client.SpeedstersWindowJuice);
--   * close: Speedsters X art on Close.TextButton (ConsoleCmds contract), Speedsters corner placement;
--   * content: action buttons -> Speedsters button families, cards -> shop pass cards, rows -> row.list_item, bars ->
--     Speedsters bar, text inputs -> codes TextBox, sub-panels -> stat boxes, every text -> FredokaOne / GothamSSm
--     with Contextual ScaledSize ink outlines;
--   * 'SpDim' (Speedsters Dim, #000 fading 1 -> 0.55 at runtime) INSIDE every TabController window root: a Frame
--     directly under a tab ScreenGui would become the root TabController / AutoGridLayout find with
--     FindFirstChildOfClass("Frame") (sah_structure C1).
-- Guard rails (D2): nothing protected is renamed, reclassed, destroyed or set Visible=false; no UIScale is added;
-- script-owned properties (per sah_structure.json runtimeProps) are left to the scripts (tint layers instead);
-- ConsoleCmds contracts hold (every Close keeps its TextButton ImageLabel / TextLabel). Idempotent: every layer this
-- step adds has an Sp* name and is reused on a second run.
-- Apply(place, spPlace, ctx) prints one summary line per window (what changed) and never throws for a missing node.
--
-- Visual pass 2 (VISUAL_PASS_PLAN D7, owner WINDOWS; refs design/references/06 + 07) adds the "studded glossy"
-- material (glossy gradient header band + stud texture + light streaks, dark studded body, round embossed close,
-- chunky glossy buttons) and two re-laid-out windows:
--   * AutoSell -> "Sell Heroes": the base game's sell tab (a registered TabController tab that BackpackController
--     never opens: its button is hidden) becomes the window of the hub sell stall. Side tabs HEROES / EGGS, Sort By
--     Size / Value, Select All, a card grid, a Total Value row with a cash icon and a glossy Sell button. The old
--     auto-sell rarity grid stays in place (BackpackController still fills it) but is hidden with Visible = false
--     (the one exception to the D2 rule above: no script toggles the Visible of those three). The window is driven
--     by StarterPlayerScripts.GUI.SellHeroes (scripts/inject/windows.luau) and opened by the stall's Sell All prompt.
--     The root carries SellHeroesWindow = true (the runtime contract) and the SpOnColor / SpOffColor / SpTabOffColor
--     palette attributes.
--   * GroupReward -> "Free Gift!": electric-cyan header band, speed bag, "~ LIMITED TIME! ~", "1,000 SPEED!", three
--     numbered step cards and a giant glossy green Claim! (ClaimReward.BackgroundColor3 stays GroupRewards' state).
--     Its hub chest prompt is re-enabled: the claim no longer needs the group (community step is informational).
--   * FreeGifts (playtime gifts) gets the same cyan header + studded body.
-- Gekko UI revamp: the studded glossy recipes now live in scripts/lib/ui_kit.luau (UiKit; this step's wrappers only add
-- notes), and scripts/steps/ui_50_revamp.luau gives every other window the same look with its own theme.

local roblox = require("@lune/roblox")
local Kit = require("../lib/speedsters_ui_kit")
local UiKit = require("../lib/ui_kit")

local Color3 = roblox.Color3
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum

local Step = {}

local INK = Kit.Colors.ink
local WHITE = Kit.Colors.white
local BLACK = Kit.Colors.black
local DIM_NAME = "SpDim"
local HEADER_ATTRIBUTE = "SpHeaderIcon"

-- legacy SAH decoration hidden by transparency (ImageLabels / Frames with these names)
local DECOR_IMAGES = {
	BevelEffect = true, InletTexture = true, DropShadow = true, Glow = true, Pattern = true, shadow = true,
	Shadow = true, ContainerShadow = true, SearchShadow = true, ["shadow-toolbar"] = true, Closure = true,
}
-- SAH ray art that Speedsters draws with its Shine rays (image swap only; scripts may rotate them)
local RAY_IMAGES = { Starburst = true, Sunburst = true, sunburst67 = true }

---------------------------------------------------------------------------------------------------
-- small utilities
---------------------------------------------------------------------------------------------------

local function child(parent, segment)
	if parent == nil then
		return nil
	end
	local name, className = string.match(segment, "^(.-)#(%u%a+)$")
	if name == nil or name == "" then
		name, className = segment, nil
	end
	for _, c in ipairs(parent:GetChildren()) do
		if c.Name == name and (className == nil or c.ClassName == className) then
			return c
		end
	end
	return nil
end

-- "A/B/C" under root ("Name#Class" picks between same-named siblings)
local function at(root, path)
	local node = root
	for _, segment in ipairs(string.split(path, "/")) do
		node = child(node, segment)
		if node == nil then
			return nil
		end
	end
	return node
end

local function newContext(name, gui)
	return {
		name = name, gui = gui, changes = {}, warnings = {}, counts = {}, styled = {}, skipText = {},
		global = gui ~= nil and Kit.prop(gui, "ZIndexBehavior") == Enum.ZIndexBehavior.Global,
	}
end

local function note(W, fmt, ...)
	table.insert(W.changes, string.format(fmt, ...))
end

local function bump(W, key, n)
	W.counts[key] = (W.counts[key] or 0) + (n or 1)
end

local function warnf(W, fmt, ...)
	table.insert(W.warnings, string.format(fmt, ...))
end

local function lum(c)
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

local function hsv(c)
	local r, g, b = c.R, c.G, c.B
	local maxv, minv = math.max(r, g, b), math.min(r, g, b)
	local d = maxv - minv
	local h = 0
	if d > 1e-6 then
		if maxv == r then
			h = ((g - b) / d) % 6
		elseif maxv == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h *= 60
	end
	return h, (maxv > 0 and d / maxv or 0), maxv
end

local function isEnabled(inst)
	return Kit.prop(inst, "Enabled") ~= false
end

local function enabledGradient(inst)
	for _, c in ipairs(inst:GetChildren()) do
		if c:IsA("UIGradient") and not Kit.isKitName(c.Name) and isEnabled(c) then
			return c
		end
	end
	return nil
end

local function disableGradients(inst)
	local n = 0
	for _, c in ipairs(inst:GetChildren()) do
		if c:IsA("UIGradient") and not Kit.isKitName(c.Name) and isEnabled(c) then
			c.Enabled = false
			n += 1
		end
	end
	return n
end

local function gradientMid(g)
	local kps = g.Color.Keypoints
	local a, b = kps[1].Value, kps[#kps].Value
	return Color3.new((a.R + b.R) / 2, (a.G + b.G) / 2, (a.B + b.B) / 2)
end

local function isImage(inst)
	return inst:IsA("ImageLabel") or inst:IsA("ImageButton")
end

-- The colour a SAH button reads as: its gradient, else its background, else its image tint.
local function dominantColor(inst)
	local g = enabledGradient(inst)
	if g then
		return gradientMid(g)
	end
	if inst.BackgroundTransparency < 0.9 then
		return inst.BackgroundColor3
	end
	if isImage(inst) and inst.ImageTransparency < 0.9 then
		return inst.ImageColor3
	end
	return inst.BackgroundColor3
end

-- Speedsters button family by colour (verb decides green buy vs claim).
local function familyFor(color, verb)
	local h, s = hsv(color)
	if s < 0.18 then
		return "equip_grey"
	end
	if h >= 70 and h < 165 then
		return verb == "buy" and "buy_green" or "claim_green"
	end
	if h >= 165 and h < 255 then
		return "cyan"
	end
	if h >= 255 and h < 330 then
		return "magenta"
	end
	if h >= 20 and h < 70 then
		return "speed_buy_gold"
	end
	return "red"
end

-- ZIndex below every other GuiObject child of `parent` (Sibling ZIndexBehavior).
local function belowChildren(parent, except)
	local minZ = nil
	for _, c in ipairs(parent:GetChildren()) do
		if c ~= except and c:IsA("GuiObject") then
			minZ = if minZ then math.min(minZ, c.ZIndex) else c.ZIndex
		end
	end
	return if minZ then minZ - 1 else 0
end

-- Lowest ZIndex of the window's real content (Global ZIndexBehavior); decoration and Sp layers excluded.
local function minContentZ(root, extraExclude)
	local minZ = root.ZIndex
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") and not Kit.isKitName(d.Name) and not DECOR_IMAGES[d.Name]
			and not (extraExclude and extraExclude[d.Name]) then
			minZ = math.min(minZ, d.ZIndex)
		end
	end
	return minZ
end

local function hideTextFace(label)
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	for _, c in ipairs(label:GetChildren()) do
		if c:IsA("UIStroke") then
			c.Transparency = 1
		end
	end
end

-- SAH stacked text: a dark copy with a lighter same-size face as a child. Returns true + the face.
local function shadowCopyFace(label)
	if not label:IsA("TextLabel") or lum(label.TextColor3) > 0.25 then
		return false, nil
	end
	for _, c in ipairs(label:GetChildren()) do
		if c:IsA("TextLabel") and c.Size.X.Scale >= 0.9 and c.Size.Y.Scale >= 0.9 and lum(c.TextColor3) > 0.45 then
			return true, c
		end
	end
	return false, nil
end

local function contextualStrokes(label)
	local list = {}
	for _, c in ipairs(label:GetChildren()) do
		if c:IsA("UIStroke") and c.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual then
			table.insert(list, c)
		end
	end
	return list
end

---------------------------------------------------------------------------------------------------
-- text
---------------------------------------------------------------------------------------------------

-- One text object in the Speedsters recipe: font by role, Contextual ScaledSize ink outline (existing outline reused),
-- colour kept (many colours are rarity / state data), legacy TextStroke off. DropShadow copies and the dark copy of
-- stacked SAH text are hidden (their face keeps the text). Never touches a stroke DoubleYourSpeed resizes in px
-- (label attribute OriginalThickness).
local function styleOneText(W, label, kind, opts)
	opts = opts or {}
	if W.styled[label] or W.skipText[label] or Kit.isKitName(label.Name) then
		return
	end
	W.styled[label] = true
	if label.Name == "DropShadow" then
		hideTextFace(label)
		Kit.setFont(label, kind)
		bump(W, "text shadows hidden")
		return
	end
	local isCopy, face = shadowCopyFace(label)
	if isCopy then
		hideTextFace(label)
		Kit.setFont(label, kind)
		bump(W, "text shadows hidden")
		if face then
			styleOneText(W, face, kind, opts)
		end
		return
	end
	Kit.setFont(label, kind)
	bump(W, "texts restyled")
	if label:IsA("TextBox") then
		return
	end
	if label:IsA("TextButton") and label.Text == "" then
		return
	end
	if label:GetAttribute("OriginalThickness") ~= nil then
		return -- DoubleYourSpeed drives this label's UIStroke thickness in px
	end
	local strokes = contextualStrokes(label)
	if #strokes == 0 and (label.TextTransparency >= 0.95 or lum(label.TextColor3) < 0.35) then
		return -- invisible or dark text: an ink outline would only muddy it
	end
	local previous = strokes[1]
	local previousTransparency = previous and previous.Transparency or 0
	local _, stroke = Kit.styleText(label, kind, {
		keepColor = opts.color == nil, color = opts.color, strokeThickness = opts.strokeThickness,
		scaled = opts.scaled, disableGradients = opts.disableGradients,
	})
	if stroke and stroke == previous and previousTransparency > 0 and previousTransparency < 1 then
		stroke.Transparency = previousTransparency
	end
	-- a second legacy outline (e.g. a px stroke the kit would not reuse) would double the outline
	for _, s in ipairs(contextualStrokes(label)) do
		if s ~= stroke and not Kit.isKitName(s.Name) then
			s.Transparency = 1
		end
	end
end

local function inButton(label, root)
	local p = label.Parent
	while p ~= nil and p ~= root do
		if p:IsA("GuiButton") then
			return true
		end
		p = p.Parent
	end
	return root ~= nil and root:IsA("GuiButton") and label:IsDescendantOf(root)
end

-- Every text object under `root` not styled yet: button labels 'button', everything else 'body' (FredokaOne).
local function styleTexts(W, root)
	if root == nil then
		return
	end
	local nodes = { root }
	for _, d in ipairs(root:GetDescendants()) do
		table.insert(nodes, d)
	end
	for _, d in ipairs(nodes) do
		if Kit.isText(d) then
			local kind = (d:IsA("TextButton") or inButton(d, root)) and "button" or "body"
			styleOneText(W, d, kind)
		end
	end
end

-- Title recipe (window.title): GothamSSm Bold white + 0.05 ink outline; stacked copies resolved to one face.
-- opts.place: float on the top edge (AnchorPoint .5,.5 at opts.position or (0.5,0,0,0)); opts.size; opts.show makes
-- a hidden (non-scripted) title visible; opts.keepColor for titles whose colour a script writes.
local function styleTitle(W, node, opts)
	opts = opts or {}
	if node == nil then
		warnf(W, "title missing")
		return
	end
	local kind = opts.kind or "title"
	local faces = {}
	local function visit(label)
		if W.styled[label] then
			return
		end
		if label.Name == "DropShadow" then
			W.styled[label] = true
			hideTextFace(label)
			Kit.setFont(label, kind)
			return
		end
		local isCopy, face = shadowCopyFace(label)
		if isCopy then
			W.styled[label] = true
			hideTextFace(label)
			Kit.setFont(label, kind)
			visit(face)
			return
		end
		W.styled[label] = true
		table.insert(faces, label)
		Kit.styleText(label, kind, {
			color = (not opts.keepColor) and WHITE or nil, keepColor = opts.keepColor, scaled = true, strokeThickness = opts.strokeThickness,
			disableGradients = not opts.keepGradient,
		})
		for _, s in ipairs(contextualStrokes(label)) do
			if not Kit.isKitName(s.Name) and s.Thickness > 0.2 then
				s.Transparency = 1 -- px outline the kit could not reuse
			end
		end
		for _, c in ipairs(label:GetChildren()) do
			if c:IsA("TextLabel") then
				visit(c)
			end
		end
	end
	if Kit.isText(node) then
		visit(node)
	else
		for _, c in ipairs(node:GetChildren()) do
			if c:IsA("TextLabel") then
				visit(c)
			end
		end
	end
	if opts.place then
		node.AnchorPoint = Vector2.new(0.5, 0.5)
		node.Position = opts.position or UDim2.new(0.5, 0, 0, 0)
		node.Rotation = 0 -- a title on the top edge is straight (Settings kept its base -19 degree tilt and hit the list)
		if opts.size then
			node.Size = opts.size
		end
		for _, face in ipairs(faces) do
			face.TextXAlignment = Enum.TextXAlignment.Center
		end
	end
	if opts.show and node:IsA("GuiObject") and not node.Visible then
		node.Visible = true
	end
	if opts.zIndex then
		node.ZIndex = opts.zIndex
	end
	note(W, "title '%s' GothamSSm Bold + ink outline%s", Kit.isText(node) and node.Text or node.Name, opts.place and " (top edge)" or "")
end

---------------------------------------------------------------------------------------------------
-- windows
---------------------------------------------------------------------------------------------------

-- Hides SAH decoration under root by transparency, swaps ray art to the Speedsters Shine.
local function hideDecor(W, root)
	if root == nil then
		return
	end
	for _, d in ipairs(root:GetDescendants()) do
		if not Kit.isKitName(d.Name) and d:IsA("GuiObject") then
			if DECOR_IMAGES[d.Name] and (isImage(d) or d:IsA("Frame")) then
				Kit.hideDecoration(d)
				bump(W, "legacy decoration hidden")
			elseif RAY_IMAGES[d.Name] and d:IsA("ImageLabel") then
				Kit.setImage(d, Kit.Images.shine)
				bump(W, "rays -> Speedsters Shine")
			end
		end
	end
end

-- Window material on `painter` (D1). fillOnLayer: the painter is the root itself, so its own fill moves onto the
-- SpBackground layer (white @0.15 under the art) to leave room for SpDim below it.
local function paintWindow(W, root, painter, opts)
	opts = opts or {}
	if root == nil or painter == nil then
		warnf(W, "window root/painter missing")
		return nil
	end
	local res = Kit.skinWindow(root, painter, {
		art = opts.art, fillTransparency = opts.fillOnLayer and 1 or nil, hide = opts.hide,
		scriptOwned = opts.painterOwned,
	})
	if not opts.keepPainterGradient then
		disableGradients(painter)
	end
	if painter ~= root and not opts.keepRootFill then
		root.BackgroundTransparency = 1
		if isImage(root) then
			root.ImageTransparency = 1
		end
	end
	local bg = res.background
	if bg then
		if opts.fillOnLayer then
			bg.BackgroundColor3 = WHITE
			bg.BackgroundTransparency = Kit.Sizes.window.fillTransparency
		end
		if W.global then
			bg.ZIndex = minContentZ(root, opts.globalExclude) - 1
		end
	end
	if res.warning and not W.global then
		warnf(W, "%s", res.warning)
	end
	note(W, "window material on %s (art %s, white@0.15, corner 0.05, ink hairline 0.007)%s", painter:GetFullName(),
		tostring(opts.art or Kit.Images.windowArt), opts.fillOnLayer and ", fill on SpBackground" or "")
	return res
end

-- Speedsters Dim (window.dim) inside a TabController window root; TabController fades it 1 -> 0.55.
local function ensureDim(W, root)
	if root == nil then
		return nil
	end
	if Kit.prop(root, "ClipsDescendants") then
		warnf(W, "%s clips its descendants: no SpDim", root:GetFullName())
		return nil
	end
	local automatic = Kit.prop(root, "AutomaticSize")
	if automatic ~= nil and automatic ~= Enum.AutomaticSize.None then
		warnf(W, "%s is AutomaticSize: no SpDim", root:GetFullName())
		return nil
	end
	local dim = Kit.ensureChild(root, "Frame", DIM_NAME)
	dim.AnchorPoint = Vector2.new(0.5, 0.5)
	dim.Position = UDim2.fromScale(0.5, 0.5)
	-- 12x the root on each axis: the dim covers the screen during the whole slide from Y 1.28
	dim.Size = UDim2.fromScale(12, 12)
	dim.BackgroundColor3 = Kit.Colors.dim
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Active = false
	if W.global then
		-- below everything in the ScreenGui, hidden decoration included
		local lowest = root.ZIndex
		for _, d in ipairs(root:GetDescendants()) do
			if d ~= dim and d:IsA("GuiObject") then
				lowest = math.min(lowest, d.ZIndex)
			end
		end
		dim.ZIndex = lowest - 1
	else
		dim.ZIndex = belowChildren(root, dim)
	end
	dim:SetAttribute("SpDimTarget", Kit.Sizes.dim.transparency)
	note(W, "SpDim in %s (#000, 1 -> %.2f at runtime)", root:GetFullName(), Kit.Sizes.dim.transparency)
	return dim
end

local function topZ(parent, except)
	local z = 1
	for _, c in ipairs(parent:GetChildren()) do
		if c ~= except and c:IsA("GuiObject") then
			z = math.max(z, c.ZIndex + 1)
		end
	end
	return z
end

-- Header icon (window.header_icon): an existing SAH icon re-arted and re-placed, or a new SpHeaderIcon. Tagged for
-- the runtime bounce.
local function headerIcon(W, root, iconId, opts)
	opts = opts or {}
	if root == nil then
		return nil
	end
	local icon = opts.existing
	if icon then
		if iconId then
			Kit.setImage(icon, iconId)
		end
		icon.ImageTransparency = 0
		icon.BackgroundTransparency = 1
		icon.ImageColor3 = WHITE
		icon.ScaleType = Enum.ScaleType.Fit
		if opts.place ~= false then
			local s = Kit.Sizes.headerIcon
			icon.AnchorPoint = s.anchor
			icon.Size = opts.size or s.size
			icon.Position = opts.position or s.position
			local aspect = icon:FindFirstChildOfClass("UIAspectRatioConstraint") or Kit.ensureChild(icon, "UIAspectRatioConstraint", Kit.Names.aspect)
			aspect.AspectRatio = 1
		end
		Kit.hideLegacyStrokes(icon)
		for _, c in ipairs(icon:GetChildren()) do
			if c:IsA("ImageLabel") and DECOR_IMAGES[c.Name] then
				Kit.hideDecoration(c)
			end
		end
		if icon.Parent and not W.global then
			icon.ZIndex = math.max(icon.ZIndex, topZ(icon.Parent, icon))
		end
	else
		icon = Kit.addHeaderIcon(opts.parent or root, iconId, { size = opts.size, position = opts.position })
	end
	if opts.zIndex then
		icon.ZIndex = opts.zIndex
	end
	icon:SetAttribute(HEADER_ATTRIBUTE, true)
	note(W, "header icon %s = %s", icon:GetFullName(), tostring(iconId or "kept SAH art"))
	return icon
end

local function skinClose(W, close, opts)
	opts = opts or {}
	if close == nil or not close:IsA("GuiButton") then
		warnf(W, "close missing")
		return
	end
	Kit.skinCloseButton(close, { place = opts.place ~= false })
	W.styled[close] = true
	for _, d in ipairs(close:GetDescendants()) do
		if Kit.isText(d) then
			W.styled[d] = true -- the hidden 'X' copy (the art draws the X)
			Kit.setFont(d, "body")
		end
	end
	if opts.zIndex then
		close.ZIndex = opts.zIndex
	end
	note(W, "close %s: X art 110882579806743 on Close.TextButton%s", close:GetFullName(), opts.place ~= false and ", Speedsters corner placement" or "")
end

---------------------------------------------------------------------------------------------------
-- content recipes
---------------------------------------------------------------------------------------------------

-- SAH action button: a GuiButton click box + child ImageLabel 'TextButton' (the pill: gradient, bevel, inlet, px
-- stroke). The Speedsters family goes on the pill (direct: white base image + family gradient + two strokes), or on the
-- button itself when it draws its own pill. opts.owned = script-owned props of the drawing node (kit tint/layer modes).
-- opts.stateGradients = { [UIGradient name] = family }: the pill's named gradients a script switches between by Enabled
-- (e.g. ClaimRewardPanel: UIGradient = claimable, GreyGradient = not claimable). Each is recoloured with its own family
-- fill, its Enabled flag stays script state, and no gradient is adopted or added (a SpFill would fight the switch).
local function skinAction(W, button, family, opts)
	opts = opts or {}
	if button == nil or not button:IsA("GuiObject") then
		warnf(W, "button missing (%s)", tostring(family))
		return nil
	end
	local visual = button:FindFirstChild("TextButton")
	local target = button
	if visual and visual:IsA("ImageLabel") and button:IsA("GuiButton") and button.Name ~= "Close" then
		target = visual
		for _, c in ipairs(button:GetChildren()) do
			if c:IsA("ImageLabel") and c.Name == "Glow" then
				Kit.hideDecoration(c)
			end
		end
		Kit.hideLegacyStrokes(button, { borderOnly = Kit.isText(button) })
		if not (opts.buttonOwned and opts.buttonOwned.BackgroundTransparency) then
			button.BackgroundTransparency = 1
		end
	end
	family = family or familyFor(dominantColor(target), opts.verb)
	local owned = opts.owned or {}
	local mode = opts.mode
	if mode == nil and isImage(target) and not (owned.BackgroundColor3 or owned.ImageColor3 or owned.Image or owned.UIGradient) then
		mode = "direct" -- the pill itself: base image + recoloured gradient
	end
	if W.global and mode == nil and not isImage(target) then
		mode = "solid" -- no child layers in Global ZIndex windows (they would tie with the content's ZIndex)
	end
	local states = opts.stateGradients
	if states then
		assert(isImage(target), "skinAction: stateGradients needs an image pill")
		mode = "direct" -- the pill keeps drawing, so whichever state gradient the script enables shows
	end
	local _, usedMode = Kit.skinButton(target, family, {
		mode = mode, adoptGradient = not owned.UIGradient, scriptOwned = owned,
	})
	if states then
		-- Kit.skinButton just adopted the first enabled one with `family` (or added SpFill if none was enabled):
		-- give every state gradient its own fill and drop the kit gradient
		for name, stateFamily in pairs(states) do
			local g = target:FindFirstChild(name)
			if g and g:IsA("UIGradient") then
				local fam = Kit.ButtonFamilies[stateFamily]
				g.Color = Kit.seq(fam.fill)
				g.Rotation = fam.fillRotation
				g.Offset = Vector2.new(0, 0)
				note(W, "state gradient %s.%s -> %s fill (Enabled kept: %s)", button:GetFullName(), name, stateFamily, tostring(g.Enabled))
			else
				warnf(W, "state gradient %s missing on %s", name, button:GetFullName())
			end
		end
		local kitFill = target:FindFirstChild(Kit.Names.fill)
		if kitFill and kitFill:IsA("UIGradient") then
			kitFill:Destroy()
		end
	end
	bump(W, "buttons -> Speedsters families")
	note(W, "button %s -> %s (%s)", button:GetFullName(), family, usedMode)
	return usedMode
end

-- Speedsters shop pass card (card.shop_pass): corner 0.05, #030f2c + #bdbdbd@0.53 ScaledSize strokes, diagonal gradient
-- (-28 deg), pass pattern overlay. opts.gradientOwned / opts.pattern == false / opts.rotate == false.
local function skinCard(W, card, opts)
	opts = opts or {}
	if card == nil or not card:IsA("GuiObject") then
		return
	end
	Kit.setCorner(card, opts.corner or 0.05)
	Kit.hideLegacyStrokes(card, { borderOnly = Kit.isText(card) })
	Kit.addStroke(card, { name = Kit.Names.stroke, color = Kit.hex("#030f2c"), thickness = 0.016, borderOffset = -0.01, zIndex = 2 })
	Kit.addStroke(card, { name = Kit.Names.strokeLight, color = Kit.hex("#bdbdbd"), transparency = 0.53, thickness = 0.016, borderOffset = -0.025, zIndex = 1 })
	if opts.rotate ~= false and not opts.gradientOwned then
		local g = enabledGradient(card)
		if g then
			g.Rotation = -28
		end
	end
	if opts.pattern ~= false and not Kit.hasLayout(card) then
		local pattern = Kit.ensureChild(card, "ImageLabel", "SpPattern")
		Kit.setImage(pattern, Kit.Images.passPattern)
		pattern.ImageTransparency = 0.6
		pattern.BackgroundTransparency = 1
		pattern.ScaleType = Enum.ScaleType.Stretch
		pattern.AnchorPoint = Vector2.new(0.5, 0.5)
		pattern.Position = UDim2.fromScale(0.5, 0.5)
		pattern.Size = UDim2.fromScale(1, 1)
		pattern.BorderSizePixel = 0
		pattern.Active = false
		pattern.ZIndex = belowChildren(card, pattern)
		Kit.setCorner(pattern, opts.corner or 0.05)
	end
	bump(W, "cards -> Speedsters pass card")
end

-- afk.stat_box: #000 @0.45, scale corner, legacy strokes hidden (strokes carrying OriginalThickness kept).
local function skinStatBox(W, frame, opts)
	opts = opts or {}
	if frame == nil or not frame:IsA("GuiObject") then
		return
	end
	local owned = opts.owned or {}
	if not owned.BackgroundColor3 then
		frame.BackgroundColor3 = opts.color or BLACK
	end
	if not owned.BackgroundTransparency then
		frame.BackgroundTransparency = opts.transparency or 0.45
	end
	Kit.setCorner(frame, opts.corner or 0.1)
	if not opts.keepStrokes then
		for _, c in ipairs(frame:GetChildren()) do
			if c:IsA("UIStroke") and not Kit.isKitName(c.Name) and c:GetAttribute("OriginalThickness") == nil then
				c.Transparency = 1
			end
		end
	end
	if opts.stroke then
		Kit.addStroke(frame, { name = Kit.Names.stroke, color = opts.strokeColor or BLACK, thickness = opts.stroke, borderOffset = opts.strokeOffset or 0 })
	end
	if opts.disableGradients then
		disableGradients(frame)
	end
	bump(W, "sub-panels -> stat box")
end

-- row.list_item: the row frame goes transparent with corner 0.25; an SpRowArt layer draws the row art 90451917704726
-- over the row colour with a black + light stroke.
local function skinRow(W, frame, colour, opts)
	opts = opts or {}
	if frame == nil or not frame:IsA("GuiObject") then
		return
	end
	local owned = opts.owned or {}
	Kit.setCorner(frame, 0.25)
	Kit.hideLegacyStrokes(frame)
	if not owned.UIGradient then
		disableGradients(frame)
	end
	if Kit.hasLayout(frame) then
		if not owned.BackgroundColor3 then
			frame.BackgroundColor3 = colour
		end
		frame.BackgroundTransparency = 0
		return
	end
	if not owned.BackgroundTransparency then
		frame.BackgroundTransparency = 1
	end
	local art = Kit.ensureChild(frame, "ImageLabel", "SpRowArt")
	Kit.setImage(art, Kit.Images.rowBackground)
	art.ImageTransparency = 0
	art.ImageColor3 = WHITE
	art.BackgroundColor3 = colour
	art.BackgroundTransparency = 0
	art.ScaleType = Enum.ScaleType.Stretch
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.Position = UDim2.fromScale(0.5, 0.5)
	art.Size = UDim2.fromScale(1, 1)
	art.BorderSizePixel = 0
	art.Active = false
	art.ZIndex = belowChildren(frame, art)
	Kit.setCorner(art, 0.25)
	Kit.addStroke(art, { name = Kit.Names.stroke, color = BLACK, thickness = 0.03, borderOffset = -0.03, zIndex = 2 })
	Kit.addStroke(art, { name = Kit.Names.strokeLight, color = WHITE, transparency = 0.35, thickness = 0.03, borderOffset = -0.055, zIndex = 1 })
	bump(W, "rows -> Speedsters row")
end

-- Speedsters bar (progress.window / hud bar): track + fill; the fill's Size/Position/AnchorPoint stay script-owned.
local function skinBar(W, track, fill, opts)
	opts = opts or {}
	if track == nil and fill == nil then
		return
	end
	if fill and not (opts.fillOwned and opts.fillOwned.UIGradient) then
		disableGradients(fill)
	end
	if track and not (opts.trackOwned and opts.trackOwned.UIGradient) then
		disableGradients(track)
	end
	Kit.skinBar(track, fill, opts.colour or "window", { scriptOwned = opts.fillOwned, trackOwned = opts.trackOwned })
	bump(W, "bars -> Speedsters bar")
end

-- codes.modal_card TextBox: holder #003658 corner 0.2 + black 0.05 stroke, FredokaOne text.
local function skinInput(W, box, holder)
	if box == nil then
		return
	end
	Kit.setFont(box, "body")
	W.styled[box] = true
	if holder and holder:IsA("GuiObject") and not holder:IsA("ScrollingFrame") then
		holder.BackgroundColor3 = Kit.hex("#003658")
		holder.BackgroundTransparency = 0
		Kit.setCorner(holder, 0.2)
		Kit.hideLegacyStrokes(holder)
		Kit.addStroke(holder, { name = Kit.Names.stroke, color = BLACK, thickness = 0.05 })
	end
	bump(W, "text inputs -> Speedsters TextBox")
end

-- button.toggle (Settings): BackgroundColor3 stays the scripted on/off colour; corner 0.3, black Border stroke.
local function skinToggle(W, button)
	if button == nil then
		return
	end
	Kit.setCorner(button, 0.3)
	Kit.hideLegacyStrokes(button)
	Kit.addStroke(button, { name = Kit.Names.stroke, color = BLACK, thickness = 0.06, mode = "Border" })
	bump(W, "toggles -> Speedsters toggle")
end

-- SAH coloured header bands (CanvasGroup / Frame) give way to the floating Speedsters title.
local function hideBand(W, band)
	if band == nil then
		return
	end
	if band:IsA("CanvasGroup") then
		band.GroupTransparency = 1
	else
		Kit.hideDecoration(band, { recursive = true })
	end
	note(W, "SAH header band %s hidden (transparency)", band:GetFullName())
end

local function eachChildNamed(parent, pattern, fn)
	if parent == nil then
		return
	end
	for _, c in ipairs(parent:GetChildren()) do
		if string.match(c.Name, pattern) then
			fn(c)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- shared window shapes
---------------------------------------------------------------------------------------------------

-- Shop / TreadmillSpeedShop: product cards (1/2/3) with a Buy button, pass cards, the Gift popup.
local function shopCards(W, scroll)
	if scroll == nil then
		return
	end
	for _, section in ipairs(scroll:GetChildren()) do
		if section:IsA("GuiObject") then
			for _, card in ipairs(section:GetChildren()) do
				if card:IsA("Frame") and string.match(card.Name, "^%d+$") then
					skinCard(W, card)
					skinAction(W, card:FindFirstChild("Buy"), "buy_green")
				end
			end
			local main = section:FindFirstChild("Main")
			if main and main:IsA("GuiObject") and section.Name ~= "ServerLuck" then
				skinCard(W, main, { rotate = section.Name ~= "SecretStarterPack" })
				if main:FindFirstChild("Buy") then
					skinAction(W, main.Buy, "buy_green")
				end
				if main:FindFirstChild("Claim") then
					skinAction(W, main.Claim, "cyan")
				end
			end
		end
	end
	-- game passes (ImageButton cards)
	local passes = scroll:FindFirstChild("GamePasses")
	if passes then
		for _, holder in ipairs(passes:GetChildren()) do
			local main = holder:FindFirstChild("Main")
			if main and main:IsA("GuiObject") then
				skinCard(W, main)
			end
		end
	end
	-- 2X speed pack / treadmill upgrade pack (TextButton cards)
	for _, name in ipairs({ "DoubleYourSpeed", "UpgradeTreadmill" }) do
		local pack = at(scroll, name .. "/Pack")
		if pack then
			skinCard(W, pack, { rotate = false })
			if pack:FindFirstChild("Buy") then
				skinAction(W, pack.Buy, "buy_green")
			end
		end
	end
	local luck = at(scroll, "ServerLuck/Main")
	if luck then
		skinCard(W, luck, { rotate = false })
		skinAction(W, luck:FindFirstChild("BuyButton"), "buy_green")
	end
	local codeInput = at(scroll, "Codes/Main/Input")
	if codeInput then
		skinInput(W, codeInput:FindFirstChild("Input"), codeInput)
	end
end

local function giftPopup(W, gift)
	if gift == nil then
		return
	end
	paintWindow(W, gift, gift, { art = Kit.Images.giftArt, fillOnLayer = true })
	styleTitle(W, gift:FindFirstChild("Title"), { place = true, size = UDim2.new(0.62, 0, 0.12, 0), zIndex = 20 })
	headerIcon(W, gift, Kit.Icons.gift)
	skinClose(W, gift:FindFirstChild("Close"))
	-- player rows (cloned by the gifting flow): row.list_item look on the row's click surface
	local row = at(gift, "Canvas/Scroll/Template")
	if row then
		local surface = row:FindFirstChild("button")
		if surface and surface:IsA("GuiObject") then
			skinStatBox(W, surface, { corner = 0.25, transparency = 0.4, color = Kit.Colors.rowStrip, stroke = 0.03, strokeOffset = -0.03 })
		end
		local icon = row:FindFirstChild("icon")
		if icon then
			Kit.setCorner(icon, 0.25)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- studded glossy material (VISUAL_PASS_PLAN D7, refs 06 Sell Heroes / 07 Free Gift!)
---------------------------------------------------------------------------------------------------

-- The studded glossy recipes live in scripts/lib/ui_kit.luau (UiKit); these wrappers add this step's bookkeeping
-- (change notes, counters, the styled-text set that keeps the generic text pass off the step's own labels).
local STUD_TILE = UiKit.STUD_TILE
local STUD_TRANSPARENCY = UiKit.STUD_TRANSPARENCY
local GLOSS_FILL = UiKit.GLOSS_FILL
local CARD_FILL = UiKit.CARD_FILL
local CHECK_GLYPH = UiKit.CHECK_GLYPH

local layer = UiKit.layer
local setBox = UiKit.setBox
local aspect = UiKit.aspect
local cornerFor = UiKit.cornerFor
local topCorner = UiKit.topCorner

local function addStuds(parent, zIndex, opts)
	return UiKit.studs(parent, zIndex, opts)
end

local function addGloss(parent, zIndex, opts)
	return UiKit.gloss(parent, zIndex, opts)
end

local function addStreaks(parent, zIndex, layerAspect)
	return UiKit.streaks(parent, zIndex, layerAspect)
end

-- Glossy header band across the top of a window root (UiKit.headerBand). opts: colors (stops), height (fraction of
-- the root), rootCorner, rootAspect, zIndex.
local function headerBand(W, root, opts)
	local band = UiKit.headerBand(root, opts)
	note(W, "glossy header band (%s, studs, streaks, gloss) on %s", tostring(opts.colors[1][2]) .. " -> " .. tostring(opts.colors[#opts.colors][2]), root:GetFullName())
	return band
end

-- Dark studded body on the window painter (UiKit.body: the Speedsters window material with its art kept faint, a
-- dark fill, the stud texture at ~15 %, a thick ink rim and a light inner rim).
local function studdedBody(W, root, painter, opts)
	if root == nil or painter == nil then
		warnf(W, "window root/painter missing")
		return nil
	end
	local res = UiKit.body(root, painter, opts)
	if res and res.warning and not W.global then
		warnf(W, "%s", res.warning)
	end
	note(W, "window material on %s (art %s, white@0.15, corner 0.05, ink hairline 0.007)", painter:GetFullName(), tostring(opts.art or Kit.Images.windowArt))
	note(W, "dark studded body %s on %s", string.format("#%02x%02x%02x", math.floor(opts.color.R * 255 + 0.5), math.floor(opts.color.G * 255 + 0.5), math.floor(opts.color.B * 255 + 0.5)), painter:GetFullName())
	return res
end

-- Round embossed close (UiKit.closeButton): the Speedsters round X art stays on Close.TextButton (ConsoleCmds
-- contract), with an ink rim and a dark disc offset under the glyph.
local function roundClose(W, close, position, size, zIndex)
	if close == nil or not close:IsA("GuiButton") then
		warnf(W, "close missing")
		return
	end
	UiKit.closeButton(close, position, size, zIndex)
	W.styled[close] = true
	for _, d in ipairs(close:GetDescendants()) do
		if Kit.isText(d) then
			W.styled[d] = true -- the hidden 'X' copy (the art draws the X)
		end
	end
	note(W, "close %s: X art 110882579806743 on Close.TextButton", close:GetFullName())
	note(W, "round embossed close %s (ink rim + emboss disc)", close:GetFullName())
end

-- Chunky glossy button (UiKit.glossButton).
local function glossyButton(W, button, opts)
	if button == nil or not button:IsA("GuiObject") then
		warnf(W, "glossy button missing")
		return nil
	end
	UiKit.glossButton(button, opts)
	bump(W, "glossy buttons")
	return button
end

-- A TextLabel the step owns (UiKit.text), excluded from the generic text pass.
local function textLayer(W, parent, name, text, kind, opts)
	local label = UiKit.text(parent, name, text, kind, opts)
	W.styled[label] = true
	return label
end

-- A text-less TextButton + child Label, glossy (UiKit.labelButton).
local function labelButton(W, parent, name, caption, opts)
	local button, label = UiKit.labelButton(parent, name, caption, opts)
	bump(W, "glossy buttons")
	W.styled[button] = true
	W.styled[label] = true
	return button, label
end

local function hideOld(W, node)
	if node and node:IsA("GuiObject") then
		node.Visible = false
		note(W, "old %s hidden", node:GetFullName())
	end
end

---------------------------------------------------------------------------------------------------
-- windows (one function per ScreenGui)
---------------------------------------------------------------------------------------------------

local Windows = {}

Windows.Shop = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, at(root, "Background"), { art = Kit.Images.shopArt })
	styleTitle(W, at(root, "TextLabel"), { place = true, size = UDim2.new(0.4, 0, 0.1, 0) })
	headerIcon(W, root, Kit.Icons.shop, { existing = at(root, "Icon") })
	skinClose(W, at(root, "Close"))
	ensureDim(W, root)
	shopCards(W, at(root, "Main/ScrollingFrame"))
	giftPopup(W, gui:FindFirstChild("Gift"))
end

Windows.TreadmillSpeedShop = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, at(root, "Background"), { art = Kit.Images.shopArt })
	styleTitle(W, at(root, "TextLabel"), { place = true, size = UDim2.new(0.4, 0, 0.1, 0) })
	headerIcon(W, root, Kit.Icons.ability, { existing = at(root, "Icon") })
	skinClose(W, at(root, "Close"))
	ensureDim(W, root)
	local scroll = at(root, "Main/ScrollingFrame")
	shopCards(W, scroll)
	local upgradeRow = at(scroll, "UpgradeTreadmill/Pack/Frame#Frame")
	if upgradeRow then
		-- BackgroundColor3 + UIGradient.Enabled are the upgrade state (TreadmillSpeedShop:90-93): tint layer only
		skinAction(W, upgradeRow:FindFirstChild("Upgrade"), "cyan", { owned = { BackgroundColor3 = true, UIGradient = true } })
		skinAction(W, upgradeRow:FindFirstChild("RobuxUpgrade"), "price_robux")
	end
	giftPopup(W, gui:FindFirstChild("Gift"))
end

Windows.Index = function(W, gui)
	local root = gui:FindFirstChild("Index")
	paintWindow(W, root, at(root, "Background/Frame"))
	local title = at(root, "Title")
	styleTitle(W, title, { place = true, size = UDim2.new(0.5, 0, 0.117, 0) })
	headerIcon(W, root, Kit.Icons.index)
	skinClose(W, at(root, "Close"))
	ensureDim(W, root)
	local page = at(root, "Content/IndexPage")
	skinStatBox(W, at(page, "IndexListFrame/Frame"), { corner = 0.05 })
	skinStatBox(W, at(page, "IndexInfoFrame/Frame"), { corner = 0.05 }) -- RarityGlow (script colour) kept
	skinStatBox(W, at(page, "IndexRewardsFrame/Frame"), { corner = 0.05, transparency = 0.45 })
	local rewardsInner = at(page, "IndexRewardsFrame/Frame/Frame")
	if rewardsInner then
		rewardsInner.BackgroundTransparency = 1
	end
	-- ClaimRewardPanel switches ClaimButton.TextButton between UIGradient (claimable) and GreyGradient (nothing to claim)
	skinAction(W, at(page, "IndexRewardsFrame/ClaimButton"), "claim_green", {
		stateGradients = { UIGradient = "claim_green", GreyGradient = "equip_grey" },
	})
	-- ClaimAllButton.TextButton.UIGradient.Enabled is script state (Index:626-628): keep that gradient instance
	skinAction(W, at(page, "ClaimAllButton"), "claim_green")
	for _, name in ipairs({ "MoneyReward", "SpeedReward" }) do
		local reward = at(page, "IndexRewardsFrame/Rewards/" .. name)
		if reward then
			skinCard(W, reward, { pattern = false, rotate = false, corner = 0.2 })
		end
	end
	skinBar(W, at(page, "ProgressBar/Progress"), at(page, "ProgressBar/Progress/Fill"), { fillOwned = { Size = true } })
	local backdrop = at(page, "ProgressBar/Frame")
	if backdrop then
		backdrop.BackgroundTransparency = 1
	end
	-- cloned list cards (Template: Name/Visible/Parent/LayoutOrder + GradientSwap on Template.Frame are scripted)
	local template = at(page, "IndexListFrame/IndexEntries/Template")
	if template then
		skinBar(W, at(template, "Frame/ProgressBar/Progress"), at(template, "Frame/ProgressBar/Progress/Fill"), { fillOwned = { Size = true } })
		local tBackdrop = at(template, "Frame/ProgressBar/Frame")
		if tBackdrop then
			tBackdrop.BackgroundTransparency = 1
		end
		-- EquipBat.TextButton.BackgroundColor3 is the equip state: tint layer
		local equip = at(template, "Frame/EquipBat")
		if equip then
			skinAction(W, equip, "equip_green", { owned = { BackgroundColor3 = true } })
		end
		local image = at(template, "Frame/Image")
		if image then
			Kit.setCorner(image, 0.1)
		end
	end
	-- hidden mutation tabs (tabs.backpack square gradient)
	for _, name in ipairs({ "Base", "Rainbow", "Silver", "Gold" }) do
		skinAction(W, at(root, "MutationsTab/IndexEntries/" .. name), "tab_magenta", { mode = "direct" })
	end
end

Windows.Settings = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, at(root, "Background"))
	styleTitle(W, at(root, "TextLabel"), { place = true, show = true, size = Kit.Sizes.titleCompact.size })
	headerIcon(W, root, Kit.Icons.settings)
	skinClose(W, at(root, "Close"))
	ensureDim(W, root)
	-- the setting rows start below the title band (the title sits on the top edge, half inside the window)
	local content = at(root, "Frame")
	if content and content:IsA("GuiObject") then
		content.Position = UDim2.new(0, 0, 0.085, 0)
		content.Size = UDim2.new(content.Size.X.Scale, content.Size.X.Offset, 0.9, 0)
	end
	local scroll = at(root, "Frame/ScrollingFrame")
	if scroll then
		for _, row in ipairs(scroll:GetChildren()) do
			local button = row:FindFirstChild("Button")
			if row:IsA("Frame") and button and button:IsA("GuiButton") then
				-- row.settings on a dark strip; the row template SFX is cloned per setting (Settings:45-56)
				skinStatBox(W, row, { corner = 0.25, transparency = 0.4, color = Kit.Colors.rowStrip, stroke = 0.04, strokeOffset = -0.04 })
				skinToggle(W, button) -- Button.BackgroundColor3 = on/off state (Settings ~72-179)
			end
		end
	end
end

-- "Free Gift!" (ref 07). GroupRewards (LocalScript) owns ClaimReward.BackgroundColor3 (it captures the build colour as
-- the unclaimed state and writes #199700 once claimed) and ClaimReward.Title.Text ("Claimed" state); the gloss
-- multiplies whatever colour it sets. Nothing is renamed or re-parented (GroupRewards indexes FrameReward.Main.*).
local GIFT = {
	aspect = 1.36, size = UDim2.fromScale(0.56, 0.66), corner = 0.035, header = 0.14,
	headerColors = { { 0, "#45efff" }, { 0.5, "#00d0ff" }, { 1, "#0a9ef2" } },
	body = Kit.hex("#252a50"),
	card = Kit.hex("#0e1124"),
	claim = Kit.hex("#36e21c"),
	steps = {
		["Like The Game!"] = { 1, "1. Like the game!" },
		["Favorite The Game!"] = { 2, "2. Favorite the game!" },
		["Join The Community!"] = { 3, "3. Join the community!" },
	},
}

-- Header (a TextLabel stack Title + Shadow face inside Header.Txts) placed on the band, left aligned.
local function bandTitle(W, root, headerHeight, text)
	local header = at(root, "Header")
	if header == nil then
		warnf(W, "Header missing")
		return
	end
	hideBand(W, at(header, "Main"))
	setBox(header, Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, headerHeight))
	header.ZIndex = 6
	local txts = at(header, "Txts")
	if txts then
		setBox(txts, Vector2.new(0, 0.5), UDim2.fromScale(0.03, 0.5), UDim2.fromScale(0.62, 0.7))
		for _, face in ipairs(txts:GetDescendants()) do
			if face:IsA("TextLabel") then
				if text then
					face.Text = text
				end
				setBox(face, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1))
				face.TextXAlignment = Enum.TextXAlignment.Left
			end
		end
		styleTitle(W, at(txts, "Title") or txts, { strokeThickness = 0.08 })
	end
end

Windows.GroupReward = function(W, gui)
	local root = gui:FindFirstChild("FrameReward")
	if root == nil then
		warnf(W, "FrameReward missing")
		return
	end
	root.Size = GIFT.size
	local ratio = root:FindFirstChildOfClass("UIAspectRatioConstraint")
	if ratio then
		ratio.AspectRatio = GIFT.aspect
	end
	local painter = at(root, "Main#ImageLabel")
	if painter then
		setBox(painter, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1))
	end
	studdedBody(W, root, painter, { color = GIFT.body, corner = GIFT.corner })
	headerBand(W, root, { height = GIFT.header, colors = GIFT.headerColors, zIndex = 4, rootCorner = GIFT.corner, rootAspect = GIFT.aspect })
	bandTitle(W, root, GIFT.header, "Free Gift!")
	roundClose(W, at(root, "Close"), UDim2.fromScale(0.955, GIFT.header / 2), UDim2.fromScale(0.075, 0.1), 12)
	ensureDim(W, root)

	local main = at(root, "Main#Frame")
	if main == nil then
		warnf(W, "FrameReward.Main (content) missing")
		return
	end
	setBox(main, Vector2.new(0.5, 0), UDim2.fromScale(0.5, GIFT.header + 0.012), UDim2.fromScale(0.96, 1 - GIFT.header - 0.03))
	main.BackgroundTransparency = 1

	-- speed bag (the reward art already in the window) with the rays behind it; top-left of the content
	local holder = at(main, "ImageLabel")
	local holderX, holderY, holderW, holderH = 0.2, 0.265, 0.36, 0.5
	if holder then
		setBox(holder, Vector2.new(0.5, 0.5), UDim2.fromScale(holderX, holderY), UDim2.fromScale(holderW, holderH))
		holder.BackgroundTransparency = 1
		local bag = at(holder, "Icon")
		if bag then
			setBox(bag, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1.05, 1.05))
			bag.ScaleType = Enum.ScaleType.Fit
			bag.ZIndex = 2
		end
		local rays = at(holder, "Sunburst")
		if rays then
			setBox(rays, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1.35, 1.35))
			rays.ImageTransparency = 0.55
			rays.ZIndex = 0
			aspect(rays, 1)
		end
		-- "1,000 SPEED!" lives in the holder (not scripted): place it on the right half of the content, in content
		-- coordinates converted to the holder's
		local speed = at(holder, "NameLabel")
		if speed then
			local cx, cy, w, h = 0.665, 0.355, 0.62, 0.17
			local left, top = holderX - holderW / 2, holderY - holderH / 2
			setBox(speed, Vector2.new(0.5, 0.5), UDim2.fromScale((cx - left) / holderW, (cy - top) / holderH), UDim2.fromScale(w / holderW, h / holderH))
			speed.Text = "1,000 SPEED!"
			speed.ZIndex = 3
			disableGradients(speed)
			Kit.styleText(speed, "heavy", { color = WHITE, scaled = true, strokeThickness = 0.07,
				gradient = { { 0, "#8ffcff" }, { 0.5, "#1fe3ea" }, { 1, "#0fcf86" } } })
			speed.TextXAlignment = Enum.TextXAlignment.Center
			W.styled[speed] = true
		end
	end
	local limited = at(main, "Info")
	if limited then
		setBox(limited, Vector2.new(0.5, 0.5), UDim2.fromScale(0.665, 0.175), UDim2.fromScale(0.58, 0.12))
		limited.Text = "~ LIMITED TIME! ~"
		disableGradients(limited)
		Kit.styleText(limited, "heavy", { color = WHITE, scaled = true, strokeThickness = 0.07,
			gradient = { { 0, "#ffa08f" }, { 0.5, "#ff4b4b" }, { 1, "#e5173a" } } })
		W.styled[limited] = true
	end

	-- three dark rounded step cards: "1. Like the game!", "2. Favorite the game!", "3. Join the community!"
	-- (informational: nothing scripts them; the community step never prompts a group join)
	local requirements = at(main, "Requirements")
	if requirements then
		setBox(requirements, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.665), UDim2.fromScale(0.985, 0.31))
		local list = requirements:FindFirstChildOfClass("UIListLayout")
		if list then
			list.FillDirection = Enum.FillDirection.Horizontal
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center
			list.VerticalAlignment = Enum.VerticalAlignment.Center
			list.Padding = UDim.new(0.018, 0)
		end
		eachChildNamed(requirements, "^Template$", function(card)
			local caption = at(card, "Name")
			local step = caption and GIFT.steps[caption.Text]
			if step then
				card.LayoutOrder = step[1]
				caption.Text = step[2]
			end
			card.Size = UDim2.fromScale(0.315, 1)
			if isImage(card) then
				card.ImageTransparency = 1
			end
			card.BackgroundColor3 = GIFT.card
			card.BackgroundTransparency = 0.05
			Kit.setCorner(card, 0.09)
			Kit.hideLegacyStrokes(card)
			Kit.addStroke(card, { name = Kit.Names.stroke, color = Kit.hex("#3c4270"), thickness = 0.014, mode = "Border" })
			if caption then
				setBox(caption, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.16), UDim2.fromScale(0.94, 0.22))
				Kit.styleText(caption, "body", { color = WHITE, scaled = true, strokeThickness = 0.08 })
				W.styled[caption] = true
			end
			local shot = at(card, "Image")
			if shot then
				setBox(shot, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.615), UDim2.fromScale(0.9, 0.64))
				shot.ZIndex = 1
				Kit.setCorner(shot, 0.08)
				Kit.addStroke(shot, { name = Kit.Names.stroke, color = Kit.hex("#4a517e"), thickness = 0.012, mode = "Border" })
			end
			bump(W, "step cards")
		end)
	end

	-- giant glossy green Claim! with relief
	local claim = at(main, "ClaimReward")
	if claim then
		setBox(claim, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.905), UDim2.fromScale(0.42, 0.155))
		glossyButton(W, claim, { color = GIFT.claim, corner = 0.3, stroke = 0.045, glossStrength = 0.4 })
		local caption = at(claim, "Title")
		if caption then
			caption.Text = "Claim!"
			setBox(caption, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.45), UDim2.fromScale(0.78, 0.74))
			caption.ZIndex = 3
			disableGradients(caption)
			Kit.styleText(caption, "heavy", { color = WHITE, scaled = true, strokeThickness = 0.1 })
			W.styled[caption] = true
		end
		note(W, "ClaimReward -> giant glossy green Claim! (BackgroundColor3 stays GroupRewards' claim state)")
	end
end

Windows.TrailShop = function(W, gui)
	local root = gui:FindFirstChild("Main")
	paintWindow(W, root, root, { fillOnLayer = true })
	local top = at(root, "ShopContent/Top")
	hideBand(W, at(top, "Main"))
	styleTitle(W, at(top, "Above/Title_2"))
	headerIcon(W, root, Kit.Icons.trail)
	skinClose(W, at(root, "Close"))
	ensureDim(W, root)
	local template = at(root, "ShopContent/List/ScrollingFrame/Template")
	if template then
		-- Template.Background gets the rarity gradient via GradientSwap (TrailShop:68): no gradient work there
		skinCard(W, at(template, "Background"), { pattern = false, rotate = false, gradientOwned = true })
		skinAction(W, at(template, "Buttons/CashBuy"), "price_wins")
		skinAction(W, at(template, "Buttons/RobuxBuy"), "price_robux")
		skinAction(W, at(template, "Gift"), "gift_square")
		skinStatBox(W, at(template, "Data"), { transparency = 0.5, corner = 0.25 })
	end
end

Windows.Message = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	styleTitle(W, at(root, "Top/Title"), { keepColor = true }) -- Top is hidden at rest; Title.Text is scripted
	skinClose(W, at(root, "Close"))
	ensureDim(W, root)
	local contents = at(root, "Contents")
	skinAction(W, at(contents, "Ok"), "claim_green")
	skinAction(W, at(contents, "Yes"), "claim_green")
	skinAction(W, at(contents, "No"), "red")
	skinAction(W, at(contents, "Option1"), "cyan")
	skinAction(W, at(contents, "Option2"), "magenta")
end

Windows.StealDnaMessage = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, at(root, "Background/Frame"))
	styleTitle(W, at(root, "Contents/Title"), { keepColor = true })
	skinClose(W, at(root, "Close"))
	ensureDim(W, root)
	skinAction(W, at(root, "Contents/StealButton"), "claim_green")
	skinStatBox(W, at(root, "Contents/Frame"), { transparency = 0.45 })
end

Windows.TradeWindow = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	W.globalExclude = { background_2 = true }
	local backdrop = at(root, "background_2")
	if backdrop then
		Kit.hideDecoration(backdrop)
	end
	paintWindow(W, root, root, { fillOnLayer = true, globalExclude = W.globalExclude })
	ensureDim(W, root)
	-- the item panels: Speedsters stat boxes; their UIStroke.Color is the ready state (Trading) -> strokes kept
	skinStatBox(W, at(root, "ClientItems"), { corner = 0.05, keepStrokes = true })
	skinStatBox(W, at(root, "PlayerItems"), { corner = 0.05, keepStrokes = true })
	skinStatBox(W, at(root, "Tabs"), { corner = 0.1, keepStrokes = true })
	skinStatBox(W, at(root, "ClientItems/ClientBar/Container"), { corner = 0.2 })
	skinInput(W, at(root, "ClientItems/ClientBar/Search/Input"), at(root, "ClientItems/ClientBar/Search"))
	skinInput(W, at(root, "ChatOverlay/Footer/Message/Input"), at(root, "ChatOverlay/Footer/Message"))
	skinInput(W, at(root, "ClientDiamonds/Diamonds/Input"), nil)
	-- Ready / Send are GradientSwap'd at runtime (Grey/Green/Red/BlueGradient, recoloured in Assets.UI.Gradients)
	skinAction(W, at(root, "Buttons/ReadyHolder/Ready"), "claim_green")
	skinAction(W, at(root, "Buttons/CancelHolder/Cancel"), "red")
	skinAction(W, at(root, "ChatOverlay/Footer/Send"), "cyan")
	skinAction(W, at(root, "ChatButton"), "cyan", { mode = "solid" })
	-- side tabs (tabs.backpack colours); Icon ImageColor3 / ImageTransparency stay the selection state
	for _, name in ipairs({ "Brainrot", "Skin" }) do
		skinAction(W, at(root, "Tabs/" .. name), "tab_magenta", { mode = "solid" })
	end
	for _, name in ipairs({ "ClientTitle", "PlayerTitle" }) do
		styleTitle(W, at(root, name), { keepColor = true }) -- TextColor3 / Text scripted
	end
	for _, name in ipairs({ "ClientIcon", "PlayerIcon" }) do
		local avatar = at(root, name)
		if avatar then
			Kit.setCorner(avatar, 0.25)
		end
	end
end

Windows.TradePlayerList = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	styleTitle(W, at(root, "Title"), { place = true, size = UDim2.new(0.45, 0, 0.11, 0), zIndex = 60 })
	-- no Speedsters trading icon exists: the SAH trade icon becomes the header icon
	headerIcon(W, root, nil, { existing = at(root, "SideIcon"), zIndex = 61 })
	skinClose(W, at(root, "Close"), { zIndex = 62 })
	ensureDim(W, root)
	skinStatBox(W, at(root, "BottomBar/Container/Main"), { corner = 0.2 })
	skinInput(W, at(root, "BottomBar/Search/Main/Input"), at(root, "BottomBar/Search/Main"))
	local row = at(root, "Players/Player")
	if row then
		skinAction(W, at(row, "ButtonHolder/Trade"), "claim_green")
	end
end

Windows.FuseMachine = function(W, gui)
	local root = gui:FindFirstChild("Main") -- TabController root (full screen)
	local window = at(root, "FuseMachine")
	paintWindow(W, window, at(window, "Background/Frame"))
	if window then
		window.BackgroundTransparency = 1
	end
	styleTitle(W, at(window, "Title#Frame"), { place = true, size = UDim2.new(0.5, 0, 0.117, 0) })
	headerIcon(W, window, Kit.Icons.evolveHeader)
	skinClose(W, at(window, "Close"))
	ensureDim(W, root)
	-- Buy.BackgroundColor3 / Active / Visible are state (FuseMachine): tint layer
	skinAction(W, at(window, "Buy"), "buy_green", { owned = { BackgroundColor3 = true } })
	skinAction(W, at(window, "Info/Ok"), "claim_green")
	for _, name in ipairs({ "Empty.1", "Empty.2", "Empty.3", "Template" }) do
		skinStatBox(W, at(window, "Content/" .. name), { corner = 0.1, transparency = 0.45 })
	end
	skinStatBox(W, at(window, "Output"), { corner = 0.1, transparency = 0.45 })
	-- side panels drawn like small Speedsters windows
	local info = at(window, "Info")
	if info then
		Kit.skinWindow(info, at(info, "Frame"))
		note(W, "window material on %s", info:GetFullName())
	end
	local picker = at(window, "BackpackScrollingFrameContainer")
	if picker then
		Kit.skinWindow(picker, at(picker, "Frame"))
		skinStatBox(W, at(picker, "Container"), { corner = 0.05 })
		note(W, "window material on %s", picker:GetFullName())
	end
end

-- "Sell Heroes" (ref 06) on the AutoSell tab. Runtime contract with StarterPlayerScripts.GUI.SellHeroes (every name
-- below is looked up by that script): root attribute SellHeroesWindow; SpTabs.HeroesTab / EggsTab (Label, Icon);
-- SpSortPanel.SortSize / SortValue / SelectAll (Label); SpList (ScrollingFrame + UIGridLayout + UIPadding); SpEmpty;
-- SpFooter.TotalLabel / CashIcon / SpGlow / TotalValue / Hint / SellButton (Label); SpCardTemplate (Icon, HeroName,
-- SizeTag, Value, Check, UIStroke Rarity). Colours of on/off states: root attributes SpOnColor / SpOffColor /
-- SpTabOffColor (the script falls back to the same values).
local SELL = {
	aspect = 1.5, size = UDim2.fromScale(0.54, 0.6), corner = 0.035, header = 0.15, top = 0.19, bodyH = 0.6,
	headerColors = { { 0, "#00e676" }, { 1, "#00b0ff" } },
	body = Kit.hex("#23283f"), panel = Kit.hex("#131726"), list = Kit.hex("#0f1220"), card = Kit.hex("#2c3252"),
	on = Kit.hex("#2bd63c"), off = Kit.hex("#4f5674"), tabOff = Kit.hex("#1d5a2b"),
	cashIcon = 130591156585519, -- the Money HUD pill's cash icon (ui_30_hud RIBBON.cashIcon; 99458650446228 is the speed shoe)
	eggIcon = 96783034607256,
}

Windows.AutoSell = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	if root == nil then
		warnf(W, "AutoSell.Frame missing")
		return
	end
	root.Size = SELL.size
	local ratio = root:FindFirstChildOfClass("UIAspectRatioConstraint")
	if ratio then
		ratio.AspectRatio = SELL.aspect
	end
	studdedBody(W, root, at(root, "Background"), { color = SELL.body, corner = SELL.corner, hide = { at(root, "Outline") } })
	headerBand(W, root, { height = SELL.header, colors = SELL.headerColors, zIndex = 2, rootCorner = SELL.corner, rootAspect = SELL.aspect })
	local title = at(root, "TextLabel#TextLabel")
	if title then
		title.Text = "Sell Heroes"
		styleTitle(W, title, { strokeThickness = 0.08 })
		setBox(title, Vector2.new(0, 0.5), UDim2.fromScale(0.105, SELL.header / 2), UDim2.fromScale(0.6, SELL.header * 0.64))
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 10
	end
	headerIcon(W, root, Kit.Icons.index, { position = UDim2.fromScale(0.055, SELL.header / 2), size = UDim2.fromScale(0.085, 0.1275), zIndex = 11 })
	roundClose(W, at(root, "Close"), UDim2.fromScale(0.952, SELL.header / 2), UDim2.fromScale(0.07, 0.105), 12)
	ensureDim(W, root)
	-- the base auto-sell rarity picker: BackpackController keeps filling Frame (never shown: its button is hidden)
	hideOld(W, at(root, "Title"))
	hideOld(W, at(root, "TextLabel_2"))
	hideOld(W, at(root, "Frame#ScrollingFrame"))

	-- side tabs HEROES / EGGS, outside the right edge (ref 06)
	local tabs = layer(root, "Frame", "SpTabs", 2)
	tabs.BackgroundTransparency = 1
	setBox(tabs, Vector2.new(0, 0), UDim2.fromScale(1.012, SELL.top), UDim2.fromScale(0.125, 0.36))
	local tabList = Kit.ensureChild(tabs, "UIListLayout", "UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Vertical
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Padding = UDim.new(0.04, 0)
	for i, spec in ipairs({ { "HeroesTab", "HEROES", Kit.Icons.index }, { "EggsTab", "EGGS", SELL.eggIcon } }) do
		local tab = labelButton(W, tabs, spec[1], spec[2], {
			color = if i == 1 then SELL.on else SELL.tabOff, corner = 0.16, stroke = 0.045, kind = "tab",
			labelPosition = UDim2.fromScale(0.5, 0.2), labelSize = UDim2.fromScale(0.9, 0.27),
		})
		tab.LayoutOrder = i
		tab.Size = UDim2.fromScale(1, 0.48)
		local icon = layer(tab, "ImageLabel", "Icon", 3)
		Kit.setImage(icon, spec[3])
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		setBox(icon, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.63), UDim2.fromScale(0.62, 0.62))
		aspect(icon, 1)
	end

	-- Sort By panel (left column)
	local panel = layer(root, "Frame", "SpSortPanel", 2)
	panel.BackgroundColor3 = SELL.panel
	panel.BackgroundTransparency = 0.15
	setBox(panel, Vector2.new(0, 0), UDim2.fromScale(0.025, SELL.top), UDim2.fromScale(0.19, SELL.bodyH))
	Kit.setCorner(panel, 0.1)
	Kit.addStroke(panel, { name = Kit.Names.stroke, color = INK, thickness = 0.02, mode = "Border" })
	textLayer(W, panel, "SortTitle", "Sort By:", "title", { position = UDim2.fromScale(0.5, 0.08), size = UDim2.fromScale(0.86, 0.1) })
	labelButton(W, panel, "SortSize", "Size", { color = SELL.off, position = UDim2.fromScale(0.5, 0.22), size = UDim2.fromScale(0.9, 0.13), corner = 0.22, stroke = 0.06 })
	labelButton(W, panel, "SortValue", "Value", { color = SELL.on, position = UDim2.fromScale(0.5, 0.38), size = UDim2.fromScale(0.9, 0.13), corner = 0.22, stroke = 0.06 })
	local divider = layer(panel, "Frame", "Divider", 3)
	divider.BackgroundColor3 = WHITE
	divider.BackgroundTransparency = 0.8
	setBox(divider, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.49), UDim2.fromScale(0.82, 0.008))
	local selectAll = labelButton(W, panel, "SelectAll", "Select All", {
		color = SELL.off, position = UDim2.fromScale(0.5, 0.6), size = UDim2.fromScale(0.9, 0.13), corner = 0.22, stroke = 0.06,
		labelPosition = UDim2.fromScale(0.6, 0.47), labelSize = UDim2.fromScale(0.72, 0.6),
	})
	local tick = layer(selectAll, "Frame", "Tick", 3)
	tick.BackgroundColor3 = SELL.on
	tick.BackgroundTransparency = 0
	setBox(tick, Vector2.new(0.5, 0.5), UDim2.fromScale(0.13, 0.47), UDim2.fromScale(0.2, 0.7))
	aspect(tick, 1)
	Kit.setCorner(tick, 0.5)
	Kit.addStroke(tick, { name = Kit.Names.stroke, color = WHITE, thickness = 0.1, mode = "Border" })
	textLayer(W, tick, "Mark", CHECK_GLYPH, "body", { size = UDim2.fromScale(0.8, 0.8) })

	-- hero card grid (cells sized at runtime from the list width)
	local list = layer(root, "ScrollingFrame", "SpList", 2)
	list.BackgroundColor3 = SELL.list
	list.BackgroundTransparency = 0.25
	setBox(list, Vector2.new(0, 0), UDim2.fromScale(0.235, SELL.top), UDim2.fromScale(0.74, SELL.bodyH))
	list.ClipsDescendants = true
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = WHITE
	list.ScrollBarImageTransparency = 0.35
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Kit.setCorner(list, 0.035)
	Kit.addStroke(list, { name = Kit.Names.stroke, color = INK, thickness = 0.012, mode = "Border" })
	local padding = Kit.ensureChild(list, "UIPadding", "UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	local grid = Kit.ensureChild(list, "UIGridLayout", "UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.CellSize = UDim2.fromOffset(110, 130)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	textLayer(W, root, "SpEmpty", "No heroes to sell yet!", "body", {
		position = UDim2.fromScale(0.235 + 0.37, SELL.top + SELL.bodyH / 2), size = UDim2.fromScale(0.6, 0.1), zIndex = 3,
		color = Kit.hex("#c9cfee"),
	})

	-- Total Value row + Sell
	local footer = layer(root, "Frame", "SpFooter", 2)
	footer.BackgroundColor3 = SELL.panel
	footer.BackgroundTransparency = 0.1
	setBox(footer, Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0.815), UDim2.fromScale(0.95, 0.155))
	Kit.setCorner(footer, 0.22)
	Kit.addStroke(footer, { name = Kit.Names.stroke, color = INK, thickness = 0.02, mode = "Border" })
	textLayer(W, footer, "TotalLabel", "Total Value:", "title", {
		anchor = Vector2.new(0, 0.5), position = UDim2.fromScale(0.03, 0.5), size = UDim2.fromScale(0.23, 0.42), alignX = Enum.TextXAlignment.Left,
	})
	local glow = layer(footer, "Frame", "SpGlow", 2)
	glow.BackgroundColor3 = Kit.hex("#4dff2e")
	glow.BackgroundTransparency = 0
	setBox(glow, Vector2.new(0.5, 0.5), UDim2.fromScale(0.43, 0.5), UDim2.fromScale(0.3, 0.72))
	Kit.setCorner(glow, 0.5)
	Kit.addGradient(glow, Kit.hex("#4dff2e"), 0, "SpGlowGradient", { transparency = { { 0, 1 }, { 0.3, 0.62 }, { 0.65, 0.78 }, { 1, 1 } } })
	local cash = layer(footer, "ImageLabel", "CashIcon", 3)
	Kit.setImage(cash, SELL.cashIcon)
	cash.BackgroundTransparency = 1
	cash.ScaleType = Enum.ScaleType.Fit
	setBox(cash, Vector2.new(0.5, 0.5), UDim2.fromScale(0.31, 0.5), UDim2.fromScale(0.1, 0.8))
	textLayer(W, footer, "TotalValue", "$0", "heavy", {
		anchor = Vector2.new(0, 0.5), position = UDim2.fromScale(0.37, 0.5), size = UDim2.fromScale(0.3, 0.6), alignX = Enum.TextXAlignment.Left,
		stroke = 0.08,
	})
	local hint = textLayer(W, footer, "Hint", "Eggs can't be sold - place them in your base to hatch them!", "body", {
		anchor = Vector2.new(0, 0.5), position = UDim2.fromScale(0.03, 0.5), size = UDim2.fromScale(0.66, 0.42), alignX = Enum.TextXAlignment.Left,
		color = Kit.hex("#ffd84a"),
	})
	hint.Visible = false
	labelButton(W, footer, "SellButton", "Sell", {
		color = SELL.off, position = UDim2.fromScale(0.855, 0.5), size = UDim2.fromScale(0.25, 0.7), corner = 0.28, stroke = 0.05,
		kind = "buy", labelSize = UDim2.fromScale(0.7, 0.62),
	})

	-- card template (cloned by the script; never laid out itself)
	local card = layer(root, "TextButton", "SpCardTemplate", 3)
	card.Visible = false
	card.Text = ""
	card.AutoButtonColor = false
	card.Active = true
	card.BackgroundColor3 = SELL.card
	card.BackgroundTransparency = 0
	card.Size = UDim2.fromOffset(110, 130)
	Kit.setCorner(card, 0.1)
	Kit.addGradient(card, CARD_FILL, 90, Kit.Names.fill)
	Kit.addStroke(card, { name = "Rarity", color = WHITE, thickness = 0.035, mode = "Border" })
	addStuds(card, 1, { corner = 0.1, transparency = 0.9 })
	local icon = layer(card, "ImageLabel", "Icon", 2)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	setBox(icon, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.41), UDim2.fromScale(0.74, 0.56))
	textLayer(W, card, "HeroName", "Hero", "body", { position = UDim2.fromScale(0.5, 0.77), size = UDim2.fromScale(0.92, 0.15), zIndex = 3 })
	textLayer(W, card, "Value", "$0", "price", { position = UDim2.fromScale(0.5, 0.905), size = UDim2.fromScale(0.9, 0.13), zIndex = 3, color = Kit.hex("#6dff4f") })
	textLayer(W, card, "SizeTag", "1.0x", "body", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.06, 0.05), size = UDim2.fromScale(0.5, 0.13), zIndex = 3,
		alignX = Enum.TextXAlignment.Left, color = Kit.hex("#dfe4ff"),
	})
	local check = layer(card, "Frame", "Check", 4)
	check.Visible = false
	check.BackgroundColor3 = SELL.on
	check.BackgroundTransparency = 0
	setBox(check, Vector2.new(0.5, 0.5), UDim2.fromScale(0.86, 0.12), UDim2.fromScale(0.24, 0.24))
	aspect(check, 1)
	Kit.setCorner(check, 0.5)
	Kit.addStroke(check, { name = Kit.Names.stroke, color = INK, thickness = 0.08, mode = "Border" })
	textLayer(W, check, "Mark", CHECK_GLYPH, "body", { size = UDim2.fromScale(0.78, 0.78), zIndex = 5 })

	root:SetAttribute("SpOnColor", SELL.on)
	root:SetAttribute("SpOffColor", SELL.off)
	root:SetAttribute("SpTabOffColor", SELL.tabOff)
	root:SetAttribute("SellHeroesWindow", true)
	note(W, "AutoSell re-laid out as Sell Heroes (tabs, sort panel, card grid, Total Value row, Sell)")
end

Windows.PetList = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	local header = at(root, "Header")
	if header then
		header.BackgroundTransparency = 1
		disableGradients(header)
		Kit.hideLegacyStrokes(header)
	end
	styleTitle(W, at(header, "TextLabel"), { keepGradient = true }) -- Text scripted (PetList:89-90)
	headerIcon(W, header, Kit.Icons.index, { existing = at(header, "Icon"), place = false })
	-- MaxSlot: AutoButtonColor/Active/BackgroundColor3 + UIGradient.Enabled are state (PetList:62-113)
	skinAction(W, at(header, "MaxSlot"), "price_robux", { owned = { BackgroundColor3 = true, UIGradient = true } })
	skinAction(W, at(root, "EquipBest"), "equip_green")
	-- the drawer's collapse arrow: a red Speedsters tab, the '>' TextLabel kept (ConsoleCmds TextLabel contract)
	skinAction(W, at(root, "Close"), "red")
	local template = at(root, "Notepad/ScrollingFrame/Template")
	if template then
		skinRow(W, at(template, "Main_Frame"), Kit.hex("#00bbff"))
		skinAction(W, at(template, "Main_Frame/Unequip"), "red")
	end
end

Windows.GrowingEggList = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	local header = at(root, "Header")
	if header then
		header.BackgroundTransparency = 1
		disableGradients(header)
		Kit.hideLegacyStrokes(header)
	end
	styleTitle(W, at(header, "TextLabel"), { keepGradient = true })
	-- eggs have no Speedsters icon: the SAH egg stays, tagged for the header bounce
	headerIcon(W, header, nil, { existing = at(header, "Icon"), place = false })
	skinAction(W, at(header, "GrowAll"), "magenta")
	skinAction(W, at(root, "Close"), "red")
	local row = at(root, "Notepad/ScrollingFrame/Template/Main_Frame")
	if row then
		skinRow(W, row, Kit.hex("#aa00ff"))
		-- HatchButton.BackgroundColor3 / Active / Visible are row state (GrowingEggListRow): tint layer
		skinAction(W, at(row, "HatchButton"), "claim_green", { owned = { BackgroundColor3 = true, UIGradient = true } })
		-- GrowButton lives under BevelEffect: only the bevel's own image is hidden (decor pass)
		skinAction(W, at(row, "BevelEffect/GrowButton"), "magenta")
		skinBar(W, at(row, "ProgressBar"), at(row, "ProgressBar/Frame"), { fillOwned = { Size = true } })
	end
end

Windows.BuyMultiple = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	headerIcon(W, root, Kit.Icons.shop, { zIndex = 20 })
	skinClose(W, at(root, "Close"), { zIndex = 21 })
	ensureDim(W, root)
	for _, name in ipairs({ "Buy1", "BuyHalf", "BuyMax" }) do
		skinAction(W, at(root, "Contents/" .. name), "buy_green")
	end
end

Windows.TradeMessage = function(W, gui)
	-- notification banner (not a TabController tab: no dim / slide)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	headerIcon(W, root, nil, { existing = at(root, "SideIcon"), place = false })
	skinAction(W, at(root, "Buttons/Yes"), "claim_green")
	skinAction(W, at(root, "Buttons/No"), "red")
end

-- dormant windows (no live opener today): same material so they match if they are ever opened

Windows.Rebirth = function(W, gui)
	local root = gui:FindFirstChild("Rebirth")
	paintWindow(W, root, at(root, "Main"))
	styleTitle(W, at(root, "Title"), { place = true, size = UDim2.new(0.5, 0, 0.113, 0) })
	headerIcon(W, root, Kit.Icons.rebirth)
	skinClose(W, at(root, "Close"))
	local content = at(root, "Content")
	skinAction(W, at(content, "Rebirth"), "magenta")
	skinAction(W, at(content, "RobuxRebirth"), "gold_magenta")
	skinBar(W, at(content, "Holder/HolderImage/Loader/Bar"), at(content, "Holder/HolderImage/Loader/Bar/Progress"))
end

Windows.GearShop = function(W, gui)
	local root = gui:FindFirstChild("Main")
	paintWindow(W, root, at(root, "Background"), { art = Kit.Images.shopArt })
	styleTitle(W, at(root, "Title"), { place = true, size = UDim2.new(0.4, 0, 0.1, 0) })
	headerIcon(W, root, Kit.Icons.shop, { existing = at(root, "Icon") })
	skinClose(W, at(root, "Close"))
	local template = at(root, "Content/Items/Template")
	if template then
		skinCard(W, template, { rotate = false })
		skinAction(W, template:FindFirstChild("Buy"), "buy_green")
		skinAction(W, template:FindFirstChild("Auto"), "cyan")
	end
end

Windows.TreadmillShop = function(W, gui)
	local root = gui:FindFirstChild("Main")
	paintWindow(W, root, root, { fillOnLayer = true })
	local top = at(root, "ShopContent/Top")
	hideBand(W, at(top, "Main"))
	local title = at(top, "Above/Title_2")
	if title then
		styleTitle(W, title)
	end
	headerIcon(W, root, Kit.Icons.shopTreadmills)
	skinClose(W, at(root, "Close"))
	local template = at(root, "ShopContent/List/ScrollingFrame/Template")
	if template then
		skinCard(W, at(template, "Background"), { pattern = false, rotate = false, gradientOwned = true })
		skinAction(W, at(template, "Buttons/CashBuy"), "price_wins")
		skinAction(W, at(template, "Buttons/RobuxBuy"), "price_robux")
		skinAction(W, at(template, "Gift"), "gift_square")
	end
end

Windows.Codes = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true, art = Kit.Images.windowArt })
	styleTitle(W, at(root, "Title"), { place = true, size = UDim2.new(0.4, 0, 0.116, 0), zIndex = 50 })
	headerIcon(W, root, Kit.Icons.codesHeader, { existing = at(root, "SideIcon") })
	skinClose(W, at(root, "Close"))
	skinInput(W, at(root, "Input/Input"), at(root, "Input"))
	skinAction(W, at(root, "Bottom/Claim"), "cyan")
end

-- Playtime gifts: same cyan "Free Gift" header band + studded body as GroupReward (the root is 2.57:1).
Windows.FreeGifts = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	if root == nil then
		warnf(W, "FreeGifts.Frame missing")
		return
	end
	local ratio = root:FindFirstChildOfClass("UIAspectRatioConstraint")
	local rootAspect = ratio and ratio.AspectRatio or 2.57
	local headerHeight = 0.17
	studdedBody(W, root, at(root, "Main"), { color = GIFT.body, corner = 0.05 })
	headerBand(W, root, { height = headerHeight, colors = GIFT.headerColors, zIndex = 4, rootCorner = 0.05, rootAspect = rootAspect })
	local header = at(root, "Header")
	hideBand(W, at(header, "Main"))
	if header then
		setBox(header, Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, headerHeight))
		header.ZIndex = 6
		local txts = at(header, "Txts")
		if txts then
			setBox(txts, Vector2.new(0, 0.5), UDim2.fromScale(0.03, 0.5), UDim2.fromScale(0.4, 0.72))
			for _, face in ipairs(txts:GetDescendants()) do
				if face:IsA("TextLabel") then
					setBox(face, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1))
					face.TextXAlignment = Enum.TextXAlignment.Left
				end
			end
		end
	end
	styleTitle(W, at(header, "Txts/Title") or at(header, "Txts"), { strokeThickness = 0.08 })
	roundClose(W, at(root, "Close"), UDim2.fromScale(0.972, headerHeight / 2), UDim2.fromScale(0.05, 0.13), 12)
	eachChildNamed(at(root, "ItemsFrame/Gifts"), "^Slot", function(slot)
		skinCard(W, slot, { pattern = false, rotate = false, corner = 0.05 })
	end)
end

Windows.SpinnyWheel = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	styleTitle(W, at(root, "Title"), { place = true, size = UDim2.new(0.45, 0, 0.11, 0), zIndex = 60 })
	headerIcon(W, root, Kit.Icons.gift, { existing = at(root, "SideIcon"), zIndex = 61 })
	skinClose(W, at(root, "Close"), { zIndex = 62 })
	skinStatBox(W, at(root, "UsingFrame"), { corner = 0.05 })
	skinAction(W, at(root, "UsingFrame/Ok"), "claim_green")
end

Windows.Odds_UI = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, at(root, "Main"))
	local header = at(root, "Header")
	hideBand(W, at(header, "Main"))
	styleTitle(W, at(header, "Txts/Title") or at(header, "Txts"))
	headerIcon(W, root, Kit.Icons.index)
	skinClose(W, at(root, "Close"))
end

Windows.LimitedStarterPackOffer = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, root, { fillOnLayer = true })
	headerIcon(W, root, Kit.Icons.shopExclusive)
	skinClose(W, at(root, "Close"))
	local main = at(root, "LimitedStarterPack/Main")
	if main then
		skinCard(W, main)
		skinAction(W, main:FindFirstChild("Buy"), "buy_green")
	end
end

local function offlineCash(W, gui)
	local root = gui:FindFirstChild("Frame")
	paintWindow(W, root, at(root, "Background"))
	local title = at(root, "Title")
	hideBand(W, at(title, "Main"))
	styleTitle(W, at(title, "Title"))
	headerIcon(W, root, Kit.Icons.afk)
	skinClose(W, at(root, "Close"))
	skinAction(W, at(root, "ButtonsFrame/Claim"), "claim_green")
	skinAction(W, at(root, "ButtonsFrame/ClaimWithMultiplierPurchase"), "price_robux")
end
Windows.OfflineCashOnly = offlineCash
Windows.OfflineCashAndAssetLevelGrew = offlineCash

Windows.BaseUpgradeTransitionGui = function(W, gui)
	-- full-screen white transition flash (fx overlay): not a window, left to its script
	note(W, "fx overlay (WhiteFrame): no window material by design")
	W.noTextPass = true
end

-- ScreenGui name -> { path under StarterGui, window function, TabController tab? }
local WINDOW_LIST = {
	{ "Shop", "Shop", true }, { "TreadmillSpeedShop", "TreadmillSpeedShop", true }, { "Index", "Index", true },
	{ "Settings", "Settings", true }, { "GroupReward", "GroupReward", true }, { "TrailShop", "TrailShop", true },
	{ "Message", "Message", true }, { "StealDnaMessage", "StealDnaMessage", true },
	{ "TradeWindow", "TradeWindow", true }, { "TradePlayerList", "TradePlayerList", true },
	{ "FuseMachine", "FuseMachine", true }, { "AutoSell", "AutoSell", true }, { "BuyMultiple", "_MISC/BuyMultiple", true },
	{ "PetList", "PetList", false }, { "GrowingEggList", "GrowingEggList", false },
	{ "TradeMessage", "TradeMessage", false },
	{ "Rebirth", "Rebirth", false }, { "GearShop", "GearShop", false }, { "TreadmillShop", "TreadmillShop", false },
	{ "Codes", "Codes", false }, { "FreeGifts", "FreeGifts", false }, { "SpinnyWheel", "_MACHINES/SpinnyWheel", false },
	{ "Odds_UI", "Odds_UI", false }, { "LimitedStarterPackOffer", "LimitedStarterPackOffer", false },
	{ "OfflineCashOnly", "OfflineCashOnly", false }, { "OfflineCashAndAssetLevelGrew", "OfflineCashAndAssetLevelGrew", false },
	{ "BaseUpgradeTransitionGui", "BaseUpgradeTransitionGui", false },
}

---------------------------------------------------------------------------------------------------
-- ReplicatedStorage.Assets.UI templates cloned into these windows
---------------------------------------------------------------------------------------------------

-- Button-state gradients GradientSwap clones onto Message / Trading buttons at runtime (Grey/Green/Red/Blue):
-- recoloured with the Speedsters family fills (top -> bottom) so a swap keeps the Speedsters pill look.
local SWAP_GRADIENTS = {
	GreenGradient = "claim_green", RedGradient = "red", BlueGradient = "cyan", GreyGradient = "equip_grey",
}

local function assetsTemplates(W, assetsUI)
	local gradients = assetsUI:FindFirstChild("Gradients")
	for name, family in pairs(SWAP_GRADIENTS) do
		local g = gradients and gradients:FindFirstChild(name)
		if g and g:IsA("UIGradient") then
			g.Color = Kit.seq(Kit.ButtonFamilies[family].fill)
			g.Rotation = Kit.ButtonFamilies[family].fillRotation
			note(W, "Assets.UI.Gradients.%s -> %s fill", name, family)
		end
	end
	local player = at(assetsUI, "Trading/PlayerList/Player")
	if player then
		skinStatBox(W, player, { corner = 0.25, transparency = 0.45 })
		skinAction(W, at(player, "ButtonHolder/Trade"), "claim_green")
		local icon = at(player, "Icon")
		if icon then
			Kit.setCorner(icon, 0.25)
		end
		styleTexts(W, player)
		note(W, "Trading.PlayerList.Player row -> stat box + claim_green Trade")
	end
	for _, name in ipairs({ "ClientLine/ClientMessage", "PlayerLine/PlayerMessage" }) do
		local bubble = at(assetsUI, "Trading/Chat/" .. name)
		if bubble then
			Kit.setCorner(bubble, 0.25)
		end
	end
	styleTexts(W, at(assetsUI, "Trading"))
	local gifting = at(assetsUI, "Gifting/Frame/Holder/Frame")
	if gifting then
		skinAction(W, gifting:FindFirstChild("Accept"), "claim_green")
		skinAction(W, gifting:FindFirstChild("Decline"), "red")
	end
	styleTexts(W, at(assetsUI, "Gifting"))
	local slot = at(assetsUI, "FreeGifts/Slot")
	if slot then
		skinCard(W, slot, { pattern = false, rotate = false, corner = 0.05 })
		styleTexts(W, slot)
	end
	styleTexts(W, at(assetsUI, "Index"))
end

---------------------------------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------------------------------

local function summarize(W)
	local parts = {}
	local keys = {}
	for k in pairs(W.counts) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for _, k in ipairs(keys) do
		table.insert(parts, string.format("%d %s", W.counts[k], k))
	end
	return table.concat(parts, ", ")
end

Step.report = {}

function Step.Apply(place, spPlace, ctx)
	local sg = place:GetService("StarterGui")
	local rs = place:GetService("ReplicatedStorage")
	Step.report = {}
	local done, failed, missing = 0, 0, 0

	for _, entry in ipairs(WINDOW_LIST) do
		local name, path, isTab = entry[1], entry[2], entry[3]
		local gui = at(sg, path)
		if gui == nil then
			missing += 1
			print(string.format("[ui_20_windows] %-28s missing (StarterGui/%s)", name, path))
		else
			local W = newContext(name, gui)
			W.isTab = isTab
			local ok, err = pcall(function()
				hideDecor(W, gui)
				Windows[name](W, gui)
				if not W.noTextPass then
					styleTexts(W, gui)
				end
			end)
			if ok then
				done += 1
			else
				failed += 1
				warnf(W, "!! error: %s", tostring(err))
			end
			table.insert(Step.report, W)
			print(string.format("[ui_20_windows] %-28s %s%s | %s", name, ok and "ok" or "ERROR",
				isTab and " (tab: slide+dim)" or "", summarize(W)))
			for _, w in ipairs(W.warnings) do
				print("[ui_20_windows]      warn: " .. w)
			end
		end
	end

	local assetsUI = at(rs, "Assets/UI")
	if assetsUI then
		local W = newContext("Assets.UI", nil)
		local ok, err = pcall(assetsTemplates, W, assetsUI)
		if not ok then
			failed += 1
			warnf(W, "!! error: %s", tostring(err))
		end
		table.insert(Step.report, W)
		print(string.format("[ui_20_windows] %-28s %s | %s", "Assets.UI templates", ok and "ok" or "ERROR", summarize(W)))
		for _, w in ipairs(W.warnings) do
			print("[ui_20_windows]      warn: " .. w)
		end
	else
		print("[ui_20_windows] ReplicatedStorage.Assets.UI missing")
	end

	-- The hub gift chest opens "Free Gift!" again: the claim is a Like + Favorite reward now (GroupRewards /
	-- GroupRewardService no longer require the group; the community step is informational), so the prompt that
	-- scripts/steps/nogroup.luau closed is re-enabled. GroupRewards binds it (TabController.ToggleTab("GroupReward")).
	local ws = place:GetService("Workspace")
	local objects = ws:FindFirstChild("__OBJECTS")
	local giftSpot = objects and objects:FindFirstChild("GroupReward")
	local giftPrompt = giftSpot and giftSpot:FindFirstChild("ProximityPrompt")
	if giftPrompt and giftPrompt:IsA("ProximityPrompt") then
		giftPrompt.Enabled = true
		giftPrompt.ObjectText = "Free Gift!"
		giftPrompt.ActionText = "Open"
		print("[ui_20_windows] Workspace.__OBJECTS.GroupReward.ProximityPrompt re-enabled (opens the Free Gift! window)")
	else
		print("[ui_20_windows] Workspace.__OBJECTS.GroupReward.ProximityPrompt missing: the Free Gift! window has no world opener")
	end
	-- The stall's "Sell All?" prompt now opens the Sell Heroes window (Game.Npcs.AssetSellerNpc): say so.
	local stands = ws:FindFirstChild("Stands")
	local sellPrompts = stands and stands:FindFirstChild("Prompts")
	local sellAll = sellPrompts and sellPrompts:FindFirstChild("SellAll")
	local sellPrompt = sellAll and sellAll:FindFirstChild("ProximityPrompt")
	local sellWindow = at(sg, "AutoSell/Frame")
	if sellPrompt and sellPrompt:IsA("ProximityPrompt") and sellWindow and sellWindow:GetAttribute("SellHeroesWindow") == true then
		sellPrompt.ActionText = "Sell Heroes"
		print("[ui_20_windows] Workspace.Stands.Prompts.SellAll.ProximityPrompt -> \"Sell Heroes\" (opens the Sell Heroes window)")
	end

	print(string.format("[ui_20_windows] Speedsters window material: %d windows re-skinned, %d missing, %d errors", done, missing, failed))
	if failed > 0 then
		error(string.format("ui_20_windows: %d window(s) failed (see the warn lines above)", failed))
	end
end

return Step
