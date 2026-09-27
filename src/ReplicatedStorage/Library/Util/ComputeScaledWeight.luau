-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKBm51bWJlcgRtYXRoA21heBNjb21wdXRlU2NhbGVkV2VpZ2h0BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwACBQIBAAAHBAAABQICAhP7AgAATQICYAAAAABSAwAAnwICAfsCAABNAgJgAAAAAFIDAQCfAgIBgRIBBQEAAABSAwEAbwQBAKQCBAAADCCAnwIDAgkDAAKCAwIABQMBAgAAAAAAAAAAAwIDAwQADCCAAAoEARgAAAAAAAEAAAAAAgAAAAAAAAEACwAAAAADAAABAgARowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgLAAggAEgABAIICAgAJAwUEAAAAQAMGAwcDCAQAAEBAAwkDCgYAAQABAAEYAAMAAAAAAAMAAAAAAAADAAgBAAAAAAGhd7iEj/Z00gjukVBmWEQS0W+v8JOz0oU=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

local function computeScaledWeight(n1: number, n2: number) -- line: 10
	-- upvalues: Asserts (copy)
	Asserts.number(n1)
	Asserts.number(n2)

	return n1 * math.max(n2, 0.0)
end

return computeScaledWeight

