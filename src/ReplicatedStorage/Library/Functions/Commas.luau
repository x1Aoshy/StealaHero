-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNBHR5cGUGbnVtYmVyBmFzc2VydANOYU4ISW5maW5pdHkJLUluZmluaXR5AAEtBG1hdGgFcm91bmQIdG9zdHJpbmcDc3ViASwAAg0BAAAAAEy7KAADUgQAAKQDAQAAAABAnwMCAvADAgACAAAAqQIAAakCAQC7AQICpAEEAAAAMECfAQIB8QADAAAAAABvAQUAggECAA0AAwAGAACAbwEHAIIBAgANAAMACAAAgG8BCQCCAQIAbwEKAIwCAABgAAMAAgAAAG8BCwA5AAAAuzAAA1IDAACkAg4AADTAgJ8CAgK7PwIDUgQCAKQDEAAAAPBAnwMCAowEAQAcBgMAIQUGEVIGAQCMBwAAYAcKAAUAAABSBwYAUgoEAEMMBAV4CwwSvAgD8BMAAACfCAQCcwYHCEMEBAUcBwMAfQQQAAcAAACMBwEAYAcEAAQAAABSBwYAbwgUAHMGBwhSBwYAUgoEAJULBBW8CAPwEwAAAJ8IBAJzBgcIlQQEEUgA7v+CBgIAFgMBBAAAAEADAgMDBAAAMEADBAIAAAAAAADwfwMFAgAAAAAAAPD/AwYDBwMIAwkDCgQANMCAAwsEAADwQAIAAAAAAAAIQAIAAAAAAADwPwMMAw0CAAAAAAAAAEAAAQABGAAAAAAAAAAAAAAAAAABAAEAAgABAAIAAQADAQAAAQEDAAAAAAEAAAAAAQEAAQEAAAEAAAAAAAAAAQIAAAEAAAEAAAIAAAAAAAAB+wcCAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAHN9h0VMotdrpXlnXioZDzBve4KYf8ydxQ=

-- decompilation:
return function(p1) -- line: 1
	assert(type(p1) == "number")

	if p1 ~= p1 then
		return "NaN"
	end

	if p1 == 1e999 then
		return "Infinity"
	end

	if p1 == -1e999 then
		return "-Infinity"
	end

	local s1 = ""

	if p1 < 0.0 then
		s1 = "-"
		p1 = -p1
	end

	local str = tostring((math.round(p1)))
	local n1 = 1.0
	local v5 = #str % 3.0

	if v5 > 0.0 then
		s1 ..= str:sub(n1, n1 + v5 - 1.0)
		n1 += v5
	end

	while n1 <= #str do
		if n1 > 1.0 then
			s1 ..= ","
		end

		s1 ..= str:sub(n1, n1 + 2.0)
		n1 += 3.0
	end

	return s1
end

