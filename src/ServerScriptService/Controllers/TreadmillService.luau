-- ServerScriptService.Controllers.TreadmillService
-- Handles "Treadmills: RequestUpgrade" (RemoteFunction). Contract confirmed by
-- reading StarterPlayer.StarterPlayerScripts.GUI.TreadmillUpgrade.Client in full:
-- client validates cost itself, then calls Network.Invoke(REQUEST_UPGRADE, nextConfig._id)
-- and expects (ok: boolean, err: string?) back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local Treadmills = require(ReplicatedStorage.Directory.Treadmills)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestUpgradeRemote = Network:WaitForChild("Treadmills: RequestUpgrade")

local TreadmillService = {}

RequestUpgradeRemote.OnServerInvoke = function(player, requestedId)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end

	local nextLevel = (profile.TreadmillUpgradeLevel or 1) + 1
	local nextConfig = Treadmills.GetByUpgradeLevel(nextLevel)
	if not nextConfig then
		return false, "Max treadmill upgrade reached"
	end
	if requestedId ~= nil and requestedId ~= nextConfig._id then
		return false, "Treadmill mismatch"
	end
	if (profile.Money or 0) < nextConfig.Price then
		return false, "Not enough money"
	end

	Database.SetAndBroadcast(player, {
		Money = profile.Money - nextConfig.Price,
		TreadmillUpgradeLevel = nextLevel,
	})

	return true
end

return TreadmillService
