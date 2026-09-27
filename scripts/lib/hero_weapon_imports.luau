--!nocheck
-- scripts/lib/hero_weapon_imports.luau
-- Saves the owner's hero weapon models imported in Studio (ServerStorage.HeroWeaponImports.Weapons.<WeaponId> Tools
-- made by the owner's HeroWeaponTools.Prepare, and ServerStorage.HeroWeaponImports.Vfx.<Name> effect models; both put
-- there by assets/hero_weapons/HeroWeaponsImport.lua) to assets/hero_weapons/imports/{weapons,vfx}/<Name>.rbxm, where
-- scripts/steps/post_hero_weapons.luau reads them. The build runs this on its output file before overwriting it, so a
-- Studio save of StealaHero.rbxl never loses an import.
--
-- CLI: lune run scripts/tools/extract_hero_weapon_imports.luau [place.rbxl | HeroWeaponImports.rbxm]

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Extract = {}

Extract.ROOT = "assets/hero_weapons/imports"
Extract.KINDS = { Weapons = "weapons", Vfx = "vfx" }
Extract.MANIFEST = "assets/hero_weapons/fbx_manifest.json"

local function write(kindDir, instance, written, fileName)
	local dir = Extract.ROOT .. "/" .. kindDir
	if not fs.isDir(dir) then
		fs.writeDir(dir)
	end
	local path = string.format("%s/%s.rbxm", dir, fileName or instance.Name)
	fs.writeFile(path, roblox.serializeModel({ instance }))
	table.insert(written, path)
	print(string.format("[hero_weapon_imports] %s -> %s", instance:GetFullName(), path))
end

-- A raw Import 3D model (the owner imported the FBX files and saved the models straight to a .rbxm, without running
-- HeroWeaponsImport.lua): filed by its FBX name, weapons under their weapon id. post_hero_weapons does the kit's
-- Prepare offline for them (the model's pivot is the FBX origin).
local manifestCache = nil
local function fileRaw(model, written)
	if manifestCache == nil then
		manifestCache = if fs.isFile(Extract.MANIFEST) then serde.decode("json", fs.readFile(Extract.MANIFEST)) else false
	end
	if not manifestCache or not model:IsA("Model") then
		return false
	end
	local weapon = manifestCache.Weapons[model.Name]
	if weapon then
		write("weapons", model, written, weapon.WeaponId)
		return true
	end
	if manifestCache.Vfx[model.Name] then
		write("vfx", model, written)
		return true
	end
	return false
end

local function fromFolder(imports, written)
	for kind, kindDir in pairs(Extract.KINDS) do
		local sub = imports and imports:FindFirstChild(kind)
		for _, child in ipairs(sub and sub:GetChildren() or {}) do
			if child:IsA("Tool") or child:IsA("Model") then
				write(kindDir, child, written)
			end
		end
	end
end

function Extract.fromPlaceFile(placePath)
	local written = {}
	if not fs.isFile(placePath) then
		return written
	end
	local ok, place = pcall(roblox.deserializePlace, fs.readFile(placePath))
	if not ok then
		print("[hero_weapon_imports] could not read " .. placePath .. ": " .. tostring(place))
		return written
	end
	local serverStorage = place:FindFirstChild("ServerStorage")
	fromFolder(serverStorage and serverStorage:FindFirstChild("HeroWeaponImports"), written)
	return written
end

-- A .rbxm saved from Studio: the HeroWeaponImports folder, one of its Weapons / Vfx folders, or single Tools / models.
function Extract.fromModelFile(modelPath)
	local written = {}
	local ok, roots = pcall(roblox.deserializeModel, fs.readFile(modelPath))
	if not ok or type(roots) ~= "table" then
		print("[hero_weapon_imports] could not read " .. modelPath .. ": " .. tostring(roots))
		return written
	end
	for _, root in ipairs(roots) do
		if root.Name == "HeroWeaponImports" then
			fromFolder(root, written)
		elseif Extract.KINDS[root.Name] then
			for _, child in ipairs(root:GetChildren()) do
				write(Extract.KINDS[root.Name], child, written)
			end
		elseif root:IsA("Tool") then
			write("weapons", root, written)
		elseif root:IsA("Model") and fileRaw(root, written) then
			-- filed by name
		else
			for _, child in ipairs(root:GetChildren()) do
				if not fileRaw(child, written) and (child:IsA("Model") or child:IsA("Tool")) then
					print("[hero_weapon_imports] skipped " .. child:GetFullName() .. " (not one of the hero weapon FBX models)")
				end
			end
		end
	end
	return written
end

return Extract
