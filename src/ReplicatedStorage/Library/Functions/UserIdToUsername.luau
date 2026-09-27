-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJFkdldE5hbWVGcm9tVXNlcklkQXN5bmMRR2V0UGxheWVyQnlVc2VySWQETmFtZQVwY2FsbAI/PwM/Pz8EZ2FtZQdQbGF5ZXJzCkdldFNlcnZpY2UAAwMAAgAAAAb7AAAA+wIBALwAAPQAAAAAnwADAIIAAAABAwEAEQABGAAAAAAAABIAAAAABgECAAAAHvsCAACHAQIADgEBAIIBAgD7AgEAUgQAALwCAmEAAAAAnwIDAg4CBQBNAwK6AQAAAPsEAABqAwQAggMCAKQDAwAAACBA2QQAABICAQASAAAAnwMCAysDAgBvBQQAggUCACsEAgBvBQUAggUCAPsFAABqBAUAggQCAAYDAgMDAwQEAAAgQAMFAwYBAAQAARgAAAEBAwAAAAABAQABAAEDAAAAAAADAQACAQACAAEFAAAAAAMAAAECAA2jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMC/wEAAAAAAADAAgQAEgABABIAAACCAgIABQMHBAAAAEADCAMJBgEBAQEAARgAAAAAAAAAAQACAAAAAQAAAAACni8e3yLFsPl1QDWJ9MZRyu43Caus63Te

-- decompilation:
local Players = game:GetService("Players")
local t1 = {}

return function(p1) -- line: 4
	-- upvalues: t1 (copy), Players (copy)
	local v4 = t1[p1]

	if v4 then
		return v4
	end

	local PlayerByUserId = Players:GetPlayerByUserId(p1)

	if PlayerByUserId then
		local PlayerByUserIdName = PlayerByUserId.Name

		t1[p1] = PlayerByUserIdName

		return PlayerByUserIdName
	end

	local ok, result = pcall(function() -- line: 17
		-- upvalues: Players (copy), p1 (copy)
		return Players:GetNameFromUserIdAsync(p1)
	end)

	if not ok then
		return "??"
	end

	if not result then
		return "???"
	end

	t1[p1] = result

	return result
end

