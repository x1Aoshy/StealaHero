--!nocheck
-- scripts/tools/vendor_weapon_vfx.luau
-- Builds vendor/weapon_vfx.rbxm: the particle emitters the hero weapons borrow from the sibling games (owner 2026-09-27:
-- "the batarang explodes where it lands, take the explosion VFX from Speedsters - Eggman's missiles do it when they
-- explode"; "Mjolnir: only the hammer and particle emitters, find emitters that fit better"). Particle emitters only:
-- scripts/steps/post_hero_weapons.luau publishes them as ReplicatedStorage.Assets.VFX.HeroWeapons.<Name> (one
-- Attachment per effect) and StarterPlayerScripts.BranchControllers.HeroWeaponController emits them.
--   EggmanBlast     Speedsters' bomb / Eggman missile explosion (../Speedsters/assets/vfx_imported/BombExplodeVFX.rbxm)
--   ToonLightning   Steal a Brainrot's Ban Hammer lightning strike (assets/vfx_library/VfxLibrary.rbxl)
--   ElectricImpact  Steal a Brainrot's Ban Hammer impact burst (same library)
-- The texture ids are the ones those games already use; nothing is uploaded.
--   lune run scripts/tools/vendor_weapon_vfx.luau [<Speedsters repo>]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local SPEEDSTERS = process.args[1] or "../Speedsters"
local LIBRARY = "assets/vfx_library/VfxLibrary.rbxl"
local OUT = "vendor/weapon_vfx.rbxm"

local root = roblox.Instance.new("Folder")
root.Name = "HeroWeaponParticles"

-- An Attachment named `name` holding clones of every ParticleEmitter under `source` (disabled, one-shot).
local function collect(name, source, filter)
	local attachment = roblox.Instance.new("Attachment")
	attachment.Name = name
	local count = 0
	for _, d in source:GetDescendants() do
		if d:IsA("ParticleEmitter") and (filter == nil or filter(d)) then
			local clone = d:Clone()
			clone.Enabled = false
			clone.Parent = attachment
			count += 1
		end
	end
	assert(count > 0, name .. ": no emitters under " .. source:GetFullName())
	attachment.Parent = root
	print(string.format("%-15s %2d emitters from %s", name, count, source:GetFullName()))
end

-- Speedsters: the bomb blast Folder (its emitters carry EmitCount attributes)
local bomb = roblox.deserializeModel(fs.readFile(SPEEDSTERS .. "/assets/vfx_imported/BombExplodeVFX.rbxm"))[1]
collect("EggmanBlast", bomb)

-- The VFX library: V40's Ban Hammer folder (each effect is a Model with an Attachment + a _Preview copy)
local library = roblox.deserializePlace(fs.readFile(LIBRARY))
local v40 = library:GetService("Workspace"):FindFirstChild("VfxLibrary"):FindFirstChild("V40 (Steal a Brainrot)")
local banHammer = v40:FindFirstChild("Tools / Ban Hammer")
assert(banHammer, "Tools / Ban Hammer is missing from the VFX library")
local function effectAttachment(effectName)
	local model = banHammer:FindFirstChild(effectName)
	assert(model, effectName .. " is missing under Tools / Ban Hammer")
	local attachment = model:FindFirstChild(effectName)
	assert(attachment and attachment:IsA("Attachment"), effectName .. " has no Attachment")
	return attachment
end
collect("ToonLightning", effectAttachment("LightningStrike"))
collect("ElectricImpact", effectAttachment("Impact1"))

fs.writeFile(OUT, roblox.serializeModel({ root }))
print(OUT .. " written")
