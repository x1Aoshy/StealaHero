-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcCENvcmVfRk9WDFNldEF0dHJpYnV0ZQ9DaGFuZ2VfRk9WX0NPUkUMR2V0QXR0cmlidXRlD1JldHVybl9Db3JlX0ZPVgRnYW1lCVdvcmtzcGFjZQ1DdXJyZW50Q2FtZXJhBG1hdGgGcmFuZG9tCVR3ZWVuSW5mbwNuZXcERW51bQtFYXNpbmdTdHlsZQRTaW5lD0Vhc2luZ0RpcmVjdGlvbgNPdXQLRmllbGRPZlZpZXcGQ3JlYXRlBFBsYXkGRGVicmlzBFRpbWUHQWRkSXRlbQpDaGFuZ2VfRk9WDFR3ZWVuU2VydmljZQpHZXRTZXJ2aWNlB1BsYXllcnMLTG9jYWxQbGF5ZXIABAUBAQAAAAr7AQAADgEHAA4ABgD7AQAAbwMAAFIEAAC8AQEuAQAAAJ8BBAGCAAEAAgMBAwIABgMBGAAAAAEAAAAAAAIHAAAAAAMAAQAAAAb7AAAAbwIAALwAABIBAAAAnwADAIIAAAACAwEDBAAMBQEYAAAAAAAADQAAAAAKAgIAAAA+pAIBAAAAAEBNAgLKAgAAAE0CAkgDAAAADgI2AJABAQQNAAcABQAAgPsCAABvBAYAvAICEgcAAACfAgMCUgACAKQECwAAKJCAjAVfAIwGaQCfBAMCWwMECAkCAQOkAw4AADTAgFIEAgCkBRIAEUDwwKQGFQAUTPDAjAcAAKkIAACMCQAAnwMHAvsEAQCkBgEAAAAAQE0GBsoCAAAATQYGSAMAAABSBwMA4ggXADAACGEWAAAAvAQElhgAAACfBAUCvAUE7hkAAACfBQIBpAUBAAAAAEBNBQWdGgAAAFIHBABNCANKGwAAALwFBXgcAAAAnwUEAYIAAQAdAwYEAAAAQAMHAwgCAAAAAAAA4D8CAAAAAACAUUADAQMEAnsUrkfheoQ/AwkDCgQAKJCAAwsDDAQANMCAAw0DDgMPBBFA8MADEAMRBBRM8MADEgUBFgMTAxQDFQMWAxcAEBgBGAAAAAAAAAABAQABAAAAAAACAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAEAAAEAAAAAAAAAAAACEQAAAAAHAAABAgAiowAAAP8AAwAAAAAApAEBAAAAAEBvAwIAvAEBFgMAAACfAQMCpAIBAAAAAEBNAgJQBAAAAE0CAjEFAAAAbwUGAIwGRgC8AwIuBwAAAJ8DBAHAAwgAEgACADADAF4JAAAAwAMKABIAAgAwAwDxCwAAAMADDAASAAIAEgABADADAD0NAAAAggACAA4DBgQAAABAAxkDGgMbAxwDAQMCBgADAwYBAwUGAgMYAwABAgEAARgAAAABAAAAAAABAAAAAAABAAAAAAIAAAAGAAAABAAAAAAOAQAAAAADiduCV8SPlgF5sdINbyK4U/nDlSO7H+hW

-- decompilation:
local t1 = {}
local TweenService = game:GetService("TweenService")
local LocalPlayer = game.Players.LocalPlayer

LocalPlayer:SetAttribute("Core_FOV", 70.0)

function t1.Change_FOV_CORE(p1) -- line: 6
	-- upvalues: LocalPlayer (copy)
	if LocalPlayer and p1 then
		LocalPlayer:SetAttribute("Core_FOV", p1)
	end
end
function t1.Return_Core_FOV() -- line: 12
	-- upvalues: LocalPlayer (copy)
	return LocalPlayer:GetAttribute("Core_FOV")
end
function t1.Change_FOV(p2, p3) -- line: 16
	-- upvalues: LocalPlayer (copy), TweenService (copy)
	if game.Workspace.CurrentCamera then
		local v7 = p3 or 0.5

		if p2 == 70.0 then
			p2 = LocalPlayer:GetAttribute("Core_FOV")
		end

		local v8 = v7 * (math.random(95.0, 105.0) * 0.01)
		local tweenInfo = TweenInfo.new(v8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.0, false, 0.0)
		local tween = TweenService:Create(game.Workspace.CurrentCamera, tweenInfo, {
			FieldOfView = p2
		})

		tween:Play()
		game.Debris:AddItem(tween, tweenInfo.Time)
	end
end

return t1

