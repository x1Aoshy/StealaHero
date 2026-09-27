-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTDlBvc2VDb250cm9sbGVyB0Rlc3Ryb3kLQ29ubmVjdGlvbnMMc2V0bWV0YXRhYmxlBXRhYmxlBWNsZWFyCEFuaW1hdG9yFkZpbmRGaXJzdENoaWxkV2hpY2hJc0EFZXJyb3IdQW5pbWF0b3Igbm90IGZvdW5kIGZvciByaWcgJSoGZm9ybWF0A25ldwlfYW5pbWF0b3IEX3JpZwdyZXF1aXJlBnNjcmlwdAZQYXJlbnQFVHlwZXMHX19pbmRleAADBAEAAAAAF00BAM4AAAAAvAEBUAEAAACfAQIBTQEA8QIAAAC8AQFQAQAAAJ8BAgGBPQAFAwAAAFICAABvAwMApAEFAAAAQECfAQMBpAEIAAAcYIBSAgAAnwECAcYAAACCAAEACQMBAwIDAwADBAQAAEBAAwUDBgQAHGCAAAkCARgAAAAAAAEAAAAAAgAAAAAAAAEAAAABAQoAAAAACQMDAAAIBQAABQMHDw8rbwUAAKkGAQC8AwBUAQAAAJ8DBAIrAwgApAQDAAAAIEBvBQQAUgcAALwFBY0FAAAAnwUDAp8EAgH7BAAATQQE7wYAAABSBQAAUgYBAJ8EAwL7BQEATQUF7wYAAABSBgQAUgcAAFIIAgCfBQQC4gcLADADB+cHAAAAMAAHNggAAAAwBAfOCQAAADAFB/EKAAAA+wgCAJ49BwMIAAAApAYNAAAAwECfBgMCggYCAA4DBwMIAwkEAAAgQAMKAwsDDAMNAw4DAQMDBQQHCAkKAwQEAADAQAAXDAEYAAAAAAABAQAAAAAAAAADAAAAAAABAAAAAAAAAgEAAQACAAEAAQAA+gAAABgAAAAABwAAAQIAKKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQHvBQAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICzgYAAACfAQICpAIBAAAAAECkAwMAAAAgQE0DA/EHAAAAnwICAv8DAQAAAAAA4gQJADADBG4IAAAAwAUKADAFA1ALAAAAwAUMABIAAQASAAIAEgAEAOIGDgAwBQbvDQAAAIIGAgAPAw8EAAAAQAMQBAAAIEADEQMSAwEDAwMTBQEIBgADAgYBAwwFAQ0CAAEBAAEYAAAAAAAAAAAAAAIAAAAAAAABAAAAAAAAAgABAAACAAAOAAAAEgEAAAEAAAAAAl1xGqtOEquuuzSZA29OgY4taQ3fb7Vwqg==

-- decompilation:
require(script.Parent.Types)

local PoseController = require(script.PoseController)
local Connections = require(script.Connections)
local t1 = {}
local t2 = {
	__index = t1
}

function t1.Destroy(p1) -- line: 9
	p1.PoseController:Destroy()
	p1.Connections:Destroy()
	setmetatable(p1, nil)
	table.clear(p1)
end

return {
	new = function(p2, p3, p4) -- line: 23
		-- upvalues: PoseController (copy), Connections (copy), t2 (copy)
		local Animator = p2:FindFirstChildWhichIsA("Animator", true)

		if not Animator then
			error(`Animator not found for rig { p2 }`)
		end

		local v10 = PoseController.new(p2, p3)
		local v11 = Connections.new(v10, p2, p4)

		return (setmetatable({
			_animator = Animator,
			_rig = p2,
			PoseController = v10,
			Connections = v11
		}, t2))
	end
}

