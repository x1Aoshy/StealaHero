-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMDBG1hdGgFcm91bmQScm91bmRUb05lYXJlc3RGaXZlAAIEAQAAAAYDAAAFAQIXDQADAAAAAICMAQAAggECAD4DAAG7MAMCpAIEAAAMIICfAgICWwECAQ0BCwAAAACAjAIAAGACAwAAAAAAjAIFAIICAgCMAgAAYAADAAIAAACMAvv/ggICAIIBAgAFAgAAAAAAAAAAAgAAAAAAABRAAwEDAgQADCCAAAMDARgAAAEAAwAAAAAAAQABAAABAAEAAAEABAQAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAACEQEAAAAAAQ==

-- decompilation:
local function roundToNearestFive(n1: number) -- line: 3
	if n1 == 0.0 then
		return 0.0
	end

	local v3 = math.round(n1 / 5.0) * 5.0

	if v3 == 0.0 then
		if n1 > 0.0 then
			return 5.0
		end

		if n1 < 0.0 then
			return -5.0
		end
	end

	return v3
end

return roundToNearestFive

