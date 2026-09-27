-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPCURyb3BUYWJsZQ9Jc0V2ZW50Q2F0ZWdvcnkOR2V0VG90YWxXZWlnaHQGUmFuZG9tA25ldwpOZXh0TnVtYmVyBFJvbGwLRGVtb25pYyBFZ2cORWdnRGlzcGxheU5hbWUJRGVtb24gSW1wCUhlbGxob3VuZAhHYXJnb3lsZQhNaW5vdGF1cgZCYWxyb2cQQXJjaGRlbW9uIERyYWdvbgAEBwEBAAAGAwAABQGDE0cAAwAAAACAqQEAAIIBAgD7AQAATQEBfQAAAADGAgAAxgMAAGQBBQATBgUAmgYDAAAAAACpBgEAggYCAG4B+v8CAAAAqQEAAIIBAgABAwEAEQIBGAAAAQADAAAAAAABAAABAP4ABgASAAAAAAcAAQAAAAyMAAAA+wEAAE0BAX0AAAAAxgIAAMYDAABkAQIAEwYFAUMAAAZuAf3/AgAAAIIAAgABAwEAHwMBGAABAAAAAAABAP8AAyAAAAAACwEBAAAGAwAABQGHL1IBAAArAQMApAECAAAEAICfAQEC+wIAAE0CAgQDAAAAnwIBAowDAAB9AgcAAwAAAPsFAABNBQV9BAAAABMEBQATAwQAggMCALwEAYUFAAAAnwQCAgkDBAKMBAAA+wUAAE0FBX0EAAAAxgYAAMYHAABkBQYAEwoJAUMEBAp9AwMABAAAABMKCQCCCgIAbgX5/wIAAAD7BwAATQcHfQQAAAD7CQAATQkJfQQAAAAcCAkAhwYHCBMFBgCCBQIABgMEAwUEAAQAgAMDAwEDBgAnBwEYAAAAAAABAAAAAQAAAQAAAAAAAwAAAAEBAAAAAAABAAEAAQD9AAcAAAAAAAAAAAAoAAAAAAoAAAECAD2jAAAA/wAEAAAAAABvAQAAMAEA6QEAAAD/AQAABgAAAP8CAAACAAAAbwMCAIwEKgDFAgMDAQAAAP8DAAACAAAAbwQDAIwFHADFAwQDAQAAAP8EAAACAAAAbwUEAIwGDwDFBAUDAQAAAP8FAAACAAAAbwYFAIwHCgDFBQYDAQAAAP8GAAACAAAAbwcGAG8IBwDFBgcDAQAAAP8HAAACAAAAbwgIAG8JCQDFBwgDAQAAAMUBAgcBAAAAMAEAfQoAAADAAQsAEgAAADABAAUMAAAAwAENABIAAAAwAQAEDgAAAMABDwASAAAAMAEAqhAAAACCAAIAEQMIAwkDCgMLAwwDDQMOApqZmZmZmRNAAw8CmpmZmZmZuT8DAQYAAwIGAQMDBgIDBwMAAQIBAAEYAAMAAgAAAgABAAAAAAABAAAAAAABAAAAAAABAAAAAAABAAAAAAABAAAAAAAAAPoACQAAAA4AAAAIAAAAEwEAAAAAAxhy6ftno7S/6fcSEY7Ko+Joav6PKraD+g==

-- decompilation:
local t1 = {
	EggDisplayName = "Demonic Egg",
	DropTable = {
		{
			"Demon Imp",
			42.0
		},
		{
			"Hellhound",
			28.0
		},
		{
			"Gargoyle",
			15.0
		},
		{
			"Minotaur",
			10.0
		},
		{
			"Balrog",
			4.9
		},
		{
			"Archdemon Dragon",
			0.1
		}
	}
}

function t1.IsEventCategory(s1: string?) -- line: 17
	-- upvalues: t1 (copy)
	if s1 == nil then
		return false
	end

	for _, v4 in t1.DropTable do
		if s1 == v4[1.0] then
			return true
		end
	end

	return false
end
function t1.GetTotalWeight() -- line: 31
	-- upvalues: t1 (copy)
	local n1 = 0.0

	for _, v7 in t1.DropTable do
		n1 += v7[2.0]
	end

	return n1
end
function t1.Roll(p1) -- line: 39
	-- upvalues: t1 (copy)
	local v9 = p1 or Random.new()
	local v10 = t1.GetTotalWeight()

	if v10 <= 0.0 then
		return t1.DropTable[1.0][1.0]
	end

	local v11 = v9:NextNumber() * v10
	local n2 = 0.0

	for _, v14 in t1.DropTable do
		n2 += v14[2.0]

		if v11 <= n2 then
			return v14[1.0]
		end
	end

	return t1.DropTable[#t1.DropTable][1.0]
end

return t1

