-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBHR5cGUGbnVtYmVyLEdldEdhbWVwYXNzQnlJRDogZ2FtZXBhc3NJZCBtdXN0IGJlIGEgbnVtYmVyBmFzc2VydAVwYWlycwlQcm9kdWN0SWQFZXJyb3IaRHVwbGljYXRlIFByb2R1Y3Q6ICUqIC8gJSoGZm9ybWF0A19pZA9HZXRHYW1lcGFzc0J5SUQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUJRGlyZWN0b3J5CkdhbWVwYXNzZXMAAgwBAgAACgMAAQUBAgMIIwI5DgA2ALsoAANSBAAApAMBAAAAAECfAwIC8AMCAAIAAACpAgABqQIBAIEBAgQDAAAAbwMDAKQBBQAAAEBAnwEDAfsBAAArARsA/wEAAAAAAACkAgcAAABgQPsDAQCfAgIEFwIRAE0IBgsIAAAAhwcBCA4HCgCkBwoAAACQQG8ICwBSCgUATQsGCwgAAAC8CAiNDAAAAJ8IBACfBwABTQcGCwgAAABqBgEHbgLu/wIAAADeAQAA+wIAAIcBAgAOAQQAUgIBAE0DAdMNAAAAggIDAMYCAADGAwAAggIDAMYBAACCAQIADgMBBAAAAEADAgMDAwQEAABAQAMFBAAAYEADBgMHBAAAkEADCAMJAwoACgsBGAABAAAAAAAAAAAAAAAAAAACAAEAAQAAAAABAAAAAQAAAAAAAAAAAAIAAPwABgIAAQEAAAACAAADAAsAAAAABQAAAQIAFqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAJEGAAAATQICPAcAAACfAQICTQIBkQYAAADGAwAA2QQAABIBA/8SAAIAwQMAAIIEAgAIAwwEAAAAQAMNAw4DDwQAAEBAAxADEQEAAQABGAACAAAAAAACAAAAAAAAAQACAgAAGQABAAAAAAEBycoACWHgYSmrwcr344+scdHddDMNoAE=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Directory = require(ReplicatedStorage.Directory.Gamepasses).Directory
local u3 = nil

local function GetGamepassByID(n1: number) -- line: 10
	-- upvalues: u3 (ref), Directory (copy)
	if n1 then
		assert(type(n1) == "number", "GetGamepassByID: gamepassId must be a number")

		if not u3 then
			local t1 = {}

			for k, v in pairs(Directory) do
				if t1[v.ProductId] then
					error(`Duplicate Product: { k } / { v.ProductId }`)
				end

				t1[v.ProductId] = v
			end

			u3 = t1
		end

		local v9 = u3[n1]

		if v9 then
			return v9, v9._id
		end

		return nil, nil
	end

	return nil
end

return GetGamepassByID

