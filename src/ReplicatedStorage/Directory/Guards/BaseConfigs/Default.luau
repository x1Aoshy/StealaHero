-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local Rarity = require(ReplicatedStorage.Directory.Rarity)

require(script.Parent.Parent.Types.Interface)

local DefaultAnimationConfigLooped = require(script.Parent.DefaultAnimationConfigLooped)

return {
	FlatRadius = 20.0,
	WalkSpeed = 18.0,
	HomeImpulseBoostDistanceXZ = 70.0,
	Rarity = Rarity.Rarities.Common,
	IdleAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://98231755264803", DefaultAnimationConfigLooped),
	WalkAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://114003305194474", DefaultAnimationConfigLooped),
	SleepAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://79297169387271", DefaultAnimationConfigLooped),
	AttackAnimation = Pipeline:GetAndSerializeAnimation("rbxassetid://81558105939037"),
	SleepSound = {
		SoundId = "rbxassetid://129416806869914",
		Volume = 0.800000011920929,
		MaxDistance = 40.0,
		PlaybackSpeed = 1.0,
		Looped = false
	},
	WakeSound = {
		SoundId = "rbxassetid://96595477884583",
		Volume = 0.30000001192092896,
		MaxDistance = 250.48046875,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	},
	AttackSound = {
		SoundId = "rbxassetid://76766635785020",
		Volume = 2.0,
		MaxDistance = 150.0,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	},
	FootstepSound = {
		SoundId = "rbxassetid://89709728610870",
		Volume = 1.5,
		MaxDistance = 74.38033294677734,
		PlaybackSpeed = 1.0700000524520874,
		Looped = false
	}
}

