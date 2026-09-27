-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMYBVRvSFNWBG1hdGgFY2xhbXAGQ29sb3IzB2Zyb21IU1YQYWRqdXN0QnJpZ2h0bmVzcwRQbGF5DElubGV0VGV4dHVyZQ5GaW5kRmlyc3RDaGlsZAxEZWZhdWx0Q29sb3IMR2V0QXR0cmlidXRlC0ltYWdlQ29sb3IzDFNldEF0dHJpYnV0ZQZTRU5TT1IHVUlTY2FsZQlUd2VlbkluZm8DbmV3BkNyZWF0ZQpNb3VzZUVudGVyB0Nvbm5lY3QKTW91c2VMZWF2ZQRnYW1lDFR3ZWVuU2VydmljZQpHZXRTZXJ2aWNlAAUJAgAAAAASvAIAzQAAAACfAgIEQwYEAYwHAACMCAEATC4AAqQFAwAACBCAnwUEAlIEBQCkBQYAABRAgFIGAgBSBwMAUggEAJ8FBACCBQAABwMBAwIDAwQACBCAAwQDBQQAFECAAAMGARgAAAABAAAAAAAAAAEAAAAAAAAEAAAAAAIAAQAAAAX7AAAAvAAA7gAAAACfAAIBggABAAEDBwAaAAEYAAAAAAEbAAAAAAIAAQAAAAX7AAAAvAAA7gAAAACfAAIBggABAAEDBwAdAAEYAAAAAAEeAAAAAA4BAQAAAFZvAwAAqQQBALwBAAMBAAAAnwEEAm8EAgC8AgASAwAAAJ8CAwIrAgYAbwQCAE0FAQAEAAAAvAIALgUAAACfAgQBbwQCALwCABIDAAAAnwIDArwDAs0GAAAAnwMCBJUHBQeMCAAAjAkBAEwuAAKkBgoAACSAgJ8GBAJSBQYApAYNAAAwsIBSBwMAUggEAFIJBQCfBgQCbwkOAKkKAQC8BwADAQAAAJ8HBAJvCg8AqQsBALwIAAMBAAAAnwgEAfsIAABSCgEApAsSAABEAIFvDBMAnwsCAuIMFAAwBgwABAAAALwICJYVAAAAnwgFAvsJAABSCwEApAwSAABEAIFvDRMAnwwCAuINFAAwAg0ABAAAALwJCZYVAAAAnwkFAk0KBxQWAAAA2QwAABIACAC8CgrHFwAAAJ8KAwFNCgfdGAAAANkMAQASAAkAvAoKxxcAAACfCgMBggcCABkDCAMJAwoDCwMMAw0DAQKamZmZmZm5PwMCAwMEACSAgAMEAwUEADCwgAMOAw8DEAMRBABEAIECAAAAAAAA0D8FAQQDEgMTAxQDFQIBAgkAARgAAAAAAAEAAAAAAQAAAAAAAgAAAAEAAAEAAAAAAAAAAQAAAAAAAQAAAAABAAAAAAEAAAAAAAABAP8AAAMAAAAAAAABAP8AAAMAAAAAAAADAAAAAAAAAwoAAAAAAwAAAQIAC6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLAAQQAwAIFABIAAACCAgIABgMWBAAAAEADFwMYBgAGAwIAAwEAARgAAAAAAAAAAgYAAAEAAAAABIcWxi9Qv8IREdrzAL61hgz3DtFbtdKsLg==

-- decompilation:
local TweenService = game:GetService("TweenService")

local function adjustBrightness(p1, p2) -- line: 3
	local v5, v6, v7 = p1:ToHSV()
	local v8 = math.clamp(v7 + p2, 0.0, 1.0)

	return Color3.fromHSV(v5, v6, v8)
end

return function(p3) -- line: 9
	-- upvalues: TweenService (copy)
	local InletTexture = p3:FindFirstChild("InletTexture", true)

	if not p3:GetAttribute("DefaultColor") then
		p3:SetAttribute("DefaultColor", InletTexture.ImageColor3)
	end

	local DefaultColor = p3:GetAttribute("DefaultColor")
	local v12, v13, v14 = DefaultColor:ToHSV()
	local v15 = math.clamp(v14 + 0.1, 0.0, 1.0)
	local color3 = Color3.fromHSV(v12, v13, v15)
	local SENSOR = p3:FindFirstChild("SENSOR", true)

	p3:FindFirstChild("UIScale", true)

	local tween = TweenService:Create(InletTexture, TweenInfo.new(0.25), {
		ImageColor3 = color3
	})
	local tween2 = TweenService:Create(InletTexture, TweenInfo.new(0.25), {
		ImageColor3 = DefaultColor
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

