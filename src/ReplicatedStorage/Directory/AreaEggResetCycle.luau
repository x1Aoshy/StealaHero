-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiCE1vb25JY29uG3JieGFzc2V0aWQ6Ly85MTQ0NjMzNDc4MDE2MAdTdW5JY29uHHJieGFzc2V0aWQ6Ly8xMDA0ODY3NTczMDcyMDcUU2xlZXBJY29uRmFkZVNlY29uZHMXTmlnaHRJY29uRmFkZU91dFNlY29uZHMeTmlnaHRMaWdodGluZ1RyYW5zaXRpb25TZWNvbmRzHk5pZ2h0TGlnaHRpbmdTdGFydERlbGF5U2Vjb25kcxxEYXlMaWdodGluZ1RyYW5zaXRpb25TZWNvbmRzJ1dhbGxDb3VudGRvd25EZWxheUFmdGVyRGF5U3RhcnRzU2Vjb25kcxRXYWxsQ291bnRkb3duU2Vjb25kcyVXYWxsU2VydmVyRW50cnlHdWFyZFN0YXJ0RGVsYXlTZWNvbmRzH1dhbGxFbnRyeVBlbmV0cmF0aW9uQnVmZmVyU3R1ZHMaV2FsbEVudHJ5UmV0dXJuQnVmZmVyU3R1ZHMkV2FsbEVudHJ5Um9sbGJhY2tTYW1wbGVNYXhBZ2VTZWNvbmRzE1RlbGVwb3J0RmFkZVNlY29uZHMXVGVsZXBvcnRGYWRlSG9sZFNlY29uZHMWTXVzaWNUcmFuc2l0aW9uU2Vjb25kcxhMaWdodGluZ01vZGlmaWVyUHJpb3JpdHkNTmlnaHRMaWdodGluZwpOaWdodE11c2ljFERheVRyYW5zaXRpb25Tb3VuZElkB0FtYmllbnQKQnJpZ2h0bmVzcwlDbG9ja1RpbWURQ29sb3JTaGlmdF9Cb3R0b20OQ29sb3JTaGlmdF9Ub3AOT3V0ZG9vckFtYmllbnQGQ29sb3IzB2Zyb21SR0ICSWQGVm9sdW1lBXRhYmxlBmZyZWV6ZQABBgAAAQIALaMAAADiAB4A4gEmAKQCKQAAoHCCjAPSAIwE0gCMBdIAnwIEAjACATofAAAApAIpAACgcIKMAykAjAQyAIwFqwCfAgQCMAIBASMAAACkAikAAKBwgowDmgCMBMwAjAX6AJ8CBAIwAgGOJAAAAKQCKQAAoHCCjANZAIwEawCMBWYAnwIEAjACAZslAAAAMAEAMRoAAADiAS4AMAEAzBsAAACkATEAAMDwglICAACfAQIAggEAADIDAQMCAwMDBAMFApqZmZmZmck/AwYCAAAAAAAA8D8DBwIAAAAAAAAUQAMIAgAAAAAAAABAAwkDCgMLAgAAAAAAAAhAAwwCAAAAAAAA0D8DDQMOAw8DEAMRAxIDEwIAAAAAAABZQAMUAxUDFgAIFAABAAAAAgMAAAAEBQAAAAYHAAAACAkAAAAKCwAAAAwJAAAADQsAAAAODwAAABARAAAAEg8AAAATDwAAABQHAAAAFQUAAAAWBQAAABcHAAAAGBkAAAAa/////xv/////HB0AAAADFwMYAxkCzczMzMzMCEADGgMbAxwIBh//////IA8AAAAhIgAAACP/////JP////8l/////wMdAx4EAKBwggMfAgAAADTlLZ9BAyACAAAAAAAA4D8IAiorAAAALC0AAAADIQMiBADA8IIAAQABGAAJEgEAAAAAAAAAAwAAAAAAAAABAAAAAAAAAAEAAAAAAAAA+gAIAAAHAAAAAAEAAAAAAARE2oh3UrFGvjFbli9T6BR0XM38NoCwiQ==

-- decompilation:
local t1 = {
	MoonIcon = "rbxassetid://91446334780160",
	SunIcon = "rbxassetid://100486757307207",
	SleepIconFadeSeconds = 0.2,
	NightIconFadeOutSeconds = 1.0,
	NightLightingTransitionSeconds = 5.0,
	NightLightingStartDelaySeconds = 2.0,
	DayLightingTransitionSeconds = 5.0,
	WallCountdownDelayAfterDayStartsSeconds = 2.0,
	WallCountdownSeconds = 3.0,
	WallServerEntryGuardStartDelaySeconds = 0.25,
	WallEntryPenetrationBufferStuds = 3.0,
	WallEntryReturnBufferStuds = 3.0,
	WallEntryRollbackSampleMaxAgeSeconds = 1.0,
	TeleportFadeSeconds = 0.2,
	TeleportFadeHoldSeconds = 0.2,
	MusicTransitionSeconds = 1.0,
	LightingModifierPriority = 100.0,
	DayTransitionSoundId = nil,
	NightLighting = {
		Brightness = 3.0,
		ClockTime = 3.1,
		Ambient = Color3.fromRGB(210.0, 210.0, 210.0),
		ColorShift_Bottom = Color3.fromRGB(41.0, 50.0, 171.0),
		ColorShift_Top = Color3.fromRGB(154.0, 204.0, 250.0),
		OutdoorAmbient = Color3.fromRGB(89.0, 107.0, 102.0)
	},
	NightMusic = {
		Id = 130775373.0,
		Volume = 0.5
	}
}

return table.freeze(t1)

