-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSBnNjcmlwdAROYW1lDkZpbmRGaXJzdENoaWxkCEluc3RhbmNlA25ldwtPYmplY3RWYWx1ZQZQYXJlbnQFVmFsdWUJQm9vbFZhbHVlBGdhbWUKUnVuU2VydmljZQpHZXRTZXJ2aWNlCElzQ2xpZW50BkNsaWVudAZTZXJ2ZXIWYWRkVG9SZXBsaWNhdGVkU3RvcmFnZQlnZXRPYmplY3QRUmVwbGljYXRlZFN0b3JhZ2UAAwcAAQAAADf7AAAApAIBAAAAAEBNAgK6AgAAALwAAAMDAAAAnwADAg4AAgCpAQAAggECAKQBBgAAFECAbwIHAJ8BAgKkAgEAAAAAQE0CAroCAAAAMAIBugIAAACkAgEAAAAAQE0CAiQIAAAAMAIB7AkAAAD7AgAAMAIBJAgAAACkAgYAABRAgG8DCgCfAgICpAQMAAAAsEBvBg0AvAQEFg4AAACfBAMCvAQEBA8AAACfBAICDgQCAG8DEABlAAEAbwMRADADAroCAAAAqQMBADADAuwJAAAAMAECJAgAAACCAQIAEgMBBAAAAEADAgMDAwQDBQQAFECAAwYDBwMIAwkDCgQAALBAAwsDDAMNAw4DDwAJEAEYAAAAAAAAAAABAQACAAAAAQAAAAAAAQAAAAAAAQAAAQAAAAEAAAAAAAAAAAAAAAAAAAEAAAEAAQoAAAAAAwABAAAADPsAAACkAgEAAAAAQE0CAroCAAAAvAAAAwMAAACfAAMCDgABAIIAAgCpAQAAggECAAQDAQQAAABAAwIDAwAZEQEYAAAAAAAAAAABAQIAGgAAAAADAAABAgASowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAv8BAgAAAAAAwAIEABIAAAAwAgF7BQAAAMACBgASAAAAMAIBGQcAAACCAQIACAMKBAAAAEADEgMMBgADEAYBAxECAAEBAAEYAAUAAAAAAAEAAgAAABAAAAAIAQAAAAACnkZtRqqA7BRvgM3ernBZXe5eejKsggdH

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	addToReplicatedStorage = function() -- line: 9
		-- upvalues: ReplicatedStorage (copy)
		if ReplicatedStorage:FindFirstChild(script.Name) then
			return false
		end

		local ObjectValue = Instance.new("ObjectValue")

		ObjectValue.Name = script.Name
		ObjectValue.Value = script.Parent
		ObjectValue.Parent = ReplicatedStorage

		local BoolValue = Instance.new("BoolValue")

		BoolValue.Name = not game:GetService("RunService"):IsClient() and "Server" or "Client"
		BoolValue.Value = true
		BoolValue.Parent = ObjectValue

		return ObjectValue
	end,
	getObject = function() -- line: 25
		-- upvalues: ReplicatedStorage (copy)
		local scriptName = ReplicatedStorage:FindFirstChild(script.Name)

		if scriptName then
			return scriptName
		end

		return false
	end
}

