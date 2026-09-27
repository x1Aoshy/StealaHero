-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWCUludmVudG9yeQ5FcXVpcHBlZEFzc2V0cwZ0eXBlb2YFdGFibGUHUmViaXJ0aAZudW1iZXIKR2FtZXBhc3NlcwhQcm9kdWN0cwZpcGFpcnMLRGVzZXJpYWxpemUHR2V0UmF0ZQRtYXRoA21heBJHZXRUb3RhbEZvclByb2ZpbGUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQRVdGlsE0Fzc2V0R2VuZXJhdGlvblV0aWwWQXNzZXRJdGVtU2VyaWFsaXphdGlvbgACFQICAAAHBAAABQIHD11NAgFgAAAAAE0DAfUBAAAAuywCA1IFAgCkBAMAAAAgQJ8EAgLwBAgABAAAgLssAwNSBQMApAQDAAAAIECfBAIC8AQDAAQAAACMBAAAggQCAE0GAdYFAAAAuywGAqQFAwAAACBAnwUCAvAFBAAGAACATQQB1gUAAABlAAEAjAQAAE0HATwHAAAAuywHAqQGAwAAACBAnwYCAvAGBAAEAACATQUBPAcAAABlAAEAxgUAAE0IAUEIAAAAuywIAqQHAwAAACBAnwcCAvAHBAAEAACATQYBQQgAAABlAAEAxgYAAIwHAACkCAoAAACQQFIJAwCfCAIEUQgcAIcNAgy7LA0DUg8NAKQOAwAAACBAnw4CAvAOFQAEAACA+w4AAE0ODk8LAAAAUg8NAJ8OAgL7EAEATRAQVAwAAABSEQ4AUhIEAFITBQBSFAYAnxAFAoESEAQNAAAAbxENAKQPEAAAPOCAnw8DAkMHBw9uCOP/AgAAgIIHAgARAwEDAgMDBAAAIEADBAMFAwYDBwMIAwkEAACQQAMKAwsCAAAAAAAAAAADDAMNBAA84IAAEQ4BGAAAAQABAAAAAAAAAAAAAAAAAAEAAgAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQEAAAAAAQEAAAAAAAABAAAAAAEAAAAAAAAAAAAAAAAAAPwABxIAAAAABQAAAQIAIaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICngcAAABNAgK3CAAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMDngcAAABNAwPACQAAAJ8CAgL/AwEAAAAAAMAECgASAAIAEgABADAEAzULAAAAggMCAAwDDwQAAABAAxADEQMSBAAAQEADEwMUAxUDFgYAAw4BAAEAARgAAwAAAAAAAwAAAAAAAAAAAQAAAAAAAAAAAwAGAAAAABQBAAAAAAGS8gV+4b/9P0zTrVjNjVEU4uoSCqA2b38=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetGenerationUtil = require(ReplicatedStorage.Library.Util.AssetGenerationUtil)
local AssetItemSerialization = require(ReplicatedStorage.Library.Util.AssetItemSerialization)

-- Steal a Hero: treadmill SpeedPower multiplies hero income (10 SP = x1, 100 = x2, 1000 = x3).
-- Mirrors ServerScriptService.Controllers.AssetService (speedPowerFactor + per-hero rounding),
-- which is authoritative; keep both identical so the $/s shown matches what is paid.
local function speedPowerFactor(p1)
	local speedPower = tonumber(p1 and p1.SpeedPower) or 10.0

	if speedPower ~= speedPower or speedPower == math.huge or speedPower == -math.huge then
		speedPower = 10.0
	end

	return 1.0 + math.log10(math.max(speedPower, 10.0) / 10.0)
end

-- One hero's $/s as AssetService pays it: GetRate result x SpeedPower factor, rounded, >= 1.
local function applySpeedPower(rate, p1)
	if typeof(rate) ~= "number" or rate ~= rate or rate <= 0.0 then
		return 0.0
	end

	return math.max(math.round(rate * speedPowerFactor(p1)), 1.0)
end

return {
	SpeedPowerFactor = speedPowerFactor,
	ApplySpeedPower = applySpeedPower,
	GetTotalForProfile = function(_, p2) -- line: 17
		-- upvalues: AssetItemSerialization (copy), AssetGenerationUtil (copy)
		local Inventory = p2.Inventory
		local EquippedAssets = p2.EquippedAssets

		if typeof(Inventory) ~= "table" or typeof(EquippedAssets) ~= "table" then
			return 0.0
		end

		local v8 = typeof(p2.Rebirth) ~= "number" and 0.0 or p2.Rebirth
		local v9 = if typeof(p2.Gamepasses) ~= "table" then nil else p2.Gamepasses
		local v10 = if typeof(p2.Products) ~= "table" then nil else p2.Products
		local n1 = 0.0

		for _, v in ipairs(EquippedAssets) do
			local v14 = Inventory[v]

			if typeof(v14) == "table" then
				local v15 = AssetItemSerialization.Deserialize(v14)

				n1 += applySpeedPower(AssetGenerationUtil.GetRate(v15, v8, v9, v10), p2)
			end
		end

		return n1
	end
}

