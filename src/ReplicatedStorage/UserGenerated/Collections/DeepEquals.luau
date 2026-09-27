-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJCHJhd2VxdWFsBHR5cGUFdGFibGUGcmF3bGVuDGdldG1ldGF0YWJsZQRfX2VxBG5leHQGcmF3Z2V0CkRlZXBFcXVhbHMAAhADAQAALQUBCQUDDw+EDw8LZBEPCWMSDwpjEg8LfAsPCXsMDwp7DA8DLl0PBDNYBAVGRYsBnjMABQEAAABSBAAAUgUBAKQDAQAAAABAnwMDAg4DAgCpAwEAggMCALsoAANSBAAApAMDAAAAIECfAwIC8AMIAAQAAIC7KAEDUgQBAKQDAwAAACBAnwMCAvADCQAEAAAA8QAFAAAAAADxAQMAAQAAAKkDAQCCAwIAqQMAAIIDAgC7OgADUgQAAKQDBgAAAFBAnwMCArs6AQNSBQEApAQGAAAAUECfBAIC8QMDAAQAAACpAwAAggMCALs8AANSBAAApAMIAAAAcECfAwICuzwBA1IFAQCkBAgAAABwQJ8EAgLxAwMABAAAAKkFAACCBQIARwMJAAAAAABNBQPjCQAAAA4FBQDxAAIAAQAAAKkFAAGpBQEAggUCAFIFAgArBQIA/wUAAAAAAACHBgUAKwYCAP8GAAAAAAAAagYFAIcGBQErBgIA/wYAAAAAAABqBgUBhwcFAIcGBwEOBgIAqQYBAIIGAgCHBgUAqQcBAGoHBgGHBgUBqQcBAGoHBgCkBgsAAACgQFIHAADGCAAAFwYRAJ4yAQUJAAAAUgwBAFINCQCkCw0AAADAQJ8LAwJHCwcAAAAAAPsMAABSDQoAUg4LAFIPBQCfDAQCKwwCAKkMAACCDAIAbgbu/wIAAACkBgsAAACgQFIHAQDGCAAAFwYLAJ4yAAUJAAAAUgwAAFINCQCkCw0AAADAQJ8LAwJHCwMAAAAAgKkMAACCDAIAbgb0/wIAAACpBgEAggYCAA4DAQQAAABAAwIEAAAgQAMDAwQEAABQQAMFBAAAcEADBgMHBAAAoEADCAQAAMBAAB8JARgAAAAAAAAAAAEABAAAAAAAAAAAAAAAAAABAAAAAQACAAQAAAAAAAAAAAAAAAEABAAAAAABAAAAAAEAAQAEAAAAAAEAAAAABAAAAAEAAAAAAQAAAAABAAABAAIAAAEAAAMAAAAAAQAAAAAAAAEAAAAAAAAAAQD9AAgAAAAAAQAAAAAAAAEAAQD9AAgAIQAAAAABAAABAwcAAAEPAAEDBKMAAADAAAAAEgAAAIIAAgABBgABAAEAARgAHgA9AQAAAAABj33csYERCJXwJX2fr+G3oP9ly8W9ubaw

-- decompilation:
--!native
local function DeepEquals(p1, p2, t1: {[any]: any}?) -- line: 31
	-- upvalues: DeepEquals (copy)
	if rawequal(p1, p2) then
		return true
	end

	if type(p1) ~= "table" or type(p2) ~= "table" then
		if p1 ~= p1 and p2 ~= p2 then
			return true
		end

		return false
	end

	if rawlen(p1) ~= rawlen(p2) then
		return false
	end

	local mt = getmetatable(p1)

	if mt ~= getmetatable(p2) then
		return false
	end

	if mt ~= nil and mt.__eq then
		return p1 == p2
	end

	local v6 = t1 or {}

	v6[p1] = v6[p1] or {}
	v6[p2] = v6[p2] or {}

	if v6[p1][p2] then
		return true
	end

	v6[p1][p2] = true
	v6[p2][p1] = true

	for k, v in next, p1 do
		local v9 = rawget(p2, k)

		if v9 == nil or not DeepEquals(v, v9, v6) then
			return false
		end
	end

	for k, _ in next, p2 do
		if rawget(p1, k) == nil then
			return false
		end
	end

	return true
end

return DeepEquals

