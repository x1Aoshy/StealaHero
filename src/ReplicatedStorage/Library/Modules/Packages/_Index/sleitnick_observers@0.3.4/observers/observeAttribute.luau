-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLDGRlZmF1bHRHdWFyZAlDb25uZWN0ZWQEdGFzawVzcGF3bgxHZXRBdHRyaWJ1dGUST25BdHRyaWJ1dGVDaGFuZ2VkCkRpc2Nvbm5lY3QZR2V0QXR0cmlidXRlQ2hhbmdlZFNpZ25hbAdDb25uZWN0BWRlZmVyEG9ic2VydmVBdHRyaWJ1dGUABwIBAAAAAAKpAQEAggECAAAAFAEBGAAAFQAAAAADAAYAAAAS+wAAAPsBAQCfAAIC+wECAPsCAwCaAQcAAgAAAPsBBABNAQHRAAAAAA4BAgDeAAUAggABAKQBAwAACBCAUgIAAJ8BAgGCAAEABAMCAwMDBAQACBCAAFYAARgAAAABAAAAAAAAAAEAAgAAAAJXAAAAAAQABwAAACP7AAAARwAHAAAAAACkAAIAAAQAgPsBAACfAAIBxgAAAN4AAAD7AAEAlQAAA94AAQD7AAEA+wECAPsDAwC8AQESBAAAAJ8BAwJHAQ8AAAAAAPsCBABSAwEAnwICAg4CCgCkAgIAAAQAgNkDAAASAgUAEgABABIAAAASAgEAEgIGABICAACfAgIBggABAAUDAwMEBAAEAIACAAAAAAAA8D8DBQEBSgYBGAAAAAEAAAABAAMAAAECAAAAAAIAAAAAAAEAAAAAAAAAAAAJSwAAAAABAAIAAAAI+wAAAE0AANEAAAAAKwABAIIAAQD7AAEAnwABAYIAAQABAwIAZQABGAAAAAABAwABZgAAAAACAAIAAAAO+wAAALwAABoAAAAAnwACAfsAAQBHAAcAAAAAAKQAAwAACBCA+wEBAJ8AAgHGAAAA3gABAIIAAQAEAwcDAwMEBAAIEIAAbgABGAAAAAABAAABAAAAAQACbwAAAAAMBAEAAAkGAAAFBAcDBYUkxgQAAMYFAACMBgAARwMDAAAAAABSBwMAZQABAPsHAADZCAAAEgEE/xIBBv8SAAAAEgABABIABwASAAIAEgEF/1ILAQC8CQAWAAAAAJ8JAwJSCwgAvAkJxwEAAACfCQMCUgUJAKQJBAAADCCA2QoBABIBBf8SAAgAnwkCAdkJAgASAQX/EgEE/8EEAACCCQIABQMIAwkDAwMKBAAMIIADAgMEPQsBGAACAQIAAAAAAgAAAAAAAAAYAAAAAAAAAAADAAAAAAAJAAAAAEMAAAAAAgAAAQIABaMAAADAAAAAwAEBABIAAACCAQIAAgYABgUCAAUBAAEYABMpADoBAAAAAAbX7ufOEwjf2qW1zs4MVQ/Ap/bwuuUqjc8=

-- decompilation:
local function defaultGuard(_) -- line: 20
	return true
end
local function observeAttribute(p2, s1: string, p3: ((...any) -> ...any), p4: ((...any) -> ...any)?) -- line: 61
	-- upvalues: defaultGuard (copy)
	local u8 = nil
	local connection = nil
	local n1 = 0.0
	local v11 = if p4 == nil then defaultGuard else p4

	local function OnAttributeChanged() -- line: 74
		-- upvalues: u8 (ref), n1 (ref), p2 (copy), s1 (copy), v11 (copy), p3 (copy), connection (ref)
		if u8 ~= nil then
			task.spawn(u8)
			u8 = nil
		end

		n1 += 1.0

		local v13 = n1
		local s1_2 = p2:GetAttribute(s1)

		if s1_2 ~= nil and v11(s1_2) then
			task.spawn(function() -- line: 86
				-- upvalues: p3 (copy), s1_2 (copy), v13 (copy), n1 (ref), connection (ref), u8 (ref)
				local v15 = p3(s1_2)

				if v13 == n1 and connection.Connected then
					u8 = v15

					return
				end

				task.spawn(v15)
			end)
		end
	end

	connection = p2:GetAttributeChangedSignal(s1):Connect(OnAttributeChanged)
	task.defer(function() -- line: 101
		-- upvalues: connection (ref), OnAttributeChanged (copy)
		if not connection.Connected then
			return
		end

		OnAttributeChanged()
	end)

	return function() -- line: 110
		-- upvalues: connection (ref), u8 (ref)
		connection:Disconnect()

		if u8 ~= nil then
			task.spawn(u8)
			u8 = nil
		end
	end
end

return observeAttribute

