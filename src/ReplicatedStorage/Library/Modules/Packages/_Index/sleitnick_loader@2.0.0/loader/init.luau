-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRC0dldENoaWxkcmVuDE1vZHVsZVNjcmlwdANJc0EHcmVxdWlyZQROYW1lDExvYWRDaGlsZHJlbg5HZXREZXNjZW5kYW50cw9Mb2FkRGVzY2VuZGFudHMFbWF0Y2gLTWF0Y2hlc05hbWUFZGVidWcRc2V0bWVtb3J5Y2F0ZWdvcnkEdHlwZQhmdW5jdGlvbgR0YXNrBXNwYXduCFNwYXduQWxsAAcLAgAAAAcEAAAFAgeFGv8CAAAAAAAAvAMAaAAAAACfAwIEZAMRAG8KAQC8CAf+AgAAAJ8IAwIOCAwADgEEAFIIAQBSCQcAnwgCAg4IBwCkCAQAAAAwQFIJBwCfCAICTQkHugUAAABqCAIJbgPu/wIAAACCAgIABgMBAwIDAwMEBAAAMEADBQAsBgEYAAABAAAAAQAAAAABAAAAAAMAAAABAAD6AAktAAAAAAsCAAAABwQAAAUCB4Ua/wIAAAAAAAC8AwBHAAAAAJ8DAgRkAxEAbwoBALwIB/4CAAAAnwgDAg4IDAAOAQQAUggBAFIJBwCfCAICDggHAKQIBAAAADBAUgkHAJ8IAgJNCQe6BQAAAGoIAgluA+7/AgAAAIICAgAGAwcDAgMDAwQEAAAwQAMFAEoIARgAAAEAAAABAAAAAAEAAAAAAwAAAAEAAPoACUsAAAAABQEBAAAGAwAABQEHC00CALoAAAAA+wQAALwCAucBAAAAnwIDAkcCAgAAAACAqQEAAakBAQCCAQIAAgMFAwkAYgABGAAAAAAAAAAAAAAAYwAAAAACAQAAAAYDAAAFAQMD2QEAABIAAACCAQIAAAECYQoBGAAAAGIAAAAAAgADAAAACKQAAgAABACA+wEAAJ8AAgH7AAEA+wECAJ8AAgGCAAEAAwMLAwwEAAQAgACBAQABGAAAAAABAAABggAAAAAKAgAAAAcEAAAFAgQDFlICAADGAwAAxgQAAGQCDwCHBwYBuygHA1IJBwCkCAEAAAAAQJ8IAgLwCAgAAgAAgKQIBQAAEDCA2QkAABIABQASAAcAEgAGAJ8IAgFuAvD/AgAAAIIAAQAGAw0EAAAAQAMOAw8DEAQAEDCAAQR9EQEYAAAAAAEBAAAAAAAAAQAAAAAAAP0ACX4AAAAAAgAAAQIAEKMAAAD/AAMAAAAAAMABAAAwAQB+AQAAAMABAgAwAQCdAwAAAMABBAAwAQA1BQAAAMABBgAwAQDqBwAAAIIAAgAIBgADBgYBAwgGAwMKBgUDEQQAAQMFAQABGAARABoAAB4AABcAABwAAAwBAAAAAAZqtlCtTBIMWNE9Pqi4hBA/Gq5H2VhyOqw=

-- decompilation:
return {
	LoadChildren = function(p1, p2: ((...any) -> ...any)?) -- line: 44
		local t1 = {}

		for _, child in p1:GetChildren() do
			if child:IsA("ModuleScript") and (not p2 or p2(child)) then
				local lib = require(child)

				t1[child.Name] = lib
			end
		end

		return t1
	end,
	LoadDescendants = function(p3, p4: ((...any) -> ...any)?) -- line: 74
		local t2 = {}

		for _, descendant in p3:GetDescendants() do
			if descendant:IsA("ModuleScript") and (not p4 or p4(descendant)) then
				local lib = require(descendant)

				t2[descendant.Name] = lib
			end
		end

		return t2
	end,
	MatchesName = function(s1: string) -- line: 97
		return function(p5) -- line: 98
			-- upvalues: s1 (copy)
			return p5.Name:match(s1) ~= nil
		end
	end,
	SpawnAll = function(t3: {[any]: any}, s2: string) -- line: 125
		for v16, v17 in t3 do
			local v18 = v17[s2]

			if type(v18) == "function" then
				task.spawn(function() -- line: 129
					-- upvalues: v16 (copy), v18 (copy), v17 (copy)
					debug.setmemorycategory(v16)
					v18(v17)
				end)
			end
		end
	end
}

