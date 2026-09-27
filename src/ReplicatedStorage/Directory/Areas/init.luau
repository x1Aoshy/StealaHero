-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMmBXBjYWxsNUFyZWEgbmFtZSAiJSoiIGRvZXMgbm90IGV4aXN0IGluIHRoZSBBcmVhcyBkaXJlY3RvcnkuBmZvcm1hdARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQxNb2R1bGVMb2FkZXIHTGlicmFyeQdHbG9iYWxzCUNvbnN0YW50cwZzY3JpcHQFVHlwZXMJSW50ZXJmYWNlCUZ1bmN0aW9ucw9NYWtlVGFibGVTdHJpY3QGX0luZGV4CHR5cGVDYXN0CEFyZWFzRGlyCHJvb3ROYW1lCUFyZWFzLkRpcg1mb3JjZVNhZmVMb2FkB25vUHJpbnQMc2hvdWxkSW5qZWN0CUlTX0NMSUVOVAlEaXJlY3RvcnkOQXJlYU5hbWVFeGlzdHMJSVNfU1RVRElPBXBhaXJzC0dldENoaWxkcmVuDE1vZHVsZVNjcmlwdANJc0EtQmFkIGluc3RhbmNlIGZvdW5kIGluc2lkZSB0aGUgY29uZmlncyBlbnY6ICUqBE5hbWUGYXNzZXJ0CkFyZWFDb25maWcgRmFpbGVkIHRvIHZhbGlkYXRlIGNvbmZpZyAlKjogJSoFQXJlYXMAAwMAAgAAAAT7AQAA+wIBAIcAAQKCAAIAAAAiAAEYAAAAACMAAAAABgEBAAAGAwAABQEDEKQBAQAAAABA2QIAABICAAASAAAAnwECAg4BAgCpAgEAggICAKkCAABvAwIAUgUAALwDA40DAAAAnwMDAoICAwAEAwEEAAAAQAMCAwMBACEAARgAAAAAAAAEAQADAAAAAAAAIgAAAAAVAAABAAB4owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAGQYAAACfAQICpAIFAAAAQEBNAwBqBwAAAE0DA0sIAAAATQMDBwkAAACfAgICpAMFAAAAQECkBAsAAACgQE0EBO8MAAAATQQEDw0AAACfAwICpAQFAAAAQEBNBQBqBwAAAE0FBVMOAAAATQUFRA8AAACfBAIC/wUCAAAAAABSBgEApAcLAAAAoEBNBwcAEAAAAP8IAAAAAAAA4gkZAE0KAjgaAAAAMAoJoRUAAACfBgQCMAYFkRsAAAAwAwXvDAAAAE0HBe8MAAAAwAgcABIABgAwCAcwHQAAAE0HAngeAAAADgcwAKQHIAAAAPBBpAgLAAAAoEBNCAgAEAAAALwICGghAAAAnwgCAJ8HAAQXByMAbw8iALwNC/4jAAAAnw0DAm8OJABNEAu6JQAAALwODo0mAAAAnw4DAp4BDQMOAAAApAwoAAAAcEKfDAMBTQ0LuiUAAACHDAYNTQ0DfCkAAABSDgwAnw0CA28RKgBNEwu6JQAAAFIUDgC8ERGNJgAAAJ8RBAKeAQ0EEQAAAFIQDQCkDygAAABwQp8PAwFuB9z/AgAAAFIHBABSCAYAbwkrAJ8HAwGCBQIALAMEBAAAAEADBQMGAwcEAABAQAMIAwkDCgMLAwwEAACgQAMNAw4DDwMQAxEDEgMTAxQDFQMWAxcBAQMYCAUREgAAABMUAAAAFf////8WFwAAABgXAAAAAxkDGgYBAxsDHAMdBAAA8EEDHgMfAyADIQMiAwMDIwQAAHBCAyQDJQMmAQEBAAEYAAMAAAAAAAMAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAABwABAQAAAAEAAQMAAAD6DAABAAIAAAAAAAwAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAgAAAQAAAAEAAAAAAAAAAAAAAAD7AAkAAAACAQAAAAACbkzudzDmHrdP2+CVWXgCXB5U+QNciIR2

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Interface = require(script.Types.Interface)
local MakeTableStrict = require(ReplicatedStorage.Library.Functions.MakeTableStrict)
local t1 = {}
local v7 = ModuleLoader(script._Index, {}, {
	typeCast = "AreasDir",
	rootName = "Areas.Dir",
	noPrint = true,
	shouldInject = true,
	forceSafeLoad = Constants.IS_CLIENT
})

t1.Directory = v7
t1.Types = Interface

function t1.Types.AreaNameExists(s1: string) -- line: 33
	-- upvalues: v7 (copy)
	if pcall(function() -- line: 34
		-- upvalues: v7 (copy), s1 (copy)
		return v7[s1]
	end) then
		return true
	end

	return false, `Area name "{ s1 }" does not exist in the Areas directory.`
end

if Constants.IS_STUDIO then
	for _, child in pairs(script._Index:GetChildren()) do
		assert(child:IsA("ModuleScript"), `Bad instance found inside the configs env: { child.Name }`)

		local v10 = v7[child.Name]
		local v11, v12 = Interface.AreaConfig(v10)

		assert(v11, `Failed to validate config { child.Name }: { v12 }`)
	end
end

MakeTableStrict(v7, "Areas")

return t1

