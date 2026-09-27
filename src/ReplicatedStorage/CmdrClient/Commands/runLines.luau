-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcAApEaXNwYXRjaGVyA3ZhchFJTklUX1BSSU5UX09VVFBVVANSdW4CCisBCgRnc3ViBXNwbGl0BmlwYWlycwNzdWIBIw5FdmFsdWF0ZUFuZFJ1bgVSZXBseQlDbGllbnRSdW4ETmFtZQlydW4tbGluZXMHQWxpYXNlcwtEZXNjcmlwdGlvbmVTcGxpdHMgaW5wdXQgYnkgbmV3bGluZXMgYW5kIHJ1bnMgZWFjaCBsaW5lIGFzIGl0cyBvd24gY29tbWFuZC4gVGhpcyBpcyB1c2VkIGJ5IHRoZSBpbml0LXJ1biBjb21tYW5kLgVHcm91cAtEZWZhdWx0VXRpbARBcmdzBFR5cGUGc3RyaW5nBlNjcmlwdBRUaGUgc2NyaXB0IHRvIHBhcnNlLgdEZWZhdWx0AAINAgAAAAA0HAIBAA0CAwAAAACAbwIBAIICAgBNAwAKAgAAAG8FAwBvBgQAvAMDFgUAAACfAwQC8AMCAAEAAICpAgABqQIBAG8FBgBvBgcAvAMBzAgAAACfAwQCbwUHALwDA+MJAAAAnwMDAqQECwAAAKBAUgUDAJ8EAgRRBBIAjAsBAIwMAQC8CQjwDAAAAJ8JBALwCQwADQAAAE0JAAoCAAAAUgsIALwJCV4OAAAAnwkDAg4CBABSDAkAvAoA2Q8AAACfCgMBbgTt/wIAAIBvBAEAggQCABACAAAAAAAAAAADAQMCAwMDBAMFAwYDBwMIAwkDCgQAAKBAAwsDDAMNAw4ADw8BGAAAAAEAAwAAAAAAAAAAAAACAAAAAAAAAAACAAAAAAEAAAAAAAAEAAAAAAACAQAAAPgADAAQAAAAAAMAAAECABGjAAAA4gAJAP8BAAAAAAAAMAEAJwIAAAD/AQAAAQAAAOICEADFAQICAQAAADABANsHAAAAwAERADABADMIAAAAggACABIDEAMRAxIDEwMUAxUDFgMXAw8IBgABAAAAAv////8DBAAAAAUGAAAAB/////8I/////wMYAxkDGgMbAxwDAQgECgsAAAAADAAAAAMNAAAADg8AAAAGAAEAAQABGAAAAgAAAAMAAQAA/wAJAAAAAQAAAAABOblk/ISdrLgZhi3lD4ehlUmhc4gLfQ79

-- decompilation:
return {
	Name = "run-lines",
	Description = "Splits input by newlines and runs each line as its own command. This is used by the init-run command.",
	Group = "DefaultUtil",
	Aliases = {},
	Args = {{
		Type = "string",
		Name = "Script",
		Description = "The script to parse.",
		Default = ""
	}},
	ClientRun = function(p1, p2) -- line: 15
		if #p2 == 0.0 then
			return ""
		end

		local v3 = p1.Dispatcher:Run("var", "INIT_PRINT_OUTPUT") ~= ""
		local parts = p2:gsub("\n+", "\n"):split("\n")

		for _, v in ipairs(parts) do
			if v:sub(1.0, 1.0) ~= "#" then
				local v7 = p1.Dispatcher:EvaluateAndRun(v)

				if v3 then
					p1:Reply(v7)
				end
			end
		end

		return ""
	end
}

