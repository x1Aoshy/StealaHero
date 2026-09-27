-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTDkZpbmRGaXJzdENoaWxkBlBsYXllcgNJc0EGVXNlcklkFkdldFVzZXJJZEZyb21OYW1lQXN5bmMGdHlwZW9mBm51bWJlcgZhc3NlcnQDZ2V0BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdQbGF5ZXJzB0xpYnJhcnkMV2FpdEZvckNoaWxkB01vZHVsZXMHcmVxdWlyZQpTbWFydENhY2hlA25ldwADBwEBAAAAJPsBAABSAwAAvAEBAwAAAACfAQMCDgEJAG8EAQC8AgH+AgAAAJ8CAwIOAgQAqQIBAE0DAeYDAAAAggIDAPsCAABSBAAAvAIC0wQAAACfAgMCuywCA1IGAgCkBQYAAABQQJ8FAgLwBQIABwAAAKkEAAGpBAEAuwEEAqQDCQAAAIBAnwMCAakDAQBSBAIAggMDAAoDAQMCAwMDBAMFAwYEAABQQAMHAwgEAACAQAAEAAEYAAAAAAABAAAAAAABAAAAAgAAAAABAAAAAAAAAAAAAAAAAQAABQAAAAAFAQEAAAAO+wEAAE0BAV8AAAAAUgIAAMYDAACpBAEAnwEEAisBBQD7AQAATQEBXwAAAABSAgAAnwECAoIBAgABAwkADgABGAAAAAAAAAAAAAAAAAAADwAAAAAIAAABAgAlowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAm8EBQC8AgDTBgAAAJ8CAwJvBAcAvAIC0wYAAACfAgMCpAMJAAAAgEBNBAI5CgAAAJ8DAgJNAwPvCwAAAIwEDwCMBRAOjAY8AMAHDAASAAEAnwMFAsAEDQASAAMAggQCAA4DCgQAAABAAwsDDAMNAw4DDwMQAxEEAACAQAMSAxMGAAYBAgABAQABGAAAAAAAAAABAAAAAAABAAAAAAAAAAEAAAAAAAAAAAAAAAAKAAABAAAAAAK0Cnwv0UBoPbnpbJBfZRzxxBJrW4bOFi4=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules")
local v4 = require(Modules.SmartCache).new(15.0, 3600.0, 60.0, function(p1) -- line: 4
	-- upvalues: Players (copy)
	local p1_2 = Players:FindFirstChild(p1)

	if p1_2 and p1_2:IsA("Player") then
		return true, p1_2.UserId
	end

	local UserIdFromNameAsync = Players:GetUserIdFromNameAsync(p1)

	assert(typeof(UserIdFromNameAsync) == "number")

	return true, UserIdFromNameAsync
end)

return function(p2) -- line: 14
	-- upvalues: v4 (copy)
	return v4.get(p2, nil, true) or v4.get(p2)
end

