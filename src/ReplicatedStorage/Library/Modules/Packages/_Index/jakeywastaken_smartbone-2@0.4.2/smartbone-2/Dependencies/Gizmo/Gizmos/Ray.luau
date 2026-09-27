-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMYDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbgRJbml0B0VuYWJsZWQLQWx3YXlzT25Ub3ASQU9UV2lyZWZyYW1lSGFuZGxlB0FkZExpbmUPV2lyZWZyYW1lSGFuZGxlCkFjdGl2ZVJheXMQU2NoZWR1bGVDbGVhbmluZwREcmF3Bk9yaWdpbgNFbmQMVHJhbnNwYXJlbmN5BkNvbG9yMwdEZXN0cm95BkNyZWF0ZQxQdXNoUHJvcGVydHkGVXBkYXRlB19faW5kZXgABQgFAQAAABP/BgQAAAAAAPsHAACePQYDBwAAAKQFAQAAAABAnwUDAjAABTcCAAAAMAEF6gMAAAAwAgVMBAAAADADBVwFAAAAMAQFjwYAAACCBQIABwMBBAAAAEADAgMDAwQDBQMGAAQHARgAAAAAAAAAAAIAAQABAAEAAQACBQAAAAAIAwAAAAgFAAAFAwQICCdNAwA3AAAAAE0EA/ABAAAAKwQBAIIAAQBNBADqAgAAAE0EBI4DAAAADgQIAE0EAzIEAAAAUgYBAFIHAgC8BARoBQAAAJ8EBAFlAAcATQQDWgYAAABSBgEAUgcCALwEBGgFAAAAnwQEAU0EADcAAAAATQUEUAcAAACVBQUIMAUEUAcAAABNBAA3AAAAAE0EBDoJAAAAnwQBAYIAAQAKAwIDCAMDAwkDCgMLAwwDDQIAAAAAAADwPwMOABAPARgAAAIAAAEDAAAAAAEAAAAAAAAAAgAAAAAAAAMAAAAAAAACAAAAAAERAAAAAAcDAAAACAUAAAUDBAgIHeIDCQAwAQNDAAAAADACAwsBAAAATQQA6goAAABNBASOAgAAADAEA44CAAAATQQA6goAAABNBATZAwAAADAEA9kDAAAATQQA6goAAABNBASaBAAAADAEA5oEAAAATQQAjwsAAABSBQAAUgYDAJ8EAwGCAwIADAMQAxEDCQMSAxMDCAEBAxQBAAgHAP////8B/////wL/////A/////8E/////wUGAAAABwgAAAADAwMGACIVARgAAQABAAEAAAAAAAEAAAAAAAEAAAAAAAUAAAAAAiMAAAAABwIAAAAAHE0CADcAAAAATQMCMwEAAABvBAIATQUBjgIAAACfAwMBTQMCMwEAAABvBAMATQUB2QMAAACfAwMBTQMCMwEAAABvBAQATQUBmgQAAACfAwMBTQUBQwUAAABNBgELBgAAALwDANQHAAAAnwMEAYIAAQAIAwIDFgMJAxIDEwMQAxEDDwAyFwEYAAACAAAAAAABAAAAAAABAAAAAAACAAAAAAAAATMAAAAAAgAAAQIAE6MAAAD/AAQAAAAAADAAAG4AAAAAwAEBABIAAAAwAQBzAgAAAMABAwAwAQDUBAAAAMABBQAwAQCWBgAAAMABBwAwAQAmCAAAAIIAAgAJAxgGAAMHBgEDDwYCAxUGAwMXBAABAgMBAAEYAAAAAQACAAAADAAAEgAAEAAACgEAAAAABN+3sGYr/z7GMhwN+61siFmvr6cS7XPaZw==

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
function t1.Draw(t2: {[any]: any}, vector3: Vector3, vector3_2: Vector3) -- line: 16
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	if t2.Propertys.AlwaysOnTop then
		Ceive.AOTWireframeHandle:AddLine(vector3, vector3_2)
	else
		Ceive.WireframeHandle:AddLine(vector3, vector3_2)
	end

	local Ceive2 = t2.Ceive

	Ceive2.ActiveRays = Ceive2.ActiveRays + 1.0
	t2.Ceive.ScheduleCleaning()
end
function t1.Create(t3: {[any]: any}, vector3: Vector3, vector3_3: Vector3) -- line: 34
	local t4 = {
		Enabled = true,
		Destroy = false,
		Origin = vector3,
		End = vector3_3,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p6, p7) -- line: 50
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Origin, p7.End)
end

return t1

