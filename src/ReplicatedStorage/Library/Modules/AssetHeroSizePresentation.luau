-- ReplicatedStorage.Library.Modules.AssetHeroSizePresentation (HEROES, Gekko #6 "Hero Size")
-- How big a pen hero is DRAWN for this viewer. A hero's Scale (ItemData.Scale, rolled from ~0.1x to 35x by
-- EggItemUtil) keeps driving its income (AssetGenerationUtil: Scale ^ 1.85) and every number the game shows; only the
-- model ActiveAssetsController renders uses the compressed visual scale below, so a 10x hero no longer towers 56 studs
-- over a 50-stud pen. Settings > Hero Size (Small / Normal / Big, profile.Settings.HeroSize, validated by
-- SettingsService) multiplies it. The hero models are ~5-7 studs tall at visual scale 1 (a player is ~5.2).
--   Scale   0.1   0.25  0.5   1     1.5   2     3     6     10    35
--   Normal  0.32  0.5   0.71  1     1.18  1.31  1.49  1.81  2.04  2.6
-- Pure functions plus two client helpers (ReadPreference / ConnectPreferenceChanged) that read the local save without
-- ever yielding; nothing here throws on a missing optional piece.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetHeroSizePresentation = {}

-- Fallback copy of Shared.Variables.HeroSizeInfo (used only if that module is stale or missing the entry).
local FALLBACK_INFO = {
	key = "HeroSize",
	displayName = "Hero Size",
	description = "Makes heroes smaller or bigger, only for you!",
	default = "Normal",
	order = { "Small", "Normal", "Big" },
	options = { Small = 0.7, Normal = 1.0, Big = 1.3 },
}

local LOG_WEIGHT = 0.45 -- above 1x: visual = 1 + ln(scale) * LOG_WEIGHT
local SMALL_EXPONENT = 0.5 -- below 1x: visual = scale ^ SMALL_EXPONENT (tiny heroes stay readable)
local MIN_VISUAL = 0.2
local MAX_VISUAL = 4.0

local info = FALLBACK_INFO
do
	local library = ReplicatedStorage:FindFirstChild("Library")
	local shared = library and library:FindFirstChild("Shared")
	local variablesModule = shared and shared:FindFirstChild("Variables")
	if variablesModule and variablesModule:IsA("ModuleScript") then
		local ok, variables = pcall(require, variablesModule)
		local candidate = ok and type(variables) == "table" and variables.HeroSizeInfo or nil
		if type(candidate) == "table" and type(candidate.options) == "table" and type(candidate.order) == "table"
			and type(candidate.default) == "string" and candidate.options[candidate.default] ~= nil then
			info = candidate
		end
	end
end

AssetHeroSizePresentation.Info = info
AssetHeroSizePresentation.Key = info.key or FALLBACK_INFO.key

-- The rendered size of a hero of `scale`, before the viewer's preference (monotonic: bigger rolls stay bigger).
function AssetHeroSizePresentation.CompressScale(scale: number): number
	if typeof(scale) ~= "number" or scale ~= scale or scale <= 0 then
		return 1.0
	end
	local visual = if scale <= 1 then scale ^ SMALL_EXPONENT else 1 + math.log(scale) * LOG_WEIGHT
	return math.clamp(visual, MIN_VISUAL, MAX_VISUAL)
end

-- A valid preference name ("Small" / "Normal" / "Big"); anything else becomes the default.
function AssetHeroSizePresentation.Sanitize(preference: any): string
	if typeof(preference) == "string" and info.options[preference] ~= nil then
		return preference
	end
	return info.default
end

function AssetHeroSizePresentation.GetMultiplier(preference: any): number
	return info.options[AssetHeroSizePresentation.Sanitize(preference)] or 1.0
end

-- What ItemDisplay should ScaleTo (times the config's BaseModelScale) for a hero of `scale` seen with `preference`.
function AssetHeroSizePresentation.GetVisualScale(scale: number, preference: any): number
	return AssetHeroSizePresentation.CompressScale(scale) * AssetHeroSizePresentation.GetMultiplier(preference)
end

-- The next choice of the Settings cycle button (Small -> Normal -> Big -> Small).
function AssetHeroSizePresentation.NextPreference(preference: any): string
	local current = AssetHeroSizePresentation.Sanitize(preference)
	local order = info.order
	for index, name in ipairs(order) do
		if name == current then
			return order[index % #order + 1]
		end
	end
	return info.default
end

---------------------------------------------------------------------------------------------------
-- Client: the local player's saved choice
---------------------------------------------------------------------------------------------------

local Save = nil
local function getSave()
	if Save ~= nil or not RunService:IsClient() then
		return Save
	end
	local library = ReplicatedStorage:FindFirstChild("Library")
	local client = library and library:FindFirstChild("Client")
	local module = client and client:FindFirstChild("Save")
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			Save = result
		end
	end
	return Save
end

-- The saved preference, or the default while the save is not loaded yet. Never yields (Save.Get only runs once the
-- local data is loaded, when it returns the cached table).
function AssetHeroSizePresentation.ReadPreference(): string
	local save = getSave()
	if save == nil or type(save.IsLocalDataLoaded) ~= "function" or type(save.Get) ~= "function" then
		return info.default
	end
	local okLoaded, loaded = pcall(save.IsLocalDataLoaded)
	if not okLoaded or loaded ~= true then
		return info.default
	end
	local okGet, data = pcall(save.Get)
	local settings = okGet and type(data) == "table" and data.Settings or nil
	return AssetHeroSizePresentation.Sanitize(type(settings) == "table" and settings[AssetHeroSizePresentation.Key] or nil)
end

-- Calls `callback(preference)` whenever the saved Settings table changes or the local data loads (the callback
-- decides whether the value really changed). Returns the connections (empty if the save module is unavailable).
function AssetHeroSizePresentation.ConnectPreferenceChanged(callback: (string) -> ())
	local connections = {}
	local save = getSave()
	if save == nil then
		return connections
	end
	local function fire()
		local ok, err = pcall(callback, AssetHeroSizePresentation.ReadPreference())
		if not ok then
			warn("[AssetHeroSizePresentation] Hero Size listener failed: " .. tostring(err))
		end
	end
	pcall(function()
		table.insert(connections, save.GetStatChangedSignal("Settings"):Connect(fire))
	end)
	pcall(function()
		local localPlayer = game:GetService("Players").LocalPlayer
		table.insert(connections, save.LoadedStats:Connect(function(player)
			if player == localPlayer then
				fire()
			end
		end))
	end)
	return connections
end

return AssetHeroSizePresentation
