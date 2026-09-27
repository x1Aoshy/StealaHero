-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBkFzc2V0cwlQYXJ0aWNsZXMIU3BhcmtsZXMORmluZEZpcnN0Q2hpbGQFQ2xvbmUERW1pdAxFbWl0U3BhcmtsZXMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB0xpYnJhcnkMV2FpdEZvckNoaWxkB3JlcXVpcmUJRnVuY3Rpb25zAAIGAQIAAAAU+wEAAE0BAYEAAAAATQEBrgEAAABvAwIAvAEBAwMAAACfAQMCvAEBOgQAAACfAQIC+wIBAE0CAlYFAAAAUgMAAMYEAABSBQEAnwIEAYIAAQAGAwEDAgMDAwQDBQMGAAUHARgAAAAAAAAAAAAAAAABAAAAAAAAAQYAAAAABAAAAQIAFKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwJvAwQAvAEA0wUAAACfAQMCpAIHAAAAYEBNAwFTCAAAAJ8CAgLAAwkAEgAAABIAAgCCAwIACgMIBAAAAEADCQMKAwsDDAMNBAAAYEADDgYAAQABAAEYAAAAAAAAAAEAAAABAAAAAAIAAAUBAAAAAAEpzGCAhSLUQqWL17tzzLc/WdR39BsICoE=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local Functions = require(Library.Functions)

local function EmitSparkles(p1) -- line: 5
	-- upvalues: ReplicatedStorage (copy), Functions (copy)
	local clone = ReplicatedStorage.Assets.Particles:FindFirstChild("Sparkles"):Clone()

	Functions.Emit(p1, nil, clone)
end

return EmitSparkles

