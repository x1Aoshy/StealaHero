-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKBG1hdGgGcmFuZG9tDVBsYXliYWNrU3BlZWQHUGxheWluZwxUaW1lUG9zaXRpb24OUGxheUNsaWNrU291bmQEZ2FtZQxTb3VuZFNlcnZpY2UKR2V0U2VydmljZQVDbGljawACBwABAAAAFPsAAACMAgEApAQDAAAIEICMBfH/jAYPAJ8EAwI+AwQAQwECAzABACgEAAAA+wAAAKkBAQAwAQBPBQAAAPsAAACMAQAAMAEAxgYAAACCAAEABwIAAAAAAABZQAMBAwIEAAgQgAMDAwQDBQAEBgEYAAAAAAAAAAAAAAABAAAAAQAAAAEFAAAAAAMAAAECAAyjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCTQEATwQAAADAAgUAEgABAIICAgAGAwcEAAAAQAMIAwkDCgYAAQABAAEYAAAAAAAAAAEAAgAGAQAAAAABCMFqV1VOa/lBmGtMUFCF2XjZfSM6BQBW

-- decompilation:
local Click = game:GetService("SoundService").Click

local function PlayClickSound() -- line: 4
	-- upvalues: Click (copy)
	Click.PlaybackSpeed = 1.0 + math.random(-15.0, 15.0) / 100.0
	Click.Playing = true
	Click.TimePosition = 0.0
end

return PlayClickSound

