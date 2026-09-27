-- ReplicatedStorage.Directory.Assets._Index.SpiderGwen
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types.Interface)
local Default = require(script.Parent.Parent.BaseConfigs.Default)
local Pipeline = require(ReplicatedStorage.Directory.Animations.Pipeline)
local Rarity = require(ReplicatedStorage.Directory.Rarity)

return (setmetatable({
	DisplayName = "Spider-Gwen",
	Icon = "rbxassetid://87733160598688",
	EarningRate = 55.0,
	IndexSpeedReward = 500.0,
	DropWeight = 0.5,
	VisualOdds = 2.0,
	ModelWeight = 80.0,
	BaseModelScale = 1.0,
	Egg = {
		DisplayName = "Spider-Gwen Egg",
		Icon = "rbxassetid://133004694392561",
		GrowthTime = 30.0,
		WeightKg = 1.0
	},
	Animations = {
		Idle = Pipeline:GetAndSerializeAnimation("rbxassetid://180435571").anim,
		Walk = Pipeline:GetAndSerializeAnimation("rbxassetid://180426354").anim
	},
	Rarity = Rarity.Rarities.Rare,
	BaseModelColor = Color3.fromRGB(235, 235, 245),
	PossibleModelColors = {
		{ Color3.fromRGB(235, 235, 245), 760.0 },
		{ Color3.fromRGB(230, 40, 140), 120.0 }
	},
}, {
	__index = Default
}))
