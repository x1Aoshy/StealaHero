-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBXBjYWxsB1NhZmVHZXQJSXNXaW5kb3dzCVZSRW5hYmxlZARFbnVtCkRldmljZUZvcm0CVlISSXNUZW5Gb290SW50ZXJmYWNlB0NvbnNvbGUHRGVza3RvcBBHeXJvc2NvcGVFbmFibGVkFEFjY2VsZXJvbWV0ZXJFbmFibGVkBVBob25lDE1vdXNlRW5hYmxlZAxUb3VjaEVuYWJsZWQOR2FtZXBhZEVuYWJsZWQDR2V0BGdhbWUKR3VpU2VydmljZQpHZXRTZXJ2aWNlEFVzZXJJbnB1dFNlcnZpY2UFdGFibGUGZnJlZXplAAUDAAIAAAUAAgAPAwT7AQAA+wIBAIcAAQKCAAIAAAAfAAEYAAAAACAAAAAABgMAAAAQBQACBQMPAw8PAwALDwQACwukAwEAAAAAQNkEAAASAAAAEgABAJ8DAgMOAwIAUgUEAIIFAgBSBQIAggUCAAIDAQQAAABAAQAeAgEYAAAAAAAAAwAAAAAfAAAAAAUAAQAAEAABAw8PAQAMDwIBCw8DAQsN+wEAAKQCAQAAAABAbwQCANkDAAASAAEAEgAEAJ8CAgMOAgIAUgADAIIAAgCpAAAAggACAAMDAQQAAABAAwMBACUDARgH+QAAAAAAAAMAAAAAHwAAAAAFAAIAABEAAgMPDw8BDwwPAhALDwMQC0H7AAAATQAAsQAAAAAOAAMApAAEAAMIEMCCAAIA+wABALwAAGwFAAAAnwACAg4AAwCkAAcABggQwIIAAgD7AQEApAIJAAAAgEBvBAoA2QMAABIAAQASAAQAnwICAw4CAgBSAAMAZQABAKkAAAAOAAMApAAMAAsIEMCCAAIA+wAAAE0AAHINAAAAKwAEAPsAAABNAAAfDgAAAA4AAwCkABAADwgQwIIAAgD7AAAATQAAUBEAAAAOAAMApAAMAAsIEMCCAAIA+wAAAE0AAH8SAAAADgADAKQAEAAPCBDAggACAPsAAABNAACzEwAAAA4AAwCkAAcABggQwIIAAgDGAAAAggACABQDBAMFAwYDBwQDCBDAAwgDCQQGCBDAAwEEAACAQAMDAwoECwgQwAMLAwwDDQQPCBDAAw4DDwMQAQApEQEYDAAAAAEAAAMAAAAAAQAA9vkAAAAAAAADAAAAABIAAAMAAAAAAAAAAgAAAwAAAAEAAAMAAAACAAADAAAAAQAAAwAfAAAAAAcAAAEDFwAABQ8AARkPAQcTDwINDQ8DDgwPBBAKGqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwLAAgUAwAMGABIAAADABAcAEgABABIAAACkBQoAACSAgOIGDAAwBAZ/CwAAAJ8FAgCCBQAADQMSBAAAAEADEwMUAxUGAQYCBgMDFgMXBAAkgIADEQUBCwMBAgMBAAEYABoAAAAAAAEAAAAAAAIHAAQAACMAAAEA/wABAAAAAAQXckkwJNA0H2ikhxQjh8LdZ2peRCW2IzE=

-- decompilation:
--!native
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local function SafeGet(p1, s1: string, p2) -- line: 30
	local ok, result = pcall(function() -- line: 31
		-- upvalues: p1 (copy), s1 (copy)
		return p1[s1]
	end)

	if ok then
		return result
	end

	return p2
end
local function IsWindows() -- line: 37
	-- upvalues: GuiService (copy)
	local v10 = GuiService
	local s2 = "IsWindows"
	local ok, result = pcall(function() -- line: 31
		-- upvalues: v10 (copy), s2 (copy)
		return v10[s2]
	end)

	if ok then
		return result
	end

	return false
end

return table.freeze({
	Get = function() -- line: 41
		-- upvalues: UserInputService (copy), GuiService (copy)
		if UserInputService.VREnabled then
			return Enum.DeviceForm.VR
		end

		if GuiService:IsTenFootInterface() then
			return Enum.DeviceForm.Console
		end

		local v14 = GuiService
		local s3 = "IsWindows"
		local ok, result = pcall(function() -- line: 31
			-- upvalues: v14 (copy), s3 (copy)
			return v14[s3]
		end)

		if ok and result then
			return Enum.DeviceForm.Desktop
		end

		if UserInputService.GyroscopeEnabled or UserInputService.AccelerometerEnabled then
			return Enum.DeviceForm.Phone
		end

		if UserInputService.MouseEnabled then
			return Enum.DeviceForm.Desktop
		end

		if UserInputService.TouchEnabled then
			return Enum.DeviceForm.Phone
		end

		if UserInputService.GamepadEnabled then
			return Enum.DeviceForm.Console
		end

		return nil
	end
})

