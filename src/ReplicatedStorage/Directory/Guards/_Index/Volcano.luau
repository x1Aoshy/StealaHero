-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMpBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlEUVnZ1BpY2t1cERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoNSWRsZUFuaW1hdGlvbg5TbGVlcEFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbg5BZnRlcldha2VTb3VuZAtBdHRhY2tTb3VuZA1Gb290c3RlcFNvdW5kBk15dGhpYxxyYnhhc3NldGlkOi8vMTI4NjcwMzkxMzQ2MzI4GEdldEFuZFNlcmlhbGl6ZUFuaW1hdGlvbhxyYnhhc3NldGlkOi8vMTA2MTE4NzczNTg3NjUyHHJieGFzc2V0aWQ6Ly8xMDIyOTg5ODIzOTEzNjAbcmJ4YXNzZXRpZDovLzg2Mjc2ODQzOTY2Nzc4B1NvdW5kSWQbcmJ4YXNzZXRpZDovLzc2NzUzMDE3MDM4MDY3BlZvbHVtZQtNYXhEaXN0YW5jZQ1QbGF5YmFja1NwZWVkBkxvb3BlZBxyYnhhc3NldGlkOi8vMTIyMzgxOTU4NDU5MjcyG3JieGFzc2V0aWQ6Ly83MDg1MDA4NzQxOTQyNhxyYnhhc3NldGlkOi8vMTAzNzM2NjYyODkwMjI0AAELAAABAgBiowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAATQIC4QkAAACfAQICpAIFAAAAQEBNAwCRCgAAAE0DA/ILAAAAnwICAk0CAugMAAAApAMFAAAAQEBNBACRCgAAAE0EBEQNAAAATQQEOQ4AAACfAwICpAQFAAAAQECkBQcAAABgQE0FBSQIAAAATQUFJAgAAABNBQU6DwAAAE0FBeIQAAAAnwQCAlIFAQDiBiIATQcCpCMAAAAwBwbyCwAAAG8JJABSCgQAvAcD6SUAAACfBwQCMAcG+hsAAABvCSYAUgoEALwHA+klAAAAnwcEAjAHBtMcAAAAbwknAFIKBAC8BwPpJQAAAJ8HBAIwBwbAHQAAAG8JKAC8BwPpJQAAAJ8HAwIwBwayHgAAAP8HAAACAAAA4ggyAOIJNADFBwgDAQAAADAHBjEfAAAA4gc5ADAHBoggAAAA4gc+ADAHBoQhAAAAnwUCAIIFAAA/AwEEAAAAQAMCAwMDBAQAAEBAAwUEAABgQAMGAwcDCAMJAwoDCwMMAw0DDgMPAgAAAAAAQFxAAxACAAAAAAAAFEADEQIAAAAAAAAyQAMSAgAAAAAAgEFAAxMCAAAAAACAa0ADFAMVAxYDFwMYAxkDGggNC/////8REgAAABMUAAAAFRYAAAAXGAAAABkaAAAAG/////8c/////x3/////Hv////8f/////yD/////If////8DGwMcAx0DHgMfAyADIQMiAyMDJAIAAAAAYE9vQAMlAgAAAAAAAPA/AyYBAAgFKSoAAAArFAAAACwtAAAALi8AAAAwMQAAAAMnCAUpMwAAACsUAAAALC0AAAAuLwAAADAxAAAAAygCAAAAAAAAAEACAAAAAADAYkACAAAAYLge8T8IBSk1AAAAKzYAAAAsNwAAAC44AAAAMDEAAAADKQIAAAAAAAD4PwIAAAAAAABOQAEBCAUpOgAAACs7AAAALDwAAAAuLwAAADA9AAAAAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAAAAwABAAAACQH+AAAAAAUB/gAAAAAFAf4AAAAABAAAAAAAAQABBwAA+AAQAAAHAADTAAEAAAAAAPON0mlFJAuAfOqvCl+OI3CDlcUdwUm4aA==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 122.0,
	HitDistance = 5.0,
	EggPickupDistance = 18.0,
	AnimationBaseWalkSpeed = 35.0,
	HomeImpulseBoostDistanceXZ = 220.0,
	Rarity = Rarities.Mythic,
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://128670391346328", DefaultAnimationConfigLooped),
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://106118773587652", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://102298982391360", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://86276843966778"),
	AfterWakeSound = {
		{
			SoundId = "rbxassetid://76753017038067",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		},
		{
			SoundId = "rbxassetid://122381958459272",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		}
	},
	AttackSound = {
		SoundId = "rbxassetid://70850087419426",
		Volume = 2.0,
		MaxDistance = 150.0,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	},
	FootstepSound = {
		SoundId = "rbxassetid://103736662890224",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

