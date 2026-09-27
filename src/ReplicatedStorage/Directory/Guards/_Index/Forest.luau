-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMtBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwlUYWJsZVV0aWwLQmFzZUNvbmZpZ3McRGVmYXVsdEFuaW1hdGlvbkNvbmZpZ0xvb3BlZARDb3B5BFBsYXkJV2Fsa1NwZWVkC0hpdERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoOU2xlZXBBbmltYXRpb24NSWRsZUFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbg5BZnRlcldha2VTb3VuZAtBdHRhY2tTb3VuZA1Gb290c3RlcFNvdW5kBkNvbW1vbhxyYnhhc3NldGlkOi8vMTMwMTM5Mzg0NTgyMzU2GEdldEFuZFNlcmlhbGl6ZUFuaW1hdGlvbhxyYnhhc3NldGlkOi8vMTM5MTIyNTgyMjQ3MjE3HHJieGFzc2V0aWQ6Ly8xMzk1NjA2MTM3NjYzMjIccmJ4YXNzZXRpZDovLzEwODUyODM1MDIwNjM3MAdTb3VuZElkHHJieGFzc2V0aWQ6Ly8xMjk2NzUzMzkzOTQ2ODEGVm9sdW1lC01heERpc3RhbmNlDVBsYXliYWNrU3BlZWQGTG9vcGVkHHJieGFzc2V0aWQ6Ly8xMTk5MTA2NzU4OTEzMTcbcmJ4YXNzZXRpZDovLzc3NTY5MDUyOTc5Mzc0AAENAAABAgB0owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAATQIC4QkAAACfAQICpAIFAAAAQEBNAwCRCgAAAE0DA/ILAAAAnwICAk0CAugMAAAApAMFAAAAQEBNBACRCgAAAE0EBEQNAAAATQQEOQ4AAACfAwICpAQFAAAAQEBNBQBqDwAAAE0FBegQAAAATQUF5hEAAABNBQXOEgAAAJ8EAgKkBQUAAABAQKQGBwAAAGBATQYGJAgAAABNBgYkCAAAAE0GBjoTAAAATQYG4hQAAACfBQICTQYEKRUAAABSBwUAqQgBAJ8GAwL/BwAAAQAAAG8IFgDFBwgCAQAAADAHBu4XAAAAUgcBAOIIJwBNCQJzKAAAADAJCPILAAAAbwspAFIMBQC8CQPpKgAAAJ8JBAIwCQjTIAAAAG8LKwBSDAUAvAkD6SoAAACfCQQCMAkI+iEAAABvCywAUgwFALwJA+kqAAAAnwkEAjAJCMAiAAAAbwstALwJA+kqAAAAnwkDAjAJCLIjAAAA4gk4ADAJCDEkAAAA4gk9ADAJCIglAAAA4glCADAJCIQmAAAAnwcCAIIHAABDAwEEAAAAQAMCAwMDBAQAAEBAAwUEAABgQAMGAwcDCAMJAwoDCwMMAw0DDgMPAxADEQMSAxMCMzMzMzMz4z8DFAMVAgAAAAAAADBAAxYCAAAAAAAABEADFwIAAAAAAAAQQAMYAgAAAAAAgFFAAxkDGgMbAxwDHQMeAx8IDAv/////GBkAAAAaGwAAABwdAAAAHh8AAAAg/////yH/////Iv////8j/////yT/////Jf////8m/////wMgAyEDIgMjAyQDJQMmAycDKAIAAAAAAAAUQAMpAgAAAABgT29AAyoCAAAAAAAA8D8DKwEACAUuLwAAADAxAAAAMjMAAAA0NQAAADY3AAAAAywCAAAAAAAAAEACAAAAAADAYkACAAAAYLge8T8IBS45AAAAMDoAAAAyOwAAADQ8AAAANjcAAAADLQIAAAAAAAD4PwIAAAAAAABOQAEBCAUuPgAAADA/AAAAMkAAAAA0NQAAADZBAAAAAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAADAAAAAAEAAAAAAAADAAEAAAAHAf4AAAAABQH+AAAAAAUB/gAAAAAEAAAAAAABAAAHAAAHAADeAAEAAAAAAHMuA587liu1CKQUMd8j2PcDNhTrQeppng==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local TableUtil = require(ReplicatedStorage.Library.Modules.Packages.TableUtil)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

TableUtil.Copy(DefaultAnimationConfigLooped, true).Play = { 0.6 }

return BuildConfig({
	WalkSpeed = 16.0,
	HitDistance = 2.5,
	AnimationBaseWalkSpeed = 4.0,
	HomeImpulseBoostDistanceXZ = 70.0,
	Rarity = Rarities.Common,
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://130139384582356", DefaultAnimationConfigLooped),
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://139122582247217", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://118560876531170", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://108528350206370"),
	AfterWakeSound = {
		SoundId = "rbxassetid://129675339394681",
		Volume = 5.0,
		MaxDistance = 250.48046875,
		PlaybackSpeed = 1.0,
		Looped = false
	},
	AttackSound = {
		SoundId = "rbxassetid://119910675891317",
		Volume = 2.0,
		MaxDistance = 150.0,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	},
	FootstepSound = {
		SoundId = "rbxassetid://77569052979374",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

