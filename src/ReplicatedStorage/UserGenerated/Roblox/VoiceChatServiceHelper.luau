-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMgHElzVm9pY2VFbmFibGVkRm9yVXNlcklkQXN5bmMIQ2FsbGJhY2sRR2V0UGxheWVyQnlVc2VySWQGRGVsZXRlBlVzZXJJZAR0YXNrBWRlbGF5C0xvY2FsUGxheWVyCEdldEFzeW5jB0ludGVnZXIIT3B0aW9uYWwHQm9vbGVhbgNHZXQEZ2FtZQdQbGF5ZXJzCkdldFNlcnZpY2UQVm9pY2VDaGF0U2VydmljZQdyZXF1aXJlEVJlcGxpY2F0ZWRTdG9yYWdlDVVzZXJHZW5lcmF0ZWQLQ29uY3VycmVuY3kFQ2FjaGUETGFuZwdBc3NlcnRzA25ldwlBc3NlcnRLZXkGTWF4QWdlDlBsYXllclJlbW92aW5nB0Nvbm5lY3QFc3Bhd24FdGFibGUGZnJlZXplAAYEAQEAAAQAAQAPBvsBAABSAwAAvAEB+gAAAACfAQMAggEAAAEDAQAbAgEYAAAAAAAAHAAAAAADAAMAAAYAAwAPDw8M+wAAAPsCAQC8AABhAAAAAJ8AAwIrAAUA+wACAPsCAQC8AABRAQAAAJ8AAwGCAAEAAgMDAwQAJQABGAAAAAAAAAEAAAAAAiYAAAAABQECAAAJAAIBDw8PAQALC00BAOYAAAAApAIDAAAIEICMAzwA2QQAABICAAASAAEAEgIBAJ8CAwGCAAEABAMFAwYDBwQACBCAAQEiAAEYAAABAAAAAAAAAAUkAAAAAAMAAgAABQACAA8PCvsAAAD7AgEATQICMQAAAABNAgLmAQAAALwAAFACAAAAnwADAYIAAQADAwgDBQMJACsAARgAAAAAAAAAAAABLAAAAAAFAgIAAAkEAgAFAgKBDw8b+wIAAE0CAkMAAAAAUgMAAJ8CAgH7AgAATQICcQEAAAD7AwAATQMDHgIAAACfAgICUgMBAJ8CAgEOAQYA+wIBAFIEAAC8AgJ/AwAAAJ8CAwCCAgAA+wIBAFIEAAC8AgJQBAAAAJ8CAwCCAgAABQMKAwsDDAMNAwkAMQEBGAAAAAAAAQAAAAAAAAAAAQEAAAAAAAIAAAAAADIAAAAACAAAAQMbAAAGDwABTA8BB0YPAg1ADwMaMw8EJyYPBUEMTaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQKQDAQAAAABATQMDPwcAAABNAwPgCAAAAE0DA2YJAAAATQMDgwoAAACfAgICpAMGAAAAUECkBAEAAAAAQE0EBD8HAAAATQQE4AgAAABNBAS+CwAAAE0EBIkMAAAAnwMCAk0EAu8NAAAA4gUSAMAGEwASAAEAMAYFRg4AAABNBgNDFAAAADAGBc0PAAAAnwQCAk0FANQVAAAAwAcWABIAAAASAAQAvAUFxxcAAACfBQMBpAUaAABkgIHABhsAEgAEABIAAACfBQIB/wUBAAAAAADABhwAEgADABIABAAwBgX6HQAAAKQGIAAAfOCBUgcFAJ8GAgCCBgAAIQMOBAAAAEADDwMQAxEDEgQAAFBAAxMDFAMVAxYDFwMYAxkDAgMaAxsCAAAAAAAA8H8IAw7/////D/////8QEQAAAAYAAwoDHAYCAx0DBgMeBABkgIEGAwYEAwEDHwMgBAB84IEEAAIDBAEAARgAEwAAAAAAAQAAAAAAAgAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAACAAABAAAAAwAAAPwIAAAAAAAAAAkAAAAAAAQAAgAAAAAJAAAAAAEAAAAABftNGWyW1itJW/6uYiTuDUGLVQ4YyYlzbQ==

-- decompilation:
--!native
local Players = game:GetService("Players")
local VoiceChatService = game:GetService("VoiceChatService")
local Cache = require(game.ReplicatedStorage.UserGenerated.Concurrency.Cache)
local Asserts = require(game.ReplicatedStorage.UserGenerated.Lang.Asserts)
local v5 = Cache.new({
	MaxAge = 1e999,
	Callback = function(p1) -- line: 27
		-- upvalues: VoiceChatService (copy)
		return VoiceChatService:IsVoiceEnabledForUserIdAsync(p1)
	end,
	AssertKey = Asserts.Integer
})

Players.PlayerRemoving:Connect(function(player) -- line: 34
	-- upvalues: Players (copy), v5 (copy)
	local UserId = player.UserId

	task.delay(60.0, function() -- line: 37
		-- upvalues: Players (copy), UserId (copy), v5 (copy)
		if not Players:GetPlayerByUserId(UserId) then
			v5:Delete(UserId)
		end
	end)
end)
task.spawn(function() -- line: 43
	-- upvalues: v5 (copy), Players (copy)
	v5:GetAsync(Players.LocalPlayer.UserId)
end)

local t1 = {
	IsVoiceEnabledForUserIdAsync = function(n1: number, b1: boolean?) -- line: 49
		-- upvalues: Asserts (copy), v5 (copy)
		Asserts.Integer(n1)
		Asserts.Optional(Asserts.Boolean)(b1)

		if b1 then
			return v5:Get(n1)
		end

		return v5:GetAsync(n1)
	end
}

return table.freeze(t1)

