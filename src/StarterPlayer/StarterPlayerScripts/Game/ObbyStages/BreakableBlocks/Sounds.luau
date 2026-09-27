-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcBUNsb25lDVBsYXliYWNrU3BlZWQGUGFyZW50BFBsYXkKVGltZUxlbmd0aAdBZGRJdGVtBV9wbGF5CVBsYXlDcmFjawtQbGF5U2hhdHRlcgpQbGF5RnJlZXplCFBsYXlUaGF3BGdhbWUGRGVicmlzCkdldFNlcnZpY2UMU291bmRTZXJ2aWNlCEluc3RhbmNlA25ldwVTb3VuZBtyYnhhc3NldGlkOi8vODQxNTU3Njg5MDk1MTQHU291bmRJZAZWb2x1bWUNQ3JhY2tUZW1wbGF0ZQROYW1lG3JieGFzc2V0aWQ6Ly84OTk5ODI2OTgwMzAzNg9TaGF0dGVyVGVtcGxhdGUbcmJ4YXNzZXRpZDovLzkxMzY3MzM4NzYwMzE3CUZyZWV6ZVNGWAdUaGF3U0ZYAAYIAgIAAAcEAAAFAgeCFbwCADoAAAAAnwICAg4BAgAwAQIoAQAAAPsDAAAwAwIkAgAAALwDAu4DAAAAnwMCAfsDAQBSBQIATQcC1gUAAACVBgcEvAMDeAYAAACfAwQBggICAAcDAQMCAwMDBAKamZmZmZm5PwMFAwYAJAcBGAAAAAEBAAMAAAEAAAEAAAAAAAAAAiUAAAAABAECAAAGAwAABQECB/sBAABNAQGJAAAAAPsCAQBSAwAAnwEDAIIBAAABAwcANQgBGAAAAAAAAAA2AAAAAAQBAgAABgMAAAUBAgf7AQAATQEBiQAAAAD7AgEAUgMAAJ8BAwCCAQAAAQMHADkJARgAAAAAAAAAOgAAAAADAAIAAAAH+wAAAE0AAIkAAAAA+wEBAMYCAACfAAMAggAAAAEDBwA9CgEYAAAAAAAAAD4AAAAAAwACAAAAB/sAAABNAACJAAAAAPsBAQDGAgAAnwADAIIAAAABAwcAQQsBGAAAAAAAAABCAAAAAAgAAAECAGCjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIHAAAYUIBvAwgAnwICAm8DCQAwAwJ8CgAAAG8DCwAwAwJLDAAAAG8DDQAwAwK6DgAAAKQDBwAAGFCAbwQIAJ8DAgJvBA8AMAQDfAoAAABvBAsAMAQDSwwAAABvBBAAMAQDug4AAACkBAcAABhQgG8FCACfBAICbwURADAFBHwKAAAAbwUSADAFBEsMAAAAbwUTADAFBLoOAAAApAUHAAAYUIBvBggAnwUCAm8GEQAwBgV8CgAAAG8GFAAwBgVLDAAAAG8GFQAwBgUoFgAAAG8GFwAwBgW6DgAAAP8GBAAAAAAAwAcYABIAAQASAAAAMAcGiRkAAADABxoAEgAGABIAAgAwBwYqGwAAAMAHHAASAAYAEgADADAHBsUdAAAAwAceABIABgASAAQAMAcGYB8AAADAByAAEgAGABIABQAwBwYPIQAAAIIGAgAiAwwEAAAAQAMNAw4DDwMQAxEEABhQgAMSAxMDFAKamZmZmZmpPwMVAxYDFwMYAxkDGgIAAAAAAAD4PwMbAjMzMzMzM+M/AmZmZmZmZuY/AwIDHAYAAwcGAQMIBgIDCQYDAwoGBAMLBQABAgMEAQABGAADAAAAAAABAAAAAAADAAAAAQAAAQAAAQAAAgAAAAEAAAEAAAEAAAIAAAABAAABAAABAAACAAAAAQAAAQAAAQAAAQAAAwAGAAAAABEAAAAABAAAAAAEAAAAAAQAAAAABAEAAAAABeb3Pl3Qp4Qoj/7Fq7LqI/aW7ykp1DNUXA==

-- decompilation:
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Speedsters audio: only whitelisted ids are ever requested (Library.Audio.ResolveSoundUri); others stay silent.
-- Required lazily so this module never joins a require cycle with Library.Audio.
local SpeedstersAudio = nil

local function resolveSoundUri(soundId): string?
	if SpeedstersAudio == nil then
		local ok, result = pcall(require, ReplicatedStorage.Library.Audio)
		SpeedstersAudio = if ok and type(result) == "table" and type(result.ResolveSoundUri) == "function" then result else false
	end

	return if SpeedstersAudio then SpeedstersAudio.ResolveSoundUri(soundId) else nil
end

local Sound = Instance.new("Sound")

Sound.SoundId = resolveSoundUri("rbxassetid://84155768909514") or ""
Sound.Volume = 0.05
Sound.Name = "CrackTemplate"

local Sound2 = Instance.new("Sound")

Sound2.SoundId = resolveSoundUri("rbxassetid://89998269803036") or ""
Sound2.Volume = 0.05
Sound2.Name = "ShatterTemplate"

local Sound3 = Instance.new("Sound")

Sound3.SoundId = resolveSoundUri("rbxassetid://91367338760317") or ""
Sound3.Volume = 1.5
Sound3.Name = "FreezeSFX"

local Sound4 = Instance.new("Sound")

Sound4.SoundId = resolveSoundUri("rbxassetid://91367338760317") or ""
Sound4.Volume = 0.6
Sound4.PlaybackSpeed = 0.7
Sound4.Name = "ThawSFX"

local t1 = {
	_play = function(p1, n1: number?) -- line: 36
		-- upvalues: SoundService (copy), Debris (copy)
		local clone = p1:Clone()

		if n1 then
			clone.PlaybackSpeed = n1
		end

		clone.Parent = SoundService
		clone:Play()
		Debris:AddItem(clone, clone.TimeLength + 0.1)

		return clone
	end
}

function t1.PlayCrack(n2: number) -- line: 53
	-- upvalues: t1 (copy), Sound (copy)
	return t1._play(Sound, n2)
end
function t1.PlayShatter(n3: number) -- line: 57
	-- upvalues: t1 (copy), Sound2 (copy)
	return t1._play(Sound2, n3)
end
function t1.PlayFreeze() -- line: 61
	-- upvalues: t1 (copy), Sound3 (copy)
	return t1._play(Sound3, nil)
end
function t1.PlayThaw() -- line: 65
	-- upvalues: t1 (copy), Sound4 (copy)
	return t1._play(Sound4, nil)
end

return t1

