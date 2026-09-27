-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRAm9zBGRhdGUDISVYA3N1YgRtYXRoBWZsb29yCHRvc3RyaW5nAToBLgZzdHJpbmcGZm9ybWF0BCUuMmYEJWQrJAVtYXRjaAMwMDoABGdzdWIAAgoDAAAAADOkAwIAAAQAgG8EAwBSBQAAnwMDAowEEA59AAYABAAAAIwGBAC8BAPwBAAAAJ8EAwJSAwQAbwQFAGAEDwAAAAAAPgUABbsMBQKkBAgAABxggJ8EAgK7PwQDUgkEAKQICgAAAJBAnwgCAlIFCABvBgsAUgcDAHMDBQcOAQwAUgQDAG8FDACkBg8AADjQgG8HEABSCAAAnwYDAm8IEQC8BgbnEgAAAJ8GAwJzAwQGDgIGAG8GEwBvBxQAvAQDzBUAAACfBAQCUgMEAIIDAgAWAwEDAgQABACAAwMDBAIAAAAAABj1QAMFAwYEABxggAMHBAAAkEADCAMJAwoDCwQAONCAAwwDDQMOAw8DEAMRAAEAARgAAAAAAAEAAAEAAAAAAgAAAQAAAAABAAAAAAAAAAACAQAAAAAAAAAAAAAAAgEAAAAAAAICAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAEUWpfPvMP25RuX4PJqc1b+ZEKAuyae/c4=

-- decompilation:
return function(p1, p2, p3) -- line: 1
	local v4 = os.date("!%X", p1)

	if p1 <= 3600.0 then
		v4 = v4:sub(4.0)
	end

	if p1 > 86400.0 then
		v4 = tostring((math.floor(p1 / 86400.0))) .. ":" .. v4
	end

	if p2 then
		v4 ..= "." .. string.format("%.2f", p1):match("%d+$")
	end

	if p3 then
		v4 = v4:gsub("00:", "")
	end

	return v4
end

