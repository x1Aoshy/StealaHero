--!nocheck
-- scripts/steps/post_hero_auras.luau (owner 2026-09-27)
-- Per-hero aura effects, added next to the rarity auras in ReplicatedStorage.Assets.VFX.SAB (scripts/steps/vfx.luau)
-- so StarterPlayerScripts.Game.SabVfxController copies them like any other aura (children -> the hero's root, every
-- emitter stored Enabled = false, sized for a 5-stud character and scaled by the hero's rendered Scale):
--   Aura_Ki        the owner's "Goku - SSJ2 Aura" model (vendor/goku_ssj2_aura.rbxm, sent 2026-09-27): its flame
--                  aura flipbook (OriginalAura2x2, Grid2x2) on an attachment 0.6 above the root. Goku wears it white
--                  (a ki aura; the client recolours it).
--   Aura_SSJ       the same flame plus the model's Super Saiyan 2 sparks (Images/0003, Grid8x8) at the head, an arm
--                  and both feet. Gohan wears it as sent.
--   Aura_RedStars  small red twinkling stars around the body (V40 "PinkStars" and "Pixel Blob" flipbooks,
--                  Grid4x4 OneShot). Superman.
--   Aura_Blades    Zoro (owner 2026-09-27: "Zoro has Goku's VFX, give him a fitting one"): a swordsman's aura instead of a
--                  ki flame. Green-white sword slashes flash around the body (the "Slash22" flipbook of the Speedsters
--                  Cursed Energy kit, Grid4x4 OneShot), a dark green wind crescent spins flat at his feet (its "Smokey
--                  Crescent", a Tatsumaki swirl) and a few green specks drift up. Textures from
--                  assets/vfx_library/VfxLibrary.rbxl.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Instance = roblox.Instance
local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3
local Vector2 = roblox.Vector2
local Color3 = roblox.Color3
local ColorSequence = roblox.ColorSequence
local NumberRange = roblox.NumberRange
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local Content = roblox.Content
local Enum = roblox.Enum

local Step = {}

Step.AURA_MODEL = "vendor/goku_ssj2_aura.rbxm"
Step.SPARK_POINTS = {
	SparkHead = Vector3.new(0, 1.7, 0),
	SparkArm = Vector3.new(1.4, 0.2, 0),
	SparkFootL = Vector3.new(-0.5, -2.2, 0),
	SparkFootR = Vector3.new(0.5, -2.2, 0),
}

local function host(folder, name, purpose)
	local existing = folder:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(2, 2, 1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part:SetAttribute("SabKind", "Aura")
	part:SetAttribute("SabPurpose", purpose)
	part.Parent = folder
	return part
end

local function attachment(parent, name, position)
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = CFrame.new(position)
	a.Parent = parent
	return a
end

local function seq(points)
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function stored(emitter, parent)
	local clone = emitter:Clone()
	clone.Enabled = false
	clone.Parent = parent
	return clone
end

local function star(parent, name, texture, color, rate, size)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.TextureContent = Content.fromUri(texture)
	e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Speed = NumberRange.new(0.4, 1.4)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 1.5
	e.Acceleration = Vector3.new(0, 0.6, 0)
	e.Size = seq({ { 0, 0 }, { 0.25, size }, { 1, 0 } })
	e.Transparency = seq({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } })
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-40, 40)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Brightness = 2
	e.Color = ColorSequence.new(color)
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Enabled = false
	e.Parent = parent
	return e
end

-- Zoro's swordsman aura (see the header): slashes around the body, a spinning wind crescent under the feet, specks.
Step.BLADE_TEXTURES = {
	slash = "rbxassetid://121148164489745", -- Speedsters CursedEnergy "Slash22" (Grid4x4)
	crescent = "rbxassetid://17085222506", -- Speedsters CursedEnergy "Smokey Crescent" (Grid4x4)
	speck = "rbxassetid://136781994057492", -- Speedsters CursedEnergy "cat spec 3"
}
local function blades(folder)
	local part = host(folder, "Aura_Blades", "Zoro: sword slashes + wind crescent")
	local slash = Instance.new("ParticleEmitter")
	slash.Name = "BladeSlashes"
	slash.TextureContent = Content.fromUri(Step.BLADE_TEXTURES.slash)
	slash.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	slash.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	slash.Rate = 2.4
	slash.Lifetime = NumberRange.new(0.32, 0.45)
	slash.Speed = NumberRange.new(0, 0)
	slash.Size = seq({ { 0, 3.1 }, { 1, 3.9 } })
	slash.Transparency = seq({ { 0, 0.05 }, { 0.7, 0.15 }, { 1, 1 } })
	slash.Rotation = NumberRange.new(-180, 180)
	slash.LightEmission = 1
	slash.LightInfluence = 0
	slash.Brightness = 2.2
	slash.ZOffset = 0.6
	slash.Color = ColorSequence.new(Color3.fromRGB(225, 255, 230), Color3.fromRGB(70, 235, 120))
	slash.Shape = Enum.ParticleEmitterShape.Box
	slash.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	slash.LockedToPart = true
	slash.Enabled = false
	slash.Parent = part

	local feet = attachment(part, "BladeWindAttachment", Vector3.new(0, -2.4, 0))
	local crescent = Instance.new("ParticleEmitter")
	crescent.Name = "BladeWind"
	crescent.TextureContent = Content.fromUri(Step.BLADE_TEXTURES.crescent)
	crescent.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	crescent.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	crescent.Rate = 1.3
	crescent.Lifetime = NumberRange.new(0.8, 1.1)
	crescent.Speed = NumberRange.new(0.01, 0.01)
	crescent.EmissionDirection = Enum.NormalId.Top
	crescent.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	crescent.Size = seq({ { 0, 3.6 }, { 1, 5.6 } })
	crescent.Transparency = seq({ { 0, 0.25 }, { 0.6, 0.35 }, { 1, 1 } })
	crescent.Rotation = NumberRange.new(0, 360)
	crescent.RotSpeed = NumberRange.new(140, 220)
	crescent.LightEmission = 0.7
	crescent.LightInfluence = 0
	crescent.Brightness = 1.6
	crescent.Color = ColorSequence.new(Color3.fromRGB(30, 130, 65), Color3.fromRGB(110, 255, 150))
	crescent.LockedToPart = true
	crescent.Enabled = false
	crescent.Parent = feet

	local speck = Instance.new("ParticleEmitter")
	speck.Name = "BladeSpecks"
	speck.TextureContent = Content.fromUri(Step.BLADE_TEXTURES.speck)
	speck.Rate = 5
	speck.Lifetime = NumberRange.new(0.8, 1.4)
	speck.Speed = NumberRange.new(1.2, 2.6)
	speck.EmissionDirection = Enum.NormalId.Top
	speck.SpreadAngle = Vector2.new(25, 25)
	speck.Drag = 0.8
	speck.Size = seq({ { 0, 0 }, { 0.2, 0.28 }, { 1, 0 } })
	speck.Transparency = seq({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } })
	speck.LightEmission = 1
	speck.LightInfluence = 0
	speck.Brightness = 2
	speck.Color = ColorSequence.new(Color3.fromRGB(150, 255, 170))
	speck.Shape = Enum.ParticleEmitterShape.Box
	speck.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	speck.Enabled = false
	speck.Parent = part
	return part
end
Step._blades = blades

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	local vfx = assets and assets:FindFirstChild("VFX")
	local folder = vfx and vfx:FindFirstChild("SAB")
	if folder == nil then
		print("[post_hero_auras] WARN ReplicatedStorage.Assets.VFX.SAB missing; no per-hero auras")
		return
	end
	local flame, spark
	if fs.isFile(Step.AURA_MODEL) then
		for _, root in ipairs(roblox.deserializeModel(fs.readFile(Step.AURA_MODEL))) do
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("ParticleEmitter") then
					if string.find(d.Name, "OriginalAura", 1, true) then
						flame = flame or d
					elseif string.find(d.Name, "0003", 1, true) then
						spark = spark or d
					end
				end
			end
		end
	end
	local made = {}
	if flame then
		local ki = host(folder, "Aura_Ki", "Goku (white): ki flame aura")
		stored(flame, attachment(ki, "AuraAttachment", Vector3.new(0, 0.6, 0)))
		table.insert(made, "Aura_Ki")
		local ssj = host(folder, "Aura_SSJ", "Gohan: Super Saiyan 2 flame + sparks")
		stored(flame, attachment(ssj, "AuraAttachment", Vector3.new(0, 0.6, 0)))
		if spark then
			for name, position in pairs(Step.SPARK_POINTS) do
				stored(spark, attachment(ssj, name, position))
			end
		end
		table.insert(made, "Aura_SSJ")
	else
		print("[post_hero_auras] WARN " .. Step.AURA_MODEL .. " missing or without its flame emitter; no ki / SSJ aura")
	end
	local stars = host(folder, "Aura_RedStars", "Superman: red twinkling stars")
	star(stars, "RedStars", "rbxassetid://8733414465", Color3.fromRGB(255, 45, 55), 7, 0.45)
	star(stars, "RedGlints", "rbxassetid://8733488500", Color3.fromRGB(255, 120, 110), 4, 0.3)
	table.insert(made, "Aura_RedStars")
	blades(folder)
	table.insert(made, "Aura_Blades")
	print("[post_hero_auras] per-hero auras: " .. table.concat(made, ", "))
end

return Step
