-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbgRJbml0B0VuYWJsZWQIUG9zaXRpb24KTG9va1ZlY3RvcgNSYXkERHJhdwlUcmFuc2Zvcm0GTGVuZ3RoC0Fsd2F5c09uVG9wDFRyYW5zcGFyZW5jeQZDb2xvcjMHRGVzdHJveQZDcmVhdGUMUHVzaFByb3BlcnR5BlVwZGF0ZQdfX2luZGV4BkNGcmFtZQEXAAUIBQEAAAAT/wYEAAAAAAD7BwAAnj0GAwcAAACkBQEAAAAAQJ8FAwIwAAU3AgAAADABBeoDAAAAMAIFTAQAAAAwAwVcBQAAADAEBY8GAAAAggUCAAcDAQQAAABAAwIDAwMEAwUDBgAEBwEYAAAAAAAAAAACAAEAAQABAAEAAgUAAAAACgMAAAAIBQAABQMEQAIdTQMANwAAAABNBAPwAQAAACsEAQCCAAEATQUBOwIAAABNBwFoAwAAADkJAgBbCAkECQYHCEMEBQZNBgE7AgAAAE0IAWgDAAAAWwkCBAkHCAlDBQYHTQYDuAUAAABSCAQAUgkFALwGBtQGAAAAnwYEAYIAAQAHAwIDCAMJAwoCAAAAAAAA4D8DCwMMABAMARgAAAIAAAEDAAAAAAAAAAEAAAAAAAACAAAAAAAAAREAAAAABwMAAAAIBQAABQMEQAId4gMJADABAyEAAAAAMAIDrQEAAABNBADqCgAAAE0EBI4CAAAAMAQDjgIAAABNBADqCgAAAE0EBNkDAAAAMAQD2QMAAABNBADqCgAAAE0EBJoEAAAAMAQDmgQAAABNBACPCwAAAFIFAABSBgMAnwQDAYIDAgAMAw0DDgMPAxADEQMIAQEDEgEACAcA/////wH/////Av////8D/////wT/////BQYAAAAHCAAAAAMDAwYAHRMBGAABAAEAAQAAAAAAAQAAAAAAAQAAAAAABQAAAAACHgAAAAAHAgAAAAAcTQIANwAAAABNAwIzAQAAAG8EAgBNBQGOAgAAAJ8DAwFNAwIzAQAAAG8EAwBNBQHZAwAAAJ8DAwFNAwIzAQAAAG8EBABNBQGaBAAAAJ8DAwFNBQEhBQAAAE0GAa0GAAAAvAMA1AcAAACfAwQBggABAAgDAgMUAw8DEAMRAw0DDgMMAC0VARgAAAIAAAAAAAEAAAAAAAEAAAAAAAIAAAAAAAABLgAAAAACAAABAgATowAAAP8ABAAAAAAAMAAAbgAAAADAAQEAEgAAADABAHMCAAAAwAEDADABANQEAAAAwAEFADABAJYGAAAAwAEHADABACYIAAAAggACAAkDFgYAAwcGAQMMBgIDEwYDAxUEAAECAwEAARgAAAABAAIAAAAMAAANAAAQAAAKAQAAAAAEFhgFM8dKXGYoTlOEYkIw02YAEkck3G8y

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.Init(p1, p2, p3, p4, p5) -- line: 4
	-- upvalues: t1 (copy)
	local self = setmetatable({}, t1)

	self.Ceive = p1
	self.Propertys = p2
	self.Request = p3
	self.Release = p4
	self.Retain = p5

	return self
end
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number) -- line: 16
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v12 = cFrame.Position + cFrame.LookVector * (-n1 * 0.5)
	local v13 = cFrame.Position + cFrame.LookVector * (n1 * 0.5)

	Ceive.Ray:Draw(v12, v13)
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n2: number) -- line: 29
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
		Length = n2,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p6, p7) -- line: 45
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Transform, p7.Length)
end

return t1

