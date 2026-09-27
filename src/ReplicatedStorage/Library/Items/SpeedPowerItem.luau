-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMqBEZyb20NbmV3U3BlZWRQb3dlchRBYnN0cmFjdEdldE1heEFtb3VudAtTcGVlZCBQb3dlcgdHZXROYW1lBVNQRUVEB0dldERlc2MbcmJ4YXNzZXRpZDovLzk5NDU4NjUwNDQ2MjI4B0dldEljb24IUmFyaXRpZXMEUmFyZQlHZXRSYXJpdHkJRGlyZWN0b3J5BV9kYXRhBXZhbHVlBnR5cGVvZgZudW1iZXIIR2V0VmFsdWUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAxBYnN0cmFjdEl0ZW0GUmFyaXR5ClN0YWNrTGltaXQOTG9ja2luZ0VuYWJsZWQOVHJhZGluZ0VuYWJsZWQTQ3JlYXRpb25UaW1lRW5hYmxlZBNDcmVhdGlvblVzZXJFbmFibGVkEU93bmVyQ291bnRFbmFibGVkD093bmVyTG9nRW5hYmxlZA9OaWNrbmFtZUVuYWJsZWQPU2lnbmVkQnlFbmFibGVkB19faW5kZXgJUHJvdG90eXBlDHNldG1ldGF0YWJsZQZEZWZpbmUKU3BlZWRQb3dlcgVDbGFzcwZfX2NhbGwACQQBAgAAAAj7AQAATQEBuwAAAAD7AgEA/wMAAAAAAACfAQMAggEAAAEDAQAzAgEYAAAAAAAAAAA0AAAAAAIBAAAAAAJvAQAAggECAAECAAAAAAAA8H8ANwMBGAAAOAAAAAACAQAAAAACbwEAAIIBAgABAwQAOwUBGAAAPAAAAAACAQAAAAACbwEAAIIBAgABAwYAPwcBGAAAQAAAAAACAQAAAAACbwEAAIIBAgABAwgAQwkBGAAARAAAAAACAQEAAAAG+wEAAE0BAegAAAAATQEBpwEAAACCAQIAAgMKAwsARwwBGAAAAAAAAEgAAAAAAgEAAAAAA/8BAAAAAAAAggECAAAASw0BGAAAAEwAAAAABAEAAAAADk0BAIwAAAAATQEBzAEAAAC7LAEDUgMBAKQCAwAAACBAnwICAvACAwAEAAAAjAIAAIICAgCCAQIABQMOAw8DEAQAACBAAxEATxIBGAAAAAABAAAAAAAAAQADUAAAAAALAAABAgBWowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CArYJAAAAnwECAqQCBQAAAEBATQMAkQoAAABNAwPyCwAAAJ8CAgL/AwIAAAAAAOIFFwDiBhkATQcBdBoAAAAwBwZuGAAAAJ49BQMGAAAApAQcAAAAsEGfBAMCTQUBSx0AAABvBh4ApAcHAAAAYEBSCAMAnwUEAzAFBCUfAAAAMAUDJR8AAAAwBAN0GgAAAMAHIAASAAYAEgADAMAIIQAwCAQLIgAAAMAIIwAwCARWJAAAAMAIJQAwCAREJgAAAMAIJwAwCAReKAAAAMAIKQASAAIAMAgEJSoAAADACCsAMAgEkQoAAADACCwAMAgE8y0AAADiCi8AMAYKbhgAAAAwBwrvLgAAAJ49AwQKAAAAUgkDAKQIHAAAALBBnwgDAoIIAgAwAxMEAAAAQAMUAxUDFgQAAEBAAxcEAABgQAMYAxkDDQMaAxsCAAAAAAAA8D8DHAEAAx0DHgMfAyADIQMiAyMICQwNAAAADg8AAAAQDwAAABEPAAAAEg8AAAATDwAAABQPAAAAFQ8AAAAWDwAAAAMkBQEYAyUDJgQAALBBAycDKAMpBgAGAQMDBgIDBQYDAwcGBAMJBgUDDAYGBgcDEgMqBQIYLggAAQIDBAUGBwEAARgAAwAAAAAAAwAAAAAAAAAAAQAAAAAAAAYAAgoBAAAAAAD1AAAOAAAAAAAAAgABAAEAEQAABAAABAAABAAABAAABAAAAAQAAAQAAAkBAAEAAAAA/gAAAAEAAAAACF/YlJdc5YxPv+e2Q/narwgvwIPjbRz+lg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbstractItem = require(script.Parent.AbstractItem)
local Rarity = require(ReplicatedStorage.Directory.Rarity)
local t1 = {}
local v5 = setmetatable({
	StackLimit = 1.0,
	LockingEnabled = false,
	TradingEnabled = false,
	CreationTimeEnabled = false,
	CreationUserEnabled = false,
	OwnerCountEnabled = false,
	OwnerLogEnabled = false,
	NicknameEnabled = false,
	SignedByEnabled = false
}, {
	__index = AbstractItem.Prototype
})
local v6, v7 = AbstractItem.Define("SpeedPower", script, t1)

v5.Class = v6
t1.Class = v6
t1.Prototype = v5

local function newSpeedPower(_) -- line: 51
	-- upvalues: v7 (copy), t1 (copy)
	return v7.From(t1, {})
end

function v5.AbstractGetMaxAmount(_) -- line: 55
	return 1e999
end
function v5.GetName(_) -- line: 59
	return "Speed Power"
end
function v5.GetDesc(_) -- line: 63
	return "SPEED"
end
function v5.GetIcon(_) -- line: 67
	return "rbxassetid://99458650446228"
end
function v5.GetRarity(_) -- line: 71
	-- upvalues: Rarity (copy)
	return Rarity.Rarities.Rare
end
function v5.Directory(_) -- line: 75
	return {}
end
function v5.GetValue(p8) -- line: 79
	local value = p8._data.value

	if typeof(value) ~= "number" then
		return 0.0
	end

	return value
end

return (setmetatable(t1, {
	__index = v7,
	__call = newSpeedPower
}))

