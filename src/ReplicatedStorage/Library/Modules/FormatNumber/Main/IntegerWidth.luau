-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBWNsYXNzCnRyeV9jb2VyY2UMSW50ZWdlcldpZHRoCHRvbnVtYmVyBG1hdGgEY2VpbBB0cnlfY29lcmNlX3JhbmdlA21pbgNtYXgKVHJ1bmNhdGVBdAp6ZXJvRmlsbFRvB3JlcXVpcmUGc2NyaXB0BlBhcmVudAlfaW50ZXJuYWwUY3JlYXRlX2luaXRfZnVuY3Rpb24QSW1tdXRhYmlsaXR5VHlwZQdERUZBVUxUBXRhYmxlBmZyZWV6ZQADCAICAAAHBAAABQIEAi77AgAATQICBQAAAABNAgJDAQAAAIwDAQBSBAAAbwUCAJ8CBAK7PgEDUgQBAKQDBAAAADBAnwMCAg4DCQC7BwEDUgQBAKQDBwAAGFCAnwMCAg0DAwAIAACAjAH//2UADAD7AwAATQMDBQAAAABNAwOuCQAAAIwEAQBSBQEATQYCuAoAAACMB+cDnwMFAlIBAwD7AwEA4gQMAE0FArgKAAAAMAUEuAoAAAAwAQSUCwAAAJ8DAgCCAwAADQMBAwIDAwMEBAAAMEADBQMGBAAYUIACAAAAAAAA8L8DBwMIAwkFAgoLAA0KARgAAAAAAAAAAAACAAAAAAAAAAAAAAAAAgACAAAAAAAAAAAAAAADAAEAAAABAP4ADgAAAAAGAQIAAAYDAAAFAQIR+wEAAE0BAQUAAAAATQEBrgEAAACMAgEAUgMAAIwEAACMBecDnwEFAlIAAQD7AQEA4gIFADAAArgCAAAAnwECAIIBAAAGAwEDBwMIAwkCAAAAAAAA8L8IAgL/////AwQAAAAAHQsBGAAAAAAAAAAAAAAAAgABAP8AHgAAAAAJAAABAgAuowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEBFAUAAACfAAIC/wEBAAAAAAD/AgEAAAAAAE0DAAUGAAAATQMDHQcAAABvBAgAxgUAAFIGAgDGBwAATQgABQYAAABNCAjPCQAAAE0ICAUKAAAAnwMGAsAECwASAAAAEgADADAEAtkMAAAAwAQNABIAAAASAAMAMAQBPg4AAACkBBEAAEDwgFIFAQCfBAIAggQAABIDDAQAAABAAw0EAAAgQAMOAw8DAQMQAwMDEQMSBgADCgYBAwsDEwMUBABA8IACAAEBAAEYAAAAAAAAAAAAAAAAAgABAAEAAAABAQEBAQAAAAAA+wgAAAAAEAAAAAAMAAAAAAEAAAAAAtrW+aKNERHebTIgRBvt9yGqzu7W6BKTow==

-- decompilation:
local _internal = require(script.Parent.Parent._internal)
local t1 = {}
local t2 = {}
local v4 = _internal.class.create_init_function("IntegerWidth", nil, t2, nil, _internal.class.ImmutabilityType.DEFAULT)

function t2.TruncateAt(t3: {[any]: any}, n1: number) -- line: 13
	-- upvalues: _internal (copy), v4 (copy)
	local v7 = _internal.class.try_coerce(1.0, t3, "IntegerWidth")
	local v8 = if not tonumber(n1) or math.ceil(n1) ~= -1.0 then _internal.class.try_coerce_range(1.0, n1, v7.min, 999.0) else -1.0

	return v4({
		min = v7.min,
		max = v8
	})
end
function t1.zeroFillTo(n2: number) -- line: 29
	-- upvalues: _internal (copy), v4 (copy)
	local v10 = _internal.class.try_coerce_range(1.0, n2, 0.0, 999.0)

	return v4({
		max = -1.0,
		min = v10
	})
end

return table.freeze(t1)

