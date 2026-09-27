-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBlZvbHVtZQhhcHBseVNmeAphcHBseU11c2ljCUlzRW5hYmxlZANTRlgFTXVzaWMIYXBwbHlBbGwEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlDFNvdW5kU2VydmljZQdMaWJyYXJ5DFdhaXRGb3JDaGlsZAZDbGllbnQHcmVxdWlyZQxTZXR0aW5nc0NtZHMHRGVmYXVsdA1EZWZhdWx0UmV2ZXJiB0NoYW5nZWQHQ29ubmVjdAAFAwEEAAAGAwAABQEBD/sBAAAOAAIA+wIBACsCAQCMAgAAMAIBSwAAAAD7AQIADgACAPsCAwArAgEAjAIAADACAUsAAAAAggABAAEDAQAWAgEYAAAAAAAAAAEAAAAAAAABFwAAAAADAQIAAAYDAAAFAQEI+wEAAA4AAgD7AgEAKwIBAIwCAAAwAgFLAAAAAIIAAQABAwEAGwMBGAAAAAAAAAABHAAAAAADAAcAAAAg+wAAAE0AABwAAAAAbwEBAJ8AAgL7AQEADgACAPsCAgArAgEAjAIAADACAUsCAAAA+wEDAA4AAgD7AgQAKwIBAIwCAAAwAgFLAgAAAPsAAABNAAAcAAAAAG8BAwCfAAIC+wEFAA4AAgD7AgYAKwIBAIwCAAAwAgFLAgAAAIIAAQAEAwQDBQMBAwYAHwcBGAkAAAAA9wAAAAAAAAEAAAAAAAAJAAAAAPsAAAAAAAAGFwAAAAAFAgYAAAcEAAAFAgMBI/AAFAAAAACAKgECAAAAAICpAgABqQIBAPsDAAAOAgIA+wQBACsEAQCMBAAAMAQDSwEAAAD7AwIADgICAPsEAwArBAEAjAQAADAEA0sBAAAAggABAPAADAACAACAKgECAAAAAICpAgABqQIBAPsDBAAOAgIA+wQFACsEAQCMBAAAMAQDSwEAAACCAAEAAwMFAwEDBgAlAAEYDwABAAAA8AAAAAAAAAEAAAAAAAAQAwABAAAA8AAAAAAAABIXAAAAABEAAAECAGOjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCbwQFALwCANMGAAAAnwIDAm8FBwC8AwLTBgAAAJ8DAwKkBAkAAACAQE0FAxQKAAAAnwQCAm8HCwC8BQHTBgAAAJ8FAwJvCAwAvAYB0wYAAACfBgMCbwkNALwHAdMGAAAAnwcDAk0IBUsOAAAATQkGSw4AAABNCgdLDgAAAMALDwASAAUAEgAIABIABgASAAkAwAwQABIABwASAAoAwA0RABIABAASAAUAEgAIABIABgASAAkAEgAHABIACgBNDgSFEgAAAMAQEwASAAUAEgAIABIABgASAAkAEgAHABIACgC8Dg7HFAAAAJ8OAwFNDgQcFQAAAG8PFgCfDgICDg4CAFIPCAArDwEAjA8AADAPBUsOAAAADg4CAFIPCQArDwEAjA8AADAPBksOAAAATQ4EHBUAAABvDw0Anw4CAg4OAgBSDwoAKw8BAIwPAAAwDwdLDgAAAIIAAQAXAwgEAAAAQAMJAwoDCwMMAw0DDgMPBAAAgEADEAMRAxIDBgMBBgAGAQYCAxMGAwMUAwQDBQQAAQIDAQABGAADAAAAAAABAAAAAAADAAAAAQAAAAIAAAAAAwAAAAEAAAABAAAAAgABAAEAAgAAAAAFAAAEAAAAAAAAAAYAAAAAAAAAAAAAAPsAAAD3AAAAAAABAAAAAAAJAAAA+wAAAAAAFQEAAAAABJbuG9DFZOlWnY91u2SBbd/m9gykpCpx0Q==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Client = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Client")
local SettingsCmds = require(Client.SettingsCmds)
local Default = SoundService:WaitForChild("Default")
local DefaultReverb = SoundService:WaitForChild("DefaultReverb")
local Music = SoundService:WaitForChild("Music")
local DefaultVolume = Default.Volume
local DefaultReverbVolume = DefaultReverb.Volume
local MusicVolume = Music.Volume

local function applySfx(b1: boolean) -- line: 22
	-- upvalues: Default (copy), DefaultVolume (copy), DefaultReverb (copy), DefaultReverbVolume (copy)
	Default.Volume = b1 and DefaultVolume or 0.0
	DefaultReverb.Volume = b1 and DefaultReverbVolume or 0.0
end
local function applyMusic(b2: boolean) -- line: 27
	-- upvalues: Music (copy), MusicVolume (copy)
	Music.Volume = b2 and MusicVolume or 0.0
end
local function applyAll() -- line: 31
	-- upvalues: SettingsCmds (copy), Default (copy), DefaultVolume (copy), DefaultReverb (copy), DefaultReverbVolume (copy), Music (copy), MusicVolume (copy)
	local v17 = SettingsCmds.IsEnabled("SFX")

	Default.Volume = v17 and DefaultVolume or 0.0
	DefaultReverb.Volume = v17 and DefaultReverbVolume or 0.0
	Music.Volume = SettingsCmds.IsEnabled("Music") and MusicVolume or 0.0
end

SettingsCmds.Changed:Connect(function(property: string, b3: boolean) -- line: 37
	-- upvalues: Default (copy), DefaultVolume (copy), DefaultReverb (copy), DefaultReverbVolume (copy), Music (copy), MusicVolume (copy)
	if property == "SFX" then
		local v20 = b3 ~= false

		Default.Volume = v20 and DefaultVolume or 0.0
		DefaultReverb.Volume = v20 and DefaultReverbVolume or 0.0

		return
	end

	if property == "Music" then
		Music.Volume = b3 ~= false and MusicVolume or 0.0
	end
end)

local v14 = SettingsCmds.IsEnabled("SFX")

Default.Volume = v14 and DefaultVolume or 0.0
DefaultReverb.Volume = v14 and DefaultReverbVolume or 0.0
Music.Volume = SettingsCmds.IsEnabled("Music") and MusicVolume or 0.0

