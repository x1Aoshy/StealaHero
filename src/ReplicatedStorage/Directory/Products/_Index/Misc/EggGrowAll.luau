-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdBlBsYXllcgdyZXF1aXJlC0NvbnRyb2xsZXJzBEVnZ3MSQ2FuUHVyY2hhc2VHcm93QWxsClNlcnZlclRlc3QHTGlicmFyeQZDbGllbnQHRWdnQ21kcwpDbGllbnRUZXN0D1B1cmNoYXNlR3Jvd0FsbAhDYWxsYmFjawRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UTU2VydmVyU2NyaXB0U2VydmljZQdBc3NlcnRzBnNjcmlwdAhQcm9kdWN0cxFGaW5kRmlyc3RBbmNlc3RvcgVUeXBlcwlJbnRlcmZhY2UJUHJvZHVjdElkC0Rpc3BsYXlOYW1lDUdyb3cgQWxsIEVnZ3MERGVzYx9GaW5pc2ggZ3Jvd2luZyBhbGwgcGxhY2VkIGVnZ3MuE0xvY2tXaGlsZVByb2Nlc3NpbmcTRGlzYWJsZU5vdGlmaWNhdGlvbgAEBAECAAAGAwAABQEHEvsBAABNAQH5AAAAAFICAACfAQIBpAECAAAAEED7AgEATQICxwMAAABNAgJPBAAAAJ8BAgJNAgE2BQAAAFIDAACfAgIAggIAAAYDAQMCBAAAEEADAwMEAwUAEgYBGAAAAAAAAgAAAAAAAAABAAAAABMAAAAAAgABAAAADqQAAQAAAABA+wEAAE0BAWoCAAAATQEBTQMAAABNAQFNBAAAAJ8AAgJNAQA2BQAAAJ8BAQCCAQAABgMCBAAAAEADBwMIAwkDBQAZCgEYAAAAAAAAAAAAAAEAAAAaAAAAAAQBAgAABgMAAAUBBxL7AQAATQEB+QAAAABSAgAAnwECAaQBAgAAABBA+wIBAE0CAscDAAAATQICTwQAAACfAQICTQIBdQUAAABSAwAAnwICAIICAAAGAwEDAgQAABBAAwMDBAMLAB4MARgAAAAAAAIAAAAAAAAAAQAAAAAfAAAAAAgAAAECADGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAwBqBwAAAE0DA4kIAAAAnwICAqQDBgAAAFBApAQKAAAAkEBvBgsAvAQEfAwAAACfBAMCTQQE7w0AAABNBAQPDgAAAJ8DAgLABA8AEgACABIAAQDABRAAEgAAAMAGEQASAAIAEgABAOIHHgAwBAeNGwAAADAFB6UcAAAAMAYHRh0AAACCBwIAHwMNBAAAAEADDgMPAxADAgQAAFBAAwcDEQMSBAAAkEADEwMUAxUDFgYABgEGAgMXAgAAADOb6OpBAxgDGQMaAxsDHAEBAx0DBgMKAwwICBITAAAAFBUAAAAWFwAAABgZAAAAGhkAAAAb/////xz/////Hf////8DAAECAQABGAADAAAAAAABAAAAAAADAAAAAAAAAQAAAAAAAAAAAAAAAAkAAAcABQAACAYAAQABAAABAAAAAAOJ2/RuZ8sWNkWYSCgNTQFg+cPjGrsfnm8=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(script:FindFirstAncestor("Products").Types.Interface)

return {
	ProductId = 3611613592.0,
	DisplayName = "Grow All Eggs",
	Desc = "Finish growing all placed eggs.",
	LockWhileProcessing = true,
	DisableNotification = true,
	ServerTest = function(p1) -- line: 18
		-- upvalues: Asserts (copy), ServerScriptService (copy)
		Asserts.Player(p1)

		return require(ServerScriptService.Controllers.Eggs).CanPurchaseGrowAll(p1)
	end,
	ClientTest = function() -- line: 25
		-- upvalues: ReplicatedStorage (copy)
		return require(ReplicatedStorage.Library.Client.EggCmds).CanPurchaseGrowAll()
	end,
	Callback = function(p2) -- line: 30
		-- upvalues: Asserts (copy), ServerScriptService (copy)
		Asserts.Player(p2)

		return require(ServerScriptService.Controllers.Eggs).PurchaseGrowAll(p2)
	end
}

