-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(script:FindFirstAncestor("Products").Types.Interface)

return function(s1: string, n1: number) -- line: 16
	-- upvalues: Asserts (copy), ServerScriptService (copy), ReplicatedStorage (copy)
	Asserts.string(s1)
	Asserts.number(n1)

	local num = tonumber((s1:gsub("Money_", ""):gsub("%D", "")))

	assert(num ~= nil, "Money product name must include a numeric reward amount")
	assert(num > 0.0, "Money reward must be positive")

	local function ensureDataLoaded(p1) -- line: 25
		if p1 then
			return true
		end

		return false, "Player data is not loaded yet."
	end

	return {
		Desc = "Purchase bonus money!",
		LockWhileProcessing = true,
		ProductId = n1,
		DisplayName = s1,
		ServerTest = function(p2) -- line: 33
			-- upvalues: ServerScriptService (copy), ensureDataLoaded (copy)
			local v10, v11 = require(ServerScriptService.Library.Database).UnsafeGetProfileAwait(p2)

			if not v10 then
				return false, "Failed to retrieve player data."
			end

			return ensureDataLoaded(v11)
		end,
		ClientTest = function() -- line: 43
			-- upvalues: ReplicatedStorage (copy), ensureDataLoaded (copy)
			local v12 = require(ReplicatedStorage.Library.Client.Save).Get()

			return ensureDataLoaded(v12)
		end,
		Callback = function(p3) -- line: 50
			-- upvalues: ServerScriptService (copy), num (copy)
			require(ServerScriptService.Controllers.MoneyService).AddMoney(p3, num)

			return true
		end
	}
end

