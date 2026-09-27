-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMoBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoOU2xlZXBBbmltYXRpb24NSWRsZUFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbg5BZnRlcldha2VTb3VuZAtBdHRhY2tTb3VuZA1Gb290c3RlcFNvdW5kBEVwaWMbcmJ4YXNzZXRpZDovLzgwMjU0NDQwNjE3MjcwGEdldEFuZFNlcmlhbGl6ZUFuaW1hdGlvbhxyYnhhc3NldGlkOi8vMTI5ODIyOTQ1MDM0NzczHHJieGFzc2V0aWQ6Ly8xMDI2OTc0MjE3NDQyODQccmJ4YXNzZXRpZDovLzEzNzE1MjYxNzQxMDEyMAdTb3VuZElkHHJieGFzc2V0aWQ6Ly8xMTA5NzE1NzI2NzIwMTEGVm9sdW1lC01heERpc3RhbmNlDVBsYXliYWNrU3BlZWQGTG9vcGVkG3JieGFzc2V0aWQ6Ly83MTEwNTEzNTE0MzI2NxxyYnhhc3NldGlkOi8vMTI3ODUzNTkxNjg4MjIyG3JieGFzc2V0aWQ6Ly85NTQ5MjY2OTQ5MzE1MQABCwAAAQIAYqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgIkCAAAAE0CAuEJAAAAnwECAqQCBQAAAEBATQMAkQoAAABNAwPyCwAAAJ8CAgJNAgLoDAAAAKQDBQAAAEBATQQAkQoAAABNBAREDQAAAE0EBDkOAAAAnwMCAqQEBQAAAEBApAUHAAAAYEBNBQUkCAAAAE0FBSQIAAAATQUFOg8AAABNBQXiEAAAAJ8EAgJSBQEA4gYgAE0HArwhAAAAMAcG8gsAAABvCSIAUgoEALwHA+kjAAAAnwcEAjAHBtMZAAAAbwkkAFIKBAC8BwPpIwAAAJ8HBAIwBwb6GgAAAG8JJQBSCgQAvAcD6SMAAACfBwQCMAcGwBsAAABvCSYAvAcD6SMAAACfBwMCMAcGshwAAAD/BwAAAgAAAOIIMQDiCTMAxQcIAwEAAAAwBwYxHQAAAOIHOAAwBwaIHgAAAOIHPQAwBwaEHwAAAJ8FAgCCBQAAPgMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHAwgDCQMKAwsDDAMNAw4DDwIAAAAAAIBUQAMQAgAAAAAAAAhAAxECAAAAAAAALEADEgIAAAAAAABkQAMTAxQDFQMWAxcDGAMZCAwL/////xESAAAAExQAAAAVFgAAABcYAAAAGf////8a/////xv/////HP////8d/////x7/////H/////8DGgMbAxwDHQMeAx8DIAMhAyICAAAAAAAAFEADIwIAAAAAYE9vQAMkAgAAAAAAAPA/AyUBAAgFJygAAAApKgAAACssAAAALS4AAAAvMAAAAAMmCAUnMgAAACkqAAAAKywAAAAtLgAAAC8wAAAAAycCAAAAAAAAAEACAAAAAADAYkACAAAAYLge8T8IBSc0AAAAKTUAAAArNgAAAC03AAAALzAAAAADKAIAAAAAAAD4PwIAAAAAAABOQAEBCAUnOQAAACk6AAAAKzsAAAAtLgAAAC88AAAAAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAAAAwABAAAACAH+AAAAAAUB/gAAAAAFAf4AAAAABAAAAAAAAQABBwAA+AAQAAAHAADUAAEAAAAAAHqMlDTXYvRAdQ+boXmnEW8KlINASEj+NQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 88.0,
	HitDistance = 3.0,
	AnimationBaseWalkSpeed = 14.0,
	HomeImpulseBoostDistanceXZ = 160.0,
	Rarity = Rarities.Epic,
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://80254440617270", DefaultAnimationConfigLooped),
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://129822945034773", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://88363827497131", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://137152617410120"),
	AfterWakeSound = {
		{
			SoundId = "rbxassetid://110971572672011",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		},
		{
			SoundId = "rbxassetid://71105135143267",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		}
	},
	AttackSound = {
		SoundId = "rbxassetid://127853591688222",
		Volume = 2.0,
		MaxDistance = 150.0,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	},
	FootstepSound = {
		SoundId = "rbxassetid://95492669493151",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

