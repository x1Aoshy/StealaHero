-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

require(ReplicatedStorage.Library.Client.GuardTutorialPresentationComponent)
require(script.Parent.Types.Interface)

local color3 = Color3.fromRGB(255.0, 255.0, 255.0)
local t1 = {
	StepId = "HeadToPen",
	IsSatisfied = function(p1) -- line: 25
		return p1:HasReturnedToPen()
	end
}

function t1.Bind(p2, p3: ((...any) -> ...any)) -- line: 29
	-- upvalues: t1 (copy), RunService (copy)
	local n1 = 0.0
	local u9 = false

	local function refresh() -- line: 33
		-- upvalues: u9 (ref), t1 (copy), p2 (copy), p3 (copy)
		if u9 or not t1.IsSatisfied(p2) then
			return
		end

		u9 = true
		p3()
	end

	local connection = p2.Changed:Connect(refresh)
	local connection2 = RunService.Heartbeat:Connect(function(dt: number) -- line: 43
		-- upvalues: n1 (ref), u9 (ref), t1 (copy), p2 (copy), p3 (copy)
		n1 += dt

		if n1 < 0.1 then
			return
		end

		n1 = 0.0

		if not u9 then
			if not t1.IsSatisfied(p2) then
				return
			end

			u9 = true
			p3()
		end
	end)

	task.defer(refresh)

	return function() -- line: 54
		-- upvalues: connection (copy), connection2 (copy)
		connection:Disconnect()
		connection2:Disconnect()
	end
end
function t1.Present(p4, p5) -- line: 60
	-- upvalues: t1 (copy), color3 (copy)
	local function refreshPresentation() -- line: 64
		-- upvalues: t1 (copy), p5 (copy), p4 (copy), color3 (copy)
		if t1.IsSatisfied(p5) then
			p4:ClearAll()

			return
		end

		local PlotSpawnTarget = p5:GetPlotSpawnTarget()

		p4:ShowAnimatedMessage("Go to your Pen!", color3)

		if PlotSpawnTarget ~= nil then
			p4:UpdateBeamTarget(PlotSpawnTarget)

			return
		end

		p4:ClearBeam()
	end

	local connection = p5.Changed:Connect(refreshPresentation)

	refreshPresentation()

	return function() -- line: 82
		-- upvalues: connection (copy), p4 (copy)
		connection:Disconnect()
		p4:ClearAll()
	end
end

return t1

