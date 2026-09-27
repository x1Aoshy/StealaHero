-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(ReplicatedStorage.Library.Modules.Packages.Trove)

local t1 = {}

local function showHighlight(p1) -- line: 18
	local Highlight = Instance.new("Highlight")

	Highlight.Name = "AreaEggHover"
	Highlight.FillTransparency = 1.0
	Highlight.OutlineTransparency = 1.0
	Highlight.OutlineColor = Color3.fromRGB(255.0, 255.0, 255.0)
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.Adornee = p1
	Highlight.Parent = p1

	return Highlight
end

function t1.Bind(p2, p3, p4) -- line: 34
	-- upvalues: Asserts (copy), TweenService (copy)
	Asserts.Model(p2)
	Asserts.Instance(p3)

	local u11 = nil

	p4:Connect(p3.PromptShown, function() -- line: 39
		-- upvalues: u11 (ref), p2 (copy), TweenService (copy)
		if u11 ~= nil then
			u11:Destroy()
		end

		local v12 = p2
		local Highlight = Instance.new("Highlight")

		Highlight.Name = "AreaEggHover"
		Highlight.FillTransparency = 1.0
		Highlight.OutlineTransparency = 1.0
		Highlight.OutlineColor = Color3.fromRGB(255.0, 255.0, 255.0)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Adornee = v12
		Highlight.Parent = v12
		u11 = Highlight
		TweenService:Create(u11, TweenInfo.new(0.15), {
			OutlineTransparency = 0.0
		}):Play()
	end)
	p4:Connect(p3.PromptHidden, function() -- line: 46
		-- upvalues: u11 (ref), TweenService (copy)
		local v14 = u11

		u11 = nil

		if v14 == nil then
			return
		end

		local tween = TweenService:Create(v14, TweenInfo.new(0.12), {
			OutlineTransparency = 1.0
		})

		tween.Completed:Once(function() -- line: 53
			-- upvalues: v14 (copy)
			v14:Destroy()
		end)
		tween:Play()
	end)
end

return t1

