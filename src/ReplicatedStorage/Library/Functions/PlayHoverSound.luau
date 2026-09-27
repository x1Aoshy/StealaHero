-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBG1hdGgGcmFuZG9tDVBsYXliYWNrU3BlZWQHUGxheWluZwZWb2x1bWUMVGltZVBvc2l0aW9uDlBsYXlIb3ZlclNvdW5kBGdhbWUMU291bmRTZXJ2aWNlCkdldFNlcnZpY2UFSG92ZXIAAgcAAQAAABj7AAAAjAIBAKQEAwAACBCAjAXx/4wGDwCfBAMCPgMEAEMBAgMwAQAoBAAAAPsAAACpAQEAMAEATwUAAAD7AAAAjAEBADABAEsGAAAA+wAAAIwBAAAwAQDGBwAAAIIAAQAIAgAAAAAAAFlAAwEDAgQACBCAAwMDBAMFAwYABgcBGAAAAAAAAAAAAAAAAQAAAAEAAAABAAAAAQcAAAAABAAAAQIAEqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwJNAQBQBAAAAP8CAQAAAAAAwAMFABIAAQAwAwI3BgAAAE0DAjcGAAAAggMCAAcDCAQAAABAAwkDCgMLBgADBwEAAQABGAAAAAAAAAABAAIAAgAAAAcAAAEAAAAAAaCoIpaqFQH3StEA6lbq2/PQsDXikmxIlw==

-- decompilation:
local Hover = game:GetService("SoundService").Hover

return ({
	PlayHoverSound = function() -- line: 6
		-- upvalues: Hover (copy)
		Hover.PlaybackSpeed = 1.0 + math.random(-15.0, 15.0) / 100.0
		Hover.Playing = true
		Hover.Volume = 1.0
		Hover.TimePosition = 0.0
	end
}).PlayHoverSound

