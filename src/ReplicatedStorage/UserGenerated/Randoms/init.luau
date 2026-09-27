-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOA25ldwtYb3JzaGlmdDEyOAZVbmlxdWURVW5pcXVlWG9yc2hpZnQxMjgHcmVxdWlyZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlDVVzZXJHZW5lcmF0ZWQHUmFuZG9tcwRCYXNlAVISRGVmYXVsdFhvcnNoaWZ0MTI4BXRhYmxlBmZyZWV6ZQADAwEBAAAEAAEADwb7AQAATQEB7wAAAABSAgAAnwECAIIBAAABAwEAHAIBGAAAAAAAAB0AAAAAAwEBAAAHAwEABQGCDwb7AQAATQEBqQAAAABSAgAAnwECAIIBAAABAwMAHwQBGAAAAAAAACAAAAAABQAAAQMPAAADDwABLQ8BDiAPAhsTLqMAAACkAAEAAAAAQKQBAwAAACBATQEBPwQAAABNAQHgBQAAAE0BAWwGAAAATQEBLgcAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAj8EAAAATQIC4AUAAABNAgJsBgAAAE0CAtgIAAAAnwECAv8CAwAAAAAATQMBcwkAAAAwAwKhCgAAAMADCwASAAEAMAMC2AgAAADAAwwAEgABADADApENAAAApAMQAAA84IBSBAIAnwMCAIIDAAARAwUEAAAAQAMGBAAAIEADBwMIAwkDCgMCAwsDDAYABgEDBAMNAw4EADzggAIAAQEAARgAEwAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAEAAIAAAABAAAAAwAAAAQAAAAAAQAAAAACHsT+29bAXbHJQo538HohqW7c6a8sAJTa

-- decompilation:
--!native
require(game.ReplicatedStorage.UserGenerated.Randoms.Base)

local Xorshift128 = require(game.ReplicatedStorage.UserGenerated.Randoms.Xorshift128)
local t1 = {
	DefaultXorshift128 = Xorshift128.R,
	Xorshift128 = function(p1) -- line: 28
		-- upvalues: Xorshift128 (copy)
		return Xorshift128.new(p1)
	end,
	UniqueXorshift128 = function(n1: number?) -- line: 31
		-- upvalues: Xorshift128 (copy)
		return Xorshift128.Unique(n1)
	end
}

return table.freeze(t1)

