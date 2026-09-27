-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMfDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbghSZWdpc3RlcgRJbml0B0VuYWJsZWQTQ29uZUhhbmRsZUFkb3JubWVudAZDb2xvcjMMVHJhbnNwYXJlbmN5BkNGcmFtZQtBbHdheXNPblRvcAZaSW5kZXgGSGVpZ2h0BlJhZGl1cwdBZG9ybmVlBlBhcmVudA9BY3RpdmVJbnN0YW5jZXMQU2NoZWR1bGVDbGVhbmluZwREcmF3CVRyYW5zZm9ybQZMZW5ndGgHRGVzdHJveQZDcmVhdGUMUHVzaFByb3BlcnR5BlVwZGF0ZQl3b3Jrc3BhY2UHVGVycmFpbgdfX2luZGV4AQ0ABQkGAQAAABX/BwQAAAAAAPsIAACePQcDCAAAAKQGAQAAAABAnwYDAjAABjcCAAAAMAEG6gMAAAAwAgZMBAAAADADBlwFAAAAMAQGjwYAAAAwBQaDBwAAAIIGAgAIAwEEAAAAQAMCAwMDBAMFAwYDBwAGCAEYAAAAAAAAAAACAAEAAQABAAEAAQACBwAAAAAIBAEAAAkGAAAFBARAAgI6TQQANwAAAABNBQTwAQAAACsFAQCCAAEATQUATAIAAABvBgMAnwUCAk0GAOoEAAAATQYGmgUAAAAwBgWaBQAAAE0GAOoEAAAATQYG2QYAAAAwBgXZBgAAADABBYUHAAAATQYA6gQAAABNBgaOCAAAADAGBY4IAAAAjAYBADAGBQ0JAAAAMAMFvAoAAAAwAgVxCwAAAPsGAAAwBgUUDAAAAPsGAAAwBgUkDQAAAE0GBEQOAAAAlQYGDzAGBEQOAAAATQYAgxAAAABSBwUAnwYCAU0GADcAAAAATQYGOhEAAACfBgEBggABABIDAgMJAwQDCgMDAwsDDAMNAw4DDwMQAxEDEgMTAxQCAAAAAAAA8D8DBwMVABMWARgAAAIAAAEDAAAAAQAAAAAAAQAAAAAAAgABAAAAAAABAAABAAEAAQAAAQAAAgAAAAACAAAAAQAAAAABFAAAAAAIBAAAAAkGAAAFBARAAgIf4gQKADABBCEAAAAAMAIEcQEAAAAwAwStAgAAAE0FAOoLAAAATQUFjgMAAAAwBQSOAwAAAE0FAOoLAAAATQUF2QQAAAAwBQTZBAAAAE0FAOoLAAAATQUFmgUAAAAwBQSaBQAAAE0FAI8MAAAAUgYAAFIHBACfBQMBggQCAA0DFwMRAxgDDgMMAwsDCQEBAxkBAAgIAP////8B/////wL/////A/////8E/////wX/////BgcAAAAICQAAAAMDAwYALBoBGAABAAEAAQABAAAAAAABAAAAAAABAAAAAAAFAAAAAAItAAAAAAgCAAAAAB5NAgA3AAAAAE0DAjMBAAAAbwQCAE0FAY4CAAAAnwMDAU0DAjMBAAAAbwQDAE0FAdkDAAAAnwMDAU0DAjMBAAAAbwQEAE0FAZoEAAAAnwMDAU0FASEFAAAATQYBcQYAAABNBwGtBwAAALwDANQIAAAAnwMFAYIAAQAJAwIDGwMOAwwDCwMXAxEDGAMWAD0cARgAAAIAAAAAAAEAAAAAAAEAAAAAAAIAAAAAAAAAAAE+AAAAAAMAAAECABijAAAApAABAAAAAEBNAABUAgAAAP8BBAAAAAAAMAEBbgMAAADAAgQAEgABADACAXMFAAAAwAIGABIAAAAwAgHUBwAAAMACCAAwAgGWCQAAAMACCgAwAgEmCwAAAIIBAgAMAx0EAAAAQAMeAx8GAAMIBgEDFgYCAxoGAwMcBAABAgMBAAEYAAAAAAACAAEAAgAAAA0AAAAZAAARAAAKAQAAAAAE2ZNZ9dcKd11VxFwQQt+usKmLToHrVzP0

-- decompilation:
local Terrain = workspace.Terrain
local t1 = {}

t1.__index = t1

function t1.Init(p1, p2, p3, p4, p5, p6) -- line: 6
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
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number, n2: number) -- line: 19
	-- upvalues: Terrain (copy)
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v15 = t2.Request("ConeHandleAdornment")

	v15.Color3 = t2.Propertys.Color3
	v15.Transparency = t2.Propertys.Transparency
	v15.CFrame = cFrame
	v15.AlwaysOnTop = t2.Propertys.AlwaysOnTop
	v15.ZIndex = 1.0
	v15.Height = n2
	v15.Radius = n1
	v15.Adornee = Terrain
	v15.Parent = Terrain
	Ceive.ActiveInstances = Ceive.ActiveInstances + 1.0
	t2.Register(v15)
	t2.Ceive.ScheduleCleaning()
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n3: number, n4: number) -- line: 44
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
		Radius = n3,
		Length = n4,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p7, p8) -- line: 61
	local Ceive = p7.Ceive

	Ceive.PushProperty("AlwaysOnTop", p8.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p8.Transparency)
	Ceive.PushProperty("Color3", p8.Color3)
	p7:Draw(p8.Transform, p8.Radius, p8.Length)
end

return t1

