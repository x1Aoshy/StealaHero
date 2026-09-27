-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGCkRpc2Nvbm5lY3QJSGVhcnRiZWF0B0Nvbm5lY3QEZ2FtZQpSdW5TZXJ2aWNlCkdldFNlcnZpY2UABQMBBQAAACD7AQAAQwEBAN4BAAD7AQAAjAIBAGACGQABAAAA+wEAAHgBAQDeAQAA+wEBAHgBAQDeAQEA+wEBAIwCAAB9AQoAAgAAAPsBAgAOAQIA+wECAJ8BAQH7AQMAvAEBGgEAAACfAQIBggABAPsBBAAOAQMA+wEEAPsCAQCfAQIBggABAAICAAAAAAAA8D8DAQAGAAEYAAAAAQAAAAEAAAEAAAEAAAABAAEAAgAAAAECAAEAAAMHAAAAAAEAAQAAAAL7AAAAggACAAAAGAABGAAAGQAAAAACAAEAAAAF+wAAALwAABoAAAAAnwACAYIAAQABAwEAGgABGAAAAAABGwAAAAAIAwEAAAgFAAAFAwKFhRWMAwAAxgQAAPsFAABNBQX9AAAAANkHAAASAQP/EgEA/xIAAgASAQT/EgABALwFBccBAAAAnwUDAlIEBQDZBQEAEgEA/9kGAgASAQT/wQAAAIIFAwACAwIDAwMAAQICAAEYAAECAAAAAAAAAAAAAAAAEgACAAAAAwAAAAADAAABAgAKowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAsABBAASAAAAggECAAUDBAQAAABAAwUDBgYDAQMBAAEYAAAAAAAAAAEAAAEAAAAABNpc4C1GnAMhf7VNEtM7x4aqRPdZ6JiKLA==

-- decompilation:
local RunService = game:GetService("RunService")

return function(n1: number, p1: ((...any) -> ...any)?, p2: ((...any) -> ...any)?) -- line: 2
	-- upvalues: RunService (copy)
	local n2 = 0.0
	local connection = nil

	connection = RunService.Heartbeat:Connect(function(dt) -- line: 6
		-- upvalues: n2 (ref), n1 (ref), p2 (copy), connection (ref), p1 (copy)
		n2 += dt

		if n2 > 1.0 then
			n2 -= 1.0
			n1 -= 1.0

			if n1 <= 0.0 then
				if p2 then
					p2()
				end

				connection:Disconnect()

				return
			end

			if p1 then
				p1(n1)
			end
		end
	end)

	return function() -- line: 24
		-- upvalues: n1 (ref)
		return n1
	end, function() -- line: 26
		-- upvalues: connection (ref)
		connection:Disconnect()
	end
end

