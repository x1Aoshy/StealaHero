-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBXRyYWNrBm9uQ2FsbAdfX2luZGV4Bl9fY2FsbAdvYmplY3RzDHNldG1ldGF0YWJsZQNuZXcGaXBhaXJzBXRhYmxlBmluc2VydAZ0eXBlb2YISW5zdGFuY2UOQW5pbWF0aW9uVHJhY2sDSXNBBFN0b3AHRGVzdHJveRNSQlhTY3JpcHRDb25uZWN0aW9uCkRpc2Nvbm5lY3QEdHlwZQhmdW5jdGlvbgVwY2FsbAR3YXJuBnN0cmluZwZmb3JtYXQuW1RyYWNrZXJdIERlc3RydWN0aW9uIGZhaWxlZCBmb3IgdHlwZSAnJXMnOiAlcwh0b3N0cmluZwdkZXN0cm95AAcEAQABAAAGowEAAN0DAAC8AQDAAAAAAJ8BAAGCAAEAAQMBAAMCARgAAQAAAAEDAAAAAAQAAgAAABPiAAIA+wEAADABAG4AAAAA+wEBADABAO8BAAAA4gIEAP8DAAAAAAAAMAMCOAMAAACePQIEAAAAAFIDAACkAQYAAABQQJ8BAwKCAQIABwMDAwQFAgABAwUFAQMDBgQAAFBAAAcHARgAAQAAAQAAAgAAAAAAAAAAAAAACAAAAAAJAQABAAAVowEAAKQBAQAAAABA/wIAAAAAAADdBAAAxQIEAAEAAACfAQIEUQEIAE0HADgCAAAAnjQHBAUAAABSCAUApAYFAAAQMICfBgMBbgH3/wIAAICCAAEABgMIBAAAAEADBQMJAwoEABAwgAAPAQEYAAEAAAAAAAAAAAEAAAAAAAAA/wADDwAAAAADAAEAAAAs+wEAALssAQKkAAEAAAAAQJ8AAgLwABAAAgAAgPsAAABvAgMAvAAA/gQAAACfAAMCDgAEAPsAAAC8AAD6BQAAAJ8AAgH7AAAAvAAAUAYAAACfAAIBggABAPsBAAC7LAECpAABAAAAAECfAAIC8AAGAAcAAID7AAAAvAAAGggAAACfAAIBggABAPsBAAC7KAECpAAKAAAAkECfAAIC8AADAAsAAID7AAAAnwABAYIAAQAMAwsEAAAAQAMMAw0DDgMPAxADEQMSAxMEAACQQAMUABkAARgAAAAAAAAAAQAAAAAAAQAAAAIAAAAAAQAAAAAAAAEAAAAAAQAAAAAAAAEAAhoAAAAADwEAAAAAJk0BADgAAAAA/wIAAAAAAAAwAgA4AAAAAKQCAgAAABBAUgMBAJ8CAgRRAhcApAcEAAAAMEDZCAAAEgAGAJ8HAgMrBxEApAkGAAAAUECkCgkAACBwgG8LCgC7LAYDUg0GAKQMDAAAALBAnwwCArs/CANSDggApA0OAAAA0ECfDQICnwoEAJ8JAAFuAuj/AgAAgKkCAQCCAgIADwMFAwgEAAAQQAMVBAAAMEADFgQAAFBAAxcDGAQAIHCAAxkDCwQAALBAAxoEAADQQAEDFRsBGAAAAQAAAAEAAAAAAQAAAAAMAQAAAAAAAAAAAAAAAAAAAADyABEAFgAAAAABAAEAAAAF+wAAAE0AAO8AAAAAnwABAIIAAAABAwcALAABGAAAAAAALQAAAAADAAABAgASowAAAP8AAwAAAAAAwAEAAMACAQASAAAAEgABADACAO8CAAAAwAIDADACAMAEAAAAwAIFADACADAGAAAAwAIHABIAAACCAgIACAYABgEDBwYCAwEGBAMbBgUFAAECBAUBAAEYAAAAAgQAAAAACAAABgAAFwAAAQAAAAAG18kw/3C97VsfqG1GaRGiW6fRJ4vlDVr+

-- decompilation:
local t1 = {}

local function onCall(p1, ...) -- line: 3
	p1:track(...)
end

function t1.new() -- line: 7
	-- upvalues: t1 (copy), onCall (copy)
	local t2 = {
		__index = t1,
		__call = onCall
	}

	return (setmetatable({
		objects = {}
	}, t2))
end
function t1.track(p2, ...) -- line: 15
	for _, v in ipairs({ ... }) do
		table.insert(p2.objects, v)
	end
end
function t1.destroy(p3) -- line: 21
	local objects = p3.objects

	p3.objects = {}

	for _, v in ipairs(objects) do
		local ok, result = pcall(function() -- line: 25
			-- upvalues: v (copy)
			if typeof(v) == "Instance" then
				if v:IsA("AnimationTrack") then
					v:Stop()
				end

				v:Destroy()

				return
			end

			if typeof(v) == "RBXScriptConnection" then
				v:Disconnect()

				return
			end

			if type(v) == "function" then
				v()
			end
		end)

		if not ok then
			warn(string.format("[Tracker] Destruction failed for type '%s': %s", typeof(v), (tostring(result))))
		end
	end

	return true
end

return function() -- line: 44
	-- upvalues: t1 (copy)
	return t1.new()
end

