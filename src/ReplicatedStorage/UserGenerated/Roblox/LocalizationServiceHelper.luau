-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
--!native
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Cache = require(ReplicatedStorage.UserGenerated.Concurrency.Cache)
local Asserts = require(ReplicatedStorage.UserGenerated.Lang.Asserts)
local v7 = Cache.new({
	Callback = function(p1) -- line: 29
		-- upvalues: Players (copy), LocalizationService (copy)
		local PlayerByUserId = Players:GetPlayerByUserId(p1)

		assert(PlayerByUserId, "PlayerNotOnline")

		return LocalizationService:GetCountryRegionForPlayerAsync(PlayerByUserId)
	end,
	AssertKey = Asserts.Integer
})

Players.PlayerRemoving:Connect(function(player) -- line: 36
	-- upvalues: Players (copy), v7 (copy)
	local UserId = player.UserId

	task.delay(60.0, function() -- line: 39
		-- upvalues: Players (copy), UserId (copy), v7 (copy)
		if not Players:GetPlayerByUserId(UserId) then
			v7:Delete(UserId)
		end
	end)
end)

if RunService:IsServer() then
	Players.PlayerAdded:Connect(function(player) -- line: 46
		-- upvalues: v7 (copy)
		v7:GetAsync(player.UserId)
	end)
else
	task.spawn(function() -- line: 50
		-- upvalues: v7 (copy), Players (copy)
		v7:GetAsync(Players.LocalPlayer.UserId)
	end)
end

local t1 = {
	GetCountryRegionForPlayerAsync = function(p2, b1: boolean?) -- line: 57
		-- upvalues: Asserts (copy), v7 (copy)
		Asserts.Player(p2)
		Asserts.Optional(Asserts.Boolean)(b1)

		if b1 then
			return v7:Get(p2.UserId)
		end

		return v7:GetAsync(p2.UserId)
	end
}

return table.freeze(t1)

