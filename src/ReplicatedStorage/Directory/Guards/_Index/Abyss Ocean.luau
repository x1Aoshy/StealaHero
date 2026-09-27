-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMnBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlEUVnZ1BpY2t1cERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoOU2xlZXBBbmltYXRpb24NSWRsZUFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbg5BZnRlcldha2VTb3VuZAtBdHRhY2tTb3VuZAZDb3NtaWMbcmJ4YXNzZXRpZDovLzc5MTIyODc0OTczNTEyGEdldEFuZFNlcmlhbGl6ZUFuaW1hdGlvbhxyYnhhc3NldGlkOi8vMTAyNDAzNzA1NDM3MzgyHHJieGFzc2V0aWQ6Ly8xMjg5NjExODU4NjU0NzgccmJ4YXNzZXRpZDovLzEzODMwNzYxNDU0NzMzNwdTb3VuZElkHHJieGFzc2V0aWQ6Ly8xMDk1MTM2NDcwNDM3NjcGVm9sdW1lC01heERpc3RhbmNlDVBsYXliYWNrU3BlZWQGTG9vcGVkHHJieGFzc2V0aWQ6Ly8xMTI3ODk4OTAwOTc5MjAccmJ4YXNzZXRpZDovLzEwMDMwODY5NjEwMTk1MgABCwAAAQIAX6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQKQCBwAAAGBATQICJAgAAABNAgIkCAAAAE0CAuEJAAAAnwECAqQCBQAAAEBATQMAkQoAAABNAwPyCwAAAJ8CAgJNAgLoDAAAAKQDBQAAAEBATQQAkQoAAABNBAREDQAAAE0EBDkOAAAAnwMCAqQEBQAAAEBApAUHAAAAYEBNBQUkCAAAAE0FBSQIAAAATQUFOg8AAABNBQXiEAAAAJ8EAgJSBQEA4gYhAE0HAgUiAAAAMAcG8gsAAABvCSMAUgoEALwHA+kkAAAAnwcEAjAHBtMbAAAAbwklAFIKBAC8BwPpJAAAAJ8HBAIwBwb6HAAAAG8JJgBSCgQAvAcD6SQAAACfBwQCMAcGwB0AAABvCScAvAcD6SQAAACfBwMCMAcGsh4AAAD/BwAAAgAAAOIIMQDiCTMAxQcIAwEAAAAwBwYxHwAAAOIHOAAwBwaIIAAAAJ8FAgCCBQAAOQMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHAwgDCQMKAwsDDAMNAw4DDwIAAAAAAEBgQAMQAgAAAAAAABRAAxECAAAAAAAAMkADEgIAAAAAAAAxQAMTAgAAAAAAQG9AAxQDFQMWAxcDGAMZCAwL/////xESAAAAExQAAAAVFgAAABcYAAAAGRoAAAAb/////xz/////Hf////8e/////x//////IP////8DGgMbAxwDHQMeAx8DIAMhAyIDIwIAAAAAYE9vQAMkAgAAAAAAAPA/AyUBAAgFKCkAAAAqFAAAACssAAAALS4AAAAvMAAAAAMmCAUoMgAAACoUAAAAKywAAAAtLgAAAC8wAAAAAycCAAAAAAAAAEACAAAAAADAYkACAAAAYLge8T8IBSg0AAAAKjUAAAArNgAAAC03AAAALzAAAAAAAQABGAADAAAAAAADAAAAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAADAAEAAAAJAf4AAAAABgH+AAAAAAUB/gAAAAAEAAAAAAABAAEHAAD4ABAAANkAAQAAAAAAIV56B9MjfK0d3BjUoJVCBVFGbXMTmhAG

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 130.0,
	HitDistance = 5.0,
	EggPickupDistance = 18.0,
	AnimationBaseWalkSpeed = 17.0,
	HomeImpulseBoostDistanceXZ = 250.0,
	Rarity = Rarities.Cosmic,
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://79122874973512", DefaultAnimationConfigLooped),
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://102403705437382", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://128961185865478", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://138307614547337"),
	AfterWakeSound = {
		{
			SoundId = "rbxassetid://109513647043767",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		},
		{
			SoundId = "rbxassetid://112789890097920",
			Volume = 5.0,
			MaxDistance = 250.48046875,
			PlaybackSpeed = 1.0,
			Looped = false
		}
	},
	AttackSound = {
		SoundId = "rbxassetid://100308696101952",
		Volume = 2.0,
		MaxDistance = 150.0,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	}
})

