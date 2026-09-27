-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKBmlwYWlycwlLZXlwb2ludHMWTnVtYmVyU2VxdWVuY2VLZXlwb2ludANuZXcEVGltZQVWYWx1ZQhFbnZlbG9wZQV0YWJsZQZpbnNlcnQOTnVtYmVyU2VxdWVuY2UAAg8CAAAABwQAAAUCBwIf/wIAAAAAAACkAwEAAAAAQE0EAMICAAAAnwMCBFEDEABSCQIApAoFAAAQMIBNCwdKBgAAAE0NB+wHAAAACQwNAU0OBxAIAAAACQ0OAZ8KBABMNAACpAgLAAAokICfCAABbgPv/wIAAICkAw0AABDAgFIEAgCfAwIAggMAAA4DAQQAAABAAwIDAwMEBAAQMIADBQMGAwcDCAMJBAAokIADCgQAEMCAAAQAARgAAAEAAAAAAAIBAAAAAAAAAAAAAP4AAAD/AAYAAAAABQAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAMAAQAAAAABsvBGq6KpwFamiwcfAAofCcLoUd+ANCyq

-- decompilation:
return function(p1, n1: number) -- line: 4
	local t1 = {}

	for _, v in ipairs(p1.Keypoints) do
		table.insert(t1, NumberSequenceKeypoint.new(v.Time, v.Value * n1, v.Envelope * n1))
	end

	return NumberSequence.new(t1)
end

