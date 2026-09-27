-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkFVHlwZXMERWdncwdNb2R1bGVzCFBhY2thZ2VzAXQJaW50ZXJmYWNlA1VpZANFZ2cGc3RyaW5nEFNjaGVtYVZhbGlkYXRpb24SU2VyaWFsaXplZFNhdmVkRWdnEFBlbmRpbmdFZ2dSZXdhcmQKRnVzZVJlc3VsdAABBwAAAQIANKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC7wcAAABNAgJPCAAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD6AkAAABNAwPmCgAAAE0DA5ULAAAAnwICAv8DAgAAAAAATQQCLwwAAADiBQ8ATQYCQRAAAAAwBgXZDQAAAE0GAd8RAAAATQYG2hIAAAAwBgXgDgAAAJ8EAgIwBAO+EwAAAE0EAd8RAAAATQQE2hIAAAAwBAMYFAAAAIIDAgAVAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNBQINDgMOAw8DEAMRAxIAAQABGAADAAAAAAADAAAAAAAAAAABAAAAAAAAAAAAACQAAgAAAQAAAAEAAAAAAP4AAAQAAAAAAAIBAAAAAADt+hEBberOvqjQJqzmxCaTneIGdd8+ewA=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Eggs = require(ReplicatedStorage.Library.Types.Eggs)
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	PendingEggReward = t.interface({
		Uid = t.string,
		Egg = Eggs.SchemaValidation.SerializedSavedEgg
	}),
	FuseResult = Eggs.SchemaValidation.SerializedSavedEgg
}

