-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBEVtaXQJVGltZVNjYWxlBFJhdGUJRW1pdENvdW50DEdldEF0dHJpYnV0ZQR0eXBlBm51bWJlcgRtYXRoBWZsb29yBnJhbmRvbQlFbWl0RGVsYXkDbWF4BHRhc2sFZGVsYXkITGlmZXRpbWUDTWF4CEVtaXRPbmNlAAMDAAIAAAUAAgAHDwb7AAAA+wIBALwAAFYAAAAAnwADAYIAAQABAwEAMwABGAAAAAAAATQAAAAACgEAAAAeAwAGBQEHDwEAVQ8CB04PAwlMDwQVQAIFLCkPBi0oVU0BAKcAAAAAjAIAAH0BAwACAAAAjAIAAIICAgBNAgD2AQAAAG8FAgC8AwASAwAAAJ8DAwK7KAMDUgUDAKQEBQAAAEBAnwQCAvAEAgAGAACAUgIDAFIEAgC7DAIDUgYCAKQFCQAAIHCAnwUCAlICBQAmBAQCjAUAAGAFBwAEAAAApAULAAAocICfBQECYAUCAAQAAACVAgIMjAUBAGACBAAFAAAAjAUAAMECAACCBQIAjAUAAG8IDQC8BgASAwAAAJ8GAwK7KAYDUggGAKQHBQAAAEBAnwcCAvAHAgAGAACAUgUGAA0FBAAOAACAjAcAAMECAACCBwIAgRIFBQ8AAABSCAUAbwkPAKQHEQAAQHCAnwcDAlIFBwCkBxQAAEwggVIIBQDZCQAAEgAAABIBAv+fBwMBTQkAyxUAAABNCQm0FgAAAOwICQFDBwUIwQIAAIIHAgAXAwIDAwMEAwUDBgQAAEBAAwcDCAMJBAAgcIADCgQAKHCAAgAAAAAAAPA/AwsCAAAAAAAA8H8CAAAAAAAAAAADDAQAQHCAAw0DDgQATCCBAw8DEAEAFBEBGAAAAQAAAQADAAEAAAABAAAAAAAAAQIBAAAAAAABAQAAAAAAAAABAgAAAQAAAwEAAAABAAAAAAAAAQIAAQAAAgAAAAAAAAACAAAAAAAABAAAAAAAAAAVAAAAAAEAAAEDBwAAAQ8AAQIDowAAAMAAAACCAAIAAQYBAQEBAAEYABMmAQAAAAAC/ueucWDsnS/Xg4PAw82Y/I7/uQXMI8Rw

-- decompilation:
--!native
local function EmitOnce(p1) -- line: 20
	local TimeScale = p1.TimeScale

	if TimeScale <= 0.0 then
		return 0.0
	end

	local p1Rate = p1.Rate
	local EmitCount = p1:GetAttribute("EmitCount")

	if type(EmitCount) == "number" then
		p1Rate = EmitCount
	end

	local u6 = math.floor(p1Rate)
	local v7 = p1Rate - u6

	if v7 > 0.0 and v7 > math.random() then
		u6 += 1.0
	end

	if u6 < 1.0 then
		return 0.0
	end

	local n1 = 0.0
	local EmitDelay = p1:GetAttribute("EmitDelay")

	if type(EmitDelay) == "number" then
		n1 = EmitDelay
	end

	if n1 == 1e999 then
		return 0.0
	end

	local v10 = math.max(n1, 0.0)

	task.delay(v10, function() -- line: 51
		-- upvalues: p1 (copy), u6 (ref)
		p1:Emit(u6)
	end)

	return v10 + p1.Lifetime.Max / TimeScale
end

return EmitOnce

