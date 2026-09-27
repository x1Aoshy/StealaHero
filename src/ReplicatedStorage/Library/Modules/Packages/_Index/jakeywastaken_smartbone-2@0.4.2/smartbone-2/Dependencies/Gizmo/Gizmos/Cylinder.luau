-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

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
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number, n2: number, n3: number) -- line: 16
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v14 = cFrame.Position + cFrame.UpVector * (n2 * 0.5)
	local v15 = cFrame.Position - cFrame.UpVector * (n2 * 0.5)
	local cFrame2 = CFrame.lookAt(v14, v14 + cFrame.UpVector)
	local cFrame3 = CFrame.lookAt(v15, v15 - cFrame.UpVector)
	local v18 = nil
	local v19 = nil
	local v20 = nil
	local v21 = nil

	for i = 0.0, 360.0, math.floor(360.0 / n3) do
		local v23 = math.sin((math.rad(i))) * n1
		local v24 = math.cos((math.rad(i))) * n1
		local v25 = cFrame.LookVector * v24 + cFrame.RightVector * v23
		local v26 = cFrame2.Position + v25
		local v27 = cFrame3.Position + v25

		Ceive.Ray:Draw(v26, v27)

		if not v18 then
			v18 = v26
			v19 = v27
			v20 = v26
			v21 = v27
		else
			Ceive.Ray:Draw(v18, v26)
			Ceive.Ray:Draw(v19, v27)
			v18 = v26
			v19 = v27
		end
	end

	Ceive.Ray:Draw(v18, v20)
	Ceive.Ray:Draw(v19, v21)
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n4: number, n5: number, n6: number) -- line: 71
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
function t1.Update(p6, p7) -- line: 89
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Transform, p7.Radius, p7.Length, p7.Subdivisions)
end

return t1

