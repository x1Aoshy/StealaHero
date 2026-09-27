-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBnR5cGVvZgV0YWJsZTQoTGlicmFyeSk6KEZ1bmN0aW9ucyk6W1V0aWxpdHlQYWNrYWdlSW5qZWN0b3JdOlF1ZXJ5CUdldFRhZ2dlZAxNb2R1bGVTY3JpcHQDSXNBBGZpbmQETmFtZQdyZXF1aXJlA25ldwdfX2luZGV4BlNjcmlwdC8oTGlicmFyeSk6KEZ1bmN0aW9ucyk6W1V0aWxpdHlQYWNrYWdlSW5qZWN0b3JdOgRnYW1lEUNvbGxlY3Rpb25TZXJ2aWNlCkdldFNlcnZpY2UMR3VpZGVkU2VhcmNoAkdTDExpbmVhclNlYXJjaAJMUwACCwICAAAAOrssAANSBAAApAMBAAAAAECfAwIC8AMDAAIAAIBSAgAAKwICAP8CAAAAAAAAUgACALssAQNSBAEApAMBAAAAAECfAwIC8AMDAAIAAIBSAgEAKwICAP8CAAAAAAAAUgECAPsCAABvBAMAvAICBQQAAACfAgMEZAIZAG8JBQC8Bwb+BgAAAJ8HAwIOBxQApAcIAAAcIIBSCAEATQkGugkAAACfBwMCKwcNAPsIAQBNCQa6CQAAAIcHCAlSCAcAKwgCAE0IBroJAAAApAkLAAAAoEBSCgYAnwkCAmoJAAhuAub/AgAAAIIAAgAMAwEEAAAAQAMCAwMDBAMFAwYDBwQAHCCAAwgDCQQAAKBAABYKARgAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAACAAAAAAABAAAAAAAAAAAAAAAEAAAAAQAAAAAAAAAA+gAJFwAAAAAFAAABAgATowAAAP8AAgAAAAAAMAAAbgAAAADiAQMApAIFAAAAQEBvBAYAvAICFgcAAACfAgMC4gMMAMAEDQASAAIAEgADADAEAO8OAAAAggACAA8DCwMMAw0IAQECAAAAAw4EAABAQAMPAxADEQMSAxMDFAgCCAkAAAAKCwAAAAYAAwoBAAEAARgAAQABAAMDAAAAAAADCgAAAAAQAQAAAAABMLm6+crlQj36HxyQMj9Ww0ChrY0CfdD4

-- decompilation:
local t1 = {}

t1.__index = t1

local _ = {
	Script = "(Library):(Functions):[UtilityPackageInjector]:"
}
local CollectionService = game:GetService("CollectionService")
local t2 = {
	GuidedSearch = "GS",
	LinearSearch = "LS"
}

function t1.new(p1, p2) -- line: 22
	-- upvalues: CollectionService (copy), t2 (copy)
	local v7 = typeof(p1) == "table" and p1 or {}
	local v8 = typeof(p2) == "table" and p2 or {}

	for _, v10 in CollectionService:GetTagged("(Library):(Functions):[UtilityPackageInjector]:Query") do
		if v10:IsA("ModuleScript") and not table.find(v8, v10.Name) then
			v7[t2[v10.Name] or v10.Name] = require(v10)
		end
	end

	return v7
end

return t1

