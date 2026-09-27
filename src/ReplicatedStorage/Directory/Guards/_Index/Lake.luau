-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlGkhvbWVJbXB1bHNlQm9vc3REaXN0YW5jZVhaDlNsZWVwQW5pbWF0aW9uDUlkbGVBbmltYXRpb24NV2Fsa0FuaW1hdGlvbg9BdHRhY2tBbmltYXRpb24NRm9vdHN0ZXBTb3VuZAhVbmNvbW1vbhxyYnhhc3NldGlkOi8vMTE5MDA2NzU4OTQxOTc5GEdldEFuZFNlcmlhbGl6ZUFuaW1hdGlvbhxyYnhhc3NldGlkOi8vMTEzOTQ3Mzg1ODczOTUyHHJieGFzc2V0aWQ6Ly8xMzY4MzI3OTI2NTY0ODkccmJ4YXNzZXRpZDovLzEwNjg0ODcyOTk2OTk0MAdTb3VuZElkG3JieGFzc2V0aWQ6Ly84NDYzOTE0MzY3MjMzMQZWb2x1bWULTWF4RGlzdGFuY2UNUGxheWJhY2tTcGVlZAZMb29wZWQAAQsAAAECAFejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICJAgAAABNAgLhCQAAAJ8BAgKkAgUAAABAQE0DAJEKAAAATQMD8gsAAACfAgICTQIC6AwAAACkAwUAAABAQE0EAJEKAAAATQQERA0AAABNBAQ5DgAAAJ8DAgKkBAUAAABAQKQFBwAAAGBATQUFJAgAAABNBQUkCAAAAE0FBToPAAAATQUF4hAAAACfBAICUgUBAOIGHABNBwKWHQAAADAHBvILAAAAbwkeAFIKBAC8BwPpHwAAAJ8HBAIwBwbTFwAAAG8JIABSCgQAvAcD6R8AAACfBwQCMAcG+hgAAABvCSEAUgoEALwHA+kfAAAAnwcEAjAHBsAZAAAAbwkiALwHA+kfAAAAnwcDAjAHBrIaAAAA4gctADAHBoQbAAAAnwUCAIIFAAAuAwEEAAAAQAMCAwMDBAQAAEBAAwUEAABgQAMGAwcDCAMJAwoDCwMMAw0DDgMPAgAAAAAAgEFAAxACAAAAAAAACEADEQIAAAAAAABZQAMSAxMDFAMVAxYICQv/////ERIAAAATFAAAABUWAAAAF/////8Y/////xn/////Gv////8b/////wMXAxgDGQMaAxsDHAMdAx4DHwIAAAAAAAD4PwMgAgAAAAAAAE5AAyECAAAAAAAA8D8DIgEBCAUjJAAAACUmAAAAJygAAAApKgAAACssAAAAAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAAAAwABAAAABgH+AAAAAAUB/gAAAAAFAf4AAAAABAAAAAAAAQAA7QABAAAAAADWFuoDNtCnUUkjzC0TiBr7pg79d+TSgAI=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 35.0,
	HitDistance = 3.0,
	HomeImpulseBoostDistanceXZ = 100.0,
	Rarity = Rarities.Uncommon,
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://119006758941979", DefaultAnimationConfigLooped),
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://113947385873952", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://136832792656489", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://106848729969940"),
	FootstepSound = {
		SoundId = "rbxassetid://84639143672331",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

