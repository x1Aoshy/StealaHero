--!nocheck
-- tests/smoke_vfx_flipbooks.luau (owner 2026-09-27: "the egg VFX flipbooks are wrong, badly emitted; the same on the
-- villains' teleports"; "remove the ugly mesh when they step, put a nice VFX"; per-hero auras). Joins the "smoke"
-- filter. Checks, against the built place:
--   1. every ParticleEmitter drawing a V40 4x4 flipbook sheet sets a flipbook layout (else Roblox draws the whole sheet,
--      a grid of 16 tiny frames on each particle);
--   2. VillainChaseFx gives its runtime emitters the same layouts, and draws its ground rings / hover / decay as
--      particles (no Neon disc or ring part);
--   3. the per-hero auras exist (Aura_Ki / Aura_SSJ / Aura_RedStars) and SabVfxController maps Goku, Gohan, Superman,
--      Zoro, Hawks and Iron Man.

local place = H.place()

local GRID4 = {
	["8733488500"] = "Pixel Blob", ["13778464872"] = "Blurry Arc Lightning", ["123944207040840"] = "FireSpecs",
	["8733414465"] = "PinkStars", ["13448020277"] = "Pixel Star", ["11847035494"] = "Pixelated Smoke Diagonal",
	["92739826225814"] = "space", ["11858773923"] = "Pixel Explosion Smoke", ["11866495294"] = "Pixelated Smoke Puff",
	["14444570452"] = "shockwave1Ring",
}

local function textureId(emitter)
	for _, prop in ipairs({ "TextureContent", "Texture" }) do
		local ok, value = pcall(function()
			return emitter[prop]
		end)
		local id = ok and string.match(tostring(value), "(%d%d%d%d%d+)")
		if id then
			return id
		end
	end
	return nil
end

local sheets, whole = 0, {}
for _, d in ipairs(place:GetDescendants()) do
	if d:IsA("ParticleEmitter") then
		local id = textureId(d)
		if id and GRID4[id] then
			sheets += 1
			if d.FlipbookLayout == H.roblox.Enum.ParticleFlipbookLayout.None then
				table.insert(whole, d:GetFullName())
			end
		end
	end
end
T.check(sheets >= 40, "expected the egg VFX and the ported effects to draw V40 flipbook sheets, found %d emitters", sheets)
T.check(#whole == 0, "%d emitter(s) draw a flipbook sheet without a layout: %s", #whole, table.concat(whole, ", ", 1, math.min(#whole, 4)))

local scripts = place:GetService("StarterPlayer").StarterPlayerScripts
local chase = H.path(scripts, "Game/VillainChaseFx")
if T.check(chase ~= nil, "StarterPlayerScripts.Game.VillainChaseFx missing") then
	local src = chase.Source
	T.check(string.find(src, "local TP_FLIPBOOK", 1, true) ~= nil and string.find(src, "ParticleFlipbookLayout.Grid4x4", 1, true) ~= nil,
		"VillainChaseFx must set flipbook layouts on its V40 sheet emitters")
	for _, key in ipairs({ "star", "pixelStar", "puff", "space", "arc", "blob", "decay", "fire", "ring" }) do
		T.check(string.find(src, key .. " = true", 1, true) ~= nil, "VillainChaseFx TP_FLIPBOOK lacks %s", key)
	end
	T.check(string.find(src, "\"VillainFxDisc\"", 1, true) == nil and string.find(src, "\"VillainFxHoverRing\"", 1, true) == nil
		and string.find(src, "\"VillainFxDecayPatch\"", 1, true) == nil, "VillainChaseFx still builds a ground disc / ring part")
	T.check(string.find(src, "ParticleOrientation.VelocityPerpendicular", 1, true) ~= nil, "ground rings must be flat particles")
	T.check(pcall(H.luau.compile, src), "VillainChaseFx does not compile")
end

local sab = H.path(place:GetService("ReplicatedStorage"), "Assets/VFX/SAB")
if T.check(sab ~= nil, "ReplicatedStorage.Assets.VFX.SAB missing") then
	for _, name in ipairs({ "Aura_Ki", "Aura_SSJ", "Aura_RedStars" }) do
		local effect = sab:FindFirstChild(name)
		local emitters = 0
		for _, d in ipairs(effect and effect:GetDescendants() or {}) do
			if d:IsA("ParticleEmitter") then
				emitters += 1
				T.check(d.Enabled == false, "%s.%s must be stored disabled", name, d.Name)
			end
		end
		T.check(emitters > 0, "aura %s missing or empty", name)
	end
end
local sabController = H.path(scripts, "Game/SabVfxController")
if T.check(sabController ~= nil, "SabVfxController missing") then
	local src = sabController.Source
	for _, entry in ipairs({ "Goku = { effect = \"Aura_Ki\"", "Gohan = { effect = \"Aura_SSJ\"", "Superman = { effect = \"Aura_RedStars\"",
		"Zoro = { effect = \"Aura_Ki\"", "Hawks = { effect = false", "IronMan = Color3.fromRGB(70, 165, 255)" }) do
		T.check(string.find(src, entry, 1, true) ~= nil, "SabVfxController lacks the aura entry %s", entry)
	end
	T.check(pcall(H.luau.compile, src), "SabVfxController does not compile")
end
