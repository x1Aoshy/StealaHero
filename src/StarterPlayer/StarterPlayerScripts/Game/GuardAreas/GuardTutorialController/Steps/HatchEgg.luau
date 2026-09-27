-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

require(ReplicatedStorage.Library.Client.GuardTutorialPresentationComponent)

local StepUtils = require(script.Parent.Parent.StepUtils)

require(script.Parent.Types.Interface)

local color3 = Color3.fromRGB(255.0, 255.0, 255.0)
local t1 = {
	StepId = "HatchEgg",
	IsSatisfied = function(p1) -- line: 26
		return p1:HasHatchedEgg()
	end
}

function t1.Bind(p2, p3: ((...any) -> ...any)) -- line: 30
	-- upvalues: StepUtils (copy), t1 (copy)
	return StepUtils.BindOnAdapterChanged(p2, t1.IsSatisfied, p3)
end
function t1.Present(p4, p5) -- line: 34
	-- upvalues: t1 (copy), color3 (copy), RunService (copy)
	local function refreshPresentation() -- line: 38
		-- upvalues: t1 (copy), p5 (copy), p4 (copy), color3 (copy)
		if t1.IsSatisfied(p5) then
			p4:ClearAll()

			return
		end

		if not p5:HasHatchableEgg() then
			p4:ClearAll()

			return
		end

		p4:ShowAnimatedMessage("Hatch the Egg!", color3)

		local NearestHatchableEggTarget = p5:GetNearestHatchableEggTarget()

		if NearestHatchableEggTarget ~= nil then
			p4:UpdateBeamTarget(NearestHatchableEggTarget)

			return
		end

		p4:ClearBeam()
	end

	local connection = p5.Changed:Connect(refreshPresentation)
	local n1 = 0.0
	local connection2 = RunService.Heartbeat:Connect(function(dt: number) -- line: 60
		-- upvalues: n1 (ref), refreshPresentation (copy)
		n1 += dt

		if n1 < 0.25 then
			return
		end

		n1 = 0.0
		refreshPresentation()
	end)

	refreshPresentation()

	return function() -- line: 71
		-- upvalues: connection (copy), connection2 (copy), p4 (copy)
		connection:Disconnect()
		connection2:Disconnect()
		p4:ClearAll()
	end
end

return t1

