-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMpAklkBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlDE1vZHVsZUxvYWRlcgdMaWJyYXJ5B0dsb2JhbHMJQ29uc3RhbnRzBnNjcmlwdAVUeXBlcwlJbnRlcmZhY2UJRnVuY3Rpb25zD01ha2VUYWJsZVN0cmljdAlGcmVlR2lmdHMGX0luZGV4CHR5cGVDYXN0C0ZyZWVHaWZ0RGlyCHJvb3ROYW1lDEZyZWVHaWZ0LkRpcg1mb3JjZVNhZmVMb2FkB25vUHJpbnQMc2hvdWxkSW5qZWN0CUlTX0NMSUVOVAlEaXJlY3RvcnkKU29ydGVkQnlJZAVwYWlycwhUeXBlRGF0YQRUeXBlCUlTX1NUVURJTwtHZXRDaGlsZHJlbgxNb2R1bGVTY3JpcHQDSXNBLUJhZCBpbnN0YW5jZSBmb3VuZCBpbnNpZGUgdGhlIGNvbmZpZ3MgZW52OiAlKgROYW1lBmZvcm1hdAZhc3NlcnQNRGVmYXVsdENvbmZpZwV0YWJsZQRzb3J0E1NvcnRlZEJ5SWRGcmVlR2lmdHMAAgUCAAAAAAlNAwCUAAAAAE0EAZQAAAAAtwMCAAQAAACpAgABqQIBAIICAgABAwEANwABGAAAAAAAAAAAADgAAAAAEgAAAQAAngGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgAZBgAAAJ8BAgKkAgUAAABAQE0DAGoHAAAATQMDSwgAAABNAwMHCQAAAJ8CAgKkAwUAAABAQKQECwAAAKBATQQE7wwAAABNBAQPDQAAAJ8DAgKkBAUAAABAQE0FAGoHAAAATQUFUw4AAABNBQVEDwAAAJ8EAgKkBQUAAABAQE0GAGoHAAAATQYG7wwAAABNBgaxEAAAAJ8FAgL/BgMAAAAAAFIHAQCkCAsAAACgQE0ICAARAAAA/wkAAAAAAADiChoATQsCOBsAAAAwCwqhFgAAAJ8HBAIwBwaRHAAAADADBu8MAAAA/wgAAAAAAAAwCAbxHQAAAKQIHwAAAOBBUgkHAJ8IAgQXCAoATQ0MXSAAAAArDQcATQ4FXSAAAABNDwwRIQAAAIcNDg8wDQxdIAAAAG4I9f8CAAAATQgCeCIAAAAOCCcApAgfAAAA4EGkCQsAAACgQE0JCQARAAAAvAkJaCMAAACfCQIAnwgABBcIGgBvECQAvA4M/iUAAACfDgMCbw8mAE0RDLonAAAAvA8PjSgAAACfDwMCngEOAw8AAACkDSoAAACQQp8NAwFNDgy6JwAAAIcNBw5NDwMMKwAAAFIQDQCfDwIATAEAAqQOKgAAAJBCnw4AAW4I5f8CAAAApAgfAAAA4EFSCQcAnwgCBBcIBQBNDQbxHQAAAE0ODJQsAAAAagwNDm4I+v8CAAAApAgvAAC40IJNCQbxHQAAAMAKMACfCAMBUggEAE0JBvEdAAAAbwoxAJ8IAwFSCAQAUgkHAG8KEACfCAMBggYCADIDAgQAAABAAwMDBAMFBAAAQEADBgMHAwgDCQMKBAAAoEADCwMMAw0DDgMPAxADEQMSAxMDFAMVAxYBAQMXCAUSEwAAABQVAAAAFv////8XGAAAABkYAAAAAxgDGQMaAxsEAADgQQMcAx0DHgMfAyADIQMiAyMDJAMlBAAAkEIDJgMBAycDKAQAuNCCBgADKQEAAQABGAADAAAAAAADAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAcAAQEAAAABAAEDAAAA+gwAAQABAAAAAgAAAAABAAADAAAAAAAA/AAHAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAIAAAEAAAAAAAAA/AAIAAAAAAEAAAAA/wAEAAAAAAAEAAAAAAEAAAACAQAAAAAB8yppdg71dfTTXVnqNDO4DoMyfgLB7gN3

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Interface = require(script.Types.Interface)
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local FreeGifts = require(ReplicatedStorage.Library.Types.FreeGifts)
local t1 = {}
local v8 = ModuleLoader(script._Index, {}, {
	typeCast = "FreeGiftDir",
	rootName = "FreeGift.Dir",
	noPrint = true,
	shouldInject = true,
	forceSafeLoad = Constants.IS_CLIENT
})

t1.Directory = v8
t1.Types = Interface
t1.SortedById = {}

for _, v in pairs(v8) do
	if not v.TypeData then
		v.TypeData = FreeGifts.TypeData[v.Type]
	end
end

if Constants.IS_STUDIO then
	for _, child in pairs(script._Index:GetChildren()) do
		assert(child:IsA("ModuleScript"), `Bad instance found inside the configs env: { child.Name }`)

		local v13 = v8[child.Name]

		assert(Interface.DefaultConfig(v13))
	end
end

for _, v in pairs(v8) do
	t1.SortedById[v.Id] = v
end

table.sort(t1.SortedById, function(p1, p2) -- line: 55
	return p1.Id < p2.Id
end)
MakeTableStrict(t1.SortedById, "SortedByIdFreeGifts")
MakeTableStrict(v8, "FreeGifts")

return t1

