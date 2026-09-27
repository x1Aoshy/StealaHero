-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMeGUV4Y2x1c2l2ZUVnZ1NwYWNpbmdSYWRpdXMXRXhjbHVzaXZlRWdnUmFkaXVzUmFuZ2UWRXhjbHVzaXZlRWdnUmFkaXVzU3RlcBhFeGNsdXNpdmVFZ2dSYWRpdXNCdWZmZXIVRXhjbHVzaXZlRWdnTWF4SGVpZ2h0GEV4Y2x1c2l2ZUVnZ0hlaWdodE9mZnNldBtFeGNsdXNpdmVFZ2dNYXhIZWlnaHRCdWZmZXIMU2V0dGluZ3NJbmZvB1ZlY3RvcjIDbmV3A1NGWAVNdXNpYwdUcmFkaW5nA0FGSw1IaWRlT3RoZXJQZXRzDURpc2FibGVWaWRlb3MLZGlzcGxheU5hbWUNU291bmQgRWZmZWN0cwtkZXNjcmlwdGlvbh9Ub2dnbGUgc291bmQgZWZmZWN0cyBvbiBvciBvZmYuB2RlZmF1bHQHb3B0aW9ucyBUb2dnbGUgbXVzaWMgcGxheWJhY2sgb24gb3Igb2ZmLi9BbGxvdyBvdGhlciBwbGF5ZXJzIHRvIHNlbmQgeW91IHRyYWRlIHJlcXVlc3RzLghBRksgTW9kZTFTdGF5IGluIHRoZSBsb2JieSBhbmQgc2tpcCBNdXJkZXIgTXlzdGVyeSByb3VuZHMuD0hpZGUgT3RoZXIgUGV0cxhIaWRlIG90aGVyIHBsYXllcnMgcGV0cy4ORGlzYWJsZSBWaWRlb3MYRGlzYWJsZSB0cmVhZG1pbGwgdmlkZW8uAAEGAAABAgBbowAAAOIADQCkARAAADzggIwCCACMA2QAnwEDAjABALoCAAAA4gEXAOICHwD/AwIAAAAAAKkEAQCpBQEAagUDBKkEAACpBQAAagUDBDADAtIeAAAAMAIBYREAAADiAiEA/wMCAAAAAACpBAEAqQUBAGoFAwSpBAAAqQUAAGoFAwQwAwLSHgAAADACAX0SAAAA4gIjAP8DAgAAAAAAqQQBAKkFAQBqBQMEqQQAAKkFAABqBQMEMAMC0h4AAAAwAgHXEwAAAOICJwD/AwIAAAAAAKkEAQCpBQEAagUDBKkEAACpBQAAagUDBDADAtIeAAAAMAIBbxQAAADiAioA/wMCAAAAAACpBAEAqQUBAGoFAwSpBAAAqQUAAGoFAwQwAwLSHgAAADACAU8VAAAA4gItAP8DAgAAAAAAqQQBAKkFAQBqBQMEqQQAAKkFAABqBQMEMAMC0h4AAAAwAgF7FgAAADABALYMAAAAggACAC4DAQIAAAAAAAAQQAMCAwMCAAAAAAAA8D8DBAIAAAAAAAAUQAMFAgAAAAAAAC5AAwYCAAAAAAAAJEADBwMICAgAAQAAAAL/////AwQAAAAFBgAAAAcIAAAACQoAAAALBgAAAAz/////AwkDCgQAPOCAAwsDDAMNAw4DDwMQBQYREhMUFRYDEQMSAxMDFAMVAQEDFggEGBkAAAAaGwAAABwdAAAAHv////8DFwgEGBIAAAAaIAAAABwdAAAAHv////8DGAgEGBMAAAAaIgAAABwdAAAAHv////8DGQMaAQAIBBgkAAAAGiUAAAAcJgAAAB7/////AxsDHAgEGCgAAAAaKQAAABwmAAAAHv////8DHQMeCAQYKwAAABosAAAAHCYAAAAe/////wABAAEYAAACAAAAAAAABwEEAAEAAAEAAP4A/AAKBAABAAABAAD+APwACgQAAQAAAQAA/gD8AAkEAAEAAAEAAP4A/AAJBAABAAABAAD+APwACQQAAQAAAQAA/gD8ANAAAAEAAAAAAHkpCrlS0iXxqkRGU73KjQkJMR3NS+1guA==

-- decompilation:
return {
	ExclusiveEggSpacingRadius = 4.0,
	ExclusiveEggRadiusStep = 1.0,
	ExclusiveEggRadiusBuffer = 5.0,
	ExclusiveEggMaxHeight = 15.0,
	ExclusiveEggHeightOffset = 10.0,
	ExclusiveEggMaxHeightBuffer = 5.0,
	ExclusiveEggRadiusRange = Vector2.new(8.0, 100.0),
	-- HEROES owner (Gekko #6): Settings > "Hero Size", how big pen heroes are drawn for this viewer. Not a SettingsInfo
	-- entry on purpose: SettingsCmds and its rows are on/off only. Saved as profile.Settings.HeroSize (one of `order`),
	-- validated by SettingsService; `options` multiply the compressed visual scale of
	-- Library.Modules.AssetHeroSizePresentation (visual only: income keeps using the hero's real Scale).
	HeroSizeInfo = {
		key = "HeroSize",
		displayName = "Hero Size",
		description = "Makes heroes smaller or bigger, only for you!",
		default = "Normal",
		order = { "Small", "Normal", "Big" },
		options = {
			Small = 0.7,
			Normal = 1.0,
			Big = 1.3
		}
	},
	SettingsInfo = {
		SFX = {
			displayName = "Sound Effects",
			description = "Toggle sound effects on or off.",
			default = true,
			options = {
				[true] = true,
				[false] = false
			}
		},
		Music = {
			displayName = "Music",
			description = "Toggle music playback on or off.",
			default = true,
			options = {
				[true] = true,
				[false] = false
			}
		},
		Trading = {
			displayName = "Trading",
			description = "Allow other players to send you trade requests.",
			default = true,
			options = {
				[true] = true,
				[false] = false
			}
		},
		AFK = {
			displayName = "AFK Mode",
			description = "Stay in the lobby and skip Murder Mystery rounds.",
			default = false,
			options = {
				[true] = true,
				[false] = false
			}
		},
		HideOtherPets = {
			displayName = "Hide Other Heroes",
			description = "Hide other players' heroes.",
			default = false,
			options = {
				[true] = true,
				[false] = false
			}
		},
		-- HIDE owner: "Hide Your Heroes" (the local player's own pen heroes; ActiveAssetsController, AssetComponent,
		-- SabVfxController). The key is new, so SettingsService (which whitelists SettingsInfo keys) accepts it and
		-- SettingsCmds defaults it to off for existing profiles.
		HideMyPets = {
			displayName = "Hide Your Heroes",
			description = "Hides your own heroes in your pen.",
			default = false,
			options = {
				[true] = true,
				[false] = false
			}
		},
		-- Owner 2026-09-27: "in settings, a switch to turn off that annoying spam of money numbers, off by default": the
		-- floating "+$" amounts next to the money counter (GUI.MoneyUpdate) only show while this is on.
		ShowMoneyPopups = {
			displayName = "Money Popups",
			description = "Shows the floating +$ amounts when you earn money.",
			default = false,
			options = {
				[true] = true,
				[false] = false
			}
		},
		-- Key kept as DisableVideos (SpeedPhone and TreadmillUI read it); only the text changed.
		DisableVideos = {
			displayName = "Hide Treadmill Phone",
			description = "Keeps the treadmill phone off.",
			default = false,
			options = {
				[true] = true,
				[false] = false
			}
		}
	}
}

