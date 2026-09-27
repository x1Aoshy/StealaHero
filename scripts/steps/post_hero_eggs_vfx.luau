--!nocheck
-- scripts/steps/post_hero_eggs_vfx.luau
-- Owner 2026-09-27: "add some effects / VFX to the eggs ... matching the hero inside ... each egg more unique and
-- alive" and "use smooth, pretty, minimalist VFX from V40 with colours that match the eggs". Every hero egg template
-- (ReplicatedStorage.Assets.Models.Eggs.<HeroId>, built by post_hero_eggs) gets a small particle set, so every runtime
-- egg (stage nests, the carried egg, the egg tool, placed / growing eggs) wears it; ViewportFrames (portraits, the
-- secret banner) never render particles.
--
-- Textures are the V40 SAB reference effects (reference/V40 SAB by FaypleStudios.rbxl): the egg-trait aura of its own
-- eggs (Models/TraitsPerAnimal/<Colour> Egg/_Template: Glow2 halo, Rays1, pixel sparkles) plus one signature layer
-- per hero picked from its traits / mutations (lightning arcs, fire specs, frost stars, droplets, petals, pixel blobs,
-- pixel smoke, space puffs, pixel stars, cyber pixels). Colours come from scripts/data/hero_palettes.luau.
--   every egg     EggVfx attachment at the egg centre: a soft Halo (Base colour); Sparkles from the Hitbox volume
--                 (Accent / Detail colour)
--   Epic and up   + slow Rays (Base colour)
--   every egg     + its signature layer (SIGNATURES), rate by rarity
-- Minimal on purpose: 3-4 emitters an egg, low rates, sizes authored for the 1-stud template (ScaleTo scales them with
-- the egg: nests, placed eggs grown 3x). Idempotent: an existing EggVfx set is replaced.

local roblox = require("@lune/roblox")
local Palettes = require("../data/hero_palettes")

local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local ColorSequence = roblox.ColorSequence
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local NumberRange = roblox.NumberRange
local Enum = roblox.Enum
local Content = roblox.Content

local Step = {}

local LOG = "[hero_eggs_vfx]"
Step.TAG = "EggVfx" -- attribute on every emitter / attachment this step adds

-- V40 textures (ids as they are in the reference place)
Step.TEXTURES = {
	halo = "rbxassetid://130130860248081", -- TraitsPerAnimal egg Glow2
	rays = "rbxassetid://3048527478", -- TraitsPerAnimal egg Rays1
	sparkle = "rbxassetid://8733488500", -- TraitsPerAnimal egg sparkles / Pixel Blob
	arc = "rbxassetid://13778464872", -- Traits/Lightning "Blurry Arc Lightning"
	ember = "rbxassetid://123944207040840", -- Traits/Fire "FireSpecs"
	frost = "rbxassetid://88325591034213", -- Traits/Snowy "Pixel Star"
	drop = "rbxassetid://122367020211100", -- Traits/Wet "Pixel Star"
	petal = "rbxassetid://137380952595409", -- Traits/Rose "Pixel Star"
	star = "rbxassetid://8733414465", -- MutationVFX/Crystal "PinkStars"
	pixelStar = "rbxassetid://13448020277", -- Traits/Cometstruck "Pixel Star"
	smoke = "rbxassetid://11847035494", -- Traits/Fire "Pixelated Smoke Diagonal"
	space = "rbxassetid://92739826225814", -- Traits/Galactic "bluerspace"
	cyber = "rbxassetid://11858773923", -- MutationVFX/Cyber "PixelExplosion"
}

-- Textures that are 4x4 flipbook sheets in V40 (every V40 emitter using them sets FlipbookLayout Grid4x4, nearly all in
-- OneShot mode: one animation over each particle's life). Without the layout Roblox draws the whole sheet: a grid of
-- 16 tiny frames on every particle (owner 2026-09-27: "the egg VFX flipbooks are wrong / badly emitted").
Step.FLIPBOOKS = {
	sparkle = "OneShot",
	arc = "OneShot",
	ember = "OneShot",
	star = "OneShot",
	pixelStar = "OneShot",
	smoke = "OneShot",
	space = "OneShot",
	cyber = "OneShot",
}

-- signature styles: emitter recipes for a 1-stud egg (host "center" = the EggVfx attachment, "volume" = the Hitbox)
Step.STYLES = {
	spark = { tex = "arc", host = "center", life = { 0.06, 0.18 }, size = { { 0, 0.9 }, { 1, 0.9 } }, light = 1, rotation = true },
	ember = { tex = "ember", host = "volume", life = { 0.4, 0.8 }, size = { { 0, 0.12 }, { 1, 0 } }, speed = { 0.3, 0.7 }, spread = 25,
		accel = { 0, 1.2, 0 }, light = 0.6 },
	frost = { tex = "frost", host = "volume", life = { 0.6, 1.0 }, size = { { 0, 0 }, { 0.3, 0.08 }, { 1, 0 } }, speed = { 0.1, 0.3 }, spread = 180,
		accel = { 0, -0.3, 0 }, light = 1 },
	water = { tex = "drop", host = "volume", life = { 0.4, 0.7 }, size = { { 0, 0 }, { 0.5, 0.06 }, { 1, 0 } }, speed = { 0.4, 0.8 }, spread = 30,
		accel = { 0, -3, 0 }, light = 0.3 },
	petal = { tex = "petal", host = "volume", life = { 0.8, 1.2 }, size = { { 0, 0 }, { 0.3, 0.08 }, { 1, 0 } }, speed = { 0.2, 0.5 }, spread = 180,
		accel = { 0, 0.3, 0 }, light = 0.2, rotation = true },
	star = { tex = "star", host = "volume", life = { 0.5, 0.9 }, size = { { 0, 0 }, { 0.3, 0.09 }, { 1, 0 } }, speed = { 0.1, 0.4 }, spread = 180, light = 1 },
	rise = { tex = "pixelStar", host = "volume", life = { 0.5, 0.9 }, size = { { 0, 0.07 }, { 1, 0 } }, speed = { 0.4, 0.8 }, spread = 45,
		accel = { 0, 1, 0 }, light = 1 },
	smoke = { tex = "smoke", host = "volume", life = { 0.8, 1.2 }, size = { { 0, 0.15 }, { 1, 0.35 } }, speed = { 0.1, 0.3 }, spread = 180,
		accel = { 0, 0.4, 0 }, light = 0, rotation = true, transparency = { { 0, 0.5 }, { 1, 1 } } },
	space = { tex = "space", host = "center", life = { 1, 1.5 }, size = { { 0, 0.2 }, { 0.5, 0.5 }, { 1, 0 } }, speed = { 0.02, 0.05 }, spread = 180,
		light = 0.3, rotation = true },
	drip = { tex = "sparkle", host = "volume", life = { 0.5, 0.9 }, size = { { 0, 0.08 }, { 1, 0 } }, speed = { 0.1, 0.3 }, spread = 180,
		accel = { 0, -1.5, 0 }, light = 0 },
	cyber = { tex = "cyber", host = "center", life = { 1, 1.5 }, size = { { 0, 0.4 }, { 1, 0.4 } }, speed = { 0.1, 0.2 }, spread = 25, light = 0.4 },
}

-- hero -> signature style and colour (the character's power / look)
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
Step.SIGNATURES = {
	-- Stage 1 · The Avengers
	Hawkeye = { style = "star", color = rgb(176, 110, 232) },
	BlackWidow = { style = "spark", color = rgb(255, 60, 70) }, -- widow's bite
	CaptainAmerica = { style = "star", color = rgb(235, 240, 255) },
	Hulk = { style = "smoke", color = rgb(92, 220, 70) }, -- gamma
	Thor = { style = "spark", color = rgb(90, 170, 255) },
	IronMan = { style = "ember", color = rgb(255, 196, 70) }, -- repulsors
	-- Stage 2 · Justice League
	Aquaman = { style = "water", color = rgb(70, 180, 255) },
	GreenLantern = { style = "rise", color = rgb(70, 255, 110) },
	Flash = { style = "spark", color = rgb(255, 214, 40) },
	WonderWoman = { style = "star", color = rgb(255, 210, 80) },
	Batman = { style = "smoke", color = rgb(120, 120, 135) },
	Superman = { style = "rise", color = rgb(255, 216, 70) }, -- solar
	-- Stage 3 · Spider-Verse
	PeterParker = { style = "star", color = rgb(255, 80, 80) },
	SpiderGwen = { style = "petal", color = rgb(255, 120, 200) },
	MilesMorales = { style = "spark", color = rgb(255, 70, 70) }, -- venom blast
	SpiderMan2099 = { style = "cyber", color = rgb(70, 150, 255) },
	AgentVenom = { style = "drip", color = rgb(220, 225, 230) },
	Venom = { style = "drip", color = rgb(40, 36, 48) },
	-- Stage 4 · My Hero Academia
	Uraraka = { style = "petal", color = rgb(255, 150, 190) },
	Bakugo = { style = "ember", color = rgb(255, 140, 40) },
	Todoroki = { style = "frost", color = rgb(190, 230, 255) },
	Hawks = { style = "ember", color = rgb(255, 60, 60) }, -- red feathers
	Deku = { style = "spark", color = rgb(90, 255, 120) }, -- One For All
	AllMight = { style = "rise", color = rgb(255, 210, 60) },
	-- Stage 5 · Dragon Ball
	Krillin = { style = "star", color = rgb(255, 170, 70) },
	Trunks = { style = "spark", color = rgb(255, 225, 90) },
	Piccolo = { style = "rise", color = rgb(190, 120, 255) },
	Gohan = { style = "spark", color = rgb(255, 235, 120) },
	Vegeta = { style = "spark", color = rgb(90, 160, 255) },
	Goku = { style = "rise", color = rgb(255, 214, 60) }, -- Super Saiyan
	-- Stage 6 · One Piece
	Usopp = { style = "star", color = rgb(200, 220, 90) },
	Nami = { style = "spark", color = rgb(110, 190, 255) }, -- Clima-Tact
	Brook = { style = "smoke", color = rgb(200, 225, 255) }, -- soul
	Sanji = { style = "ember", color = rgb(255, 120, 40) }, -- Diable Jambe
	Zoro = { style = "rise", color = rgb(110, 230, 130) },
	Shanks = { style = "spark", color = rgb(255, 40, 50) }, -- red Haki lightning
	Luffy = { style = "star", color = rgb(255, 90, 80) },
	JoyBoy = { style = "space", color = rgb(235, 225, 255) }, -- Gear 5 clouds
}

-- emission rate multiplier of the signature layer by rarity (Common eggs stay calm, rarer eggs livelier)
Step.RARITY_RATE = { Common = 1.5, Rare = 2, Epic = 2.5, Legendary = 3, Mythic = 3.5, Secret = 4 }
Step.RAYS_RARITIES = { Epic = true, Legendary = true, Mythic = true, Secret = true }

local function log(fmt, ...)
	print(string.format("%s " .. fmt, LOG, ...))
end

local function color3(t)
	return rgb(t[1], t[2], t[3])
end

local function seq(points)
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function emitter(parent, name, spec)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.TextureContent = Content.fromUri(Step.TEXTURES[spec.tex])
	local flipbook = Step.FLIPBOOKS[spec.tex]
	if flipbook then
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		e.FlipbookMode = Enum.ParticleFlipbookMode[flipbook]
		e.FlipbookStartRandom = false
	else
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.None
	end
	e.Rate = spec.rate
	e.Lifetime = NumberRange.new(spec.life[1], spec.life[2])
	e.Size = seq(spec.size)
	e.Transparency = seq(spec.transparency or { { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } })
	local speed = spec.speed or { 0, 0 }
	e.Speed = NumberRange.new(speed[1], speed[2])
	local spread = spec.spread or 0
	e.SpreadAngle = Vector2.new(spread, spread)
	e.EmissionDirection = Enum.NormalId.Top
	local a = spec.accel or { 0, 0, 0 }
	e.Acceleration = Vector3.new(a[1], a[2], a[3])
	e.Drag = spec.drag or 0
	e.LightEmission = spec.light or 0
	e.LightInfluence = 0
	if spec.rotation then
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-30, 30)
	end
	e.Color = ColorSequence.new(spec.color)
	e.Enabled = true
	e:SetAttribute(Step.TAG, true)
	e.Parent = parent
	return e
end

local function strip(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:GetAttribute(Step.TAG) == true and d.Parent ~= nil then
			d:Destroy()
		end
	end
end

-- The particle set of one egg. Returns the number of emitters added.
function Step.Decorate(model, heroId, rarity)
	local palette = Palettes[heroId]
	local signature = Step.SIGNATURES[heroId]
	local hitbox = model.PrimaryPart or model:FindFirstChild("Hitbox")
	if not (palette and signature and hitbox and hitbox:IsA("BasePart")) then
		return 0
	end
	strip(model)
	local base = color3(palette.Base)
	local accent = color3(palette.Accent)
	local detail = color3(palette.Detail)
	-- the sparkle colour: whichever of Accent / Detail is brighter (a black band never sparkles black)
	local function lum(c)
		return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
	end
	local sparkleColor = if lum(detail) >= lum(accent) then detail else accent
	if lum(sparkleColor) < 0.25 then
		sparkleColor = sparkleColor:Lerp(rgb(255, 255, 255), 0.5)
	end

	local center = Instance.new("Attachment")
	center.Name = "EggVfx"
	center:SetAttribute(Step.TAG, true)
	center.Parent = hitbox
	local count = 0
	emitter(center, "EggVfxHalo", {
		tex = "halo", rate = 2, life = { 1, 1 }, size = { { 0, 0.85 }, { 1, 0.85 } }, light = 1,
		transparency = { { 0, 1 }, { 0.3, 0.62 }, { 1, 1 } }, color = base:Lerp(rgb(255, 255, 255), 0.15),
	})
	count += 1
	emitter(hitbox, "EggVfxSparkles", {
		tex = "sparkle", rate = 5, life = { 0.8, 1.4 }, size = { { 0, 0 }, { 0.2, 0.11 }, { 1, 0 } }, speed = { 0.2, 0.7 }, spread = 180,
		drag = 1, light = 1, color = sparkleColor:Lerp(rgb(255, 255, 255), 0.2),
	})
	count += 1
	if Step.RAYS_RARITIES[rarity] then
		emitter(center, "EggVfxRays", {
			tex = "rays", rate = 3, life = { 0.9, 1.2 }, size = { { 0, 0 }, { 1, 0.38 } }, light = 1, rotation = true,
			transparency = { { 0, 0.45 }, { 1, 1 } }, color = base:Lerp(rgb(255, 255, 255), 0.25),
		})
		count += 1
	end
	local style = Step.STYLES[signature.style]
	if style then
		local spec = table.clone(style)
		spec.rate = Step.RARITY_RATE[rarity] or 2
		spec.color = signature.color
		emitter(if style.host == "center" then center else hitbox, "EggVfxSignature", spec)
		count += 1
	end
	model:SetAttribute("EggVfxStyle", signature.style)
	return count
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local eggs = models and models:FindFirstChild("Eggs")
	if eggs == nil then
		log("ReplicatedStorage.Assets.Models.Eggs missing: no egg VFX")
		return
	end
	local decorated, emitters, missing = 0, 0, {}
	for _, model in ipairs(eggs:GetChildren()) do
		local heroId = model:GetAttribute("HeroId")
		if model:IsA("Model") and model:GetAttribute("HeroEgg") == true and type(heroId) == "string" then
			local n = Step.Decorate(model, heroId, model:GetAttribute("Rarity"))
			if n > 0 then
				decorated += 1
				emitters += n
			else
				table.insert(missing, heroId)
			end
		end
	end
	table.sort(missing)
	log("%d hero eggs wear their VFX (%d emitters, V40 textures, palette colours)%s", decorated, emitters,
		if #missing > 0 then "; no palette / signature: " .. table.concat(missing, ", ") else "")
end

return Step
