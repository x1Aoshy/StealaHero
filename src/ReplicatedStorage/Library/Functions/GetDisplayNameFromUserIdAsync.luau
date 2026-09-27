-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWEUdldFBsYXllckJ5VXNlcklkC0Rpc3BsYXlOYW1lGkdldFVzZXJJbmZvc0J5VXNlcklkc0FzeW5jIE1pc3NpbmcgdXNlciBpbmZvIGZvciB1c2VyIGlkICUqBmZvcm1hdAZhc3NlcnQEdHlwZQZzdHJpbmcrSW52YWxpZCBkaXNwbGF5IG5hbWUgcGF5bG9hZCBmb3IgdXNlciBpZCAlKiFFbXB0eSBkaXNwbGF5IG5hbWUgZm9yIHVzZXIgaWQgJSoDZ2V0M0NhY2hlZCBkaXNwbGF5IG5hbWUgbXVzdCBiZSBhIHN0cmluZyBmb3IgdXNlciBpZCAlKgRnYW1lB1BsYXllcnMKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQtVc2VyU2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwpTbWFydENhY2hlA25ldwADCgECAAAGAwAABQECSvsBAABSAwAAvAEBYQAAAACfAQMCDgEEAKkCAQBNAwFXAQAAAIICAwD7AgEA/wQAAAEAAABSBQAAxQQFAgEAAAC8AgLhAgAAAJ8CAwITAwIARwMCAAAAAICpBQABqQUBAG8GAwBSCAAAvAYGjQQAAACfBgMCngEFAwYAAACkBAYAAABQQJ8EAwFNBANXAQAAALsoBANSCAQApAcIAAAAcECfBwIC8AcCAAkAAACpBgABqQYBAG8HCgBSCQAAvAcHjQQAAACfBwMCngEGAwcAAACkBQYAAABQQJ8FAwEcBwQAjAgAALcIAgAHAAAAqQYAAakGAQBvBwsAUgkAALwHB40EAAAAnwcDAp4BBgMHAAAApAUGAAAAUECfBQMBqQUBAFIGBACCBQMADAMBAwIDAwMEAwUDBgQAAFBAAwcEAABwQAMIAwkDCgAMAAEYAAAAAAABAQAAAAMAAAAAAAAAAAEBAAAAAAAAAAAAAAAAAAEAAQAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAANAAAAAAcBAQAABgMAAAUBAiH7AQAATQEBXwAAAABSAgAAxgMAAKkEAQCfAQQCKwEFAPsBAABNAQFfAAAAAFICAACfAQICuygBA1IFAQCkBAIAAAAQQJ8EAgLwBAIAAwAAAKkDAAGpAwEAbwQEAFIGAAC8BASNBQAAAJ8EAwKeAQMDBAAAAKQCBwAAAGBAnwIDAYIBAgAIAwsDBwQAABBAAwgDDAMFAwYEAABgQAAfAAEYAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAABIAAAAAAJAAABAgAoowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCAQAAAABAbwQFALwCAhYDAAAAnwIDAqQDBwAAAGBATQQBaggAAABNBAToCQAAAE0EBDkKAAAAnwMCAk0EA+8LAAAAjAUPAIwGEA6MBzwAwAgMABIAAAASAAIAnwQFAsAFDQASAAQAggUCAA4DDQQAAABAAw4DDwMQAxEDEgQAAGBAAxMDFAMVAxYGAAYBAgABAQABGAADAAAAAAABAAAAAAABAAAAAAADAAAAAAAAAAADAAAAAAAAAAATAAABAAAAAAL2MA9yNHMwPG5bwPjnh7j3higYBsT0ZXM=

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")
local v4 = require(ReplicatedStorage.Library.Modules.SmartCache).new(15.0, 3600.0, 60.0, function(n1: number) -- line: 12
	-- upvalues: Players (copy), UserService (copy)
	local PlayerByUserId = Players:GetPlayerByUserId(n1)

	if PlayerByUserId then
		return true, PlayerByUserId.DisplayName
	end

	local v7 = UserService:GetUserInfosByUserIdsAsync({ n1 })[1.0]

	assert(v7 ~= nil, `Missing user info for user id { n1 }`)

	local DisplayName = v7.DisplayName

	assert(type(DisplayName) == "string", `Invalid display name payload for user id { n1 }`)
	assert(#DisplayName > 0.0, `Empty display name for user id { n1 }`)

	return true, DisplayName
end)

return function(n2: number) -- line: 31
	-- upvalues: v4 (copy)
	local v10 = v4.get(n2, nil, true) or v4.get(n2)

	assert(type(v10) == "string", `Cached display name must be a string for user id { n2 }`)

	return v10
end

