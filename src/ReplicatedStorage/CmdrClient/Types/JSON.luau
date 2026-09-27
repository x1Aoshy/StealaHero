-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBXBjYWxsCkpTT05EZWNvZGUIVmFsaWRhdGUFUGFyc2UEanNvbgxSZWdpc3RlclR5cGUEZ2FtZQtIdHRwU2VydmljZQpHZXRTZXJ2aWNlAAQFAQEAAAAJpAEBAAAAAED7AgAATQICywIAAAD7AwAAUgQAAJ8BBACCAQAAAwMBBAAAAEADAgAFAwEYAAAAAAAAAAAABgAAAAAEAQEAAAAG+wEAAFIDAAC8AQHLAAAAAJ8BAwCCAQAAAQMCAAkEARgAAAAAAAAKAAAAAAYBAQAAAA5vAwAA4gQDAMAFBAASAgAAMAUEdgEAAADABQUAEgIAADAFBJsCAAAAvAEA3QYAAACfAQQBggABAAcDBQMDAwQFAgECBgAGAQMGAgABAwABGAAAAQAAAAQAAAD7AAAJBAAAAAADAAABAgAKowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAsABBAASAAAAggECAAUDBwQAAABAAwgDCQYCAQIBAAEYAAAAAAAAAAIAAAEAAAAAA5LIGJ9wFcXDs5vwQ/WzvHri0A/roAxyng==

-- decompilation:
local HttpService = game:GetService("HttpService")

return function(p1) -- line: 3
	-- upvalues: HttpService (copy)
	p1:RegisterType("json", {
		Validate = function(p2) -- line: 5
			-- upvalues: HttpService (copy)
			return pcall(HttpService.JSONDecode, HttpService, p2)
		end,
		Parse = function(p3) -- line: 9
			-- upvalues: HttpService (copy)
			return HttpService:JSONDecode(p3)
		end
	})
end

