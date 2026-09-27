-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMND1BhcnRpY2xlRW1pdHRlcgNJc0EEbWF0aANtYXgGaXBhaXJzC0dldENoaWxkcmVuBEVtaXQHcmVxdWlyZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlDVVzZXJHZW5lcmF0ZWQDVkZYCEVtaXRPbmNlAAILAQIAABQDAgMFAQcPDw8FFQoPBhUKAgEAIiKMAQAAbwQAALwCAP4BAAAAnwIDAg4CCQBSAwEA+wQAAFIFAACfBAIATBIAAqQCBAAADCCAnwIAAlIBAgCkAgYAAABQQLwDAGgHAAAAnwMCAJ8CAARRAgkAUggBAPsJAQBSCgYAnwkCAEwSAAKkBwQAAAwggJ8HAAJSAQcAbgL2/wIAAICCAQIACAMBAwIDAwMEBAAMIIADBQQAAFBAAwYAFgcBGAABAAAAAAEAAAAAAAAAAAIAAAAAAAABAAAAAAAAAAD/AAMXAAAAAAIAAAEDCwAAAg8AAREPAQ4EEqMAAACkAAEAAAAAQKQBAwAAACBATQEBPwQAAABNAQHgBQAAAE0BAX4GAAAATQEBewcAAACfAAICwAEIABIAAAASAAEAggECAAkDCAQAAABAAwkEAAAgQAMKAwsDDAMNBgABAAEAARgAEwAAAAAAAAAAAAAAAAIAAAsBAAAAAAF0Kml7chs6b5naqsssCYVtBDJ+D0buA3o=

-- decompilation:
--!native
local EmitOnce = require(game.ReplicatedStorage.UserGenerated.VFX.EmitOnce)

local function Emit(p1) -- line: 22
	-- upvalues: EmitOnce (copy), Emit (copy)
	local n1 = 0.0

	if p1:IsA("ParticleEmitter") then
		n1 = math.max(n1, EmitOnce(p1))
	end

	for _, child in ipairs(p1:GetChildren()) do
		n1 = math.max(n1, Emit(child))
	end

	return n1
end

return Emit

