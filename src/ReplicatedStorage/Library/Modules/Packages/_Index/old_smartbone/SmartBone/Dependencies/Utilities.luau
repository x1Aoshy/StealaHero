-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBXBhaXJzC1NoYWxsb3dDb3B5BExlcnADRG90BUNyb3NzBkNGcmFtZQ1mcm9tQXhpc0FuZ2xlA25ldwFYAVkBWhJHZXRSb3RhdGlvbkJldHdlZW4Ed2FybiVDaGlsZCBhbmQgUm9vdCBhcmUgdGhlIHNhbWUgSW5zdGFuY2UhDUNoaWxkIGlzIG5pbCEGUGFyZW50EkdldEhpZXJhcmNoeUxlbmd0aAJvcwVjbG9jawR0YXNrBHdhaXQVRmluZEZpcnN0Q2hpbGRPZkNsYXNzE1dhaXRGb3JDaGlsZE9mQ2xhc3MABgcBAAAAAAv/AQAAAAAAAKQCAQAAAABAUgMAAJ8CAgQXAgEAagYBBW4C/v8CAAAAggECAAIDAQQAAABAAAMCARgAAAIAAAAAAf8ABAQAAAAABgMAAAAABCYFAQAJBAUCQwMABIIDAgAAAA0DARgAAAAADgAAAAAOAwAAAAgFAAAFAwgICCFSBwEAvAUAKwAAAACfBQMCUgMFAFIGAQC8BAC7AQAAAJ8EAwJvBQIAYAMHAAUAAACkBQUAABAwgFIGAgBvBwYAnwUDAIIFAACkBQgAABwwgIwGAACMBwAAjAgAAE0JBHkJAAAATQoEeAoAAABNCwR7CwAAAIwNAQBDDA0DnwUIAIIFAAAMAwQDBQIdd0oH6//vvwMGAwcEABAwgAIYLURU+yEJQAMIBAAcMIADCQMKAwsAEQwBGAAAAAAAAAAAAAIAAAEAAAAAAAMAAAAAAAAAAAAAAAAAABIAAAAABAIAAAAHBAAABQIHBxeaAAYAAQAAAKQCAQAAAABAbwMCAJ8CAgGCAAEARwAGAAAAAICkAgEAAAAAQG8DAwCfAgIBggABAFICAACMAwAAlQMDBE0CAiQFAAAA8QICAAEAAABIAPr/ggMCAAYDDQQAAABAAw4DDwIAAAAAAADwPwMQABsRARgAAAEAAAABAwABAAAAAQMBAwEAAQAAAhwAAAAABwMAAAAIBQAABQMHAwIYpAMCAAAEAICfAwECkAICA6QEBgAAFECAnwQBAVIGAQC8BAC4BwAAAJ8EAwIrBAcApAUCAAAEAICfBQECJgQFA7cCAgAEAAAASADx/1IGAQC8BAC4BwAAAJ8EAwCCBAAACAMSAxMEAAQAgAIAAAAAAAAkQAMUAxUEABRAgAMWADEXARgAAAABAgAAAQAAAAAAAAAAAAAAAQAAAAAyAAAAAAIAAAECABOjAAAA/wAEAAAAAADAAQAAMAEArAEAAADAAQIAMAEAXwMAAADAAQQAMAEA1wUAAADAAQYAMAEA5AcAAADAAQgAMAEAiQkAAACCAAIACgYAAwIGAQMDBgIDDAYDAxEGBAMXBQABAgMEAQABGAAAAAIAAAoAAAQAAAoAABYAAAkBAAAAAAUIO7WtuPB1ncNF/YqaAZfFeCOi2Tr/36w=

-- decompilation:
return {
	ShallowCopy = function(p1) -- line: 3
		local t1 = {}

		for k, v in pairs(p1) do
			t1[k] = v
		end

		return t1
	end,
	Lerp = function(p2, p3, p4) -- line: 13
		return p2 + (p3 - p2) * p4
	end,
	GetRotationBetween = function(vector3: Vector3, vector3_2: Vector3, vector3_3: Vector3) -- line: 17
		local v11 = vector3:Dot(vector3_2)
		local v12 = vector3:Cross(vector3_2)

		if v11 < -0.99999 then
			return CFrame.fromAxisAngle(vector3_3, 3.141592653589793)
		end

		return CFrame.new(0.0, 0.0, 0.0, v12.X, v12.Y, v12.Z, 1.0 + v11)
	end,
	GetHierarchyLength = function(p5, p6) -- line: 27
		if p5 == p6 then
			warn("Child and Root are the same Instance!")

			return
		end

		if p5 == nil then
			warn("Child is nil!")

			return
		end

		local n1 = 0.0

		repeat
			n1 += 1.0
			p5 = p5.Parent
		until p5 == p6

		return n1
	end,
	WaitForChildOfClass = function(p7, s1: string, n2: number) -- line: 49
		local elapsed = os.clock()
		local v20 = n2 or 10.0

		repeat
			task.wait()
		until p7:FindFirstChildOfClass(s1) or v20 < os.clock() - elapsed

		return p7:FindFirstChildOfClass(s1)
	end
}

