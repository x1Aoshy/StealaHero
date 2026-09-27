-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTCkRpc2Nvbm5lY3QJSGVhcnRiZWF0B0Nvbm5lY3QERmlyZQhJbnN0YW5jZQNuZXcNQmluZGFibGVFdmVudAVFdmVudARXYWl0B0Rlc3Ryb3kEZ2FtZQpSdW5TZXJ2aWNlCkdldFNlcnZpY2UJSXNSdW5uaW5nBHRpbWUCb3MFY2xvY2sQSGVhcnRiZWF0TG9vcEZvchVBd2FpdEhlYXJ0YmVhdExvb3BGb3IABQcBBwAAAC37AgAAnwIBAvsDAQAmAQID+wICAGABCAACAAAA+wIDAFIDAQBSBAAA+wYCAOwFAQafAgQBggABAPsCBAAqAgQAAQAAAPsCBQBHAgwAAAAAgPsCBgBHAhYAAAAAAPsCBgC8AgIaAAAAAJ8CAgHGAgAA3gIGAIIAAQCCAAEAqQIBAN4CBAD7AgUAnwIBAfsCBgBHAgcAAAAAAPsCBgC8AgIaAAAAAJ8CAgHGAgAA3gIGAIIAAQABAwEACgABGAAAAAABAAABAAAAAAABAgAAAAAAAQAAAQAAAAEAAQADAAEAAQAAAQAAAAEAAwsAAAAACQMCAAAAFcYDAAD7BAAAnwQBAqkFAAD7BgEATQYG/QAAAADZCAAAEgIAABIABAASAAAAEgABABIBBf8SAAIAEgED/7wGBscBAAAAnwYDAlIDBgDBAwAAggMCAAIDAgMDAQAGAAEYAAEAAQEAAAAAAAAAAAAAAAAAABcABwAAAAAHAQgAAAA7+wIAAJ8CAQL7AwEAJgECA/sCAgBgAQgAAgAAAPsCAwBSAwEAUgQAAPsGAgDsBQEGnwIEAYIAAQD7AgQAKgIEAAEAAAD7AgUARwITAAAAAID7AgYARwIFAAAAAAD7AgYAvAIC3QAAAACfAgIB+wIHAEcCHQAAAAAA+wIHALwCAhoBAAAAnwICAcYCAADeAgcAggABAIIAAQCpAgEA3gIEAPsCBQCfAgEB+wIGAEcCBQAAAAAA+wIGALwCAt0AAAAAnwICAfsCBwBHAgcAAAAAAPsCBwC8AgIaAQAAAJ8CAgHGAgAA3gIHAIIAAQACAwQDAQAoAAEYAAAAAAEAAAEAAAAAAAECAAAAAAABAAABAAAAAgAAAQAAAAEAAQADAAEAAQAAAQAAAAIAAAEAAAABAAMpAAAAAAoDAgAAACLGAwAA+wQAAJ8EAQKkBQIAAAQAgG8GAwCfBQICqQYAAPsHAQBNBwf9BAAAANkJAAASAgAAEgAEABIAAAASAAEAEgEG/xIAAgASAAUAEgED/7wHB8cFAAAAnwcDAlIDBwBNBwU2BgAAALwHB/cHAAAAnwcCAbwHBVAIAAAAnwcCAcEDAACCAAEACQMFAwYEAAQAgAMHAwIDAwMIAwkDCgECIwABGAABAAEAAAABAQAAAAAAAAAAAAAAAAAAAB0AAAAAAQAAAQAkAAAAAAUAAAECAB2jAAAA/wACAAAAAACkAQEAAAAAQG8DAgC8AQEWAwAAAJ8BAwK8AwGzBAAAAJ8DAgIOAwMApAIGAAAAUEArAgIApAIJAAAgcIDAAwoAEgACABIAAQAwAwBBCwAAAMADDAASAAIAEgABADADAMsNAAAAggACAA4DCwQAAABAAwwDDQMOAw8EAABQQAMQAxEEACBwgAYBAxIGAwMTAgEDAQABGAACAAEAAAAAAAEAAAAAAAAAAAEAAAAAHQAAAAAlAQAAAAAEUyqVVGlO/4WKFkeWNphi7CMygiBh7v9V

-- decompilation:
local t1 = {}
local RunService = game:GetService("RunService")
local v3 = RunService:IsRunning() and time or os.clock

function t1.HeartbeatLoopFor(p1, p2, p3) -- line: 6
	-- upvalues: v3 (copy), RunService (copy)
	local u7 = nil
	local v8 = v3()
	local u9 = false

	u7 = RunService.Heartbeat:Connect(function(dt) -- line: 10
		-- upvalues: v3 (copy), v8 (copy), p1 (copy), p2 (copy), u9 (ref), p3 (copy), u7 (ref)
		local v18 = v3() - v8

		if v18 < p1 then
			p2(v18, dt, v18 / p1)

			return
		end

		if u9 == true or p3 == nil then
			if u7 ~= nil then
				u7:Disconnect()
				u7 = nil

				return
			end
		else
			u9 = true
			p3()

			if u7 ~= nil then
				u7:Disconnect()
				u7 = nil
			end
		end
	end)

	return u7
end
function t1.AwaitHeartbeatLoopFor(p4, p5, p6) -- line: 35
	-- upvalues: v3 (copy), RunService (copy)
	local u13 = nil
	local v14 = v3()
	local BindableEvent = Instance.new("BindableEvent")
	local u16 = false

	u13 = RunService.Heartbeat:Connect(function(dt) -- line: 40
		-- upvalues: v3 (copy), v14 (copy), p4 (copy), p5 (copy), u16 (ref), p6 (copy), BindableEvent (copy), u13 (ref)
		local v20 = v3() - v14

		if v20 < p4 then
			p5(v20, dt, v20 / p4)

			return
		end

		if u16 == true or p6 == nil then
			if BindableEvent ~= nil then
				BindableEvent:Fire()
			end

			if u13 ~= nil then
				u13:Disconnect()
				u13 = nil

				return
			end
		else
			u16 = true
			p6()

			if BindableEvent ~= nil then
				BindableEvent:Fire()
			end

			if u13 ~= nil then
				u13:Disconnect()
				u13 = nil
			end
		end
	end)
	BindableEvent.Event:Wait()
	BindableEvent:Destroy()
end

return t1

