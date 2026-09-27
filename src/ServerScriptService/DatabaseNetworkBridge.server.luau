local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Database = require(ServerScriptService:WaitForChild("Library"):WaitForChild("Database"))
local Network = ReplicatedStorage:WaitForChild("Network")
local getStats = Network:WaitForChild("Get Stats")

getStats.OnServerInvoke = function(player, targetPlayer)
	local target = if typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then targetPlayer else player
	local profile = Database.WaitForProfile(target, 10)
	if not profile then
		return nil
	end
	return profile
end

Players.PlayerAdded:Connect(function(player)
	Database.WaitForProfile(player, 10)
end)