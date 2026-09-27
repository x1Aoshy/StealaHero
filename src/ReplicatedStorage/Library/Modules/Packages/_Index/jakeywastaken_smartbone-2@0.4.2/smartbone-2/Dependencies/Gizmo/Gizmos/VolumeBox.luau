-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdDHNldG1ldGF0YWJsZQVDZWl2ZQlQcm9wZXJ0eXMHUmVxdWVzdAdSZWxlYXNlBlJldGFpbghSZWdpc3RlcgRJbml0B0VuYWJsZWQSQm94SGFuZGxlQWRvcm5tZW50BkNvbG9yMwxUcmFuc3BhcmVuY3kGQ0ZyYW1lBFNpemULQWx3YXlzT25Ub3AGWkluZGV4B0Fkb3JuZWUGUGFyZW50D0FjdGl2ZUluc3RhbmNlcxBTY2hlZHVsZUNsZWFuaW5nBERyYXcJVHJhbnNmb3JtB0Rlc3Ryb3kGQ3JlYXRlDFB1c2hQcm9wZXJ0eQZVcGRhdGUJd29ya3NwYWNlB1RlcnJhaW4HX19pbmRleAENAAUJBgEAAAAV/wcEAAAAAAD7CAAAnj0HAwgAAACkBgEAAAAAQJ8GAwIwAAY3AgAAADABBuoDAAAAMAIGTAQAAAAwAwZcBQAAADAEBo8GAAAAMAUGgwcAAACCBgIACAMBBAAAAEADAgMDAwQDBQMGAwcABggBGAAAAAAAAAAAAgABAAEAAQABAAEAAgcAAAAABwMBAAAIBQAABQMEQAg4TQMANwAAAABNBAPwAQAAACsEAQCCAAEATQQATAIAAABvBQMAnwQCAk0FAOoEAAAATQUFmgUAAAAwBQSaBQAAAE0FAOoEAAAATQUF2QYAAAAwBQTZBgAAADABBIUHAAAAMAIELwgAAABNBQDqBAAAAE0FBY4JAAAAMAUEjgkAAACMBQEAMAUEDQoAAAD7BQAAMAUEFAsAAAD7BQAAMAUEJAwAAABNBQNEDQAAAJUFBQ4wBQNEDQAAAE0FAIMPAAAAUgYEAJ8FAgFNBQA3AAAAAE0FBToQAAAAnwUBAYIAAQARAwIDCQMEAwoDAwMLAwwDDQMOAw8DEAMRAxIDEwIAAAAAAADwPwMHAxQAExUBGAAAAgAAAQMAAAABAAAAAAABAAAAAAACAAEAAQAAAAAAAQAAAQAAAQAAAgAAAAACAAAAAQAAAAABFAAAAAAHAwAAAAgFAAAFAwRACB3iAwkAMAEDIQAAAAAwAgMvAQAAAE0EAOoKAAAATQQEjgIAAAAwBAOOAgAAAE0EAOoKAAAATQQE2QMAAAAwBAPZAwAAAE0EAOoKAAAATQQEmgQAAAAwBAOaBAAAAE0EAI8LAAAAUgUAAFIGAwCfBAMBggMCAAwDFgMOAw8DDAMLAwkBAQMXAQAIBwD/////Af////8C/////wP/////BP////8FBgAAAAcIAAAAAwMDBgArGAEYAAEAAQABAAAAAAABAAAAAAABAAAAAAAFAAAAAAIsAAAAAAcCAAAAABxNAgA3AAAAAE0DAjMBAAAAbwQCAE0FAY4CAAAAnwMDAU0DAjMBAAAAbwQDAE0FAdkDAAAAnwMDAU0DAjMBAAAAbwQEAE0FAZoEAAAAnwMDAU0FASEFAAAATQYBLwYAAAC8AwDUBwAAAJ8DBAGCAAEACAMCAxkDDwMMAwsDFgMOAxUAOxoBGAAAAgAAAAAAAQAAAAAAAQAAAAAAAgAAAAAAAAE8AAAAAAMAAAECABijAAAApAABAAAAAEBNAABUAgAAAP8BBAAAAAAAMAEBbgMAAADAAgQAEgABADACAXMFAAAAwAIGABIAAAAwAgHUBwAAAMACCAAwAgGWCQAAAMACCgAwAgEmCwAAAIIBAgAMAxsEAAAAQAMcAx0GAAMIBgEDFQYCAxgGAwMaBAABAgMBAAEYAAAAAAACAAEAAgAAAA0AAAAYAAAQAAAKAQAAAAAE/vFIVIK0JZC99kPp8ldFQo7pXyDMNSJV

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
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, vector3: Vector3) -- line: 19
	-- upvalues: Terrain (copy)
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v14 = t2.Request("BoxHandleAdornment")

	v14.Color3 = t2.Propertys.Color3
	v14.Transparency = t2.Propertys.Transparency
	v14.CFrame = cFrame
	v14.Size = vector3
	v14.AlwaysOnTop = t2.Propertys.AlwaysOnTop
	v14.ZIndex = 1.0
	v14.Adornee = Terrain
	v14.Parent = Terrain
	Ceive.ActiveInstances = Ceive.ActiveInstances + 1.0
	t2.Register(v14)
	t2.Ceive.ScheduleCleaning()
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, vector3: Vector3) -- line: 43
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
		Size = vector3,
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
	p7:Draw(p8.Transform, p8.Size)
end

return t1

