-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBXRhYmxlBXBhaXJzBnR5cGVvZglBdFdhcm5pbmcnSW52YWxpZCB2YWx1ZSBmb3IgJyUqJyB3aGVuIGxvYWRpbmcgZGlyBmZvcm1hdANMb2cIaXNmcm96ZW4DX2lkBmZyZWV6ZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMHTW9kdWxlcwhQYWNrYWdlcwNuZXcAAgwCAgAABwQAAAUCD4Ey+wIAAE0CAksAAAAAUgMAAJ8CAgGkAgIAAAAQQFIDAACfAgIEFwIlALssBgNSCAYApAcEAAAAMECfBwIC8AcOAAAAAAD7BwEAvAcHCgUAAACfBwICbwkGAFILBQC8CQmNBwAAAJ8JAwK8BwehCAAAAJ8HAwFlABEApAcKAAAkAIBSCAYAnwcCAisHAgAwBQbTCwAAAA4BCQCkBwoAACQAgFIIBgCfBwICKwcEAKQHDQAAMACAUggGAJ8HAgFuAtr/AgAAAIIAAgAOAwEDAgQAABBAAwMEAAAwQAMEAwUDBgMHAwgEACQAgAMJAwoEADAAgAAKAAEYAAAAAAACAAAAAAEAAAAAAAABAAAAAAAAAAAAAAABAwAAAAABAAMAAAAAAAMAAADzABALAAAAAAUAAAECACCjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwPoCAAAAE0DA+YJAAAATQMDoQoAAACfAgICTQMC7wsAAACfAwECwAQMABIAAQASAAMAggQCAA0DCwQAAABAAwwDDQMOBAAAQEADDwMQAxEDEgMHAxMGAAEAAQABGAABAAAAAAADAAAAAAAAAQAAAAAAAAAAAAABAAADAAAAAQAAAAABmbESlrmYRgMgmpHEdRJofempBeKrdXiX

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local v3 = require(ReplicatedStorage.Library.Modules.Packages.Log).new()

return function(p1, b1: boolean?) -- line: 10
	-- upvalues: Asserts (copy), v3 (copy)
	Asserts.table(p1)

	for k, v in pairs(p1) do
		if typeof(v) ~= "table" then
			v3:AtWarning():Log(`Invalid value for '{ k }' when loading dir`)
		else
			if not table.isfrozen(v) then
				v._id = k
			end

			if b1 and not table.isfrozen(v) then
				table.freeze(v)
			end
		end
	end

	return p1
end

