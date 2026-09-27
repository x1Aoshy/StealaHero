-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBnNlcnZlcihjYW5ub3Qgd3JpdGUgdG8gcmVwbGljYXRkdmFsdWUgb24gY2xpZW50BmFzc2VydAlfbHVhdURhdGEGX3ZhbHVlCkpTT05FbmNvZGUFVmFsdWUFd3JpdGUEcmVhZAV0YWJsZQZmcmVlemUKSlNPTkRlY29kZQxzZXRtZXRhdGFibGUGY2xpZW50B0NoYW5nZWQHQ29ubmVjdARnYW1lC0h0dHBTZXJ2aWNlCkdldFNlcnZpY2UKUnVuU2VydmljZQhJc1NlcnZlcgdfX2luZGV4AAUGAgIAAAcEAAAFAg8EF/sEAADwBAIAAAAAAKkDAAGpAwEAgQEDBAEAAABvBAEApAIDAAAAIECfAgMBMAEAuwQAAABNAgDjBQAAAPsDAQBSBQEAvAMDngYAAACfAwMCMAMC7AcAAACCAAEACAMBAwIDAwQAACBAAwQDBQMGAwcAEAgBGAAAAAAAAAAAAAAAAgADAAAAAAAAAAABEQAAAAACAQAAAAADTQEAuwAAAACCAQIAAQMEABkJARgAAAAaAAAAAAYBAgAABgMAAAUBAw4rAAEAggABAPsBAACkAgIAAAQAgPsDAQBSBQAAvAMDywMAAACfAwMAnwIAAjACAbsEAAAAggABAAUDCgMLBAAEAIADDAMEACgAARgAAQMAAAAAAAAAAAAAASkAAAAABgEDAAAGAwAABQEHJf8CAgAAAAAA+wMAAJ49AgMDAAAApAEBAAAAAECfAQMC/wIAAAAAAAAwAgG7AgAAADAAAeMDAAAA+wIBAPACFAAEAACApAIHAAAYUID7AwIATQUA7AgAAAC8AwPLCQAAAJ8DAwCfAgACMAIBuwIAAABNAgCFCgAAANkEAAASAAEAEgICALwCAscLAAAAnwIDAYIBAgAMAw0EAAAAQAMEAwUDDgMKAwsEABhQgAMHAwwDDwMQAQIdAAEYAAAAAAAAAAACAAAAAQAEAAABAAAAAAAAAAAAAAIAAAAAAAAACR4AAAAABgAAAQIAJqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwK8AwELBQAAAJ8DAgIOAwIAbwIGAGUAAQBvAgcA/wMCAAAAAADiBAkAMAMEbggAAADABQoAEgACABIAAAAwBQPSCwAAAMAFDAAwBQN5DQAAAMAFDgASAAQAEgACABIAAACCBQIADwMRBAAAAEADEgMTAxQDFQMBAw4DFgUBCAYAAwgGAQMJBgMDAAEDAQABGAAAAAAAAAABAAAAAAACAAAAAAAAAgABAAAJAAAAAAkAAAQAAAAAAQAAAAAEBtdzrpNroAAyI5hoJFhXi3bPZNo0Exmv

-- decompilation:
local HttpService = game:GetService("HttpService")
local v2 = not game:GetService("RunService"):IsServer() and "client" or "server"
local t1 = {}
local t2 = {
	__index = t1
}

function t1.write(p1, t3: {[any]: any}) -- line: 16
	-- upvalues: v2 (copy), HttpService (copy)
	assert(v2 == "server", "cannot write to replicatdvalue on client")
	p1._luauData = t3
	p1._value.Value = HttpService:JSONEncode(t3)
end
function t1.read(p2) -- line: 25
	return p2._luauData
end

return function(p3) -- line: 29
	-- upvalues: t2 (copy), v2 (copy), HttpService (copy)
	local self = setmetatable({}, t2)

	self._luauData = {}
	self._value = p3

	if v2 == "client" then
		self._luauData = table.freeze(HttpService:JSONDecode(p3.Value))
		p3.Changed:Connect(function(property: string) -- line: 40
			-- upvalues: self (copy), HttpService (copy)
			if not property then
				return
			end

			self._luauData = table.freeze(HttpService:JSONDecode(property))
		end)
	end

	return self
end

