-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBHdhcm4aJSoKU3RhY2sgQmVnaW4KJSpTdGFjayBFbmQIdG9zdHJpbmcFZGVidWcJdHJhY2ViYWNrBmZvcm1hdAxFcnJvckhhbmRsZXIGeHBjYWxsBVdDYWxsAAMIAQAAAAASpAEBAAAAAEBvAgIAuz8AA1IFAACkBAQAAAAwQJ8EAgKkBQcAABhQgMYGAACMBwMAnwUDArwCAo0IAAAAnwIEAp8BAgGCAAEACQMBBAAAAEADAgMDBAAAMEADBAMFBAAYUIADBgAUBwEYAAAAAAAAAAAAAAAAAAAAAAABFQAAAAAFAQEBAAcDAQAFAQUPCKMBAACkAQEAAAAAQFICAAD7AwAA3QQAAJ8BAACCAQAAAgMIBAAAAEAAGAkBGAABAAAAAAAAGAAAAAACAAABAwsAAAIPAAEEDwECAwWjAAAAwAAAAMABAQASAAAAggECAAIGAAYBAgABAQABGAATBAAEAQAAAAACdtrq4YISEdn7/SXMUwWIDQbC/ZVEHoDg

-- decompilation:
--!native
local function ErrorHandler(p1) -- line: 20
	warn(`{ tostring(p1) }\nStack Begin\n{ debug.traceback(nil, 3.0) }Stack End`)
end
local function WCall(p2: ((...any) -> ...any), ...) -- line: 24
	-- upvalues: ErrorHandler (copy)
	return xpcall(p2, ErrorHandler, ...)
end

return WCall

