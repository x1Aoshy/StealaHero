-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLCHRvc3RyaW5nBWRlYnVnCXRyYWNlYmFjawV0YWJsZQRwYWNrBnhwY2FsbAZ1bnBhY2sEd2FybgZzdHJpbmcGZm9ybWF0IkVycm9yOiAlcwpTdGFjayBCZWdpbgolcwpTdGFjayBFbmQAAwUBAgAAABG7PwADUgIAAKQBAQAAAABAnwECAt4BAACkAgQAAAwggMYDAACMBAMAnwIDAEw/AAKkAQEAAAAAQJ8BAALeAQEAggABAAUDAQQAAABAAwIDAwQADCCAAAcAARgAAAAAAAABAAAAAAAAAAAAAQkAAAAACwEAAQAGAwAABQEFL6MBAADGAQAAxgIAAKQDAgAABACApAQEAAAAMEBSBQAA2QYAABIBAf8SAQL/3QcAAJ8EAACfAwACEwQDAA4ECgBSBQQAgTUDBQUAAABSBwMAbwgFAKQGBwAAGACAnwYDAMEBAACCBQAApAUJAAAAgECkBgwAACyggG8HDQC7PwEDUgkBAKQIDwAAAOBAnwgCArs/AgNSCgIApAkPAAAA4ECfCQICnwYEAJ8FAAGpBQAAUgYBAMEBAACCBQMAEAMEAwUEAAQAgAMGBAAAMEACAAAAAAAAAEADBwQAGACAAwgEAACAQAMJAwoEACyggAMLAwEEAADgQAEAAwABGAABAQIAAAAAAAAABPwABgICAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAACAAAAAwAAAAABAAABAgADowAAAMAAAACCAAIAAQYBAQEBAAEYAAIAAQAAAAACNhM+rOqbZIdZHv9g8SjFSEYLKdgE11St

-- decompilation:
return function(p1: ((...any) -> ...any), ...) -- line: 3
	local str = nil
	local str2 = nil
	local v4 = table.pack(xpcall(p1, function(err) -- line: 7
		-- upvalues: str (ref), str2 (ref)
		str = tostring(err)
		str2 = tostring(debug.traceback(nil, 3.0))
	end, ...))
	local v5 = v4[1.0]

	if v5 then
		return v5, table.unpack(v4, 2.0)
	end

	warn(string.format("Error: %s\nStack Begin\n%s\nStack End", tostring(str), (tostring(str2))))

	return false, str
end

