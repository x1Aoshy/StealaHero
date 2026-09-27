-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMODV5odHRwcz86Ly8uKyQFbWF0Y2goVVJMcyBtdXN0IGJlZ2luIHdpdGggaHR0cDovLyBvciBodHRwczovLwhWYWxpZGF0ZQVQYXJzZQN1cmwMUmVnaXN0ZXJUeXBlBHVybHMQTWFrZUxpc3RhYmxlVHlwZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQGU2hhcmVkBFV0aWwABAQBAAAAAApvAwAAvAEA5wEAAACfAQMCDgECAKkBAQCCAQIAqQEAAG8CAgCCAQMAAwMBAwIDAwAEBAEYAAAAAAABAAMAAAUAAAAAAQEAAAAAAYIAAgAAAAwFARgADQAAAAAGAQIAAAAPbwMAAPsEAAC8AQDdAQAAAJ8BBAFvAwIA+wQBAE0EBCQDAAAA+wUAAJ8EAgC8AQDdAQAAAJ8BAAGCAAEABAMGAwcDCAMJABEAARgAAAAAAAEAAAAAAAAAAAESAAAAAAMAAAECABmjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQESBQAAAE0BAZ4GAAAAnwACAuIBCQDAAgoAMAIBdgcAAADAAgsAMAIBmwgAAADAAgwAEgABABIAAACCAgIADQMKBAAAAEADCwQAACBAAwwDDQMOAwQDBQUCBwgGAAYBBgIDAAECAQABGAAAAAAAAAAAAAAAAAAAAgEAAAgAAAUAAAABAAAAAAMa3oYHb41Zk/lo8mvYFuD8asaRcyga7AY=

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)
local t1 = {
	Validate = function(p1) -- line: 4
		if p1:match("^https?://.+$") then
			return true
		end

		return false, "URLs must begin with http:// or https://"
	end,
	Parse = function(p2) -- line: 12
		return p2
	end
}

return function(p3) -- line: 17
	-- upvalues: t1 (copy), Util (copy)
	p3:RegisterType("url", t1)
	p3:RegisterType("urls", Util.MakeListableType(t1))
end

