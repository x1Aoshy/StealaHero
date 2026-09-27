-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFBENvbWIHcmVxdWlyZQZzY3JpcHQGUGFyZW50CUZhY3RvcmlhbAACCAIBAAAADPsDAABSBAAAnwMCAvsFAABSBgEAnwUCAvsGAAAmBwABnwYCAgkEBQbsAgMEggICAAAAAwEBGAAAAAAAAAAAAAAAAAQAAAAAAgAAAQIADaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQErBQAAAJ8AAgLAAQYAEgAAAIIBAgAHAwIEAAAAQAMDBAAAIEADBAMFBgABAAEAARgAAAAAAAAAAAAAAgAEAQAAAAAB

-- decompilation:
local Factorial = require(script.Parent.Factorial)

local function Comb(p1, p2) -- line: 3
	-- upvalues: Factorial (copy)
	return Factorial(p1) / (Factorial(p2) * Factorial(p1 - p2))
end

return Comb

