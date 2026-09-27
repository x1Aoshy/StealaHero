-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPCEJhc2VQYXJ0BnN0cmluZwZpcGFpcnMLR2V0Q2hpbGRyZW4KU3VyZmFjZUd1aQNJc0EORmluZEZpcnN0Q2hpbGQJR3VpQnV0dG9uA0dldARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMAAgsCAQAABwQAAAUCBwMn+wIAAE0CAmMAAAAAUgMAAJ8CAgH7AgAATQICQQEAAABSAwEAnwICAaQCAwAAACBAvAMAaAQAAACfAwIAnwIABFECEgBvCQUAvAcG/gYAAACfBwMCDgcNAFIJAQCpCgEAvAcGAwcAAACfBwQCRwcHAAAAAABvCggAvAgH/gYAAACfCAMCDggBAIIHAgBuAu3/AgAAgMYCAACCAgIACQMBAwIDAwQAACBAAwQDBQMGAwcDCAAQCQEYAAAAAAABAAAAAAIAAAAAAAABAAAAAAQAAAAAAQAAAAAAAAH5AAsAEQAAAAAEAAABAgAVowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgL/AgEAAAAAAMADCAASAAEAMAMCfwkAAACCAgIACgMKBAAAAEADCwMMAw0EAABAQAMOAw8GAAMJAQABAAEYAAMAAAAAAAMAAAAAAAADAAYAAAASAQAAAAABiI9v5GEG+dfjcsM9DkQwC/iXeJC6SwXl

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return {
	Get = function(p1, s1: string) -- line: 16
		-- upvalues: Asserts (copy)
		Asserts.BasePart(p1)
		Asserts.string(s1)

		for _, child in ipairs(p1:GetChildren()) do
			if not child:IsA("SurfaceGui") then
				continue
			end

			local s1_2 = child:FindFirstChild(s1, true)

			if s1_2 ~= nil and s1_2:IsA("GuiButton") then
				return s1_2
			end
		end

		return nil
	end
}

