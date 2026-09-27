-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRKkJhc2UgdXBncmFkZSB0cmFuc2l0aW9uIGlzIGFscmVhZHkgcGxheWluZwZhc3NlcnQFQmVnaW45QmFzZSB1cGdyYWRlIHRyYW5zaXRpb24gbXVzdCBiZSBwbGF5aW5nIGJlZm9yZSBjb21wbGV0aW9uCUNvbXBsZXRlZARGaXJlCENvbXBsZXRlCUlzUGxheWluZwRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B01vZHVsZXMIUGFja2FnZXMGU2lnbmFsA25ldwAEAwABAAAAC/sCAABWAQIAgQEBBAAAAABvAgAApAACAAAAEECfAAMBqQABAN4AAACCAAEAAwMBAwIEAAAQQAAUAwEYAAAAAAAAAAABAAEVAAAAAAMAAgAAABD7AQAAgQEBBAAAAABvAgAApAACAAAAEECfAAMBqQAAAN4AAAD7AAEATQAAGAMAAAC8AADdBAAAAJ8AAgGCAAEABQMEAwIEAAAQQAMFAwYAGQcBGAAAAAAAAAABAAEAAAAAAAEaAAAAAAEAAQAAAAL7AAAAggACAAAAHwgBGAAAIAAAAAAFAAABAgApowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQICHwkAAACfAQICqQIAAP8DAwAAAAAATQQB7woAAACfBAECMAQDGAsAAADZBAAAEgEC/zAEA7gMAAAA2QQBABIBAv8SAAMAMAQDZw0AAADZBAIAEgEC/zAEA5wOAAAAwQIAAIIDAgAPAwkEAAAAQAMKAwsDDAQAAEBAAw0DDgMPAxADEQMFAwMDBwMIAwABAgEAARgAAwAAAAAAAwAAAAAAAAAAAAADAwABAAAAAAYAAAAFAAAAAAYAAAAEAAEAAAAAAx1cbvOTWtKxNn16QT5m02ltRHmHL5gE8g==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Library.Modules.Packages.Signal)
local u3 = false
local t1 = {
	Completed = Signal.new(),
	Begin = function() -- line: 20
		-- upvalues: u3 (ref)
		assert(not u3, "Base upgrade transition is already playing")
		u3 = true
	end
}

function t1.Complete() -- line: 25
	-- upvalues: u3 (ref), t1 (copy)
	assert(u3, "Base upgrade transition must be playing before completion")
	u3 = false
	t1.Completed:Fire()
end
function t1.IsPlaying() -- line: 31
	-- upvalues: u3 (ref)
	return u3
end

return t1

