-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZBVZhbHVlA0dldAlBc3NlcnRpb24HQ2hhbmdlZARGaXJlA1NldAR0eXBlCGZ1bmN0aW9uBmFzc2VydANuZXcIUmVhZG9ubHkMc2V0bWV0YXRhYmxlClVuYXNzZXJ0ZWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUNVXNlckdlbmVyYXRlZAtDb2xsZWN0aW9ucwpEZWVwRXF1YWxzC0NvbmN1cnJlbmN5CEJpbmRhYmxlBXRhYmxlBmZyZWV6ZQdfX2luZGV4AAUCAQAAAAADTQEA7AAAAACCAQIAAQMBAC0CARgAAAAuAAAAAAcCAQAACAABAQ8PAggRGU0CACQAAAAADgIFAE0CACQAAAAAUgMBAJ8CAgJSAQIATQIA7AEAAAAwAQDsAQAAAPsDAABSBAEAUgUCAJ8DAwIrAwcATQMAhQIAAABSBQEAUgYCALwDA90DAAAAnwMEAYICAgAEAwMDAQMEAwUAPAYBGAAAAAEAAAAAAgABAAEAAAAAAQAAAAAAAAI9AAAAAAYCAgAADQQCAQUCBQ8PDw8CERUmuygAA1IFAACkBAEAAAAAQJ8EAgLwBAIAAgAAAKkDAAGpAwEAuwEDAqQCBAAAADBAnwICAVICAABSAwEAnwICAlIBAgDiAggA+wMAAE0DA+8JAAAAnwMBAjADAoUFAAAAMAACJAYAAAAwAQLsBwAAADACAmYKAAAA+wUBAJ49AgQFAAAAUgQCAKQDDAAAALBAnwMDAoIDAgANAwcEAAAAQAMIAwkEAAAwQAMEAwMDAQUDBQYHAwoDCwMMBAAAsEAATwoBGAAAAAAAAAAAAAAAAAABAAAAAQEAAAAAAAEAAQACAAEAAAAAAAAAUAAAAAAFAQIAAAkAAgEPDw8BABMT4gECAPsCAABNAgLvAwAAAJ8CAQIwAgGFAAAAADAAAewBAAAAMAEBZgQAAAD7BAEAnj0BBAQAAABSAwEApAIGAAAAUECfAgMCggICAAcDBAMBBQIAAQMKAwsDDAQAAFBAAFwNARgAAQAAAAAAAQACAAEAAAAAAAAAXQAAAAALAAABAycAAAkPAAE4DwEHMg8CECkPAxkgDwQaHw8FHB0PBiQVDwcqDw8ILQw5owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIA4AYAAABNAgKhBwAAAE0CArMIAAAAnwECAqQCBQAAAEBATQMA4AYAAABNAwNmCQAAAE0DA6IKAAAAnwICAsADCwDABAwAEgABAKQFDwAAONCA4gYSADADBn8QAAAAMAQGcxEAAACfBQICpAYPAAA40IDiBxQAMAUHbhMAAACfBgICwAcVABIAAgASAAYAwAgWABIAAgASAAYApAkPAAA40IDiChkAMAcK7xcAAAAwCAo1GAAAAJ8JAgCCCQAAGgMOBAAAAEADDwMQAxEEAABAQAMSAxMDFAMVAxYGAAYBAxcDGAQAONCAAwIDBgUCEBEDGQUBEwYCBgMDCgMNBQIXGAQAAQIDAQABGAATAAAAAAACAAAAAAAAAAABAAAAAAAAAAAWDwAMAAABAAEA/gQAAAAAAAMAAA0AAAkAAAEAAQD+AAEAAAAABEnI7i1SkP9AXJHleKIJ5yg50PlZewyELA==

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepEquals = require(ReplicatedStorage.UserGenerated.Collections.DeepEquals)
local Bindable = require(ReplicatedStorage.UserGenerated.Concurrency.Bindable)
local v4 = table.freeze({
	Get = function(p1) -- line: 45
		return p1.Value
	end,
	Set = function(p2, p3) -- line: 60
		-- upvalues: DeepEquals (copy)
		if p2.Assertion then
			p3 = p2.Assertion(p3)
		end

		local p2Value = p2.Value

		p2.Value = p3

		if not DeepEquals(p3, p2Value) then
			p2.Changed:Fire(p3, p2Value)
		end

		return p2Value
	end
})
local v5 = table.freeze({
	__index = v4
})

return table.freeze({
	new = function(p4: ((...any) -> ...any), p5) -- line: 79
		-- upvalues: Bindable (copy), v5 (copy)
		assert(type(p4) == "function")

		local v12 = p4(p5)
		local t1 = {
			Changed = Bindable.new(),
			Assertion = p4,
			Value = v12
		}

		t1.Readonly = t1

		return (setmetatable(t1, v5))
	end,
	Unasserted = function(p6) -- line: 92
		-- upvalues: Bindable (copy), v5 (copy)
		local t2 = {
			Changed = Bindable.new(),
			Value = p6
		}

		t2.Readonly = t2

		return (setmetatable(t2, v5))
	end
})

