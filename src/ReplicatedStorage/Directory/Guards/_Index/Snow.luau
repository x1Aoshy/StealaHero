-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMoBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoNSWRsZUFuaW1hdGlvbg5TbGVlcEFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbg5BZnRlcldha2VTb3VuZAtBdHRhY2tTb3VuZA1Gb290c3RlcFNvdW5kCUxlZ2VuZGFyeRtyYnhhc3NldGlkOi8vODI2MzY2NjU2ODU4MTYYR2V0QW5kU2VyaWFsaXplQW5pbWF0aW9uHHJieGFzc2V0aWQ6Ly8xMjI3NDg5NzgzNDU0ODQccmJ4YXNzZXRpZDovLzEyMTQ2MDQ4NTU1MDU2NBtyYnhhc3NldGlkOi8vNzUxNDMzOTQ1NTk1OTQHU291bmRJZBtyYnhhc3NldGlkOi8vOTMxNDM0NTU4Njc4NTAGVm9sdW1lC01heERpc3RhbmNlDVBsYXliYWNrU3BlZWQGTG9vcGVkG3JieGFzc2V0aWQ6Ly84NDA2NzAzNjU0MDYwNBxyYnhhc3NldGlkOi8vMTAxMTg1NDk5MzIxMTE3G3JieGFzc2V0aWQ6Ly84NjkyMzI3MjE3MzgzMgABCwAAAQIAYqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgIkCAAAAE0CAuEJAAAAnwECAqQCBQAAAEBATQMAkQoAAABNAwPyCwAAAJ8CAgJNAgLoDAAAAKQDBQAAAEBATQQAkQoAAABNBAREDQAAAE0EBDkOAAAAnwMCAqQEBQAAAEBApAUHAAAAYEBNBQUkCAAAAE0FBSQIAAAATQUFOg8AAABNBQXiEAAAAJ8EAgJSBQEA4gYgAE0HArkhAAAAMAcG8gsAAABvCSIAUgoEALwHA+kjAAAAnwcEAjAHBvoZAAAAbwkkAFIKBAC8BwPpIwAAAJ8HBAIwBwbTGgAAAG8JJQBSCgQAvAcD6SMAAACfBwQCMAcGwBsAAABvCSYAvAcD6SMAAACfBwMCMAcGshwAAAD/BwAAAgAAAOIIMQDiCTMAxQcIAwEAAAAwBwYxHQAAAOIHOAAwBwaIHgAAAOIHPQAwBwaEHwAAAJ8FAgCCBQAAPgMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHAwgDCQMKAwsDDAMNAw4DDwIAAAAAAIBYQAMQAgAAAAAAAAhAAxECAAAAAAAAPkADEgIAAAAAAMBnQAMTAxQDFQMWAxcDGAMZCAwL/////xESAAAAExQAAAAVFgAAABcYAAAAGf////8a/////xv/////HP////8d/////x7/////H/////8DGgMbAxwDHQMeAx8DIAMhAyICAAAAAAAAFEADIwIAAAAAYE9vQAMkAgAAAAAAAPA/AyUBAAgFJygAAAApKgAAACssAAAALS4AAAAvMAAAAAMmCAUnMgAAACkqAAAAKywAAAAtLgAAAC8wAAAAAycCAAAAAAAAAEACAAAAAADAYkACAAAAYLge8T8IBSc0AAAAKTUAAAArNgAAAC03AAAALzAAAAADKAIAAAAAAAD4PwIAAAAAAABOQAEBCAUnOQAAACk6AAAAKzsAAAAtLgAAAC88AAAAAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAAAAwABAAAACAH+AAAAAAUB/gAAAAAFAf4AAAAABAAAAAAAAQABBwAA+AAQAAAHAADUAAEAAAAAAKGQF82YBdYMRKvKKQKnTUDRiAC5k1R9zA==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 102.0,
	HitDistance = 3.0,
	AnimationBaseWalkSpeed = 30.0,
	HomeImpulseBoostDistanceXZ = 190.0,
	Rarity = Rarities.Legendary,
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://82636665685816", DefaultAnimationConfigLooped),
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://122748978345484", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://80916124797143", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://75143394559594"),
	AfterWakeSound = {
		{
			SoundId = "rbxassetid://93143455867850",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		},
		{
			SoundId = "rbxassetid://84067036540604",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		}
	},
	AttackSound = {
		SoundId = "rbxassetid://101185499321117",
		Volume = 2.0,
		MaxDistance = 150.0,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	},
	FootstepSound = {
		SoundId = "rbxassetid://86923272173832",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

