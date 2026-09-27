-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaB3JlcXVpcmULQ29udHJvbGxlcnMKU2VydmVyTHVjawhHZXRTdGF0ZQpNdWx0aXBsaWVyJ1NlcnZlciBhbHJlYWR5IGhhcyBlcXVhbCBvciBiZXR0ZXIgbHVjawpTZXJ2ZXJUZXN0DkhhbmRsZVB1cmNoYXNlCENhbGxiYWNrBnN0cmluZwZudW1iZXIJUHJvZHVjdElkC0Rpc3BsYXlOYW1lE0xvY2tXaGlsZVByb2Nlc3NpbmcTRGlzYWJsZU5vdGlmaWNhdGlvbgRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UTU2VydmVyU2NyaXB0U2VydmljZQdMaWJyYXJ5B0Fzc2VydHMGc2NyaXB0CFByb2R1Y3RzEUZpbmRGaXJzdEFuY2VzdG9yBVR5cGVzCUludGVyZmFjZQAEBQECAAAGAwAABQEHFaQBAQAAAABA+wIAAE0CAscCAAAATQICwwMAAACfAQICTQIBdgQAAACfAgECTQMCBgUAAAD7BAEAfQQEAAMAAACpAwAAbwQGAIIDAwCpAwEAggMCAAcDAQQAAABAAwIDAwMEAwUDBgAOBwEYAAAAAAAAAAABAAABAAAAAAEAAAMADwAAAAAFAQIAAAYDAAAFAQcPpAEBAAAAAED7AgAATQICxwIAAABNAgLDAwAAAJ8BAgJNAgEgBAAAAPsDAQBSBAAAnwIDAakCAQCCAgIABQMBBAAAAEADAgMDAwgAGAkBGAAAAAAAAAAAAQAAAAABABkAAAAABgMCAAAIBQAABQMDAgIf+wMAAE0DA0EAAAAAUgQAAJ8DAgH7AwAATQMDYAEAAABSBAEAnwMCAfsDAABNAwNgAQAAAFIEAgCfAwIB2QMAABICAQASAAIA2QQBABICAQASAAIA4gUJADABBQsCAAAAMAAFVwMAAAAwBAVGBwAAADADBY0IAAAAggUCAAoDCgMLAwwDDQMOAQEDDwMJAwcIBgL/////A/////8EBQAAAAYFAAAAB/////8I/////wIAAQkAARgAAAAAAAEAAAAAAQAAAAACAAAKAAAGAQABAAMAAQAACgAAAAAHAAABAgAlowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCBgAAAFBATQMAagcAAABNAwOJCAAAAJ8CAgKkAwYAAABQQKQECgAAAJBAbwYLALwEBHwMAAAAnwQDAk0EBO8NAAAATQQEDw4AAACfAwICwAQPABIAAgASAAEAggQCABADEAQAAABAAxEDEgMTAwEEAABQQAMUAxUDFgQAAJBAAxcDGAMZAxoGAgECAQABGAACAAAAAAABAAAAAAACAAAAAAAAAQAAAAAAAAAAAAAAAAIAAAABAAAAAANCWiJ8GHfRhTSC7XSW/iltMkI1CHCeSH0=

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
		Callback = function(p1) -- line: 24
			-- upvalues: ServerScriptService (copy), n2 (copy)
			require(ServerScriptService.Controllers.ServerLuck).HandlePurchase(n2, p1)

			return true
		end,
		ServerTest = function(_) -- line: 14
			-- upvalues: ServerScriptService (copy), n2 (copy)
			if require(ServerScriptService.Controllers.ServerLuck).GetState().Multiplier >= n2 then
				return false, "Server already has equal or better luck"
			end

			return true
		end
	}
end

