-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXOEludmFsaWQgb3IgbWlzc2luZyBudW1iZXIgYXQgcG9zaXRpb24gJWQgaW4gVmVjdG9yIHR5cGUuBmZvcm1hdA52YWxpZGF0ZVZlY3Rvcgd2ZWN0b3IzDFJlZ2lzdGVyVHlwZQh2ZWN0b3IzcxBNYWtlTGlzdGFibGVUeXBlB3ZlY3RvcjIIdmVjdG9yMnMHcmVxdWlyZQZzY3JpcHQGUGFyZW50BlNoYXJlZARVdGlsEE1ha2VTZXF1ZW5jZVR5cGUMVmFsaWRhdGVFYWNoDVRyYW5zZm9ybUVhY2gLQ29uc3RydWN0b3IGTGVuZ3RoCHRvbnVtYmVyB1ZlY3RvcjMDbmV3B1ZlY3RvcjIAAwYCAAAABwAAAQMDBQILRwAIAAAAAICpAgAAbwMAAFIFAQC8AwONAQAAAJ8DAwCCAgAAqQIBAIICAgACAwEDAgADAwEYAAABAAAAAAAAAwAEAAAAAAYBAwAAAB1vAwAA+wQAALwBAN0BAAAAnwEEAW8DAgD7BAEATQQEJAMAAAD7BQAAnwQCALwBAN0BAAAAnwEAAW8DBAD7BAIAvAEA3QEAAACfAQQBbwMFAPsEAQBNBAQkAwAAAPsFAgCfBAIAvAEA3QEAAACfAQABggABAAYDBAMFAwYDBwMIAwkAGQABGAAAAAAAAQAAAAAAAAAAAgAAAAABAAAAAAAAAAABGgAAAAAGAAABAgAwowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEBEgUAAABNAQGeBgAAAJ8AAgLAAQcATQIAIwgAAADiAw4AMAEDkQkAAACkBBAAAADwQDAEA00KAAAApAQTAABIEIEwBAO3CwAAAJ8CAgJNAwAjCAAAAOIEFQAwAQSRCQAAAKQFEAAAAPBAMAUETQoAAACkBRcAAEhggTAFBLcLAAAAnwMCAsAEGAASAAIAEgAAABIAAwCCBAIAGQMKBAAAAEADCwQAACBAAwwDDQMOBgADDwMQAxEDEgMTAgAAAAAAAAhACAQJ/////wr/////C/////8MDQAAAAMUBAAA8EADFQMWBABIEIECAAAAAAAAAEAIBAn/////Cv////8L/////wwUAAAAAxcEAEhggQYBAgABAQABGAAAAAAAAAAAAAAAAAAAAggAAAEAAQAAAAEAAAD9BwAAAQABAAAAAQAAAP0HAAAAAAEAAAAAAl4zhK/ydEcHuUHWnabwrfEuK5PbbPfurg==

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)

local function validateVector(p1, p2) -- line: 3
	if p1 == nil then
		return false, ("Invalid or missing number at position %d in Vector type."):format(p2)
	end

	return true
end

local v3 = Util.MakeSequenceType({
	Length = 3.0,
	ValidateEach = validateVector,
	TransformEach = tonumber,
	Constructor = Vector3.new
})
local v4 = Util.MakeSequenceType({
	Length = 2.0,
	ValidateEach = validateVector,
	TransformEach = tonumber,
	Constructor = Vector2.new
})

return function(p3) -- line: 25
	-- upvalues: v3 (copy), Util (copy), v4 (copy)
	p3:RegisterType("vector3", v3)
	p3:RegisterType("vector3s", Util.MakeListableType(v3))
	p3:RegisterType("vector2", v4)
	p3:RegisterType("vector2s", Util.MakeListableType(v4))
end

