-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)
local Players = game:GetService("Players")
local t1 = {}

local function getUserId(p1) -- line: 5
	-- upvalues: t1 (copy), Players (copy)
	if t1[p1] then
		return t1[p1]
	end

	if Players:FindFirstChild(p1) then
		t1[p1] = Players[p1].UserId

		return Players[p1].UserId
	end

	local ok, result = pcall(Players.GetUserIdFromNameAsync, Players, p1)

	if not ok then
		return nil
	end

	t1[p1] = result

	return result
end

local t2 = {
	DisplayName = "Full Player Name",
	Prefixes = "# integer",
	Transform = function(p2) -- line: 27
		-- upvalues: Util (copy), Players (copy)
		return p2, Util.MakeFuzzyFinder(Players:GetPlayers())(p2)
	end,
	ValidateOnce = function(p3) -- line: 33
		-- upvalues: t1 (copy), Players (copy)
		local v11

		if t1[p3] then
			v11 = t1[p3]
		elseif Players:FindFirstChild(p3) then
			t1[p3] = Players[p3].UserId
			v11 = Players[p3].UserId
		else
			local ok

			ok, v11 = pcall(Players.GetUserIdFromNameAsync, Players, p3)

			if not ok then
				v11 = nil
			else
				t1[p3] = v11
			end
		end

		return v11 ~= nil, "No player with that name could be found."
	end,
	Autocomplete = function(_, p5) -- line: 37
		-- upvalues: Util (copy)
		return Util.GetNames(p5)
	end,
	Parse = function(p6) -- line: 41
		-- upvalues: t1 (copy), Players (copy)
		if t1[p6] then
			return t1[p6]
		end

		if Players:FindFirstChild(p6) then
			t1[p6] = Players[p6].UserId

			return Players[p6].UserId
		end

		local ok, result = pcall(Players.GetUserIdFromNameAsync, Players, p6)

		if not ok then
			return nil
		end

		t1[p6] = result

		return result
	end,
	Default = function(p7) -- line: 45
		return p7.Name
	end,
	ArgumentOperatorAliases = {
		me = ".",
		all = "*",
		others = "**",
		random = "?"
	}
}

return function(p8) -- line: 57
	-- upvalues: t2 (copy), Util (copy)
	p8:RegisterType("playerId", t2)
	p8:RegisterType("playerIds", Util.MakeListableType(t2, {
		Prefixes = "# integers"
	}))
end

