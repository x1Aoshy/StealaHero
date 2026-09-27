-- ServerScriptService.Controllers.SpeedService
-- Applies profile.SpeedPower to Humanoid.WalkSpeed, and implements Slow Mode
-- (contract confirmed by reading StarterPlayerScripts.GUI.SlowToggle in full:
-- both remotes return (enabled: boolean, restoredWalkSpeed: number)).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestGetSlowToggleStateRemote = Network:WaitForChild("Treadmills: RequestGetSlowToggleState")
local RequestSetSlowToggleEnabledRemote = Network:WaitForChild("Treadmills: RequestSetSlowToggleEnabled")

-- BUG FIX (user report: "despues de usar la rainbow carpet me vuelve a 16 speed" -- happens on
-- LANDING, not just on unequip: ReplicatedStorage.Rainbow.LocalScript hardcodes
-- Humanoid.WalkSpeed = 16 client-side the moment you stop flying, and the server has zero
-- visibility into that (its OnServerInvoke for fly mode is an empty stub -- confirmed by reading
-- the whole script). Rather than track every foreign gear script's private state, expose a
-- generic "please recompute my real WalkSpeed" remote any client-side script can fire after it
-- does something that might have stomped WalkSpeed -- Rainbow's landing code now fires this
-- right after its own WalkSpeed=16 write, so the authoritative server value wins immediately
-- after.
local RequestSpeedRefreshRemote = Instance.new("RemoteEvent")
RequestSpeedRefreshRemote.Name = "Treadmills: RequestSpeedRefresh"
RequestSpeedRefreshRemote.Parent = Network

local SLOW_WALK_SPEED = 8

local SpeedService = {}

local slowModeEnabled = {} -- [player] = boolean

local function computedWalkSpeed(profile)
	local ok, speed = pcall(TreadmillUtil.SpeedPowerToWalkSpeed, profile.SpeedPower)
	if ok and type(speed) == "number" then
		return speed
	end
	warn("[SpeedService] SpeedPowerToWalkSpeed failed for SpeedPower=" .. tostring(profile.SpeedPower) .. " (falling back to 16): " .. tostring(speed))
	return 16
end

function SpeedService.Refresh(player)
	local profile = Database.Get(player)
	if not profile then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if slowModeEnabled[player] then
		humanoid.WalkSpeed = SLOW_WALK_SPEED
	else
		humanoid.WalkSpeed = computedWalkSpeed(profile)
	end
end

RequestSpeedRefreshRemote.OnServerEvent:Connect(function(player)
	SpeedService.Refresh(player)
end)

Database.OnLoaded(function(player)
	if slowModeEnabled[player] == nil then
		slowModeEnabled[player] = false
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		SpeedService.Refresh(player)
	end)
	if player.Character then
		SpeedService.Refresh(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	slowModeEnabled[player] = nil
end)

RequestGetSlowToggleStateRemote.OnServerInvoke = function(player)
	local profile = Database.Get(player)
	local enabled = slowModeEnabled[player] == true
	local restored = profile and computedWalkSpeed(profile) or 16
	return enabled, restored
end

RequestSetSlowToggleEnabledRemote.OnServerInvoke = function(player, enabled)
	if typeof(enabled) ~= "boolean" then
		enabled = false
	end
	slowModeEnabled[player] = enabled
	SpeedService.Refresh(player)
	local profile = Database.Get(player)
	local restored = profile and computedWalkSpeed(profile) or 16
	return enabled, restored
end

return SpeedService
