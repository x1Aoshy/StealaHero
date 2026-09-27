-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQD01ha2VGdXp6eUZpbmRlcgxHZXRUeXBlTmFtZXMJVHJhbnNmb3JtJk5vIHR5cGUgd2l0aCB0aGF0IG5hbWUgY291bGQgYmUgZm91bmQuCFZhbGlkYXRlDEF1dG9jb21wbGV0ZQVQYXJzZQR0eXBlDFJlZ2lzdGVyVHlwZQV0eXBlcxBNYWtlTGlzdGFibGVUeXBlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAZTaGFyZWQEVXRpbAAGBAECAAAADPsBAABNAQE9AAAAAPsCAQC8AgKCAQAAAJ8CAgCfAQACUgIBAFIDAACfAgIAggIAAAIDAQMCAAUDARgAAAAAAAAAAAIAAAAGAAAAAAQBAAAAAAgcAgAAjAMAALcDAgACAAAAqQEAAakBAQBvAgAAggEDAAEDBAALBQEYAAAAAAAAAAAMAAAAAAEBAAAAAAGCAAIAAAAPBgEYABAAAAAAAgEAAAAAAhMBAACCAQIAAAATBwEYAAAUAAAAAAcBAQAAAB7iAQQA2QIAABICAAASAAAAMAIBIQAAAADAAgUAMAIBdgEAAADAAgYAMAIBqwIAAADAAgcAMAIBmwMAAABvBAgAUgUBALwCAN0JAAAAnwIEAW8ECgD7BQAATQUFJAsAAABSBgEAnwUCALwCAN0JAAAAnwIAAYIAAQAMAwMDBQMGAwcFBAABAgMGAQYCBgMDCAMJAwoDCwQAAQIDAwABGAABAAAAAAYAAAQAAAQAAAUAAAAAAQAAAAAAAAAAAQQAAAAAAgAAAQIAEaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BARIFAAAATQEBngYAAACfAAICwAEHABIAAACCAQIACAMMBAAAAEADDQQAACBAAw4DDwMQBgQBBAEAARgAAAAAAAAAAAAAAAAAAAIAAAEAAAAABSiDLjG8cMM1gUspKTDedhtYmzlFGkdEMA==

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)

return function(p1) -- line: 3
	-- upvalues: Util (copy)
	local t1 = {
		Transform = function(p2) -- line: 5
			-- upvalues: Util (copy), p1 (copy)
			return Util.MakeFuzzyFinder(p1:GetTypeNames())(p2)
		end,
		Validate = function(p3) -- line: 11
			return #p3 > 0.0, "No type with that name could be found."
		end,
		Autocomplete = function(p4) -- line: 15
			return p4
		end,
		Parse = function(p5) -- line: 19
			return p5[1.0]
		end
	}

	p1:RegisterType("type", t1)
	p1:RegisterType("types", Util.MakeListableType(t1))
end

