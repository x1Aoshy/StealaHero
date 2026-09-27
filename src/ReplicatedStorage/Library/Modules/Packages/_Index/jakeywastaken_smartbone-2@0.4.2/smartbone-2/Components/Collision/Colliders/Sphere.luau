-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKCU1hZ25pdHVkZQRVbml0CFNhZmVVbml0EENsb3Nlc3RQb2ludEZ1bmMIUG9zaXRpb24BWAFZAVoEbWF0aANtaW4ABAIBAAAAAAlNAQCqAAAAAA0BAwABAACAbwECAIIBAgBNAQAHAwAAAIIBAgAEAwECAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAMCAAIDARgAAAAAAQADAAADAAAAAAkDAAAAEwAABA8FAwkPAwAVDwQDEgEFDAkVJgMAAk0DA6oAAAAAJgUCAE0GBaoAAAAADQYDAAEAAIBvBAIAZQACAE0EBQcDAAAA1AMCAAEAAACpBQABqQUBAFIGBQAJCAQBQwcACFIIBACCBgQABAMBAgAAAAAAAAAABwAAAAAAAAAAAAAAAAAAAAADAgAKBAEYCAAAAfcAAAABAAMABgAAAAIAAAAAAwAAAAANBAAAAC8AAAsPCxIJDwcNFg8IDhUPAg8UDwkPFA8KEhEBCxsIDwQNIA8FDSAPBg0gDwclCC1NAAA7AAAAAE0FAXkCAAAATQYBeAMAAABNBwF7BAAAAEwTAAKkBAcAABhQgJ8EBAJbAQQBUgcAAFIIAQAmCQcCTQkJqggAAAAmCwIHTQwLqggAAAANDAMACQAAgG8KCgBlAAIATQoLBwsAAADUCQIACAAAAKkLAAGpCwEAUgQLAAkMCghDBQcMUgYKAA4EAQCCBAQAJgcFAk0HB6oIAAAAtwcCAAMAAACpBAABqQQBAIIEBAAMAwUCAAAAAAAA4D8DBgMHAwgDCQMKBAAYUIADAQIAAAAAAAAAAAcAAAAAAAAAAAAAAAAAAAAAAwIAEgABGBIAAQAAAAAAAAAAAAACAPMAAAH3AAAAAQADAAYAAAACAAAACwEDAAACAAAAAwMAAAAAAwAAAQMLAAACDwABBA8BAgMFowAAAMAAAADAAQEAwAICAIICAgADBgAGAQYCAwABAgEAARgAAQgIAAEAAAAAA0c6CR9jWrzjQ3pXGiO4Lrg3Ih5rdf5jHg==

-- decompilation:
--!native
local function SafeUnit(p1) -- line: 2
	if p1.Magnitude == 0.0 then
		return (Vector3.new(0.0, 0.0, 0.0))
	end

	return p1.Unit
end
local function ClosestPointFunc(p2, p3, p4) -- line: 10
	local Magnitude = (p2 - p4).Magnitude
	local v8 = p4 - p2
	local v9 = if v8.Magnitude ~= 0.0 then v8.Unit else Vector3.new(0.0, 0.0, 0.0)

	return Magnitude <= p3, p2 + v9 * p3, v9
end

return function(p5, p6, p7, p8) -- line: 18
	local p5Position = p5.Position
	local v15 = math.min(p6.X, p6.Y, p6.Z) * 0.5
	local Magnitude = (p5Position - p7).Magnitude
	local v17 = p7 - p5Position
	local v18 = if v17.Magnitude ~= 0.0 then v17.Unit else Vector3.new(0.0, 0.0, 0.0)
	local v19 = Magnitude <= v15
	local v20 = p5Position + v18 * v15

	if v19 then
		return v19, v20, v18
	end

	return p8 > (v20 - p7).Magnitude, v20, v18
end

