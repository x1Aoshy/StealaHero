-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMqBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlEUVnZ1BpY2t1cERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoOU2xlZXBBbmltYXRpb24NSWRsZUFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbgpTbGVlcFNvdW5kDkFmdGVyV2FrZVNvdW5kC0F0dGFja1NvdW5kDUZvb3RzdGVwU291bmQGU2VjcmV0HHJieGFzc2V0aWQ6Ly8xMzM0MjIzNzQ0NTk0NjMYR2V0QW5kU2VyaWFsaXplQW5pbWF0aW9uG3JieGFzc2V0aWQ6Ly84NTgwNDkyNTA5NTc2NhxyYnhhc3NldGlkOi8vMTE3Mjc0MzEzMzM4MDkwG3JieGFzc2V0aWQ6Ly83MjgxOTkyMTA0MzA3MQdTb3VuZElkHHJieGFzc2V0aWQ6Ly8xMjk0MTY4MDY4Njk5MTQGVm9sdW1lC01heERpc3RhbmNlDVBsYXliYWNrU3BlZWQGTG9vcGVkG3JieGFzc2V0aWQ6Ly83NTY2NDMxNDI1MDg2MhtyYnhhc3NldGlkOi8vOTUxMTYwNzI1MDYyMDYbcmJ4YXNzZXRpZDovLzg2MzkyMzk3NjYxNzQyAAELAAABAgBgowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAATQIC4QkAAACfAQICpAIFAAAAQEBNAwCRCgAAAE0DA/ILAAAAnwICAk0CAugMAAAApAMFAAAAQEBNBACRCgAAAE0EBEQNAAAATQQEOQ4AAACfAwICpAQFAAAAQECkBQcAAABgQE0FBSQIAAAATQUFJAgAAABNBQU6DwAAAE0FBeIQAAAAnwQCAlIFAQDiBiMATQcCZyQAAAAwBwbyCwAAAG8JJQBSCgQAvAcD6SYAAACfBwQCMAcG0xsAAABvCScAUgoEALwHA+kmAAAAnwcEAjAHBvocAAAAbwkoAFIKBAC8BwPpJgAAAJ8HBAIwBwbAHQAAAG8JKQC8BwPpJgAAAJ8HAwIwBwayHgAAAOIHNAAwBwbCHwAAAOIHNwAwBwYxIAAAAOIHOwAwBwaIIQAAAOIHQAAwBwaEIgAAAJ8FAgCCBQAAQQMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHAwgDCQMKAwsDDAMNAw4DDwIAAAAAAABjQAMQAgAAAAAAABRAAxECAAAAAAAAMkADEgIAAAAAAAA+QAMTAgAAAAAAMHFAAxQDFQMWAxcDGAMZAxoDGwgOC/////8REgAAABMUAAAAFRYAAAAXGAAAABkaAAAAG/////8c/////x3/////Hv////8f/////yD/////If////8i/////wMcAx0DHgMfAyADIQMiAyMDJAIAAAAAAAAAAAMlAgAAAGAM3FpAAyYCAAAAAAAA8D8DJwEACAUqKwAAACwtAAAALi8AAAAwMQAAADIzAAAAAygCAAAAAGBPb0AIBSo1AAAALBQAAAAuNgAAADAxAAAAMjMAAAADKQIAAAAAAAAQQAIAAAAAAMByQAgFKjgAAAAsOQAAAC46AAAAMDEAAAAyMwAAAAMqAgAAAAAAAPg/AgAAAAAAAE5AAQEIBSo8AAAALD0AAAAuPgAAADAxAAAAMj8AAAAAAQABGAADAAAAAAADAAAAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAADAAEAAAAJAf4AAAAABQH+AAAAAAUB/gAAAAAEAAAAAAACAAAHAAAHAAAHAADUAAEAAAAAACkTs1I8QtAl8TZa1asOy2lZC6QmG9fZUw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 152.0,
	HitDistance = 5.0,
	EggPickupDistance = 18.0,
	AnimationBaseWalkSpeed = 30.0,
	HomeImpulseBoostDistanceXZ = 275.0,
	Rarity = Rarities.Secret,
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://133422374459463", DefaultAnimationConfigLooped),
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://85804925095766", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://117274313338090", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://72819921043071"),
	SleepSound = {
		SoundId = "rbxassetid://129416806869914",
		Volume = 0.0,
		MaxDistance = 107.4382553100586,
		PlaybackSpeed = 1.0,
		Looped = false
	},
	AfterWakeSound = {
		SoundId = "rbxassetid://75664314250862",
		Volume = 5.0,
		MaxDistance = 250.48046875,
		PlaybackSpeed = 1.0,
		Looped = false
	},
	AttackSound = {
		SoundId = "rbxassetid://95116072506206",
		Volume = 4.0,
		MaxDistance = 300.0,
		PlaybackSpeed = 1.0,
		Looped = false
	},
	FootstepSound = {
		SoundId = "rbxassetid://86392397661742",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

