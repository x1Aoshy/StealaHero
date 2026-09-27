-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local RunService = game:GetService("RunService")
local Parent = require(script.Parent.Parent)

local function makeLighter(color3: Color3, n1: number) -- line: 5
	return color3:Lerp(Color3.fromRGB(255.0, 255.0, 255.0), n1)
end
local function findColorFromObject(p1) -- line: 9
	local v8 = p1[({
		TextButton = "BackgroundColor3",
		TextLabel = "TextColor3",
		ImageLabel = "ImageColor3",
		ImageButton = "ImageColor3",
		Frame = "BackgroundColor3",
		ScrollingFrame = "BackgroundColor3",
		ViewportFrame = "BackgroundColor3"
	})[p1.ClassName]]

	if v8 then
		return v8
	end

	return Color3.fromRGB(255.0, 255.0, 255.0)
end

return function(p2, n2: number, n3: number, color3: Color3) -- line: 29
	-- upvalues: findColorFromObject (copy), Parent (copy), RunService (copy)
	local v13 = color3 or findColorFromObject(p2)
	local v14 = v13:Lerp(Color3.fromRGB(255.0, 255.0, 255.0), 0.6)
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, v13),
		ColorSequenceKeypoint.new(0.5, v14),
		ColorSequenceKeypoint.new(1.0, v13)
	})
	local v16 = Parent.Stroke.new(p2, n3)
	local v17 = Parent.Gradient.new(v16.Instance, colorSequence, 0.0)
	local n4 = 0.75
	local connection = nil

	connection = RunService.Heartbeat:Connect(function(dt) -- line: 48
		-- upvalues: v16 (copy), connection (ref), n4 (ref), n2 (copy), v17 (copy)
		if not v16.Instance or v16.Instance.Parent == nil then
			connection:Disconnect()
		end

		n4 += n2 * dt
		v17:SetRotation(n4, 1.0)
	end)

	return {
		Effects = {
			v17,
			v16
		},
		Connections = { connection }
	}
end

