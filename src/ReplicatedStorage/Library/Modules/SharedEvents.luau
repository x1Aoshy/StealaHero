-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiDnB1c2hQYXJ0Q0ZyYW1lBWRlYnVnDHByb2ZpbGViZWdpbhpTaGFyZWRFdmVudFV0aWxzOlN0ZXBQYXJ0cwl3b3Jrc3BhY2UERW51bQxCdWxrTW92ZU1vZGURRmlyZUNGcmFtZUNoYW5nZWQKQnVsa01vdmVUbwV0YWJsZQVjbGVhcgpwcm9maWxlZW5kCXN0ZXBQYXJ0cwRTdG9wB0Rlc3Ryb3kHY2xlYW51cAZSZW1vdmUNTG9hZEFuaW1hdGlvbgNBZGQNbG9hZEFuaW1hdGlvbgRnYW1lClJ1blNlcnZpY2UKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwVUcm92ZQhJc1NlcnZlcg5Qb3N0U2ltdWxhdGlvbgdDb25uZWN0CVByZVJlbmRlcgZDRnJhbWUBIgAGBAIDAAAHBAAABQIHQAv7AwAAlQIDAN4CAAD7AgEA+wMAAGoAAgP7AgIA+wMAAGoBAgPGAgAAggICAAECAAAAAAAA8D8ACgEBGAAAAAEAAAEAAAEACwAAAAAFAAMAAAAcpAACAAAEAIBvAQMAnwACAaQABQAAAEBA+wIAAPsDAQCkBAkACBxgwLwAAMMKAAAAnwAFAYwAAADeAAIApAANAAAwsID7AQAAnwACAaQADQAAMLCA+wEBAJ8AAgGkAA8AADgAgJ8AAQHGAAAAggACABADAgMDBAAEAIADBAMFBAAAQEADBgMHAwgECBxgwAMJAwoDCwQAMLCAAwwEADgAgAARDQEYAAAAAAEAAAAAAAAAAAEAAQAAAAEAAAABAAABABIAAAAAAwABAAAACvsAAACMAgAAvAAA+gAAAACfAAMB+wAAALwAAFABAAAAnwACAYIAAQACAw4DDwAdEAEYAAAAAAABAAAAAR4AAAAAAwACAAAABvsAAAD7AgEAvAAAaQAAAACfAAMBggABAAEDEQAiAAEYAAAAAAABIwAAAAAIAwAAAAgFAAAFAw8HBw9SBQIAvAMBlAAAAACfAwMC2QQAABIAAwBSBwQAvAUAXwEAAACfBQMBUgUDANkGAQASAAAAEgAEAIIFAwACAxIDEwICAxsUARgAAAAAAQAEAAAAAQAAAAAcAAAAAAwAAAECAD6jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAwFqBwAAAE0DA+gIAAAATQMD5gkAAABNAwObCgAAAJ8CAgKMAwAA/wQAAAAAAAD/BQAAAAAAANkGAAASAQP/EgAEABIABQDZBwEAEgAEABIABQASAQP/wAgLALwJAAsMAAAAnwkCAg4JBwBNCQC2DQAAAFILBwC8CQnHDgAAAJ8JAwFlAAYATQkAKQ8AAABSCwcAvAkJxw4AAACfCQMB4gkSADAGCYUQAAAAMAgJdBEAAADBAwAAggkCABMDFQQAAABAAxYDFwMYAxkEAABQQAMaAxsDHAMdBgQDHgMfAyADIQMBAxQFAhARAwABBAEAARgAAAAAAAAAAQAAAAAAAgAAAAAAAAAAAAACAQABAAIAAAAHAAAACgwAAAABAAAAAAAAAgAAAAAAAwEAAQADAAEAAAAABeP8UPoDpCwjZ1FwKYJqQhCT5EeO0Tg6+w==

-- decompilation:
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Modules.Packages.Trove)

local n1 = 0.0
local t1 = {}
local t2 = {}

local function stepParts() -- line: 17
	-- upvalues: t1 (copy), t2 (copy), n1 (ref)
	debug.profilebegin("SharedEventUtils:StepParts")
	workspace:BulkMoveTo(t1, t2, Enum.BulkMoveMode.FireCFrameChanged)
	n1 = 0.0
	table.clear(t1)
	table.clear(t2)
	debug.profileend()

	return nil
end

if RunService:IsServer() then
	RunService.PostSimulation:Connect(stepParts)
else
	RunService.PreRender:Connect(stepParts)
end

return {
	pushPartCFrame = function(p1, cFrame: CFrame) -- line: 10
		-- upvalues: n1 (ref), t1 (copy), t2 (copy)
		n1 += 1.0
		t1[n1] = p1
		t2[n1] = cFrame

		return nil
	end,
	loadAnimation = function(p2, p3, p4) -- line: 27
		local track = p3:LoadAnimation(p4)

		local function cleanup() -- line: 29
			-- upvalues: track (copy)
			track:Stop(0.0)
			track:Destroy()
		end

		p2:Add(cleanup)

		return track, function() -- line: 34
			-- upvalues: p2 (copy), cleanup (copy)
			p2:Remove(cleanup)
		end
	end
}

