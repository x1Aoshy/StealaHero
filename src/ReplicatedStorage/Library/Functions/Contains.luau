-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMBBXBhaXJzAAIJAgAAAAAPpAIBAAAAAEBSAwAAnwICBBcCBgBSBwEAUggGAJ8HAgIOBwIAqQcBAIIHAgBuAvn/AgAAAKkCAACCAgIAAgMBBAAAAEAAAQABGAAAAAAAAQAAAAEA/gAFAAIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAQ==

-- decompilation:
return function(p1, p2) -- line: 1
	for _, v in pairs(p1) do
		if p2(v) then
			return true
		end
	end

	return false
end

