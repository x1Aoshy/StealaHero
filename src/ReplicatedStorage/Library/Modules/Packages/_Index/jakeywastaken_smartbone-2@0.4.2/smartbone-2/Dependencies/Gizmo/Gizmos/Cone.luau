-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.Init(p1, p2, p3, p4, p5) -- line: 6
	-- upvalues: t1 (copy)
	local self = setmetatable({}, t1)

	self.Ceive = p1
	self.Propertys = p2
	self.Request = p3
	self.Release = p4
	self.Retain = p5

	return self
end
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number, n2: number, n3: number) -- line: 18
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v14 = cFrame * CFrame.Angles(-1.5707963267948966, 0.0, 0.0)
	local v15 = v14.Position + v14.UpVector * (n2 * 0.5)
	local v16 = v14.Position + -v14.UpVector * (n2 * 0.5)
	local cFrame2 = CFrame.lookAt(v15, v15 + v14.UpVector)
	local cFrame3 = CFrame.lookAt(v16, v16 - v14.UpVector)
	local v19 = nil
	local v20 = nil

	for i = 0.0, 360.0, math.floor(360.0 / n3) do
		local v22 = math.sin((math.rad(i))) * n1
		local v23 = math.cos((math.rad(i))) * n1
		local v24 = v14.LookVector * v23 + v14.RightVector * v22
		local v25 = cFrame3.Position + v24

		if not v19 then
			v19 = v25
			v20 = v25
			Ceive.Ray:Draw(v25, cFrame2.Position)
		else
			Ceive.Ray:Draw(v25, cFrame2.Position)
			Ceive.Ray:Draw(v19, v25)
			v19 = v25
		end
	end

	Ceive.Ray:Draw(v19, v20)
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n4: number, n5: number, n6: number) -- line: 63
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
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
function t1.Update(p6, p7) -- line: 81
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Transform, p7.Radius, p7.Length, p7.Subdivisions)
end

return t1

