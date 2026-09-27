-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEB3JlcXVpcmUGc2NyaXB0BlBhcmVudANHQ0QAAgcCAQAAAAcJAwAB+wQAAFIFAABSBgEAnwQDAuwCAwSCAgIAAAADAAEYAAAAAAAAAAQAAAAAAgAAAQIADaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQHKBQAAAJ8AAgLAAQYAEgAAAIIBAgAHAwEEAAAAQAMCBAAAIEADAwMEBgABAAEAARgAAAAAAAAAAAAAAgAAAQAAAAAB

-- decompilation:
local GCD = require(script.Parent.GCD)

return function(p1, p2) -- line: 3
	-- upvalues: GCD (copy)
	return p1 * p2 / GCD(p1, p2)
end

