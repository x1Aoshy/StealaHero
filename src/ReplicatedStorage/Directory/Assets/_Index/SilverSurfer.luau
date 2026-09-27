-- ReplicatedStorage.Directory.Assets._Index.SilverSurfer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types.Interface)
local Default = require(script.Parent.Parent.BaseConfigs.Default)
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local Rarity = require(ReplicatedStorage.Directory.Rarity)

return (setmetatable({
	DisplayName = "Silver Surfer",
	Icon = "rbxassetid://87733160598688",
	EarningRate = 2500.0,
	IndexSpeedReward = 500.0,
	DropWeight = 0.5,
	VisualOdds = 2.0,
	ModelWeight = 80.0,
	BaseModelScale = 1.0,
	Egg = {
		DisplayName = "Silver Surfer Egg",
		Icon = "rbxassetid://133004694392561",
		GrowthTime = 120.0,
		WeightKg = 1.0
	},
	Animations = {
		Idle = Pipeline:GetAndSerializeAnimation("rbxassetid://180435571").anim,
		Walk = Pipeline:GetAndSerializeAnimation("rbxassetid://180426354").anim
	},
	Rarity = Rarity.Rarities.Secret,
	BaseModelColor = Color3.fromRGB(215, 225, 235),
	PossibleModelColors = {
		{ Color3.fromRGB(215, 225, 235), 760.0 },
		{ Color3.fromRGB(160, 200, 255), 120.0 }
	},
}, {
	__index = Default
}))
