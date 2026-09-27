-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcCEV4ZWN1dG9yBUdyb3VwB0lzQWRtaW4ISXNTdHVkaW8wWW91IGRvIG5vdCBoYXZlIHBlcm1pc3Npb24gdG8gcnVuIHRoaXMgZnVuY3Rpb24uCUJlZm9yZVJ1bgxSZWdpc3Rlckhvb2sEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlE1NlcnZlclNjcmlwdFNlcnZpY2UKUnVuU2VydmljZQhJc1NlcnZlcgdyZXF1aXJlC0NvbnRyb2xsZXJzEUFkbWluUGFuZWxTZXJ2aWNlB0xpYnJhcnkGQ2xpZW50B05ldHdvcmsHR2xvYmFscwlDb25zdGFudHMLTkVUV09SS19NQVAKQWRtaW5QYW5lbAVGaXJlZBVBRE1JTl9TVEFUVVNfUkVTUE9OU0UHQ29ubmVjdARGaXJlEkNIRUNLX0FETUlOX1NUQVRVUwAGBQECAAAAEk0BAP8AAAAATQIAxAEAAAD7AwAATQMDiAIAAABSBAEAnwMCAisDBQD7AwEAvAMDCgMAAACfAwICDgMBAIIAAQBvAwQAggMCAAUDAQMCAwMDBAMFAAkAARgAAAEAAgAAAAAAAAAAAAABAwAKAAAAAAUBAgAAAAhvAwAAwAQBABICAAASAgEAvAEA7wIAAACfAQQBggABAAMDBgYAAwcBAAgAARgAAAAAAAAACgkAAAAAAQEBAAAGAwAABQEBAt4AAACCAAEAAAAbAAEYAAEcAAAAAAUBAgAAAA5NAQD/AAAAAE0CAMQBAAAA+wMAACsDBQD7AwEAvAMDCgIAAACfAwICDgMBAIIAAQBvAwMAggMCAAQDAQMCAwQDBQAhAAEYAAABAAIAAAAAAAABAwAiAAAAAAUBAgAAAAhvAwAA2QQAABICAAASAgEAvAEA7wEAAACfAQQBggABAAIDBgMHAQMgAAEYAAAAAAAAAAohAAAAAAoAAAECAE6jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIBAAAAAEBvBAUAvAICFgMAAACfAgMCvAMCCwYAAACfAwICDgMLAKQDCAAAAHBATQQBxwkAAABNBAQGCgAAAJ8DAgLABAsAEgADABIAAgCCBAIApAMIAAAAcEBNBABqDAAAAE0EBE0NAAAATQQEUg4AAACfAwICpAQIAAAAcEBNBQBqDAAAAE0FBUsPAAAATQUFBxAAAACfBAICTQUEsxEAAABNBQWwEgAAAKkGAABNBwNLEwAAAE0IBXcUAAAAnwcCAtkJAQASAQb/vAcHxxUAAACfBwMBTQcD3RYAAABNCAXxFwAAAJ8HAgHZBwIAEgEG/xIAAgDBBgAAggcCAMEGAAAYAwgEAAAAQAMJAwoDCwMMAw0DDgQAAHBAAw8DEAYBAxEDEgMTAxQDFQMWAxcDGAMZAxoDGwMcAwECBAEAARgAAAAAAAAAAQAAAAAAAQAAAAAAAgAAAAEAAAAAAAACAAAADQAAAAAAAAAAAQAAAAAAAAAAAQAAAAICAAAAAAAAAAAAAwAAAAACAAAAAAABAAAAAAVGb2urEvhzxVIDOVsx3/nNNnd833SrAao=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	local AdminPanelService = require(ServerScriptService.Controllers.AdminPanelService)

	return function(p1) -- line: 8
		-- upvalues: AdminPanelService (copy), RunService (copy)
		p1:RegisterHook("BeforeRun", function(p2) -- line: 9
			-- upvalues: AdminPanelService (copy), RunService (copy)
			local Executor = p2.Executor
			local _ = p2.Group

			if AdminPanelService.IsAdmin(Executor) or RunService:IsStudio() then
				return
			end

			return "You do not have permission to run this function."
		end)
	end
end

local Network = require(ReplicatedStorage.Library.Client.Network)
local AdminPanel = require(ReplicatedStorage.Library.Globals.Constants).NETWORK_MAP.AdminPanel
local u7 = false

Network.Fired(AdminPanel.ADMIN_STATUS_RESPONSE):Connect(function(b1: boolean) -- line: 27
	-- upvalues: u7 (ref)
	u7 = b1
end)
Network.Fire(AdminPanel.CHECK_ADMIN_STATUS)

return function(p3) -- line: 32
	-- upvalues: u7 (ref), RunService (copy)
	p3:RegisterHook("BeforeRun", function(p4) -- line: 33
		-- upvalues: u7 (ref), RunService (copy)
		local _ = p4.Executor
		local _ = p4.Group

		if u7 or RunService:IsStudio() then
			return
		end

		return "You do not have permission to run this function."
	end)
end

