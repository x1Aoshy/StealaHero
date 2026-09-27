-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBnR5cGVvZghmdW5jdGlvbglDb25uZWN0ZWQGUGFyZW50BHRhc2sFc3Bhd24NT25QbGF5ZXJBZGRlZBBPblBsYXllclJlbW92aW5nCkdldFBsYXllcnMKRGlzY29ubmVjdARuZXh0C1BsYXllckFkZGVkB0Nvbm5lY3QOUGxheWVyUmVtb3ZpbmcFZGVmZXINb2JzZXJ2ZVBsYXllcgRnYW1lB1BsYXllcnMKR2V0U2VydmljZQAHAwAEAAAAG/sAAAD7AQEAnwACArssAANSAgAApAEBAAAAAECfAQIC8AERAAIAAID7AQIATQEB0QMAAAAOAQgA+wEBAE0BASQEAAAADgEEAPsBAwD7AgEAagABAoIAAQCkAQcAABhQgFICAACfAQIBggABAAgDAQQAAABAAwIDAwMEAwUDBgQAGFCAACAAARgAAAABAAAAAAAAAQAAAAAAAAABAAAAAgAAAAMhAAAAAAMBAwAABgMAAAUBBw77AQAATQEB0QAAAAArAQEAggABAKQBAwAACBCA2QIAABICAQASAAAAEgIAABICAgCfAQIBggABAAQDAwMFAwYEAAgQgAEAGwcBGAAAAAABAwAAAAAAAAAKHAAAAAAEAQEAAAYDAAAFAQcR+wIAAIcBAgD7AgAAxgMAAGoDAgC7LAEDUgMBAKQCAQAAAABAnwICAvACBQACAACApAIFAAAQMIBSAwEAnwICAYIAAQAGAwEEAAAAQAMCAwUDBgQAEDCAACwIARgAAAEAAAEAAAAAAAABAAAAAi0AAAAACAADAAAAEvsAAABNAADRAAAAACsAAQCCAAEA+wABALwAAKsBAAAAnwACBGQABQCkBQQAAAwggPsGAgBSBwQAnwUDAW4A+v8CAAAAggABAAUDAwMJAwUDBgQADCCAADkAARgAAAAAAQMAAAAAAQAAAAD/AAM6AAAAAAUAAwAAACX7AAAAvAAAGgAAAACfAAIB+wABALwAABoAAAAAnwACAaQAAgAAABBA+wECAJ8AAgIOABcAUgEAAPsDAgCHAgMB+wMCAMYEAABqBAMBuywCA1IEAgCkAwQAAAAwQJ8DAgLwAwUABQAAgKQDCAAAHGCAUgQCAJ8DAgGkAQIAAAAQQPsCAgCfAQICUgABAEgA6P+CAAEACQMKAwsEAAAQQAMBBAAAMEADAgMFAwYEABxggABEAAEYGAAAAAEAAAACAAAAAQHjAAEAAAEAAAAAAAABAAAAGwAAAAD+BC0AAAAACQEBAAAGAwAABQEFJ8YBAADGAgAA/wMAAAAAAADZBAAAEgEB/xIAAAASAAMA2QUBABIAAwD7BgAATQYGKAAAAABSCAQAvAYGxwEAAACfBgMCUgEGAPsGAABNBgbUAgAAAFIIBQC8BgbHAQAAAJ8GAwJSAgYApAYFAAAQMIDZBwIAEgEB/xICAAASAAQAnwYCAdkGAwASAQH/EgEC/xIAAwDBAQAAggYCAAYDDAMNAw4DBQMPBAAQMIAEAQIDBBUQARgAAQIAAgAAABEACQAAAAAAAAABAAAAAAAAAAMAAAAAAAALAAAAAAAWAAAAAAMAAAECAAqjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCwAEEABIAAACCAQIABQMRBAAAAEADEgMTBgUBBQEAARgAAgAAAAAAEgA7AQAAAAAGCVGd7CJ/o6uCfhTf67E7CnlJipg7lfft

-- decompilation:
local Players = game:GetService("Players")

local function observePlayer(p1: ((...any) -> ...any)) -- line: 21
	-- upvalues: Players (copy)
	local connection = nil
	local t1 = {}

	local function OnPlayerAdded(p2) -- line: 27
		-- upvalues: connection (ref), p1 (copy), t1 (copy)
		if not connection.Connected then
			return
		end

		task.spawn(function() -- line: 32
			-- upvalues: p1 (copy), p2 (copy), connection (ref), t1 (copy)
			local v16 = p1(p2)

			if typeof(v16) == "function" then
				if connection.Connected and p2.Parent then
					t1[p2] = v16

					return
				end

				task.spawn(v16)
			end
		end)
	end
	local function OnPlayerRemoving(p3) -- line: 44
		-- upvalues: t1 (copy)
		local v11 = t1[p3]

		t1[p3] = nil

		if typeof(v11) == "function" then
			task.spawn(v11)
		end
	end

	connection = Players.PlayerAdded:Connect(OnPlayerAdded)

	local connection2 = Players.PlayerRemoving:Connect(OnPlayerRemoving)

	task.defer(function() -- line: 57
		-- upvalues: connection (ref), Players (copy), OnPlayerAdded (copy)
		if not connection.Connected then
			return
		end

		for _, player in Players:GetPlayers() do
			task.spawn(OnPlayerAdded, player)
		end
	end)

	return function() -- line: 68
		-- upvalues: connection (ref), connection2 (ref), t1 (copy)
		connection:Disconnect()
		connection2:Disconnect()

		local v14 = next(t1)

		while v14 do
			local v15 = t1[v14]

			t1[v14] = nil

			if typeof(v15) == "function" then
				task.spawn(v15)
			end

			v14 = next(t1)
		end
	end
end

return observePlayer

