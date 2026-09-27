-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBnR5cGVvZghJbnN0YW5jZQxXYWl0Rm9yQ2hpbGQORmluZEZpcnN0Q2hpbGQFdGFibGUKU2FmZV9JbmRleAR3YXJuPUZhaWxsZWQgdG8gZXhlY3V0ZSBkdWUgdG86IChCYXNlIG11c3QgYmUgYSB0YWJsZSBvciBJbnN0YW5jZSkGc3RyaW5nAXwFc3BsaXQ9RmFpbGxlZCB0byBleGVjdXRlIGR1ZSB0bzogKFBhdGggbXVzdCBiZSBhIHN0cmluZyBvciBhIHRhYmxlKQZudW1iZXIIZnVuY3Rpb24oUGF0aCBub3QgZm91bmQgYXQgc3RlcCAnJXMnLCB0cmFjZTogJyVzJwh0b3N0cmluZwVkZWJ1Zwl0cmFjZWJhY2sGZm9ybWF0BkV4ZV9HUwADBgMAAAAAGrssAANSBAAApAMBAAAAAECfAwIC8AMKAAIAAIAOAgIAbwQDAGUAAQBvBAQAhwMABFIEAABSBQEAnwMDAIIDAAC7LAADUgQAAKQDAQAAAABAnwMCAvADAwAFAACAhwMAAYIDAgCCAAEABgMBBAAAAEADAgMDAwQDBQABBgEYAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAABAAICAAAAABUHAAAAEQkAAQUHDw+CDw+FgQMRkgECmQG7LAADUggAAKQHAQAAAABAnwcCAvAHCQACAAAA8AcHAAMAAACkCAUAAABAQG8JBgCfCAIBxggAAIIIAgC7LAEDUgkBAKQIAQAAAABAnwgCAvAIBwAHAACAbwsIALwJAeMJAAAAnwkDAlIBCQBlAAgA8AgHAAMAAACkCQUAAABAQG8KCgCfCQIBxgkAAIIJAgC7LAIDUgsCAKQKAQAAAABAnwoCAvAKAwALAACAUgkCACsJAQCMCQEAUgIJAFIJAAC7LAUDUgwFAKQLAQAAAABAnwsCAvALAgAMAAAAqQoAAakKAQBSDQIAHAsBAIwMAQCoC1sAhw4BDQ4KBQBSDwUAUhAJAFIRAQBSEg0Anw8EARwQAQDxDQIAEAAAAKkPAAGpDwEADg8gAA4DAQBqBAkOUhEJALssEQNSExEApBIBAAAAAECfEgIC8BILAAIAAIAOBgIAbxMNAGUAAQBvEw4AhxIRE1ITEQBSFA4AnxIDAlIQEgBlAAoAuywRA1ITEQCkEgEAAAAAQJ8SAgLwEgMAAwAAgIcQEQ5lAAEAxhAAAFIRDgCCEAMAUhAJALssEANSEhAApBEBAAAAAECfEQIC8BELAAIAAIAOBgIAbxINAGUAAQBvEg4AhxEQElISEABSEw4AnxEDAlIJEQBlAAoAuywQA1ISEACkEQEAAAAAQJ8RAgLwEQMAAwAAgIcJEA5lAAEAxgkAACsJEACkEAUAAABAQG8RDwC7Pw4DUhQOAKQTEQAAAABBnxMCAqQUFAAATCCBnxQBALwREY0VAAAAnxEAAJ8QAACCEAAAiwul/4IAAQAWAwEEAAAAQAMCAwUDBwQAAEBAAwgDCQMKAwsDDAMNAw4DAwMEAw8DEAQAAABBAxEDEgQATCCBAxMACRQBGBEAAAAAAQAAAAEAAAABAAQAAAAAAQABAAAAAAABAAEAAAABAAQAAAAAAAAAAAAAAwEAAAAAAAAAAAMAAAABAgEAAAAAAwAAAAABAQECzAAAAAAAAAEAAAAAAAAAAAABAAAAAAAAAQAAMQADyQAAAAAAAAEAAAAAAAAAAAABAAAAAAAAAQAANQEAAQAAAAAAAAAAAAAA/wDvFwIAAAAAAgAAAQIABKMAAADAAAAAwAEBAIIBAgACBgAGAQIAAQEAARgAAAg6AQAAAAACHcrWb9PzQ/CqpwWwYdb6N23SwRsvDrxu

-- decompilation:
local function Safe_Index(p1, p2, p3) -- line: 1
	if typeof(p1) == "Instance" then
		return p1[not p3 and "FindFirstChild" or "WaitForChild"](p1, p2)
	end

	if typeof(p1) == "table" then
		return p1[p2]
	end
end
local function Exe_GS(p4, p5, n1: number?, p6, p7, p8: ((...any) -> ...any)?, b1: boolean?) -- line: 9
	local v13 = typeof(p4)

	if v13 ~= "Instance" and v13 ~= "table" then
		warn("Failled to execute due to: (Base must be a table or Instance)")

		return nil
	end

	local v14 = typeof(p5)

	if v14 == "string" then
		p5 = p5:split("|")
	elseif v14 ~= "table" then
		warn("Failled to execute due to: (Path must be a string or a table)")

		return nil
	end

	local v15 = typeof(n1) == "number" and n1 or 1.0
	local v16 = typeof(p8) == "function"

	for i = v15, #p5 do
		local v18 = p5[i]

		if v16 then
			p8(p4, p5, i)
		end

		if i == #p5 then
			if p6 then
				p4[v18] = p7
			end

			return if typeof(p4) ~= "Instance" then if typeof(p4) ~= "table" then nil else p4[v18] else p4[not b1 and "FindFirstChild" or "WaitForChild"](p4, v18), v18
		end

		p4 = if typeof(p4) ~= "Instance" then if typeof(p4) ~= "table" then nil else p4[v18] else p4[not b1 and "FindFirstChild" or "WaitForChild"](p4, v18)

		if not p4 then
			return warn(("Path not found at step '%s', trace: '%s'"):format(tostring(v18), debug.traceback()))
		end
	end
end

return Exe_GS

