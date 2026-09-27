-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWCFBvc2l0aW9uCkZyZWVMZW5ndGgLUGFyZW50SW5kZXgKQ3JlYXRlQm9uZQZleHBlY3QJTWFnbml0dWRlAnRvBWVxdWFsCENhbGxiYWNrBUJvbmVzAml0HFNob3VsZCBsaW1pdCB0byAlKiBzdHVkcyAjJSoGZm9ybWF0BG1hdGgGcmFuZG9tCGRlc2NyaWJlE0Rpc3RhbmNlIENvbnN0cmFpbnQHcmVxdWlyZQZzY3JpcHQGUGFyZW50EkRpc3RhbmNlQ29uc3RyYWludAxXYWl0Rm9yQ2hpbGQABQQDAAAAAAjiAwMAMAADOwAAAAAwAQN+AQAAADACA80CAAAAggMCAAQDAQMCAwMFAwABAgADBAEYAAEAAQABAAAEAAAAAAQAAwAAABj7AAAA+wEBAPsCAQBNAgI7AAAAAPsDAgCfAAQCpAECAAAAEEBNAgCqAwAAAJ8BAgJNAQGSBAAAAE0BAXsFAAAA+wIBAE0CAn4GAAAAnwECAfsBAQAwAAE7AAAAAIIAAQAHAwEDBQQAABBAAwYDBwMIAwIAFgkBGAAAAAAAAAACAAAAAAAAAAAAAAAAAgAAARcAAAAACgACAAAAIPsBAABNAQF4AAAAABMAAQHZAQAAEgIBABIAAAASAgAAjAQBAIwCCgCMAwEAqAITAKQFAgAAABBAbwYDAE0IAH4EAAAAUgkEALwGBo0FAAAAnwYEAlIHAQCfBQMBpAUIAAAcYICMBgEAjAcUAJ8FAwIwBQB+BAAAAIsC7f+CAAEACQMKAwsEAAAQQAMMAwIDDQMOAw8EABxggAEBEwABGAAAAAACAAAACAAAAAEAAAAAAAAAAAAAAQAAAAAAAP4EFAAAAAAEAAEAAAAR4gABAP8BAAACAAAA4gIIAOIDCwDFAQIDAQAAADABAHgAAAAApAENAAAAwEBvAg4A2QMAABIAAAASAgAAnwEDAYIAAQAPAwoFAQADAQcAAAAAAAAAAAAAAAAAAAAAAwICAAAAAAAACEADAwIAAAAAAAAAAAgDAgMAAAAEBQAAAAYHAAAABwAAAAAAAIA/AAAAAAAAAAACAAAAAAAA8D8IAwIJAAAABAUAAAAGCgAAAAMQBAAAwEADEQECCwABGAgBAPcAAAAJAAYAAAAAAAAQBAAAAAAEAAABAgAQowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAG8DBQC8AQHTBgAAAJ8BAwCfAAACwAEHAMACCAASAAAAggICAAkDEgQAAABAAxMEAAAgQAMUAxUDFgYABgMCAAMBAAEYAAAAAAAAAAAAAAAAAggAAAEAAAAABCtNTx+vQGPG0SpmDNIJDuNbVVhrGYklHg==

-- decompilation:
local DistanceConstraint = require(script.Parent:WaitForChild("DistanceConstraint"))

local function CreateBone(p1, p2, p3) -- line: 3
	return {
		Position = p1,
		FreeLength = p2,
		ParentIndex = p3
	}
end

return function() -- line: 11
	-- upvalues: DistanceConstraint (copy)
	local t1 = {
		Bones = {
			{
				Position = Vector3.new(0.0, 0.0, 0.0),
				FreeLength = 3.0,
				ParentIndex = 0.0
			},
			{
				Position = Vector3.new(0.0, 1.0, 0.0),
				FreeLength = 3.0,
				ParentIndex = 1.0
			}
		}
	}

	describe("Distance Constraint", function() -- line: 19
		-- upvalues: t1 (copy), DistanceConstraint (copy)
		local v7 = t1.Bones[2.0]

		local function Callback() -- line: 22
			-- upvalues: DistanceConstraint (copy), v7 (copy), t1 (copy)
			local v10 = DistanceConstraint(v7, v7.Position, t1)

			expect(v10.Magnitude).to.equal(v7.FreeLength)
			v7.Position = v10
		end

		for i = 1.0, 10.0 do
			it(`Should limit to { v7.FreeLength } studs #{ i }`, Callback)
			v7.FreeLength = math.random(1.0, 20.0)
		end
	end)
end

