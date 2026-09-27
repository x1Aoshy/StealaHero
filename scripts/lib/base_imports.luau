--!nocheck
-- scripts/lib/base_imports.luau
-- Saves the Blender base themes the owner imported in Studio (ServerStorage.BaseThemeImports.<Key>.<Name>, one model
-- per theme holding both pen variants, put there by assets/models/bases/BaseThemesImport.lua) to
-- assets/models/bases/<Key>/<Name>.rbxm, where scripts/steps/post_zz_base_themes.luau (section 4, IMPORTED_PENS) reads
-- them next to <Name>.json. The build runs this on its output file before overwriting it, so a Studio save of
-- StealaHero.rbxl never loses an import.
--
-- CLI: lune run scripts/tools/extract_base_imports.luau [place.rbxl]      (default StealaHero.rbxl)

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local Extract = {}

Extract.ROOT = "assets/models/bases"

local function writeModel(key, model, written)
	local dir = Extract.ROOT .. "/" .. key
	if not fs.isDir(dir) then
		fs.writeDir(dir)
	end
	local path = string.format("%s/%s.rbxm", dir, model.Name)
	fs.writeFile(path, roblox.serializeModel({ model }))
	table.insert(written, path)
	print(string.format("[extract_base_imports] %s -> %s", model:GetFullName(), path))
end

local function fromImportsFolder(imports, written)
	for _, keyFolder in ipairs(imports and imports:GetChildren() or {}) do
		for _, model in ipairs(keyFolder:GetChildren()) do
			if model:IsA("Model") then
				writeModel(keyFolder.Name, model, written)
			end
		end
	end
end

-- Returns the list of written paths (empty when the place has no imports).
function Extract.fromPlaceFile(placePath)
	local written = {}
	if not fs.isFile(placePath) then
		return written
	end
	local ok, place = pcall(roblox.deserializePlace, fs.readFile(placePath))
	if not ok then
		print("[extract_base_imports] could not read " .. placePath .. ": " .. tostring(place))
		return written
	end
	local serverStorage = place:FindFirstChild("ServerStorage")
	fromImportsFolder(serverStorage and serverStorage:FindFirstChild("BaseThemeImports"), written)
	return written
end

-- The same from a .rbxm the owner saved from Studio (right-click > Save to File... on
-- ServerStorage.BaseThemeImports, on one <Key> folder, or on single theme models), e.g. when the imports were made
-- in the published place instead of the local StealaHero.rbxl. A bare theme model is filed by its layout JSON
-- (assets/models/bases/<Key>/<Name>.json).
function Extract.fromModelFile(modelPath)
	local written = {}
	local ok, roots = pcall(roblox.deserializeModel, fs.readFile(modelPath))
	if not ok or type(roots) ~= "table" then
		print("[extract_base_imports] could not read " .. modelPath .. ": " .. tostring(roots))
		return written
	end
	local keyOf = {}
	for _, key in ipairs(fs.readDir(Extract.ROOT)) do
		if fs.isDir(Extract.ROOT .. "/" .. key) then
			for _, file in ipairs(fs.readDir(Extract.ROOT .. "/" .. key)) do
				local name = string.match(file, "^(.+)%.json$")
				if name then
					keyOf[name] = key
				end
			end
		end
	end
	for _, root in ipairs(roots) do
		if root.Name == "BaseThemeImports" then
			fromImportsFolder(root, written)
		elseif root:IsA("Model") and keyOf[root.Name] then
			writeModel(keyOf[root.Name], root, written)
		else
			for _, model in ipairs(root:GetChildren()) do
				if model:IsA("Model") and keyOf[model.Name] then
					writeModel(keyOf[model.Name], model, written)
				end
			end
		end
	end
	return written
end

return Extract
