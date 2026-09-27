-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMgCElzU2VydmVyB3JlcXVpcmULQ29udHJvbGxlcnMRQWRtaW5BYnVzZVNlcnZpY2USR2V0U2NoZWR1bGVkRXZlbnRzB0xpYnJhcnkGQ2xpZW50B05ldHdvcmsHTkVUX01BUApBZG1pbkFidXNlBkludm9rZRRHRVRfU0NIRURVTEVEX0VWRU5UUwV0YWJsZQZpbnNlcnQEVHlwZQROYW1lEVNjaGVkdWxlZEV2ZW50S2V5BENtZHIEVXRpbAxNYWtlRW51bVR5cGUQc2NoZWR1bGVFdmVudEtleQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UTU2VydmVyU2NyaXB0U2VydmljZQpSdW5TZXJ2aWNlGmdsb2JhbFJlbW92ZVNjaGVkdWxlZEV2ZW50C0Rlc2NyaXB0aW9uIVNjaGVkdWxlcyBhbiBldmVudCBpbiBhbGwgc2VydmVycwVHcm91cAlNb2RlcmF0b3IEQXJncwACCwEDAAAAQ8YBAAD7AgAAvAICCwAAAACfAgICDgINAKQCAgAAABBA+wMBAE0DA8cDAAAATQMDvAQAAACfAgICTQMC7QUAAACfAwECUgEDAGUAFACkAgIAAAAQQPsDAgBNAwNqBgAAAE0DA00HAAAATQMDUggAAACfAgICTQMC0AkAAABNAwPoCgAAAE0EAjYLAAAATQUDigwAAACfBAICUgEEAP8CAAAAAAAAUgMBAMYEAADGBQAAZAMHAJ40AgUGAAAAUgkCAFIKBgCkCA8AADjQgJ8IAwFuA/j/AQAAAOIDEwBNBACeFAAAAE0EBJ4VAAAATQQEshYAAABvBRcAUgYCAJ8EAwIwBAMREAAAAIIDAgAYAwEDAgQAABBAAwMDBAMFAwYDBwMIAwkDCgMLAwwDDQMOBAA40IADDwMQAxEIAhD/////ERIAAAADEgMTAxQDFQAKAAEYAAIAAAAAAQAAAAAAAAABAAAAAAIAAAAAAAAAAAABAAAAAQAAAAAABAABAAAAAQAAAAAAAP8ABAEAAAAAAAAAAAAAAAsAAAAABgAAAQIAH6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgEAAAAAQG8EBQC8AgIWAwAAAJ8CAwLiAw0A/wQAAAEAAADABQ4AEgACABIAAQASAAAAxQQFAgEAAAAwBAPbDAAAAIIDAgAPAxYEAAAAQAMXAxgDGQMaAxADGwMcAx0DHgMfAyAIBAYHAAAACAkAAAAKCwAAAAz/////BgABAAEAARgAAAAAAAAAAQAAAAAAAQAAAAAAAgQAAQAAAAAA/wAAAQAAAAABWSpyLQW7bGtgqst31A7rmykyZVlr7hgs

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

return {
	Name = "globalRemoveScheduledEvent",
	Description = "Schedules an event in all servers",
	Group = "Moderator",
	Args = { function(p1) -- line: 10
		-- upvalues: RunService (copy), ServerScriptService (copy), ReplicatedStorage (copy)
		local v5

		if RunService:IsServer() then
			v5 = require(ServerScriptService.Controllers.AdminAbuseService).GetScheduledEvents()
		else
			local Network = require(ReplicatedStorage.Library.Client.Network)
			local AdminAbuse = Network.NET_MAP.AdminAbuse

			v5 = Network.Invoke(AdminAbuse.GET_SCHEDULED_EVENTS)
		end

		local t1 = {}

		for v9 in v5 do
			table.insert(t1, v9)
		end

		return {
			Name = "ScheduledEventKey",
			Type = p1.Cmdr.Util.MakeEnumType("scheduleEventKey", t1)
		}
	end }
}

