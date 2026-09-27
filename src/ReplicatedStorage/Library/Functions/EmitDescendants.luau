-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMND1BhcnRpY2xlRW1pdHRlcgNJc0EEbWF0aANtYXgGaXBhaXJzC0dldENoaWxkcmVuD0VtaXREZXNjZW5kYW50cwdyZXF1aXJlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UHTGlicmFyeQlGdW5jdGlvbnMHRW1pdE9uZQACDQIBAAAHBAAABQIHDyWMAgAAbwUAALwDAP4BAAAAnwMDAg4DCgBSBAIA+wUAAFIGAABSBwEAnwUDAEwSAAKkAwQAAAwggJ8DAAJSAgMApAMGAAAAUEC8BABoBwAAAJ8EAgCfAwAEUQMLAFIJAgA1CgC3CAAAAFILBwBSDAEAnwoDAEwSAAKkCAQAAAwggJ8IAAJSAggAbgP0/wIAAICCAgIACQMBAwIDAwMEBAAMIIADBQQAAFBAAwYDBwAKBwEYAAIAAAAAAQAAAAAAAAAAAAMAAAAAAAABAAAAAAAAAAAAAP8ABAsAAAAAAgAAAQIAFaMAAACkAAEAAAAAQKQBAwAAACBATQEBPwQAAABNAQFqBQAAAE0BAVMGAAAATQEBXgcAAACfAAICwAEIABIAAAAYAQC3CQAAADUBALcJAAAAggECAAoDCAQAAABAAwkEAAAgQAMKAwsDDAMNBgADBwEAAQABGAAHAAAAAAAAAAAAAAAAAgAAAA4AAAEAAAAAAT4x1+b+06P4b5v+ymrENmhOKcCSDPW95w==

-- decompilation:
local EmitOne = require(game.ReplicatedStorage.Library.Functions.EmitOne)

function EmitDescendants(p1, p2) -- line: 10
	-- upvalues: EmitOne (copy)
	local n1 = 0.0

	if p1:IsA("ParticleEmitter") then
		n1 = math.max(n1, EmitOne(p1, p2))
	end

	for _, child in ipairs(p1:GetChildren()) do
		n1 = math.max(n1, EmitDescendants(child, p2))
	end

	return n1
end

return EmitDescendants

