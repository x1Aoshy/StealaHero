-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBnR5cGVvZghmdW5jdGlvbglDb25uZWN0ZWQGUGFyZW50BHRhc2sFc3Bhd24KRGlzY29ubmVjdAVkZWZlcg9BbmNlc3RyeUNoYW5nZWQHQ29ubmVjdBBPbkNoYXJhY3RlckFkZGVkCUNoYXJhY3Rlcg5DaGFyYWN0ZXJBZGRlZBBvYnNlcnZlQ2hhcmFjdGVyB3JlcXVpcmUGc2NyaXB0DW9ic2VydmVQbGF5ZXIACAMABgAAABv7AAAA+wEBAPsCAgCfAAMCuywAA1ICAACkAQEAAAAAQJ8BAgLwARAAAgAAgPsBAwBNAQHRAwAAAA4BBwD7AQIATQEBJAQAAAAOAQMA3gAEAN4ABQCCAAEApAEHAAAYUIBSAgAAnwECAYIAAQAIAwEEAAAAQAMCAwMDBAMFAwYEABhQgAAfAAEYAAAAAAIAAAAAAAABAAAAAAAAAAEBAAMAAAADIAAAAAAEAgMAAAAaRwEYAAAAAID7AgAATQIC0QAAAAAOAhMA+wIAALwCAhoBAAAAnwICAfsCAQBHAg0AAAAAAKQCBAAADCCA+wMBAJ8CAgH7AgIA+wMBAJoCAwADAAAAxgIAAN4CAgDGAgAA3gIBAIIAAQAFAwMDBwMFAwYEAAwggAAvAAEYAAAAAAAAAQAAAAEAAAEAAAABAAAAAQACAAMwAAAAAAYBBAAABgMAAAUBBxjGAQAApAICAAAEAIDZAwAAEgIAABICAQASAAAAEgICABIBAf8SAgMAnwICAcYCAABNAwCLAwAAANkFAQASAQL/EgEB/xICAwC8AwPHBAAAAJ8DAwJSAgMAwQEAAIIAAQAFAwUDCAQABACAAwkDCgIAARsLARgAAwAAAAAAAAAAAA8BAAAAAAAAAAAADAAcAAAAAAMAAwAAABD7AAAATQAAaQAAAAAOAAsA+wABAE0AANEBAAAADgAHAKQABAAADCCA+wECAPsCAABNAgJpAAAAAJ8AAwGCAAEABQMMAwMDBQMGBAAMIIAAQQABGAAAAAAAAAAAAQAAAAAAAAJCAAAAAAIAAgAAAA77AAAAvAAAGgAAAACfAAIB+wABAEcABwAAAAAApAADAAAIEID7AQEAnwACAcYAAADeAAEAggABAAQDBwMFAwYEAAgQgABIAAEYAAAAAAEAAAEAAAABAAJJAAAAAAcBAQAAABrGAQAAxgIAANkDAAASAgAAEgAAABIBAv8SAQH/TQQAlwAAAABSBgMAvAQExwEAAACfBAMCUgIEAKQEBAAADCCA2QUBABIAAAASAQL/EgADAJ8EAgHZBAIAEgEC/xIBAf/BAQAAggQCAAUDDQMKAwUDCAQADCCAAwIDBBYAARgAAgIAAAAAIwAAAAAAAAMAAAAAAAAHAAAAABcAAAAAAwEBAAAGAwAABQEFBfsBAADZAgAAEgAAAJ8BAgCCAQAAAAEFFQ4BGAAAAAAAFgAAAAACAAABAgANowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BATwFAAAAnwACAsABBgASAAAAggECAAcDDwQAAABAAxAEAAAgQAMEAxEGBgEGAQABGAACAAAAAAAAAAASAD0BAAAAAAcLgkSfuN3f5lwY0iN9IN3ee5pT6zlGLp4=

-- decompilation:
local observePlayer = require(script.Parent.observePlayer)

local function observeCharacter(p1: ((...any) -> ...any)) -- line: 21
	-- upvalues: observePlayer (copy)
	return observePlayer(function(p2) -- line: 22
		-- upvalues: p1 (copy)
		local u5 = nil
		local connection = nil

		local function OnCharacterAdded(p3) -- line: 27
			-- upvalues: p1 (copy), p2 (copy), connection (ref), u5 (ref)
			local u9 = nil

			task.defer(function() -- line: 31
				-- upvalues: p1 (copy), p2 (copy), p3 (copy), connection (ref), u9 (ref), u5 (ref)
				local v11 = p1(p2, p3)

				if typeof(v11) == "function" then
					if connection.Connected and p3.Parent then
						u9 = v11
						u5 = v11

						return
					end

					task.spawn(v11)
				end
			end)

			local connection2 = nil

			connection2 = p3.AncestryChanged:Connect(function(_, parent) -- line: 47
				-- upvalues: connection2 (ref), u9 (ref), u5 (ref)
				if parent == nil and connection2.Connected then
					connection2:Disconnect()

					if u9 ~= nil then
						task.spawn(u9)

						if u5 == u9 then
							u5 = nil
						end

						u9 = nil
					end
				end
			end)
		end

		connection = p2.CharacterAdded:Connect(OnCharacterAdded)
		task.defer(function() -- line: 65
			-- upvalues: p2 (copy), connection (ref), OnCharacterAdded (copy)
			if p2.Character and connection.Connected then
				task.spawn(OnCharacterAdded, p2.Character)
			end
		end)

		return function() -- line: 72
			-- upvalues: connection (ref), u5 (ref)
			connection:Disconnect()

			if u5 ~= nil then
				task.spawn(u5)
				u5 = nil
			end
		end
	end)
end

return observeCharacter

