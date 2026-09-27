return {
	Name = "setSpeedPower",
	Aliases = { "setSpeed", "speed" },
	Description = "Sets the target player(s) SpeedPower to the given amount.",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "Players",
			Description = "The players to set speed on.",
		},
		{
			Type = "integer",
			Name = "Amount",
			Description = "The SpeedPower value to set.",
		},
	},

	Run = function(context, players, amount)
		local Remote = game:GetService("ReplicatedStorage")
			:WaitForChild("CmdrAdmin_SetSpeedPower", 5)
		if not Remote then
			return "CmdrAdmin_SetSpeedPower remote not found (server handler not loaded)"
		end
		local userIds = {}
		for _, player in ipairs(players) do
			table.insert(userIds, player.UserId)
		end
		Remote:FireServer(userIds, amount)
		return string.format("Requested SpeedPower=%d for %d player(s).", amount, #userIds)
	end,
}
