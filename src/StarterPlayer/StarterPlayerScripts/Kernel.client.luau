-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUB3JlcXVpcmUGc2NyaXB0BlBhcmVudAxQbGF5ZXJNb2R1bGUMV2FpdEZvckNoaWxkA25ldxVbQ2xpZW50XTpbRWNvc3lzdGVtXToNU3Bhd25JblRocmVhZARMb2FkBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQhJc0xvYWRlZAZMb2FkZWQEV2FpdAR0YXNrBXNwYXduB0xpYnJhcnkHTG9hZGVycxBUYWdQYWNrYWdlTG9hZGVyAAMEAAAAAAAMpAABAAAAAECkAQMAAAAgQE0BASQEAAAAbwMFALwBAdMGAAAAnwEDAJ8AAAGCAAEABwMBBAAAAEADAgQAACBAAwMDBAMFAA0AARgAAAAAAAAAAAAAAAEOAAAAAAQAAQAAAA77AAAATQAA7wAAAABvAQEA/wIAAAEAAABvAwIAxQIDAgEAAACfAAMCvAAAfgMAAACfAAIBggABAAQDBgMHAwgDCQAVAAEYAAAAAAAAAAAAAAAAAAEWAAAAAAQAAAECACejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEC8AQFVBAAAAJ8BAgIrAQcApAEBAAAAAEBNAQEEBQAAALwBAfcGAAAAnwECAaQBCQAAIHCAwAIKAJ8BAgGkAQwAAACwQE0CAGoNAAAATQICSw4AAABNAgIBDwAAAJ8BAgKkAgkAACBwgMADEAASAAEAnwICAYIAAQARAwoEAAAAQAMLAwwDDQMOAw8DEAMRBAAgcIAGAAMBBAAAsEADEgMTAxQGAQIAAQEAARgAAwAAAAAABQAAAAAAAQAAAAAAAAMAAAAFAAAAAAAAAAADAAAAAAMBAAAAAAIZOA1qSrCwQIDs2kjHs+9GaSAaHiv8Z2s=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

task.spawn(function() -- line: 13
	require(script.Parent:WaitForChild("PlayerModule"))
end)

local TagPackageLoader = require(ReplicatedStorage.Library.Loaders.TagPackageLoader)

task.spawn(function() -- line: 21
	-- upvalues: TagPackageLoader (copy)
	-- No instance in this rebuild carries the CollectionService tag
	-- "[Client]:[Ecosystem]:SpawnInThread" (lost in the rip), so .Load() used to hard-assert
	-- "Attempt to load an empty module directory: [SpawnInThread]" every join. Only call site
	-- in the whole game (grepped) -- safe to just make it tolerant instead of editing the
	-- shared TagPackageLoader module.
	local ok, err = pcall(function()
		TagPackageLoader.new("[Client]:[Ecosystem]:", { "SpawnInThread" }):Load()
	end)
	if not ok then
		warn("[Kernel] SpawnInThread tag package empty in this rebuild (expected): " .. tostring(err))
	end
end)

