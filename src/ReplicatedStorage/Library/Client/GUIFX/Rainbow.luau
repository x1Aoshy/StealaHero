-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLBlBhcmVudApEaXNjb25uZWN0DVJlbmRlclN0ZXBwZWQHQ29ubmVjdA1SYWluYm93RWZmZWN0BGdhbWUKUnVuU2VydmljZQpHZXRTZXJ2aWNlB3JlcXVpcmUGc2NyaXB0C1JhaW5ib3dTdGVwAAQFAQQAAAYDAAAFAQIQ+wEAAE0BASQAAAAADgEHAPsBAAD7AgEA+wMCAFIEAACfAwICagMBAoIAAQD7AQMAvAEBGgEAAACfAQIBggABAAIDAQMCABEAARgAAAAAAQAAAAAAAAIAAAACEgAAAAACAAEAAAAF+wAAALwAABoAAAAAnwACAYIAAQABAwIAGQABGAAAAAABGgAAAAAJBAIAAAkGAAAFBAcDgoIV+wQAAFIFAgBSBgMAnwQDAsYFAAD7BgEATQYGzwAAAADZCAAAEgAAABIAAQASAAQAEgEF/7wGBscBAAAAnwYDAlIFBgDZBgEAEgEF/8EFAACCBgIAAgMDAwQCAAENBQEYAAAAAAECAAAAAAAAAAAAAAAIAAAADgAAAAADAAABAgAYowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAhoJAAAAnwECAsACCgASAAEAEgAAABgCAI0LAAAANQIAjQsAAACCAgIADAMGBAAAAEADBwMIAwkEAABAQAMKBAAAYEADAQMLBgIDBQECAQABGAAAAAAAAAACAAAAAAAAAAAKAAAAABEAAAEAAAAAA/TTmKyiOL4dmT/O6NCa3BeEy4/YxhfyrQ==

-- decompilation:
local RunService = game:GetService("RunService")
local RainbowStep = require(script.Parent.RainbowStep)

function RainbowEffect(p1, s1: string, n1: number?, n2: number?) -- line: 13
	-- upvalues: RainbowStep (copy), RunService (copy)
	local v7 = RainbowStep(n1, n2)
	local connection = nil

	connection = RunService.RenderStepped:Connect(function(dt: number) -- line: 17
		-- upvalues: p1 (copy), s1 (copy), v7 (copy), connection (ref)
		if p1.Parent then
			p1[s1] = v7(dt)

			return
		end

		connection:Disconnect()
	end)

	return function() -- line: 25
		-- upvalues: connection (ref)
		connection:Disconnect()
	end
end

return RainbowEffect

