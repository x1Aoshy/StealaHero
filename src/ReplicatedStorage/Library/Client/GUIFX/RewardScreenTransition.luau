-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMkB0Rlc3Ryb3kEUGxheQZzY3JpcHQISW5zdGFuY2UDbmV3BUZyYW1lBVVEaW0yCWZyb21TY2FsZQRTaXplFkJhY2tncm91bmRUcmFuc3BhcmVuY3kGQ29sb3IzB2Zyb21SR0IQQmFja2dyb3VuZENvbG9yMwZQYXJlbnQJVHdlZW5JbmZvBEVudW0LRWFzaW5nU3R5bGUFUXVpbnQPRWFzaW5nRGlyZWN0aW9uA091dAZDcmVhdGUJQ29tcGxldGVkBE9uY2UJd29ya3NwYWNlDUN1cnJlbnRDYW1lcmELRmllbGRPZlZpZXcEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlDFR3ZWVuU2VydmljZQdyZXF1aXJlB0xpYnJhcnkFQXVkaW8GQ2xpZW50BUdVSUZYCUdldEhvbGRlcgAEAgABAAAABfsAAAC8AABQAAAAAJ8AAgGCAAEAAQMBABoAARgAAAAAARsAAAAAAgABAAAABfsAAAC8AADuAAAAAJ8AAgGCAAEAAQMCACgAARgAAAAAASkAAAAADAADAAAAd/sAAABNAADuAAAAAG8BAQCkAgMAAAAgQIwDAQBvBAQAnwAFAfsAAABNAADuAAAAAG8BBQCkAgMAAAAgQIwDAQCMBAEAnwAFAaQACAAAHGCAbwEJAJ8AAgKkAQwAACyggIwCAQCMAwEAnwEDAjABAC8NAAAAjAEAADABADoOAAAApAERAABA8ICMAv8AjAOvAIwEAACfAQQCMAEAnxIAAAD7AQEAnwEBAjABACQTAAAA+wECAFIDAACkBBUAABxAgW8FFgCkBhoAGWBwwaQHHQAcbHDBjAgAAKkJAABvCh4AnwQHAuIFIAC8AQGWIQAAAJ8BBQJNAgEYIgAAANkEAAASAAAAvAICPSMAAACfAgMB+wICAKQEJQAAAEBCTQQESCYAAACkBRUAABxAgW8GJwCkBxoAGWBwwaQIHQAcbHDBjAkAAKkKAABvCx4AnwUHAuIGKgC8AgKWIQAAAJ8CBQL7AwIApAUlAAAAQEJNBQVIJgAAAKQGFQAAHECBjAcBAKQIGgAZYHDBpAkdABxscMGfBgQC4gcsALwDA5YhAAAAnwMFAk0EAhgiAAAA2QYBABIAAwC8BAQ9IwAAAJ8EAwG8BALuAAAAAJ8EAgG8BAHuAAAAAJ8EAgGCAAEALQMCAsDzsua+1tRCAwMEAAAgQAKamZmZmZnpPwJAasGjaqXZQgMEAwUEABxggAMGAwcDCAQALKCAAwkDCgMLAwwEAEDwgAMNAw4DDwQAHECBAmZmZmZmZvY/AxADEQMSBBlgcMEDEwMUBBxscMECmpmZmZmZqT8CAAAAAAAA8D8IAQ4fAAAAAxUDFgMXAxgEAABAQgMZApqZmZmZmdk/AxoCAAAAAAAAWUAIASgpAAAAAgAAAAAAgFFACAEoKwAAAAIAAQwAARgAAAAAAAAAAAABAAAAAAAAAAACAAAAAQAAAAAAAAEAAAEAAAAAAAAAAQAAAAEBAQAAAAAAAAAAAAAB/QAABQAAAAAAAAQBAAAAAQAAAAAAAAAAAAAB/QAABQEAAAABAAAAAAAAAAH9AAAFAAAAAAAAAwAAAgAAAQ0AAAAABQAAAQIAJKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAGoHAAAATQMD0ggAAACfAgICpAMGAAAAUEBNBABqBwAAAE0EBE0JAAAATQQEgQoAAABNBAR3CwAAAJ8DAgLABAwAEgACABIAAwASAAEAggQCAA0DGwQAAABAAxwDHQMeAx8EAABQQAMgAyEDIgMjAyQGAgECAQABGAADAAAAAAABAAAAAAADAAAAAAAAAQAAAAAAAAAAAAADAAAAAAEAAAAAA2X+pN91J7zTCaYIXPjkop4V5rOrVzrO3g==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Audio = require(ReplicatedStorage.Library.Audio)
local GetHolder = require(ReplicatedStorage.Library.Client.GUIFX.GetHolder)

return function() -- line: 12
	-- upvalues: Audio (copy), GetHolder (copy), TweenService (copy)
	Audio.Play(91650233387983.0, script, 1.0, 0.8)
	Audio.Play(112792997660073.0, script, 1.0, 1.0)

	local Frame = Instance.new("Frame")

	Frame.Size = UDim2.fromScale(1.0, 1.0)
	Frame.BackgroundTransparency = 0.0
	Frame.BackgroundColor3 = Color3.fromRGB(255.0, 175.0, 0.0)
	Frame.Parent = GetHolder()

	local tween = TweenService:Create(Frame, TweenInfo.new(1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0.0, false, 0.05), {
		BackgroundTransparency = 1.0
	})

	tween.Completed:Once(function() -- line: 26
		-- upvalues: Frame (copy)
		Frame:Destroy()
	end)

	local tween2 = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0.0, false, 0.05), {
		FieldOfView = 100.0
	})
	local tween3 = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		FieldOfView = 70.0
	})

	tween2.Completed:Once(function() -- line: 40
		-- upvalues: tween3 (copy)
		tween3:Play()
	end)
	tween2:Play()
	tween:Play()
end

