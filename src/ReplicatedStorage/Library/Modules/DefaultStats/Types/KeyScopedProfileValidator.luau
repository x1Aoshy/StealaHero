-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNHkludmFsaWQgcHJvZmlsZSBmaWVsZCAnJSonOiAlKg9zY2hlbWEgbWlzbWF0Y2gGZm9ybWF0FHZhbGlkYXRlQ2hhbmdlZEZpZWxkBnR5cGVvZgV0YWJsZRxwcm9maWxlIGRhdGEgbXVzdCBiZSBhIHRhYmxlGUtleVNjb3BlZFByb2ZpbGVWYWxpZGF0b3IHcmVxdWlyZQZzY3JpcHQGUGFyZW50DFNjaGVtYUZpZWxkcwlJbnZlbnRvcnkAAwoCAQAABwQAAAUCAw8T+wMAAIcCAwArAgIAqQMBAIIDAgBSAwIAUgQBAJ8DAgMOAwIAqQUBAIIFAgCpBQAAbwYAAFIIAACQCQQBvAYGjQIAAACfBgQCggUDAAMDAQMCAwMADwQBGAAAAQEAAwAAAQEAAwAAAAAAAAAQAAAAABICAgAAAF27LAADUgMAAKQCAQAAAABAnwICAvACBAACAAAAqQIAAG8DAwCCAgMAuywBA1IDAQCkAgEAAAAAQJ8CAgLwAiMAAgAAAPsCAADGAwAAxgQAAGQCGgCHCQAF+wsAAIcKCwUrCgMAqQcBAMYIAABlAA8AUgsKAFIMCQCfCwIDDgsDAKkHAQDGCAAAZQAIAKkHAABvDQQAUg8FAJAQDAW8DQ2NBgAAAJ8NBAJSCA0AKwcDAKkJAABSCggAggkDAG4C5f8BAAAAqQIBAIICAgD7AgAAxgMAAMYEAABkAiIAhwcABYcIAQWaBwQACAAAAPsKAQCHCQoFKwkbAPEHGgAIAAAA+wwAAIcLDAUrCwMAqQkBAMYKAABlAA8AUgwLAFINBwCfDAIDDgwDAKkJAQDGCgAAZQAIAKkJAABvDgQAUhAFAJARDQW8Dg6NBgAAAJ8OBAJSCg4AKwkDAKkLAABSDAoAggsDAG4C3f8BAAAAqQIBAIICAgAHAwUEAAAAQAMGAwcDAQMCAwMAHQgBGA4AAAAAAAABAAADAAAAAAAAAQAAAALrAAEBAAADAAABAQAAAwAAAAAAAAAMAQAA/AAHAAMAAAACAQIAAAAABADaAAEBAAADAAABAQAAAwAAAAAAAAAeAQAA9AARABAAAAAABAAAAQIAEaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQFvBQAAAJ8AAgLiAQgAwAIJABIAAADAAwoAEgAAABIAAQCCAwIACwMJBAAAAEADCgQAACBAAwsDDAMNAQEIAQYHAAAABgAGAQIAAQEAARgAAwAAAAAAAAAABgUADgAAJAEAAAAAAoCxA9oUwsIWDqlMmXmG3KLwqRSusnVp2w==

-- decompilation:
local SchemaFields = require(script.Parent.SchemaFields)
local t1 = {
	Inventory = true
}

local function validateChangedField(s1: string, p1) -- line: 15
	-- upvalues: SchemaFields (copy)
	local v7 = SchemaFields[s1]

	if not v7 then
		return true
	end

	local v8, v9 = v7(p1)

	if v8 then
		return true
	end

	return false, `Invalid profile field '{ s1 }': { v9 or "schema mismatch" }`
end
local function KeyScopedProfileValidator(p2, p3) -- line: 29
	-- upvalues: SchemaFields (copy), t1 (copy)
	if typeof(p2) ~= "table" then
		return false, "profile data must be a table"
	end

	if typeof(p3) ~= "table" then
		for v12 in SchemaFields do
			local v13 = p2[v12]
			local v14 = SchemaFields[v12]
			local v15, v16

			if not v14 then
				v15 = true
				v16 = nil
			else
				local v17, v18 = v14(v13)

				if v17 then
					v15 = true
					v16 = nil
				else
					v15 = false
					v16 = `Invalid profile field '{ v12 }': { v18 or "schema mismatch" }`
				end
			end

			if not v15 then
				return false, v16
			end
		end

		return true
	end

	for v19 in SchemaFields do
		local v20 = p2[v19]
		local v21 = p3[v19]

		if v20 == v21 and t1[v19] or v20 == v21 then
			continue
		end

		local v22 = SchemaFields[v19]
		local v23, v24

		if not v22 then
			v23 = true
			v24 = nil
		else
			local v25, v26 = v22(v20)

			if v25 then
				v23 = true
				v24 = nil
			else
				v23 = false
				v24 = `Invalid profile field '{ v19 }': { v26 or "schema mismatch" }`
			end
		end

		if not v23 then
			return false, v24
		end
	end

	return true
end

return KeyScopedProfileValidator

