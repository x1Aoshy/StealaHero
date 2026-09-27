-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiB0J1bGtHZXQDS2V5J0tleSBtdXN0IGJlIHByb3ZpZGVkIHRvIEZhc3RGbGFncy5HZXQoKQZhc3NlcnQGdHlwZW9mBnN0cmluZwVlcnJvchlLZXkgbXVzdCBiZSBzdHJpbmcgKHdhcyAnAicpB09wdGlvbnMNTWlzc2luZyBLZXk6IAtjdXJyZW50RGF0YQhOdWxsYWJsZQdEZWZhdWx0A0dldARLZXlzEEFkbWluRkZsYWdCeXBhc3MLTG9jYWxQbGF5ZXIGUGxheWVyBGx1YXUGQWRtaW5zBlVzZXJJZAlDYW5CeXBhc3MEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB1BsYXllcnMHTGlicmFyeQxXYWl0Rm9yQ2hpbGQHTW9kdWxlcwdyZXF1aXJlBkZGbGFncwdBc3NlcnRzEGN1cnJlbnREYXRhU2F2ZWQABAQDAAAACAUAAAUDAwOHAqkDAQCCAwIAAAAVAQEYAAAXAAAAAAkBAgAAADJNAgAqAAAAAIEBAgQBAAAAbwMBAKQBAwAAACBAnwEDArssAQNSAwEApAIFAAAAQECfAgIC8AINAAYAAACkAggAAABwQG8ECQC7LAEDUggBAKQHBQAAAEBAnwcCAlIFBwBvBgoAcwMEBp8CAgH7AwAATQMDMgsAAACHAgMBKwIGAKQDCAAAAHBAbwUMAFIGAQBzBAUGnwMCAfsEAQBNBASgDQAAAIcDBAFHAwYAAAAAgE0EApwOAAAAKwQCAE0DAjoPAAAAggMCABADAgMDAwQEAAAgQAMFBAAAQEADBgMHBAAAcEADCAMJAwoDCwMMAw0DDgAwDwEYAAAAAAAAAAABAAAAAAAAAQAAAAAAAAAAAAAAAgAAAAEBAAAAAAACAAAAAQAAAAABAAIxAAAAAAUBBQAABgMAAAUBhzf7AQAATQEBjAAAAABNAQHwAQAAACsBDAD7AQAATQEBfwIAAAD7AgAATQICjAAAAABNAgLwAQAAAJ8BAgIOAQIAqQEAAIIBAgBSAQAAKwEDAPsBAQBNAQExAwAAAFIAAQD7AQIATQEB+QQAAABSAgAAnwECAYEBAAUFAAAAUgIAAG8DBQCkAQcAAABgQJ8BAwH7AgMAhwECAEcBBAAAAAAA+wIDAIcBAgCCAQIAqQEAAPsDBABNAwPWCAAAAE0EAOYJAAAAhwIDBA4CAQCpAQEA+wIDAGoBAgCCAQIACgMQAxEDDwMSAxMDFAMEBAAAYEADFQMWAEAXARgAAAAAAAAAAAAAAAAAAAAAAQADAAAAAAABAAAAAAEAAAAAAAACAAAAAQAAAwEAAAAAAAABAwACQQAAAAAJAAABAgBFowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAm8EBQC8AgDTBgAAAJ8CAwJvBQcAvAMC0wYAAACfAwMCpAQJAAAAgEBNBQMgCgAAAJ8EAgKkBQkAAACAQE0GAGoFAAAATQYGiQsAAACfBQIC4gYQAE0HBDIMAAAAMAcGMgwAAABNBwSMDQAAADAHBowNAAAA/wcAAAAAAAAwBwagDgAAAP8HAAAAAAAAMAcGyw8AAAD/BwAAAAAAAMAIEQAwCAa9EgAAAMAIEwASAAQAEgAGADAIBn8UAAAAwAgVABIABgASAAEAEgAFABIABwASAAQAMAgGchYAAACCBgIAFwMYBAAAAEADGQMaAxsDHAMdAx4DHwQAAIBAAyADIQMKAxADDAMiBQQMDQ4PBgADAQYBAw8GAgMXAwABAgEAARgAAAAAAAAAAQAAAAAAAgAAAAEAAAACAAAAAAEAAAAAAAACAQAAAAEAAAACAAAAAQAAAAMAAwAAGwAAAAAQAAAAAAAAABcBAAAAAAPkzR137yA7338cDwxtSwKwlNUKA9YJd3Y=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules")
local FFlags = require(Modules.FFlags)
local Asserts = require(ReplicatedStorage.Library.Asserts)
local t1 = {
	Options = FFlags.Options,
	Keys = FFlags.Keys,
	currentData = {},
	currentDataSaved = {}
}
local t2 = {}

function t1.BulkGet(_: string, _: string, _) -- line: 21
	return true
end
function t1.Get(p2) -- line: 48
	-- upvalues: FFlags (copy), t1 (copy)
	local v12 = assert(p2.Key, "Key must be provided to FastFlags.Get()")

	if typeof(v12) ~= "string" then
		error("Key must be string (was '" .. typeof(v12) .. "')")
	end

	local v13 = FFlags.Options[v12]

	if not v13 then
		error("Missing Key: " .. v12)
	end

	local v14 = t1.currentData[v12]

	if v14 == nil and not v13.Nullable then
		v14 = v13.Default
	end

	return v14
end
function t1.CanBypass(p3) -- line: 64
	-- upvalues: t1 (copy), Players (copy), Asserts (copy), t2 (copy), FFlags (copy)
	if not t1.Keys.AdminFFlagBypass and t1.Get(t1.Keys.AdminFFlagBypass) then
		return false
	end

	local v16 = p3 or Players.LocalPlayer

	Asserts.Player(v16)
	assert(v16, "luau")

	if t2[v16] ~= nil then
		return t2[v16]
	end

	local v17 = false

	if FFlags.Admins[v16.UserId] then
		v17 = true
	end

	t2[v16] = v17

	return v17
end

return t1

