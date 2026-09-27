-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZDV9kZWJ1Z0VuYWJsZWQLc2V0RGVidWdMb2cPX2luZm9Mb2dFbmFibGVkCnNldEluZm9Mb2cXX2luZm9Mb2dBZHZhbmNlZEVuYWJsZWQNc2V0VmVyYm9zZUxvZxRJbmZvL0dhbWVBbmFseXRpY3M6IAVwcmludAFpF1dhcm5pbmcvR2FtZUFuYWx5dGljczogBHdhcm4BdxVFcnJvci9HYW1lQW5hbHl0aWNzOiAFZXJyb3IEdGFzawVzcGF3bgFlFURlYnVnL0dhbWVBbmFseXRpY3M6IAFkF1ZlcmJvc2UvR2FtZUFuYWx5dGljczogAmlpBGdhbWUKUnVuU2VydmljZQpHZXRTZXJ2aWNlCElzU3R1ZGlvAAoCAgAAAAADMAEAQAAAAACCAAEAAQMBAAoCARgAAAELAAAAAAICAAAAAAMwAQACAAAAAIIAAQABAwMADgQBGAAAAQ8AAAAAAgIAAAAAAzABAPQAAAAAggABAAEDBQASBgEYAAABEwAAAAAFAgAAAAAMTQIAAgAAAAArAgEAggABAG8DAQBSBAEAcwIDBKQDAwAAACBAUgQCAJ8DAgGCAAEABAMDAwcDCAQAACBAABYJARgAAAABAwAAAQAAAAgXAAAAAAUCAAAAAAhvAwAAUgQBAHMCAwSkAwIAAAAQQFIEAgCfAwIBggABAAMDCgMLBAAAEEAAJgwBGAAAAAEAAAAIJwAAAAAEAAEAAAAJbwEAAPsCAABzAAECpAECAAAAEEBSAgAAjAMAAJ8BAwGCAAEAAwMNAw4EAAAQQAAzAAEYAAAAAQAAAAAINAAAAAAEAgAAAAAGpAICAAAEAIDZAwAAEgABAJ8CAgGCAAEAAwMPAxAEAAQAgAEFMhEBGAAAAAAACzMAAAAABQIAAAAADE0CAEAAAAAAKwIBAIIAAQBvAwEAUgQBAHMCAwSkAwMAAAAgQFIEAgCfAwIBggABAAQDAQMSAwgEAAAgQABAEwEYAAAAAQMAAAEAAAAIQQAAAAAFAgAAAAAMTQIA9AAAAAArAgEAggABAG8DAQBSBAEAcwIDBKQDAwAAACBAUgQCAJ8DAgGCAAEABAMFAxQDCAQAACBAAFAVARgAAAABAwAAAQAAAAhRAAAAAAQAAAECACajAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMC4gEIALwCAAoJAAAAnwICAjACAUAHAAAAwAIKADACAeQLAAAAwAIMADACAe4NAAAAwAIOADACAVoPAAAAwAIQADACAYgRAAAAwAISADACAZYTAAAAwAIUADACAYQVAAAAwAIWADACAYUXAAAAwAIYADACAVgZAAAAggECABoDFgQAAABAAxcDGAMDAQADBQMBCAMEBQAAAAYFAAAAB/////8DGQYAAwIGAQMEBgIDBgYDAwkGBAMMBgYDEQYHAxMGCAMVCAABAgMEBgcIAQABGAAAAAAAAAADAwAAAAADAAAEAAAEAAAEAAAQAAAMAAAOAAAQAAAQAQAAAAAJO1OAicmfJ479fgsAoDUkMktLl/0Jl+qI

-- decompilation:
local RunService = game:GetService("RunService")

return {
	_infoLogEnabled = false,
	_infoLogAdvancedEnabled = false,
	_debugEnabled = RunService:IsStudio(),
	setDebugLog = function(p1, p2) -- line: 10
		p1._debugEnabled = p2
	end,
	setInfoLog = function(p3, p4) -- line: 14
		p3._infoLogEnabled = p4
	end,
	setVerboseLog = function(p5, p6) -- line: 18
		p5._infoLogAdvancedEnabled = p6
	end,
	i = function(p7, p8) -- line: 22
		if not p7._infoLogEnabled then
			return
		end

		local v10 = "Info/GameAnalytics: " .. p8

		print(v10)
	end,
	w = function(_, p10) -- line: 38
		local v13 = "Warning/GameAnalytics: " .. p10

		warn(v13)
	end,
	e = function(_, p12) -- line: 50
		task.spawn(function() -- line: 51
			-- upvalues: p12 (copy)
			local v22 = "Error/GameAnalytics: " .. p12

			error(v22, 0.0)
		end)
	end,
	d = function(p13, p14) -- line: 64
		if not p13._debugEnabled then
			return
		end

		local v18 = "Debug/GameAnalytics: " .. p14

		print(v18)
	end,
	ii = function(p15, p16) -- line: 80
		if not p15._infoLogAdvancedEnabled then
			return
		end

		local v21 = "Verbose/GameAnalytics: " .. p16

		print(v21)
	end
}

