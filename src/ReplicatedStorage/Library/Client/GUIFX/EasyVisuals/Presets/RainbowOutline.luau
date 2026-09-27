-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTCEluc3RhbmNlBlBhcmVudApEaXNjb25uZWN0C1NldFJvdGF0aW9uBlN0cm9rZQNuZXcIR3JhZGllbnQJVGVtcGxhdGVzB1JhaW5ib3cFQ29sb3IJSGVhcnRiZWF0B0Nvbm5lY3QHRWZmZWN0cwtDb25uZWN0aW9ucwRnYW1lClJ1blNlcnZpY2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAADBQEFAAAAG/sBAABNAQH0AAAAAA4BBwD7AQAATQEB9AAAAABNAQEkAQAAAEcBBQAAAACA+wEBALwBARoCAAAAnwECAfsCAgD7BAMACQMEAEMBAgPeAQIA+wEEAPsDAgCMBAEAvAEBUQMAAACfAQQBggABAAQDAQMCAwMDBAALAAEYAAAAAAAAAAAAAAABAAAAAgAAAAABAAAAAAABDAAAAAALAwIAAAgFAAAFAwcCAjn7AwAATQMDpQAAAABNAwPvAQAAAFIEAABSBQIAnwMDAvsEAABNBAQ9AgAAAE0EBO8BAAAATQUD9AMAAAD7BgAATQYGSwQAAABNBgZ0BQAAAE0GBqQGAAAAjAcAAJ8EBAKMBQUAxgYAAPsHAQBNBwf9BwAAANkJAAASAAMAEgEG/xIBBf8SAAEAEgAEALwHB8cIAAAAnwcDAlIGBwDiBwsA/wgAAAIAAABSCQQAUgoDAMUICQMBAAAAMAgHlwkAAAD/CAAAAQAAAFIJBgDFCAkCAQAAADAIB/EKAAAAwQUAAIIHAgAMAwUDBgMHAwEDCAMJAwoDCwMMAw0DDgUCCQoBAAUAARgAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAgEAAAAAAAAAAAAAAAAIAQAAAAAAAAABAAAAAAAAAAAGAAAAAAMAAAECABSjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICJAgAAACfAQICwAIJABIAAQASAAAAggICAAoDDwQAAABAAxADEQMSBAAAQEADEwQAAGBAAwIGAQEBAQABGAAAAAAAAAACAAAAAAAAAAACAAAAAQAAAAACA+B6fsTMcD5ABLBQN8ClT3P4bQoxJBB/

-- decompilation:
local RunService = game:GetService("RunService")
local Parent = require(script.Parent.Parent)

return function(p1, n1: number, n2: number) -- line: 5
	-- upvalues: Parent (copy), RunService (copy)
	local v6 = Parent.Stroke.new(p1, n2)
	local v7 = Parent.Gradient.new(v6.Instance, Parent.Templates.Rainbow.Color, 0.0)
	local n3 = 5.0
	local connection = nil

	connection = RunService.Heartbeat:Connect(function(dt) -- line: 11
		-- upvalues: v6 (copy), connection (ref), n3 (ref), n1 (copy), v7 (copy)
		if not v6.Instance or v6.Instance.Parent == nil then
			connection:Disconnect()
		end

		n3 += n1 * dt
		v7:SetRotation(n3, 1.0)
	end)

	return {
		Effects = {
			v7,
			v6
		},
		Connections = { connection }
	}
end

