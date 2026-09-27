-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPDFJlcXVlc3RBc3luYwVwY2FsbAR0eXBlBXRhYmxlB1N1Y2Nlc3MKU3RhdHVzQ29kZQ1TdGF0dXNNZXNzYWdlB0hlYWRlcnMEQm9keQ5UcmFuc3BvcnRFcnJvcgh0b3N0cmluZwRIVFRQBGdhbWULSHR0cFNlcnZpY2UKR2V0U2VydmljZQADAwACAAAABvsAAAD7AgEAvAAANAAAAACfAAMAggAAAAEDAQAhAAEYAAAAAAAAIgAAAAAGAQEAAAYDAAAFAQQcpAEBAAAAAEDZAgAAEgIAABIAAACfAQIDDgEHALsoAgNSBAIApAMDAAAAIECfAwIC8AMOAAQAAADiAw8Auz8CA1IFAgCkBBEAAAAAQZ8EAgIwBAMQCQAAAP8EAAAAAAAAMAQDnwoAAACCAwIAggICABIDAgQAAABAAwMEAAAgQAMEAwUBAAMGAgAAAAAAAHlAAwcDCAMJAAMKAQEIBgUGAAAABwgAAAAJ/////wr/////CwwAAAANDgAAAAMLBAAAAEEBACAMARgAAAAAAAAEAAAAAAAAAAEDAAAAAAAAAQAAAAAGIQAAAAADAAABAgAKowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAsABBAASAAAAggECAAUDDQQAAABAAw4DDwYBAQEBAAEYAAMAAAAAABwAFwEAAAAAAuEcHyKmj49jE5DBSRLXso2RBAhW09h1Iw==

-- decompilation:
local HttpService = game:GetService("HttpService")

local function HTTP(t1: {[any]: any}) -- line: 32
	-- upvalues: HttpService (copy)
	local ok, result = pcall(function() -- line: 33
		-- upvalues: HttpService (copy), t1 (copy)
		return HttpService:RequestAsync(t1)
	end)

	if not ok or type(result) ~= "table" then
		return {
			Success = false,
			StatusCode = 400.0,
			Body = nil,
			TransportError = true,
			StatusMessage = tostring(result),
			Headers = {}
		}
	end

	return result
end

return HTTP

