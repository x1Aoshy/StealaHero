-- ServerScriptService.Controllers.GroupRewardService
-- "Free Gift!" reward (StarterGui.GroupReward, VISUAL_PASS_PLAN D7): 1. Like the game, 2. Favorite the game,
-- 3. Join the community. The client (StarterPlayer...GUI.GroupRewards) calls
-- Network.Invoke("GroupReward: ClaimReward", flag) expecting (ok, err?, speedPowerAmount). Likes and favorites cannot
-- be verified by a server and the community step is informational, so the reward is granted once per profile
-- (ClaimedGroupReward) without a group-membership check; the client flag is not trusted for anything. Reward amount:
-- ReplicatedStorage.Library.Types.GroupReward.GetSpeedPowerRewardAmount() = 1000 (BALANCE 2026-09-23; was 10000).
-- (Before the visual pass the grant required player:IsInGroup(Constants.GROUP_ID); the base game also opened
-- GroupService:PromptJoinAsync, removed by the [nogroup] fix.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local SpeedService = require(game.ServerScriptService.Controllers.SpeedService)
local GroupReward = require(ReplicatedStorage.Library.Types.GroupReward)

local Network = ReplicatedStorage:WaitForChild("Network")
local ClaimRewardRemote = Network:WaitForChild("GroupReward: ClaimReward")

local GroupRewardService = {}

ClaimRewardRemote.OnServerInvoke = function(player, _clientFlag)
	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end
	if profile.ClaimedGroupReward == true then
		return false, "You already claimed this reward!"
	end

	local amountOk, amount = pcall(GroupReward.GetSpeedPowerRewardAmount)
	if not amountOk or type(amount) ~= "number" then
		warn("[GroupRewardService] GetSpeedPowerRewardAmount failed: " .. tostring(amount))
		amount = 1000
	end

	profile.ClaimedGroupReward = true
	profile.SpeedPower = (profile.SpeedPower or 10) + amount
	Database.SetAndBroadcast(player, {
		ClaimedGroupReward = true,
		SpeedPower = profile.SpeedPower,
	})
	SpeedService.Refresh(player)

	return true, nil, amount
end

return GroupRewardService
