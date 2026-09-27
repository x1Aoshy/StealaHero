-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Boundary = ReplicatedStorage.Assets.Extra.Boundary

return {
	createBoundary = function(p1) -- line: 17
		-- upvalues: Asserts (copy), Boundary (copy), Constants (copy)
		Asserts.Model(p1)

		local Boundary2 = p1:FindFirstChild("Boundary")

		if Boundary2 then
			return Boundary2
		end

		local clone = Boundary:Clone()

		clone.Size = Vector3.new(0.15, Constants.MIN_PLACE_GRID_SIZE, Constants.MIN_PLACE_GRID_SIZE)
		clone.CFrame = p1:GetPivot() * CFrame.fromEulerAnglesXYZ(0.0, 0.0, 1.5707963267948966)
		clone.Name = "Boundary"
		clone.Anchored = true
		clone.CanCollide = false
		clone.Color = Color3.fromRGB(248.0, 248.0, 248.0)
		clone.Transparency = 0.9
		clone:SetAttribute("MutationFXDontRender", true)
		clone:SetAttribute("EggBoundary", true)
		clone.Parent = p1

		return clone
	end,
	createServerBoundary = function(p2) -- line: 39
		-- upvalues: Asserts (copy), Constants (copy)
		Asserts.Model(p2)

		local ServerBoundary = p2:FindFirstChild("ServerBoundary")

		if ServerBoundary then
			return ServerBoundary
		end

		local Part = Instance.new("Part")

		Part.Name = "ServerBoundary"
		Part.Size = Vector3.new(0.15, Constants.SERVER_MIN_GRID_SIZE, Constants.SERVER_MIN_GRID_SIZE)
		Part.CFrame = p2:GetPivot() * CFrame.fromEulerAnglesXYZ(0.0, 0.0, 1.5707963267948966)
		Part.Anchored = true
		Part.CanCollide = false
		Part.Transparency = 1.0
		Part:SetAttribute("MutationFXDontRender", true)
		Part:SetAttribute("EggBoundary", true)
		Part.Parent = p2

		return Part
	end
}

