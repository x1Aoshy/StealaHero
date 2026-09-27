-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBUNsZWFuClN0YXJ0RXZlbnQJU3RvcEV2ZW50BGdhbWUJV29ya3NwYWNlCkdldFNlcnZpY2UITGlnaHRpbmcRUmVwbGljYXRlZFN0b3JhZ2UTU2VydmVyU2NyaXB0U2VydmljZQ1TZXJ2ZXJTdG9yYWdlBkRlYnJpcwdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwVUcm92ZQNuZXcAAwQCAgAABwQAAAUCBAIH+wIAALwCAk8AAAAAnwICAakCAQDeAgEAggABAAEDAQAaAgEYAAAAAAEAAhsAAAAAAwECAAAAB/sBAAC8AQFPAAAAAJ8BAgGpAQAA3gEBAIIAAQABAwEAIAMBGAAAAAABAAEhAAAAAAsAAAECAEKjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIBAAAAAEBvBAUAvAICFgMAAACfAgMCpAMBAAAAAEBvBQYAvAMDFgMAAACfAwMCpAQBAAAAAEBvBgcAvAQEFgMAAACfBAMCpAUBAAAAAEBvBwgAvAUFFgMAAACfBQMCpAYKAAAAkEBNBwJqCwAAAE0HB+gMAAAATQcH5g0AAABNBwebDgAAAJ8GAgJNBwbvDwAAAJ8HAQKpCAAA/wkCAAAAAADZCgAAEgAHABIBCP8wCgnUEAAAANkKAQASAAcAEgEI/zAKCewRAAAAwQgAAIIJAgASAwQEAAAAQAMFAwYDBwMIAwkDCgMLAwwEAACQQAMNAw4DDwMQAxEDAgMDAgABAQABGAADAAAAAAABAAAAAAABAAAAAAABAAAAAAABAAAAAAABAAAAAAAEAAAAAAAAAAAAAAYAAAEEAAIAAAAABgAAAAAFAAEAAAAAAv4YC7+W9rfjAR8fMRWc9sKOABzLzNxhvg==

-- decompilation:
game:GetService("Workspace")
game:GetService("Lighting")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

game:GetService("ServerScriptService")
game:GetService("ServerStorage")
game:GetService("Debris")

local v2 = require(ReplicatedStorage.Library.Modules.Packages.Trove).new()
local u3 = false

return {
	StartEvent = function(_: {[any]: any}, _: number) -- line: 26
		-- upvalues: v2 (copy), u3 (ref)
		v2:Clean()
		u3 = true
	end,
	StopEvent = function(_) -- line: 32
		-- upvalues: v2 (copy), u3 (ref)
		v2:Clean()
		u3 = false
	end
}

