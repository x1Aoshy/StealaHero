-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBnN0cmluZwlEaXJlY3RvcnkXTWlzc2luZyBhc3NldCBjb25maWcgJSoGZm9ybWF0BmFzc2VydAZSYXJpdHkMUmFyaXR5TnVtYmVyEUZyb21Bc3NldENhdGVnb3J5BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwZBc3NldHMFdGFibGUGZnJlZXplAAIHAQIAAAYDAAAFAQMc+wEAAE0BAUEAAAAAUgIAAJ8BAgH7AgEATQICkQEAAACHAQIARwECAAAAAICpAwABqQMBAG8EAgBSBgAAvAQEjQMAAACfBAMCngEDAwQAAACkAgUAAABAQJ8CAwFNAgHyBgAAAE0CArAHAAAAggICAAgDAQMCAwMDBAMFBAAAQEADBgMHABIIARgAAAAAAAIAAAABAAAAAAAAAAAAAAAAAAEAAAAAEwAAAAAGAAABAgAhowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgKkAgUAAABAQE0DAJEIAAAATQMDgQkAAACfAgIC/wMBAAAAAADABAoAEgABABIAAgAwBAMnCwAAAKQEDgAANMCAUgUDAJ8EAgCCBAAADwMJBAAAAEADCgMLAwwEAABAQAMNAw4DAgMPBgADCAMQAxEEADTAgAEAAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAMABwAAAAAIAAAAAAEAAAAAAS8BkJR7ddAdqz83PsRtqFdfGYfgHcX6lQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Assets = require(ReplicatedStorage.Directory.Assets)
local t1 = {
	FromAssetCategory = function(s1: string) -- line: 18
		-- upvalues: Asserts (copy), Assets (copy)
		Asserts.string(s1)

		local v6 = Assets.Directory[s1]

		assert(v6 ~= nil, `Missing asset config { s1 }`)

		return v6.Rarity.RarityNumber
	end
}

return table.freeze(t1)

