-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUI = require(ReplicatedStorage.Library.Client.GUI)
local GetFriendCountInServer = require(ReplicatedStorage.Library.Functions.GetFriendCountInServer)
local FriendBoosts = require(ReplicatedStorage.Library.Shared.Variables.FriendBoosts)
local Confetti = require(ReplicatedStorage.Library.Client.GUIFX.Confetti)
local UpdateTextAndShadow = require(ReplicatedStorage.Library.Functions.UpdateTextAndShadow)
local Network = require(game.ReplicatedStorage.Library.Client.Network)
local LocalPlayer = Players.LocalPlayer
local FriendBoost = GUI.Money().Bottom.Frame.FriendBoost
local CurrentBoost = FriendBoost.CurrentBoost

FriendBoost.Visible = false

local function onFriendsInGame() -- line: 24
	-- upvalues: FriendBoost (copy)
	FriendBoost.Visible = true
end
local function onNoFriends() -- line: 28
	-- upvalues: FriendBoost (copy)
	FriendBoost.Visible = false
end
local function updateBoostsDisplay() -- line: 32
	-- upvalues: GetFriendCountInServer (copy), LocalPlayer (copy), FriendBoost (copy), FriendBoosts (copy), UpdateTextAndShadow (copy), CurrentBoost (copy)
	local v15 = GetFriendCountInServer.GetCountByPlayer(LocalPlayer)

	if not v15 or v15 <= 0.0 then
		FriendBoost.Visible = false

		return
	end

	local v16 = math.floor(FriendBoosts.BaseBoostPercent * math.clamp(v15, 0.0, FriendBoosts.MaxPlayers))

	if v16 <= 0.0 then
		FriendBoost.Visible = false

		return
	end

	FriendBoost.Visible = true
	UpdateTextAndShadow(CurrentBoost, string.format("Friend Boost: +%d%%", v16))
end

GetFriendCountInServer.CacheUpdated:Connect(function(p1) -- line: 49
	-- upvalues: LocalPlayer (copy), updateBoostsDisplay (copy)
	if p1 == LocalPlayer then
		updateBoostsDisplay()
	end
end)
updateBoostsDisplay()
Players.PlayerAdded:Connect(updateBoostsDisplay)
Players.PlayerRemoving:Connect(updateBoostsDisplay)
Network.Fired(Network.NET_MAP.InviteFriends.ON_INVITE_SUCCESS):Connect(function() -- line: 59
	-- upvalues: Confetti (copy)
	Confetti.Play()
end)

return {}

