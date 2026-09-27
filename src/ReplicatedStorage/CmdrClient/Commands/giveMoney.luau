return {
	Name = "giveMoney",
	Aliases = { "money", "cash" },
	Description = "Gives the target player(s) Money.",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "Players",
			Description = "The players to give money to.",
		},
		{
			Type = "integer",
			Name = "Amount",
			Description = "The amount of money to give.",
		},
	},

	-- Client-side runner. Cmdr in this game only wires up its Registry on the
	-- client (see ReplicatedStorage.CmdrClient line 102), which means the
	-- traditional "commandNameServer" pattern would never load. Instead we
	-- fire a dedicated RemoteEvent that ServerScriptService.CmdrAdminHandler
	-- validates against its admin whitelist and applies to the real profile.
	Run = function(context, players, amount)
		local Remote = game:GetService("ReplicatedStorage")
			:WaitForChild("CmdrAdmin_GiveMoney", 5)
		if not Remote then
			return "CmdrAdmin_GiveMoney remote not found (server handler not loaded)"
		end
		local userIds = {}
		for _, player in ipairs(players) do
			table.insert(userIds, player.UserId)
		end
		Remote:FireServer(userIds, amount)
		return string.format("Requested +%d money for %d player(s).", amount, #userIds)
	end,
}
