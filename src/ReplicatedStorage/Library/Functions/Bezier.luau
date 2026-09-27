-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMBG1hdGgDcG93BXRhYmxlBHBhY2sBbglNYWduaXR1ZGUGaW5zZXJ0B3JlcXVpcmUGc2NyaXB0BlBhcmVudARDb21iDFdhaXRGb3JDaGlsZAADDQEDAAAAIm8BAACMBAAA+wIAAIwDAQCoAhwA+wYBAJUHBAGHBQYH9QYBAPsIAAAmBwgEnhUGBQcAAABSCwYAUgwHAKQKBAAADCCAnwoDAgkJBQqeFQAFBAAAAFILAABSDAQApAoEAAAMIICfCgMCCQgJCvsLAgCVDAQBhwoLDAkJCghDAQEJiwLk/4IBAgAFBwAAAAAAAAAAAAAAAAAAAAACAAAAAAAA8D8DAQMCBAAMIIAADgABGAABAAAAAQAAAQEAAQAAAAAAAAAAAAAAAAAAAAEAAAAA+wcPAAAAAAwAAQEAACujAAAApAACAAAEAIDdAQAAnwAAAk0CAI8EAAAAeAECA4wCAACMBQEAUgMBAIwEAQCoAwgAhwcABZUJBQOHCAAJJgYHCE0GBqoFAAAAQwICBosD+P//AwAAAAAAAIwGAABSBAEAjAUBAKgECgBSCAMA+wkAAFIKAQBSCwYAnwkDAEw0AAKkBwcAABgAgJ8HAAGLBPb/2QQAABIAAQASAAMAEgAAAFIFAgCCBAMACAMDAwQEAAQAgAIAAAAAAADwPwMFAwYDBwQAGACAAQADAAEYAAEAAAABAAABAQAAAAEAAAAAAAD/AwABAAAAAQAAAAAAAAAA/wMAAAALAAMAAAAABAAAAQIAD6MAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABvAwUAvAEB0wYAAACfAQMAnwAAAsABBwASAAAAggECAAgDCAQAAABAAwkEAAAgQAMKAwsDDAYBAQEBAAEYAAAAAAAAAAAAAAAAAgAAAQAAAAACeHVCfOXOXmCoRH4sEqwohQhtVQhKsSh9

-- decompilation:
local Comb = require(script.Parent:WaitForChild("Comb"))

return function(...) -- line: 3
	-- upvalues: Comb (copy)
	local v2 = table.pack(...)
	local v3 = v2.n - 1.0
	local n1 = 0.0

	for i = 1.0, v3 do
		n1 += (v2[i] - v2[i + 1.0]).Magnitude
	end

	local t1 = {}

	for i = 0.0, v3 do
		table.insert(t1, Comb(v3, i))
	end

	return function(p1) -- line: 14
		-- upvalues: v3 (copy), t1 (copy), v2 (copy)
		local vector3 = Vector3.new(0.0, 0.0, 0.0)

		for i = 0.0, v3 do
			local v11 = t1[i + 1.0] * math.pow(1.0 - p1, v3 - i) * math.pow(p1, i)

			vector3 += v2[i + 1.0] * v11
		end

		return vector3
	end, n1
end

