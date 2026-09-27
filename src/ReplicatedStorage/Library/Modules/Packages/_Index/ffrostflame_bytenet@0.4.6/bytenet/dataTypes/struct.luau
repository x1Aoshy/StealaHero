-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBXRhYmxlBWNsb25lBHJlYWQFd3JpdGUGc2VydmVyA2FkZAZjbGllbnQLY3VycmVudE5hbWUGYWNjZXNzCnN0cnVjdERhdGEEZ2FtZQpSdW5TZXJ2aWNlCkdldFNlcnZpY2UHcmVxdWlyZQZzY3JpcHQGUGFyZW50Cm5hbWVzcGFjZXMWbmFtZXNwYWNlc0RlcGVuZGVuY2llcwpyZXBsaWNhdGVkBnZhbHVlcwV0eXBlcwhJc1NlcnZlcgAEDQIDAAAHAAABAwsQARekAgIAAAQAgPsDAACfAgICUgMBAPsEAQDGBQAAxgYAAGQECQBNCQh5AwAAAFIKAABSCwMAnwkDA/sMAgCHCwwHagkCC0MDAwpuBPb/AgAAAFIEAgAmBQMBggQDAAQDAQMCBAAEAIADAwBKAwEYAAAAAAECAAAAAQAAAAACAAAC+wAIAABLAAAAAAoBAgAABwAAAQMICAEN+wEAAMYCAADGAwAAZAEGAE0GBdIAAAAA+wkBAIcICQSHBwAInwYCAW4B+f8CAAAAggABAAEDBABZBAEYAAAAAAEAAAAAAP8AA1oAAAAADAEDAAAGAwAABQEERv8BAAAAAAAA/wIAAAAAAAD7AwAA8AMVAAAAAID/AwAAAAAAAIwEAABSBQAAxgYAAMYHAABkBQUAlQQEAWoEAwiHCgAIagoBBGoIAgRuBfr/AQAAAPsFAQBNBQW/AgAAAFIGAwCfBQIBZQAeAPsDAADwAxwAAwAAgPsDAQBNAwO/AgAAAFIEAACfAwIB+wMBAE0DA14EAAAAnwMBAvsEAgBNBAQiBQAAAFIFAwCfBAICvAUEeQYAAACfBQICpAYIAAAAcEDGBwAAxggAAGQGAwCHCwAJagsBCmoJAgpuBvz/AgAAAOIDCgDZBAAAEgAAABIAAQASAAIAMAQDeQYAAADZBAEAEgABABIAAgAwBAPSCQAAAIIDAgALAwUCAAAAAAAA8D8DBgMHAwgDCQMDAwoEAABwQAMEBQIGCQIAAQ0AARgAAAEAEQAAAQADAQAAAAEBAwAB+gAKAAAAAAABAAACAAAAAAIAAAACAAAAAAEAAAUAAAAAAQAB/gAGAQAAAAAADwAAAAAAFQAAAAAHAAABAgA4owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAATQICRAkAAABNAgKGCgAAAJ8BAgKkAgUAAABAQKQDBwAAAGBATQMDJAgAAABNAwMkCAAAAE0DA48LAAAATQMDwgwAAACfAgICpAMFAAAAQECkBAcAAABgQE0EBCQIAAAATQQEJAgAAABNBAQPDQAAAJ8DAgK8BQALDgAAAJ8FAgIOBQIAbwQPAGUAAQBvBBAAwAURABIABAASAAEAEgACAIIFAgASAwsEAAAAQAMMAw0DDgQAAEBAAw8EAABgQAMQAxEDEgMTAxQDFQMWAwUDBwYCAQIBAAEYAAAAAAAAAAIAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAACAAAAAAAABgAAAAABAAAAAANSUy2CVteSAMEeM6866D9nIks69mCXR4M=

-- decompilation:
local RunService = game:GetService("RunService")
local namespacesDependencies = require(script.Parent.Parent.namespaces.namespacesDependencies)
local values = require(script.Parent.Parent.replicated.values)

require(script.Parent.Parent.types)

local v4 = not RunService:IsServer() and "client" or "server"

return function(t1: {[any]: any}) -- line: 13
	-- upvalues: v4 (copy), namespacesDependencies (copy), values (copy)
	local t2 = {}
	local t3 = {}

	if v4 == "server" then
		local t4 = {}
		local n1 = 0.0

		for v10 in t1 do
			n1 += 1.0
			t4[v10] = n1
			t2[n1] = t1[v10]
			t3[n1] = v10
		end

		namespacesDependencies.add(t4)
	elseif v4 == "client" then
		namespacesDependencies.add(t1)

		local v11 = namespacesDependencies.currentName()

		values.access(v11):read()

		for v12, v13 in structData do
			t2[v13] = t1[v12]
			t3[v13] = v12
		end
	end

	return {
		read = function(p1, p2) -- line: 74
			-- upvalues: t1 (copy), t2 (copy), t3 (copy)
			local v16 = table.clone(t1)
			local v17 = p2

			for v18, v19 in t2 do
				local v20, v21 = v19.read(p1, v17)

				v16[t3[v18]] = v20
				v17 += v21
			end

			return v16, v17 - p2
		end,
		write = function(p3) -- line: 89
			-- upvalues: t2 (copy), t3 (copy)
			for v23, v24 in t2 do
				v24.write(p3[t3[v23]])
			end
		end
	}
end

