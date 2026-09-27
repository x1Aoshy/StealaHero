-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMeBGdhbWUITGlnaHRpbmcKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQlXb3Jrc3BhY2UHcmVxdWlyZQdMaWJyYXJ5CUZ1bmN0aW9ucw9NYWtlVGFibGVTdHJpY3QHR2xvYmFscwlDb25zdGFudHMGQ2xpZW50DUxpZ2h0aW5nc0NvcmUORGVlcENvcHlVbnNhZmUGc2NyaXB0BVR5cGVzCUludGVyZmFjZQlEaXJlY3RvcnkJU2VyaWFsaXplB0RlZmF1bHQPU2VyaWFsaXplQ2xvdWRzB1RlcnJhaW4GQ2xvdWRzCUlTX1NUVURJTwVwYWlycw5MaWdodGluZ0NvbmZpZyBJbnZhbGlkIGxpZ2h0aW5nIGNvbmZpZyAiJSoiOiAlKgZmb3JtYXQGYXNzZXJ0E0xpZ2h0aW5ncy5EaXJlY3RvcnkAARcAAAEAAHijAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIBAAAAAEBvBAUAvAICFgMAAACfAgMCpAMHAAAAYEBNBAFqCAAAAE0EBFMJAAAATQQERAoAAACfAwICpAQHAAAAYEBNBQFqCAAAAE0FBUsLAAAATQUFBwwAAACfBAICpAUHAAAAYEBNBgFqCAAAAE0GBk0NAAAATQYGTw4AAACfBQICpAYHAAAAYEBNBwFqCAAAAE0HB1MJAAAATQcHBg8AAACfBgICpAcHAAAAYECkCBEAAAAAQU0ICO8SAAAATQgIDxMAAACfBwIC/wgCAAAAAAD/CQEAAAAAADAJCJEUAAAAMAcI7xIAAABNCgVxFQAAAFILAACfCgICMAoJOhYAAABNCgk6FgAAAE0LBQEXAAAATQwCVBgAAABNDAyPGQAAAJ8LAgIwCwqPGQAAAE0KBHgaAAAADgoXAKQKHAAAALBBUgsJAJ8KAgQXChAATQ8Hux0AAABSEA4Anw8CA28THgBSFQ0AUhYQALwTE40fAAAAnxMEAp4BDwQTAAAAUhIPAKQRIQAAAABCnxEDAW4K7/8CAAAAUgoDAFILCQBvDCIAnwoDAYIIAgAjAwEEAAAAQAMCAwMDBAMFAwYEAABgQAMHAwgDCQMKAwsDDAMNAw4DDwQAAABBAxADEQMSAxMDFAMVAxYDFwMYAxkEAACwQQMaAxsDHAMdBAAAAEIDHgABAAEYAAMAAAAAAAEAAAAAAAEAAAAAAAMAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAkAAQABAAEAAgAAAAAAAQAAAAAAAAAAAAACAAABAAAAAAEAAAABAAAAAAAAAAAAAAD+AAYAAAACAQAAAAAAO76INkx0smAks5KPw400bEumn0IJeuI3

-- decompilation:
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local LightingsCore = require(ReplicatedStorage.Library.Client.LightingsCore)

require(ReplicatedStorage.Library.Functions.DeepCopyUnsafe)

local Interface = require(script.Types.Interface)
local t1 = {}
local t2 = {}

t1.Directory = t2
t1.Types = Interface
t2.Default = LightingsCore.Serialize(Lighting)
t2.Default.Clouds = LightingsCore.SerializeClouds(Workspace.Terrain.Clouds)

if Constants.IS_STUDIO then
	for k, v in pairs(t2) do
		local v12, v13 = Interface.LightingConfig(v)

		assert(v12, `Invalid lighting config "{ k }": { v13 }`)
	end
end

MakeTableStrict(t2, "Lightings.Directory")

return t1

