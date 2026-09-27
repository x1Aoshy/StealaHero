-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBnNlcnZlcghJbnN0YW5jZQNuZXcGRm9sZGVyDkJ5dGVuZXRTdG9yYWdlBE5hbWUGUGFyZW50BmNsaWVudAxXYWl0Rm9yQ2hpbGQFc3RhcnQORmluZEZpcnN0Q2hpbGQLU3RyaW5nVmFsdWUDSXNBBmFjY2VzcwRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UKUnVuU2VydmljZQdyZXF1aXJlBnNjcmlwdA9yZXBsaWNhdGVkVmFsdWUISXNTZXJ2ZXIAAwMAAwAAABn7AAAA8AANAAAAAICkAAMAAAgQgG8BBACfAAICbwEFADABALoGAAAA+wEBADABACQHAAAA3gACAIIAAQD7AAAA8AAHAAgAAID7AAEAbwIFALwAANMJAAAAnwADAt4AAgCCAAEACgMBAwIDAwQACBCAAwQDBQMGAwcDCAMJAA4KARgAAAABAAAAAQAAAQAAAgABAAABAAAAAAACDwAAAAAFAQQAAAYDAAAFAQMw+wIAAIcBAgAOAQMA+wIAAIcBAgCCAQIA+wEBAPABEwAAAACA+wECAFIDAAC8AQEDAQAAAJ8BAwIOAR4AbwQCALwCAf4DAAAAnwIDAg4CGQD7AgMAUgMBAJ8CAgL7AwAAagIDAIICAgBlABIA+wEBAPABEAAEAACApAEHAAAYUIBvAgIAnwECAjAAAboIAAAA+wICADACASQJAAAA+wIDAFIDAQCfAgIC+wMAAGoCAwCCAgIA+wIAAIcBAgCCAQIACgMIAwsDDAMNAwEDAgMDBAAYUIADBgMHABoOARgAAAABAAADAAABAAAAAAEAAAAAAAIAAAIAAgACAAACAAAAAQABAAACAAACAAIDAAAcAAAAAAgAAAECADGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUECkAwgAAABwQE0DAyQJAAAATQMDYQoAAACfAgICvAQBCwsAAACfBAICDgQCAG8DDABlAAEAbwMNAMYEAAD/BQAAAAAAAP8GAgAAAAAA2QcAABIAAwASAAAAEgEE/zAHBvwOAAAA2QcBABIABQASAAMAEgEE/xIAAgAwBwYiDwAAAMEEAACCBgIAEAMPBAAAAEADEAMRAxIDEwQAAFBAAxQEAABwQAMHAxUDFgMBAwgDCgMOAgABAQABGAAAAAAAAAABAAAAAAACAAAAAAAAAAACAAAAAAAAAQMAAgACAAAAAAAMAAAAAAAAIAABAAAAAAItdAEb6SpaI76nJm38SNH4XWwWbx+waxo=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local replicatedValue = require(script.Parent.replicatedValue)
local v4 = not RunService:IsServer() and "client" or "server"
local u5 = nil
local t1 = {}

return {
	start = function() -- line: 14
		-- upvalues: v4 (copy), ReplicatedStorage (copy), u5 (ref)
		if v4 == "server" then
			local Folder = Instance.new("Folder")

			Folder.Name = "BytenetStorage"
			Folder.Parent = ReplicatedStorage
			u5 = Folder

			return
		end

		if v4 == "client" then
			u5 = ReplicatedStorage:WaitForChild("BytenetStorage")
		end
	end,
	access = function(s1: string) -- line: 26
		-- upvalues: t1 (copy), v4 (copy), u5 (ref), replicatedValue (copy)
		if t1[s1] then
			return t1[s1]
		end

		if v4 == "client" then
			local s1_2 = u5:FindFirstChild(s1)

			if s1_2 and s1_2:IsA("StringValue") then
				local v10 = replicatedValue(s1_2)

				t1[s1] = v10

				return v10
			end
		elseif v4 == "server" then
			local StringValue = Instance.new("StringValue")

			StringValue.Name = s1
			StringValue.Parent = u5

			local v12 = replicatedValue(StringValue)

			t1[s1] = v12

			return v12
		end

		return t1[s1]
	end
}

