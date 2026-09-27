-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t1 = {}
local Client = ReplicatedStorage.Library.Client
local Packages = ReplicatedStorage.Library.Modules.Packages
local WeatherEffectController = require(Client.WeatherEffectController)
local WeatherSoundsController = require(Client.WeatherSoundsController)
local CycleController = require(Client.CycleController)
local v8 = require(Packages.Trove).new()

function t1.OnStart(_) -- line: 15
	-- upvalues: ReplicatedStorage (copy), v8 (copy), WeatherSoundsController (copy), CycleController (copy), WeatherEffectController (copy)
	ReplicatedStorage:SetAttribute("Effect_Space", true)
	v8:Add(function() -- line: 17
		-- upvalues: ReplicatedStorage (copy)
		ReplicatedStorage:SetAttribute("Effect_Space", nil)
	end)
	WeatherSoundsController:UpdateOST()
	CycleController:Update()

	local v10 = v8:Extend()
	local u11 = true

	v8:Add(function() -- line: 24
		-- upvalues: u11 (ref)
		u11 = false
	end)

	local u12 = nil

	local function runUpdate() -- line: 28
		-- upvalues: ReplicatedStorage (copy), u11 (ref), u12 (ref), WeatherEffectController (copy), WeatherSoundsController (copy), CycleController (copy), v10 (copy)
		local NyanCatsEvent = ReplicatedStorage:GetAttribute("NyanCatsEvent")
		local v17 = if u11 then if not NyanCatsEvent then script.Space else script.Nyan else nil

		if v17 == u12 then
			return
		end

		u12 = v17
		WeatherEffectController:Activate("Blink")
		WeatherSoundsController:UpdateOST()
		CycleController:Update()
		v10:Destroy()

		if v17 then
			local clone = v10:Clone(v17)

			clone.Parent = workspace
			clone.spacemeshbg.Transparency = 0.0

			for _, descendant in clone:GetDescendants() do
				if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
					descendant.Enabled = true
				end
			end
		end
	end

	ReplicatedStorage:GetAttributeChangedSignal("NyanCatsEvent"):Connect(runUpdate)
	v8:Add(task.spawn(runUpdate))
	v8:Add(runUpdate)
end
function t1.OnStop(_) -- line: 55
	-- upvalues: v8 (copy)
	v8:Destroy()
end
function t1.OnLoad(_) -- line: 59
end

return t1

