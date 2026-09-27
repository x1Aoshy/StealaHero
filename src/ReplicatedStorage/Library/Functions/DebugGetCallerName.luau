-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPCG9wdGlvbmFsBm51bWJlcgVkZWJ1ZwRpbmZvAXMJKFteJS5dLSkkBW1hdGNoABJEZWJ1Z0dldENhbGxlck5hbWUHcmVxdWlyZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHTGlicmFyeQdBc3NlcnRzAAIFAQEAAAYDAAAFAYIU+wEAAE0BAREAAAAATQEBYAEAAABSAgAAnwECAaQBBAAADCCAkAIABW8DBgCfAQMCDgEFAG8EBwC8AgHnCAAAAJ8CAwIrAgEAbwIJAIICAgAKAwEDAgMDAwQEAAwggAIAAAAAAAAQQAMFAwYDBwMIAAMJARgAAAAAAAAAAQAAAAABAAAAAAAAAAQAAAAABAAAAQIAEaMAAACkAAEAAAAAQKQBAwAAACBAbwMEALwBARYFAAAAnwEDAk0BAWoGAAAATQEBiQcAAACfAAICwAEIABIAAACCAQIACQMKBAAAAEADCwQAACBAAwwDDQMOAw8GAAEAAQABGAAAAAAAAAAAAAAAAAAAAgAGAQAAAAABu3Qq4OUc9yy2tsCYvJdBwctsPZSJsEDh

-- decompilation:
local Asserts = require(game:GetService("ReplicatedStorage").Library.Asserts)

local function DebugGetCallerName(n1: number?) -- line: 3
	-- upvalues: Asserts (copy)
	Asserts.optional.number(n1)

	local v4 = debug.info(n1 or 4.0, "s")

	return v4 and v4:match("([^%.]-)$") or ""
end

return DebugGetCallerName

