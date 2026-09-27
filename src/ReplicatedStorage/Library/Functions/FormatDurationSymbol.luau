-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBm51bWJlcgRtYXRoA21heARjZWlsAyUqbQZmb3JtYXQHJSptICUqcwMlKmgHJSpoICUqbQMlKmQHJSpkICUqaARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQZzY3JpcHQGUGFyZW50DkZvcm1hdER1cmF0aW9uB0xpYnJhcnkHQXNzZXJ0cwACCAECAAAGAwAABQECVfsBAABNAQFgAAAAAFICAACfAQIBgRIABQEAAABSAwAAbwQBAKQCBAAADCCAnwIDArsHAgKkAQYAABQggJ8BAgKMAjwAYAEFAAIAAAD7AgEAUgMBAJ8CAgCCAgAAjAIQDmABEwACAAAAtgIBByEDAQeMBAAAfQMHAAQAAABvBAgAUgYCALwEBI0JAAAAnwQDAoIEAgBvBAoAUgYCAFIHAwC8BASNCQAAAJ8EBAKCBAIAbwILAGABFAACAAAAtgIBDCEEAQy2AwQHjAQAAH0DBwAEAAAAbwQNAFIGAgC8BASNCQAAAJ8EAwKCBAIAbwQOAFIGAgBSBwMAvAQEjQkAAACfBAQCggQCALYCAQshBAELtgMEDIwEAAB9AwcABAAAAG8EDwBSBgIAvAQEjQkAAACfBAMCggQCAG8EEABSBgIAUgcDALwEBI0JAAAAnwQEAoIEAgARAwECAAAAAAAAAAADAgMDBAAMIIADBAQAFCCAAgAAAAAAAE5AAwUDBgMHAgAAAAAAGPVAAgAAAAAAIKxAAwgDCQMKAwsACwABGAAAAAAAAgAAAAAAAAAAAAAGAAABAAAAAwAAAQEBAAABAAAAAAACAAAAAAAAAQAAAQEAAQAAAQAAAAAAAgAAAAAAAAIBAAEAAAEAAAAAAAIAAAAAAAAMAAAAAAQAAAECABujAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICXAkAAACfAQICpAIFAAAAQEBNAwBqCgAAAE0DA4kLAAAAnwICAsADDAASAAIAEgABAIIDAgANAwwEAAAAQAMNAw4DDwQAAEBAAxAEAABgQAMRAxIDEwMUBgABAAEAARgAAwAAAAAAAwAAAAAAAAAAAQAAAAAAAAMAAAABAAAAAAFRHc+Afywaz2j8dnICk++pIQXY9GPZpYE=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatDuration = require(script.Parent.FormatDuration)
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(n1: number) -- line: 11
	-- upvalues: Asserts (copy), FormatDuration (copy)
	Asserts.number(n1)

	local v5 = math.ceil((math.max(n1, 0.0)))

	if v5 < 60.0 then
		return FormatDuration(v5)
	end

	if v5 < 3600.0 then
		local v6 = v5 // 60.0
		local v7 = v5 % 60.0

		if v7 <= 0.0 then
			return `{ v6 }m`
		end

		return `{ v6 }m { v7 }s`
	end

	if v5 < 86400.0 then
		local v8 = v5 // 3600.0
		local v9 = v5 % 3600.0 // 60.0

		if v9 <= 0.0 then
			return `{ v8 }h`
		end

		return `{ v8 }h { v9 }m`
	end

	local v10 = v5 // 86400.0
	local v11 = v5 % 86400.0 // 3600.0

	if v11 <= 0.0 then
		return `{ v10 }d`
	end

	return `{ v10 }d { v11 }h`
end

