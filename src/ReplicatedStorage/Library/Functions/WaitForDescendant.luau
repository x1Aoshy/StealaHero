-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMDkZpbmRGaXJzdENoaWxkBHdhcm4/SW5maW5pdGUgeWllbGQgcG9zc2libGUgb24gJ2dhbWUuJXM6V2FpdEZvckRlc2NlbmRhbnQoIiVzIiknICVzC0dldEZ1bGxOYW1lBWRlYnVnCXRyYWNlYmFjawZmb3JtYXQNUHJlU2ltdWxhdGlvbgRXYWl0BGdhbWUKUnVuU2VydmljZQpHZXRTZXJ2aWNlAAINAwEAAAcAAAEDCCICMVIFAQCpBgEAvAMAAwAAAACfAwQCDgMBAIIDAgCMBAAAkAUCAakGAABSCQEAqQoBALwHAAMAAAAAnwcEAlIDBwB9BQIABAAAAIIDAgCMBwUAfQcRAAQAAAArBg8AqQYBAKQHAwAAACBAbwgEALwKALIFAAAAnwoCAlILAQCkDAgAABxggJ8MAQC8CAiNCQAAAJ8IAAKfBwIB+wcAAE0HBwgKAAAAvAcH9wsAAACfBwICQwQEBw4DAQCCAwIASADa/4IAAQAMAwECAAAAAAAA8H8DAgQAACBAAwMDBAMFAwYEABxggAMHAwgDCQADAAEYAAAAAAABAQMBAQMAAAAAAAEAAQIAAAABAQACAQAAAQEAAP0AAP4KAAAAAAAAAQHtFgQAAAAAAwAAAQIACqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLAAQQAEgAAAIIBAgAFAwoEAAAAQAMLAwwGAAEAAQABGAAAAAAAAAACAAABAAAAAAGIOwSxpmTeX4dVk+Ddg+ix+CMTxbr/brA=

-- decompilation:
local RunService = game:GetService("RunService")

return function(p1, p2, p3) -- line: 3
	-- upvalues: RunService (copy)
	local p2_2 = p1:FindFirstChild(p2, true)

	if p2_2 then
		return p2_2
	end

	local n1 = 0.0
	local v7 = p3 or 1e999
	local v8 = false
	local p2_3

	repeat
		p2_3 = p1:FindFirstChild(p2, true)

		if v7 <= n1 then
			return p2_3
		end

		if n1 >= 5.0 and not v8 then
			v8 = true
			warn((("Infinite yield possible on 'game.%s:WaitForDescendant(\"%s\")' %s"):format(p1:GetFullName(), p2, debug.traceback())))
		end

		n1 += RunService.PreSimulation:Wait()
	until p2_3

	return p2_3
end

