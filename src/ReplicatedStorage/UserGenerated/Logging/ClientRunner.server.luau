-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPCFNldExldmVsB3JlcXVpcmUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQ1Vc2VyR2VuZXJhdGVkCUZhc3RGbGFncwZzY3JpcHQGUGFyZW50ClJlcGxpY2F0ZWQhVXNlckdlbmVyYXRlZC5Mb2dnaW5nLkNsaWVudExldmVsC0Fzc2VydExldmVsBFdhcm4DR2V0B0NoYW5nZWQHQ29ubmVjdAACAwEBAAAABvsBAABNAQH2AAAAAFICAACfAQIBggABAAEDAQAYAAEYAAAAAAABGQAAAAAGAAABAgAoowAAAKQAAQAAAABApAEDAAAAIEBNAQE/BAAAAE0BAeAFAAAATQEB/wYAAACfAAICpAEBAAAAAECkAggAAABwQE0CAiQJAAAAnwECAk0CAK8KAAAAbwMLAE0EAf8MAAAAbwUNAJ8CBAJNAwH2DgAAALwEAn8PAAAAnwQCAJ8DAAFNAwKFEAAAAMAFEQASAAEAvAMDxxIAAACfAwMBggABABMDAgQAAABAAwMEAAAgQAMEAwUDBgMHBAAAcEADCAMJAwoDCwMMAwEDDQMOBgADDwEAAQABGAARAAAAAAAAAAAAAAEAAAAAAAADAAAAAAAAAQAAAAAAAQAAAAAAAAMBAAAAAAEKx3/mWNYKKEUnB1NPQ/ZEet9okjgDFec=

-- decompilation:
local FastFlags = require(game.ReplicatedStorage.UserGenerated.FastFlags)
local Parent = require(script.Parent)
local v3 = FastFlags.Replicated("UserGenerated.Logging.ClientLevel", Parent.AssertLevel, "Warn")

Parent.SetLevel(v3:Get())
v3.Changed:Connect(function(property) -- line: 24
	-- upvalues: Parent (copy)
	Parent.SetLevel(property)
end)

