-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local CurrentCamera = workspace.CurrentCamera
local t1 = {}

t1.__index = t1

function t1.Init(p1, p2, p3, p4, p5) -- line: 9
	-- upvalues: t1 (copy)
	local self = setmetatable({}, t1)

	self.Ceive = p1
	self.Propertys = p2
	self.Request = p3
	self.Release = p4
	self.Retain = p5

	return self
end
function t1.Draw(t2: {[any]: any}, vector3: Vector3, s1: string, n1: number?) -- line: 21
	-- upvalues: CurrentCamera (copy)
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	if t2.Propertys.AlwaysOnTop then
		local Magnitude = (vector3 - CurrentCamera.CFrame.Position).Magnitude
		local v15 = Ceive.PopProperty("Color3")

		Ceive.PushProperty("Color3", Color3.new())

		local v16 = -Vector3.new(1.0, 1.0, 0.0).Unit

		Ceive.AOTWireframeHandle:AddText(vector3 + v16 * (Magnitude * 0.00175), s1, n1)
		Ceive.PushProperty("Color3", v15)
		Ceive.AOTWireframeHandle:AddText(vector3, s1, n1)
	else
		local Magnitude = (vector3 - CurrentCamera.CFrame.Position).Magnitude
		local v18 = Ceive.PopProperty("Color3")

		Ceive.PushProperty("Color3", Color3.new())

		local v19 = -Vector3.new(1.0, 1.0, 0.0).Unit

		Ceive.WireframeHandle:AddText(vector3 + v19 * (Magnitude * 0.00175), s1, n1)
		Ceive.PushProperty("Color3", v18)
		Ceive.WireframeHandle:AddText(vector3, s1, n1)
	end

	t2.Ceive.ScheduleCleaning()
end
function t1.Create(t3: {[any]: any}, vector3: Vector3, s2: string, n2: number?) -- line: 60
	local t4 = {
		Enabled = true,
		Destroy = false,
		Origin = vector3,
		Text = s2,
		Size = n2,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p6, p7) -- line: 77
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Origin, p7.Text, p7.Size)
end

return t1

