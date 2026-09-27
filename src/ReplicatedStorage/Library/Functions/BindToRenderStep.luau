-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFFFVuYmluZEZyb21SZW5kZXJTdGVwEEJpbmRUb1JlbmRlclN0ZXAEZ2FtZQpSdW5TZXJ2aWNlCkdldFNlcnZpY2UAAwMAAgAAAAb7AAAA+wIBALwAACcAAAAAnwADAYIAAQABAwEABQABGAAAAAAAAQYAAAAACAMBAAAIBQAABQMDAgUL+wMAAFIFAABSBgEAUgcCALwDA28AAAAAnwMFAdkDAAASAgAAEgAAAIIDAgABAwIBAAMAARgAAAAAAAAAAQAAAAQAAAAAAwAAAQIACqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLAAQQAEgAAAIIBAgAFAwMEAAAAQAMEAwUGAQEBAQABGAAAAAAAAAACAAABAAAAAALezmvuyho/cgaC3ptDWz6IrtZ8muwKAe8=

-- decompilation:
local RunService = game:GetService("RunService")

return function(s1: string, n1: number, p1: ((...any) -> ...any)) -- line: 3
	-- upvalues: RunService (copy)
	RunService:BindToRenderStep(s1, n1, p1)

	return function() -- line: 5
		-- upvalues: RunService (copy), s1 (copy)
		RunService:UnbindFromRenderStep(s1)
	end
end

