-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMCBXRhYmxlBmluc2VydAACBgMAAAAIBQAABQMEDwINHAMAAGADCQACAAAAnjQABQEAAABSBAAAUgUBAKQDAgAABACAnwMDAYIAAQBqAQACggABAAMDAQMCBAAEAIAAAQABGAAAAAEAAAAAAAABAgECAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAE=

-- decompilation:
return function(t1: {[any]: any}, p1, n1: number) -- line: 1
	if n1 > #t1 then
		table.insert(t1, p1)

		return
	end

	t1[n1] = p1
end

