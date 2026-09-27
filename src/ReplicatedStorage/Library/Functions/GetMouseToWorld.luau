-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQCXdvcmtzcGFjZQ1DdXJyZW50Q2FtZXJhEEdldE1vdXNlTG9jYXRpb24LR2V0R3VpSW5zZXQBWAFZEFNjcmVlblBvaW50VG9SYXkGT3JpZ2luCURpcmVjdGlvbgdSYXljYXN0BGdhbWUQVXNlcklucHV0U2VydmljZQpHZXRTZXJ2aWNlCkd1aVNlcnZpY2UYR2V0UHJvcGVydHlDaGFuZ2VkU2lnbmFsB0Nvbm5lY3QAAwEAAQAAAAakAAEAAAAAQE0AAEgCAAAA3gAAAIIAAQADAwEEAAAAQAMCAAQAARgAAAAAAAEFAAAAAAsCAwAAACP7AgAAvAICBgAAAACfAgIC+wMBALwDA1cBAAAAnwMCAvsEAgBNBwJ5AgAAAE0IA3kCAAAAQwYHCE0IAngDAAAATQkDeAMAAAAmBwgJvAQEQwQAAACfBAQCpAUGAAAAUEBNBwRDBwAAAE0JBGEIAAAAkAoBCQkICQpSCQAAvAUFwgoAAACfBQUAggUAAAsDAwMEAwUDBgMHAwEEAABQQAMIAwkCAAAAAABAj0ADCgAIAAEYAAAAAAEAAAABAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAJAAAAAAYAAAECACKjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAgJIBwAAAKQDBgAAAFBAbwUHALwDA5QIAAAAnwMDAtkFAAASAQL/vAMDxwkAAACfAwMB2QMBABIAAAASAAEAEgEC/8ECAACCAwIACgMLBAAAAEADDAMNAw4DAQQAAFBAAwIDDwMQAgABAQABGAAAAAAAAAABAAAAAAABAAAAAQAAAAAAAAAAAAAEAAAAAAABAAAAAAJNZYNUF+fjZwNIIpN95JvsPX2UIH+h6VU=

-- decompilation:
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CurrentCamera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() -- line: 4
	-- upvalues: CurrentCamera (ref)
	CurrentCamera = workspace.CurrentCamera
end)

return function(p1, p2) -- line: 8
	-- upvalues: UserInputService (copy), GuiService (copy), CurrentCamera (ref)
	local MouseLocation = UserInputService:GetMouseLocation()
	local GuiInset = GuiService:GetGuiInset()
	local v8 = CurrentCamera:ScreenPointToRay(MouseLocation.X + GuiInset.X, MouseLocation.Y - GuiInset.Y)

	return workspace:Raycast(v8.Origin, v8.Direction * (p2 or 1000.0), p1)
end

