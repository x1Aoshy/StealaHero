--!nocheck
-- scripts/steps/ui_98_square_studs.luau
-- Owner 2026-09-27: "put the Roblox stud texture rbxassetid://6927295847 on the buttons and every UI, and make it show;
-- some UIs got another texture that is not studs, check it is the stud texture; reduce the corner rounding, leave them
-- square with a separation, no more rounded UI". The last UI pass (name order: before ui_99_textwrap), over every GUI
-- the build leaves in the place (StarterGui, the UI templates in ReplicatedStorage, the SurfaceGuis / BillboardGuis in
-- Workspace):
--   * every UICorner -> radius 0 (the four per-corner radii: Lune does not persist CornerRadius);
--   * every stud layer (image 6927295847) at most STUD_MAX_TRANSPARENCY transparent, so the studs read;
--   * every non-stud background pattern (the old theme patterns: stars / flames / sparkles / blocks / money / big studs,
--     the pass pattern, the blocky window art used as a faint overlay) -> hidden where its parent already has a stud
--     layer, else turned into a stud layer. Art that is a fill (drawn nearly opaque), icons and pictures are untouched.
-- The kits already write square corners (Kit.SQUARE_UI) and no theme pattern (UiKit.THEME_PATTERNS = false); this pass
-- also squares what the base place's own GUIs and the older steps carry. StarterPlayerScripts.GUI.SquareUi squares the
-- corners runtime scripts create.

local roblox = require("@lune/roblox")

local Content = roblox.Content
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Enum = roblox.Enum

local Step = {}

Step.STUD_ID = "6927295847"
Step.STUD_MAX_TRANSPARENCY = 0.62
Step.STUD_TILE = UDim2.fromOffset(18, 18)
Step.CONVERTED_TRANSPARENCY = 0.6
-- tiled / overlay textures that are not the stud texture
Step.NON_STUD_PATTERNS = {
	["116054484875156"] = "stars",
	["86655919544454"] = "flames",
	["130029461460330"] = "sparkles",
	["118133511364596"] = "blocks",
	["123051839615959"] = "money",
	["117164658961906"] = "big studs",
	["125961309868308"] = "pass pattern",
	["106477372921851"] = "blocky window art",
}
-- a pattern drawn more opaque than this is a fill, not an overlay: left alone
Step.OVERLAY_MIN_TRANSPARENCY = 0.3

local function get(inst, prop)
	local ok, value = pcall(function()
		return inst[prop]
	end)
	return if ok then value else nil
end

local function assetDigits(inst)
	local content = get(inst, "ImageContent")
	local text = if content ~= nil then tostring(content) else tostring(get(inst, "Image") or "")
	return string.match(text, "(%d%d%d%d%d+)")
end

local function isImage(inst)
	return inst:IsA("ImageLabel") or inst:IsA("ImageButton")
end

local function hasStudSibling(inst)
	local parent = inst.Parent
	if parent == nil then
		return false
	end
	for _, sibling in ipairs(parent:GetChildren()) do
		if sibling ~= inst and isImage(sibling) and assetDigits(sibling) == Step.STUD_ID and get(sibling, "ImageTransparency") ~= nil
			and sibling.ImageTransparency < 1 then
			return true
		end
	end
	return false
end

local function guiRoots(place)
	local roots = { place:GetService("StarterGui") }
	local rs = place:GetService("ReplicatedStorage")
	table.insert(roots, rs)
	for _, d in ipairs(place:GetService("Workspace"):GetDescendants()) do
		if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			table.insert(roots, d)
		end
	end
	return roots
end

function Step.Apply(place, _spPlace, _ctx)
	local squared, studsShown, patternsHidden, patternsConverted = 0, 0, 0, 0
	local seen = {}
	local zero = UDim.new(0, 0)
	for _, root in ipairs(guiRoots(place)) do
		for _, d in ipairs(root:GetDescendants()) do
			if seen[d] then
				continue
			end
			seen[d] = true
			if d:IsA("UICorner") then
				d.TopLeftRadius = zero
				d.TopRightRadius = zero
				d.BottomLeftRadius = zero
				d.BottomRightRadius = zero
				squared += 1
			elseif isImage(d) then
				local digits = assetDigits(d)
				if digits == Step.STUD_ID then
					if d.ImageTransparency > Step.STUD_MAX_TRANSPARENCY and d.ImageTransparency < 1 then
						d.ImageTransparency = Step.STUD_MAX_TRANSPARENCY
						studsShown += 1
					end
				elseif digits and Step.NON_STUD_PATTERNS[digits] and d.ImageTransparency >= Step.OVERLAY_MIN_TRANSPARENCY
					and d.ImageTransparency < 1 then
					if hasStudSibling(d) then
						d.ImageTransparency = 1
						patternsHidden += 1
					else
						d.ImageContent = Content.fromUri("rbxassetid://" .. Step.STUD_ID)
						d.ScaleType = Enum.ScaleType.Tile
						d.TileSize = Step.STUD_TILE
						d.ImageTransparency = Step.CONVERTED_TRANSPARENCY
						patternsConverted += 1
					end
				end
			end
		end
	end
	print(string.format(
		"[ui_98_square_studs] %d UICorners squared, %d stud layers made visible (<= %.2f), %d non-stud patterns hidden, %d turned into studs",
		squared, studsShown, Step.STUD_MAX_TRANSPARENCY, patternsHidden, patternsConverted))
end

return Step
