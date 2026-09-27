-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBmFjY2VzcwVzdGFydAVlbXB0eQZzZXJ2ZXIHc3RydWN0cwdwYWNrZXRzA3NldAV3cml0ZQZjbGllbnQEcmVhZARnYW1lClJ1blNlcnZpY2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQKcmVwbGljYXRlZAZ2YWx1ZXMFdHlwZXMWbmFtZXNwYWNlc0RlcGVuZGVuY2llcwlwYWNrZXRJRHMISXNTZXJ2ZXIAAg8CBQAABwQAAAUCAwVe+wIAAE0CAiIAAAAAUgMAAJ8CAgL7AwEATQMD/AEAAABSBAAAnwMCAVIDAQCfAwEC+wQBAE0EBK0CAAAAnwQBAv8FAAAAAAAA+wYCAPAGLwADAACA4gYGAP8HAAAAAAAAMAcGhgQAAAD/BwAAAAAAADAHBhwFAAAAUgcDAMYIAADGCQAAZAcRAPsMAwCVDAwH3gwDAE0MBhwFAAAA+w0DAGoNDAqHDAMK+w0DAJ8MAgJqDAUK+wwEAE0MDFMIAAAA+w0DAIcOBQqfDAMBbgfu/wEAAABSBwQAxggAAMYJAABkBwMATQwGhgQAAABqCwwKbgf8/wIAAABSCQYAvAcC0gkAAACfBwMBggUCAPsGAgDwBhgACgAAgLwGAnkLAAAAnwYCAlIHAwDGCAAAxgkAAGQHDgBSDAsATQ4GHAUAAACHDQ4KnwwCAmoMBQr7DAQATQwMUwgAAABNDgYcBQAAAIcNDgqHDgUKnwwDAW4H8f8CAAAAggUCAAwDAQMCAwMDBAMFAwYFAgQFAgAAAAAAAPA/AwcDCAMJAwoAEwABGAAAAAAAAgAAAAADAAEAAAACAAIAAAEBAAAAAQAAAAMAAAABAAABAAAAAQAAAAIAAAAAAPsACAAAAAEAAP8ABAAAAAABAAADAAACAAAAAQAAAAAAAgAAAAAAAAD9AAcZAAAAAAgAAAECAEGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQECkAgcAAABgQE0CAiQIAAAATQICJAgAAABNAgKPCQAAAE0CAsIKAAAAnwECAqQCBQAAAEBApAMHAAAAYEBNAwMkCAAAAE0DAyQIAAAATQMDDwsAAACfAgICpAMFAAAAQECkBAcAAABgQE0EBCQIAAAATQQEhgwAAACfAwICpAQFAAAAQECkBQcAAABgQE0FBSQIAAAATQUFIQ0AAACfBAICvAYACw4AAACfBgICDgYCAG8FDwBlAAEAbwUQAIwGAADZBwAAEgABABIAAwASAAUAEgEG/xIABADBBgAAggcCABEDCwQAAABAAwwDDQMOBAAAQEADDwQAAGBAAxADEQMSAxMDFAMVAxYDBAMJAQABAAEYAAcAAAAAAAIAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAIAAAAAAAACAgAAAAAAAAABAAAAAAF8Z9WGdfOGoP2OIA0VXAVJDH/C8k6jv4c=

-- decompilation:
local RunService = game:GetService("RunService")
local values = require(script.Parent.Parent.replicated.values)

require(script.Parent.Parent.types)

local namespacesDependencies = require(script.Parent.namespacesDependencies)
local packetIDs = require(script.Parent.packetIDs)
local v5 = not RunService:IsServer() and "client" or "server"
local n1 = 0.0

return function(s1: string, p1: ((...any) -> ...any)) -- line: 19
	-- upvalues: values (copy), namespacesDependencies (copy), v5 (copy), n1 (ref), packetIDs (copy)
	local v9 = values.access(s1)

	namespacesDependencies.start(s1)

	local v10 = p1()
	local v11 = namespacesDependencies.empty()
	local t1 = {}

	if v5 == "server" then
		local t2 = {
			structs = {},
			packets = {}
		}

		for v14 in v10 do
			n1 += 1.0
			t2.packets[v14] = n1
			t1[v14] = v10[v14](n1)
			packetIDs.set(n1, t1[v14])
		end

		for v15, v16 in v11 do
			t2.structs[v15] = v16
		end

		v9:write(t2)

		return t1
	end

	if v5 == "client" then
		local v17 = v9:read()

		for v18, v19 in v10 do
			t1[v18] = v19(v17.packets[v18])
			packetIDs.set(v17.packets[v18], t1[v18])
		end
	end

	return t1
end

