-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKBG1hdGgFZmxvb3IMRmxvb3JGaWd1cmVzBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkJRnVuY3Rpb25zDFJvdW5kRmlndXJlcwACCAMBAAAACPsDAABSBAAAUgUBAFIGAgCkBwIAAAQAgJ8DBQCCAwAAAwMBAwIEAAQAgAAEAwEYAAAAAAAAAAAFAAAAAAMAAAECABejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAlMHAAAATQICvQgAAACfAQICwAIJABIAAQAYAgCNCgAAADUCAI0KAAAAggICAAsDBAQAAABAAwUDBgMHBAAAQEADCAMJAwoGAAMDAQABAAEYAAAAAAAAAAEAAAAAAAAAAAIAAAAEAAABAAAAAAERKC7UQ2xSDyaT2KbLyFeaYTA5oCPsRNU=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFigures = require(ReplicatedStorage.Library.Functions.RoundFigures)

function FloorFigures(p1, p2, p3) -- line: 4
	-- upvalues: RoundFigures (copy)
	return RoundFigures(p1, p2, p3, math.floor)
end

return FloorFigures

