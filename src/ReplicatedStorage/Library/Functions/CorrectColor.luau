-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUCkJyaWdodG5lc3MHQW1iaWVudA5PdXRkb29yQW1iaWVudANNYXgGQ29sb3IzB2Zyb21SR0IVQ29sb3JDb3JyZWN0aW9uRWZmZWN0FUZpbmRGaXJzdENoaWxkT2ZDbGFzcwdFbmFibGVkClNhdHVyYXRpb24JVGludENvbG9yBGdhbWUITGlnaHRpbmcKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQKVmVjVG9Db2xvcgpDb2xvclRvVmVjEFJvYmxveFNhdHVyYXRpb24AAg0BBAAAAD/7AQAATQEB7QAAAAD7AgEA+wMAAE0DAzoBAAAAnwICAvsEAQD7BQAATQUFmwIAAACfBAIAvAICtAMAAACfAgACjAMAAIwEAAD7BQEApAYGAAAUQICMB/8AjAj/AIwJ/wCfBgQAnwUAAvsGAABvCAcAvAYGuAgAAACfBgMCDgYMAE0HBvAJAAAADgcJAE0DBu0AAAAATQQGigoAAAD7BwEATQgGLAsAAACfBwICUgUHAPsLAQBSDAAAnwsCAgkKCwEJCQoCCQgJBZUJAwwJBwgJ+wgCAPsJAQD7CgMA+wsCAFIMBwCfCwICUgwEAJ8KAwCfCQAAnwgAAIIIAAANAwEDAgMDAwQDBQMGBAAUQIADBwMIAwkDCgMLAgAAAAAAAPA/AAYAARgAAAABAAAAAAAAAAAAAAAAAQEBAAAAAAAAAAEAAAAAAQAAAAEAAQABAAAAAAIAAAAAAAAAAQAAAAAAAAAAAAAHAAAAAAUAAAECACijAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQIC1gkAAACfAQICpAIFAAAAQECkAwcAAABgQE0DAyQIAAAATQMDkwoAAACfAgICpAMFAAAAQECkBAcAAABgQE0EBCQIAAAATQQEbQsAAACfAwICwAQMABIAAAASAAIAEgABABIAAwCCBAIADQMMBAAAAEADDQMOAw8EAABAQAMQBAAAYEADEQMSAxMDFAYAAQABAAEYAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAIAAAAAAAEAAAAAAQflVNNtC5a61JHnUKnd32F3/UOnNSE+0g==

-- decompilation:
local Lighting = game:GetService("Lighting")
local VecToColor = require(script.Parent.VecToColor)
local ColorToVec = require(script.Parent.ColorToVec)
local RobloxSaturation = require(script.Parent.RobloxSaturation)

return function(p1) -- line: 6
	-- upvalues: Lighting (copy), ColorToVec (copy), VecToColor (copy), RobloxSaturation (copy)
	local LightingBrightness = Lighting.Brightness
	local v7 = ColorToVec(Lighting.Ambient):Max(ColorToVec(Lighting.OutdoorAmbient))
	local n1 = 0.0
	local n2 = 0.0
	local v10 = ColorToVec(Color3.fromRGB(255.0, 255.0, 255.0))
	local ColorCorrectionEffect = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")

	if ColorCorrectionEffect and ColorCorrectionEffect.Enabled then
		n1 = ColorCorrectionEffect.Brightness
		n2 = ColorCorrectionEffect.Saturation
		v10 = ColorToVec(ColorCorrectionEffect.TintColor)
	end

	local v12 = ColorToVec(p1) * LightingBrightness * v7 * v10 * (n1 + 1.0)

	return VecToColor(ColorToVec(RobloxSaturation(VecToColor(v12), n2)))
end

