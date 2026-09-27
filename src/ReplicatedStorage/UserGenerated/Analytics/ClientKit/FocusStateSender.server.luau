-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLCkZpcmVTZXJ2ZXIEZ2FtZRBVc2VySW5wdXRTZXJ2aWNlCkdldFNlcnZpY2UGc2NyaXB0BlBhcmVudApGb2N1c1N0YXRlDFdhaXRGb3JDaGlsZA1XaW5kb3dGb2N1c2VkB0Nvbm5lY3QTV2luZG93Rm9jdXNSZWxlYXNlZAADAwABAAAEAAEADwb7AAAAqQIBALwAAGsAAAAAnwADAYIAAQABAwEAGAABGAAAAAAAARkAAAAAAwABAAAEAAEADwb7AAAAqQIAALwAAGsAAAAAnwADAYIAAQABAwEAGwABGAAAAAAAARwAAAAABQAAAQMLAAACDwABHQ8BBxceowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQEBJAYAAABvAwcAvAEB0wgAAACfAQMCTQIAZAkAAADABAoAEgABALwCAscLAAAAnwIDAU0CACoMAAAAwAQNABIAAQC8AgLHCwAAAJ8CAwGCAAEADgMCBAAAAEADAwMEAwUEAABAQAMGAwcDCAMJBgADCgMLBgECAAEBAAEYABMAAAAAAAIAAAAAAAAAAgAAAAAAAAMAAAAAAAADAQAAAAACxO0PdVLPKf+XOGyRMq1RYrT1GAH2KWV0

-- decompilation:
--!native
local UserInputService = game:GetService("UserInputService")
local FocusState = script.Parent:WaitForChild("FocusState")

UserInputService.WindowFocused:Connect(function() -- line: 24
	-- upvalues: FocusState (copy)
	FocusState:FireServer(true)
end)
UserInputService.WindowFocusReleased:Connect(function() -- line: 27
	-- upvalues: FocusState (copy)
	FocusState:FireServer(false)
end)

