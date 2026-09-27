-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMBHdhcm4aJSoKU3RhY2sgQmVnaW4KJSpTdGFjayBFbmQIdG9zdHJpbmcFZGVidWcJdHJhY2ViYWNrBmZvcm1hdAxFcnJvckhhbmRsZXIGeHBjYWxsBWVycm9yBnNlbGVjdAZIYW5kbGUHRmluYWxseQAECAEAAAAAEqQBAQAAAABAbwICALs/AANSBQAApAQEAAAAMECfBAICpAUHAAAYUIDGBgAAjAcDAJ8FAwK8AgKNCAAAAJ8CBAKfAQIBggABAAkDAQQAAABAAwIDAwQAADBAAwQDBQQAGFCAAwYAFAcBGAAAAAAAAAAAAAAAAAAAAAAAARUAAAAABgIBAQAIBAEABQIFAQ8SowIAAKQCAQAAAABAUgMAAPsEAACfAgMBKwEJAKQCAwAAACBAjAQBALs5BAOkAwUAAABAQN0FAACfAwACnwICAd0CAACCAgAABgMIBAAAAEADCQQAACBAAwoEAABAQAAYCwEYAAEAAAAAAQEAAAAAAAAAAAIAGAAAAAAIAgIBAAkEAgAFAgUFDw8LowIAAPsCAABSAwEApAQBAAAAAEBSBQAA+wYBAN0HAACfBAAAnwIAAIICAAACAwgEAAAAQAAgDAEYAAEAAAAAAAAAAAAgAAAAAAMAAAEDDwAAAw8AAQcPAQIGDwIEBAijAAAAwAAAAMABAQASAAAAwAICABIAAQASAAAAggICAAMGAAYBBgIDAAECAQABGAATBAAIAAAEAQAAAAADnm9F4MOwaKt0H8iPhgZAS+53UpSsqy/h

-- decompilation:
--!native
local function ErrorHandler(p1) -- line: 20
	warn(`{ tostring(p1) }\nStack Begin\n{ debug.traceback(nil, 3.0) }Stack End`)
end
local function Handle(p2: ((...any) -> ...any), b1: boolean, ...) -- line: 24
	-- upvalues: ErrorHandler (copy)
	xpcall(p2, ErrorHandler)

	if not b1 then
		error((select(1.0, ...)))
	end

	return ...
end
local function Finally(p3: ((...any) -> ...any), p4: ((...any) -> ...any), ...) -- line: 32
	-- upvalues: Handle (copy), ErrorHandler (copy)
	return Handle(p4, xpcall(p3, ErrorHandler, ...))
end

return Finally

