-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTCEluc3RhbmNlA25ldw1CaW5kYWJsZUV2ZW50BnNjcmlwdAZQYXJlbnQIT25VcGRhdGUFRXZlbnQMc2V0bWV0YXRhYmxlBGdhbWULSHR0cFNlcnZpY2UKR2V0U2VydmljZQxHZW5lcmF0ZUdVSUQJSW5zdGFuY2VzA0FkZARGaXJlCVNldFdlaWdodAVwYWlycxBHZXRIaWdoZXN0T2JqZWN0B19faW5kZXgABQUAAQAAABekAAIAAAQAgG8BAwCfAAICpAEFAAAAQEAwAQAkBgAAAOIBCQBNAgA2CAAAADACAc4HAAAAMAABNggAAAD7BAAAnj0BBAQAAABSAwEApAILAAAAoECfAgMBggECAAwDAQMCBAAEAIADAwMEBAAAQEADBQMGAwcFAgcIAwgEAACgQAAGAgEYAAAAAAEAAAABAQAAAAEAAgAAAAAAAAEHAAAAAAYDAAAAAA6kAwEAAAAAQG8FAgC8AwMWAwAAAJ8DAwK8AwOkBAAAAJ8DAgJNBADnBQAAAJAFAgZqBQQBggMCAAcDCQQAAABAAwoDCwMMAw0CAAAAAAAA8D8AEQ4BGAAAAAAAAAAAAAEAAAABEgAAAAAFAwAAAAANTQQA5wAAAACHAwQBDgMDAE0DAOcAAAAAagIDAU0DADYBAAAAvAMD3QIAAACfAwIBggABAAMDDQMHAw8AFxABGAAAAAABAAACAAAAAAEYAAAAAAgBAAAAABPGAQAAxgIAAKQDAQAAAABATQQA5wIAAACfAwIEFwMGAEcBAwAAAAAAfQEDAAcAAABSAQcAUgIGAG4D+f8CAAAAUgMCAFIEAQCCAwMAAwMRBAAAAEADDQAeEgEYAAEBAAAAAAABAAAAAQH9AAYAAB8AAAAAAgAAAQIAFqMAAADiAAEA/wEAAAAAAAAwAQDnAAAAADAAAG4CAAAAwAEDABIAAAAwAQDvBAAAAMABBQAwAQBfBgAAAMABBwAwAQAnCAAAAMABCQAwAQDsCgAAAIIAAgALAw0FAQADEwYAAwIGAQMOBgIDEAYDAxIEAAECAwEAARgAAAEAAAACAAIAAAALAAAGAAAHAAAMAQAAAAAEcdBb7GM6dqz2WjZQwJRyaQHITJhDFDHt

-- decompilation:
local t1 = {
	Instances = {}
}

t1.__index = t1

function t1.new() -- line: 6
	-- upvalues: t1 (copy)
	local BindableEvent = Instance.new("BindableEvent")

	BindableEvent.Parent = script

	local t2 = {
		OnUpdate = BindableEvent.Event,
		Event = BindableEvent
	}

	setmetatable(t2, t1)

	return t2
end
function t1.Add(p1, p2, p3) -- line: 17
	local guid = game:GetService("HttpService"):GenerateGUID()

	p1.Instances[p2] = p3 or 1.0

	return guid
end
function t1.SetWeight(p4, p5, p6) -- line: 23
	if p4.Instances[p5] then
		p4.Instances[p5] = p6
	end

	p4.Event:Fire()
end
function t1.GetHighestObject(p7) -- line: 30
	local v12 = nil
	local v13 = nil

	for k, v in pairs(p7.Instances) do
		if v12 == nil or v12 <= v then
			v12 = v
			v13 = k
		end
	end

	return v13, v12
end

return t1

