-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOCHRvc3RyaW5nBWRlYnVnCXRyYWNlYmFjawV0YWJsZQRwYWNrBnhwY2FsbAVlcnJvcholcwpTdGFjayBCZWdpbgolc1N0YWNrIEVuZAZmb3JtYXQGdW5wYWNrB3JlcXVpcmUGc2NyaXB0BlBhcmVudAV3Y2FsbAADBQECAAAAEbs/AANSAgAApAEBAAAAAECfAQIC3gEAAKQCBAAADCCAxgMAAIwEAwCfAgMATD8AAqQBAQAAAABAnwEAAt4BAQCCAAEABQMBBAAAAEADAgMDBAAMIIAABgABGAAAAAAAAAEAAAAAAAAAAAABBwAAAAAKAgEBAAcAAAEDBhgCKKMCAADGAgAAxgMAAKQEAgAABACApAUEAAAAMEBSBgAA2QcAABIBAv8SAQP/3QgAAJ8FAACfBAACEwUEACsFDAD7BQAAUgYBAJ8FAgGkBQYAAABQQG8GBwBSCAIAUgkDALwGBo0IAAAAnwYEAJ8FAAH7BQAAUgYBAJ8FAgGBNQQFCQAAAFIGBABvBwkApAULAAAoAICfBQMAwQIAAIIFAAAMAwQDBQQABACAAwYEAAAwQAMHBAAAUEADCAMJAgAAAAAAAABAAwoEACgAgAEAAwABGAABAQEAAAAAAAAAA/0ABAABAAABAAAAAAAAAAACAAABAAAAAAAAAAADAAAAAAIAAAECAA2jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBUQUAAACfAAICwAEGABIAAACCAQIABwMLBAAAAEADDAQAACBAAw0DDgYBAQEBAAEYAAAAAAAAAAAAAAIAAAEAAAAAAoyDXWdnxX98mgPX4C4pkr38m0oTvkc3Zg==

-- decompilation:
local wcall = require(script.Parent.wcall)

return function(p1, p2, ...) -- line: 3
	-- upvalues: wcall (copy)
	local str = nil
	local str2 = nil
	local v6 = table.pack(xpcall(p1, function(err) -- line: 6
		-- upvalues: str (ref), str2 (ref)
		str = tostring(err)
		str2 = tostring(debug.traceback(nil, 3.0))
	end, ...))

	if not v6[1.0] then
		wcall(p2)
		error(("%s\nStack Begin\n%sStack End"):format(str, str2))
	end

	wcall(p2)

	return table.unpack(v6, 2.0)
end

