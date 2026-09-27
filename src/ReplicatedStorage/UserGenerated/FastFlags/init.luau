-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQpSdW5TZXJ2aWNlB3JlcXVpcmUNVXNlckdlbmVyYXRlZAlGYXN0RmxhZ3MPU2hhcmVkRmFzdEZsYWdzCElzQ2xpZW50BkNsaWVudA9DbGllbnRGYXN0RmxhZ3MISXNTZXJ2ZXITU2VydmVyU2NyaXB0U2VydmljZQZTZXJ2ZXIPU2VydmVyRmFzdEZsYWdzBWVycm9yClJ1bkNvbnRleHQAAQcAAAEDFwAABQ8EKhAPAAE/DwEHOQ8CDTMPAxYqQKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAOAHAAAATQMD/wgAAABNAwM6CQAAAJ8CAgLGAwAAvAQBBAoAAACfBAICDgQLAKQEBgAAAFBATQUA4AcAAABNBQVNCwAAAE0FBXYMAAAAnwQCAlIDBACCAwIAvAQBCw0AAACfBAICDgQRAKQEAQAAAABAbwYOALwEBBYDAAAAnwQDAqQFBgAAAFBATQYE4AcAAABNBgbvDwAAAE0GBnMQAAAAnwUCAlIDBQCCAwIApAQSAAAAEEFvBRMAnwQCAYIDAgAUAwEEAAAAQAMCAwMDBAMFBAAAUEADBgMHAwgDCQMKAwsDDAMNAw4DDwMQBAAAEEEDEQABAAEYABMAAAAAAAEAAAAAAAIAAAAAAAAAAAQCAAAAAQAAAAAAAAAAAAABAAAAAQAAAAAAAQAAAAAAAAAAAAACAAAAAwEAAAAAAFRGBiv7bs5CI6PTDxjiCcAkXhFfZoJsKg==

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

require(ReplicatedStorage.UserGenerated.FastFlags.SharedFastFlags)

if RunService:IsClient() then
	return (require(ReplicatedStorage.UserGenerated.Client.ClientFastFlags))
end

if RunService:IsServer() then
	local ServerScriptService = game:GetService("ServerScriptService")

	return (require(ServerScriptService.UserGenerated.Server.ServerFastFlags))
end

error("RunContext")

return nil

