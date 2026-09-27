-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHBnR5cGVvZgV0YWJsZQZpbnNlcnQEbmV4dAxnZXRtZXRhdGFibGUMc2V0bWV0YXRhYmxlCERlZXBDb3B5AAIOAgEAAABGuywAA1IDAACkAgEAAAAAQJ8CAgLwAgIAAgAAAIIAAgBSAgEAKwICAP8CAAAAAAAAUgECAIcCAQAOAgEAggICAP8DAAAAAAAAagMBABwEAACMBQAAYAUQAAQAAACMBwEAUgUEAIwGAQCoBRsAUgkDAPsKAACHCwAHUgwBAJ8KAwBMNAACpAgEAAAMIICfCAABiwX2/2UAEACkBQYAAABQQFIGAADGBwAAFwUJAPsKAABSCwgAUgwBAJ8KAwL7CwAAUgwJAFINAQCfCwMCagsDCm4F9v8CAAAAuzwAA1IGAACkBQgAAABwQJ8FAgIOBQkAUgcDAPsIAABSCQUAUgoBAJ8IAwBMPQACpAYKAAAAkECfBgABggMCAAsDAQQAAABAAwIDAwQADCCAAwQEAABQQAMFBAAAcEADBgQAAJBAAAEHARgAAAAAAAAAAQIAAAAAAQEBAgABAQEAAAEAAAABAAAAAAAAAAD/AAQAAAAAAQAAAAAAAAAA/wAEAAAAAAEBAAAAAAAAAAACAgAAAAABAAABAgAEowAAAMAAAAASAAAAggACAAEGAAEAAQABGAAAABwBAAAAAAHg91VUvwrVPDFcpNk2gNIAkO9CINIzP1U=

-- decompilation:
local function DeepCopy(p1, p2) -- line: 1
	-- upvalues: DeepCopy (copy)
	if typeof(p1) ~= "table" then
		return p1
	end

	local v4 = p2 or {}
	local v5 = v4[p1]

	if v5 then
		return v5
	end

	local t1 = {}

	v4[p1] = t1

	local v7 = #p1

	if v7 > 0.0 then
		for i = 1.0, v7 do
			table.insert(t1, DeepCopy(p1[i], v4))
		end
	else
		for k, v in next, p1 do
			t1[DeepCopy(k, v4)] = DeepCopy(v, v4)
		end
	end

	local mt = getmetatable(p1)

	if mt then
		setmetatable(t1, DeepCopy(mt, v4))
	end

	return t1
end

return DeepCopy

