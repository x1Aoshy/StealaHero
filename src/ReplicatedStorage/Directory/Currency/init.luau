-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMmBXBjYWxsPEN1cnJlbmN5IG5hbWUgIiUqIiBkb2VzIG5vdCBleGlzdCBpbiB0aGUgQ3VycmVuY3kgZGlyZWN0b3J5LgZmb3JtYXQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUMTW9kdWxlTG9hZGVyB0xpYnJhcnkHR2xvYmFscwlDb25zdGFudHMGc2NyaXB0BVR5cGVzCUludGVyZmFjZQlGdW5jdGlvbnMPTWFrZVRhYmxlU3RyaWN0Bl9JbmRleAh0eXBlQ2FzdAtDdXJyZW5jeURpcghyb290TmFtZQxDdXJyZW5jeS5EaXINZm9yY2VTYWZlTG9hZAdub1ByaW50DHNob3VsZEluamVjdAlJU19DTElFTlQJRGlyZWN0b3J5EkN1cnJlbmN5TmFtZUV4aXN0cwlJU19TVFVESU8FcGFpcnMLR2V0Q2hpbGRyZW4MTW9kdWxlU2NyaXB0A0lzQS1CYWQgaW5zdGFuY2UgZm91bmQgaW5zaWRlIHRoZSBjb25maWdzIGVudjogJSoETmFtZQZhc3NlcnQNRGVmYXVsdENvbmZpZyBGYWlsZWQgdG8gdmFsaWRhdGUgY29uZmlnICUqOiAlKghDdXJyZW5jeQADAwACAAAABPsBAAD7AgEAhwABAoIAAgAAACIAARgAAAAAIwAAAAAGAQEAAAYDAAAFAQMQpAEBAAAAAEDZAgAAEgIAABIAAACfAQICDgECAKkCAQCCAgIAqQIAAG8DAgBSBQAAvAMDjQMAAACfAwMCggIDAAQDAQQAAABAAwIDAwEAIQABGAAAAAAAAAQBAAMAAAAAAAAiAAAAABUAAAEAAHijAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgAZBgAAAJ8BAgKkAgUAAABAQE0DAGoHAAAATQMDSwgAAABNAwMHCQAAAJ8CAgKkAwUAAABAQKQECwAAAKBATQQE7wwAAABNBAQPDQAAAJ8DAgKkBAUAAABAQE0FAGoHAAAATQUFUw4AAABNBQVEDwAAAJ8EAgL/BQIAAAAAAFIGAQCkBwsAAACgQE0HBwAQAAAA/wgAAAAAAADiCRkATQoCOBoAAAAwCgmhFQAAAJ8GBAIwBgWRGwAAADADBe8MAAAATQcF7wwAAADACBwAEgAGADAIB+wdAAAATQcCeB4AAAAOBzAApAcgAAAA8EGkCAsAAACgQE0ICAAQAAAAvAgIaCEAAACfCAIAnwcABBcHIwBvDyIAvA0L/iMAAACfDQMCbw4kAE0QC7olAAAAvA4OjSYAAACfDgMCngENAw4AAACkDCgAAABwQp8MAwFNDQu6JQAAAIcMBg1NDQMMKQAAAFIODACfDQIDbxEqAE0TC7olAAAAUhQOALwREY0mAAAAnxEEAp4BDQQRAAAAUhANAKQPKAAAAHBCnw8DAW4H3P8CAAAAUgcEAFIIBgBvCSsAnwcDAYIFAgAsAwQEAAAAQAMFAwYDBwQAAEBAAwgDCQMKAwsDDAQAAKBAAw0DDgMPAxADEQMSAxMDFAMVAxYDFwEBAxgIBRESAAAAExQAAAAV/////xYXAAAAGBcAAAADGQMaBgEDGwMcAx0EAADwQQMeAx8DIAMhAyIDAwMjBAAAcEIDJAMlAyYBAQEAARgAAwAAAAAAAwAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAHAAEBAAAAAQABAwAAAPoMAAEAAgAAAAAADAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAACAAABAAAAAQAAAAAAAAAAAAAAAPsACQAAAAIBAAAAAAKUkfKy0mgXBHt/CJqU4xSF5InlxqZVmLM=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Interface = require(script.Types.Interface)
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local t1 = {}
local v7 = ModuleLoader(script._Index, {}, {
	typeCast = "CurrencyDir",
	rootName = "Currency.Dir",
	noPrint = true,
	shouldInject = true,
	forceSafeLoad = Constants.IS_CLIENT
})

t1.Directory = v7
t1.Types = Interface

function t1.Types.CurrencyNameExists(s1: string) -- line: 33
	-- upvalues: v7 (copy)
	if pcall(function() -- line: 34
		-- upvalues: v7 (copy), s1 (copy)
		return v7[s1]
	end) then
		return true
	end

	return false, `Currency name "{ s1 }" does not exist in the Currency directory.`
end

if Constants.IS_STUDIO then
	for _, child in pairs(script._Index:GetChildren()) do
		assert(child:IsA("ModuleScript"), `Bad instance found inside the configs env: { child.Name }`)

		local v10 = v7[child.Name]
		local v11, v12 = Interface.DefaultConfig(v10)

		assert(v11, `Failed to validate config { child.Name }: { v12 }`)
	end
end

MakeTableStrict(v7, "Currency")

return t1

