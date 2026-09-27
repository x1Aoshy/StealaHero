-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBWVycm9yPUF0dGVtcHRlZCB0byBpbmRleCBtaXNzaW5nIGtleSAnJSonIGluIHJlZ2lzdHJ5OiAocm9vdDogJyUqJykGZm9ybWF0B19faW5kZXg3QXR0ZW1wdGVkIHRvIHNldCBuZXcga2V5ICclKicgaW4gcmVnaXN0cnk6IChyb290OiAnJSonKQpfX25ld2luZGV4BXRhYmxlCG9wdGlvbmFsBnN0cmluZwd1bmtub3duDHNldG1ldGF0YWJsZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMABAcCAQAAAAukAgEAAAAAQG8DAgBSBQEA+wYAALwDA40DAAAAnwMEAowEAgCfAgMBggABAAQDAQQAAABAAwIDAwAPBAEYAAAAAAAAAAAAAAEQAAAAAAcCAQAAAAukAgEAAAAAQG8DAgBSBQEA+wYAALwDA40DAAAAnwMEAowEAgCfAgMBggABAAQDAQQAAABAAwUDAwASBgEYAAAAAAAAAAAAAAETAAAAAAcCAQAABwQAAAUCD4Md+wIAAE0CAksAAAAAUgMAAJ8CAgH7AgAATQICEQEAAABNAgJBAgAAAFIDAQCfAgIBkAIBA+IFBgDZBgAAEgACADAGBW4EAAAA2QYBABIAAgAwBgXOBQAAAJ49AAQFAAAAUgQAAKQDCAAAAHBAnwMDAYIAAgAJAwcDCAMJAwoDBAMGBQIEBQMLBAAAcEACAAEIAAEYAAAAAAABAAAAAAAAAgIBAAAAAwAAAAAAAPwAAAkJAAAAAAMAAAECABGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAsACCAASAAEAggICAAkDDAQAAABAAw0DDgMPBAAAQEADEAMRBgIBAgEAARgAAQAAAAAAAwAAAAAAAAMAAAEAAAAAAxC2urpLF8WdOQy1vnBFSqtgrq3OInLQuw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1, s1: string?) -- line: 8
	-- upvalues: Asserts (copy)
	Asserts.table(p1)
	Asserts.optional.string(s1)

	local v5 = s1 or "unknown"

	setmetatable(p1, {
		__index = function(_, p3) -- line: 15
			-- upvalues: v5 (copy)
			error(`Attempted to index missing key '{ p3 }' in registry: (root: '{ v5 }')`, 2.0)
		end,
		__newindex = function(_, p5) -- line: 18
			-- upvalues: v5 (copy)
			error(`Attempted to set new key '{ p5 }' in registry: (root: '{ v5 }')`, 2.0)
		end
	})

	return p1
end

