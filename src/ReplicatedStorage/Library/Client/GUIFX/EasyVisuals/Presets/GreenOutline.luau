-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUCEluc3RhbmNlBlBhcmVudApEaXNjb25uZWN0C1NldFJvdGF0aW9uBlN0cm9rZQNuZXcIR3JhZGllbnQJVGVtcGxhdGVzBUdyZWVuBUNvbG9yDFRyYW5zcGFyZW5jeQlIZWFydGJlYXQHQ29ubmVjdAdFZmZlY3RzC0Nvbm5lY3Rpb25zBGdhbWUKUnVuU2VydmljZQpHZXRTZXJ2aWNlB3JlcXVpcmUGc2NyaXB0AAMFAQUAAAAb+wEAAE0BAfQAAAAADgEHAPsBAABNAQH0AAAAAE0BASQBAAAARwEFAAAAAID7AQEAvAEBGgIAAACfAQIB+wICAPsEAwAJAwQAQwECA94BAgD7AQQA+wMCAIwEAQC8AQFRAwAAAJ8BBAGCAAEABAMBAwIDAwMEAA8AARgAAAAAAAAAAAAAAAEAAAACAAAAAAEAAAAAAAEQAAAAAAsDAgAACAUAAAUDBwICP/sDAABNAwOlAAAAAE0DA+8BAAAAUgQAAFIFAgCfAwMC+wQAAE0EBD0CAAAATQQE7wEAAABNBQP0AwAAAPsGAABNBgZLBAAAAE0GBpsFAAAATQYGpAYAAAD7BwAATQcHSwQAAABNBwebBQAAAE0HB9kHAAAAnwQEAowFBQDGBgAA+wcBAE0HB/0IAAAA2QkAABIAAwASAQb/EgEF/xIAAQASAAQAvAcHxwkAAACfBwMCUgYHAOIHDAD/CAAAAgAAAFIJBABSCgMAxQgJAwEAAAAwCAeXCgAAAP8IAAABAAAAUgkGAMUICQIBAAAAMAgH8QsAAADBBQAAggcCAA0DBQMGAwcDAQMIAwkDCgMLAwwDDQMOAw8FAgoLAQAFAAEYAAAAAAAAAAABAAAAAAEAAQAAAAAAAAEAAAAAAAD9BQIBAAAAAAAAAAAAAAAACAEAAAAAAAAAAQAAAAAAAAAABgAAAAADAAABAgAUowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAAnwECAsACCQASAAEAEgAAAIICAgAKAxAEAAAAQAMRAxIDEwQAAEBAAxQEAABgQAMCBgEBAQEAARgAAAAAAAAAAgAAAAAAAAAAAgAAAAEAAAAAAgLFRheNQOzYjC5ahpdaXFdy3VFjMAEsFg==

-- decompilation:
local RunService = game:GetService("RunService")
local Parent = require(script.Parent.Parent)

return function(p1, n1: number, n2: number) -- line: 5
	-- upvalues: Parent (copy), RunService (copy)
	local v6 = Parent.Stroke.new(p1, n2)
	local v7 = Parent.Gradient.new(v6.Instance, Parent.Templates.Green.Color, Parent.Templates.Green.Transparency)
	local n3 = 5.0
	local connection = nil

	connection = RunService.Heartbeat:Connect(function(dt) -- line: 15
		-- upvalues: v6 (copy), connection (ref), n3 (ref), n1 (copy), v7 (copy)
		if not v6.Instance or v6.Instance.Parent == nil then
			connection:Disconnect()
		end

		n3 += n1 * dt
		v7:SetRotation(n3, 1.0)
	end)

	return {
		Effects = {
			v7,
			v6
		},
		Connections = { connection }
	}
end

