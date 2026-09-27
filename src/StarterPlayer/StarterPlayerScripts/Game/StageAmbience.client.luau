-- StarterPlayerScripts.Game.StageAmbience (docs/STAGES_PLAN.md A9, injected by scripts/inject/stages.luau)
-- Per-stage lighting mood picked by the local player's X: the hub and stages 1/4 keep the default lighting,
-- stage 2 (Justice League) is dark and rainy blue, stages 3 (Spider-Verse) and 5 (Dragon Ball) are saturated,
-- stage 6 (One Piece) is warm. Applied as a LightingsController modifier with a tweened transition, so the
-- night reset lighting (AreaEggResetCycle, priority 100) still wins on top of it.
-- Stage 2 is the storm half of the Gotham rain (docs/HERO_MODELS_PLAN.md H5): StageWeather draws the rain over the
-- same X range and fades it over the same ~2 s. The values follow the owner's ZeroDown / RobloxBall rain states: the
-- fog comes from the Atmosphere (the place has one, so the engine ignores Lighting.Fog*; FogColor/FogEnd only matter
-- in a place without it): denser, lower haze, dark overcast Terrain clouds, lower brightness, cold desaturated grade.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MODIFIER_ID = "StageAmbience"
local MODIFIER_PRIORITY = 50
local TRANSITION_SECONDS = 2
local POLL_SECONDS = 0.25

-- Stage start X (plan §1); the hub is everything before stage 1.
local STAGE_START_X = { 72, 169.5, 315.6, 526.5, 762.5, 1086.5 }
local STAGES_END_X = 1471.5

local DEFAULT_COLOR_CORRECTION = {
	Brightness = 0,
	Contrast = 0,
	Enabled = true,
	Saturation = 0,
	TintColor = Color3.new(1, 1, 1),
}

local PRESETS = {
	[2] = {
		BrightnessScale = 0.5,
		Ambient = Color3.fromRGB(62, 72, 98),
		OutdoorAmbient = Color3.fromRGB(56, 66, 94),
		ColorShift_Top = Color3.fromRGB(112, 130, 184),
		FogColor = Color3.fromRGB(50, 58, 80),
		FogStart = 30,
		FogEnd = 380,
		Atmosphere = {
			Density = 0.5,
			Offset = 0.2,
			Color = Color3.fromRGB(86, 98, 126),
			Decay = Color3.fromRGB(42, 48, 64),
			Glare = 0,
			Haze = 2.4,
		},
		Clouds = { Cover = 0.92, Density = 0.62, Color = Color3.fromRGB(38, 44, 58) },
		ColorCorrection = { Saturation = -0.2, Contrast = 0.15, Brightness = -0.04, TintColor = Color3.fromRGB(192, 210, 255) },
	},
	[3] = { ColorCorrection = { Saturation = 0.35, Contrast = 0.08 } },
	[5] = { ColorCorrection = { Saturation = 0.4, Contrast = 0.06 } },
	[6] = {
		OutdoorAmbient = Color3.fromRGB(150, 118, 88),
		ColorShift_Top = Color3.fromRGB(255, 196, 140),
		ColorCorrection = { Saturation = 0.15, Contrast = 0.04, TintColor = Color3.fromRGB(255, 234, 204) },
	},
}

local LightingsController = nil
do
	local ok, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Library", 30):WaitForChild("Client", 30):WaitForChild("LightingsController", 30))
	end)
	if ok and type(result) == "table" and type(result.SetModifier) == "function" then
		LightingsController = result
	else
		warn("[StageAmbience] LightingsController unavailable, stage lighting disabled: " .. tostring(result))
		return
	end
end

local function makeTransform(preset)
	return function(config)
		local out = table.clone(config)
		for key, value in pairs(preset) do
			if key == "BrightnessScale" then
				if type(config.Brightness) == "number" then
					out.Brightness = config.Brightness * value
				end
			elseif key == "ColorCorrection" then
				local cc = table.clone(if type(config.ColorCorrection) == "table" then config.ColorCorrection else DEFAULT_COLOR_CORRECTION)
				for k, v in pairs(value) do
					cc[k] = v
				end
				cc.Enabled = true
				out.ColorCorrection = cc
			elseif key == "Atmosphere" or key == "Clouds" then
				-- only tint an Atmosphere (it overrides the fog) / Terrain Clouds the place already has
				if type(config[key]) == "table" then
					local merged = table.clone(config[key])
					for k, v in pairs(value) do
						merged[k] = v
					end
					out[key] = merged
				end
			elseif config[key] ~= nil then
				out[key] = value
			end
		end
		return out
	end
end

local TRANSFORMS = {}
for stage, preset in pairs(PRESETS) do
	TRANSFORMS[stage] = makeTransform(preset)
end

local function stageAt(x)
	if x < STAGE_START_X[1] or x > STAGES_END_X then
		return 0
	end
	for i = #STAGE_START_X, 1, -1 do
		if x >= STAGE_START_X[i] then
			return i
		end
	end
	return 0
end

local LocalPlayer = Players.LocalPlayer
local currentPreset = nil -- stage number of the applied preset, or nil for the default lighting

while true do
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local stage = stageAt(root.Position.X)
		local preset = if TRANSFORMS[stage] then stage else nil
		if preset ~= currentPreset then
			currentPreset = preset
			local ok, err = pcall(function()
				if preset then
					LightingsController:SetModifier(MODIFIER_ID, TRANSFORMS[preset], MODIFIER_PRIORITY, TRANSITION_SECONDS)
				else
					LightingsController:ClearModifier(MODIFIER_ID, TRANSITION_SECONDS)
				end
			end)
			if not ok then
				warn("[StageAmbience] " .. tostring(err))
			end
		end
	end
	task.wait(POLL_SECONDS)
end
