-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFBmlwYWlycwtHZXRDaGlsZHJlbglHdWlPYmplY3QDSXNBB0Rlc3Ryb3kAAgkBAAAAABKkAQEAAAAAQLwCAGgCAAAAnwICAJ8BAARRAQgAbwgDALwGBf4EAAAAnwYDAg4GAwC8BgVQBQAAAJ8GAgFuAff/AgAAgIIAAQAGAwEEAAAAQAMCAwMDBAMFAAEAARgAAAAAAAAAAQAAAAABAAD+AAUCAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAE=

-- decompilation:
return function(p1) -- line: 1
	for _, child in ipairs(p1:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

