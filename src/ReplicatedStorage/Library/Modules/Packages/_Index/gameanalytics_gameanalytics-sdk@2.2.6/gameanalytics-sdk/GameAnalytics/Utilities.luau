-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHE2lzU3RyaW5nTnVsbE9yRW1wdHkGaXBhaXJzGXN0cmluZ0FycmF5Q29udGFpbnNTdHJpbmcFcGFpcnMGdHlwZW9mBXRhYmxlCWNvcHlUYWJsZQAEBAIAAAAACFYCAQArAgUAHAMBAA0DAgAAAAAAqQIAAakCAQCCAgIAAQIAAAAAAAAAAAADAQEYAAAAAAAAAAAEAAAAAAkDAAAAABIcAwEADQMDAAAAAICpAwAAggMCAKQDAgAAABBAUgQBAJ8DAgRRAwQAmgcDAAIAAACpCAEAgggCAG4D+/8CAACAqQMAAIIDAgADAgAAAAAAAAAAAwIEAAAQQAAHAwEYAAAAAQADAAAAAAEAAQD+AAYACAAAAAALAgAAAAAY/wIAAAAAAACkAwEAAAAAQFIEAQCfAwIEFwMOALssBwNSCQcApAgDAAAAIECfCAIC8AgHAAQAAIBSCgcAvAgANQUAAACfCAMCaggCBmUAAQBqBwIGbgPx/wIAAACCAgIABgMEBAAAAEADBQQAACBAAwYDBwAVBwEYAAABAAAAAAEAAAAAAAABAAAAAAAC/AAHFgAAAAACAAABAgANowAAAP8AAwAAAAAAwAEAADABAK0BAAAAwAECADABAD0DAAAAwAEEADABADUFAAAAggACAAYGAAMBBgEDAwYCAwcDAAECAQABGAAAAAIAAAQAAA4AAAwBAAAAAAOSV6Qsi1QQpjUR3f8Eh8zF4k+zWKCTzi0=

-- decompilation:
return {
	isStringNullOrEmpty = function(_, p2) -- line: 3
		return not p2 or #p2 == 0.0
	end,
	stringArrayContainsString = function(_, p4, p5) -- line: 7
		if #p4 == 0.0 then
			return false
		end

		for _, v in ipairs(p4) do
			if v == p5 then
				return true
			end
		end

		return false
	end,
	copyTable = function(p6, p7) -- line: 21
		local t1 = {}

		for k, v in pairs(p7) do
			if typeof(v) == "table" then
				t1[k] = p6:copyTable(v)
			else
				t1[k] = v
			end
		end

		return t1
	end
}

