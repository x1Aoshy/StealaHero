-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBkNvbG9yMwdmcm9tUkdCBExlcnALbWFrZUxpZ2h0ZXIQQmFja2dyb3VuZENvbG9yMwpUZXh0QnV0dG9uClRleHRDb2xvcjMJVGV4dExhYmVsC0ltYWdlQ29sb3IzCkltYWdlTGFiZWwLSW1hZ2VCdXR0b24FRnJhbWUOU2Nyb2xsaW5nRnJhbWUNVmlld3BvcnRGcmFtZQlDbGFzc05hbWUTZmluZENvbG9yRnJvbU9iamVjdA1Db2xvclNlcXVlbmNlA25ldxVDb2xvclNlcXVlbmNlS2V5cG9pbnQIR3JhZGllbnQOU2V0T2Zmc2V0U3BlZWQLU2V0Um90YXRpb24HRWZmZWN0cwdyZXF1aXJlBnNjcmlwdAZQYXJlbnQBAQAECAIAAAAHBAAABQJAAgukBAIAAAQAgIwF/wCMBv8AjAf/AJ8EBAJSBQEAvAIAXwMAAACfAgQAggIAAAQDAQMCBAAEAIADAwAEBAEYAAAAAAAAAAAAAAAFAAAAAAcBAAAABgMAAAUBByT/AQQAAAAAAG8CAAAwAgFsAQAAAG8CAgAwAgGaAwAAAG8CBAAwAgEvBQAAAG8CBAAwAgEXBgAAAG8CAAAwAgGdBwAAAG8CAAAwAgH+CAAAAG8CAAAwAgF0CQAAAE0EANsKAAAAhwMBBIcCAAMOAgEAggICAKQDDQAAMLCAjAT/AIwF/wCMBv8AnwMEAIIDAAAOAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwMBAwIEADCwgAAIEAEYAAABAAABAAABAAABAAABAAABAAABAAADAAAAAQEEAAAAAAAACQAAAAAOBAIAAAkGAAAFBAcCAkBGUgQDACsEAwD7BAAAUgUAAJ8EAgJSAwQAUgQDAFIGAwCkCQIAAAQAgIwK/wCMC/8AjAz/AJ8JBAJvCgMAvAcGXwQAAACfBwQCUgUHAFIGAwCkBwcAABhQgP8IAAADAAAApAkJAAAYgICMCgAAUgsEAJ8JAwKkCgkAABiAgG8LCgBSDAUAnwoDAqQLCQAAGICAjAwBAFINBgCfCwMAxQgJAAEAAACfBwIC+wgBAE0ICD0LAAAATQgI7wYAAABSCQAAUgoHAIwLAACfCAQCWwsBDIwMAQC8CQhaDQAAAJ8JBAGMCzwAjAwBALwJCFEOAAAAnwkEAeIJEAD/CgAAAQAAAFILCADFCgsCAQAAADAKCZcPAAAAggkCABEDAQMCBAAEAIACnKc65Ga42j8DAwMRAxIEABhQgAMTBAAYgIACAAAAAAAA4D8DFAIzMzMzMzPjPwMVAxYDFwUBDwAcAAEYGAAAAAAAAwHkAAAAAAAAAAAAAB0CAAAAAQAAAAABAAAAAAEAAAAAAAD9BgAAAAAAAAAAAQAAAAABAAAAAAEBAAAAAAAAAAUAAAAABAAAAQIAEKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAJ8AAgLAAQUAwAIGAMADBwASAAIAEgAAAIIDAgAIAxgEAAAAQAMZBAAAIEADGgYABgEGAgMAAQIBAAEYAAAAAAAAAAAAAAMEFAAAAAEAAAAAAwKFbHbe3hvHi5lPRmgYnXNynXsCMEEGdw==

-- decompilation:
local Parent = require(script.Parent.Parent)

local function makeLighter(color3: Color3, n1: number) -- line: 4
	return color3:Lerp(Color3.fromRGB(255.0, 255.0, 255.0), n1)
end
local function findColorFromObject(p1) -- line: 8
	local v7 = p1[({
		TextButton = "BackgroundColor3",
		TextLabel = "TextColor3",
		ImageLabel = "ImageColor3",
		ImageButton = "ImageColor3",
		Frame = "BackgroundColor3",
		ScrollingFrame = "BackgroundColor3",
		ViewportFrame = "BackgroundColor3"
	})[p1.ClassName]]

	if v7 then
		return v7
	end

	return Color3.fromRGB(255.0, 255.0, 255.0)
end

return function(p2, n2: number, _: number, color3: Color3) -- line: 28
	-- upvalues: findColorFromObject (copy), Parent (copy)
	local v12 = color3 or findColorFromObject(p2)
	local v13 = v12:Lerp(Color3.fromRGB(255.0, 255.0, 255.0), 0.417505)
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, v12),
		ColorSequenceKeypoint.new(0.5, v13),
		ColorSequenceKeypoint.new(1.0, v12)
	})
	local v15 = Parent.Gradient.new(p2, colorSequence, 0.0)

	v15:SetOffsetSpeed(n2 * 0.6, 1.0)
	v15:SetRotation(60.0, 1.0)

	return {
		Effects = { v15 }
	}
end

