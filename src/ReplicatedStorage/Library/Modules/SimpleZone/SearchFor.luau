-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUAV8Fc3BsaXQFdGFibGUGY29uY2F0FnNwbGl0UmVjdXJzaXZlUHJvcGVydHkGUGFyZW50CVNlYXJjaEZvcg5GaW5kRmlyc3RDaGlsZANUYWcGSGFzVGFnCkF0dHJpYnV0ZV8FbWF0Y2gMR2V0QXR0cmlidXRlD3Byb3BlcnR5Q2hlY2tlcgJPcgZpbnNlcnQDQW5kDmNoZWNrQ29uZGl0aW9uEkJhZCBtb2RlIGFyZ3VtZW50LgZhc3NlcnQABQgBAAAABgMAAAUBAxNvAwAAvAEA4wEAAACfAQMCEwABAFICAACpAwAAHAQBAIwFAQBgBQgABAAAAKQDBAAADCCAUgQBAG8FAACMBgIAHAcBAJ8DBQKCAgMABQMBAwIDAwMEBAAMIIAAAQUBGAAAAAACAgAAAAAAAAAAAAAAAAACAAAAABIEAAAAAHJSBAMAxgUAAMYGAABkBGsAUgsHAG8OAAC8DAvjAQAAAJ8MAwITCwwAUgkLAKkKAAAcDQwAjA4BAGAOCQANAAAApA0EAAAMIIBSDgwAbw8AAIwQAgAcEQwAnw0FAlIKDQDwCRUABQAAgA4KEwA1CwDEBgAAAP8MAAABAAAATQ0AJAUAAADFDA0CAQAAAP8NAQAAAAAAaggNClIOAQCfCwQCUgwCAE0OACQFAAAAhw0LDp8MAgFlAEEAUg0JALwLAAMHAAAAnwsDAg4LFgAOChUANQsAxAYAAAD/DAAAAQAAAFIPCQC8DQADBwAAAJ8NAwDFDA0AAQAAAP8NAQAAAAAAaggNClIOAQCfCwQCUgwCAE0OACQFAAAAhw0LDp8MAgFlACYA8AgIAAgAAIBSCwIAUg4JALwMAN4JAAAAnwwDAJ8LAAFlAB0Abw0KALwLCecLAAAAnwsDAg4LEQBvDgAAvAwJ4wEAAACfDAMCEwsMAVIPCwC8DQASDAAAAJ8NAwLxDQIACAAAAKkMAAGpDAEAUg0CAFIODACfDQIBZQAHAFILAgCHDQAJ8Q0CAAgAAACpDAABqQwBAJ8LAgFuBJT/AgAAAIIAAQANAwEDAgMDAwQEAAwggAMGAwcDCAMJAwoDCwMMAw0ACQ4BGAgAAAAB9wAAAAICAAAAAAAAAAAAAAAAAAgAAAEAAAAAAAAAAAAAAAABAAAAAAEDAAAAAAABAAAAAAAAAAAAAAAAAAABAAAAAAEDAAEAAAAAAAEDAAAAAAEAAAAAAgAAAAAAAAACAAABAwAAAAAAAOIAIAIAAAAABAEEAAAAEw4ACwD7AQAA8AEJAAAAAID7AgEA+wMCAJ40AgMDAAAApAEDAAAIEICfAQMBggABACsABQD7AQAA8AEDAAQAAICpAQEA3gEDAIIAAQAFAw8DAwMQBAAIEIADEQA0EgEYAAAAAAEAAAAAAAAAAQAAAAEAAjUAAAAAEAMBAAAIBQAABQMPBAMwqQQAAEcCCAAAAAAAqQQBAPACBQAAAAAA8AICAAEAAACpBAABqQQBAIEBBAQCAAAAbwUCAKQDBAAAADBAnwMDAf8DAAAAAAAAUgQAAMYFAADGBgAAZAQXAKkJAADZCgAAEgACABIAAwASAAgAEgEJ//sLAABSDAgAUg0CAFIOCgBSDwEAnwsFASsJCQDwAggAAQAAgJ40AwUIAAAAUgwDAFINCACkCwcAABhQgJ8LAwHBCQAAbgTo/wIAAACCAwIACAMPAxEDEwMUBAAAMEADAwMQBAAYUIABAiwHARgAAAAAAAAAAAAAAAAAAAAAAgACAAAAAQIAAAAACAAAAAAAAgAAAQAAAAAAAADyABEtAAAAAAMAAAECAAqjAAAAwAAAAMABAQDAAgIAEgABABgCAMQDAAAANQIAxAMAAACCAgIABAYABgEGAwMHAwABAwEAARgAAAgjAAAAGQAAAQAAAAAE0Q2M0dDEUsxtdZdddjXPHqEVm6XjyebQ

-- decompilation:
local function splitRecursiveProperty(s1: string) -- line: 1
	local parts = s1:split("_")

	return parts[1.0], #parts > 1.0 and table.concat(parts, "_", 2.0, #parts)
end
local function propertyChecker(p1, p2, p3, p4) -- line: 9
	for v9, v10 in p4 do
		local parts = v9:split("_")
		local v12 = parts[1.0]
		local v13 = #parts > 1.0 and table.concat(parts, "_", 2.0, #parts)

		if v12 == "Parent" and v13 then
			p3(SearchFor({ p1.Parent }, {
				[v13] = v10
			}, p2)[p1.Parent])
		elseif p1:FindFirstChild(v12) and v13 then
			p3(SearchFor({ p1:FindFirstChild(v12) }, {
				[v13] = v10
			}, p2)[p1.Parent])
		elseif v10 == "Tag" then
			p3(p1:HasTag(v12))
		elseif v12:match("Attribute_") then
			p3(v10 == p1:GetAttribute(v12:split("_")[2.0]))
		else
			p3(v10 == p1[v12])
		end
	end
end

function SearchFor(p5, t1: {[any]: any}, s2: string) -- line: 44
	-- upvalues: propertyChecker (copy)
	assert(s2 ~= nil and (s2 == "Or" or s2 == "And"), "Bad mode argument.")

	local t2 = {}

	for _, v19 in p5 do
		local u20 = false

		local function checkCondition(p6) -- line: 52
			-- upvalues: s2 (copy), t2 (copy), v19 (copy), u20 (ref)
			if p6 and s2 == "Or" then
				table.insert(t2, v19)

				return
			end

			if not p6 and s2 == "And" then
				u20 = true
			end
		end

		propertyChecker(v19, s2, checkCondition, t1)

		if not u20 and s2 == "And" then
			table.insert(t2, v19)
		end
	end

	return t2
end

return SearchFor

