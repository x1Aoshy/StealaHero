--!nocheck
-- scripts/steps/ui_50_revamp.luau (owner UI, Gekko TO DO "UI Revamp")
-- Every window a player can open gets the look of the two windows the owner picked as the reference, "Free Gift!"
-- (StarterGui.GroupReward) and "Sell Heroes" (StarterGui.AutoSell): a dark studded body, a glossy header band with
-- the window's icon and a left-aligned title, the round embossed X, dark panels / cards and chunky glossy buttons.
-- Each window has its own colour theme, icon and faint background pattern (scripts/lib/ui_kit.luau UiKit.Themes).
-- Runs after ui_20_windows (the Speedsters material pass this step builds on), ui_25_index_stages, ui_30_hud and
-- ui_40_world, before ui_60_treadmill / ui_90_terms / ui_99_textwrap.
--
-- Placement: most windows get the band ON TOP of their body ("above"): nothing inside the window moves, the root's
-- AnchorPoint is shifted so band + body stay centred (TabController always opens a window at (0.5, 0.5) and never
-- writes AnchorPoint). Windows whose old header strip already sat inside the body get the band "inside" instead.
-- Titles, header icons and Close buttons move onto the band; Close stays the root's direct child (TabController /
-- ConsoleCmds contract) and keeps its TextButton ImageLabel glyph.
-- Guard rails (as ui_20_windows D2): nothing scripts look up is renamed, re-parented or destroyed; legacy look is
-- hidden by transparency; script-owned properties (listed per window) are left alone; every new layer is Sp*-named.
-- Apply(place, spPlace, ctx) prints one line per window and errors (strict build) when a window function throws.
--
-- Index window structure after this step (StarterGui.Index, ScreenGui; root Index.Index = TabController frame):
--   Index                       Frame, UIAspectRatioConstraint 1.73, AnchorPoint Y shifted (band on top)
--     SpHeaderBand              Frame: the cyan glossy band ABOVE the body (AnchorPoint (0.5, 1) at the body's top)
--     SpHeaderIcon              the blue book icon on the band (left)
--     Title                     Frame on the band (left aligned after the icon): TextLabel = "Hero Index"
--     Close                     round X on the band (right)
--     Background.Frame          the body: dark indigo #1c2555, SpBackground (faint art), SpPattern (sparkles), SpStuds
--     Content.IndexPage         unchanged layout (IndexListFrame 69 % left: stage sections; IndexInfoFrame top right;
--                               IndexRewardsFrame bottom right; ProgressBar bottom left; ClaimAllButton)
--       IndexListFrame.Frame / IndexInfoFrame.Frame / IndexRewardsFrame.Frame
--                               dark panels (UiKit.panel, theme index: #111836 / list #0d1330, ink rim)
--   A reward panel for the Index (BASES) fits the same look with:
--     local UiKit = require("../lib/ui_kit"); local T = UiKit.Themes.index
--     UiKit.panel(frame, { color = T.panel }) / UiKit.card(card, { color = T.card, strokeColor = T.cardStroke })
--     UiKit.glossButton(button, { color = T.accent }) + UiKit.text(button, "Label", "Claim!", "button", {...})

local roblox = require("@lune/roblox")
local UiKit = require("../lib/ui_kit")
local Kit = UiKit.Kit

local Color3 = roblox.Color3
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum

local Step = {}

local T = UiKit.Themes
local WHITE = UiKit.WHITE
local INK = UiKit.INK

---------------------------------------------------------------------------------------------------
-- utilities
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

local function note(W, fmt, ...)
	table.insert(W.changes, string.format(fmt, ...))
end

local function warnf(W, fmt, ...)
	table.insert(W.warnings, string.format(fmt, ...))
end

local function lum(c)
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

-- Hides a text face by transparency (text, legacy stroke, UIStroke children).
local function hideText(label)
	if label and Kit.isText(label) then
		label.TextTransparency = 1
		label.TextStrokeTransparency = 1
		for _, c in ipairs(label:GetChildren()) do
			if c:IsA("UIStroke") then
				c.Transparency = 1
			end
		end
	end
end

-- The visible text faces of a title node (itself and its text descendants whose text is drawn): SAH titles are a
-- dark copy with a white face child, or a face with a DropShadow copy; ui_20_windows already hid the copies.
local function titleFaces(node)
	local faces = {}
	local function visit(n)
		if Kit.isText(n) and n.TextTransparency < 0.95 and n.Name ~= "DropShadow" then
			table.insert(faces, n)
		end
	end
	if node then
		visit(node)
		for _, d in ipairs(node:GetDescendants()) do
			visit(d)
		end
	end
	return faces
end

-- Title node on the band: AutomaticSize off (a TextScaled face inside a fixed band box), faces styled + centred in it.
local function bandTitle(node)
	if node and node:IsA("GuiObject") and Kit.prop(node, "AutomaticSize") ~= nil then
		node.AutomaticSize = Enum.AutomaticSize.None
	end
	local faces = titleFaces(node)
	for _, face in ipairs(faces) do
		if face ~= node and face:IsA("GuiObject") then
			UiKit.setBox(face, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1))
			if Kit.prop(face, "AutomaticSize") ~= nil then
				face.AutomaticSize = Enum.AutomaticSize.None
			end
		end
	end
	return faces
end

-- Standard chrome: band + icon + title + close on a window, with the step's bookkeeping.
--   spec: painter, theme, title (node), text, icon (existing node), close, placement, bandPx / bandHeight, corner,
--         zBand, zTop, hide
local function chrome(W, root, spec)
	if root == nil then
		warnf(W, "window root missing")
		return nil
	end
	local faces = spec.title and bandTitle(spec.title) or nil
	local res = UiKit.chrome(root, spec.painter or root, spec.theme, {
		corner = spec.corner, bandPx = spec.bandPx, bandHeight = spec.bandHeight, placement = spec.placement,
		title = spec.title, titleFaces = faces, text = spec.text, keepTitleColor = spec.keepTitleColor,
		icon = spec.icon and { existing = spec.icon } or nil, close = spec.close, zBand = spec.zBand, zTop = spec.zTop,
		hide = spec.hide, showTitle = spec.showTitle, noIcon = spec.noIcon, globalExclude = spec.globalExclude,
	})
	note(W, "chrome: band %s (%s, %.3f of the root), icon %s, title %s, close %s", spec.placement or "above",
		spec.theme.band[1][2] .. " -> " .. spec.theme.band[#spec.theme.band][2], res.box.height,
		tostring(spec.theme.letter or spec.theme.icon), spec.title and spec.title:GetFullName() or "-",
		spec.close and "round X" or "-")
	return res
end

-- Text that was dark on the old white windows turns light on the dark body (colour is kept when it is bright or a
-- script writes it: opts.skip = { [label] = true }).
local function lightenTexts(W, root, opts)
	opts = opts or {}
	local n = 0
	local names = {}
	for _, d in ipairs(root:GetDescendants()) do
		local c = Kit.isText(d) and d.TextColor3
		local grey = c and (math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B)) < 0.25
		if c and grey and not d:IsA("GuiButton") and not d:IsA("TextBox") and d.Text ~= "" and not (opts.skip and opts.skip[d])
			and d.TextTransparency < 0.95 and lum(c) < 0.3 then
			local inButton = false
			local p = d.Parent
			while p and p ~= root do
				if p:IsA("GuiButton") then
					inButton = true
					break
				end
				p = p.Parent
			end
			if not inButton then
				d.TextColor3 = opts.color or Color3.fromRGB(230, 234, 255)
				n += 1
				table.insert(names, d.Name)
			end
		end
	end
	if n > 0 then
		note(W, "%d dark texts lightened for the dark body (%s)", n, table.concat(names, ", "))
	end
end

-- Old Speedsters stat boxes / sub-panels (black @0.45) become the theme's dark panels.
local function panels(W, root, paths, theme, opts)
	opts = opts or {}
	for _, path in ipairs(paths) do
		local node = at(root, path)
		if node then
			UiKit.panel(node, { color = opts.color or theme.panel, transparency = opts.transparency or 0.12, corner = opts.corner or 0.05,
				stroke = opts.stroke, owned = opts.owned, keepStrokes = opts.keepStrokes })
		else
			warnf(W, "panel %s missing", path)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- windows
---------------------------------------------------------------------------------------------------

local Windows = {}

-- Hero Index (TabController tab "Index"; GUI/Index LocalScript). Script-owned: the section/entry clones, RarityGlow
-- colour, ClaimButton gradients, ProgressBar fill size, Title text is static.
Windows.Index = function(W, gui)
	local root = gui:FindFirstChild("Index")
	local theme = T.index
	chrome(W, root, {
		painter = at(root, "Background/Frame"), theme = theme, title = at(root, "Title"), icon = at(root, "SpHeaderIcon"),
		close = at(root, "Close"), zTop = 100,
	})
	local page = at(root, "Content/IndexPage")
	panels(W, page, { "IndexListFrame/Frame" }, theme, { color = theme.list, transparency = 0.1, corner = 0.035 })
	panels(W, page, { "IndexInfoFrame/Frame", "IndexRewardsFrame/Frame" }, theme, { corner = 0.06, keepStrokes = true })
	lightenTexts(W, root)
end

-- Robux Shop (TabController tab "Shop"; GUI/Shop/*). Script-owned: card contents, Gift / GiftingUser visibility.
Windows.Shop = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	chrome(W, root, {
		painter = at(root, "Background"), theme = T.shop, title = at(root, "TextLabel"), text = "Shop", icon = at(root, "Icon"),
		close = at(root, "Close"), zTop = 20,
	})
	lightenTexts(W, root)
end

-- Speed Shop (TabController tab "TreadmillSpeedShop").
Windows.TreadmillSpeedShop = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	chrome(W, root, {
		painter = at(root, "Background"), theme = T.speed, title = at(root, "TextLabel"), text = "Speed Shop", icon = at(root, "Icon"),
		close = at(root, "Close"), zTop = 20,
	})
	lightenTexts(W, root)
end

-- Trail Shop (hub stall; GUI/Shops/TrailShop). The old header strip (ShopContent.Top) sits inside the window: the
-- band goes inside over it; the title face (Top.Above.Title_2 / Shadow) is laid out by Above's UIListLayout, so the
-- band title is a new SpTitle and the old one is hidden. Script-owned: Template clones (Title text, rarity gradient).
local function stallShop(W, gui, theme, text)
	local root = gui:FindFirstChild("Main")
	if root == nil then
		warnf(W, "Main missing")
		return
	end
	local top = at(root, "ShopContent/Top")
	for _, face in ipairs(titleFaces(at(top, "Above"))) do
		hideText(face)
	end
	local res = chrome(W, root, {
		painter = root, theme = theme, close = at(root, "Close"), placement = "inside", zTop = 20, text = text,
		icon = at(root, "SpHeaderIcon"),
	})
	-- the card list starts under the band (List is bottom-anchored)
	local list = at(root, "ShopContent/List")
	if list and res then
		local oldHeight = list.Size.Y.Scale
		local newHeight = 1 - res.box.height - 0.015
		list.Size = UDim2.new(list.Size.X.Scale, list.Size.X.Offset, newHeight, 0)
		-- A card's height follows its width (the grid's UIAspectRatioConstraint 0.65, width-limited), so the shorter
		-- list would clip the bottom of every card (price buttons cut): the cells shrink with the list (2 % margin).
		local grid = at(list, "ScrollingFrame") and at(list, "ScrollingFrame"):FindFirstChildOfClass("UIGridLayout")
		if grid and oldHeight > 0 and newHeight < oldHeight then
			local cell = grid.CellSize
			local scaleX = cell.X.Scale * (newHeight / oldHeight) * 0.98
			grid.CellSize = UDim2.new(scaleX, cell.X.Offset, cell.Y.Scale, cell.Y.Offset)
			note(W, "card cells %.3f -> %.3f of the list width (list %.3f -> %.3f tall)", cell.X.Scale, scaleX, oldHeight, newHeight)
		end
	end
	lightenTexts(W, root)
end

Windows.TrailShop = function(W, gui)
	stallShop(W, gui, T.trail, "Trail Shop")
end

Windows.TreadmillShop = function(W, gui)
	stallShop(W, gui, T.treadmill, "Treadmill Shop")
end

-- Gear shop (dormant: no live opener). Title is a dark copy with a Shadow face.
Windows.GearShop = function(W, gui)
	local root = gui:FindFirstChild("Main")
	chrome(W, root, {
		painter = at(root, "Background"), theme = T.gear, title = at(root, "Title"), text = "Gear Shop", icon = at(root, "Icon"),
		close = at(root, "Close"), zTop = 20,
	})
	local template = at(root, "Content/Items/Template")
	if template then
		UiKit.card(template, { color = T.gear.card, strokeColor = T.gear.cardStroke, corner = 0.12, stroke = 0.02 })
	end
	lightenTexts(W, root)
end

-- Settings (TabController tab "Settings"; GUI/Settings, owned by HEROES: rows are cloned from the SFX row template at
-- runtime, so styling the template rows styles the clones). Script-owned: Button.BackgroundColor3 (on/off), row text.
Windows.Settings = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	local theme = T.settings
	chrome(W, root, {
		painter = at(root, "Background"), theme = theme, title = at(root, "TextLabel"), text = "Settings", icon = at(root, "SpHeaderIcon"),
		close = at(root, "Close"), zTop = 20, showTitle = true,
	})
	-- the rows use the whole body again (ui_20_windows had pushed them under a floating title)
	local content = at(root, "Frame")
	if content and content:IsA("GuiObject") then
		content.Position = UDim2.new(0.025, 0, 0.03, 0)
		content.Size = UDim2.new(0.975, 0, 0.94, 0)
	end
	local scroll = at(root, "Frame/ScrollingFrame")
	if scroll then
		for _, row in ipairs(scroll:GetChildren()) do
			local button = row:FindFirstChild("Button")
			if row:IsA("Frame") and button and button:IsA("GuiButton") then
				UiKit.card(row, { color = theme.card, strokeColor = theme.cardStroke, corner = 0.22, stroke = 0.03, transparency = 0.05 })
				for _, c in ipairs(row:GetChildren()) do
					if c:IsA("UIGradient") then
						c.Enabled = false
					end
				end
			end
		end
	end
	lightenTexts(W, root)
end

-- Codes (dormant).
Windows.Codes = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	local theme = T.codes
	chrome(W, root, {
		painter = root, theme = theme, title = at(root, "Title"), text = "Codes", icon = at(root, "SideIcon"), close = at(root, "Close"),
		zTop = 60,
	})
	UiKit.input(at(root, "Input"), at(root, "Input/Input"), theme)
	local claim = at(root, "Bottom/Claim")
	if claim then
		UiKit.glossButton(claim, { color = theme.accent, corner = 0.3, stroke = 0.045 })
		local caption = claim:FindFirstChild("TextLabel")
		if caption and Kit.isText(caption) then
			caption.ZIndex = math.max(caption.ZIndex, claim.ZIndex + 2)
			Kit.styleText(caption, "heavy", { color = WHITE, scaled = true, strokeThickness = 0.1 })
		end
	end
	lightenTexts(W, root)
end

-- Chances (Odds_UI, dormant): the old header strip sits inside the window -> band inside, static SpTitle.
Windows.Odds_UI = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	for _, face in ipairs(titleFaces(at(root, "Header"))) do
		hideText(face)
	end
	chrome(W, root, {
		painter = at(root, "Main"), theme = T.odds, placement = "inside", bandHeight = 0.166, text = "Chances!",
		icon = at(root, "SpHeaderIcon"), close = at(root, "Close"), zTop = 20,
	})
	lightenTexts(W, root)
end

-- Right-edge drawers (PetList = the equipped heroes, GrowingEggList = the growing eggs). The Header row (icon, the
-- scripted count / title, MaxSlot / GrowAll) stays where it is and gets the glossy band behind it; Close is the ">"
-- collapse tab (ConsoleCmds.RegisterCloseButton) and keeps its Speedsters pill. Script-owned: header texts,
-- MaxSlot colour / gradient, row clones.
local function drawer(W, gui, theme)
	local root = gui:FindFirstChild("Frame")
	if root == nil then
		warnf(W, "Frame missing")
		return
	end
	local header = at(root, "Header")
	local corner = 0.05
	local _, pxH = UiKit.rootPixels(root)
	local pxW = UiKit.rootPixels(root)
	UiKit.body(root, root, { color = theme.body, corner = UiKit.cornerFor(corner, 1), theme = theme })
	local height = header and header.Size.Y.Scale or 0.157
	UiKit.headerBand(root, {
		colors = theme.band, height = height, zIndex = header and math.max(header.ZIndex - 1, 1) or 14, rootCorner = corner,
		rootAspect = pxW / math.max(pxH, 1),
	})
	local icon = at(header, "Icon")
	if icon and theme.letter then
		-- the HUD's purple "H" tab opens this drawer: the same glossy letter replaces the book (hidden by transparency)
		local letter = UiKit.letterIcon(header, theme.letter, { name = "SpHeaderLetter", strokeColor = theme.letterStroke, zIndex = icon.ZIndex })
		UiKit.setBox(letter, icon.AnchorPoint, icon.Position, icon.Size)
		UiKit.aspect(letter, 1)
		letter:SetAttribute("SpHeaderIcon", true)
		icon.ImageTransparency = 1
		-- only the visible letter is the bounce target (SpeedstersWindowJuice takes the FIRST tagged descendant, and the
		-- hidden book carries the tag from ui_20_windows)
		icon:SetAttribute("SpHeaderIcon", nil)
	elseif icon then
		icon:SetAttribute("SpHeaderIcon", true)
	end
	for _, face in ipairs(titleFaces(at(header, "TextLabel"))) do
		Kit.styleText(face, "title", { keepColor = true, scaled = true, strokeThickness = 0.1 })
	end
	note(W, "drawer: dark studded body + glossy band behind the header (%s)", theme.band[2][2])
end

Windows.PetList = function(W, gui)
	drawer(W, gui, T.heroes)
end

Windows.GrowingEggList = function(W, gui)
	drawer(W, gui, T.eggs)
end

-- Fuse Machine (TabController tab; GUI/FuseMachine): the window is Main.FuseMachine (Main is the full-screen tab
-- root holding SpDim). The Info side card and the hero picker overlay become small dark studded windows.
-- Script-owned: Buy colour / Active / Visible, slot clones, Output fill, Title (rich text) contents.
Windows.FuseMachine = function(W, gui)
	local root = at(gui, "Main/FuseMachine")
	local theme = T.fuse
	chrome(W, root, {
		painter = at(root, "Background/Frame"), theme = theme, title = at(root, "Title#Frame"), text = "Fuse Machine",
		icon = at(root, "SpHeaderIcon"), close = at(root, "Close"), zTop = 100,
	})
	local info = at(root, "Info")
	if info then
		UiKit.body(info, at(info, "Frame"), { color = theme.body, corner = 0.08, theme = theme })
	end
	local picker = at(root, "BackpackScrollingFrameContainer")
	if picker then
		UiKit.body(picker, at(picker, "Frame"), { color = theme.body, corner = 0.04, theme = theme })
		UiKit.panel(at(picker, "Container"), { color = theme.list, transparency = 0.1, corner = 0.04 })
	end
	for _, name in ipairs({ "Content/Empty.1", "Content/Empty.2", "Content/Empty.3", "Content/Template", "Output" }) do
		local slot = at(root, name)
		if slot then
			UiKit.card(slot, { color = theme.card, strokeColor = theme.cardStroke, transparency = 0.15, corner = 0.1, stroke = 0.025 })
		end
	end
	lightenTexts(W, root)
end

-- Trade window (Global ZIndexBehavior; GUI/Trading). No title / icon / close of its own: the band carries the two
-- offer titles ("Your Offer" / "Their Offer", scripted text + colour) that already sit above the body, with the two
-- avatars on its ends and the chat button on the seam. Script-owned: item panel stroke colours (ready state),
-- Status / title texts, Ready / Cancel GradientSwap, tab icon colours.
Windows.TradeWindow = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	local theme = T.trade
	chrome(W, root, {
		painter = root, theme = theme, noIcon = true, zBand = 40, zTop = 50, bandHeight = 0.12,
		globalExclude = { background_2 = true },
	})
	for _, name in ipairs({ "ClientIcon", "PlayerIcon" }) do
		local avatar = at(root, name)
		if avatar then
			avatar.ZIndex = math.max(avatar.ZIndex, 51)
			local loading = avatar:FindFirstChild("Loading")
			if loading and loading:IsA("GuiObject") then
				loading.ZIndex = math.max(loading.ZIndex, 52)
			end
			Kit.addStroke(avatar, { name = "SpRim", color = INK, thickness = 0.05, mode = "Border" })
		end
	end
	for _, name in ipairs({ "ClientItems", "PlayerItems" }) do
		UiKit.panel(at(root, name), { color = theme.list, transparency = 0.1, corner = 0.05, keepStrokes = true, stroke = false })
	end
	UiKit.panel(at(root, "Tabs"), { color = theme.panel, transparency = 0.1, corner = 0.12, keepStrokes = true, stroke = 0.03 })
	lightenTexts(W, root)
end

-- Trading player picker (Global). Title "Trading!" (static), the swap-arrows icon, round X.
Windows.TradePlayerList = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	chrome(W, root, {
		painter = root, theme = T.trade, title = at(root, "Title"), text = "Trading!", icon = at(root, "SideIcon"),
		close = at(root, "Close"), zBand = 55, zTop = 60,
	})
	lightenTexts(W, root)
end

-- Incoming trade request banner (Global, not a TabController tab): a compact dark studded card.
Windows.TradeMessage = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	if root == nil then
		warnf(W, "Frame missing")
		return
	end
	UiKit.body(root, root, { color = T.trade.body, corner = 0.14, theme = T.trade })
	local icon = at(root, "SideIcon")
	if icon then
		icon:SetAttribute("SpHeaderIcon", true)
	end
	note(W, "banner: dark studded body (trade theme)")
end

-- Offline earnings popups (dormant): the old header strip (Title) is inside the body -> band inside + SpTitle.
local function offlineCash(W, gui)
	local root = gui:FindFirstChild("Frame")
	for _, face in ipairs(titleFaces(at(root, "Title"))) do
		hideText(face)
	end
	local painter = at(root, "Background")
	local _, _, _, h = UiKit.boxOf(painter, root)
	chrome(W, root, {
		painter = painter, theme = T.offline, placement = "inside", bandHeight = 0.136 * math.max(h, 1) / 1.05, text = "Welcome Back!",
		icon = at(root, "SpHeaderIcon"), close = at(root, "Close"), zTop = 20,
	})
	local backdrop = at(root, "Background2")
	if backdrop and backdrop:IsA("CanvasGroup") then
		backdrop.GroupTransparency = 1 -- the white sheet behind the growth list
		UiKit.panel(at(root, "AssetsLevelGrowth"), { color = T.offline.list, transparency = 0.15, corner = 0.05 })
	end
	lightenTexts(W, root)
end
Windows.OfflineCashOnly = offlineCash
Windows.OfflineCashAndAssetLevelGrew = offlineCash

-- Limited starter pack offer (dormant). The pack card keeps its pass-card look; the old title strip stays hidden.
Windows.LimitedStarterPackOffer = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	chrome(W, root, {
		painter = root, theme = T.starter, text = "Starter Pack!", icon = at(root, "SpHeaderIcon"), close = at(root, "Close"),
		zTop = 20,
	})
	lightenTexts(W, root)
end

-- Rebirth (dormant: RebirthController is a stub).
Windows.Rebirth = function(W, gui)
	local root = gui:FindFirstChild("Rebirth")
	chrome(W, root, {
		painter = at(root, "Main"), theme = T.rebirth, title = at(root, "Title"), text = "Rebirth!", icon = at(root, "SpHeaderIcon"),
		close = at(root, "Close"), zTop = 20,
	})
	UiKit.panel(at(root, "Content/Holder/HolderImage"), { color = T.rebirth.list, transparency = 0.15, corner = 0.15 })
	lightenTexts(W, root)
end

-- Generic popup (Library.Client.Message): the scripted Top.Title ("Hey!" / the popup title) becomes the band title
-- (Top was hidden in the base place). Script-owned: Close / buttons / Desc visibility, every text.
Windows.Message = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	local top = at(root, "Top")
	if top then
		Kit.hideDecoration(at(top, "background-side"))
		top.BackgroundTransparency = 1
		top.Visible = true
	end
	chrome(W, root, {
		painter = root, theme = T.message, title = top, icon = nil, close = at(root, "Close"), zTop = 20,
	})
	lightenTexts(W, root)
end

-- Steal DNA prompt (Library.Client.AssetDnaStealPrompt): Contents.Title (static rich text) moves onto the band.
Windows.StealDnaMessage = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	chrome(W, root, {
		painter = at(root, "Background/Frame"), theme = T.danger, title = at(root, "Contents/Title"), icon = nil,
		close = at(root, "Close"), zTop = 20, zBand = 0, -- the title lives in Contents (ZIndex 1): the band stays below it
	})
	panels(W, root, { "Contents/Frame" }, T.danger, { color = T.danger.list, transparency = 0.15, corner = 0.1 })
	lightenTexts(W, root)
end

-- Gift-a-player popups of the shops (the Gift ImageLabel next to the shop window).
local function giftPopup(W, gui, theme)
	local root = gui:FindFirstChild("Gift")
	if root == nil then
		return
	end
	chrome(W, root, {
		painter = root, theme = theme, title = at(root, "Title"), text = "Gift a Player!", icon = at(root, "SpHeaderIcon"),
		close = at(root, "Close"), zTop = 30,
	})
	local row = at(root, "Canvas/Scroll/Template/button")
	if row then
		UiKit.card(row, { color = theme.card, strokeColor = theme.cardStroke, corner = 0.25, stroke = 0.03 })
	end
end

Windows.ShopGift = function(W, gui)
	giftPopup(W, gui, T.gift)
end

-- Buy-multiple popup (Global; _MISC.BuyMultiple, legacy).
Windows.BuyMultiple = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	chrome(W, root, {
		painter = root, theme = T.shop, text = "Buy More!", icon = at(root, "SpHeaderIcon"), close = at(root, "Close"),
		zBand = 18, zTop = 20,
	})
	lightenTexts(W, root)
end

-- Playtime gifts: already in the reference look (ui_20_windows); it gets its gift icon on the band and the star
-- pattern like the other windows.
Windows.FreeGifts = function(W, gui)
	local root = gui:FindFirstChild("Frame")
	local painter = at(root, "Main")
	if painter then
		local art = UiKit.pattern(painter, 1, T.freegifts)
		if art then
			Kit.setCorner(art, 0.05)
		end
	end
	local band = at(root, "SpHeaderBand")
	if band == nil then
		warnf(W, "SpHeaderBand missing (ui_20_windows)")
		return
	end
	local ratio = root:FindFirstChildOfClass("UIAspectRatioConstraint")
	local rootAspect = ratio and ratio.AspectRatio or 2.57
	local h = band.Size.Y.Scale
	local size = h * 1.25
	UiKit.headerIcon(root, T.freegifts.icon, {
		position = UDim2.fromScale(0.012 + (size * 0.5) / rootAspect, h * 0.47), size = UDim2.fromScale(size / rootAspect, size), zIndex = 13,
	})
	local txts = at(root, "Header/Txts")
	if txts then
		txts.Position = UDim2.fromScale(0.012 + (size * 1.1) / rootAspect, 0.5)
	end
	note(W, "gift icon on the band + star pattern")
end

---------------------------------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------------------------------

-- window function -> ScreenGui path under StarterGui
local WINDOW_LIST = {
	{ "Index", "Index" }, { "Shop", "Shop" }, { "TreadmillSpeedShop", "TreadmillSpeedShop" }, { "TrailShop", "TrailShop" },
	{ "TreadmillShop", "TreadmillShop" }, { "GearShop", "GearShop" }, { "Settings", "Settings" }, { "Codes", "Codes" },
	{ "Odds_UI", "Odds_UI" }, { "PetList", "PetList" }, { "GrowingEggList", "GrowingEggList" }, { "FuseMachine", "FuseMachine" },
	{ "TradeWindow", "TradeWindow" }, { "TradePlayerList", "TradePlayerList" }, { "TradeMessage", "TradeMessage" },
	{ "OfflineCashOnly", "OfflineCashOnly" }, { "OfflineCashAndAssetLevelGrew", "OfflineCashAndAssetLevelGrew" },
	{ "LimitedStarterPackOffer", "LimitedStarterPackOffer" }, { "Rebirth", "Rebirth" }, { "Message", "Message" },
	{ "StealDnaMessage", "StealDnaMessage" }, { "ShopGift", "Shop" }, { "ShopGift", "TreadmillSpeedShop" },
	{ "BuyMultiple", "_MISC/BuyMultiple" }, { "FreeGifts", "FreeGifts" },
}

Step.report = {}

function Step.Apply(place, _spPlace, _ctx)
	local sg = place:GetService("StarterGui")
	Step.report = {}
	local done, failed, missing = 0, 0, 0
	for _, entry in ipairs(WINDOW_LIST) do
		local name, path = entry[1], entry[2]
		local gui = at(sg, path)
		if gui == nil then
			missing += 1
			print(string.format("[ui_50_revamp] %-28s missing (StarterGui/%s)", name, path))
		else
			local W = { name = name, gui = gui, changes = {}, warnings = {} }
			local ok, err = pcall(Windows[name], W, gui)
			if ok then
				done += 1
			else
				failed += 1
				warnf(W, "!! error: %s", tostring(err))
			end
			table.insert(Step.report, W)
			print(string.format("[ui_50_revamp] %-28s %s | %s", name, ok and "ok" or "ERROR", table.concat(W.changes, "; ")))
			for _, w in ipairs(W.warnings) do
				print("[ui_50_revamp]      warn: " .. w)
			end
		end
	end
	print(string.format("[ui_50_revamp] studded glossy revamp: %d windows, %d missing, %d errors", done, missing, failed))
	if failed > 0 then
		error(string.format("ui_50_revamp: %d window(s) failed (see the warn lines above)", failed))
	end
end

return Step
