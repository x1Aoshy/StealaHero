-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBm51bWJlcgRjb25kCURpcmVjdG9yeRBTcGVlZFBvd2VyUmV3YXJkQFByb2R1Y3RzIGRpcmVjdG9yeSBtdXN0IGNvbnRhaW4gYXQgbGVhc3Qgb25lIHNwZWVkLXBvd2VyIHByb2R1Y3QGYXNzZXJ0ElNtYWxsZXN0U3VmZmljaWVudARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2UAAgoBAgAABgMAAAUBAjb7AQAATQEBYAAAAABSAgAAnwECAfsBAABNAQEdAQAAAIwDAAC3AwIAAAAAAKkCAAGpAgEAnwECAcYBAADGAgAA+wMBAE0DA5ECAAAAxgQAAMYFAABkAxQATQgHUgMAAABHCBEAAAAAAEcBBQAAAAAATQkBUgMAAABgCQIACAAAAFIBBwB9AAgACAAAAEcCBQAAAAAATQkCUgMAAABgCAIACQAAAFICBwBuA+v/AgAAAFIDAgArAwcAgQEBBQQAAABSBAEAbwUEAKQDBgAAAFBAnwMDAoIDAgAHAwEDAgMDAwQDBQMGBAAAUEAAEgcBGAAAAAAAAQAAAAAAAAAAAgEBAAAAAAABAAEABQAAAAAAAQMAAQAAAAAAAfMAEgABAAAAAAAAABMAAAAABgAAAQIAKKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIFAAAAQECkAwkAAACAQE0DAyQKAAAAnwICAqQDBQAAAEBApAQJAAAAgEBNBAQkCgAAAE0EBO8LAAAATQQEDwwAAACfAwIC/wQBAAAAAADABQ0AEgABABIAAgAwBQQzDgAAAIIEAgAPAwgEAAAAQAMJAwoDCwQAAEBAAwwDDQMOBAAAgEADDwMQAxEGAAMHAQABAAEYAAMAAAAAAAMAAAAAAAABAAAAAAAAAQAAAAAAAAAAAAADAAYAAAAAHAEAAAAAAYS1b7q4Ii8f9CmOugKlfW/0rXjOtnEFuw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Parent = require(script.Parent)

require(script.Parent.Types.Interface)

return {
	SmallestSufficient = function(n1: number) -- line: 18
		-- upvalues: Asserts (copy), Parent (copy)
		Asserts.number(n1)
		Asserts.cond(n1 > 0.0)

		local v5 = nil
		local v6 = nil

		for _, v8 in Parent.Directory do
			local SpeedPowerReward = v8.SpeedPowerReward

			if SpeedPowerReward ~= nil then
				if v5 == nil or SpeedPowerReward > v5.SpeedPowerReward then
					v5 = v8
				end

				if n1 <= SpeedPowerReward and (v6 == nil or SpeedPowerReward < v6.SpeedPowerReward) then
					v6 = v8
				end
			end
		end

		return v6 or assert(v5, "Products directory must contain at least one speed-power product")
	end
}

