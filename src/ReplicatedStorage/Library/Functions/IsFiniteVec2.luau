-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGAVgBWQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQISXNGaW5pdGUAAgQBAQAAAAv7AQAATQIAeQAAAACfAQICDgEFAPsCAABNAwB4AQAAAJ8CAgJSAQIAggECAAIDAQMCAAMAARgAAAAAAQEAAAAAAgQAAAAAAgAAAQIADaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQFuBQAAAJ8AAgLAAQYAEgAAAIIBAgAHAwMEAAAAQAMEBAAAIEADBQMGBgABAAEAARgAAAAAAAAAAAAAAgAAAQAAAAAB

-- decompilation:
local IsFinite = require(script.Parent.IsFinite)

return function(p1) -- line: 3
	-- upvalues: IsFinite (copy)
	return IsFinite(p1.X) and IsFinite(p1.Y)
end

