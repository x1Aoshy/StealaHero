-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBGdhbWUSTWFya2V0cGxhY2VTZXJ2aWNlCkdldFNlcnZpY2UOR2V0UHJvZHVjdEluZm8NbGF0ZXN0VmVyc2lvbgAFcGNhbGwETmFtZQR0YXNrBHdhaXQGc3RyaW5nBW1hdGNoEV5Ub3BiYXJQbHVzICguKikkAyVzKwRnc3ViEGdldExhdGVzdFZlcnNpb24KYXBwVmVyc2lvbg1nZXRBcHBWZXJzaW9uCmlzVXBUb0RhdGUGdjMuMi41AAUDAAAAAAALpAABAAAAAEBvAgIAvAAAFgMAAACfAAMCbwIEALwAAHUFAAAAnwADAIIAAAAGAwEEAAAAQAMCAwMCAEvBxIK32kIDBAASAAEYAAAAAAAAAAAAAAATAAAAAAYAAQAAACX7AAAATQAAwAAAAAAOAAEAggACAG8BAQCkAgMAAAAgQMADBACfAgIDDgIEAA4DAwBNAQO6BQAAAGUABQCkBAgAABxggIwFAQCfBAIBSADy/6QCCwAAKJCAUgMBAG8EDACfAgMCUgACAA4ABgBvBA0AbwUBALwCAMwOAAAAnwIEAlIAAgD7AgAAMAACwAAAAACCAAIADwMFAwYDBwQAACBABgADCAMJAwoEABxggAMLAwwEACiQgAMNAw4DDwEAChABGAAAAAEBAgIAAAADAAEAAQIAAAD4CgAAAAAAAQEAAAAAAAIAAAEMAAAAAAEAAQAAAAT7AAAATQAAkQAAAACCAAIAAQMRACMSARgAAAAAJAAAAAADAAEAAAAQ+wAAAE0AADMAAAAAnwABAvsBAABNAQGXAQAAAJ8BAQKpAgAARwAFAAAAAADxAAIAAQAAAKkCAAGpAgEAggICAAIDEAMSACcTARgAAAAAAQAAAAEAAAAAAAAAKAAAAAACAAABAgAWowAAAP8ABAAAAAAAbwEAADABAJEBAAAAxgEAADABAMACAAAAwAEDABIAAAAwAQAzBAAAAMABBQASAAAAMAEAlwYAAADAAQcAEgAAADABAEoIAAAAggACAAkDFAMRAwUGAQMQBgIDEgYDAxMDAQIDAQABGAACAAMAAAEAAAMAAAAZAAAABAAAAAYBAAAAAASay4LlN9ZflIOe9JFNcrh26tOVkagP6OQ=

-- decompilation:
local t1 = {
	appVersion = "v3.2.5",
	latestVersion = nil
}

function t1.getLatestVersion() -- line: 10
	-- upvalues: t1 (copy)
	local latestVersion = t1.latestVersion

	if latestVersion then
		return latestVersion
	end

	local result = nil

	while true do
		local ok

		ok, result = pcall(function() -- line: 18
			return game:GetService("MarketplaceService"):GetProductInfo(117501901079852.0)
		end)

		if ok and result then
			break
		end

		task.wait(1.0)
	end

	local resultName = result.Name
	local match = string.match(resultName, "^TopbarPlus (.*)$")

	if match then
		match = match:gsub("%s+", "")
	end

	t1.latestVersion = match

	return match
end
function t1.getAppVersion() -- line: 35
	-- upvalues: t1 (copy)
	return t1.appVersion
end
function t1.isUpToDate() -- line: 39
	-- upvalues: t1 (copy)
	local v7 = t1.getLatestVersion()
	local v8 = t1.getAppVersion()

	return v7 ~= nil and v7 == v8
end

return t1

