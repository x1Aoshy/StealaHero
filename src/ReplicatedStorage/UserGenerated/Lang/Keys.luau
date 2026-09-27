-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEBXBhaXJzBXRhYmxlBmluc2VydARLZXlzAAIKAQAAABIDAAMFAQQHBQYIBwYGCA8BABER/wEAAAAAAACkAgEAAAAAQFIDAACfAgIEFwIHAJ40AQUFAAAAUggBAFIJBQCkBwQAAAwggJ8HAwFuAvj/AgAAAIIBAgAFAwEEAAAAQAMCAwMEAAwggAAUBAEYAAABAAAAAAEAAAAAAAD/AAMVAAAAAAEAAAEDBwAAAQ8AAQIDowAAAMAAAACCAAIAAQYAAQABAAEYABMIAQAAAAAB

-- decompilation:
--!native
local function Keys(t1: {[any]: any}) -- line: 20
	local t2 = {}

	for k, _ in pairs(t1) do
		table.insert(t2, k)
	end

	return t2
end

return Keys

