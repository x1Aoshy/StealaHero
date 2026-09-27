-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

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
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number, n2: number, n3: number?, n4: number?) -- line: 19
	-- upvalues: Terrain (copy)
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v17 = t2.Request("CylinderHandleAdornment")

	v17.Color3 = t2.Propertys.Color3
	v17.Transparency = t2.Propertys.Transparency
	v17.CFrame = cFrame
	v17.Height = n2
	v17.Radius = n1
	v17.InnerRadius = n3 or 0.0
	v17.Angle = n4 or 360.0
	v17.AlwaysOnTop = t2.Propertys.AlwaysOnTop
	v17.ZIndex = 1.0
	v17.Adornee = Terrain
	v17.Parent = Terrain
	Ceive.ActiveInstances = Ceive.ActiveInstances + 1.0
	t2.Register(v17)
	t2.Ceive.ScheduleCleaning()
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n5: number, n6: number, n7: number?, n8: number?) -- line: 46
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
		Radius = n5,
		Length = n6,
		InnerRadius = n7 or 0.0,
		Angle = n8 or 360.0,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p7, p8) -- line: 65
	local Ceive = p7.Ceive

	Ceive.PushProperty("AlwaysOnTop", p8.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p8.Transparency)
	Ceive.PushProperty("Color3", p8.Color3)
	p7:Draw(p8.Transform, p8.Radius, p8.Length, p8.InnerRadius, p8.Angle)
end

return t1

