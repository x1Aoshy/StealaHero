-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPCEluc3RhbmNlA25ldwVTb3VuZA9Db25maWd1cmVkU291bmQETmFtZRlQcmVwYXJlU291bmRGcm9tU291bmRGaWxlBlBhcmVudBVDcmVhdGVDb25maWd1cmVkU291bmQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzBnNjcmlwdAACBwMCAAAIBQAABQMHD4MV+wMAAE0DA/QAAAAAUgQAAJ8DAgGkAwIAAAQAgG8EAwCfAwICkAQCBDAEA7oFAAAA+wQBAE0EBGYGAAAAUgUDAFIGAQCfBAMBMAADJAcAAACCAwIACAMBAwIEAAQAgAMDAwQDBQMGAwcADggBGAAAAAAAAgAAAAEAAAEAAAAAAAEAAg8AAAAABAAAAQIAGaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIFAAAAQECkAwkAAACAQE0DAyQKAAAAnwICAsADCwASAAEAEgACAIIDAgAMAwkEAAAAQAMKAwsDDAQAAEBAAw0DDgMPBAAAgEADBwYAAQABAAEYAAMAAAAAAAMAAAAAAAABAAAAAAAABgAACwEAAAAAAcQx1wse3YT9GIIrFTZ1TjS0KcB/9vW9Cg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Parent = require(script.Parent)

local function CreateConfiguredSound(p1, p2, s1: string?) -- line: 14
	-- upvalues: Asserts (copy), Parent (copy)
	Asserts.Instance(p1)

	local Sound = Instance.new("Sound")

	Sound.Name = s1 or "ConfiguredSound"
	Parent.PrepareSoundFromSoundFile(Sound, p2)
	Sound.Parent = p1

	return Sound
end

return CreateConfiguredSound

