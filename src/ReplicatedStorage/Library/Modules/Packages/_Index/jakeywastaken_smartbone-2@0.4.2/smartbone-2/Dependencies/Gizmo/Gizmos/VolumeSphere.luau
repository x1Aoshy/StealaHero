-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbghSZWdpc3RlcgRJbml0B0VuYWJsZWQVU3BoZXJlSGFuZGxlQWRvcm5tZW50BkNvbG9yMwxUcmFuc3BhcmVuY3kGQ0ZyYW1lBlJhZGl1cwtBbHdheXNPblRvcAZaSW5kZXgHQWRvcm5lZQZQYXJlbnQPQWN0aXZlSW5zdGFuY2VzEFNjaGVkdWxlQ2xlYW5pbmcERHJhdwlUcmFuc2Zvcm0HRGVzdHJveQZDcmVhdGUMUHVzaFByb3BlcnR5BlVwZGF0ZQl3b3Jrc3BhY2UHVGVycmFpbgdfX2luZGV4AQ0ABQkGAQAAABX/BwQAAAAAAPsIAACePQcDCAAAAKQGAQAAAABAnwYDAjAABjcCAAAAMAEG6gMAAAAwAgZMBAAAADADBlwFAAAAMAQGjwYAAAAwBQaDBwAAAIIGAgAIAwEEAAAAQAMCAwMDBAMFAwYDBwAGCAEYAAAAAAAAAAACAAEAAQABAAEAAQACBwAAAAAHAwEAAAgFAAAFAwRAAjhNAwA3AAAAAE0EA/ABAAAAKwQBAIIAAQBNBABMAgAAAG8FAwCfBAICTQUA6gQAAABNBQWaBQAAADAFBJoFAAAATQUA6gQAAABNBQXZBgAAADAFBNkGAAAAMAEEhQcAAAAwAgRxCAAAAE0FAOoEAAAATQUFjgkAAAAwBQSOCQAAAIwFAQAwBQQNCgAAAPsFAAAwBQQUCwAAAPsFAAAwBQQkDAAAAE0FA0QNAAAAlQUFDjAFA0QNAAAATQUAgw8AAABSBgQAnwUCAU0FADcAAAAATQUFOhAAAACfBQEBggABABEDAgMJAwQDCgMDAwsDDAMNAw4DDwMQAxEDEgMTAgAAAAAAAPA/AwcDFAATFQEYAAACAAABAwAAAAEAAAAAAAEAAAAAAAIAAQABAAAAAAABAAABAAABAAACAAAAAAIAAAABAAAAAAEUAAAAAAcDAAAACAUAAAUDBEACHeIDCQAwAQMhAAAAADACA3EBAAAATQQA6goAAABNBASOAgAAADAEA44CAAAATQQA6goAAABNBATZAwAAADAEA9kDAAAATQQA6goAAABNBASaBAAAADAEA5oEAAAATQQAjwsAAABSBQAAUgYDAJ8EAwGCAwIADAMWAw4DDwMMAwsDCQEBAxcBAAgHAP////8B/////wL/////A/////8E/////wUGAAAABwgAAAADAwMGACsYARgAAQABAAEAAAAAAAEAAAAAAAEAAAAAAAUAAAAAAiwAAAAABwIAAAAAHE0CADcAAAAATQMCMwEAAABvBAIATQUBjgIAAACfAwMBTQMCMwEAAABvBAMATQUB2QMAAACfAwMBTQMCMwEAAABvBAQATQUBmgQAAACfAwMBTQUBIQUAAABNBgFxBgAAALwDANQHAAAAnwMEAYIAAQAIAwIDGQMPAwwDCwMWAw4DFQA7GgEYAAACAAAAAAABAAAAAAABAAAAAAACAAAAAAAAATwAAAAAAwAAAQIAGKMAAACkAAEAAAAAQE0AAFQCAAAA/wEEAAAAAAAwAQFuAwAAAMACBAASAAEAMAIBcwUAAADAAgYAEgAAADACAdQHAAAAwAIIADACAZYJAAAAwAIKADACASYLAAAAggECAAwDGwQAAABAAxwDHQYAAwgGAQMVBgIDGAYDAxoEAAECAwEAARgAAAAAAAIAAQACAAAADQAAABgAABAAAAoBAAAAAAQXICLQFn/BqD1edHX2xslOZzg1pCXkSNE=

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
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number) -- line: 19
	-- upvalues: Terrain (copy)
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v14 = t2.Request("SphereHandleAdornment")

	v14.Color3 = t2.Propertys.Color3
	v14.Transparency = t2.Propertys.Transparency
	v14.CFrame = cFrame
	v14.Radius = n1
	v14.AlwaysOnTop = t2.Propertys.AlwaysOnTop
	v14.ZIndex = 1.0
	v14.Adornee = Terrain
	v14.Parent = Terrain
	Ceive.ActiveInstances = Ceive.ActiveInstances + 1.0
	t2.Register(v14)
	t2.Ceive.ScheduleCleaning()
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n2: number) -- line: 43
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
		Radius = n2,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p7, p8) -- line: 59
	local Ceive = p7.Ceive

	Ceive.PushProperty("AlwaysOnTop", p8.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p8.Transparency)
	Ceive.PushProperty("Color3", p8.Color3)
	p7:Draw(p8.Transform, p8.Radius)
end

return t1

