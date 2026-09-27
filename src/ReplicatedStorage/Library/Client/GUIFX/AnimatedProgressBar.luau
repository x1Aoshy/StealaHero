-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaClRhcmdldEZpbGwMR2V0QXR0cmlidXRlBm51bWJlcgRTaXplAVgFU2NhbGUFVURpbTIDbmV3Bk9mZnNldAFZBG1hdGgDYWJzA2V4cApEaXNjb25uZWN0CUd1aU9iamVjdAhvcHRpb25hbBlHZXRBdHRyaWJ1dGVDaGFuZ2VkU2lnbmFsB0Nvbm5lY3QNUmVuZGVyU3RlcHBlZARnYW1lClJ1blNlcnZpY2UKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwAFBgAEAAAALPsAAQBvAgAAvAAAEgEAAACfAAMC3gAAAPsAAgBNAABgAgAAAPsBAACfAAIB+wAAAPsBAQBNAQEvAwAAAE0BAXkEAAAATQEBhAUAAABgABcAAQAAAPsAAQCkAQgAABxggPsCAAD7AwMATQMDeQQAAABNAwNwCQAAAPsEAwBNBAR4CgAAAE0EBIQFAAAA+wUDAE0FBXgKAAAATQUFcAkAAACfAQUCMAEALwMAAACCAAEACwMBAwIDAwMEAwUDBgMHAwgEABxggAMJAwoADQABGAAAAAAAAAEAAAAAAgAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAACDgAAAAAMAQQAAAAy+wEAAE0BAS8AAAAATQEBeQEAAABNAQGEAgAAAPsEAQAmAwEEuwIDAqQCBQAAEDCAnwICAm8DBgB9AyIAAgAAAPsCAACkAwkAACBwgPsHAQAmBgcB+wsCADkKCwAJCQoAuwsJAqQIDAAALDCAnwgCAvUHCggJBQYHQwQBBfsFAwBNBQV5AQAAAE0FBXANAAAA+wYDAE0GBngOAAAATQYGhAIAAAD7BwMATQcHeA4AAABNBwdwDQAAAJ8DBQIwAwIvAAAAAIIAAQAPAwQDBQMGAwsDDAQAEDCAAnsUrkfheoQ/AwcDCAQAIHCAAgAAAAAAAPA/Aw0EACwwgAMJAwoAFwABGAAAAAAAAAABAAAAAAAAAAABAAABAAAAAAAAAAAAAAABAAAAAAEAAAAAAQAAAAD8AAAHGAAAAAACAAEAAAAF+wAAALwAABoAAAAAnwACAYIAAQABAw4AIwABGAAAAAABJAAAAAAIAgIAAAcEAAAFAgeCK/sCAABNAgLjAAAAAFIDAACfAgIB+wIAAE0CAhEBAAAATQICYAIAAABSAwEAnwICAU0CAC8DAAAAjAMAAG8GBAC8BAAWBQAAAJ8EAwLZBgAAEgED/xIAAAASAgAAEgACALwEBMcGAAAAnwQDAZAEAQf7BQEATQUFzwgAAADZBwEAEgAAABIBA/8SAAQAEgACALwFBccGAAAAnwUDAtkGAgASAAUAwQMAAIIGAgAJAw8DEAMDAwQDAQMRAxICAAAAAAAAJEADEwMAAQIGAAEYAAAAAAABAAAAAAAAAgABAgAAAAAAAAAAAAAACQEAAAAAAAAAAAAADAAAAAcAAAAABAAAAQIAGKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAWoHAAAATQMDiQgAAACfAgICwAMJABIAAgASAAAAggMCAAoDFAQAAABAAxUDFgMXAxgEAABQQAMZAxoGAwEDAQABGAAAAAAAAAABAAAAAAACAAAAAAAAAgAAAAEAAAAABEjgyQZN0EXBALxtkTqxMV44+N5yeiSjBw==

-- decompilation:
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1, n1: number?) -- line: 6
	-- upvalues: Asserts (copy), RunService (copy)
	Asserts.GuiObject(p1)
	Asserts.optional.number(n1)

	local p1Size = p1.Size
	local n2 = 0.0

	p1:GetAttributeChangedSignal("TargetFill"):Connect(function() -- line: 13
		-- upvalues: n2 (ref), p1 (copy), Asserts (copy), p1Size (copy)
		n2 = p1:GetAttribute("TargetFill")
		Asserts.number(n2)

		if n2 < p1.Size.X.Scale then
			p1.Size = UDim2.new(n2, p1Size.X.Offset, p1Size.Y.Scale, p1Size.Y.Offset)
		end
	end)

	local v8 = n1 or 10.0
	local connection = RunService.RenderStepped:Connect(function(dt) -- line: 23
		-- upvalues: p1 (copy), n2 (ref), v8 (copy), p1Size (copy)
		local XScale = p1.Size.X.Scale

		if math.abs(XScale - n2) >= 0.01 then
			p1.Size = UDim2.new(XScale + (n2 - XScale) * (1.0 - math.exp(-v8 * dt)), p1Size.X.Offset, p1Size.Y.Scale, p1Size.Y.Offset)
		end
	end)

	return function() -- line: 35
		-- upvalues: connection (copy)
		connection:Disconnect()
	end
end

