-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBXRhYmxlBmZyZWV6ZQR0eXBlCkRlZXBGcmVlemUFY2xvbmUIRGVlcENvcHkGRXh0ZW5kBE5vbmUIbmV3cHJveHkABAgBAQAABgMAAAUBBBekAQIAAAQAgFICAACfAQIBUgEAAMYCAADGAwAAZAEMALsoBQNSBwUApAYEAAAAMECfBgIC8AYGAAAAAID7BgAATQYG1gUAAABSBwUAnwYCAW4B8/8CAAAAggACAAYDAQMCBAAEAIADAwQAADBAAwQADgQBGAAAAAABAAAAAQAAAAAAAAEAAAAA/gAFDwAAAAAJAQEAAAYDAAAFAQQYpAECAAAEAIBSAgAAnwECAlICAQDGAwAAxgQAAGQCDQC7KAYDUggGAKQHBAAAADBAnwcCAvAHBwAAAACA+wcAAE0HB4UFAAAAUggGAJ8HAgJqBwEFbgLy/wIAAACCAQIABgMBAwUEAAQAgAMDBAAAMEADBgAZBgEYAAAAAAEAAAABAAAAAAAAAQAAAAAA/gAFGgAAAAALAgEAAAcEAAAFAgQEMvsCAABNAgKFAAAAAFIDAACfAgICUgMBAMYEAADGBQAAZAMmALsoBwNSCQcApAgCAAAAEECfCAIC8AgXAAMAAICHCQAGuygJAqQIAgAAABBAnwgCAvAICQADAACA+wgAAE0ICLwEAAAAhwkABlIKBwCfCAMCaggCBmUAEAD7CAAATQgIhQAAAABSCQcAnwgCAmoIAgZlAAkA+wgAAE0ICD8FAAAAmgcEAAgAAADGCAAAaggCBmUAAQBqBwIGbgPZ/wIAAACCAgIABgMGAwMEAAAQQAMBAwcDCAAlBwEYAAAAAAABAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAAIAAAAAAAACAAAAAAEAAAL2AA0mAAAAAAIAAAECABWjAAAA/wADAAAAAACkAQEAAAAAQJ8BAQIwAQA/AgAAAMABAwASAAAAMAEA1gQAAADAAQUAEgAAADABAIUGAAAAwAEHABIAAAAwAQC8CAAAAIIAAgAJAwkEAAAAQAMIBgADBAYBAwYGAgMHAwABAgEAARgACAACAAAAAAMAAAALAAAADAAAABIBAAAAAAPF36L/qP0OD0bot4lJ5Q5Ntce1i/cbyP4=

-- decompilation:
local t1 = {
	None = newproxy()
}

function t1.DeepFreeze(t2: {[any]: any}) -- line: 14
	-- upvalues: t1 (copy)
	table.freeze(t2)

	for _, v4 in t2 do
		if type(v4) == "table" then
			t1.DeepFreeze(v4)
		end
	end

	return t2
end
function t1.DeepCopy(t3: {[any]: any}) -- line: 25
	-- upvalues: t1 (copy)
	local v6 = table.clone(t3)

	for v7, v8 in v6 do
		if type(v8) == "table" then
			v6[v7] = t1.DeepCopy(v8)
		end
	end

	return v6
end
function t1.Extend(t4: {[any]: any}, t5: {[any]: any}) -- line: 37
	-- upvalues: t1 (copy)
	local v11 = t1.DeepCopy(t4)

	for v12, v13 in t5 do
		if type(v13) == "table" then
			if type(t4[v12]) == "table" then
				v11[v12] = t1.Extend(t4[v12], v13)
			else
				v11[v12] = t1.DeepCopy(v13)
			end
		elseif v13 == t1.None then
			v11[v12] = nil
		else
			v11[v12] = v13
		end
	end

	return v11
end

return t1

