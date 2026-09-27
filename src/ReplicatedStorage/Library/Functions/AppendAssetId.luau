-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBnN0cmluZwh0b251bWJlch9NdXN0IGJlIGEgdmFsaWQgZXh0ZW5zaW9uIHR5cGUuBmFzc2VydAQlKiUqA14lKgZmb3JtYXQEZmluZAAGQXBwZW5kBFdyYXAHcmVxdWlyZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHTGlicmFyeQdBc3NlcnRzCnJieGFzc2V0aWQNcmJ4YXNzZXRpZDovLwAECwICAAAHBAAABQIDAyb7AgAATQICQQAAAABSAwAAnwICAbs+AQNSAwEApAICAAAAEECfAgICKwIBAIIBAgD7BAEAhwMEAIEBAwQDAAAAbwQDAKQCBQAAAEBAnwIDAm8DBgBvCAcAUgoCALwICI0IAAAAnwgDArwGAVYJAAAAnwYDAg4GAgBvBQoAZQABAFIFAgBSBgEAvAMDjQgAAACfAwQCggMCAAsDAQMCBAAAEEADAwMEBAAAQEADBQMGAwcDCAMJAAsKARgAAAAAAAEAAAAAAAEDAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAwAAAAAAwACAQAACKMAAAD7AAAATQAA/AAAAAD7AQEA3QIAAJ8AAACCAAAAAQMKABYAARgAAQAAAAAAABYAAAAAAgEBAAAGAwAABQEDBNkBAAASAgAAEgAAAIIBAgAAAQEVCwEYAAAAABYAAAAABAAAAQIAG6MAAACkAAEAAAAAQKQBAwAAACBAbwMEALwBARYFAAAAnwEDAk0BAWoGAAAATQEBiQcAAACfAAIC4gEKAP8CAgAAAAAAwAMLABIAAAASAAEAMAMC/AwAAADAAw0AEgACADADArUOAAAAggICAA8DDAQAAABAAw0EAAAgQAMOAw8DEAMRAxIDEwgBCAkAAAAGAAMKBgIDCwIAAgEAARgAAAAAAAAAAAAAAAAAAAIGAAIAAAAACgAAAAYBAAAAAAOIcB6AqBMbzVMtlsf7xsFn+GgJ9Lq0dIE=

-- decompilation:
local Asserts = require(game:GetService("ReplicatedStorage").Library.Asserts)
local t1 = {
	rbxassetid = "rbxassetid://"
}
local t2 = {
	Append = function(s1: string, s2: string) -- line: 11
		-- upvalues: Asserts (copy), t1 (copy)
		Asserts.string(s1)

		if not tonumber(s2) then
			return s2
		end

		local v6 = assert(t1[s1], "Must be a valid extension type.")

		return `{ (if not s2:find(`^{ v6 }`) then v6 else "") }{ s2 }`
	end
}

function t2.Wrap(s3: string) -- line: 21
	-- upvalues: t2 (copy)
	return function(...) -- line: 22
		-- upvalues: t2 (copy), s3 (copy)
		return t2.Append(s3, ...)
	end
end

return t2

