-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRCUVtaXRDb3VudAxHZXRBdHRyaWJ1dGUMU2V0QXR0cmlidXRlBlNjYWxlcgRFbWl0C0dldENoaWxkcmVuDEVtaXRDb25mZXR0aQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHTGlicmFyeQxXYWl0Rm9yQ2hpbGQGQXNzZXRzCVBhcnRpY2xlcwdyZXF1aXJlCUZ1bmN0aW9ucwhDb25mZXR0aQADCQEDAAAAF/sBAAAOAQsAbwMAAG8IAAC8BgASAgAAAJ8GAwKQBQYB+wYAAAkEBQa8AQAuAwAAAJ8BBAH7AQEADgEHAPsBAgBNAQGnBAAAAJ8BAQJSAgAA+wMBAJ8BAwGCAAEABQMBAgAAAAAAAAAAAwIDAwMEAAkAARgAAAEAAAAAAAAAAAAAAgABAAAAAAAAAgoAAAAACAMCAAAADvsDAABNAwNWAAAAAFIEAADZBQAAEgABABIAAgASAgAA+wYBALwGBmgBAAAAnwYCAJ8DAACCAwAAAgMFAwYBAAgHARgAAAAAAAAAAAcAAAD5AAkAAAAACAAAAQIAJKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwJvAwQAvAEA0wUAAACfAQMCbwQGALwCANMFAAAAnwIDAm8FBwC8AwLTBQAAAJ8DAwKkBAkAAACAQE0FAVMKAAAAnwQCAm8HCwC8BQPTBQAAAJ8FAwLABgwAEgAEABIABQAYBgBlDQAAADUGAGUNAAAAggYCAA4DCAQAAABAAwkDCgMLAwwDDQMOAw8EAACAQAMQAxEGAQMHAQEBAAEYAAAAAAAAAAEAAAABAAAAAQAAAAEAAAAAAQAAAAIAAAAACwAAAQAAAAAC7befBiOnR/tKGhEXushLgZ2viHLfc/UH

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local Particles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Particles")
local Functions = require(Library.Functions)
local Confetti = Particles:WaitForChild("Confetti")

function EmitConfetti(p1, p2, p3) -- line: 8
	-- upvalues: Functions (copy), Confetti (copy)
	return Functions.Emit(p1, function(p4) -- line: 9
		-- upvalues: p2 (copy), p3 (copy), Functions (copy)
		if p2 then
			p4:SetAttribute("EmitCount", (p4:GetAttribute("EmitCount") or 0.0) * p2)
		end

		if p3 then
			Functions.Scaler()(p4, p3)
		end
	end, Confetti:GetChildren())
end

return EmitConfetti

