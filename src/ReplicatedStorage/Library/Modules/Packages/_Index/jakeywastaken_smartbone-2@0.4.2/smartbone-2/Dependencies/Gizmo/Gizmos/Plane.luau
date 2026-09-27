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
function t1.Draw(t2: {[any]: any}, vector3: Vector3, vector3_2: Vector3, vector3_3: Vector3) -- line: 16
	local Ceive = t2.Ceive

	if not Ceive.Enabled then
		return
	end

	local v13 = vector3_3 * Vector3.new(1.0, 1.0, 0.0)
	local cFrame = CFrame.lookAt(vector3, vector3 + vector3_2)
	local UpVector = cFrame.UpVector
	local RightVector = cFrame.RightVector
	local LookVector = cFrame.LookVector
	local v18 = v13 * 0.5

	local function CalculateZFace(p6, p7, p8) -- line: 35
		-- upvalues: vector3 (copy), Ceive (copy)
		local v31 = vector3 + (p6 - p7 + p8)
		local v32 = vector3 + (p6 + p7 + p8)
		local v33 = vector3 + (-p6 - p7 + p8)
		local v34 = vector3 + (-p6 + p7 + p8)

		Ceive.Ray:Draw(v31, v32)
		Ceive.Ray:Draw(v31, v33)
		Ceive.Ray:Draw(v32, v34)
		Ceive.Ray:Draw(v32, v33)
		Ceive.Ray:Draw(v33, v34)
	end

	CalculateZFace(UpVector * v18.Y, RightVector * v18.X, LookVector * v18.Z)
end
function t1.Create(t3: {[any]: any}, vector3: Vector3, vector3_4: Vector3, vector3_5: Vector3) -- line: 53
	local t4 = {
		Enabled = true,
		Destroy = false,
		Position = vector3,
		Normal = vector3_4,
		Size = vector3_5,
		AlwaysOnTop = t3.Propertys.AlwaysOnTop,
		Transparency = t3.Propertys.Transparency,
		Color3 = t3.Propertys.Color3
	}

	t3:Retain(t4)

	return t4
end
function t1.Update(p9, p10) -- line: 70
	local Ceive = p9.Ceive

	Ceive.PushProperty("AlwaysOnTop", p10.AlwaysOnTop)
	Ceive.PushProperty("Transparency", p10.Transparency)
	Ceive.PushProperty("Color3", p10.Color3)
	p9:Draw(p10.Position, p10.Normal, p10.Size)
end

return t1

