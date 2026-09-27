-- scripts/steps/ui_25_index_stages.luau
-- Visual pass D5 (owner INDEX): the Hero Index stage cards. Build hook: scripts/build_stealahero.luau step 14b runs
-- every scripts/steps/ui_*.luau in name order, Apply(place, spPlace, ctx) - this one runs right after ui_20_windows
-- (which skins the Index window) so the card look below wins over its generic corner.
--
-- Target: StarterGui.Index.Index.Content.IndexPage.IndexListFrame.IndexEntries.Template.Frame, the area card of the
-- section template the Index LocalScript clones once per stage (src/StarterPlayer/StarterPlayerScripts/GUI/Index/
-- init.client.luau, `_ensureSectionPool`). The card becomes a vertical 9:16 stage card:
--
--   Frame                  (card, name/class kept; ProgressBar + EquipBat children untouched, they sit beside it)
--     SpStageAspect        UIAspectRatioConstraint 0.5625 (9:16), width dominant, FitWithinMaxSize
--     UICorner             10 px (per-corner radii; CornerRadius does not persist in Lune)
--     Image                the stage art: ImageLabel ScaleType Crop, 10 px corners, ink outline (SpStroke). The
--                          script sets Image = StageArt.GetImage(key) ("" while the PNG is not uploaded)
--     SpStageFallback      shown by the script while ImageId == 0: white Frame + SpStageGradient (StageArt Colors,
--                          vertical) + SpGloss (top shine) + SpStuds (tiled rbxassetid://6927295847) +
--                          SpStageCaption ("STAGE") + SpStageNumber (big stage number)
--     TextLabel            the floating stage-name title over the top of the card (FredokaOne, white, ink outline)
--
-- D2 (CONTRACTS_PHASE3): no protected node is renamed, reclassed, destroyed or hidden; new layers carry Sp* names;
-- no UIScale. Lune 0.10.5: images via ImageContent (Kit.setImage), fonts via FontFace, corners via the 4 radii.

local roblox = require("@lune/roblox")
local Kit = require("../lib/speedsters_ui_kit")

local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Color3 = roblox.Color3
local Enum = roblox.Enum
local Instance = roblox.Instance
local ColorSequence = roblox.ColorSequence
local ColorSequenceKeypoint = roblox.ColorSequenceKeypoint
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint

local Step = {}

local CARD_ASPECT = 9 / 16 -- 0.5625
local CARD_CORNER = UDim.new(0, 10)
local STUD_TEXTURE_ID = 6927295847
local INK = Kit.Colors.ink -- #0b1b3d
local WHITE = Color3.fromRGB(255, 255, 255)

local TEMPLATE_PATH = { "Index", "Index", "Content", "IndexPage", "IndexListFrame", "IndexEntries", "Template", "Frame" }

local function log(fmt, ...)
	print(string.format("[ui_25_index_stages] " .. fmt, ...))
end

local function child(parent, name, className)
	for _, c in ipairs(parent:GetChildren()) do
		if c.Name == name and (className == nil or c.ClassName == className) then
			return c
		end
	end
	return nil
end

-- The child `name` of exact class `className`, created when missing (idempotent re-runs).
local function ensure(parent, className, name)
	local existing = child(parent, name, className)
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local function corner(inst)
	local c = inst:FindFirstChildOfClass("UICorner")
	if not c then
		c = Instance.new("UICorner")
		c.Name = "UICorner"
		c.Parent = inst
	end
	c.TopLeftRadius = CARD_CORNER
	c.TopRightRadius = CARD_CORNER
	c.BottomLeftRadius = CARD_CORNER
	c.BottomRightRadius = CARD_CORNER
	return c
end

local function fill(inst, zIndex)
	inst.AnchorPoint = Vector2.new(0.5, 0.5)
	inst.Position = UDim2.fromScale(0.5, 0.5)
	inst.Size = UDim2.fromScale(1, 1)
	inst.BorderSizePixel = 0
	inst.ZIndex = zIndex
	inst.Visible = true
end

-- Default fallback colours in the template (stage 1 palette); the script recolours every card per stage.
local function defaultSequence()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(101, 179, 242)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(23, 141, 247)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 79, 127)),
	})
end

local function styleCard(card)
	-- 9:16 portrait card. Width stays the SAH column width (0.228 of the section row); the constraint derives the
	-- height, so the ProgressBar / EquipBat children (scale-positioned beside the card) keep their place.
	local aspect = ensure(card, "UIAspectRatioConstraint", "SpStageAspect")
	aspect.AspectRatio = CARD_ASPECT
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	aspect.DominantAxis = Enum.DominantAxis.Width
	corner(card)
	card.BackgroundTransparency = 1
	card.ClipsDescendants = false -- ProgressBar / EquipBat live outside the card rectangle

	-- stage art
	local art = child(card, "Image", "ImageLabel")
	assert(art, "Template.Frame.Image (ImageLabel) missing")
	fill(art, 1)
	art.ScaleType = Enum.ScaleType.Crop
	art.BackgroundColor3 = Color3.fromRGB(24, 38, 68)
	art.BackgroundTransparency = 0 -- dark plate while an uploaded image streams in
	art.ImageTransparency = 0
	art.ImageColor3 = WHITE
	Kit.setImage(art, nil) -- per-stage image is script-owned (Index `_renderStageCard`)
	corner(art)
	Kit.addStroke(art, { name = Kit.Names.stroke, color = INK, thickness = 0.022, zIndex = 1 })

	-- fallback: StageArt gradient + studs + big number (ImageId == 0)
	local fallback = ensure(card, "Frame", "SpStageFallback")
	fill(fallback, 2)
	fallback.BackgroundColor3 = WHITE
	fallback.BackgroundTransparency = 0
	fallback.ClipsDescendants = false
	corner(fallback)
	local gradient = ensure(fallback, "UIGradient", "SpStageGradient")
	gradient.Color = defaultSequence()
	gradient.Rotation = 90
	gradient.Offset = Vector2.new(0, 0)
	gradient.Transparency = NumberSequence.new(0)
	gradient.Enabled = true
	Kit.addStroke(fallback, {
		name = Kit.Names.strokeLight, color = WHITE, transparency = 0.45, thickness = 0.012, borderOffset = -0.03,
		zIndex = 2, position = "Inner",
	})

	local gloss = ensure(fallback, "Frame", "SpGloss")
	gloss.AnchorPoint = Vector2.new(0.5, 0)
	gloss.Position = UDim2.fromScale(0.5, 0)
	gloss.Size = UDim2.fromScale(1, 0.5)
	gloss.BorderSizePixel = 0
	gloss.BackgroundColor3 = WHITE
	gloss.BackgroundTransparency = 0
	gloss.ZIndex = 3
	gloss.Visible = true
	corner(gloss)
	local glossFade = ensure(gloss, "UIGradient", "SpGlossFade")
	glossFade.Color = ColorSequence.new(WHITE)
	glossFade.Rotation = 90
	glossFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.62),
		NumberSequenceKeypoint.new(0.55, 0.88),
		NumberSequenceKeypoint.new(1, 1),
	})
	glossFade.Enabled = true

	local studs = ensure(fallback, "ImageLabel", "SpStuds")
	fill(studs, 3)
	studs.BackgroundTransparency = 1
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(26, 26)
	studs.ImageColor3 = WHITE
	studs.ImageTransparency = 0.8
	Kit.setImage(studs, STUD_TEXTURE_ID)
	corner(studs)

	local caption = ensure(fallback, "TextLabel", "SpStageCaption")
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.Position = UDim2.fromScale(0.5, 0.4)
	caption.Size = UDim2.fromScale(0.62, 0.08)
	caption.BackgroundTransparency = 1
	caption.ZIndex = 4
	caption.Visible = true
	caption.Text = "STAGE"
	caption.TextXAlignment = Enum.TextXAlignment.Center
	caption.TextYAlignment = Enum.TextYAlignment.Center
	Kit.styleText(caption, "tab", { scaled = true, color = WHITE, strokeThickness = 0.1 })

	local number = ensure(fallback, "TextLabel", "SpStageNumber")
	number.AnchorPoint = Vector2.new(0.5, 0.5)
	number.Position = UDim2.fromScale(0.5, 0.62)
	number.Size = UDim2.fromScale(0.86, 0.36)
	number.BackgroundTransparency = 1
	number.ZIndex = 4
	number.Visible = true
	number.Text = "1"
	number.TextXAlignment = Enum.TextXAlignment.Center
	number.TextYAlignment = Enum.TextYAlignment.Center
	Kit.styleText(number, "heavy", { scaled = true, color = WHITE, strokeThickness = 0.07 })

	-- floating stage title over the card (the script writes the stage name into it)
	local title = child(card, "TextLabel", "TextLabel")
	assert(title, "Template.Frame.TextLabel missing")
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.035)
	title.Size = UDim2.fromScale(0.94, 0.19)
	title.BackgroundTransparency = 1
	title.ZIndex = 6
	title.Visible = true
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextColor3 = WHITE
	title.Text = "The Avengers"
	Kit.styleText(title, "button", { scaled = true, color = WHITE, strokeThickness = 0.1, strokeColor = INK, disableGradients = true })
	local sizeCap = ensure(title, "UITextSizeConstraint", "SpTitleSize")
	sizeCap.MaxTextSize = 34
	sizeCap.MinTextSize = 8
	return art, fallback, title
end

function Step.Apply(place, _spPlace, _ctx)
	local node = place:GetService("StarterGui")
	for _, name in ipairs(TEMPLATE_PATH) do
		node = node and child(node, name)
	end
	assert(node and node:IsA("Frame"), "StarterGui." .. table.concat(TEMPLATE_PATH, ".") .. " (Frame) missing")
	styleCard(node)
	log("Index stage card template: 9:16 SpStageAspect, Crop art + ink outline, SpStageFallback (gradient, gloss, studs %d, number), floating title; 10 px corners", STUD_TEXTURE_ID)
end

return Step
