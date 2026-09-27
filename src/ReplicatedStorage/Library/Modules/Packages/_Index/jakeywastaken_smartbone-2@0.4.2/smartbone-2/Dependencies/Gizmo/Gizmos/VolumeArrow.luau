-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbghSZWdpc3RlcgRJbml0B0VuYWJsZWQGQ0ZyYW1lBmxvb2tBdARVbml0CFBvc2l0aW9uCU1hZ25pdHVkZQ5Wb2x1bWVDeWxpbmRlcgREcmF3A1JheQpWb2x1bWVDb25lEFNjaGVkdWxlQ2xlYW5pbmcGT3JpZ2luA0VuZA5DeWxpbmRlclJhZGl1cwpDb25lUmFkaXVzBkxlbmd0aAtVc2VDeWxpbmRlcgtBbHdheXNPblRvcAxUcmFuc3BhcmVuY3kGQ29sb3IzB0Rlc3Ryb3kGQ3JlYXRlDFB1c2hQcm9wZXJ0eQZSYWRpdXMGVXBkYXRlB19faW5kZXgABQkGAQAAABX/BwQAAAAAAPsIAACePQcDCAAAAKQGAQAAAABAnwYDAjAABjcCAAAAMAEG6gMAAAAwAgZMBAAAADADBlwFAAAAMAQGjwYAAAAwBQaDBwAAAIIGAgAIAwEEAAAAQAMCAwMDBAMFAwYDBwAECAEYAAAAAAAAAAACAAEAAQABAAEAAQACBQAAAAARBwAAABAJAAEFBwQICAICAoEICwkCO00HADcAAAAATQgH8AEAAAArCAEAggABAKQIBAAADCCAJgsCAU0LCwcFAAAAWwwFBgkKCwwmCQIKUgoCAJ8IAwIqBhUAAQAAgE0JCDsHAAAAJgoJAU0KCqoIAAAApAsEAAAMIIBDDQEJWwwNBlINAgCfCwMCTQwHCwkAAABSDgsAUg8DAFIQCgC8DAzUCgAAAJ8MBQFlAAcATQkHuAsAAABSCwEAUgwCALwJCdQKAAAAnwkEAU0JB3oMAAAAUgsIAFIMBABSDQUAvAkJ1AoAAACfCQUBTQkANwAAAABNCQk6DQAAAJ8JAQGCAAEADgMCAwkDCgMLBAAMIIADDAIAAAAAAADgPwMNAw4DDwMQAxEDEgMTABEQARgAAAIAAAEDAAAAAAAAAAAAAgABAAEAAAEAAAAAAAIAAAAAAAAAAAIAAAAAAAADAAAAAAAAAAEAAAAAARkAAAAACwcAAAAMCQAABQcECAgCAgKBJeIHDQAwAQdDAAAAADACBwsBAAAAMAMH+QIAAAAwBAcWAwAAADAFB60EAAAAMAYHZwUAAABNCADqDgAAAE0ICI4GAAAAMAgHjgYAAABNCADqDgAAAE0ICNkHAAAAMAgH2QcAAABNCADqDgAAAE0ICJoIAAAAMAgHmggAAABNCACPDwAAAFIJAABSCgcAnwgDAYIHAgAQAxQDFQMWAxcDGAMZAxoDGwMcAwkBAQMdAQAICwD/////Af////8C/////wP/////BP////8F/////wb/////B/////8I/////wkKAAAACwwAAAADAwMGAC8eARgAAQABAAEAAQABAAEAAQAAAAAAAQAAAAAAAQAAAAAABQAAAAACNwAAAAAKAgAAAAAiTQIANwAAAABNAwIzAQAAAG8EAgBNBQGOAgAAAJ8DAwFNAwIzAQAAAG8EAwBNBQHZAwAAAJ8DAwFNAwIzAQAAAG8EBABNBQGaBAAAAJ8DAwFNBQFDBQAAAE0GAQsGAAAATQcBcQcAAABNCAGtCAAAAE0JAWcJAAAAvAMA1AoAAACfAwcBggABAAsDAgMfAxoDGwMcAxQDFQMgAxgDGQMQAEohARgAAAIAAAAAAAEAAAAAAAEAAAAAAAMAAQABAAEAAQD7AAAHSwAAAAACAAABAgATowAAAP8ABAAAAAAAMAAAbgAAAADAAQEAEgAAADABAHMCAAAAwAEDADABANQEAAAAwAEFADABAJYGAAAAwAEHADABACYIAAAAggACAAkDIgYAAwgGAQMQBgIDHgYDAyEEAAECAwEAARgAAAABAAIAAAANAAAeAAAbAAAQAQAAAAAEjEm/e45jDWvHWcbR5FQ+VPxRqA++jdV6

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.Init(p1, p2, p3, p4, p5, p6) -- line: 4
	-- upvalues: t1 (copy)
	local self = setmetatable({}, t1)

	self.Ceive = p1
	self.Propertys = p2
	self.Request = p3
	self.Release = p4
	self.Retain = p5
	self.Register = p6

	return self
end
function t1.Draw(t2: {[any]: any}, vector3: Vector3, vector3_2: Vector3, n1: number, n2: number, n3: number, b1: boolean?) -- line: 17
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local cFrame = CFrame.lookAt(vector3_2 - (vector3_2 - vector3).Unit * (n3 * 0.5), vector3_2)

	if b1 == true then
		local cFramePosition = cFrame.Position
		local Magnitude = (cFramePosition - vector3).Magnitude
		local cFrame2 = CFrame.lookAt((vector3 + cFramePosition) * 0.5, vector3_2)

		Ceive.VolumeCylinder:Draw(cFrame2, n1, Magnitude)
	else
		Ceive.Ray:Draw(vector3, vector3_2)
	end

	Ceive.VolumeCone:Draw(cFrame, n2, n3)
	t2.Ceive.ScheduleCleaning()
end
function t1.Create(t3: {[any]: any}, vector3: Vector3, vector3_3: Vector3, n4: number, n5: number, n6: number, b2: boolean?) -- line: 47
	local t4 = {
		Enabled = true,
		Destroy = false,
		Origin = vector3,
		End = vector3_3,
		CylinderRadius = n4,
		ConeRadius = n5,
		Length = n6,
		UseCylinder = b2,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p7, p8) -- line: 74
	local Ceive = p7.Ceive

	Ceive.PushProperty("AlwaysOnTop", p8.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p8.Transparency)
	Ceive.PushProperty("Color3", p8.Color3)
	p7:Draw(p8.Origin, p8.End, p8.Radius, p8.Length, p8.UseCylinder)
end

return t1

