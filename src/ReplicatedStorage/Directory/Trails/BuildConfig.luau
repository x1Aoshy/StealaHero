-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKB19faW5kZXgMc2V0bWV0YXRhYmxlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCYXNlQ29uZmlncwdEZWZhdWx0BlJhcml0eQVUeXBlcwlJbnRlcmZhY2UAAgUBAQAABgMAAAUBBAviAwEA+wQAADAEA24AAAAAnj0ABAMAAABSAgAApAEDAAAAIECfAQMCggECAAQDAQUBAAMCBAAAIEAAFAABGAABAAAAAAD/AAAAFQAAAAAEAAABAgAlowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BAToFAAAATQEBOgYAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgLyBwAAAJ8BAgKkAgEAAAAAQKQDAwAAACBATQMDJAQAAABNAwPvCAAAAE0DAw8JAAAAnwICAsADCgASAAAAggMCAAsDAwQAAABAAwQEAAAgQAMFAwYDBwMIAwkDCgYAAQABAAEYAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAA4AAAEAAAAAAeB/QVQzAhA/nLPKO569Z++QZ1Yg0rsrVQ==

-- decompilation:
local Default = require(script.Parent.BaseConfigs.Default)

require(script.Parent.Parent.Rarity)
require(script.Parent.Types.Interface)

return function(t1: {[any]: any}) -- line: 20
	-- upvalues: Default (copy)
	return (setmetatable(t1, {
		__index = Default
	}))
end

