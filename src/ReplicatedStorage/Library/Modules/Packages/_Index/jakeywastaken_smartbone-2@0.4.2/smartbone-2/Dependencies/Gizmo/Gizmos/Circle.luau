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
function t1.Draw(t2: {[any]: any}, cFrame: CFrame, n1: number, n2: number, n3: number, b1: boolean?) -- line: 16
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v15 = nil
	local v16 = nil
	local n4 = 0.0

	for i = 0.0, n3, math.floor(n3 / n2) do
		local v19 = math.sin((math.rad(i))) * n1
		local v20 = math.cos((math.rad(i))) * n1
		local v21 = cFrame.Position + (cFrame.UpVector * v20 + cFrame.RightVector * v19)

		if v15 == nil then
			v15 = v21
			v16 = v21
			n4 = i
		else
			Ceive.Ray:Draw(v15, v21)
			v15 = v21
			n4 = i
		end
	end

	if n4 ~= n3 then
		local v22 = math.sin((math.rad(n3))) * n1
		local v23 = math.cos((math.rad(n3))) * n1
		local v24 = cFrame.Position + (cFrame.UpVector * v23 + cFrame.RightVector * v22)

		Ceive.Ray:Draw(v15, v24)
	end

	if b1 ~= false then
		Ceive.Ray:Draw(v15, v16)
	end

	return v15
end
function t1.Create(t3: {[any]: any}, cFrame: CFrame, n5: number, n6: number, n7: number, b2: boolean?) -- line: 66
	local t4 = {
		Enabled = true,
		Destroy = false,
		Transform = cFrame,
		Radius = n5,
		Subdivisions = n6,
		Angle = n7,
		ConnectToStart = b2,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p6, p7) -- line: 85
	local Ceive = p6.Ceive

	Ceive.PushProperty("AlwaysOnTop", p7.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p7.Transparency)
	Ceive.PushProperty("Color3", p7.Color3)
	p6:Draw(p7.Transform, p7.Radius, p7.Subdivisions, p7.Angle, p7.ConnectToStart)
end

return t1

