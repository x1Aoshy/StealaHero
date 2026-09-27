-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
--!native
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local RunService = game:GetService("RunService")
local Cache = require(game.ReplicatedStorage.UserGenerated.Concurrency.Cache)
local Asserts = require(game.ReplicatedStorage.UserGenerated.Lang.Asserts)
local v6 = Cache.new({
	MaxAge = 1e999,
	Callback = function(p1) -- line: 38
		-- upvalues: GroupService (copy)
		return GroupService:GetGroupsAsync(p1)
	end,
	AssertKey = Asserts.Integer
})

Players.PlayerRemoving:Connect(function(player) -- line: 44
	-- upvalues: Players (copy), v6 (copy)
	local UserId = player.UserId

	task.delay(60.0, function() -- line: 47
		-- upvalues: Players (copy), UserId (copy), v6 (copy)
		if not Players:GetPlayerByUserId(UserId) then
			v6:Delete(UserId)
		end
	end)
end)

if RunService:IsServer() then
	Players.PlayerAdded:Connect(function(player) -- line: 54
		-- upvalues: v6 (copy)
		v6:GetAsync(player.UserId)
	end)
else
	task.spawn(function() -- line: 58
		-- upvalues: v6 (copy), Players (copy)
		v6:GetAsync(Players.LocalPlayer.UserId)
	end)
end

local t1 = {
	Cache = v6,
	GetGroupsAsync = function(n1: number, b1: boolean?) -- line: 67
		-- upvalues: Asserts (copy), v6 (copy)
		Asserts.Integer(n1)
		Asserts.Optional(Asserts.Boolean)(b1)

		if b1 then
			return v6:Get(n1)
		end

		return v6:GetAsync(n1)
	end
}

return table.freeze(t1)

