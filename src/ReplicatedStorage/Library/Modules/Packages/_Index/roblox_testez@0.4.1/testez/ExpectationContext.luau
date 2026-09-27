-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSBXBhaXJzBGNvcHkLX2V4dGVuc2lvbnMMc2V0bWV0YXRhYmxlA25ldwZleHRlbmQVc3RhcnRFeHBlY3RhdGlvbkNoYWluBnN0cmluZwZmb3JtYXQjQ2Fubm90IHJlYXNzaWduICVxIGluIGV4cGVjdC5leHRlbmQGYXNzZXJ0LkNhbm5vdCBvdmVyd3JpdGUgbWF0Y2hlciAlcTsgaXQgYWxyZWFkeSBleGlzdHMHcmVxdWlyZQZzY3JpcHQGUGFyZW50C0V4cGVjdGF0aW9uGmNoZWNrTWF0Y2hlck5hbWVDb2xsaXNpb25zB19faW5kZXgABQcBAAAAAAv/AQAAAAAAAKQCAQAAAABAUgMAAJ8CAgQXAgEAagYBBW4C/v8CAAAAggECAAIDAQQAAABAAAQCARgAAAIAAAAAAf8ABAUAAAAACgEBAAAAHOIBAQAOAA4ATQMACgAAAAD/BAAAAAAAAKQFAwAAACBAUgYDAJ8FAgQXBQEAagkECG4F/v8CAAAAUgIEACsCAgD/AgAAAAAAADACAQoAAAAA+wQAAJ49AQQEAAAAUgMBAKQCBQAAAEBAnwIDAoICAgAGAwMFAQADAQQAACBAAwQEAABAQAARBQEYDQEAAPIAAgAAAAAB/wAEAAgAAAADAAAAAAAAAAUAAAAABAEBAQAADKMBAAD7AQAATQEB7wAAAADdAgAAnwEAAk0DAAoBAAAAvAEBnAIAAACfAQMAggEAAAMDBQMDAwYAGQcBGAABAAAAAAAAAAAAABkAAAAADAIBAAAAJ6QCAQAAAABAUgMBAJ8CAgQXAh8ATQoACgIAAACHCQoFRwkCAAAAAACpCAABqQgBAKQJBQAAEDCAbwoGAFILBQCfCQMATAEAAqQHCAAAAHBAnwcAAfsIAABSCQUAnwgCAqQJBQAAEDCAbwoJAFILBQCfCQMATAEAAqQHCAAAAHBAnwcAAU0HAAoCAAAAagYHBW4C4P8CAAAAggABAAoDAQQAAABAAwMDCAMJBAAQMIADCgMLBAAAcEADDAAdBgEYAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAgAA/AAGHgAAAAAFAAABAgAeowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BAf8FAAAAnwACAk0BAOEGAAAAwAIHAP8DAwAAAAAAMAMDbggAAADABAkAEgADADAEA+8KAAAAwAQLABIAAAAwBAOmDAAAAMAEDQASAAEAMAQDnA4AAACCAwIADwMNBAAAAEADDgQAACBAAw8DEAMRBgADEgYBAwUGAgMHBgMDBgQAAQIDAQABGAAAAAAAAAAAAAABAAIKAAEAAgAAAAgAAAAEAAAACQEAAAAABEn8l55W2YHLEXV4w8IQeug55IDqezj9nw==

-- decompilation:
local Expectation = require(script.Parent.Expectation)
local checkMatcherNameCollisions = Expectation.checkMatcherNameCollisions

local function copy(p1) -- line: 4
	local t1 = {}

	for k, v in pairs(p1) do
		t1[k] = v
	end

	return t1
end

local t2 = {}

t2.__index = t2

function t2.new(p2) -- line: 17
	-- upvalues: t2 (copy)
	local t3 = {}
	local g11 = nil
	local t4 = nil

	repeat
		if g11 or p2 then
			if not g11 then
				local _extensions = p2._extensions

				t4 = {}

				for k, v in pairs(_extensions) do
					t4[k] = v
				end
			end

			if g11 or t4 then
				g11 = false
				t3._extensions = t4

				return (setmetatable(t3, t2))
			end
		end

		t4 = {}
		g11 = true
	until not g11
end
function t2.startExpectationChain(p3, ...) -- line: 25
	-- upvalues: Expectation (copy)
	return Expectation.new(...):extend(p3._extensions)
end
function t2.extend(p4, p5) -- line: 29
	-- upvalues: checkMatcherNameCollisions (copy)
	for k, v in pairs(p5) do
		assert(p4._extensions[k] == nil, string.format("Cannot reassign %q in expect.extend", k))
		assert(checkMatcherNameCollisions(k), string.format("Cannot overwrite matcher %q; it already exists", k))
		p4._extensions[k] = v
	end
end

return t2

