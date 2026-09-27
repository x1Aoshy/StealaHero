-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMrBkJvdHRvbQdNZXNzYWdlIkNhbm5vdCB1c2UgaXRlbXMgaW4gdGhlIHNhZmUgem9uZSEFQ29sb3IEVGltZQZDb2xvcjMHZnJvbVJHQhRQcmV2ZW50RHVwbGljYXRlVGV4dBNzaG93U2FmZVpvbmVNZXNzYWdlCEdlYXJOYW1lDEdldEF0dHJpYnV0ZQZ0eXBlb2YGc3RyaW5nEmlzR2FtZXBsYXlHZWFyVG9vbAhPcHRpb25hbBBIdW1hbm9pZFJvb3RQYXJ0CEJhc2VQYXJ0A0lzQRBJc0luR2FtZXBsYXlTaWRlCFBvc2l0aW9uG0lzTG9jYWxQbGF5ZXJJbkdhbWVwbGF5QXJlYRBDYW5BY3RpdmF0ZUxvY2FsBGdhbWUHUGxheWVycwpHZXRTZXJ2aWNlEVJlcGxpY2F0ZWRTdG9yYWdlCVdvcmtzcGFjZQdyZXF1aXJlB0xpYnJhcnkEVXRpbBNHdWFyZEFyZWFMb29rdXBVdGlsBkNsaWVudBBOb3RpZmljYXRpb25DbWRzBlBsYXllcgtMb2NhbFBsYXllcglfX09CSkVDVFMGRm9sZGVyJFdvcmtzcGFjZS5fX09CSkVDVFMgbXVzdCBiZSBhIEZvbGRlcgZhc3NlcnQFQXJlYXMqV29ya3NwYWNlLl9fT0JKRUNUUy5BcmVhcyBtdXN0IGJlIGEgRm9sZGVyDlNlcGFyYXRpb25MaW5lO1dvcmtzcGFjZS5fX09CSkVDVFMuQXJlYXMuU2VwYXJhdGlvbkxpbmUgbXVzdCBiZSBhIEJhc2VQYXJ0AAUGAAEAAAAP+wAAAE0AABMAAAAA4gEGAKQCCQAAIHCAjAP/AIwERgCMBUYAnwIEAjACAaQDAAAA4gIMAJ8AAwGCAAEADQMBAwIDAwMEAwUCAAAAAAAAAEAIAwECAAAAA/////8EBQAAAAMGAwcEACBwgAMIAQEIAQoLAAAAACwJARgAAAAAAgAAAAAAAAAC/ActAAAAAAYBAAAABgMAAAUBhxFHAAMAAAAAgKkBAQCCAQIAbwUAALwDABIBAAAAnwMDAEwsAAKkAgMAAAAgQJ8CAALwAgIABAAAAKkBAAGpAQEAggECAAUDCgMLAwwEAAAgQAMNADYOARgAAAEAAwAAAAAAAAAAAAAAADcAAAAABAAEAAAAGPsAAABNAABxAAAAAE0AAGYBAAAA+wEBAJ8AAgJHAAYAAAAAAG8DAgC8AQD+AwAAAJ8BAwIrAQIAqQEAAIIBAgD7AQIATQEBZgQAAAD7AgMATQMAOwUAAACfAQMAggEAAAYDDwMQAxEDEgMTAxQAQhUBGAAAAAAAAAABAAAAAAAAAQADAAAAAAAAAEMAAAAABgECAAAGAwAABQGHHkcAAwAAAACAqQEBAGUADABvBQAAvAMAEgEAAACfAwMATCwAAqQCAwAAACBAnwIAAvACAgAEAAAAqQEAAakBAQArAQIAqQEBAIIBAgD7AQAATQEBXgUAAACfAQECDgECAKkBAQCCAQIA+wEBAJ8BAQGpAQAAggECAAYDCgMLAwwEAAAgQAMNAxUASxYBGAAAAQADAAAAAAAAAAAAAAAAEgADAAAAAAEAAwABADcAAAAADgAAAQIAZqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgEAAAAAQG8EBQC8AgIWAwAAAJ8CAwKkAwcAAABgQE0EAWoIAAAATQQEngkAAABNBAQMCgAAAJ8DAgKkBAcAAABgQE0FAWoIAAAATQUFTQsAAABNBQVsDAAAAE0FBfgNAAAAnwQCAqQFBwAAAGBATQYBaggAAABNBgb5DgAAAJ8FAgJNBgAxDwAAAE0HAsMQAAAAbwsRALwJB/4SAAAAnwkDAoEBCQQTAAAAbwoTAKQIFQAAAEBBnwgDAU0IBxQWAAAAbwwRALwKCP4SAAAAnwoDAoEBCgQXAAAAbwsXAKQJFQAAAEBBnwkDAU0JCLgYAAAAbw0ZALwLCf4SAAAAnwsDAoEBCwQaAAAAbwwaAKQKFQAAAEBBnwoDAf8KAgAAAAAAwAsbABIABADADBwAwA0dABIABQASAAYAEgADABIACQAwDQpeHgAAAMANHwASAAoAEgALADANCjwgAAAAggoCACEDFwQAAABAAxgDGQMaAxsDHAQAAGBAAx0DHgMfAyADIQMCAyIDIwMkAyUDEgMmAycEAABAQQMoAykDKgMRAysGAAYBBgIDFQYDAxYEAAECAwEAARgAAwAAAAAAAQAAAAAAAQAAAAAAAwAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAEQACAAEAAAAAAAAAAAABAAEAAAAAAAAAAAABAAEAAAAAAAAAAAADAAYACgwAAAAAAAAJAAAAAA0BAAAAAARlnXCx+iPZGlGj5RXUmGhYFYVnxVdZGrA=

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GuardAreaLookupUtil = require(ReplicatedStorage.Library.Util.GuardAreaLookupUtil)
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)
local Player = require(ReplicatedStorage.Library.Player)
local LocalPlayer = Players.LocalPlayer
local __OBJECTS = Workspace.__OBJECTS

assert(__OBJECTS:IsA("Folder"), "Workspace.__OBJECTS must be a Folder")

local Areas = __OBJECTS.Areas

assert(Areas:IsA("Folder"), "Workspace.__OBJECTS.Areas must be a Folder")

local SeparationLine = Areas.SeparationLine

assert(SeparationLine:IsA("BasePart"), "Workspace.__OBJECTS.Areas.SeparationLine must be a BasePart")

local t1 = {}

local function showSafeZoneMessage() -- line: 44
	-- upvalues: Message (copy)
	Message.Bottom({
		Message = "Cannot use items in the safe zone!",
		Time = 2.0,
		Color = Color3.fromRGB(255.0, 70.0, 70.0)
	}, {
		PreventDuplicateText = true
	})
end
local function isGameplayGearTool(p1) -- line: 54
	if p1 == nil then
		return true
	end

	return typeof(p1:GetAttribute("GearName")) == "string"
end

function t1.IsLocalPlayerInGameplayArea() -- line: 66
	-- upvalues: Player (copy), LocalPlayer (copy), GuardAreaLookupUtil (copy), SeparationLine (copy)
	local v15 = Player.Optional.HumanoidRootPart(LocalPlayer)

	if v15 == nil or not v15:IsA("BasePart") then
		return false
	end

	return GuardAreaLookupUtil.IsInGameplaySide(SeparationLine, v15.Position)
end
function t1.CanActivateLocal(p2) -- line: 75
	-- upvalues: t1 (copy), showSafeZoneMessage (copy)
	if p2 ~= nil and typeof(p2:GetAttribute("GearName")) ~= "string" then
		return true
	end

	if t1.IsLocalPlayerInGameplayArea() then
		return true
	end

	showSafeZoneMessage()

	return false
end

return t1

