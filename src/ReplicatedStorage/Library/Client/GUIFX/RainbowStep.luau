-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEBkNvbG9yMwdmcm9tSFNWBG1hdGgGcmFuZG9tAAMFAQIAAAYDAAAFAQIN+wEAAPsDAQAJAgADQwEBAt4BAACkAQIAAAQAgPsDAAAhAgMDjAMBAIwEAQCfAQQAggEAAAQDAQMCBAAEAIACAAAAAAAA8D8ACwABGAAAAAAAAQAAAAAAAAAMAAAAAAUCAAAABwQAAAUCgoILkAIAAFIDAQArAwMApAMDAAAIEICfAwEC2QQAABIBA/8SAAIAwQMAAIIEAgAEAgAAAAAAAPA/AwMDBAQACBCAAQAHAAEYAAEAAAAAAgAAAAAIAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgEBAQEAARgABgABAAAAAAKkKvf8R51DgFz6LTalHAVi1DLgiJbunf0=

-- decompilation:
return function(n1: number?, n2: number?) -- line: 7
	local v3 = n1 or 1.0
	local u4 = n2 or math.random()

	return function(n3: number) -- line: 11
		-- upvalues: u4 (ref), v3 (copy)
		u4 += n3 * v3

		return Color3.fromHSV(u4 % 1.0, 1.0, 1.0)
	end
end

