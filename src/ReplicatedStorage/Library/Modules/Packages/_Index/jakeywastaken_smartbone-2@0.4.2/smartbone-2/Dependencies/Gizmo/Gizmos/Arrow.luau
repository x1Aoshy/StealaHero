-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbgRJbml0B0VuYWJsZWQDUmF5BERyYXcGQ0ZyYW1lBmxvb2tBdARVbml0BENvbmUGT3JpZ2luA0VuZAZSYWRpdXMGTGVuZ3RoDFN1YmRpdmlzaW9ucwtBbHdheXNPblRvcAxUcmFuc3BhcmVuY3kGQ29sb3IzB0Rlc3Ryb3kGQ3JlYXRlDFB1c2hQcm9wZXJ0eQZVcGRhdGUHX19pbmRleAAFCAUBAAAAE/8GBAAAAAAA+wcAAJ49BgMHAAAApAUBAAAAAECfBQMCMAAFNwIAAAAwAQXqAwAAADACBUwEAAAAMAMFXAUAAAAwBAWPBgAAAIIFAgAHAwEEAAAAQAMCAwMDBAMFAwYABAcBGAAAAAAAAAAAAgABAAEAAQABAAIFAAAAAA4GAAAADwgAAQUGBAgIAgICCAoQAiFNBgA3AAAAAE0HBvABAAAAKwcBAIIAAQBNBwa4AgAAAFIJAQBSCgIAvAcH1AMAAACfBwQBpAcGAAAUQIAmCgECTQoKBwcAAABbCwQICQkKC0MIAglSCQIAnwcDAk0IBjQJAAAAUgoHAFILAwBSDAQAUg0FALwICNQDAAAAnwgGAYIAAQAKAwIDCAMJAwoDCwMMBAAUQIADDQIAAAAAAADgPwMOABAKARgAAAIAAAEDAAAAAAAAAgAAAAAAAAAAAAEAAAAAAAAAAAERAAAAAAoGAAAACwgAAAUGBAgIAgICI+IGDAAwAQZDAAAAADACBgsBAAAAMAMGcQIAAAAwBAatAwAAADAFBpkEAAAATQcA6g0AAABNBweOBQAAADAHBo4FAAAATQcA6g0AAABNBwfZBgAAADAHBtkGAAAATQcA6g0AAABNBweaBwAAADAHBpoHAAAATQcAjw4AAABSCAAAUgkGAJ8HAwGCBgIADwMPAxADEQMSAxMDFAMVAxYDCAEBAxcBAAgKAP////8B/////wL/////A/////8E/////wX/////Bv////8H/////wgJAAAACgsAAAADAwMGAB0YARgAAQABAAEAAQABAAEAAAAAAAEAAAAAAAEAAAAAAAUAAAAAAh4AAAAACgIAAAAAIk0CADcAAAAATQMCMwEAAABvBAIATQUBjgIAAACfAwMBTQMCMwEAAABvBAMATQUB2QMAAACfAwMBTQMCMwEAAABvBAQATQUBmgQAAACfAwMBTQUBQwUAAABNBgELBgAAAE0HAXEHAAAATQgBrQgAAABNCQGZCQAAALwDANQKAAAAnwMHAYIAAQALAwIDGQMUAxUDFgMPAxADEQMSAxMDCgAwGgEYAAACAAAAAAABAAAAAAABAAAAAAADAAEAAQABAAEA+wAABzEAAAAAAgAAAQIAE6MAAAD/AAQAAAAAADAAAG4AAAAAwAEBABIAAAAwAQBzAgAAAMABAwAwAQDUBAAAAMABBQAwAQCWBgAAAMABBwAwAQAmCAAAAIIAAgAJAxsGAAMHBgEDCgYCAxgGAwMaBAABAgMBAAEYAAAAAQACAAAADAAADQAAEwAAEAEAAAAABARRoW9IVExpQenaLIJFKfJ0SbYbNpXLbg==

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
function t1.Draw(t2: {[any]: any}, vector3: Vector3, vector3_2: Vector3, n1: number, n2: number, n3: number) -- line: 16
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	Ceive.Ray:Draw(vector3, vector3_2)

	local cFrame = CFrame.lookAt(vector3_2 + (vector3 - vector3_2).Unit * (n2 * 0.5), vector3_2)

	Ceive.Cone:Draw(cFrame, n1, n2, n3)
end
function t1.Create(t3: {[any]: any}, vector3: Vector3, vector3_3: Vector3, n4: number, n5: number, n6: number) -- line: 29
	local t4 = {
		Enabled = true,
		Destroy = false,
		Origin = vector3,
		End = vector3_3,
		Radius = n4,
		Length = n5,
		Subdivisions = n6,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p6, p7) -- line: 48
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Origin, p7.End, p7.Radius, p7.Length, p7.Subdivisions)
end

return t1

