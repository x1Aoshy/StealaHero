-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJCUNvbm5lY3RlZAR0YXNrBXNwYXduEU9uUHJvcGVydHlDaGFuZ2VkCkRpc2Nvbm5lY3QYR2V0UHJvcGVydHlDaGFuZ2VkU2lnbmFsB0Nvbm5lY3QFZGVmZXIPb2JzZXJ2ZVByb3BlcnR5AAYDAAYAAAAS+wAAAPsBAQCfAAIC+wECAPsCAwCaAQcAAgAAAPsBBABNAQHRAAAAAA4BAgDeAAUAggABAKQBAwAACBCAUgIAAJ8BAgGCAAEABAMBAwIDAwQACBCAACQAARgAAAABAAAAAAAAAAEAAgAAAAIlAAAAAAQABgAAABv7AAAARwAHAAAAAACkAAIAAAQAgPsBAACfAAIBxgAAAN4AAAD7AAEAlQAAA94AAQD7AAEA+wICAPsDAwCHAQIDpAICAAAEAIDZAwAAEgIEABIAAQASAAAAEgIBABICBQASAgAAnwICAYIAAQAEAwIDAwQABACAAgAAAAAAAPA/AQAZBAEYAAAAAQAAAAEAAwAAAQIAAAIAAAAAAAAAAAAIGgAAAAAEAAYAAAAg+wAAAE0AANEAAAAAKwABAIIAAQD7AAEARwAHAAAAAACkAAMAAAgQgPsBAQCfAAIBxgAAAN4AAQD7AAIAlQAABN4AAgD7AAIA+wIDAPsDBACHAQIDpAIDAAAIEIDZAwAAEgIFABIAAQASAAAAEgICABICAAASAgEAnwICAYIAAQAFAwEDAgMDBAAIEIACAAAAAAAA8D8BADIAARgZAAAAAeYAAAEAAAABAAMAAAECAAACAAAAAAAAAAAAExoAAAAAAgACAAAADvsAAAC8AAAaAAAAAJ8AAgH7AAEARwAHAAAAAACkAAMAAAgQgPsBAQCfAAIBxgAAAN4AAQCCAAEABAMFAwIDAwQACBCAADoAARgAAAAAAQAAAQAAAAEAAjsAAAAACgMAAAAIBQAABQMHAwUixgMAAMYEAACMBQAA2QYAABIBA/8SAQX/EgAAABIAAQASAAIAEgEE/1IJAQC8BwCUAAAAAJ8HAwJSCQYAvAcHxwEAAACfBwMCUgQHAKQHBAAADCCA2QgBABIBBP8SAQP/EgEF/xIAAAASAAEAEgACAJ8HAgHZBwIAEgEE/xIBA//BAwAAggcCAAUDBgMHAwIDCAQADCCAAwECAxMJARgAAgECAAAAAAAAFgAAAAAAAAAAAwAAAAAAAAAAAAgAAAAAFAAAAAABAAABAgADowAAAMAAAACCAAIAAQYEAQQBAAEYABIwAQAAAAAFRVd95kuqGPCdzHJTeZxTTDVPapJ3kxfn

-- decompilation:
local function observeProperty(p1, s1: string, p2: ((...any) -> ...any)) -- line: 19
	local u5 = nil
	local connection = nil
	local n1 = 0.0

	local function OnPropertyChanged() -- line: 25
		-- upvalues: u5 (ref), n1 (ref), p1 (copy), s1 (copy), p2 (copy), connection (ref)
		if u5 ~= nil then
			task.spawn(u5)
			u5 = nil
		end

		n1 += 1.0

		local v9 = n1
		local v10 = p1[s1]

		task.spawn(function() -- line: 36
			-- upvalues: p2 (copy), v10 (copy), v9 (copy), n1 (ref), connection (ref), u5 (ref)
			local v13 = p2(v10)

			if v9 == n1 and connection.Connected then
				u5 = v13

				return
			end

			task.spawn(v13)
		end)
	end

	connection = p1:GetPropertyChangedSignal(s1):Connect(OnPropertyChanged)
	task.defer(function() -- line: 50
		-- upvalues: connection (ref), u5 (ref), n1 (ref), p1 (copy), s1 (copy), p2 (copy)
		if not connection.Connected then
			return
		end

		if u5 ~= nil then
			task.spawn(u5)
			u5 = nil
		end

		n1 += 1.0

		local v11 = n1
		local v12 = p1[s1]

		task.spawn(function() -- line: 36
			-- upvalues: p2 (copy), v12 (copy), v11 (copy), n1 (ref), connection (ref), u5 (ref)
			local v14 = p2(v12)

			if v11 == n1 and connection.Connected then
				u5 = v14

				return
			end

			task.spawn(v14)
		end)
	end)

	return function() -- line: 58
		-- upvalues: connection (ref), u5 (ref)
		connection:Disconnect()

		if u5 ~= nil then
			task.spawn(u5)
			u5 = nil
		end
	end
end

return observeProperty

