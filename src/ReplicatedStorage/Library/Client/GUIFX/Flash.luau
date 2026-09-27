-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMeCEluc3RhbmNlA25ldwVGcmFtZRZCYWNrZ3JvdW5kVHJhbnNwYXJlbmN5EEJhY2tncm91bmRDb2xvcjMFVURpbTIEU2l6ZQdWZWN0b3IyC0FuY2hvclBvaW50CFBvc2l0aW9uD0JvcmRlclNpemVQaXhlbAZQYXJlbnQFVHdlZW4ERXhwbwNPdXQEd2FpdARTaW5lB0Rlc3Ryb3kGQ29sb3IzBHRhc2sFc3Bhd24EZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQxXYWl0Rm9yQ2hpbGQJRnVuY3Rpb25zBnNjcmlwdAlHZXRIb2xkZXIAAwgABgAAAGOkAAIAAAQAgG8BAwCfAAICjAEBADABADoEAAAA+wEAADABAJ8FAAAApAEHAAAEYICMAgIAjAMAAIwEAgCMBQAAnwEFAjABAC8IAAAApAEKAAAEkIBvAgsAbwMLAJ8BAwIwAQDoDAAAAKQBBwAABGCAbwILAIwDAABvBAsAjAUAAJ8BBQIwAQA7DQAAAIwBAAAwAQCODgAAAPsBAQCfAQECMAEAJA8AAAD7AQIAjAIAAGACFgABAAAA+wEDAE0BAeAQAAAAUgIAAOIDEQD7BAQAMAQDOgQAAAD/BAAAAwAAAPsFAgBvBhIAbwcTAMUEBQQBAAAAnwEEAaQBFQAAAEBB+wICAJ8BAgFlAAMA+wEEADABADoEAAAA+wEFAIwCAABgAhMAAQAAAPsBAwBNAQHgEAAAAFICAADiAxcA/wQAAAMAAAD7BQUAbwYYAG8HEwDFBAUEAQAAAJ8BBAGkARUAAABAQfsCBQCfAQIBZQADAIwBAQAwAQA6BAAAALwBAFAZAAAAnwECAYIAAQAaAwEDAgQABACAAwMDBAMFAwYEAARggAMHAwgEAASQgAIAAAAAAADgPwMJAwoDCwMMAw0FAQQDDgMPAxAEAABAQQIAAAAAAADwPwgBBBYAAAADEQMSAAwAARgAAAAAAQAAAQAAAQAAAAAAAAAAAQAAAAAAAAEAAAAAAAAAAAEAAAEAAAACAAAAAQAAAAABAAABAAAAAAAA/gMAAAAAAgAAAwAAAAEAAAAAAgAAAAAAAP4DAAAAAAIAAAMAAAENAAAAAAoEAgAAABaQBAAAkAUBAFIGAgArBgYApAYDAAAIEICMBwEAjAgBAIwJAQCfBgQCkAcDBKQIBwAAGFCA2QkAABIABgASAgAAEgAEABICAQASAAcAEgAFAJ8IAgGCAAEACAIAAAAAAADwPwMTAwIEAAgQgAIAAAAAAAAAAAMUAxUEABhQgAEABgABGAABAQAAAAAAAAABAgAAAAAAAAAAAB4HAAAAAAUAAAECAB2jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBvBAYAvAIA0wcAAACfAgMCTQICUwgAAACfAQICpAIFAAAAQECkAwoAAACQQE0DAyQLAAAATQMDdwwAAACfAgICwAMNABIAAgASAAEAggMCAA4DFgQAAABAAxcDGAMZBAAAQEADGgMbAxwDHQQAAJBAAwwDHgYBAQEBAAEYAAAAAAAAAAIAAAAAAAAAAAEAAAAAAAAAAAIAAAABAAAAAAKMlmys9zi5j5lTk9vOJYRc/I572L5SBq0=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Functions = require(ReplicatedStorage:WaitForChild("Library").Functions)
local GetHolder = require(script.Parent.GetHolder)

return function(p1, p2, p3, p4) -- line: 6
	-- upvalues: GetHolder (copy), Functions (copy)
	local v8 = p1 or 1.0
	local v9 = p2 or 1.0
	local v10 = p3 or Color3.new(1.0, 1.0, 1.0)
	local v11 = p4 or 0.0

	task.spawn(function() -- line: 12
		-- upvalues: v10 (copy), GetHolder (copy), v8 (copy), Functions (copy), v11 (copy), v9 (copy)
		local Frame = Instance.new("Frame")

		Frame.BackgroundTransparency = 1.0
		Frame.BackgroundColor3 = v10
		Frame.Size = UDim2.new(2.0, 0.0, 2.0, 0.0)
		Frame.AnchorPoint = Vector2.new(0.5, 0.5)
		Frame.Position = UDim2.new(0.5, 0.0, 0.5, 0.0)
		Frame.BorderSizePixel = 0.0
		Frame.Parent = GetHolder()

		if v8 > 0.0 then
			Functions.Tween(Frame, {
				BackgroundTransparency = v11
			}, {
				v8,
				"Expo",
				"Out"
			})
			wait(v8)
		else
			Frame.BackgroundTransparency = v11
		end

		if v9 > 0.0 then
			Functions.Tween(Frame, {
				BackgroundTransparency = 1.0
			}, {
				v9,
				"Sine",
				"Out"
			})
			wait(v9)
		else
			Frame.BackgroundTransparency = 1.0
		end

		Frame:Destroy()
	end)
end

