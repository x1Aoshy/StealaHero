-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQLQnVpbGRDb25maWcJRGlyZWN0b3J5BlJhcml0eQhSYXJpdGllcwpBbmltYXRpb25zCFBpcGVsaW5lC0Jhc2VDb25maWdzHERlZmF1bHRBbmltYXRpb25Db25maWdMb29wZWQJV2Fsa1NwZWVkC0hpdERpc3RhbmNlGkhvbWVJbXB1bHNlQm9vc3REaXN0YW5jZVhaDlNsZWVwQW5pbWF0aW9uDUlkbGVBbmltYXRpb24NV2Fsa0FuaW1hdGlvbg9BdHRhY2tBbmltYXRpb24NRm9vdHN0ZXBTb3VuZARSYXJlG3JieGFzc2V0aWQ6Ly85MTQ3NzM3NzUwODU1ORhHZXRBbmRTZXJpYWxpemVBbmltYXRpb24bcmJ4YXNzZXRpZDovLzg1Nzc3OTE3ODUzNDgyG3JieGFzc2V0aWQ6Ly83MzI5MDYxOTIwMTg0OBxyYnhhc3NldGlkOi8vMTMyMDQ3MTYxNDc2NzQ1B1NvdW5kSWQccmJ4YXNzZXRpZDovLzEzNzY4Mjg2MTg3MTAwMwZWb2x1bWULTWF4RGlzdGFuY2UNUGxheWJhY2tTcGVlZAZMb29wZWQAAQsAAAECAFejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICJAgAAABNAgLhCQAAAJ8BAgKkAgUAAABAQE0DAJEKAAAATQMD8gsAAACfAgICTQIC6AwAAACkAwUAAABAQE0EAJEKAAAATQQERA0AAABNBAQ5DgAAAJ8DAgKkBAUAAABAQKQFBwAAAGBATQUFJAgAAABNBQUkCAAAAE0FBToPAAAATQUF4hAAAACfBAICUgUBAOIGHABNBwKnHQAAADAHBvILAAAAbwkeAFIKBAC8BwPpHwAAAJ8HBAIwBwbTFwAAAG8JIABSCgQAvAcD6R8AAACfBwQCMAcG+hgAAABvCSEAUgoEALwHA+kfAAAAnwcEAjAHBsAZAAAAbwkiALwHA+kfAAAAnwcDAjAHBrIaAAAA4gctADAHBoQbAAAAnwUCAIIFAAAuAwEEAAAAQAMCAwMDBAQAAEBAAwUEAABgQAMGAwcDCAMJAwoDCwMMAw0DDgMPAgAAAAAAAE9AAxACAAAAAAAAEEADEQIAAAAAAEBgQAMSAxMDFAMVAxYICQv/////ERIAAAATFAAAABUWAAAAF/////8Y/////xn/////Gv////8b/////wMXAxgDGQMaAxsDHAMdAx4DHwIAAAAAAAD4PwMgAgAAAAAAAE5AAyECAAAAAAAA8D8DIgEBCAUjJAAAACUmAAAAJygAAAApKgAAACssAAAAAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAAAAwABAAAABgH+AAAAAAUB/gAAAAAFAf4AAAAABAAAAAAAAQAA7QABAAAAAABvLLhITHXQ8Xp/YSszhXDbHzSvPF3o0kk=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(script.Parent.Parent.BuildConfig)
local Rarities = require(ReplicatedStorage.Directory.Rarity).Rarities
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local DefaultAnimationConfigLooped = require(script.Parent.Parent.BaseConfigs.DefaultAnimationConfigLooped)

return BuildConfig({
	WalkSpeed = 62.0,
	HitDistance = 4.0,
	HomeImpulseBoostDistanceXZ = 130.0,
	Rarity = Rarities.Rare,
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://91477377508559", DefaultAnimationConfigLooped),
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://85777917853482", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://73290619201848", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://132047161476745"),
	FootstepSound = {
		SoundId = "rbxassetid://137682861871003",
		Volume = 1.5,
		MaxDistance = 60.0,
		PlaybackSpeed = 1.0,
		Looped = true
	}
})

