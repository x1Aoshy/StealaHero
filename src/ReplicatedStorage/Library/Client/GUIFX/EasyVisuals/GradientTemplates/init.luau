-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBnNjcmlwdA5HZXREZXNjZW5kYW50cwxNb2R1bGVTY3JpcHQDSXNBBE5hbWUHcmVxdWlyZQABCgAAAQAAHKMAAACkAAEAAAAAQLwAAEcCAAAAnwACAv8BAAAAAAAAUgIAAMYDAADGBAAAZAINAG8JAwC8Bwb+BAAAAJ8HAwIOBwgATQcGugUAAACkCAcAAABgQFIJBgCfCAICnwgBAmoIAQduAvL/AgAAAIIBAgAIAwEEAAAAQAMCAwMDBAMFAwYEAABgQAABAAEYAAAAAAAAAQACAAAAAQAAAAADAAAAAAAAAPwABwEAAAAAAA==

-- decompilation:
local t1 = {}

for _, descendant in (script:GetDescendants()) do
	if descendant:IsA("ModuleScript") then
		t1[descendant.Name] = require(descendant)()
	end
end

return t1

