-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVClRleHRDb2xvcjMGQ29sb3IzA25ldwFyAWcBYgVUd2VlbglGbGFzaFRleHQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB0xpYnJhcnkMV2FpdEZvckNoaWxkBkNsaWVudAdyZXF1aXJlCFNldHRpbmdzCUZ1bmN0aW9ucwZzY3JpcHQGUGFyZW50DUNhY2hlUHJvcGVydHkNVUlFYXNpbmdTdHlsZQACCgIDAAAHBAAABQIHgjmQAgEA+wMAAFIEAABvBQEAnwMDAqQEBAAADCCAjAUBAIwGAQCMBwEAnwQEApoDEAAEAAAApAQEAAAMIIBNBgOTBgAAAD4FBgVNBwOGBwAAAD4GBwVNCAODCAAAAD4HCAWfBAQCMAQAcwEAAABlAA4ApAQEAAAMIIBNBgOTBgAAAFsFBgVNBwOGBwAAAFsGBwVNCAODCAAAAFsHCAWfBAQCMAQAcwEAAAD7BAEATQQE4AkAAABSBQAA4gYKADADBnMBAAAA/wcAAAIAAABSCAIA+wkCAMUHCAMBAAAAnwQEAYIAAQALAgAAAAAAAPA/AwEDAgMDBAAMIIACAAAAAAAAAEADBAMFAwYDBwUBAQAQCAEYAAEAAAACAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAwAAAAABAAEAAAAAAP4DEQAAAAAIAAABAgApowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAm8DBAC8AQDTBQAAAJ8BAwJvBAYAvAIB0wUAAACfAgMCpAMIAAAAcEBNBALKCQAAAJ8DAgKkBAgAAABwQE0FAVMKAAAAnwQCAqQFCAAAAHBApAYMAAAAsEBNBgYkDQAAAE0GBjwOAAAAnwUCAk0GA2YPAAAAwAcQABIABQASAAQAEgAGAIIHAgARAwkEAAAAQAMKAwsDDAMNAw4DDwQAAHBAAxADEQMSBAAAsEADEwMUAxUGAAEAAQABGAACAAAAAAACAAAAAQAAAAIAAAAAAQAAAAABAAAAAAAAAAAEAAIAAAAPAQAAAAAB0UwlamrJ1KuZkXTyaoEuyaFUMh7jiE9r

-- decompilation:
local Library = game:GetService("ReplicatedStorage"):WaitForChild("Library")
local Client = Library:WaitForChild("Client")
local Settings = require(Client.Settings)
local Functions = require(Library.Functions)
local CacheProperty = require(script.Parent.CacheProperty)
local UIEasingStyle = Settings.UIEasingStyle

local function FlashText(p1, n1: number?) -- line: 16
	-- upvalues: CacheProperty (copy), Functions (copy), UIEasingStyle (copy)
	local v10 = n1 or 1.0
	local v11 = CacheProperty(p1, "TextColor3")

	if v11 == Color3.new(1.0, 1.0, 1.0) then
		p1.TextColor3 = Color3.new(v11.r / 2.0, v11.g / 2.0, v11.b / 2.0)
	else
		p1.TextColor3 = Color3.new(v11.r * 2.0, v11.g * 2.0, v11.b * 2.0)
	end

	Functions.Tween(p1, {
		TextColor3 = v11
	}, {
		v10,
		UIEasingStyle
	})
end

return FlashText

