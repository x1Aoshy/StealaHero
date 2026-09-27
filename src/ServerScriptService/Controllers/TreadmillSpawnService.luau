-- ServerScriptService.Controllers.TreadmillSpawnService
-- Spawns the actual visual treadmill model on each player's plot server-side.
-- The original client-side render pipeline (StarterPlayerScripts.Game.Plots.TreadmillStaticController)
-- has silent failures in this rip that leave the treadmill model missing even though the
-- upgrade sign and grind service both work. This module bypasses that: whenever a player
-- with BaseUpgradeLevel > 0 owns a plot, we clone the correct treadmill Tool for their
-- TreadmillUpgradeLevel and pivot it onto the plot's TreadmillBottom part. Rebuilds on
-- upgrade. Cleans up on leave. Visible to every player, which is fine because everyone
-- can already see each other's plots.
--
-- One treadmill per plot: the plot owner's client (TreadmillStaticController) still renders
-- its own copy of the same skin (rate sign, video cover, session hooks), so it hides this
-- server copy on its own screen while that copy exists. Everyone else sees this one. Plots
-- with no owner or an owner at BaseUpgradeLevel 0 (treadmill not bought) show nothing.
-- Skins flagged FloorAligned (every treadmill model skin, scripts/steps/treadmill.luau)
-- are grounded on the plot's walkable floor (Plots.<id>.TreadmillFloorY), exactly like the
-- client render (TreadmillStaticController.Render), and the rate sign shows the same
-- "+<multiplier>/step" text the owner's client writes on its copy.
--
-- Static display (CONTRACTS_PHASE3 D6): scripts/steps/treadmill.luau bakes a visual-only copy of the
-- tier-1 treadmill model named SpeedsterTreadmillDisplay into every plot, in its LOCKED look (visible
-- parts at 0.35 transparency + "UNLOCK $8" lock billboard, ECON /125 2026-09-24). This module owns its runtime
-- state, one per plot, re-derived after every render change:
--   Hidden   - this module has a render for the plot (Transparency 1, billboard off);
--   Locked   - no render and the plot is unowned or its owner has not bought the treadmill
--              (profile BaseUpgradeLevel 0): the display stays the only treadmill, locked;
--   Unlocked - no render although the treadmill is bought (the render failed to build): the display
--              shows unlocked so the plot still has exactly one treadmill.
-- Every display part stays CanCollide/CanQuery/CanTouch = false in every state. The owner's
-- TreadmillStaticController additionally hides the display on its own screen while it shows its
-- local render, so every viewer sees exactly one treadmill per plot. Grinding stays gated by
-- TreadmillGrindService (BaseUpgradeLevel > 0); the display is never usable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Database = require(ServerScriptService.Library.Database)
local PlotService = require(ServerScriptService.Controllers.PlotService)
local Treadmills = require(ReplicatedStorage.Directory.Treadmills)
local TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil)

local TreadmillModels = ReplicatedStorage.Assets.Models.Treadmills
local PlotsFolder = Workspace:WaitForChild("Plots")

-- Pure number formatter (same one TreadmillStaticRateSign uses on the client); optional.
local okCommas, Commas = pcall(function()
	return require(ReplicatedStorage.Library.Functions.Commas)
end)
if not okCommas or type(Commas) ~= "function" then
	Commas = nil
end

local FLOOR_ALIGNED_ATTRIBUTE = "FloorAligned" -- on the skin Tool
local FLOOR_ATTRIBUTE = "TreadmillFloorY" -- on the plot Model
local MAX_FLOOR_CORRECTION = 2
local DECOR_ATTRIBUTE = "TreadmillDecor" -- on the skin's visual-only model parts

local DISPLAY_NAME = "SpeedsterTreadmillDisplay" -- static display in every plot (scripts/steps/treadmill.luau)
local DISPLAY_STATE_ATTRIBUTE = "DisplayState"
local DISPLAY_LOCKED_TRANSPARENCY = 0.35
local DISPLAY_BILLBOARD_ATTRIBUTE = "TreadmillLockBillboard"

local TreadmillSpawnService = {}

-- Container the spawned treadmills live in. Kept out of the plot itself so the plot's
-- own child-list stays untouched (PlotService and the ripped client scripts iterate it).
local spawnedFolder = Workspace:FindFirstChild("__ServerTreadmillRenders")
if not spawnedFolder then
	spawnedFolder = Instance.new("Folder")
	spawnedFolder.Name = "__ServerTreadmillRenders"
	spawnedFolder.Parent = Workspace
end

local activeByPlot = {} -- [plotId] = { model = Tool, treadmillId = string }
local displayStateByPlot = {} -- [plotId] = last applied display state

-- Display state for a plot: Hidden while a render exists, else Locked until the treadmill is bought.
local function resolveDisplayState(hasRender, baseUpgradeLevel)
	if hasRender then
		return "Hidden"
	end
	local level = tonumber(baseUpgradeLevel)
	if level ~= nil and level == level and level > 0 then
		return "Unlocked"
	end
	return "Locked"
end

-- Writes one display state onto the display's parts and lock billboard (visual-only in every state).
local function applyDisplayVisual(display, state)
	local lockedTransparency = tonumber(display:GetAttribute("LockedTransparency")) or DISPLAY_LOCKED_TRANSPARENCY
	for _, descendant in ipairs(display:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local original = tonumber(descendant:GetAttribute("OrigTransparency")) or 0
			if state == "Hidden" then
				descendant.Transparency = 1
			elseif state == "Locked" and original < 0.99 then
				descendant.Transparency = math.max(original, lockedTransparency)
			else
				descendant.Transparency = original
			end
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		elseif descendant:IsA("BillboardGui") and descendant:GetAttribute(DISPLAY_BILLBOARD_ATTRIBUTE) == true then
			descendant.Enabled = state == "Locked"
		end
	end
	display:SetAttribute(DISPLAY_STATE_ATTRIBUTE, state)
end

-- BaseUpgradeLevel of the plot's current owner (the same profile field the render decision reads);
-- 0 for an unowned plot. `leaving` is a player being removed, who no longer owns anything.
local function resolveOwnerBaseLevel(plotId, leaving)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= leaving and PlotService.GetPlotId(player) == plotId then
			local profile = Database.Get(player)
			return profile and tonumber(profile.BaseUpgradeLevel) or 0
		end
	end
	return 0
end

-- Re-derives the plot's display state from this module's render and the plot owner's profile.
local function refreshDisplay(plotId, leaving)
	local plot = PlotsFolder:FindFirstChild(tostring(plotId))
	local display = plot and plot:FindFirstChild(DISPLAY_NAME)
	if not display then
		return
	end
	local entry = activeByPlot[plotId]
	local hasRender = entry ~= nil and entry.model ~= nil and entry.model.Parent ~= nil
	local state = resolveDisplayState(hasRender, if hasRender then nil else resolveOwnerBaseLevel(plotId, leaving))
	if displayStateByPlot[plotId] == state and display:GetAttribute(DISPLAY_STATE_ATTRIBUTE) == state then
		return
	end
	displayStateByPlot[plotId] = state
	local ok, err = pcall(applyDisplayVisual, display, state)
	if not ok then
		warn("[TreadmillSpawnService] Could not update the treadmill display of plot " .. tostring(plotId) .. ": " .. tostring(err))
	end
end

local function destroySpawn(plotId)
	local entry = activeByPlot[plotId]
	if not entry then return end
	activeByPlot[plotId] = nil
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
end

local function findTreadmillBottom(plotId)
	local plot = PlotsFolder:FindFirstChild(tostring(plotId))
	if not plot then return nil end
	local bottom = plot:FindFirstChild("TreadmillBottom")
	if bottom and bottom:IsA("BasePart") then return bottom end
	return nil
end

-- Vertical correction from the TreadmillBottom plate to the plot's walkable floor for skins built
-- for the floor (the plates sit up to ~0.26 studs above or below it). 0 for every other skin.
local function resolveFloorCorrection(bottom, model)
	if model:GetAttribute(FLOOR_ALIGNED_ATTRIBUTE) ~= true then return 0 end
	local plot = bottom.Parent
	local floorY = plot and plot:GetAttribute(FLOOR_ATTRIBUTE)
	if type(floorY) ~= "number" or floorY ~= floorY then return 0 end
	local correction = floorY - bottom.Position.Y
	if math.abs(correction) > MAX_FLOOR_CORRECTION then return 0 end
	return correction
end

-- Same text/colour TreadmillStaticRateSign.Apply writes on the owner's client copy, so every
-- viewer reads the real multiplier instead of the template's placeholder.
local function applyRateSign(model, config)
	local ratePart = model:FindFirstChild("SpeedPerSecond")
	local billboard = ratePart and ratePart:FindFirstChild("BillboardGui")
	local frame = billboard and billboard:FindFirstChild("Frame")
	local label = frame and frame:FindFirstChild("TextLabel")
	if not (label and label:IsA("TextLabel")) then return end
	local multiplier = tonumber(config.SpeedMultiplier)
	if not multiplier then return end
	local okText, text = false, nil
	if Commas then
		okText, text = pcall(Commas, multiplier)
	end
	label.Text = "+" .. (if okText and type(text) == "string" then text else tostring(math.round(multiplier))) .. "/step"
	local rarity = config.Rarity
	if type(rarity) == "table" and typeof(rarity.Color) == "Color3" then
		label.TextColor3 = rarity.Color
	end
end

local function buildTreadmill(plotId, config)
	local treadmillId = config._id
	local template = TreadmillModels:FindFirstChild(treadmillId)
	if not template then
		warn("[TreadmillSpawnService] No model for treadmill '" .. tostring(treadmillId) .. "'")
		return nil
	end

	local bottom = findTreadmillBottom(plotId)
	if not bottom then
		warn("[TreadmillSpawnService] Plot " .. tostring(plotId) .. " has no TreadmillBottom")
		return nil
	end

	local clone = template:Clone()
	clone.Name = "ServerTreadmill_" .. tostring(plotId)

	-- Anchor every part so it doesn't fall; disable collision so players walk over it (they
	-- run on the invisible TreadmillBottom trigger, not on the visual mesh); disable touch
	-- so we don't accidentally trigger the Grind service off the visual pieces. Kill any
	-- BaseScripts baked into the Tool so its old client logic doesn't run twice. The model's
	-- visual-only parts (TreadmillDecor, scripts/steps/treadmill.luau) stay out of spatial
	-- queries; the functional parts (hitbox, PhoneScreen, ...) stay queryable.
	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = desc:GetAttribute(DECOR_ATTRIBUTE) ~= true
		elseif desc:IsA("BaseScript") then
			desc:Destroy()
		end
	end
	applyRateSign(clone, config)

	clone.Parent = spawnedFolder

	-- Pivot the model so its Root part sits grounded on the TreadmillBottom, matching how
	-- the client controller placed it. Uses the same utility so the alignment matches.
	local root = clone:FindFirstChild("Root")
	if root and root:IsA("BasePart") then
		local ok, target = pcall(TreadmillUtil.ResolveGroundedToolRootCFrameAtLocation, bottom, clone)
		if ok and target then
			target = target + Vector3.new(0, resolveFloorCorrection(bottom, clone), 0)
			local pivot = clone:GetPivot()
			local rootToPivot = pivot:ToObjectSpace(root.CFrame)
			clone:PivotTo(target * rootToPivot:Inverse())
		else
			-- Fallback: put the model directly above the bottom part.
			clone:PivotTo(bottom.CFrame * CFrame.new(0, 3, 0))
		end
	else
		clone:PivotTo(bottom.CFrame * CFrame.new(0, 3, 0))
	end

	return clone
end

local function refreshRenderForPlayer(player)
	if not player or not player.Parent then return end
	local plotId = PlotService.GetPlotId(player)
	if not plotId then return end

	local profile = Database.Get(player)
	if not profile then return end

	local baseLevel = tonumber(profile.BaseUpgradeLevel) or 0
	if baseLevel <= 0 then
		destroySpawn(plotId)
		return
	end

	local upgradeLevel = math.max(1, math.floor(tonumber(profile.TreadmillUpgradeLevel) or 1))
	local config = Treadmills.GetByUpgradeLevel(upgradeLevel)
	if not config then
		warn("[TreadmillSpawnService] No treadmill config for level " .. tostring(upgradeLevel))
		destroySpawn(plotId)
		return
	end

	local existing = activeByPlot[plotId]
	if existing and existing.treadmillId == config._id and existing.model and existing.model.Parent then
		return -- already up to date
	end

	destroySpawn(plotId)

	local model = buildTreadmill(plotId, config)
	if model then
		activeByPlot[plotId] = { model = model, treadmillId = config._id }
	end
end

-- Every render change goes through here, so the plot's display state is re-derived right after it
-- (same frame: a tier rebuild never shows the display in between).
local function refreshForPlayer(player)
	refreshRenderForPlayer(player)
	local plotId = player and PlotService.GetPlotId(player)
	if plotId then
		refreshDisplay(plotId)
	end
end

local function refreshForPlot(plotId)
	if not plotId then return end
	for _, player in ipairs(Players:GetPlayers()) do
		if PlotService.GetPlotId(player) == plotId then
			refreshForPlayer(player) -- also refreshes this plot's display
			return
		end
	end
	destroySpawn(plotId)
	refreshDisplay(plotId)
end

-- Initial spawn as each player's data finishes loading.
Database.OnLoaded(function(player)
	task.defer(function()
		-- Wait a moment for PlotService to assign the plot (both are triggered by OnLoaded,
		-- but PlotService is registered first in Bootstrap so we usually land after it).
		for _ = 1, 30 do
			if PlotService.GetPlotId(player) then break end
			task.wait(0.1)
		end
		refreshForPlayer(player)
	end)
end)

-- Rebuild when upgrades change.
Database.OnFieldChanged("TreadmillUpgradeLevel", function(player)
	task.defer(refreshForPlayer, player)
end)
Database.OnFieldChanged("BaseUpgradeLevel", function(player)
	task.defer(refreshForPlayer, player)
end)

Players.PlayerRemoving:Connect(function(player)
	local plotId = PlotService.GetPlotId(player)
	if plotId then
		destroySpawn(plotId)
		refreshDisplay(plotId, player)
	end
end)

-- Also follow each plot's BaseUpgradeLevel attribute, which PlotService sets on assign, keeps in
-- step with the owner's profile and resets to 0 on free. This catches owners assigned after the
-- OnLoaded pass gave up (a waiting player handed a freed plot on a full server) and removes a
-- leaver's render when PlotService's PlayerRemoving cleared the plot before the handler above ran.
-- refreshForPlot reads the live owner, so redundant or out-of-order refreshes are harmless.
local function watchPlotAttribute(plot)
	local plotId = tonumber(plot.Name)
	if not plotId then return end
	plot:GetAttributeChangedSignal("BaseUpgradeLevel"):Connect(function()
		task.defer(refreshForPlot, plotId)
	end)
end
for _, plot in ipairs(PlotsFolder:GetChildren()) do
	watchPlotAttribute(plot)
	local plotId = tonumber(plot.Name)
	if plotId then
		refreshDisplay(plotId) -- every plot starts Locked (no renders yet)
	end
end
PlotsFolder.ChildAdded:Connect(watchPlotAttribute)

-- Retry pass in case any player's plot assignment happened before this module loaded.
task.defer(function()
	task.wait(1)
	for _, player in ipairs(Players:GetPlayers()) do
		if Database.IsPlayerLoaded(player) then
			refreshForPlayer(player)
		end
	end
end)

return TreadmillSpawnService
