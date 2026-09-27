--!nocheck
-- scripts/tools/extract_hero_weapon_imports.luau
-- Saves the hero weapon models the owner imported in Studio (ServerStorage.HeroWeaponImports, filled by
-- assets/hero_weapons/HeroWeaponsImport.lua) to assets/hero_weapons/imports/ (see scripts/lib/hero_weapon_imports.luau;
-- the build also does it on its output file).
--   lune run scripts/tools/extract_hero_weapon_imports.luau [place.rbxl | HeroWeaponImports.rbxm]   (default StealaHero.rbxl)

local process = require("@lune/process")
local Imports = require("../lib/hero_weapon_imports")

local path = process.args[1] or "StealaHero.rbxl"
local written = if string.match(string.lower(path), "%.rbxm$") then Imports.fromModelFile(path) else Imports.fromPlaceFile(path)
if #written == 0 then
	print("[extract_hero_weapon_imports] no hero weapon imports found in " .. path)
end
