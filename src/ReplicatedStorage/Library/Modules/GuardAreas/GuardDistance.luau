-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMB1ZlY3RvcjMBWAFaA25ldwlNYWduaXR1ZGUCWFoEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzAAIHAgEAAAsEAAEFAggICAMUAhf7AgAATQICTwAAAABSAwAAnwICAfsCAABNAgJPAAAAAFIDAQCfAgIBJgIAAU0EAnkBAAAAjAUAAE0GAnsCAAAATDYAAqQDBAAADACAnwMEAk0DA6oFAAAAggMCAAYDAQMCAwMDBAQADACAAwUAEAYBGAAAAAAAAQAAAAABAQAAAAAAAAAAAAAAEQAAAAAEAAABAgAVowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgL/AgEAAAAAAMADCAASAAEAMAMC5gkAAACCAgIACgMHBAAAAEADCAMJAwoEAABAQAMLAwwGAAMGAQABAAEYAAMAAAAAAAMAAAAAAAADAAYAAAAHAQAAAAABuucmVlkCx4zYIO8RKR4Npsr/MSKII0xX

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return {
	XZ = function(vector3: Vector3, vector3_2: Vector3) -- line: 16
		-- upvalues: Asserts (copy)
		Asserts.Vector3(vector3)
		Asserts.Vector3(vector3_2)

		local v5 = vector3 - vector3_2

		return Vector3.new(v5.X, 0.0, v5.Z).Magnitude
	end
}

