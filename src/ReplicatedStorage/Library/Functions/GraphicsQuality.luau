-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBG1hdGgFcm91bmQFY2xhbXAPZXN0aW1hdGVRdWFsaXR5ClBvdGF0b01vZGUMVXNlclNldHRpbmdzDEdhbWVTZXR0aW5ncxFTYXZlZFF1YWxpdHlMZXZlbAVWYWx1ZQRnYW1lEFVzZXJJbnB1dFNlcnZpY2UKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdyZXF1aXJlB0xpYnJhcnkJRnVuY3Rpb25zEkVzdGltYXRlQ2xvY2tTcGVlZANNYXAJVmFyaWFibGVzDFRvdWNoRW5hYmxlZAxNb3VzZUVuYWJsZWQQR3lyb3Njb3BlRW5hYmxlZBRBY2NlbGVyb21ldGVyRW5hYmxlZAADCQACAAAAF/sAAACfAAECKwACAMYBAACCAQIA+wMBAFIEAACMBQIAjAYFAIwHAQCMCAoAnwMGArswAwKkAgIAAAQAgJ8CAgKMAwEAjAQKAEwuAAKkAQQAAAwAgJ8BBAKCAQIABQMBAwIEAAQAgAMDBAAMAIAACgQBGAAAAQEAAgAAAAAAAAAAAAAAAAAAAAAACwAAAAALAAUAAABC+wAAAE0AABgAAAAADgACAIwAAQCCAAIApAACAAAAEECfAAECTQAArgMAAABNAAAGBAAAAE0AAOwFAAAADQAdAAYAAID7AQEAKwEYAPsCAgCfAgECKwICAMYBAABlABIA+wUDAFIGAgCMBwIAjAgFAIwJAQCMCgoAnwUGArswBQKkBAkAACBwgJ8EAgKMBQEAjAYKAEwuAAKkAwsAAChwgJ8DBAJSAQMA3gEBAPsBAQCQAAEM+wEEAA4BEgD7AwMAUgQAAIwFAQCMBgoAjAcBAIwIBQCfAwYCuzADAqQCCQAAIHCAnwICAowDAQCMBAoATC4AAqQBCwAAKHCAnwEEAlIAAQCCAAIADQMFAwYEAAAQQAMHAwgDCQIAAAAAAAAAAAMBAwIEACBwgAMDBAAocIACAAAAAAAAFEAAFAABGAoAAAABAAIAAAAAAAAAAAEAAQDxAAEBAAIAAAAAAAAAAAAAAAAAAAAAAAwCAAIAAQAAAAAAAAAAAAAAAAAAAAAAAgsAAAAACQAAAQIAPqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAWoHAAAATQMDUwgAAABNAwMkCQAAAJ8CAgKkAwYAAABQQE0EAWoHAAAATQQEUwgAAABNBASwCgAAAJ8DAgKkBAYAAABQQE0FAWoHAAAATQUFbAsAAACfBAICTQYAfwwAAAAOBgQATQYAUA0AAABWBQYAKwUFAE0FAHIOAAAAKwUCAE0FAB8PAAAAwAYQABIAAgASAAMAxgcAANkIAQASAAQAEgEH/xIAAgASAAMAEgAFAMEHAACCCAIAEQMKBAAAAEADCwMMAw0DDgQAAFBAAw8DEAMRAxIDEwMUAxUDFgMXBgACAAEBAAEYAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAQACAAAIAgAAAAAAAAABAAAAAAIavkRQ9ctRTGI/fLuF7oMvaqZTJCh6LlE=

-- decompilation:
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EstimateClockSpeed = require(ReplicatedStorage.Library.Functions.EstimateClockSpeed)
local Map = require(ReplicatedStorage.Library.Functions.Map)
local Variables = require(ReplicatedStorage.Library.Variables)
local v6 = UserInputService.TouchEnabled and not UserInputService.MouseEnabled or (UserInputService.GyroscopeEnabled or UserInputService.AccelerometerEnabled)

local function estimateQuality() -- line: 10
	-- upvalues: EstimateClockSpeed (copy), Map (copy)
	local v9 = EstimateClockSpeed()

	if not v9 then
		return nil
	end

	return (math.clamp(math.round((Map(v9, 2.0, 5.0, 1.0, 10.0))), 1.0, 10.0))
end

local u8 = nil

return function() -- line: 20
	-- upvalues: Variables (copy), u8 (ref), EstimateClockSpeed (copy), Map (copy), v6 (copy)
	if Variables.PotatoMode then
		return 1.0
	end

	local SavedQualityLevelValue = UserSettings().GameSettings.SavedQualityLevel.Value

	if SavedQualityLevelValue == 0.0 then
		if not u8 then
			local v11 = EstimateClockSpeed()

			u8 = if v11 then math.clamp(math.round((Map(v11, 2.0, 5.0, 1.0, 10.0))), 1.0, 10.0) else nil
		end

		SavedQualityLevelValue = u8 or 5.0
	end

	if v6 then
		SavedQualityLevelValue = math.clamp(math.round((Map(SavedQualityLevelValue, 1.0, 10.0, 1.0, 5.0))), 1.0, 10.0)
	end

	return SavedQualityLevelValue
end

