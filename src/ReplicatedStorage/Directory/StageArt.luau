-- ReplicatedStorage.Directory.StageArt
-- Stage card art for the Hero Index (docs/VISUAL_PASS_PLAN.md D5). Injected by scripts/inject/stageart.luau.
--
-- Keys are the internal zone keys (Workspace.__OBJECTS.Areas.GuardAreas.<Key>, Directory.Areas._Index.<Key>); the
-- player only ever sees Number + Name. `pairs(StageArt)` yields exactly the 6 stages; the helpers below live on the
-- metatable (StageArt.Get, StageArt.Order, ...), so they never show up in an iteration.
--
--   Number   stage number 1..6 (the Index lists the stages in this order)
--   Name     the stage name players see
--   File     the illustration in the project (941x1672, 9:16) that belongs on the card
--   ImageId  the uploaded Roblox image asset id, 0 = not uploaded yet
--   Colors   2-3 colour stops sampled from the illustration (light top -> saturated -> dark bottom); the Index card
--            draws them as a vertical gradient + tiled stud texture + big stage number while ImageId is 0
--
-- >>> OWNER: HOW TO SHOW THE REAL STAGE ART <<<
--   1. Upload the six PNGs of assets/Stages/ to Roblox (Studio: View > Asset Manager > Images > Bulk Import, or
--      create.roblox.com > Development Items > Images). Use the account/group that owns the experience.
--   2. Copy each uploaded image's asset id (the number in rbxassetid://<id>; if you uploaded Decals, use the Image
--      id Roblox shows for the decal, not the decal id).
--   3. Paste it into `ImageId` of the matching stage below (replace the 0), e.g. `ImageId = 123456789012345,`.
--   4. Rebuild the place. Nothing else changes: a non-zero ImageId switches that card from the fallback to the art.

local STUD_TEXTURE_ID = 6927295847 -- Speedsters stud tile (UI), drawn with ScaleType.Tile

local Stages = {
	Forest = {
		Number = 1,
		Name = "The Avengers",
		File = "assets/Stages/Stage1_TheAvengers.png",
		ImageId = 0, -- <<< paste the uploaded Stage1_TheAvengers.png image id here
		-- sky blue, tower glass blue, steel navy
		Colors = { Color3.fromRGB(101, 179, 242), Color3.fromRGB(23, 141, 247), Color3.fromRGB(39, 79, 127) },
	},
	Lake = {
		Number = 2,
		Name = "Justice League",
		File = "assets/Stages/Stage2_JusticeLeague.png",
		ImageId = 0, -- <<< paste the uploaded Stage2_JusticeLeague.png image id here
		-- lavender sky, periwinkle, dusk indigo
		Colors = { Color3.fromRGB(135, 141, 213), Color3.fromRGB(92, 106, 208), Color3.fromRGB(85, 86, 159) },
	},
	Desert = {
		Number = 3,
		Name = "Spider-Verse",
		File = "assets/Stages/Stage3_SpiderVerse.png",
		ImageId = 0, -- <<< paste the uploaded Stage3_SpiderVerse.png image id here
		-- sunset orange, brick red, rooftop shadow
		Colors = { Color3.fromRGB(236, 148, 67), Color3.fromRGB(176, 85, 47), Color3.fromRGB(65, 33, 30) },
	},
	Jungle = {
		Number = 4,
		Name = "My Hero Academia",
		File = "assets/Stages/Stage4_MyHeroAcademia.png",
		ImageId = 0, -- <<< paste the uploaded Stage4_MyHeroAcademia.png image id here
		-- glass teal, deep sky blue, navy
		Colors = { Color3.fromRGB(119, 171, 192), Color3.fromRGB(3, 61, 178), Color3.fromRGB(5, 51, 135) },
	},
	Snow = {
		Number = 5,
		Name = "Dragon Ball",
		File = "assets/Stages/Stage5_DragonBall.png",
		ImageId = 0, -- <<< paste the uploaded Stage5_DragonBall.png image id here
		-- Namek green sky, green, blue grass
		Colors = { Color3.fromRGB(131, 222, 122), Color3.fromRGB(75, 202, 63), Color3.fromRGB(37, 98, 198) },
	},
	Volcano = {
		Number = 6,
		Name = "One Piece",
		File = "assets/Stages/Stage6_OnePiece.png",
		ImageId = 0, -- <<< paste the uploaded Stage6_OnePiece.png image id here
		-- lagoon cyan, sky blue, dock wood
		Colors = { Color3.fromRGB(99, 207, 232), Color3.fromRGB(12, 136, 249), Color3.fromRGB(86, 69, 59) },
	},
}

for key, stage in pairs(Stages) do
	stage.Key = key
end

local Helpers = {}

Helpers.STUD_TEXTURE_ID = STUD_TEXTURE_ID
Helpers.STUD_TEXTURE = "rbxassetid://" .. STUD_TEXTURE_ID

-- Zone keys in stage order.
Helpers.Order = {}
for key, stage in pairs(Stages) do
	Helpers.Order[stage.Number] = key
end

-- The stage entry for a zone key, or nil (retired / unknown zones have none).
function Helpers.Get(key: string?)
	if type(key) ~= "string" then
		return nil
	end
	return Stages[key]
end

function Helpers.IsStage(key: string?): boolean
	return Helpers.Get(key) ~= nil
end

-- "rbxassetid://<ImageId>", or "" while the art has not been uploaded (ImageId 0).
function Helpers.GetImage(key: string?): string
	local stage = Helpers.Get(key)
	local id = stage and tonumber(stage.ImageId) or 0
	if id == nil or id <= 0 then
		return ""
	end
	return "rbxassetid://" .. string.format("%d", id)
end

function Helpers.HasImage(key: string?): boolean
	return Helpers.GetImage(key) ~= ""
end

-- The fallback gradient as a ColorSequence (evenly spaced stops, top to bottom with UIGradient.Rotation = 90).
function Helpers.GetColorSequence(key: string?): ColorSequence
	local stage = Helpers.Get(key)
	local colors = stage and stage.Colors or nil
	if type(colors) ~= "table" or #colors == 0 then
		return ColorSequence.new(Color3.fromRGB(0, 180, 255), Color3.fromRGB(11, 27, 61))
	end
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local keypoints = {}
	for i, color in ipairs(colors) do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color))
	end
	return ColorSequence.new(keypoints)
end

return setmetatable(Stages, { __index = Helpers })
