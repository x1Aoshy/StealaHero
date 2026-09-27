-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local scriptParent = script.Parent
local u3 = true
local Network = require(ReplicatedStorage.Library.Client.Network)
local GetMouseToWorld = require(ReplicatedStorage.Library.Functions.GetMouseToWorld)
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)

scriptParent.Activated:Connect(function() -- line: 9
	-- upvalues: u3 (ref), scriptParent (copy), GetMouseToWorld (copy), Message (copy), Network (copy)
	if u3 then
		u3 = false
		task.delay(0.4, function() -- line: 12
			-- upvalues: u3 (ref)
			u3 = true
		end)

		if math.min(scriptParent:GetAttribute("Uses") or 1.0, scriptParent:GetAttribute("LocalUses") or 1.0) <= 0.0 then
			return
		end

		local raycastParams = RaycastParams.new()

		raycastParams.FilterDescendantsInstances = { workspace.Map.CanPlace }
		raycastParams.FilterType = Enum.RaycastFilterType.Include

		local v9 = GetMouseToWorld(raycastParams, 1000.0)

		if not v9 then
			Message.Bottom({
				Message = "You cannot place your egg here!",
				Time = 0.5
			})

			return
		end

		Network.Fire(Network.NET_MAP.Pets.PET_EGG_SERVICE, "CreateEgg", v9.Position)
	end
end)
scriptParent:GetAttributeChangedSignal("Uses"):Connect(function() -- line: 33
	-- upvalues: scriptParent (copy)
	local v10 = scriptParent:GetAttribute("Uses") or 1.0

	scriptParent:SetAttribute("LocalUses", v10)
	scriptParent.Name = (scriptParent:GetAttribute("EggName") or "Common") .. " x" .. v10
end)

local v7 = scriptParent:GetAttribute("Uses") or 1.0

scriptParent:SetAttribute("LocalUses", v7)
scriptParent.Name = (scriptParent:GetAttribute("EggName") or "Common") .. " x" .. v7

