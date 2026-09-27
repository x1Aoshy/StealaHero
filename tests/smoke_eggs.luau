--!nocheck
-- Smoke checks for the voxel Hero Eggs (scripts/steps/post_hero_eggs.luau) and the secret hero spawn broadcast
-- (Controllers.AreaEggService.announceSecretSpawn -> GUI.SecretHeroAnnouncer). Runs with the "smoke" filter.

local PLAN = H.PLAN
local Enum = H.roblox.Enum
local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

-- 1. every roster hero renders its own voxel costume egg (the template EggRenderer clones), boss eggs kept aside
local eggs = H.path(rs, "Assets/Models/Eggs")
local notVoxel = {}
for _, hero in ipairs(PLAN.HEROES) do
	local egg = eggs and eggs:FindFirstChild(hero[1])
	local primary = egg and egg.PrimaryPart
	if not (egg and egg:GetAttribute("VoxelEgg") == true and primary and primary.Name == "Hitbox"
		and (egg:GetAttribute("PartCount") or 0) >= 30) then
		table.insert(notVoxel, hero[1])
	end
end
T.check(#notVoxel == 0, "roster eggs that are not voxel costume eggs with a Hitbox: %s", table.concat(notVoxel, ", ", 1, math.min(#notVoxel, 6)))
local bossEggs = H.path(rs, "Assets/Models/BossEggs")
T.check(bossEggs ~= nil and #bossEggs:GetChildren() == 6, "Assets.Models.BossEggs must hold the 6 boss costume eggs")
local variant = false
for _, d in ipairs(place:GetService("MaterialService"):GetChildren()) do
	variant = variant or (d:IsA("MaterialVariant") and d.Name == "HeroEggStud" and d.BaseMaterial == Enum.Material.SmoothPlastic)
end
T.check(variant, "MaterialService.HeroEggStud (the eggs' stud finish) missing")
local luffy = eggs and eggs:FindFirstChild("Luffy")
if luffy and luffy.PrimaryPart then
	local loose = 0
	for _, d in ipairs(luffy:GetDescendants()) do
		if d:IsA("BasePart") and d ~= luffy.PrimaryPart then
			local welded = false
			for _, w in ipairs(d:GetChildren()) do
				welded = welded or (w:IsA("WeldConstraint") and w.Part0 == luffy.PrimaryPart and w.Part1 == d)
			end
			loose += if welded and d:GetAttribute("DontModify") == true and not d.CanCollide then 0 else 1
		end
	end
	T.check(loose == 0, "Eggs.Luffy: %d parts not welded to the Hitbox / not DontModify / collidable", loose)
end
local paint = H.fs.readFile("scripts/steps/post_egg_colors.luau")
T.check(H.has(paint, "GetAttribute(\"VoxelEgg\") == true"), "post_egg_colors must never repaint a voxel costume egg")

-- 2. secret hero spawn broadcast: server fires it from SpawnIntoNest for Secret+ eggs, the client shows chat + banner
local areaEggs = H.path(sss, "Controllers/AreaEggService")
local src = areaEggs and areaEggs.Source or ""
T.check(H.has(src, "\"Eggs: SecretHeroSpawned\"") and H.has(src, "SECRET_ANNOUNCE_MIN_RARITY_NUMBER = 8"),
	"AreaEggService must create Network['Eggs: SecretHeroSpawned'] and announce RarityNumber >= 8 (Secret)")
local spawnBody = H.extractFunction and H.extractFunction(src, "AreaEggService.SpawnIntoNest") or src
T.check(H.has(spawnBody or src, "announceSecretSpawn(record)"), "SpawnIntoNest must announce secret spawns (announceSecretSpawn(record))")
T.check(H.has(src, "HAS SPAWNED IN %s!"), "the broadcast message must read 'A SECRET HERO, <HERO> HAS SPAWNED IN <STAGE>!'")
local announcer = sps and H.path(sps, "GUI/SecretHeroAnnouncer")
if T.check(announcer ~= nil and announcer:IsA("LocalScript"), "StarterPlayerScripts.GUI.SecretHeroAnnouncer missing") then
	local a = announcer.Source
	T.check(pcall(H.luau.compile, a), "SecretHeroAnnouncer must compile")
	T.check(H.has(a, "[SERVER]") and H.has(a, "#00FFCC") and H.has(a, "DisplaySystemMessage"),
		"SecretHeroAnnouncer must post the cyan [SERVER] line through TextChatService")
	T.check(H.has(a, "BANNER_SECONDS = 6") and H.has(a, "Audio.Play"), "SecretHeroAnnouncer must show a 6 s banner with a fanfare")
end
local catalog = H.fs.readFile("src/ReplicatedStorage/Directory/HeroCatalog.luau")
T.check(string.find(catalog, "Id = \"JoyBoy\"[^\n]-Rarity = \"Secret\"") ~= nil, "HeroCatalog: JoyBoy must stay the Secret hero")
