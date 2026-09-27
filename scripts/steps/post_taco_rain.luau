--!nocheck
-- scripts/steps/post_taco_rain.luau (owner 2026-09-27: "migrate the taco event (without the treadmill) to the admin panel:
-- a rain of tacos, a chance a taco falls on an egg in your base or on the stages, which multiplies that egg x3, with the
-- taco explosion VFX, the taco particle emitter and the taco music")
-- Publishes what the Taco Rain needs (the event itself: ServerScriptService.BranchServices.TacoRainService, started from
-- the admin panel; its client: StarterPlayerScripts.BranchControllers.TacoRainController):
--   1. vendor/taco_rain.rbxm (scripts/tools/vendor_taco_rain.luau, Steal a Brainrot's Raining Tacos event) ->
--      ReplicatedStorage.Assets.VFX.TacoRain.{Taco, StruckVFX, TacoAmbient}: the falling taco, the taco explosion and the
--      sky of tacos. Every emitter is left disabled in storage (the client enables / emits its copies).
--   2. ReplicatedStorage.Mutation_FX.Taco: the Taco mutation's particles (Library.Modules.Mutations "Taco" puts them on a
--      hero's FX part, Library.Client.Eggs.EggRenderer on a taco'd egg), derived from TacoAmbient's own taco emitter and
--      yellow flakes: a few tacos and crumbs popping off the egg / hero. Tagged EggVfx (PerfController halves them on
--      phones).
--   3. SoundService.TacoRainMusic: the ONE Sound of the event music, looped, silent until the client fades it in, routed
--      through SoundService.Music.AdminAbuseMusic (the Music setting mutes it). Its id is set by scripts/steps/audio.luau
--      after the build's final sound sanitize (owner request 2026-09-27, the only id outside the Speedsters set).
--   4. ReplicatedStorage.Network["TacoRain: Event"]: server -> client broadcasts (Drop / Hit / Miss / Stop).

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local NumberRange = roblox.NumberRange
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local Enum = roblox.Enum

local Step = {}

Step.VENDOR = "vendor/taco_rain.rbxm"
Step.FOLDER = "TacoRain"
Step.ASSETS = { "Taco", "StruckVFX", "TacoAmbient" }
Step.MUTATION = "Taco"
Step.MUSIC = "TacoRainMusic"
Step.MUSIC_GROUP = { "Music", "AdminAbuseMusic" }
Step.REMOTE = "TacoRain: Event"
Step.TACO_TEXTURE = "84855954319870" -- TacoAmbient's taco sprite
Step.FLAKE_TEXTURE = "13802408466" -- TacoAmbient's yellow flakes

local function log(fmt, ...)
	print(string.format("[post_taco_rain] " .. fmt, ...))
end

local function folder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and not existing:IsA("Folder") then
		existing:Destroy()
		existing = nil
	end
	if existing == nil then
		existing = Instance.new("Folder")
		existing.Name = name
		existing.Parent = parent
	end
	return existing
end

local function textureOf(emitter)
	local ok, content = pcall(function()
		return emitter.TextureContent
	end)
	return ok and content and string.match(tostring(content.Uri or ""), "(%d+)$") or nil
end

-- The first emitter under `root` whose texture id is `id` (and whose flipbook is `flipbook` when given).
local function emitterWith(root, id, flipbook)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("ParticleEmitter") and textureOf(d) == id and (flipbook == nil or d.FlipbookLayout == flipbook) then
			return d
		end
	end
	return nil
end

local function seq(points)
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

-- 2. the mutation's particles, re-tuned from the sky emitters for a small egg / hero: a slow pop upwards that falls back
function Step.MutationParticles(ambient)
	local taco = emitterWith(ambient, Step.TACO_TEXTURE, Enum.ParticleFlipbookLayout.None) or emitterWith(ambient, Step.TACO_TEXTURE)
	local flakes = emitterWith(ambient, Step.FLAKE_TEXTURE)
	assert(taco and flakes, "TacoAmbient must hold its taco and flake emitters")
	local list = {}

	local tacos = taco:Clone()
	tacos.Name = "TacoPops"
	tacos.Enabled = true
	tacos.Rate = 2.5
	tacos.Speed = NumberRange.new(4, 7)
	tacos.SpreadAngle = Vector2.new(40, 40)
	tacos.EmissionDirection = Enum.NormalId.Top
	tacos.Acceleration = Vector3.new(0, -14, 0)
	tacos.Lifetime = NumberRange.new(0.9, 1.4)
	tacos.Size = seq({ { 0, 0 }, { 0.15, 0.85 }, { 0.8, 0.85 }, { 1, 0 } })
	tacos.Transparency = seq({ { 0, 0 }, { 0.8, 0 }, { 1, 1 } })
	tacos.Orientation = Enum.ParticleOrientation.FacingCamera
	tacos.Rotation = NumberRange.new(-180, 180)
	tacos.RotSpeed = NumberRange.new(-140, 140)
	tacos.LightInfluence = 0
	tacos.Brightness = 1.2
	tacos.LockedToPart = false
	tacos.ZOffset = 0.5
	tacos:SetAttribute("EggVfx", true)
	table.insert(list, tacos)

	local crumbs = flakes:Clone()
	crumbs.Name = "TacoCrumbs"
	crumbs.Enabled = true
	crumbs.Rate = 7
	crumbs.Speed = NumberRange.new(2, 5)
	crumbs.SpreadAngle = Vector2.new(70, 70)
	crumbs.EmissionDirection = Enum.NormalId.Top
	crumbs.Acceleration = Vector3.new(0, -6, 0)
	crumbs.Lifetime = NumberRange.new(0.7, 1.1)
	crumbs.Size = seq({ { 0, 0 }, { 0.2, 0.28 }, { 0.8, 0.28 }, { 1, 0 } })
	crumbs.LightInfluence = 0
	crumbs.LockedToPart = false
	crumbs:SetAttribute("EggVfx", true)
	table.insert(list, crumbs)
	return list
end

function Step.Apply(place, _spPlace, _ctx)
	assert(fs.isFile(Step.VENDOR), Step.VENDOR .. " missing (lune run scripts/tools/vendor_taco_rain.luau)")
	local rs = place:GetService("ReplicatedStorage")
	local source = roblox.deserializeModel(fs.readFile(Step.VENDOR))[1]
	assert(source and source.Name == Step.FOLDER, Step.VENDOR .. " must hold the TacoRain folder")

	-- 1. the event assets
	local assets = rs:FindFirstChild("Assets")
	assert(assets ~= nil, "ReplicatedStorage.Assets missing")
	local vfx = folder(assets, "VFX")
	local old = vfx:FindFirstChild(Step.FOLDER)
	if old then
		old:Destroy()
	end
	local published = Instance.new("Folder")
	published.Name = Step.FOLDER
	local emitters = 0
	for _, name in ipairs(Step.ASSETS) do
		local asset = source:FindFirstChild(name)
		assert(asset and asset:IsA("BasePart"), Step.VENDOR .. ": " .. name .. " missing")
		local copy = asset:Clone() -- the whole subtree (the taco's Trail keeps its attachments)
		for _, d in ipairs(copy:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				d:SetAttribute("TacoRainRate", d.Rate) -- the authored rate: the client scales from it
				d.Enabled = false
				emitters += 1
			elseif d:IsA("Sound") or d:IsA("LuaSourceContainer") then
				d:Destroy()
			end
		end
		copy.Anchored = true
		copy.CanCollide = false
		copy.CanQuery = false
		copy.CanTouch = false
		copy.Parent = published
	end
	published.Parent = vfx

	-- 2. the mutation's particles
	local mutationFx = rs:FindFirstChild("Mutation_FX")
	if mutationFx == nil then
		mutationFx = Instance.new("Folder")
		mutationFx.Name = "Mutation_FX"
		mutationFx.Parent = rs
	end
	local taco = mutationFx:FindFirstChild(Step.MUTATION)
	if taco then
		taco:Destroy()
	end
	taco = Instance.new("Folder")
	taco.Name = Step.MUTATION
	for _, emitter in ipairs(Step.MutationParticles(source.TacoAmbient)) do
		emitter.Parent = taco
	end
	taco.Parent = mutationFx

	-- 3. the music Sound (its id: scripts/steps/audio.luau)
	local soundService = place:GetService("SoundService")
	local music = soundService:FindFirstChild(Step.MUSIC)
	if music and not music:IsA("Sound") then
		music:Destroy()
		music = nil
	end
	if music == nil then
		music = Instance.new("Sound")
		music.Name = Step.MUSIC
		music.Parent = soundService
	end
	music.Looped = true
	music.Volume = 0
	music.Playing = false
	local group = soundService
	for _, name in ipairs(Step.MUSIC_GROUP) do
		group = group and group:FindFirstChild(name)
	end
	if group and group:IsA("SoundGroup") then
		music.SoundGroup = group
	end

	-- 4. the broadcast remote
	local network = folder(rs, "Network")
	local remote = network:FindFirstChild(Step.REMOTE)
	if remote and not remote:IsA("RemoteEvent") then
		remote:Destroy()
		remote = nil
	end
	if remote == nil then
		remote = Instance.new("RemoteEvent")
		remote.Name = Step.REMOTE
		remote.Parent = network
	end

	log("ReplicatedStorage.Assets.VFX.%s (%s, %d emitters), Mutation_FX.%s (%d emitters), SoundService.%s (%s), Network[%q]",
		Step.FOLDER, table.concat(Step.ASSETS, ", "), emitters, Step.MUTATION, #taco:GetChildren(), Step.MUSIC,
		if group then group:GetFullName() else "no group", Step.REMOTE)
end

return Step
