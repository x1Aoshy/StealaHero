-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local t1 = {}
local t2 = {
	ModelAdded = require(ReplicatedStorage.Library.Modules.Packages.Signal).new(),
	ApplyModelHidden = function(p1, b1: boolean) -- line: 22
		-- upvalues: Asserts (copy)
		Asserts.Model(p1)
		Asserts.boolean(b1)

		for _, descendant in ipairs(p1:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = not b1 and 0.0 or 1.0
			end
		end
	end,
	ResolveModel = function(s1: string) -- line: 33
		-- upvalues: Asserts (copy), Workspace (copy)
		Asserts.string(s1)

		local s1_2 = Workspace:FindFirstChild(s1)

		if s1_2 == nil then
			return nil
		end

		assert(s1_2:IsA("Model"), `Workspace area egg { s1 } must be a Model`)

		return s1_2
	end
}

function t2.SetHidden(s2: string, b2: boolean) -- line: 43
	-- upvalues: Asserts (copy), t1 (copy), Workspace (copy), t2 (copy)
	Asserts.string(s2)
	Asserts.boolean(b2)

	if b2 then
		t1[s2] = true
	else
		t1[s2] = nil
	end

	for _, child in ipairs(Workspace:GetChildren()) do
		if s2 == child.Name and child:IsA("Model") then
			t2.ApplyModelHidden(child, b2)
		end
	end
end
function t2.Start() -- line: 59
	-- upvalues: Workspace (copy), t1 (copy), t2 (copy)
	Workspace.ChildAdded:Connect(function(child) -- line: 60
		-- upvalues: Workspace (copy), t1 (copy), t2 (copy)
		if not child:IsA("Model") or child.Parent ~= Workspace then
			return
		end

		if t1[child.Name] == true then
			t2.ApplyModelHidden(child, true)
		end

		t2.ModelAdded:Fire(child)
	end)
end

return table.freeze(t2)

