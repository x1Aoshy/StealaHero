-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcCkJyaWdodG5lc3MGQ2FuY2VsBFBsYXkIQWN0aXZhdGUEZ2FtZQxUd2VlblNlcnZpY2UKR2V0U2VydmljZQlXb3Jrc3BhY2UHcmVxdWlyZQZzY3JpcHQHRWZmZWN0cxFGaW5kRmlyc3RBbmNlc3RvcgZQYXJlbnQFVHlwZXMISW5zdGFuY2UDbmV3FUNvbG9yQ29ycmVjdGlvbkVmZmVjdAZDb2xvcjMHZnJvbVJHQglUaW50Q29sb3INQ3VycmVudENhbWVyYQlUd2VlbkluZm8ERW51bQtFYXNpbmdTdHlsZQRTaW5lD0Vhc2luZ0RpcmVjdGlvbgJJbgZDcmVhdGUAAgIAAgAAAA37AAAAjAEKADABAO0AAAAA+wABALwAAKEBAAAAnwACAfsAAQC8AADuAgAAAJ8AAgGCAAEAAwMBAwIDAwASBAEYAAAAAAEAAAABAAAAARMAAAAACwAAAQIAQqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQKQDCAAAAHBAbwUJALwDA3wKAAAAnwMDAk0DAyQLAAAATQMD7wwAAACfAgIB/wIBAAAAAACkAw8AADjQgG8EEACfAwICjAQAADAEA+0RAAAApAQUAABMIIGMBf8AjAb/AIwH/wCfBAQCMAQDLBUAAABNBAFIFgAAADAEAyQLAAAAUgYDAKQHGAAAOHCBjAgBAKQJHAAbaJDBpAofAB50kMGfBwQC4gghALwEAJYiAAAAnwQFAsAFIwASAAMAEgAEADAFAsEkAAAAggICACUDBQQAAABAAwYDBwMIAwkEAABQQAMKBAAAcEADCwMMAw0DDgMPAxAEADjQgAMRAwEDEgMTBABMIIEDFAMVAxYEADhwgQMXAxgDGQQbaJDBAxoDGwQedJDBAgAAAAAAAAAACAERIAAAAAMcBgADBAEAAQABGAAAAAAAAAABAAAAAAACAAAAAAAAAAAAAAAAAgACAAAAAQAAAQAAAAAAAAABAAAAAwAAAAAAAAAAAAAAAAQAAAAABgEAAAAAAXjKyaCyN18fXBjFBTW7T20I0t7USg6joQ==

-- decompilation:
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

require(script:FindFirstAncestor("Effects").Parent.Types)

local t1 = {}
local ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")

ColorCorrectionEffect.Brightness = 0.0
ColorCorrectionEffect.TintColor = Color3.fromRGB(255.0, 255.0, 255.0)
ColorCorrectionEffect.Parent = Workspace.CurrentCamera

local tween = TweenService:Create(ColorCorrectionEffect, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
	Brightness = 0.0
})

function t1.Activate() -- line: 18
	-- upvalues: ColorCorrectionEffect (copy), tween (copy)
	ColorCorrectionEffect.Brightness = 10.0
	tween:Cancel()
	tween:Play()
end

return t1

