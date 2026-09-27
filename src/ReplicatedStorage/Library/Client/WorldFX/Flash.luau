-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local RunService = game:GetService("RunService")

function Flash(p1, p2, p3, p4, p5) -- line: 4
	-- upvalues: RunService (copy)
	local u7 = p2 or 1.0
	local u8 = p3 or 0.5
	local v9 = p4 or Color3.new(1.0, 1.0, 1.0)

	if not p1 then
		warn("Object is missing")

		return function() -- line: 12
		end
	end

	local t1 = {}

	if p1:IsA("BasePart") and (not p5 or p5(p1)) then
		table.insert(t1, p1)
	end

	for _, descendant in ipairs(p1:GetDescendants()) do
		if descendant:IsA("BasePart") and (not p5 or p5(descendant)) then
			table.insert(t1, descendant)
		end
	end

	local t2 = {
		Enum.NormalId.Back,
		Enum.NormalId.Front,
		Enum.NormalId.Left,
		Enum.NormalId.Right,
		Enum.NormalId.Top,
		Enum.NormalId.Bottom
	}
	local t3 = {}

	for _, v in ipairs(t1) do
		for i = 1.0, 6.0 do
			local Decal = Instance.new("Decal")

			Decal.Texture = "rbxassetid://6381483576"
			Decal.Name = "_SELECTIONFX"
			Decal.Transparency = u8
			Decal.Color3 = v9
			Decal.Face = t2[i]
			Decal.Parent = v
			table.insert(t3, Decal)
		end
	end

	local connection = nil

	local function cleanup() -- line: 53
		-- upvalues: connection (ref), t3 (copy)
		if connection then
			connection:Disconnect()
		end

		for _, v in ipairs(t3) do
			if v then
				v:Destroy()
			end
		end
	end

	local n1 = 0.0

	connection = RunService.RenderStepped:Connect(function(dt) -- line: 65
		-- upvalues: p1 (copy), t3 (copy), n1 (ref), u7 (ref), u8 (ref), cleanup (copy)
		if p1 and (p1.Parent and t3[1.0]) then
			n1 = math.clamp(n1 + dt, 0.0, u7)

			local v25 = n1 / u7
			local v26 = u8 + (1.0 - u8) * v25

			for _, v in ipairs(t3) do
				if not v then
					cleanup()

					return
				end

				v.Transparency = v26
			end

			if n1 >= u7 then
				cleanup()

				return
			end
		else
			cleanup()
		end
	end)

	return cleanup
end

return Flash

