-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBHR5cGUGbnVtYmVyBnN0cmluZwVtYXRjaBRecmJ4YXNzZXRpZDovLyglZCspJCpeaHR0cDovL3d3dyUucm9ibG94JS5jb20vYXNzZXQvJT9pZD0oJWQrKSQIdG9udW1iZXIEbWF0aAVmbG9vcgACBQEAAAAAKsYBAAC7KAADUgMAAKQCAQAAAABAnwICAvACAwACAACAUgEAAGUAEgCkAgUAABAwgFIDAABvBAYAnwIDAisCBQCkAgUAABAwgFIDAABvBAcAnwIDAg4CBgC7PgIDUgQCAKQDCQAAAIBAnwMCAlIBAwAOAQwAuwwBA1IDAQCkAgwAACyggJ8CAgKaAgUAAQAAAA0BAwANAAAADQECAA4AAIDGAQAAggECAA8DAQQAAABAAwIDAwMEBAAQMIADBQMGAwcEAACAQAMIAwkEACyggAIAAAAAAADwfwIAAAAAAADw/wABAAEYAAEAAAAAAAABAAIAAAAAAAEAAAAAAQEAAAAAAAMBAAAAAAAAAAAAAAEDAgAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAABvHGpe22YFeN387w+WgyNasxpvg+OtcN6

-- decompilation:
return function(p1) -- line: 1
	local v2 = nil

	if type(p1) == "number" then
		v2 = p1
	else
		local v3 = string.match(p1, "^rbxassetid://(%d+)$") or string.match(p1, "^http://www%.roblox%.com/asset/%?id=(%d+)$")

		if v3 then
			v2 = tonumber(v3)
		end
	end

	if v2 and (v2 ~= math.floor(v2) or v2 == 1e999 or v2 == -1e999) then
		v2 = nil
	end

	return v2
end

