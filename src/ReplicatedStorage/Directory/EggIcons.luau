-- ReplicatedStorage.Directory.EggIcons (HATCH 2026-09-23, injected by scripts/inject/eggicons.luau)
-- Owner: "Add Inventory Icons for each egg (once Ani has made them)".
--
-- HOW TO ADD AN EGG ICON
--   1. Upload the egg picture (Studio: Asset Manager > Images > Bulk Import, or Creator Dashboard > Images).
--   2. Copy its IMAGE id: in Studio, paste the upload into any ImageLabel's Image and copy the number Studio shows
--      after rbxassetid://. (A Decal id from the website is NOT the image id and would show a blank icon.)
--   3. Replace the 0 next to that hero below with the number, e.g.  Hawkeye = 1234567890123,
--      ("rbxassetid://1234567890123" in quotes also works.)
--   4. Rebuild the place. 0 = not uploaded yet: that egg keeps the current generic egg image.
--
-- Used by: the backpack / hotbar egg slots (StarterPlayerScripts.GUI.BackpackController.Main), which also calls
-- ApplyToAssetConfigs once so every client screen that reads a hero config's Egg.Icon (growing eggs list, fuse
-- machine, ...) shows the same picture. Keys are the hero ids (= Directory.Assets config names, HeroCatalog.List Id).

local EggIcons = {}

EggIcons.Ids = {
	-- Stage 1: The Avengers
	Hawkeye = 0,
	BlackWidow = 0,
	CaptainAmerica = 0,
	Hulk = 0,
	Thor = 0,
	IronMan = 0,

	-- Stage 2: Justice League
	Aquaman = 0,
	GreenLantern = 0,
	Flash = 0, -- The Flash
	WonderWoman = 0,
	Batman = 0,
	Superman = 0,

	-- Stage 3: Spider-Verse
	PeterParker = 0,
	SpiderGwen = 0,
	MilesMorales = 0,
	SpiderMan2099 = 0,
	AgentVenom = 0,
	Venom = 0, -- Venom (Anti-Hero)

	-- Stage 4: My Hero Academia
	Uraraka = 0,
	Bakugo = 0,
	Todoroki = 0,
	Hawks = 0,
	Deku = 0,
	AllMight = 0,

	-- Stage 5: Dragon Ball
	Krillin = 0,
	Trunks = 0,
	Piccolo = 0,
	Gohan = 0,
	Vegeta = 0,
	Goku = 0,

	-- Stage 6: One Piece
	Usopp = 0,
	Nami = 0,
	Brook = 0,
	Sanji = 0,
	Zoro = 0,
	Shanks = 0,
	Luffy = 0,
	JoyBoy = 0, -- Joy Boy
}

-- The hero's egg icon as an image content string, or nil when none was uploaded (0 / missing / not an id).
function EggIcons.Get(heroId: string?): string?
	if type(heroId) ~= "string" then
		return nil
	end

	local value = EggIcons.Ids[heroId]

	if type(value) == "number" then
		if value >= 1 and value == math.floor(value) then
			return string.format("rbxassetid://%.0f", value)
		end

		return nil
	end

	if type(value) == "string" then
		local digits = string.match(value, "^%s*(%d+)%s*$") or string.match(value, "^%s*rbxassetid://(%d+)%s*$")

		if digits and string.match(digits, "[1-9]") then
			return "rbxassetid://" .. digits
		end
	end

	return nil
end

-- The hero's egg icon when one was uploaded, otherwise `fallback` (the current generic egg image).
function EggIcons.Resolve(heroId: string?, fallback: string?): string
	return EggIcons.Get(heroId) or fallback or ""
end

-- Writes every uploaded icon into the matching hero config's Egg.Icon (client-side copy of Directory.Assets), so
-- screens that read config.Egg.Icon directly pick it up. Heroes still at 0 are left untouched. Never errors.
function EggIcons.ApplyToAssetConfigs(directory: any): number
	local applied = 0

	if type(directory) ~= "table" then
		return applied
	end

	for heroId in pairs(EggIcons.Ids) do
		local icon = EggIcons.Get(heroId)

		if icon then
			pcall(function()
				local config = directory[heroId] -- Directory.Assets is strict: a missing hero errors (caught)
				local egg = type(config) == "table" and config.Egg

				if type(egg) == "table" then
					egg.Icon = icon
					applied += 1
				end
			end)
		end
	end

	return applied
end

return EggIcons
