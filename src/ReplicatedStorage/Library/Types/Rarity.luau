-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0BXVuaW9uB2xpdGVyYWwGQ29tbW9uCFVuY29tbW9uBFJhcmUJTGVnZW5kYXJ5CE15dGhpY2FsBkRpdmluZQlQcmlzbWF0aWMMVHJhbnNjZW5kZW50BlJhcml0eQABDQAAAQIAOqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC6AcAAABNAgLmCAAAAE0CApUJAAAAnwECAv8CAQAAAAAATQMBmAoAAABNBAFzCwAAAG8FDACfBAICTQUBcwsAAABvBg0AnwUCAk0GAXMLAAAAbwcOAJ8GAgJNBwFzCwAAAG8IDwCfBwICTQgBcwsAAABvCRAAnwgCAk0JAXMLAAAAbwoRAJ8JAgJNCgFzCwAAAG8LEgCfCgICTQsBcwsAAABvDBMAnwsCAJ8DAAIwAwLyFAAAAIICAgAVAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwMQAxEDEgMTAAEAARgAAwAAAAAAAwAAAAAAAAAAAAAMAAIAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAD4AAALAQAAAAAALWkWXnLwwhK88ZTMcGXvol1xASofrXxf

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	Rarity = t.union(t.literal("Common"), t.literal("Uncommon"), t.literal("Rare"), t.literal("Legendary"), t.literal("Mythical"), t.literal("Divine"), t.literal("Prismatic"), t.literal("Transcendent"))
}

