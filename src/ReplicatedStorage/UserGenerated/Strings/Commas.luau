-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTBHR5cGUGc3RyaW5nBW1hdGNoE14oLi0pKFswLTksXSspKC4qKSQFdGFibGUGaW5zZXJ0BGdzdWIBLAADc3ViBmNvbmNhdAZDb21tYXMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUNVXNlckdlbmVyYXRlZAdTdHJpbmdzE1RyaW1tZWROdW1iZXJTdHJpbmcAAg8BAQAAIAABBw8DAQBmDwIOWA8DDlgPBA5YDwUVUQIGJkACByc/ZsYBAAC7KAADUgMAAKQCAQAAAABAnwICAvACAwACAACAUgEAAGUABAD7AgAAUgMAAJ8CAgJSAQIApAIEAAAMIIBSAwEAbwQFAJ8CAwQrAwEAggECAP8FAAAAAAAADgIHAJ40BQUCAAAAUgcFAFIIAgCkBggAABxggJ8GAwGkBgoAACQggFIHAwBvCAsAbwkMAJ8GBAJSAwYAjAYBABwIAwAhBwgNjAgAAGAIEQAHAAAAQw4GB3gNDg40LQMFBg0AAFILAwBSDAYApAoQAAA8IICfCgQCnjQFBAoAAABSCQUApAgIAAAcYICfCAMBQwYGBxwIAwB9BhsACAAAAIwIAQBgCAgABgAAAIE0BQULAAAAUgkFAG8KCwCkCAgAABxggJ8IAwGVDQYRNC0DBQYNAABSCwMAUgwGAKQKEAAAPCCAnwoEAp40BQQKAAAAUgkFAKQICAAAHGCAnwgDAZUGBg1IAOP/DgQHAJ40BQUEAAAAUgkFAFIKBACkCAgAABxggJ8IAwGkCBMAAEhggFIJBQCfCAIAgggAABQDAQQAAABAAwIDAwQADCCAAwQDBQMGBAAcYIADBwQAJCCAAwgDCQIAAAAAAAAIQAIAAAAAAADwPwMKBAA8IIACAAAAAAAAAEADCwQASGCAACMMARgAAQAAAAAAAAEAAgAAAAIAAAAAAQECAAEBAAAAAAAAAgAAAAAAAAEBAAEAAAEAAAAAAAAAAAAAAAAAAAECAAABAAABAAAAAAAAAgAAAAAAAAAAAAAAAAAB+wcBAAAAAAAAAgAAAAAkAAAAAAMAAAEDDwAAAw8AARIPAQcMDwIQAxOjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgDgBgAAAE0CAh8HAAAATQICnQgAAACfAQICwAIJABIAAQCCAgIACgMNBAAAAEADDgMPAxAEAABAQAMRAxIDEwYAAQABAAEYABMAAAAAAAIAAAAAAAAAAA0AIwEAAAAAAUibRH753araDyskJlBb5BM4g1MKel8ufw==

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrimmedNumberString = require(ReplicatedStorage.UserGenerated.Strings.TrimmedNumberString)

local function Commas(p1) -- line: 35
	-- upvalues: TrimmedNumberString (copy)
	local v5 = if type(p1) ~= "string" then TrimmedNumberString(p1) else p1
	local v6, v7, v8 = string.match(v5, "^(.-)([0-9,]+)(.*)$")

	if not v7 then
		return v5
	end

	local t1 = {}

	if v6 then
		table.insert(t1, v6)
	end

	local v10 = string.gsub(v7, ",", "")
	local n1 = 1.0
	local v12 = #v10 % 3.0

	if v12 > 0.0 then
		table.insert(t1, (string.sub(v10, n1, n1 + v12 - 1.0)))
		n1 += v12
	end

	while n1 <= #v10 do
		if n1 > 1.0 then
			table.insert(t1, ",")
		end

		table.insert(t1, (string.sub(v10, n1, n1 + 2.0)))
		n1 += 3.0
	end

	if v8 then
		table.insert(t1, v8)
	end

	return table.concat(t1)
end

return Commas

