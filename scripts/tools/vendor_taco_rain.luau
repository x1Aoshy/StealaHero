--!nocheck
-- scripts/tools/vendor_taco_rain.luau
-- Builds vendor/taco_rain.rbxm: the Raining Tacos event assets the admin panel's Taco Rain borrows from Steal a Brainrot
-- (owner 2026-09-27: "migrate the taco event to the admin panel: a rain of tacos ... the taco explosion VFX and the
-- taco particle emitter"). Taken from the VFX library (assets/vfx_library/VfxLibrary.rbxl, V40 hall, "Events /
-- Raining Tacos" = V40 ReplicatedStorage/Controllers/EventController/Events/Raining Tacos; the same Taco and
-- StruckVFX ship in Speedsters' ReplicatedStorage.Shared.TacoEventAssets):
--   Taco         the falling taco (MeshPart, mesh 121725002379738, with its pixel Trail)
--   StruckVFX    the taco explosion (an invisible Part: attachments of one-shot emitters with EmitCount attributes)
--   TacoAmbient  the sky of tacos (a 255 x 403 invisible plane with 12 emitters: tacos, yellow / red / green flakes).
--                The library shows a scaled preview of it; the untouched copy (ServerStorage.VfxLibraryOriginals) is
--                the one taken.
-- scripts/steps/post_taco_rain.luau publishes them (ReplicatedStorage.Assets.VFX.TacoRain) and derives the Taco
-- mutation's particles (ReplicatedStorage.Mutation_FX.Taco) from TacoAmbient's taco emitter. Every id is one those
-- games already use; nothing is uploaded. Particles / trails only: no sound is taken (the music id is set by
-- scripts/steps/audio.luau).
--   lune run scripts/tools/vendor_taco_rain.luau
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local LIBRARY = "assets/vfx_library/VfxLibrary.rbxl"
local OUT = "vendor/taco_rain.rbxm"
local HALL = "V40 (Steal a Brainrot)"
local CATEGORY = "Events / Raining Tacos"
local KEEP_ATTRIBUTES = { SourceFile = true, SourcePath = true }

local library = roblox.deserializePlace(fs.readFile(LIBRARY))
local shown = library:GetService("Workspace"):FindFirstChild("VfxLibrary")
shown = shown and shown:FindFirstChild(HALL)
shown = shown and shown:FindFirstChild(CATEGORY)
assert(shown, CATEGORY .. " is missing from the VFX library")
local originals = library:GetService("ServerStorage"):FindFirstChild("VfxLibraryOriginals")
originals = originals and originals:FindFirstChild(HALL)
originals = originals and originals:FindFirstChild(CATEGORY)

local root = roblox.Instance.new("Folder")
root.Name = "TacoRain"

-- A clean copy: the library's bookkeeping attributes go (SourceFile / SourcePath stay as provenance), no scripts,
-- no sounds.
local function take(name, source)
	assert(source, name .. " is missing")
	local copy = source:Clone()
	copy.Name = name
	for _, node in ipairs({ copy, table.unpack(copy:GetDescendants()) }) do
		for key in pairs(node:GetAttributes()) do
			if node == copy and not KEEP_ATTRIBUTES[key] then
				node:SetAttribute(key, nil)
			end
		end
		if node:IsA("LuaSourceContainer") or node:IsA("Sound") then
			node:Destroy()
		end
	end
	if copy:IsA("BasePart") then
		copy.Anchored = true
		copy.CanCollide = false
		copy.CanQuery = false
		copy.CanTouch = false
		copy.CastShadow = false
		copy.CFrame = roblox.CFrame.new()
	end
	local emitters = 0
	for _, d in ipairs(copy:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			emitters += 1
		end
	end
	copy.Parent = root
	print(string.format("%-12s %-9s %2d emitters from %s", name, copy.ClassName, emitters, source:GetFullName()))
	return copy
end

take("Taco", shown:FindFirstChild("Taco"))
take("StruckVFX", shown:FindFirstChild("StruckVFX"))
local ambient = take("TacoAmbient", (originals and originals:FindFirstChild("TacoAmbient")) or shown:FindFirstChild("TacoAmbient"))
assert(ambient.Size.X > 200, "TacoAmbient must be the untouched (full size) copy, got " .. tostring(ambient.Size))

fs.writeFile(OUT, roblox.serializeModel({ root }))
print(OUT .. " written")
