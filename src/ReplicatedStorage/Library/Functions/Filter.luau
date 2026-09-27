-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMBBXBhaXJzAAIKAgAAAAAP/wIAAAAAAACkAwEAAAAAQFIEAACfAwIEFwMFAFIIAQBSCQcAnwgCAg4IAQBqBwIGbgP6/wIAAACCAgIAAgMBBAAAAEAAAQABGAAAAQAAAAABAAAAAf4ABQIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAQ==

-- decompilation:
return function(p1, p2) -- line: 1
	local t1 = {}

	for k, v in pairs(p1) do
		if p2(v) then
			t1[k] = v
		end
	end

	return t1
end

