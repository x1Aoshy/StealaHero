-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw
-- Decompiled from the base place (Steal An Egg with treadmill V2.rbxl); injected by scripts/inject/uiaudio.luau.
--
-- Speedsters audio patch: the music id goes through Library.Audio.ResolveSoundId (Speedsters whitelist +
-- remap). A rejected or unparseable id yields a silent Sound (SoundId "") instead of an assert, so
-- MusicController keeps working without ever requesting a non-whitelisted (403) asset.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ParseAssetId = require(ReplicatedStorage.Library.Functions.ParseAssetId)

-- Library.Audio is required lazily: it is this module's parent and loads client-only dependencies.
local resolveSoundId = nil

local function resolveMusicId(id: number): number?
	if resolveSoundId == nil then
		local ok, Audio = pcall(require, script.Parent)
		if ok and type(Audio) == "table" and type(Audio.ResolveSoundId) == "function" then
			resolveSoundId = Audio.ResolveSoundId
		else
			resolveSoundId = false
		end
	end

	if not resolveSoundId then
		return nil
	end

	local ok, resolved = pcall(resolveSoundId, id)

	return if ok then resolved else nil
end

return function(s1: string, p1, b1: boolean) -- line: 20
	local v7 = p1

	if type(p1) == "string" then
		local ok, parsed = pcall(ParseAssetId, p1)

		v7 = if ok then parsed else nil
	end

	local resolvedId = if type(v7) == "number" and v7 > 0.0 then resolveMusicId(v7) else nil
	local Music = script.Parent:FindFirstChild("Music")
	local MusicGroup = SoundService:FindFirstChild("Music")
	local GameMusic = MusicGroup and MusicGroup:FindFirstChild("GameMusic")
	local Sound = Instance.new("Sound")

	Sound.Name = s1
	Sound.SoundId = if resolvedId then ("rbxassetid://%d"):format(resolvedId) else ""
	Sound.Volume = 0.0
	Sound.Looped = b1 == true

	if GameMusic and GameMusic:IsA("SoundGroup") then
		Sound.SoundGroup = GameMusic
	end

	Sound.Parent = Music or script.Parent

	return Sound
end
