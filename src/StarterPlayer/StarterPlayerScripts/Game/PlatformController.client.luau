-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMjDlByZWZlcnJlZElucHV0BEVudW0HR2FtZXBhZAdDb25zb2xlBVRvdWNoBk1vYmlsZQdEZXNrdG9wD3Jlc29sdmVQbGF0Zm9ybQhQbGF0Zm9ybQlWUkVuYWJsZWQCVlIERmlyZRBDaGFuZ2VkIFBsYXRmb3JtBkF0SW5mbyBQcmVmZXJyZWQgcGxhdGZvcm0gY2hhbmdlZCB0byAlKgZmb3JtYXQDTG9nD3B1Ymxpc2hQbGF0Zm9ybQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UQVXNlcklucHV0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwZTaWduYWwJVmFyaWFibGVzA25ldwdJbnZva2VkDVBsYXRmb3JtOiBHZXQIT25JbnZva2UYR2V0UHJvcGVydHlDaGFuZ2VkU2lnbmFsB0Nvbm5lY3QAAAQCAAEAAAAR+wAAAE0AAPAAAAAApAEDAAIAEMCaAAMAAQAAAG8BBACCAQIApAEGAAUAEMCaAAMAAQAAAG8BBwCCAQIAbwEIAIIBAgAJAwEDAgMDBAIAEMADBAMFBAUAEMADBgMHABMIARgAAAABAAAAAQACAAAAAQACABQAAAAABgAEAAAAR/sBAABNAQHwAAAAAKQCAwACABDAmgEDAAIAAABvAAQAZQAHAKQCBgAFABDAmgEDAAIAAABvAAcAZQABAG8ACAD7AQEATQEBkQkAAACaAQIAAAAAAIIAAQD7AQEAMAABkQkAAAD7AQEA8AACAAQAAACpAgABqQIBADACAYEEAAAA+wEBAPAAAgAHAAAAqQIAAakCAQAwAgFZBwAAAPsBAQDwAAIACAAAAKkCAAGpAgEAMAIBMQgAAAD7AQEA+wIAAE0CArEKAAAAMAIB6gsAAAD7AQIATQEB3QwAAABvAg0AUgMAAJ8BAwH7AQMAvAEBGw4AAACfAQICbwMPAFIFAAC8AwONEAAAAJ8DAwK8AQGhEQAAAJ8BAwGCAAEAEgMBAwIDAwQCABDAAwQDBQQFABDAAwYDBwMJAwoDCwMMAw0DDgMPAxADEQAeEgEYAAAAAQAAAAEAAgAAAAEAAgUAAAAAAQIAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAEAAAAAAAEAAAAAAAAAAAAAAAEUAAAAAAEAAQAAAAT7AAAATQAAkQAAAACCAAIAAQMJADAAARgAAAAAMQAAAAALAAABAgBGowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCBgAAAFBATQMAagcAAABNAwPoCAAAAE0DA+YJAAAATQMDoQoAAACfAgICpAMGAAAAUEBNBABqBwAAAE0EBB8LAAAAnwMCAqQEBgAAAFBATQUAagcAAABNBQVsDAAAAJ8EAgJNBQLvDQAAAJ8FAQLABg4AEgABAMAHDwASAAEAEgAEABIAAwASAAUATQgDDRAAAABvCREAnwgCAsAJEgASAAQAMAkI/BMAAABvChQAvAgBlBUAAACfCAMCUgoHALwICMcWAAAAnwgDAW8IFwAwCASRGAAAAFIIBwCfCAEBggABABkDEwQAAABAAxQDFQMWAxcEAABQQAMYAxkDGgMRAxsDHAMdBgAGAQMeAx8GAgMgAwEDIQMiAyMDCQMAAQIBAAEYAAMAAAAAAAEAAAAAAAMAAAAAAAAAAAAAAQAAAAAAAAEAAAAAAAADAAAGAAsAAAAAEgAAAAAAAAAEAAAAAAAAAAIAAAEAAQEAAAAAAyX1L6Dwc461vvpmxgQ/Kn1V7TjUFzFFoQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Log = require(ReplicatedStorage.Library.Modules.Packages.Log)
local Signal = require(ReplicatedStorage.Library.Signal)
local Variables = require(ReplicatedStorage.Library.Variables)
local v6 = Log.new()

local function resolvePlatform() -- line: 19
	-- upvalues: UserInputService (copy)
	local PreferredInput = UserInputService.PreferredInput

	if PreferredInput == Enum.PreferredInput.Gamepad then
		return "Console"
	end

	if PreferredInput == Enum.PreferredInput.Touch then
		return "Mobile"
	end

	return "Desktop"
end
local function publishPlatform() -- line: 30
	-- upvalues: UserInputService (copy), Variables (copy), Signal (copy), v6 (copy)
	local PreferredInput = UserInputService.PreferredInput
	local v11 = if PreferredInput ~= Enum.PreferredInput.Gamepad then PreferredInput ~= Enum.PreferredInput.Touch and "Desktop" or "Mobile" else "Console"

	if v11 == Variables.Platform then
		return
	end

	Variables.Platform = v11
	Variables.Console = v11 == "Console"
	Variables.Mobile = v11 == "Mobile"
	Variables.Desktop = v11 == "Desktop"
	Variables.VR = UserInputService.VREnabled
	Signal.Fire("Changed Platform", v11)
	v6:AtInfo():Log(`Preferred platform changed to { v11 }`)
end

Signal.Invoked("Platform: Get").OnInvoke = function() -- line: 48
	-- upvalues: Variables (copy)
	return Variables.Platform
end
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(publishPlatform)
Variables.Platform = ""
publishPlatform()

