-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBGdhbWUJV29ya3NwYWNlB0dyYXZpdHkEbWF0aARzcXJ0BGF0YW4AAhEDAAAAACCkAwEAAAAAQE0DA8oCAAAATQMDJQMAAAAEBwIEBAoCBQQOAAQJDQMOjBACAAkPEAEEEAIECQ4PEEMMDQ4JCwMMJgkKC7sZCQKkCAgAABxggJ8IAgJDBgcICQcDAOwFBge7BgUCpAQKAAAkYICfBAIC8QQCAAQAAABvBAsAggQCAAwDAQQAAABAAwIDAwIAAAAAAAAAQAIAAAAAAAAQQAMEAwUEABxggAMGBAAkYIACGC1EVPsh6T8ABAABGAAAAAAAAAMAAAAAAAAAAAAAAAAAAAABAAD+AAAFAAEDBQAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAMAAQAAAAABtw6+uWbYYNMbZ1kQ4jsXY8cWqc2FytS4

-- decompilation:
return function(p1, p2, p3) -- line: 4
	local Gravity = game.Workspace.Gravity
	local v5 = math.atan((p3 ^ 2.0 + math.sqrt(p3 ^ 4.0 - Gravity * (Gravity * p1 ^ 2.0 + 2.0 * p2 * p3 ^ 2.0))) / (Gravity * p1))

	if v5 ~= v5 then
		v5 = 0.7853981633974483
	end

	return v5
end

