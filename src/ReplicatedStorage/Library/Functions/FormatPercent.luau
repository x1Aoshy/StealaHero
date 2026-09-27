-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFASUHcmVxdWlyZQZzY3JpcHQGUGFyZW50DUZvcm1hdEZpZ3VyZXMAAggBAQAAAAn7BAAAWwUAAIwGBACMBwUAnwQEAlICBABvAwEAcwECA4IBAgACAgAAAAAAAFlAAwEAAwABGAAAAAAAAAAAAAQAAAAAAgAAAQIADaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEWBQAAAJ8AAgLAAQYAEgAAAIIBAgAHAwIEAAAAQAMDBAAAIEADBAMFBgABAAEAARgAAAAAAAAAAAAAAgAAAQAAAAAB

-- decompilation:
local FormatFigures = require(script.Parent.FormatFigures)

return function(p1) -- line: 3
	-- upvalues: FormatFigures (copy)
	return FormatFigures(p1 * 100.0, 4.0, 5.0) .. "%"
end

