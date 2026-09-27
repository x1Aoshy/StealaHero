-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlDE1vZHVsZUxvYWRlcgdMaWJyYXJ5B0dsb2JhbHMJQ29uc3RhbnRzBnNjcmlwdAVUeXBlcwlJbnRlcmZhY2UERGF0YQlGdW5jdGlvbnMPTWFrZVRhYmxlU3RyaWN0Bl9JbmRleAh0eXBlQ2FzdAxTcGlubnlXaGVlbHMIcm9vdE5hbWUWU3Bpbm55V2hlZWxzLkRpcmVjdG9yeQ1mb3JjZVNhZmVMb2FkB25vUHJpbnQMc2hvdWxkSW5qZWN0CUlTX0NMSUVOVAlEaXJlY3RvcnkJSVNfU1RVRElPBXBhaXJzC0dldENoaWxkcmVuBE5hbWUMTW9kdWxlU2NyaXB0A0lzQRBCYWQgaW5zdGFuY2U6ICUqBmZvcm1hdAZhc3NlcnQNRGVmYXVsdENvbmZpZx5JbnZhbGlkIGNvbmZpZyBtb2R1bGU6ICUqIC0gJSoNQWxsV2hlZWxOYW1lcztTcGlubnkgV2hlZWwgbmFtZTogIiUqIiBpcyBub3QgcmVnaXN0ZXJlZCBpbiBBbGxXaGVlbE5hbWVzLgABFwAAAQAAiAGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgAZBgAAAJ8BAgKkAgUAAABAQE0DAGoHAAAATQMDSwgAAABNAwMHCQAAAJ8CAgKkAwUAAABAQKQECwAAAKBATQQE7wwAAABNBAQPDQAAAJ8DAgKkBAUAAABAQKQFCwAAAKBATQUFxg4AAACfBAICpAUFAAAAQEBNBgBqBwAAAE0GBlMPAAAATQYGRBAAAACfBQIC/wYDAAAAAABSBwEApAgLAAAAoEBNCAgAEQAAAP8JAAAAAAAA4goaAE0LAjgbAAAAMAsKoRYAAACfBwQCMAcGkRwAAAAwAwbvDAAAADAEBsYOAAAAUggFAFIJBwBvChUAnwgDAU0IAngdAAAADgg9AKQIHwAAAOBBpAkLAAAAoEBNCQkAEQAAALwJCWggAAAAnwkCAJ8IAAQXCDAATQ0MuiEAAABvESIAvA8M/iMAAACfDwMCbxAkAFISDQC8EBCNJQAAAJ8QAwKeAQ8DEAAAAKQOJwAAAGBCnw4DAYcOBw1NDwMMKAAAAFIQDgCfDwIDbxMpAFIVDQBSFhAAvBMTjSUAAACfEwQCngEPBBMAAABSEg8ApBEnAAAAYEKfEQMBTREDwioAAABSEg0AnxECAm8UKwBSFg0AvBQUjSUAAACfFAMCngERBBQAAABSExEApBInAAAAYEKfEgMBbgjP/wIAAACCBgIALAMBBAAAAEADAgMDAwQEAABAQAMFAwYDBwMIAwkEAACgQAMKAwsDDAMNAw4DDwMQAxEDEgMTAxQDFQEBAxYIBRITAAAAFBUAAAAW/////xcYAAAAGRgAAAADFwMYAxkDGgQAAOBBAxsDHAMdAx4DHwMgAyEEAABgQgMiAyMDJAMlAAEAARgAAQAAAAAAAwAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAQAAAAAAAAAACQABAQAAAAEAAQMAAAD6DAABAAEAAgAAAAMAAAEAAAAAAAAAAAAAAQABAAAAAAAAAAAAAAAAAAIBAAAAAgAAAAAAAAAAAAAAAgAAAAEAAAAAAAAAAAAA9gAOAQAAAAAAcOkBYCYCuYY6AlA8T9b2wQDxFhRCLWth

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Interface = require(script.Types.Interface)
local Data = require(script.Data)
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local t1 = {}
local v8 = ModuleLoader(script._Index, {}, {
	typeCast = "SpinnyWheels",
	rootName = "SpinnyWheels.Directory",
	noPrint = true,
	shouldInject = true,
	forceSafeLoad = Constants.IS_CLIENT
})

t1.Directory = v8
t1.Types = Interface
t1.Data = Data
MakeTableStrict(v8, "SpinnyWheels.Directory")

if Constants.IS_STUDIO then
	for _, child in pairs(script._Index:GetChildren()) do
		local childName = child.Name

		assert(child:IsA("ModuleScript"), `Bad instance: { childName }`)

		local v12 = v8[childName]
		local v13, v14 = Interface.DefaultConfig(v12)

		assert(v13, `Invalid config module: { childName } - { v14 }`)
		assert(Interface.AllWheelNames(childName), `Spinny Wheel name: "{ childName }" is not registered in AllWheelNames.`)
	end
end

return t1

