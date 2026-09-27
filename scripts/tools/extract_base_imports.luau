--!nocheck
-- scripts/tools/extract_base_imports.luau
-- Saves the Blender base pens imported in Studio (ServerStorage.BaseThemeImports.<Key>.<Variant>) to
-- assets/models/bases/<Key>/<Name>.rbxm (see scripts/lib/base_imports.luau; the build also does it on its output
-- file before overwriting it). Accepts a saved place (.rbxl) or a .rbxm saved from Studio with right-click > Save to
-- File... on BaseThemeImports (imports made in the published place).
--   lune run scripts/tools/extract_base_imports.luau [place.rbxl | BaseThemeImports.rbxm]      (default StealaHero.rbxl)

local process = require("@lune/process")
local BaseImports = require("../lib/base_imports")

local path = process.args[1] or "StealaHero.rbxl"
local written = if string.match(string.lower(path), "%.rbxm$") then BaseImports.fromModelFile(path) else BaseImports.fromPlaceFile(path)
if #written == 0 then
	print("[extract_base_imports] no base theme imports found in " .. path)
end
