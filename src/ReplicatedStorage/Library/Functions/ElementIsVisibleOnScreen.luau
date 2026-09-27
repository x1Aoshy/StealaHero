-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFBlBhcmVudAlTY3JlZW5HdWkDSXNBB0VuYWJsZWQHVmlzaWJsZQACBAEAAAAGAwAABQEHFw4AFABNAQAkAAAAAA4BEQBvAwEAvAEA/gIAAACfAQMCDgEDAE0BAPADAAAAggECAE0BAIAEAAAAKgEDAAAAAICpAQAAggECAE0AACQAAAAASADr/6kBAACCAQIABQMBAwIDAwMEAwUAAQABGAAAAAABAAAAAAEAAAIAAAABAAIA+QkAAgAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAAB

-- decompilation:
return function(p1) -- line: 1
	while p1 and p1.Parent do
		if p1:IsA("ScreenGui") then
			return p1.Enabled
		end

		if p1.Visible == false then
			return false
		end

		p1 = p1.Parent
	end

	return false
end

