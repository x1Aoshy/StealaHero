-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMBG1hdGgDc2luCFJvdGF0aW9uDVJlbmRlclN0ZXBwZWQEVGhlbgZXaWdnbGUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQlGdW5jdGlvbnMABAsCAgAAABX7AgAAbwUBAIwHAQBDBgcBCQQFBlsDBAD7BAEAuxgDA1IIAwCkBwQAAAwggJ8HAgIJBgIHjAgEAIwKBQAJCQoBsgcICewFBgcwBQQ4BQAAAIIAAQAGAgAAAAAAABhAAhgtRFT7IRlAAwEDAgQADCCAAwMABwABGAABAAAAAAEAAAAAAAAAAAAAAAAAAQgAAAAAAgACAAAABfsAAAD7AQEAMAEAOAAAAACCAAEAAQMDAAsAARgAAAAAAQwAAAAACAMBAAAAFJABAQBNAwA4AQAAAPsEAABNBATPAgAAANkFAAASAQH/EgAAAJAGAgOpBwEAnwQEAtkGAQASAAAAEgADALwEBHsEAAAAnwQDAMEBAACCBAAABQIAAAAAAAAuQAMDAwQCAAAAAAAA8D8DBQIAAQQGARgAAQABAAAAAAAEAPwEAAAAAAAAAAUAAAAAAwAAAQIAEaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICUwcAAACfAQICwAIIABIAAQCCAgIACQMHBAAAAEADCAMJAwoEAABAQAMLAwwGAgECAQABGAAAAAAAAAABAAAAAAAAAgAMAQAAAAAD5sbJ+YdyCOkdrnDyHbtGYJbe3o3UAqP4

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Functions = require(ReplicatedStorage.Library.Functions)

local function Wiggle(p1, p2, p3) -- line: 4
	-- upvalues: Functions (copy)
	local u7 = p2 or 15.0
	local p1Rotation = p1.Rotation

	return Functions.RenderStepped(function(_, p5) -- line: 7
		-- upvalues: u7 (ref), p1 (copy)
		p1.Rotation = u7 * math.sin(6.283185307179586 * (1.0 + p5) * 6.0) / 4.0 ^ (5.0 * p5)
	end, p3 or 1.0, true):Then(function() -- line: 11
		-- upvalues: p1 (copy), p1Rotation (copy)
		p1.Rotation = p1Rotation
	end)
end

return Wiggle

