-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBWNsZWFyDkdldFByb2R1Y3RJbmZvBHR5cGUGbnVtYmVyBmFzc2VydAZ0eXBlb2YIRW51bUl0ZW0IRW51bVR5cGUERW51bQhJbmZvVHlwZQRJbmZvC0xhc3RVcGRhdGVkBHRpbWUKVXBkYXRlUmF0ZQtMYXN0RmFpbHVyZQlSZXRyeVJhdGUFcGNhbGwEd2FybgZzdHJpbmcGZm9ybWF0RltQcm9kdWN0Q2FjaGVdIEZhaWxlZCB0byByZXRyaWV2ZTogcHJvZHVjdElkPSVkIGluZm9UeXBlPSVzIGVycm9yPSclcycETmFtZQh0b3N0cmluZw5nZXRQcm9kdWN0SW5mbwRnYW1lEk1hcmtldHBsYWNlU2VydmljZQpHZXRTZXJ2aWNlAAQBAAEAAAAE/wAAAAAAAADeAAAAggABAAAACgEBGAAAAAELAAAAAAQAAwAAAAf7AAAA+wIBAPsDAgC8AAB1AAAAAJ8ABACCAAAAAQMCACYAARgAAAAAAAAAJwAAAAAPAgMAAAB7uygAA1IFAACkBAEAAAAAQJ8EAgLwBAIAAgAAAKkDAAGpAwEAuwEDAqQCBAAAADBAnwICAcYCAAC7LAEDUgQBAKQDBgAAAFBAnwMCAvADCgAHAACATQMBdggAAACkBAsAACiQgPEDAgAEAAAAqQIAAakCAQBlAAEAqQIAALsBAgNSBAIApAMEAAAAMECfAwIB+wQAAIcDBAErAwQA/wMAAAAAAAD7BAAAagMEAYcEAwArBAMA/wQAAAAAAABqBAMATQUEegwAAAAOBREATQUEWg0AAAAOBQ4ApAYPAAAA4ECfBgECTQcEWg0AAAAmBQYH+wYBAE0GBnYQAAAAYAUEAAYAAABSBQQAqQYBAIIFAwBNBQQDEQAAAA4FDgCkBg8AAADgQJ8GAQJNBwQDEQAAACYFBgf7BgEATQYGahIAAABgBQQABgAAAFIFBACpBgAAggUDAKQFFAAAADBB2QYAABICAgASAAAAEgABAJ8FAgOkBw8AAADgQJ8HAQIOBQcAMAcEWg0AAAAwBgR6DAAAAFIIBACpCQEAgggDADAHBAMRAAAApAgWAAAAUEGkCRkAAGBwgW8KGgBSCwAATQwBuhsAAAC7PwYDUg4GAKQNHQAAAMBBnw0CAp8JBQCfCAABUggEAKkJAACCCAMAHgMDBAAAAEADBAMFBAAAMEADBgQAAFBAAwcDCAMJAwoEACiQgAMLAwwDDQQAAOBAAw4DDwMQAxEEAAAwQQMSBAAAUEEDEwMUBABgcIEDFQMWAxcEAADAQQEBDhgBGAAAAAAAAAAAAAAAAAABAQAAAAAAAAEAAAAAAAAAAAICAAAAAAEAAQEAAQACAQEAAQIAAAAAAAAAAAAAAAAAAAAAAQAAAQAAAAAAAAAAAAAAAAABAAACAAAAAAAAAwAAAQEAAQABAAACAAEAAQABAQEAAQAAAAD8/wgAAA8AAAAABAAAAQIAFqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLiAQcA/wIAAAAAAADZAwAAEgEC/zADAbAIAAAA2QMBABIBAv8SAAEAEgAAADADAZUJAAAAwQIAAIIBAgAKAxkEAAAAQAMaAxsDDgIAAAAAACCMQAMQCAIEBQAAAAYFAAAAAwEDGAIAAgEAARgAAAAAAAAAAgUAAgAAAAQAAAAAAC8AAQAAAAADK0ipY5jmnZ1L0Nd2y903MFtQvhcZjMNi

-- decompilation:
local MarketplaceService = game:GetService("MarketplaceService")
local t1 = {
	UpdateRate = 900.0,
	RetryRate = 900.0
}
local t2 = {}

function t1.clear() -- line: 10
	-- upvalues: t2 (ref)
	t2 = {}
end
function t1.getProductInfo(p1, p2) -- line: 14
	-- upvalues: t2 (ref), t1 (copy), MarketplaceService (copy)
	assert(type(p1) == "number")
	assert(typeof(p2) == "EnumItem" and p2.EnumType == Enum.InfoType)

	local v6 = t2[p2]

	if not v6 then
		v6 = {}
		t2[p2] = v6
	end

	local v7 = v6[p1]

	if not v7 then
		v7 = {}
		v6[p1] = v7
	end

	if v7.Info and v7.LastUpdated and time() - v7.LastUpdated < t1.UpdateRate then
		return v7, true
	end

	if v7.LastFailure and time() - v7.LastFailure < t1.RetryRate then
		return v7, false
	end

	local ok, result = pcall(function() -- line: 38
		-- upvalues: MarketplaceService (copy), p1 (copy), p2 (copy)
		return MarketplaceService:GetProductInfo(p1, p2)
	end)
	local v10 = time()

	if ok then
		v7.LastUpdated = v10
		v7.Info = result

		return v7, true
	end

	v7.LastFailure = v10
	warn(string.format("[ProductCache] Failed to retrieve: productId=%d infoType=%s error='%s'", p1, p2.Name, (tostring(result))))

	return v7, false
end

return t1

