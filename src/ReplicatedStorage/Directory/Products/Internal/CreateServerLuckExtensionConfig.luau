-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZB3JlcXVpcmULQ29udHJvbGxlcnMKU2VydmVyTHVjawhHZXRTdGF0ZQpNdWx0aXBsaWVyClNlcnZlclRlc3QHQWRkVGltZQhDYWxsYmFjawZzdHJpbmcGbnVtYmVyCVByb2R1Y3RJZAtEaXNwbGF5TmFtZRNMb2NrV2hpbGVQcm9jZXNzaW5nE0Rpc2FibGVOb3RpZmljYXRpb24EZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlE1NlcnZlclNjcmlwdFNlcnZpY2UHTGlicmFyeQdBc3NlcnRzBnNjcmlwdAhQcm9kdWN0cxFGaW5kRmlyc3RBbmNlc3RvcgVUeXBlcwlJbnRlcmZhY2UABAYBAQAABgMAAAUBBxOkAQEAAAAAQPsCAABNAgLHAgAAAE0CAsMDAAAAnwECAk0CAXYEAAAAnwIBAk0EAgYFAAAAjAUBALcFAgAEAAAAqQMAAakDAQCCAwIABgMBBAAAAEADAgMDAwQDBQAOBgEYAAAAAAAAAAABAAABAAAAAAAAAA8AAAAABQECAAAGAwAABQEHD6QBAQAAAABA+wIAAE0CAscCAAAATQICwwMAAACfAQICTQIB9QQAAAD7BAEAWwMEBVIEAACfAgMAggIAAAYDAQQAAABAAwIDAwMHAgAAAAAAAE5AABQIARgAAAAAAAAAAAEAAAAAAAAVAAAAAAYDAgAACAUAAAUDAwICHvsDAABNAwNBAAAAAFIEAACfAwIB+wMAAE0DA2ABAAAAUgQBAJ8DAgH7AwAATQMDYAEAAABSBAIAnwMCAcADAgASAgEA2QQBABICAQASAAIA4gUKADABBQsDAAAAMAAFVwQAAAAwAwWNCAAAADAEBUYJAAAAggUCAAsDCQMKBgADCwMMAw0BAQMOAwYDCAgGA/////8E/////wUGAAAABwYAAAAI/////wn/////AgABCQABGAAAAAAAAQAAAAABAAAAAAIABgAABQEAAQADAAEAAAoAAAAABwAAAQIAJaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAGoHAAAATQMDiQgAAACfAgICpAMGAAAAUECkBAoAAACQQG8GCwC8BAR8DAAAAJ8EAwJNBATvDQAAAE0EBA8OAAAAnwMCAsAEDwASAAIAEgABAIIEAgAQAw8EAAAAQAMQAxEDEgMBBAAAUEADEwMUAxUEAACQQAMWAxcDGAMZBgIBAgEAARgAAgAAAAAAAQAAAAAAAgAAAAAAAAEAAAAAAAAAAAAAAAACAAAAAQAAAAADk4lWCO9pApIT6Zg88+Bfq+ORQXyhTTwJ

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(script:FindFirstAncestor("Products").Types.Interface)

return function(s1: string, n1: number, n2: number) -- line: 9
	-- upvalues: Asserts (copy), ServerScriptService (copy)
	Asserts.string(s1)
	Asserts.number(n1)
	Asserts.number(n2)

	return {
		LockWhileProcessing = true,
		DisableNotification = true,
		ProductId = n1,
		DisplayName = s1,
		ServerTest = function(_) -- line: 14
			-- upvalues: ServerScriptService (copy)
			return require(ServerScriptService.Controllers.ServerLuck).GetState().Multiplier > 1.0
		end,
		Callback = function(p2) -- line: 20
			-- upvalues: ServerScriptService (copy), n2 (copy)
			return require(ServerScriptService.Controllers.ServerLuck).AddTime(n2 * 60.0, p2)
		end
	}
end

