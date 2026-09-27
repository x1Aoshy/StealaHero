-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWCEJhc2VQYXJ0A0lzQQpEaXNjb25uZWN0DkdldERlc2NlbmRhbnRzD0Rlc2NlbmRhbnRBZGRlZAdDb25uZWN0BXRhYmxlBmluc2VydBJEZXNjZW5kYW50UmVtb3ZpbmcVaGFuZGxlQ2hhcmFjdGVyVXBkYXRlDkNoYXJhY3RlckFkZGVkCUNoYXJhY3Rlcg1vblBsYXllckFkZGVkEG9uUGxheWVyUmVtb3ZpbmcLUGxheWVyQWRkZWQOUGxheWVyUmVtb3ZpbmcKR2V0UGxheWVycwVzdGFydARnYW1lB1BsYXllcnMKR2V0U2VydmljZRBjaGFyYWN0ZXJPYmplY3RzAAgEAQIAAAAKbwMAALwBAP4BAAAAnwEDAisBAQCCAAEA+wEAAPsCAQBqAgEAggABAAIDAQMCABoAARgAAAAAAAECAAABGwAAAAAEAQEAAAAKbwMAALwBAP4BAAAAnwEDAisBAQCCAAEA+wEAAMYCAABqAgEAggABAAIDAQMCACQAARgAAAAAAAECAAABJQAAAAAKAgIAAAA++wUAAIcCBQDGAwAAxgQAAGQCAwC8BwYaAAAAAJ8HAgFuAvz/AgAAAPsCAQDGAwAAxgQAAGQCBQCaBgQAAAAAAPsHAQDGCAAAaggHBW4C+v8CAAAAvAIBRwEAAACfAgIEZAIHAG8JAgC8Bwb+AwAAAJ8HAwIOBwIA+wcBAGoABwZuAvj/AgAAAPsEAACHAwQATQQBZAQAAADZBgAAEgIBABIAAAC8BATHBQAAAJ8EAwBMNAACpAIIAAAcYICfAgAB+wQAAIcDBABNBAGzCQAAAMAGCgASAgEAvAQExwUAAACfBAMATDQAAqQCCAAAHGCAnwIAAYIAAQALAwMDBAMBAwIDBQMGAwcDCAQAHGCAAwkGAQIAAQYKARgAAAAAAAEAAP8AAwAAAAEAAwAA/AAHAAAAAQAAAAADAPwACAABAAAAAAAAAP4AAAALAAEAAAAAAAD+AAAACQcAAAAABAECAAAABfsBAAD7AgEAUgMAAJ8BAwGCAAEAAAAwAAEYAAAAAAExAAAAAAQBAgAAABX7AQAA/wIAAAAAAABqAgEATQEAlwAAAADZAwAAEgIBABIAAAC8AQHHAQAAAJ8BAwFNAQBpAgAAAA4BBQD7AQEAUgIAAE0DAGkCAAAAnwEDAYIAAQADAwsDBgMMAQMtDQEYAAAAAAIAAAAAAAAABAAAAQAAAAACLgAAAAAIAQIAAAAZ+wQAAIcBBADGAgAAxgMAAGQBAwC8BgUaAAAAAJ8GAgFuAfz/AgAAAPsBAADGAgAAagIBAPsBAQDGAgAAxgMAAGQBBQCaBQQAAAAAAPsGAQDGBwAAagcGBG4B+v8CAAAAggABAAEDAwA5DgEYAAAAAAABAAD/AAMAAAIAAAABAAQAAPsABzoAAAAACQADAAAAGfsAAABNAAAoAAAAAPsCAQC8AADHAQAAAJ8AAwL7AQAATQEB1AIAAAD7AwIAvAEBxwEAAACfAQMC+wIAALwCAqsDAAAAnwICBGQCAwD7BwEAUggGAJ8HAgFuAvz/AgAAAIIAAwAEAw8DBgMQAxEASBIBGAAAAAAAAAABAAAAAAAAAgAAAAABAAD/AARJAAAAAAgAAAECACKjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMC/wEAAAAAAAD/AgAAAAAAAMADBAASAAIAEgABAMAEBQASAAIAEgADAMAFBgASAAIAEgABAMAGBwASAAAAEgAEABIABQDiBwwAMAEHsQgAAAAwBgf8CQAAADAEB7YKAAAAMAUHqAsAAACCBwIADQMTBAAAAEADFAMVBgIGBAYFBgYDFgMSAw0DDgUECAkKCwQCBAUGAQABGAAAAAAAAAACAAEAAgAAJwAADAAADwAAAAsBAAEAAQABAAABAAAAAAcw85rQIwMjbzm1d33h4BxyQOuNpAI38NE=

-- decompilation:
local Players = game:GetService("Players")
local t1 = {}
local t2 = {}

local function handleCharacterUpdate(p1, p2) -- line: 6
	-- upvalues: t2 (copy), t1 (copy)
	for _, v10 in t2[p1] do
		v10:Disconnect()
	end

	for v11, v12 in t1 do
		if v12 == p1 then
			t1[v11] = nil
		end
	end

	for _, descendant in p2:GetDescendants() do
		if descendant:IsA("BasePart") then
			t1[descendant] = p1
		end
	end

	table.insert(t2[p1], p2.DescendantAdded:Connect(function(descendant) -- line: 26
		-- upvalues: t1 (copy), p1 (copy)
		if not descendant:IsA("BasePart") then
			return
		end

		t1[descendant] = p1
	end))
	table.insert(t2[p1], p2.DescendantRemoving:Connect(function(descendant) -- line: 36
		-- upvalues: t1 (copy)
		if not descendant:IsA("BasePart") then
			return
		end

		t1[descendant] = nil
	end))
end
local function onPlayerAdded(p3) -- line: 45
	-- upvalues: t2 (copy), handleCharacterUpdate (copy)
	t2[p3] = {}
	p3.CharacterAdded:Connect(function(character) -- line: 48
		-- upvalues: handleCharacterUpdate (copy), p3 (copy)
		handleCharacterUpdate(p3, character)
	end)

	if p3.Character then
		handleCharacterUpdate(p3, p3.Character)
	end
end
local function onPlayerRemoving(p4) -- line: 57
	-- upvalues: t2 (copy), t1 (copy)
	for _, v18 in t2[p4] do
		v18:Disconnect()
	end

	t2[p4] = nil

	for v19, v20 in t1 do
		if v20 == p4 then
			t1[v19] = nil
		end
	end
end

return {
	characterObjects = t1,
	start = function() -- line: 72
		-- upvalues: Players (copy), onPlayerAdded (copy), onPlayerRemoving (copy)
		local connection = Players.PlayerAdded:Connect(onPlayerAdded)
		local connection2 = Players.PlayerRemoving:Connect(onPlayerRemoving)

		for _, player in Players:GetPlayers() do
			onPlayerAdded(player)
		end

		return connection, connection2
	end,
	onPlayerAdded = onPlayerAdded,
	onPlayerRemoving = onPlayerRemoving
}

