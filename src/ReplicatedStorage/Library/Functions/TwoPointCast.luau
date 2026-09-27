-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMICU1hZ25pdHVkZQZDRnJhbWUGbG9va0F0Ckxvb2tWZWN0b3IHUmF5Y2FzdARnYW1lCVdvcmtzcGFjZQpHZXRTZXJ2aWNlAAIKAwEAAAATJgMAAU0DA6oAAAAApAUDAAAIEIBSBgAAUgcBAJ8FAwJNBQVoBAAAAAkEBQP7BQAAUgcAAFIIBABSCQIAvAUFwgUAAACfBQUAggUAAAYDAQMCAwMEAAgQgAMEAwUAAwABGAAAAAEAAAAAAAAAAQAAAAAAAAAEAAAAAAMAAAECAAqjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCwAEEABIAAACCAQIABQMGBAAAAEADBwMIBgABAAEAARgAAAAAAAAAAgAAAQAAAAABRAyFf4QSaUKPeT9Nmzb7SjQUkgt2yO9+

-- decompilation:
local Workspace = game:GetService("Workspace")

return function(p1, p2, p3) -- line: 3
	-- upvalues: Workspace (copy)
	local Magnitude = (p1 - p2).Magnitude
	local v6 = CFrame.lookAt(p1, p2).LookVector * Magnitude

	return Workspace:Raycast(p1, v6, p3)
end

