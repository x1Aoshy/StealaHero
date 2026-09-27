-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Easing = require(ReplicatedStorage.Library.Functions.Easing)
local EggActionMovement = require(script.Parent.EggActionMovement)
local EggRenderer = require(script.Parent.EggRenderer)
local SkipEggEffect = ReplicatedStorage.Assets.Particles["Egg Open"].SkipEggEffect

return {
	Play = function(p1) -- line: 24
		-- upvalues: Asserts (copy), EggRenderer (copy), SkipEggEffect (copy), RunService (copy), Easing (copy), EggActionMovement (copy), Debris (copy)
		Asserts.Model(p1)
		EggRenderer.DisableCollisions(p1)

		local Pivot = p1:GetPivot()
		local n1 = 0.0
		local clone = SkipEggEffect.Attachment:Clone()

		clone.Parent = workspace.Terrain

		for _, descendant in clone:GetDescendants() do
			descendant.Enabled = true
		end

		clone.WorldCFrame = Pivot * CFrame.Angles(0.0, 0.0, 3.141592653589793)

		while n1 < 1.2 do
			n1 += RunService.Heartbeat:Wait()

			local v15 = Easing(n1 / 1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			EggActionMovement.SetPivot(p1, Pivot * CFrame.Angles(0.0, math.rad(v15 * 1080.0), 0.0) * CFrame.Angles(0.0, 0.0, (math.rad(math.sin(1080.0 * v15) * 35.0 * (1.0 - v15)))))
		end

		for _, descendant in clone:GetDescendants() do
			descendant.Enabled = false
		end

		Debris:AddItem(clone, 5.0)
	end
}

