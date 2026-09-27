-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBFBsYXkGU0VOU09SDkZpbmRGaXJzdENoaWxkB1VJU2NhbGUFU2NhbGUJVHdlZW5JbmZvA25ldwZDcmVhdGUQTW91c2VCdXR0b24xRG93bgdDb25uZWN0Dk1vdXNlQnV0dG9uMVVwCk1vdXNlRW50ZXIKTW91c2VMZWF2ZQRnYW1lDFR3ZWVuU2VydmljZQpHZXRTZXJ2aWNlAAYCAAEAAAAF+wAAALwAAO4AAAAAnwACAYIAAQABAwEADQABGAAAAAABDgAAAAACAAEAAAAF+wAAALwAAO4AAAAAnwACAYIAAQABAwEAEAABGAAAAAABEQAAAAACAAEAAAAF+wAAALwAAO4AAAAAnwACAYIAAQABAwEAEwABGAAAAAABFAAAAAACAAEAAAAF+wAAALwAAO4AAAAAnwACAYIAAQABAwEAFgABGAAAAAABFwAAAAAOAgEAAABTbwQAAKkFAQC8AgADAQAAAJ8CBAJvBQIAqQYBALwDAAMBAAAAnwMEApABAQNNBAOEBAAAAIwHAQBDBgcBCQUEBvUHBQEJBgQH+wcAAFIJAwCkCggAABxggG8LCQCfCgIC4gsKADAFC4QEAAAAvAcHlgsAAACfBwUC+wgAAFIKAwCkCwgAABxggG8MCQCfCwIC4gwKADAGDIQEAAAAvAgIlgsAAACfCAUC+wkAAFILAwCkDAgAABxggG8NCQCfDAIC4g0KADAEDYQEAAAAvAkJlgsAAACfCQUCTQoCYQwAAADZDAAAEgAIALwKCscNAAAAnwoDAU0KAjIOAAAA2QwBABIABwC8CgrHDQAAAJ8KAwFNCgIUDwAAANkMAgASAAcAvAoKxw0AAACfCgMBTQoC3RAAAADZDAMAEgAJALwKCscNAAAAnwoDAYICAgARAwIDAwMEApqZmZmZmak/AwUCAAAAAAAA8D8DBgMHBAAcYIACAAAAAAAA0D8FAQQDCAMJAwoDCwMMAw0EAAECAwMAARgAAAAAAAEAAAAAAQEAAQAAAQABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAABAAAAAAAAAwAAAAAAAAMAAAAAAAADAAAAAAAAAwQAAAAAAwAAAQIACqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLAAQQAEgAAAIIBAgAFAw4EAAAAQAMPAxAGBAEEAQABGAAAAAAAAAACAAABAAAAAAVuXsTsxTuRIUxzBorBTaTrHkbTmFyaru0=

-- decompilation:
local TweenService = game:GetService("TweenService")

return function(p1, p2) -- line: 3
	-- upvalues: TweenService (copy)
	local SENSOR = p1:FindFirstChild("SENSOR", true)
	local UIScale = p1:FindFirstChild("UIScale", true)
	local v6 = p2 or 0.05
	local UIScaleScale = UIScale.Scale
	local v8 = UIScaleScale * (1.0 + v6)
	local v9 = UIScaleScale * (1.0 - v6)
	local tween = TweenService:Create(UIScale, TweenInfo.new(0.25), {
		Scale = v8
	})
	local tween2 = TweenService:Create(UIScale, TweenInfo.new(0.25), {
		Scale = v9
	})
	local tween3 = TweenService:Create(UIScale, TweenInfo.new(0.25), {
		Scale = UIScaleScale
	})

	SENSOR.MouseButton1Down:Connect(function() -- line: 13
		-- upvalues: tween2 (copy)
		tween2:Play()
	end)
	SENSOR.MouseButton1Up:Connect(function() -- line: 16
		-- upvalues: tween (copy)
		tween:Play()
	end)
	SENSOR.MouseEnter:Connect(function() -- line: 19
		-- upvalues: tween (copy)
		tween:Play()
	end)
	SENSOR.MouseLeave:Connect(function() -- line: 22
		-- upvalues: tween3 (copy)
		tween3:Play()
	end)

	return SENSOR
end

