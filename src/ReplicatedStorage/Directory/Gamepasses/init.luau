-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlDE1vZHVsZUxvYWRlcgdMaWJyYXJ5B0dsb2JhbHMJQ29uc3RhbnRzBnNjcmlwdAVUeXBlcwlJbnRlcmZhY2UJRnVuY3Rpb25zD01ha2VUYWJsZVN0cmljdAZfSW5kZXgIdHlwZUNhc3QNR2FtZXBhc3Nlc0Rpcghyb290TmFtZQ5HYW1lcGFzc2VzLkRpcg1mb3JjZVNhZmVMb2FkB25vUHJpbnQMc2hvdWxkSW5qZWN0CUlTX0NMSUVOVAlEaXJlY3RvcnkJSVNfU1RVRElPBXBhaXJzDURlZmF1bHRDb25maWcnQmFkIGNvbmZpZyBmb3VuZCBpbiBHYW1lcGFzc2VzOiAlKiAtICUqBmZvcm1hdAZhc3NlcnQJUHJvZHVjdElkBWVycm9yG0R1cGxpY2F0ZSBHYW1lcGFzczogJSogLyAlKgpHYW1lcGFzc2VzAAEVAAABAAcAAAEDEF4CbaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CABkGAAAAnwECAqQCBQAAAEBATQMAagcAAABNAwNLCAAAAE0DAwcJAAAAnwICAqQDBQAAAEBApAQLAAAAoEBNBATvDAAAAE0EBA8NAAAAnwMCAqQEBQAAAEBATQUAagcAAABNBQVTDgAAAE0FBUQPAAAAnwQCAv8FAgAAAAAAUgYBAKQHCwAAAKBATQcHABAAAAD/CAAAAAAAAOIJGQBNCgI4GgAAADAKCaEVAAAAnwYEAjAGBZEbAAAAMAMF7wwAAABNBwJ4HAAAAA4HKwD/BwAAAAAAAKQIHgAAANBBUgkGAJ8IAgQXCCIATQ0DDB8AAABSDgwAnw0CA28RIABSEwsAUhQOALwREY0hAAAAnxEEAp4BDQQRAAAAUhANAKQPIwAAACBCnw8DAU0QDAskAAAAhw8HEA4PCwCkDyYAAABQQm8QJwBSEgsATRMMCyQAAAC8EBCNIQAAAJ8QBAKfDwIBZQADAE0PDAskAAAAagsHD24I3f8CAAAAUgcEAFIIBgBvCSgAnwcDAYIFAgApAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQQAAKBAAwoDCwMMAw0DDgMPAxADEQMSAxMDFAEBAxUIBRESAAAAExQAAAAV/////xYXAAAAGBcAAAADFgMXAxgDGQQAANBBAxoDGwMcAx0EAAAgQgMeAx8EAABQQgMgAyEAAQABGAADAAAAAAADAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAcAAQEAAAABAAEDAAAA+gwAAQACAAABAAEAAAAAAQAAAAEAAAAAAAAAAAAAAAIAAAABAAAAAAAAAAAAAAIAAPkADAAAAAIBAAAAAACRnEFimvvLhloXpYqVI8B44YRWFqNYK2M=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Interface = require(script.Types.Interface)
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local t1 = {}
local v7 = ModuleLoader(script._Index, {}, {
	typeCast = "GamepassesDir",
	rootName = "Gamepasses.Dir",
	noPrint = true,
	shouldInject = true,
	forceSafeLoad = Constants.IS_CLIENT
})

t1.Directory = v7
t1.Types = Interface

if Constants.IS_STUDIO then
	local t2 = {}

	for k, v in pairs(v7) do
		local v11, v12 = Interface.DefaultConfig(v)

		assert(v11, `Bad config found in Gamepasses: { k } - { v12 }`)

		if t2[v.ProductId] then
			error(`Duplicate Gamepass: { k } / { v.ProductId }`)
		else
			t2[v.ProductId] = k
		end
	end
end

MakeTableStrict(v7, "Gamepasses")

return t1

