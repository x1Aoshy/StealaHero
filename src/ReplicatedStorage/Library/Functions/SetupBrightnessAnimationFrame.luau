-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBVRvSFNWBG1hdGgFY2xhbXAGQ29sb3IzB2Zyb21IU1YQYWRqdXN0QnJpZ2h0bmVzcwRQbGF5DERlZmF1bHRDb2xvcgxHZXRBdHRyaWJ1dGUQQmFja2dyb3VuZENvbG9yMwxTZXRBdHRyaWJ1dGUGU0VOU09SDkZpbmRGaXJzdENoaWxkB1VJU2NhbGUJVHdlZW5JbmZvA25ldwZDcmVhdGUKTW91c2VFbnRlcgdDb25uZWN0Ck1vdXNlTGVhdmUEZ2FtZQxUd2VlblNlcnZpY2UKR2V0U2VydmljZQAFCQIAAAAAErwCAM0AAAAAnwICBEMGBAGMBwAAjAgBAEwuAAKkBQMAAAgQgJ8FBAJSBAUApAUGAAAUQIBSBgIAUgcDAFIIBACfBQQAggUAAAcDAQMCAwMEAAgQgAMEAwUEABRAgAADBgEYAAAAAQAAAAAAAAABAAAAAAAABAAAAAACAAEAAAAF+wAAALwAAO4AAAAAnwACAYIAAQABAwcAGgABGAAAAAABGwAAAAACAAEAAAAF+wAAALwAAO4AAAAAnwACAYIAAQABAwcAHQABGAAAAAABHgAAAAAPAgEAAABSbwQAALwCABIBAAAAnwIDAisCBgBvBAAATQUAnwIAAAC8AgAuAwAAAJ8CBAFvBAAAvAIAEgEAAACfAgMCkAMBBLwEAs0FAAAAnwQCBEMIBgOMCQAAjAoBAEwuAAKkBwgAABxggJ8HBAJSBgcApAcLAAAokIBSCAQAUgkFAFIKBgCfBwQCbwoMAKkLAQC8CAADDQAAAJ8IBAJvCw4AqQwBALwJAAMNAAAAnwkEAfsJAABSCwAApAwRAABA8IBvDRIAnwwCAuINEwAwBw2fAgAAALwJCZYUAAAAnwkFAvsKAABSDAAApA0RAABA8IBvDhIAnw0CAuIOEwAwAg6fAgAAALwKCpYUAAAAnwoFAk0LCBQVAAAA2Q0AABIACQC8CwvHFgAAAJ8LAwFNCwjdFwAAANkNAQASAAoAvAsLxxYAAACfCwMBgggCABgDCAMJAwoDCwKamZmZmZm5PwMBAwIDAwQAHGCAAwQDBQQAKJCAAwwDDQMOAw8DEAQAQPCAAgAAAAAAANA/BQECAxEDEgMTAxQCAQIJAAEYAAAAAAABAAAAAAACAAAAAQEAAAEAAAAAAAAAAQAAAAAAAQAAAAABAAAAAAEAAAAAAAABAP8AAAMAAAAAAAABAP8AAAMAAAAAAAADAAAAAAAAAwoAAAAAAwAAAQIAC6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLAAQQAwAIFABIAAACCAgIABgMVBAAAAEADFgMXBgAGAwIAAwEAARgAAAAAAAAAAgYAAAEAAAAABIkh6EXFh2twNpHxYZvxsRH5Of8xu+WCRA==

-- decompilation:
local TweenService = game:GetService("TweenService")

local function adjustBrightness(p1, p2) -- line: 3
	local v5, v6, v7 = p1:ToHSV()
	local v8 = math.clamp(v7 + p2, 0.0, 1.0)

	return Color3.fromHSV(v5, v6, v8)
end

return function(p3, p4) -- line: 9
	-- upvalues: TweenService (copy)
	if not p3:GetAttribute("DefaultColor") then
		p3:SetAttribute("DefaultColor", p3.BackgroundColor3)
	end

	local DefaultColor = p3:GetAttribute("DefaultColor")
	local v12 = p4 or 0.1
	local v13, v14, v15 = DefaultColor:ToHSV()
	local v16 = math.clamp(v15 + v12, 0.0, 1.0)
	local color3 = Color3.fromHSV(v13, v14, v16)
	local SENSOR = p3:FindFirstChild("SENSOR", true)

	p3:FindFirstChild("UIScale", true)

	local tween = TweenService:Create(p3, TweenInfo.new(0.25), {
		BackgroundColor3 = color3
	})
	local tween2 = TweenService:Create(p3, TweenInfo.new(0.25), {
		BackgroundColor3 = DefaultColor
	})

	SENSOR.MouseEnter:Connect(function() -- line: 26
		-- upvalues: tween (copy)
		tween:Play()
	end)
	SENSOR.MouseLeave:Connect(function() -- line: 29
		-- upvalues: tween2 (copy)
		tween2:Play()
	end)

	return SENSOR
end

