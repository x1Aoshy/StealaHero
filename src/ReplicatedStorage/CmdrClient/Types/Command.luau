-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQD01ha2VGdXp6eUZpbmRlcg9HZXRDb21tYW5kTmFtZXMJVHJhbnNmb3JtKU5vIGNvbW1hbmQgd2l0aCB0aGF0IG5hbWUgY291bGQgYmUgZm91bmQuCFZhbGlkYXRlDEF1dG9jb21wbGV0ZQVQYXJzZQdjb21tYW5kDFJlZ2lzdGVyVHlwZQhjb21tYW5kcxBNYWtlTGlzdGFibGVUeXBlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAZTaGFyZWQEVXRpbAAGBAECAAAADPsBAABNAQE9AAAAAPsCAQC8AgLaAQAAAJ8CAgCfAQACUgIBAFIDAACfAgIAggIAAAIDAQMCAAUDARgAAAAAAAAAAAIAAAAGAAAAAAQBAAAAAAgcAgAAjAMAALcDAgACAAAAqQEAAakBAQBvAgAAggEDAAEDBAALBQEYAAAAAAAAAAAMAAAAAAEBAAAAAAGCAAIAAAAPBgEYABAAAAAAAgEAAAAAAhMBAACCAQIAAAATBwEYAAAUAAAAAAcBAQAAAB7iAQQA2QIAABICAAASAAAAMAIBIQAAAADAAgUAMAIBdgEAAADAAgYAMAIBqwIAAADAAgcAMAIBmwMAAABvBAgAUgUBALwCAN0JAAAAnwIEAW8ECgD7BQAATQUFJAsAAABSBgEAnwUCALwCAN0JAAAAnwIAAYIAAQAMAwMDBQMGAwcFBAABAgMGAQYCBgMDCAMJAwoDCwQAAQIDAwABGAABAAAAAAYAAAQAAAQAAAUAAAAAAQAAAAAAAAAAAQQAAAAAAgAAAQIAEaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BARIFAAAATQEBngYAAACfAAICwAEHABIAAACCAQIACAMMBAAAAEADDQQAACBAAw4DDwMQBgQBBAEAARgAAAAAAAAAAAAAAAAAAAIAAAEAAAAABaf72OPAo7ZJVZRQrQfkq8fX48+XlT+y4g==

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)

return function(p1) -- line: 3
	-- upvalues: Util (copy)
	local t1 = {
		Transform = function(p2) -- line: 5
			-- upvalues: Util (copy), p1 (copy)
			return Util.MakeFuzzyFinder(p1:GetCommandNames())(p2)
		end,
		Validate = function(p3) -- line: 11
			return #p3 > 0.0, "No command with that name could be found."
		end,
		Autocomplete = function(p4) -- line: 15
			return p4
		end,
		Parse = function(p5) -- line: 19
			return p5[1.0]
		end
	}

	p1:RegisterType("command", t1)
	p1:RegisterType("commands", Util.MakeListableType(t1))
end

