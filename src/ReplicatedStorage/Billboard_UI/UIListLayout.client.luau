-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSC0dldENoaWxkcmVuFERpc2FibGVHYW1lcGFkQ3Vyc29yBUZyYW1lFkZpbmRGaXJzdENoaWxkV2hpY2hJc0ETRW5hYmxlR2FtZXBhZEN1cnNvcg11cGRhdGVHYW1lcGFkBGdhbWUOR2FtZXBhZFNlcnZpY2UKR2V0U2VydmljZRBVc2VySW5wdXRTZXJ2aWNlDkdhbWVwYWRFbmFibGVkD0tleWJvYXJkRW5hYmxlZAxNb3VzZUVuYWJsZWQGc2NyaXB0BlBhcmVudApDaGlsZEFkZGVkB0Nvbm5lY3QMQ2hpbGRSZW1vdmVkAAQFAAIAAAAX+wEAALwBAWgAAAAAnwECAhwAAQANAAYAAQAAgPsBAQC8AQEqAgAAAJ8BAgGCAAEA+wEAAG8DAwC8AQFUBAAAAJ8BAwL7AgEAUgQBALwCAj0FAAAAnwIDAYIAAQAGAwECAAAAAAAAAEADAgMDAwQDBQAMBgEYAAAAAAABAAEAAAAAAgAAAAABAAAAAAINAAAAAAUAAgAAABf7AQAAvAEBaAAAAACfAQICHAABAA0ABgABAACA+wEBALwBASoCAAAAnwECAYIAAQD7AQAAbwMDALwBAVQEAAAAnwEDAvsCAQBSBAEAvAICPQUAAACfAgMBggABAAYDAQIAAAAAAAAAQAMCAwMDBAMFABYAARgAAAAAAAEAAQAAAAACAAAAAAEAAAAABg0AAAAABQACAAAAF/sBAAC8AQFoAAAAAJ8BAgIcAAEADQAGAAEAAID7AQEAvAEBKgIAAACfAQIBggABAPsBAABvAwMAvAEBVAQAAACfAQMC+wIBAFIEAQC8AgI9BQAAAJ8CAwGCAAEABgMBAgAAAAAAAABAAwIDAwMEAwUAGgABGAAAAAAAAQABAAAAAAIAAAAAAQAAAAAKDQAAAAAIAAABAgAxowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqkCAABNAwGzBQAAAA4DBwBNAwEtBgAAACsDBABNAwFQBwAAACsDAQCpAgEADgIXAKQDCQAAAIBATQMDJAoAAADABAsAEgADABIAAABNBQNrDAAAAMAHDQASAAMAEgAAALwFBccOAAAAnwUDAU0FA70PAAAAwAcQABIAAwASAAAAvAUFxw4AAACfBQMBggABABEDBwQAAABAAwgDCQMKAwsDDAMNAw4EAACAQAMPBgADEAYBAxEDEgYCAwABAgEAARgAAAAAAAAAAQAAAAAAAQIAAAAAAAAAAAEDAQAAAAIAAAoAAAAAAAAABAAAAAAAAAADAQAAAAAD6XO/J3G3hBtnmD0myT+mO5lrqFPbt9Um

-- decompilation:
local GamepadService = game:GetService("GamepadService")
local UserInputService = game:GetService("UserInputService")
local v3 = false

if UserInputService.GamepadEnabled and (not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled) then
	v3 = true
end

if v3 then
	local scriptParent = script.Parent

	local function updateGamepad() -- line: 12
		-- upvalues: scriptParent (copy), GamepadService (copy)
		if #scriptParent:GetChildren() == 2.0 then
			GamepadService:DisableGamepadCursor()

			return
		end

		local Frame = scriptParent:FindFirstChildWhichIsA("Frame")

		GamepadService:EnableGamepadCursor(Frame)
	end

	scriptParent.ChildAdded:Connect(function() -- line: 22
		-- upvalues: scriptParent (copy), GamepadService (copy)
		if #scriptParent:GetChildren() == 2.0 then
			GamepadService:DisableGamepadCursor()

			return
		end

		local Frame = scriptParent:FindFirstChildWhichIsA("Frame")

		GamepadService:EnableGamepadCursor(Frame)
	end)
	scriptParent.ChildRemoved:Connect(function() -- line: 26
		-- upvalues: scriptParent (copy), GamepadService (copy)
		if #scriptParent:GetChildren() == 2.0 then
			GamepadService:DisableGamepadCursor()

			return
		end

		local Frame = scriptParent:FindFirstChildWhichIsA("Frame")

		GamepadService:EnableGamepadCursor(Frame)
	end)
end

