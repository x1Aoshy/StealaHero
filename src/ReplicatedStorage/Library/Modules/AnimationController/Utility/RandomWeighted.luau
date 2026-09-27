-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIBndlaWdodARtYXRoBnJhbmRvbQRhbmltB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwACCwEAAAAGAwAABQEEKIwBAACMBAEAHAIAAIwDAQCoAgYAhwUABE0HBcsBAAAAkAYHAEMBAQaLAvr/pAMEAAAMIICfAwECCQIDAYwDAACMBgEAHAQAAIwFAQCoBA0AhwcABk0JB8sBAAAAkAgJAEMDAwh9AgYAAwAAAE0IBy4FAAAAHAkAAFIKBwCCCAQAiwTz/xwFAACHBAAFTQUELgUAAAAcBgAAUgcEAIIFBAAGAgAAAAAAAPA/AwEDAgMDBAAMIIADBAADAAEYAAIAAAABAgAAAP0GAAAAAQIAAAABAgAAAAEAAQAAAAD7CQACAAAAAAQAAAAAAgAAAQIADqMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BAe8FAAAAnwACAsABBgCCAQIABwMFBAAAAEADBgQAACBAAwcDCAYAAQABAAEYAAAAAAAAAAAAAAAAAgABAAAAAAHwz4qMMMJVgINo8POnrQeDgNed+MIL4I0=

-- decompilation:
require(script.Parent.Parent.Types)

return function(t1: {[any]: any}) -- line: 3
	local n1 = 0.0

	for i = 1.0, #t1 do
		n1 += t1[i].weight or 1.0
	end

	local v4 = math.random() * n1
	local n2 = 0.0

	for i = 1.0, #t1 do
		local v7 = t1[i]

		n2 += v7.weight or 1.0

		if v4 <= n2 then
			return v7.anim, #t1, v7
		end
	end

	local v8 = t1[#t1]

	return v8.anim, #t1, v8
end

