-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSEkdldEJhY2twYWNrRW5hYmxlZBJTZXRCYWNrcGFja0VuYWJsZWQHRW5hYmxlZApJc1VuTG9ja2VkCVNldExvY2tlZARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5BkNsaWVudANHVUkPSGlkZUltcG9ydGFudFVJBnNjcmlwdAZQYXJlbnQSQmFja3BhY2tDb250cm9sbGVyBE1haW4IQmFja3BhY2sAAgUBBQAABgMAAAUBASv7AQAAmgECAAAAAACCAAEA3gAAAA4ADwD7AQIAvAEBSwAAAACfAQIC3gEBAPsBAgCpAwAAvAEBRwEAAACfAQMB+wEDAKkCAAAwAgHwAgAAAIIAAQD7AQEAxgIAAN4CAQBHAQIAAAAAgIIAAQD7AgIAUgQBALwCAkcBAAAAnwIDAQ4BCQD7AgQAvAIClgMAAACfAgICDgIEAPsCAwCpAwEAMAMC8AIAAACCAAEABAMBAwIDAwMEACAFARgAAAABAwIBAAAAAAEAAAAAAQAAAAEDAQACAAEDAAAAAAIAAAAAAAEAAAACIQAAAAAJAAABAgA1owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgJNBwAAAE0CAjkIAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwNNBwAAAE0DAyYJAAAAnwICAqQDBQAAAEBApAQLAAAAoEBNBAQkDAAAAE0EBAUNAAAATQQEWg4AAACfAwICTQQBrw8AAACfBAECqQUAAMYGAAD/BwEAAAAAANkIAAASAQX/EgEG/xIAAwASAAQAEgACADAIBw4QAAAAwQUAAIIHAgARAwYEAAAAQAMHAwgDCQQAAEBAAwoDCwMMAw0DDgQAAKBAAw8DEAMRAxIDBQEAAQABGAADAAAAAAADAAAAAAAAAAABAAAAAAAAAAAMAAAAAAAAAAAAAAEAAAEBAwAGAAAAAAAAABwAAQAAAAABOVDJvYV84nCtwROtjwAK8UlI3skLlKO8

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUI = require(ReplicatedStorage.Library.Client.GUI)
local HideImportantUI = require(ReplicatedStorage.Library.Client.HideImportantUI)
local Main = require(script.Parent.BackpackController.Main)
local v5 = GUI.Backpack()
local u6 = false
local BackpackEnabled = nil

return {
	SetLocked = function(b1: boolean) -- line: 32
		-- upvalues: u6 (ref), BackpackEnabled (ref), Main (copy), v5 (copy), HideImportantUI (copy)
		if b1 == u6 then
			return
		end

		u6 = b1

		if b1 then
			BackpackEnabled = Main:GetBackpackEnabled()
			Main:SetBackpackEnabled(false)
			v5.Enabled = false

			return
		end

		local v9 = BackpackEnabled

		BackpackEnabled = nil

		if v9 == nil then
			return
		end

		Main:SetBackpackEnabled(v9)

		if v9 and HideImportantUI:IsUnLocked() then
			v5.Enabled = true
		end
	end
}

