-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMsBXBjYWxsNkdlYXJzIG5hbWUgIiUqIiBkb2VzIG5vdCBleGlzdCBpbiB0aGUgR2VhcnMgZGlyZWN0b3J5LgZmb3JtYXQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUMTW9kdWxlTG9hZGVyB0xpYnJhcnkHR2xvYmFscwlDb25zdGFudHMGc2NyaXB0BVR5cGVzCUludGVyZmFjZQlGdW5jdGlvbnMPTWFrZVRhYmxlU3RyaWN0BFV0aWwSU2VhcmNoR2VhclRvb2xVdGlsBl9JbmRleAh0eXBlQ2FzdAhHZWFyc0Rpcghyb290TmFtZQlHZWFycy5EaXINZm9yY2VTYWZlTG9hZAdub1ByaW50DHNob3VsZEluamVjdAlJU19DTElFTlQJRGlyZWN0b3J5DkdlYXJOYW1lRXhpc3RzCUlTX1NUVURJTwVwYWlycw5HZXREZXNjZW5kYW50cwxNb2R1bGVTY3JpcHQDSXNBBE5hbWUNRGVmYXVsdENvbmZpZyBGYWlsZWQgdG8gdmFsaWRhdGUgY29uZmlnICUqOiAlKgZhc3NlcnQUTWF4U2hvcFN0b2NrUXVhbnRpdHkUTWluU2hvcFN0b2NrUXVhbnRpdHk/Q29uZmlnICUqIGhhcyBNYXhTaG9wU3RvY2tRdWFudGl0eSAlKiA8IE1pblNob3BTdG9ja1F1YW50aXR5ICUqCVRvb2xNb2RlbDpNaXNzaW5nIEdlYXJNb2RlbCAlKiBmb3IgJSogaW4gUmVwbGljYXRlZFN0b3JhZ2UuR2VhclRvb2xzBUdlYXJzAAMDAAIAAAAE+wEAAPsCAQCHAAECggACAAAAIgABGAAAAAAjAAAAAAYBAQAABgMAAAUBAxCkAQEAAAAAQNkCAAASAgAAEgAAAJ8BAgIOAQIAqQIBAIICAgCpAgAAbwMCAFIFAAC8AwONAwAAAJ8DAwKCAgMABAMBBAAAAEADAgMDAQAhAAEYAAAAAAAABAEAAwAAAAAAACIAAAAAFwAAAQAAogGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgAZBgAAAJ8BAgKkAgUAAABAQE0DAGoHAAAATQMDSwgAAABNAwMHCQAAAJ8CAgKkAwUAAABAQKQECwAAAKBATQQE7wwAAABNBAQPDQAAAJ8DAgKkBAUAAABAQE0FAGoHAAAATQUFUw4AAABNBQVEDwAAAJ8EAgKkBQUAAABAQE0GAGoHAAAATQYGnhAAAABNBgYYEQAAAJ8FAgL/BgIAAAAAAFIHAQCkCAsAAACgQE0ICAASAAAA/wkAAAAAAADiChsATQsCOBwAAAAwCwqhFwAAAJ8HBAIwBwaRHQAAADADBu8MAAAATQgG7wwAAADACR4AEgAHADAJCAcfAAAATQgCeCAAAAAOCFEApAgiAAAAEEKkCQsAAACgQE0JCQASAAAAvAkJRyMAAACfCQIAnwgABBcIRABvDyQAvA0M/iUAAACfDQMCDg0/AE0ODLomAAAAhw0HDk0OAwwnAAAAUg8NAJ8OAgNvEigATRQMuiYAAABSFQ8AvBISjSkAAACfEgQCngEOBBIAAABSEQ4ApBArAAAAoEKfEAMBTRINzSwAAABNEw1QLQAAANQTAgASAAAAqREAAakRAQBvEi4ATRQMuiYAAABNFQ3NLAAAAE0WDVAtAAAAvBISjSkAAACfEgUCngERAxIAAACkECsAAACgQp8QAwFNEA2BLwAAACsQAgBNEAy6JgAAAFISBQBSExAAnxICAm8TMABSFRAATRYMuiYAAAC8ExONKQAAAJ8TBAKeARIDEwAAAKQRKwAAAKBCnxEDAW4Iu/8CAAAAUggEAFIJBwBvCjEAnwgDAYIGAgAyAwQEAAAAQAMFAwYDBwQAAEBAAwgDCQMKAwsDDAQAAKBAAw0DDgMPAxADEQMSAxMDFAMVAxYDFwMYAxkBAQMaCAUTFAAAABUWAAAAF/////8YGQAAABoZAAAAAxsDHAYBAx0DHgMfBAAAEEIDIAMhAyIDIwMkAyUDAwMmBAAAoEIDJwMoAykDKgMrAywBAQEAARgAAwAAAAAAAwAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAGAAEBAAAAAQABAwAAAPoMAAEAAgAAAAAADAAAAQAAAAAAAAAAAAABAAAAAAQAAAEAAAABAAAAAAAAAAAAAAAAAwAAAAAAAAABAAAAAAAAAAAAAAD+AAAFAAAAAAIAAAEAAAAAAAAAAP4AAPEAFgAAAAIBAAAAAAKMt6wLrhQYLKQ6JjnXHSJB/K+7f75zxgo=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Interface = require(script.Types.Interface)
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local SearchGearToolUtil = require(ReplicatedStorage.Library.Util.SearchGearToolUtil)
local t1 = {}
local v8 = ModuleLoader(script._Index, {}, {
	typeCast = "GearsDir",
	rootName = "Gears.Dir",
	noPrint = true,
	shouldInject = true,
	forceSafeLoad = Constants.IS_CLIENT
})

t1.Directory = v8
t1.Types = Interface

function t1.Types.GearNameExists(s1: string) -- line: 33
	-- upvalues: v8 (copy)
	if pcall(function() -- line: 34
		-- upvalues: v8 (copy), s1 (copy)
		return v8[s1]
	end) then
		return true
	end

	return false, `Gears name "{ s1 }" does not exist in the Gears directory.`
end

if Constants.IS_STUDIO then
	for _, descendant in pairs(script._Index:GetDescendants()) do
		if descendant:IsA("ModuleScript") then
			local v11 = v8[descendant.Name]
			local v12, v13 = Interface.DefaultConfig(v11)

			assert(v12, `Failed to validate config { descendant.Name }: { v13 }`)
			assert(v11.MaxShopStockQuantity >= v11.MinShopStockQuantity, `Config { descendant.Name } has MaxShopStockQuantity { v11.MaxShopStockQuantity } < MinShopStockQuantity { v11.MinShopStockQuantity }`)

			local v14 = v11.ToolModel or descendant.Name

			assert(SearchGearToolUtil(v14), `Missing GearModel { v14 } for { descendant.Name } in ReplicatedStorage.GearTools`)
		end
	end
end

MakeTableStrict(v8, "Gears")

return t1

