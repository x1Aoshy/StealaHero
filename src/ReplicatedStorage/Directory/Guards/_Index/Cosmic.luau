-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMoBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoOU2xlZXBBbmltYXRpb24NSWRsZUFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbg5BZnRlcldha2VTb3VuZAtBdHRhY2tTb3VuZA1Gb290c3RlcFNvdW5kB0V0ZXJuYWwccmJ4YXNzZXRpZDovLzEyNDc4ODQ1NjE4MDc1MBhHZXRBbmRTZXJpYWxpemVBbmltYXRpb24ccmJ4YXNzZXRpZDovLzEyMDA4MzI4NDE0Nzc2OBxyYnhhc3NldGlkOi8vMTAzMjI2MzcwODEyMDc2G3JieGFzc2V0aWQ6Ly83MzE4NzAyNDIwODA2MAdTb3VuZElkHHJieGFzc2V0aWQ6Ly8xMzU0MTk2MzQ1MTkxNDcGVm9sdW1lC01heERpc3RhbmNlDVBsYXliYWNrU3BlZWQGTG9vcGVkHHJieGFzc2V0aWQ6Ly8xMzY4MDU0NDQ3NjUxMTcccmJ4YXNzZXRpZDovLzEwMzQzNTk1OTg0NzY5ORtyYnhhc3NldGlkOi8vODU4OTIwNTM0ODExMTMAAQsAAAECAGKjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICJAgAAABNAgLhCQAAAJ8BAgKkAgUAAABAQE0DAJEKAAAATQMD8gsAAACfAgICTQIC6AwAAACkAwUAAABAQE0EAJEKAAAATQQERA0AAABNBAQ5DgAAAJ8DAgKkBAUAAABAQKQFBwAAAGBATQUFJAgAAABNBQUkCAAAAE0FBToPAAAATQUF4hAAAACfBAICUgUBAOIGIABNBwImIQAAADAHBvILAAAAbwkiAFIKBAC8BwPpIwAAAJ8HBAIwBwbTGQAAAG8JJABSCgQAvAcD6SMAAACfBwQCMAcG+hoAAABvCSUAUgoEALwHA+kjAAAAnwcEAjAHBsAbAAAAbwkmALwHA+kjAAAAnwcDAjAHBrIcAAAA/wcAAAIAAADiCDEA4gkzAMUHCAMBAAAAMAcGMR0AAADiBzgAMAcGiB4AAADiBz0AMAcGhB8AAACfBQIAggUAAD4DAQQAAABAAwIDAwMEBAAAQEADBQQAAGBAAwYDBwMIAwkDCgMLAwwDDQMOAw8CAAAAAAAAaUADEAIAAAAAAAAQQAMRAgAAAAAAADxAAxICAAAAAADAckADEwMUAxUDFgMXAxgDGQgMC/////8REgAAABMUAAAAFRYAAAAXGAAAABn/////Gv////8b/////xz/////Hf////8e/////x//////AxoDGwMcAx0DHgMfAyADIQMiAgAAAAAAABRAAyMCAAAAAGBPb0ADJAIAAAAAAADwPwMlAQAIBScoAAAAKSoAAAArLAAAAC0uAAAALzAAAAADJggFJzIAAAApKgAAACssAAAALS4AAAAvMAAAAAMnAgAAAAAAAABAAgAAAAAAwGJAAgAAAGC4HvE/CAUnNAAAACk1AAAAKzYAAAAtNwAAAC8wAAAAAygCAAAAAAAA+D8CAAAAAAAATkABAQgFJzkAAAApOgAAACs7AAAALS4AAAAvPAAAAAABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAAAAAAMAAQAAAAgB/gAAAAAFAf4AAAAABQH+AAAAAAQAAAAAAAEAAQcAAPgAEAAABwAA1AABAAAAAABCbb8SJiveqZ8wHjektLqeMnWoZnCp1RM=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 200.0,
	HitDistance = 4.0,
	AnimationBaseWalkSpeed = 28.0,
	HomeImpulseBoostDistanceXZ = 300.0,
	Rarity = Rarities.Eternal,
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://124788456180750", DefaultAnimationConfigLooped),
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://137108472820709", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://90373019857576", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://73187024208060"),
	AfterWakeSound = {
		{
			SoundId = "rbxassetid://135419634519147",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		},
		{
			SoundId = "rbxassetid://136805444765117",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		}
	},
	AttackSound = {
		SoundId = "rbxassetid://103435959847699",
		Volume = 2.0,
		MaxDistance = 150.0,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	},
	FootstepSound = {
		SoundId = "rbxassetid://85892053481113",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

