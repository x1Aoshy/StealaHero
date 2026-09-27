-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLDEdhbWVTZXR0aW5ncxFTYXZlZFF1YWxpdHlMZXZlbAVWYWx1ZQ1DdXJyZW50Q2FtZXJhBkNGcmFtZQhQb3NpdGlvbglNYWduaXR1ZGUEbWF0aAVjbGFtcAl3b3Jrc3BhY2UMVXNlclNldHRpbmdzAAIJAgIAAAAl+wIAAE0CAq4AAAAATQICBgEAAABNAgLsAgAAAA0CAwAEAACAjAQKAGUAAQBSBAIAPgMEA/sIAQBNCAhICAAAAE0ICIUJAAAATQgIOwoAAAAmBwgBTQcHqgsAAAB4BgcHPgUGBvUEBQWMBwAAjAgBADQuBAQHCAAAUgYEAKQFDgAANMCAnwUEAgkHAAMJBgcFggYCAA8DAQMCAwMCAAAAAAAAJEACAAAAAAAAAAACAAAAAAAA8D8CAAAAAAAAiUACAAAAAAAAaUADBAMFAwYDBwMIAwkEADTAgAAEAAEYAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAEAAAUAAAAAAwAAAQIACqMAAACkAAEAAAAAQKQBAwAAACBAnwEBAsACBAASAAEAEgAAAIICAgAFAwoEAAAAQAMLBAAAIEAGAAEAAQABGAAAAAEAAAIAAAABAAAAAAHiD6g646yeZZjSgH6hN9vkkhe/TtDLwjs=

-- decompilation:
local _workspace = workspace
local v2 = UserSettings()

return function(p1, p2) -- line: 4
	-- upvalues: v2 (copy), _workspace (copy)
	local SavedQualityLevelValue = v2.GameSettings.SavedQualityLevel.Value
	local v6 = ((if SavedQualityLevelValue ~= 0.0 then SavedQualityLevelValue else 10.0)) / 10.0
	local v7 = math.clamp(1.0 - ((_workspace.CurrentCamera.CFrame.Position - p2).Magnitude - 200.0) / 800.0, 0.0, 1.0)

	return p1 * v6 * v7
end

