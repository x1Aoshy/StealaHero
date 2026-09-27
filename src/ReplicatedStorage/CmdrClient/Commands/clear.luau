-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMYC0xvY2FsUGxheWVyCVBsYXllckd1aQxXYWl0Rm9yQ2hpbGQEQ21kcgVGcmFtZQVwYWlycwtHZXRDaGlsZHJlbgROYW1lBExpbmUHVGV4dEJveANJc0EHRGVzdHJveQAJQ2xpZW50UnVuBGdhbWUHUGxheWVycwpHZXRTZXJ2aWNlBWNsZWFyB0FsaWFzZXMLRGVzY3JpcHRpb244Q2xlYXIgYWxsIGxpbmVzIGFib3ZlIHRoZSBlbnRyeSBsaW5lIG9mIHRoZSBDbWRyIHdpbmRvdy4FR3JvdXALRGVmYXVsdFV0aWwEQXJncwACCwABAAAAKPsAAABNAAAxAAAAAG8DAQC8AQDTAgAAAJ8BAwJvAwMAvAEB0wIAAACfAQMCbwQEALwCAdMCAAAAnwIDAg4BFgAOAhUApAMGAAAAUEC8BAJoBwAAAJ8EAgCfAwAEFwMMAE0IB7oIAAAA8AgJAAkAAIBvCgoAvAgH/gsAAACfCAMCDggDALwIB1AMAAAAnwgCAW4D8/8CAAAAbwMNAIIDAgAOAwEDAgMDAwQDBQMGBAAAUEADBwMIAwkDCgMLAwwDDQAJDgEYAAAAAQAAAAAAAAABAAAAAgABAAAAAAAAAQAAAAAAAAAAAQAA/gAGAAoAAAAAAwAAAQIAFaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLiAQ0A/wIAAAAAAAAwAgEnBgAAAP8CAAAAAAAAMAIB2wsAAADAAg4AEgAAADACATMMAAAAggECAA8DDwQAAABAAxADEQMIAxIDEwMUAxUDFgMXAxgDDggGBAUAAAAG/////wcIAAAACQoAAAAL/////wz/////BgABAAEAARgAAAAAAAAAAgIAAAADAAAAAQAAAAABAAAAAAHBuQFpRSb9UX4+mxVxIS1/saEWHfN9a2g=

-- decompilation:
local Players = game:GetService("Players")

return {
	Name = "clear",
	Description = "Clear all lines above the entry line of the Cmdr window.",
	Group = "DefaultUtil",
	Aliases = {},
	Args = {},
	ClientRun = function() -- line: 9
		-- upvalues: Players (copy)
		local Cmdr = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Cmdr")
		local Frame = Cmdr:WaitForChild("Frame")

		if Cmdr and Frame then
			for _, child in pairs(Frame:GetChildren()) do
				if child.Name == "Line" and child:IsA("TextBox") then
					child:Destroy()
				end
			end
		end

		return ""
	end
}

