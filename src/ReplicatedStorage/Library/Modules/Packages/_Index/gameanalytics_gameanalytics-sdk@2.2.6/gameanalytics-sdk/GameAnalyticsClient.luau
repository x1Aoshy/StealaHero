-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaC0dldEZ1bGxOYW1lBXBjYWxsEkdhbWVBbmFseXRpY3NFcnJvcgpGaXJlU2VydmVyEklzVGVuRm9vdEludGVyZmFjZQdDb25zb2xlDFRvdWNoRW5hYmxlZAxNb3VzZUVuYWJsZWQGTW9iaWxlB0Rlc2t0b3ALZ2V0UGxhdGZvcm0HcmVxdWlyZQZzY3JpcHQGUGFyZW50DUdhbWVBbmFseXRpY3MGUG9zdGllBUVycm9yB0Nvbm5lY3QLc2V0Q2FsbGJhY2sKaW5pdENsaWVudARnYW1lCkd1aVNlcnZpY2UKR2V0U2VydmljZRBVc2VySW5wdXRTZXJ2aWNlEVJlcGxpY2F0ZWRTdG9yYWdlDVNjcmlwdENvbnRleHQABQIAAgAAAAb7AAEAvAAAsgAAAACfAAIC3gAAAIIAAQABAwEAGAABGAAAAAAAARkAAAAACwMBAAAAFysCAQCCAAEAxgMAAKQEAQAAAABA2QUAABIBA/8SAAIAnwQCAysEAgDBAwAAggABAPsGAABNBgZaAgAAAFIIAABSCQEAUgoDALwGBmsDAAAAnwYFAcEDAACCAAEABAMCBAAAAEADAwMEAQASAAEYAAEDAQAAAAAAAwEAAwAAAAAAAAAAAQATAAAAAAIAAgAAABP7AAAAvAAAbAAAAACfAAICDgACAG8AAQCCAAIA+wABAE0AAH8CAAAADgAGAPsAAQBNAABQAwAAACsAAgBvAAQAggACAG8ABQCCAAIABgMFAwYDBwMIAwkDCgAjCwEYAAAAAAABAAEAAAAAAAAAAQACACQAAAAABQAEAAAAHKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BAR0FAAAATQEBdQYAAACfAAIC+wEAAE0BAd4HAAAAwAMIABICAQC8AQHHCQAAAJ8BAwHAAQoAEgICABICAwBNAgBfCwAAAG8DDABSBAEAnwIDAYIAAQANAwwEAAAAQAMNBAAAIEADDgMPAxADEQYBAxIGAgMTAwsCAQIPFAEYAAAAAAAAAAAAAAACAAAAAAAAABEAAAsAAAAAARAAAAAABwAAAQIAI6MAAAD/AAEAAAAAAKQBAQAAAABAbwMCALwBARYDAAAAnwEDAqQCAQAAAABAbwQEALwCAhYDAAAAnwIDAqQDAQAAAABAbwUFALwDAxYDAAAAnwMDAqQEAQAAAABAbwYGALwEBBYDAAAAnwQDAsAFBwASAAQAEgADABIAAQASAAIAMAUAKggAAACCAAIACQMVBAAAAEADFgMXAxgDGQMaBgMDFAEDAQABGAAAAAIAAAAAAAEAAAAAAAEAAAAAAAEAAAAAAAkAAAAAAAAiAQAAAAAESoB2ya2XZK/+RZ5LUwzuiDqYYb14RBzI

-- decompilation:
local t1 = {}
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")

function t1.initClient() -- line: 15
	-- upvalues: ScriptContext (copy), ReplicatedStorage (copy), GuiService (copy), UserInputService (copy)
	local Postie = require(script.Parent.GameAnalytics.Postie)

	ScriptContext.Error:Connect(function(p1, p2, p3) -- line: 18
		-- upvalues: ReplicatedStorage (copy)
		if not p3 then
			return
		end

		local FullName = nil
		local ok, _ = pcall(function() -- line: 24
			-- upvalues: FullName (ref), p3 (copy)
			FullName = p3:GetFullName()
		end)

		if not ok then
			return
		end

		ReplicatedStorage.GameAnalyticsError:FireServer(p1, p2, FullName)
	end)

	local function getPlatform() -- line: 35
		-- upvalues: GuiService (copy), UserInputService (copy)
		if GuiService:IsTenFootInterface() then
			return "Console"
		end

		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			return "Mobile"
		end

		return "Desktop"
	end

	Postie.setCallback("getPlatform", getPlatform)
end

return t1

