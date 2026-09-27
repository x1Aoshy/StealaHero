-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBnR5cGVvZgV0YWJsZQxnZXRtZXRhdGFibGUMc2V0bWV0YXRhYmxlBWNsZWFyCERlZXBDb3B5AAIUBgEAAABYuywAA1IHAACkBgEAAAAAQJ8GAgLwBgIAAgAAAIIAAgBSBgQAKwYCAP8GAAAAAAAAUgQGAIcGBAAOBgEAggYCALssAQNSCQEApAgBAAAAAECfCAIC8AgDAAIAAIBSBwEAKwcCAP8HAAAAAAAAagcEAFIIAADGCQAAxgoAAGQIHQC7LAMDUg4DAKQNAQAAAABAnw0CAvANBAACAACADgICAIcNAwsrDRMAuywMA1IODACkDQEAAAAAQJ8NAgLwDQwAAgAAgCsCCgD7DQAAUg4MAMYPAABSEAIAUhEDAFISBACpEwEAnw0HAmoNBwtlAAEAagwHC24I4v8CAAAAuzwAA1IJAACkCAQAAAAwQJ8IAgK7LAgDUgoIAKQJAQAAAABAnwkCAvAJCAACAACAnj0HBQgAAABSCgcAUgsIAKQJBgAAAFBAnwkDASsFBACkCQgAABwggFIKBACfCQIBggcCAAkDAQQAAABAAwIDAwQAADBAAwQEAABQQAMFBAAcIIAAAQYBGAAAAAAAAAABAgAAAAABAQECAAAAAAAAAAAAAAEBAAAAAQAAAAAAAAAAAAMAAAAAAAAAAQAAAAAAAAAAAAL5AAoAAAAAAQAAAAAAAAEAAAAAAAACAQAAAAICAAAAAAEAAAECAASjAAAAwAAAABIAAACCAAIAAQYAAQABAAEYAAAAHwEAAAAAAY2dPuzyb3l0oSpABtE7q4L9hSmYv1lU7Q==

-- decompilation:
local function DeepCopy(p1, p2, p3, p4, p5, p6) -- line: 1
	-- upvalues: DeepCopy (copy)
	if typeof(p1) ~= "table" then
		return p1
	end

	local v8 = p5 or {}
	local v9 = v8[p1]

	if v9 then
		return v9
	end

	local v10 = typeof(p2) == "table" and p2 or {}

	v8[p1] = v10

	for v11, v12 in p1 do
		if typeof(p4) ~= "table" or not p3 or not p4[v11] then
			if typeof(v12) == "table" and not p3 then
				v10[v11] = DeepCopy(v12, nil, p3, p4, v8, true)
			else
				v10[v11] = v12
			end
		end
	end

	local mt = getmetatable(p1)

	if typeof(mt) == "table" then
		setmetatable(v10, mt)
	end

	if not p6 then
		table.clear(v8)
	end

	return v10
end

return DeepCopy

