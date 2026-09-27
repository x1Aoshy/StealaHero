-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBHR5cGUFdGFibGUEbmV4dBZEZWVwQ29weVdpdGhNZXRhdGFibGVzDGdldG1ldGF0YWJsZQxzZXRtZXRhdGFibGUAAg4CAAAAHwQABgUCD4QPCBYMDwkWDAQCCCoPAwwmDwQPIw8FJA4yuygAA1IDAACkAgEAAAAAQJ8CAgLwAgIAAgAAAIIAAgBSAgEAKwICAP8CAAAAAAAAhwMCAA4DAQCCAwIA/wQAAAAAAABqBAIApAUEAAAAMEBSBgAAxgcAABcFCwA1CgBqBQAAAFILCABSDAIAnwoDAjULAGoFAAAAUgwJAFINAgCfCwMCagsECm4F9P8CAAAAuzwAA1IGAACkBQcAAABgQJ8FAgIOBQcAnj0EBQUAAABSBwQAUggFAKQGCQAAAIBAnwYDAYIEAgAKAwEEAAAAQAMCAwMEAAAwQAMEAwUEAABgQAMGBAAAgEAAIQQBGAAAAAAAAAABBAAAAAQBAQQAAgMAAAAAAQAAAAAAAAAAAAD/AAUAAAAAAgEAAAAAAAADIwAAAAABAAABAwAHowAAAMAAAAAYAABqAQAAADUAAGoBAAAAggACAAIGAAMEAQABAAEYACAAACQAAAEAAAAAATiInDsuQyBdIaj/5PDKZjVIkItPCkz2Og==

-- decompilation:
--!native
function DeepCopyWithMetatables(p1, t1: {[any]: any}?) -- line: 33
	if type(p1) ~= "table" then
		return p1
	end

	local v3 = t1 or {}
	local v4 = v3[p1]

	if v4 then
		return v4
	end

	local t2 = {}

	v3[p1] = t2

	for k, v in next, p1 do
		t2[DeepCopyWithMetatables(k, v3)] = DeepCopyWithMetatables(v, v3)
	end

	local mt = getmetatable(p1)

	if mt then
		setmetatable(t2, mt)
	end

	return t2
end

return DeepCopyWithMetatables

