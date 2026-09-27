-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMeC19jb25uZWN0aW9uCkRpc2Nvbm5lY3QKX2NhbGxiYWNrcwZpcGFpcnMLSXNDb25uZWN0ZWQEdHlwZQhmdW5jdGlvbgZhc3NlcnQFdGFibGUGaW5zZXJ0BFRoZW4EdGFzawR3YWl0BFdhaXQCX3QJX2R1cmF0aW9uEV90aW1lVW5yZXN0cmljdGVkBG1hdGgDbWluC190aW1lU2NhbGVkA19mbgVfU3RlcAZudW1iZXIHX19pbmRleAxzZXRtZXRhdGFibGUJSGVhcnRiZWF0B0Nvbm5lY3QEZ2FtZQpSdW5TZXJ2aWNlCkdldFNlcnZpY2UACAkBAAAAAB1NAQAsAAAAAA4BBgDGAgAAMAIALAAAAAC8AgEaAQAAAJ8CAgFNAgC4AgAAABwDAgCMBAAAYAQOAAMAAAD/AwAAAAAAADADALgCAAAApAMEAAAAMEBSBAIAnwMCBFEDAgBSCAcAnwgBAW4D/f8CAACAggABAAUDAQMCAwMDBAQAADBAAAUCARgAAAEBAAABAAACAAEAAAABAAAAAQAAAAABAP8ABAYAAAAAAwEAAAAAB00CACwAAAAARwICAAAAAICpAQABqQEBAIIBAgABAwEAFAUBGAAAAAAAAAAVAAAAAAYCAAAAABy7KAEDUgUBAKQEAQAAAABAnwQCAvAEAgACAAAAqQMAAakDAQC7AQMCpAIEAAAAMECfAgIBTQIALAUAAAArAgMAUgIBAJ8CAQGCAAIATQMAuAYAAACeNAMEAQAAAFIEAQCkAgkAACBwgJ8CAwGCAAIACgMGBAAAAEADBwMIBAAAMEADAQMDAwkDCgQAIHCAABgLARgAAAAAAAAAAAAAAAAAAQAAAQABAgAAAAAAAAABGQAAAAADAQAAAAAJvAEA+wAAAACfAQICDgEEAKQBAwAACBCAnwEBAUgA+P+CAAEABAMFAwwDDQQACBCAACIOARgAAAAAAQAA/wMjAAAAAAsCAAAAAEZNAgD6AAAAAE0DAGoBAAAATQQA9wIAAAArBAkAJgUDAp4TAQUFAAAAUgcBAFIIBQCkBgUAABAwgJ8GAwJSAQYAQwUCASsECACeEwUFAwAAAFIHBQBSCAMApAYFAAAQMICfBgMCUgUGADAFAPoAAAAAxgYAAE0HAK4GAAAADgcZAA0DAwAHAACAUgYFAGUAFgDsAQED7AYFAysEEwD1BwgGnhMBBQcAAABSCQEAUgoHAKQIBQAAEDCAnwgDAlIBCACBEwYFCAAAAFIJBgBvCggApAgFAAAQMICfCAMCUgYIAGUAAQBSBgUATQcAaAkAAABSCAEAUgkGAJ8HAwIrBwIAfQMEAAUAAAC8BwAaCgAAAJ8HAgGCAAEACwMPAxADEQMSAxMEABAwgAMUAgAAAAAAAPB/AgAAAAAAAPA/AxUDAgAoFgEYAAABAAEAAQEBAAAAAAAAAAIBAQAAAAAAAAACAAEBAAABAAEAAgEBAQEAAAAAAAAAAQAAAAAAAAAABAIAAAAAAAAAAQAAAikAAAAABAEBAAAABvsBAABSAwAAvAEBnQAAAACfAQMBggABAAEDFgBaAAEYAAAAAAABWwAAAAAIBAIAAABXuygAA1IHAACkBgEAAAAAQJ8GAgLwBgIAAgAAAKkFAAGpBQEAuwEFAqQEBAAAADBAnwQCAUcBHwAAAAAAuygBA1IHAQCkBgEAAAAAQJ8GAgLwBgIABQAAAKkFAAGpBQEAuwEFAqQEBAAAADBAnwQCAYwGAAC3BgIAAQAAAKkFAAGpBQEAuwEFAqQEBAAAADBAnwQCAfEBAgABAAAAqQUAAakFAQC7AQUCpAQEAAAAMECfBAIB4gUPADAABWgGAAAAkAYBEDAGBWoHAAAAKgICAAEAAACpBgABqQYBADAGBa4IAAAAKgMCAAEAAACpBgABqQYBADAGBfcJAAAA/wYAAAAAAAAwBgW4DAAAAOIGEgD7BwAAMAcGbhEAAACePQUDBgAAAKQEFAAAADBBnwQDAvsFAQBNBQX9FQAAANkHAAASAAQAvAUFxxYAAACfBQMCMAUELA0AAACCBAIAFwMGBAAAAEADBwMIBAAAMEADFwMVAxADFAMRAw8CAAAAAAAAAAADAwMBAAgHBv////8H/////wj/////Cf////8KCwAAAAz/////DQ4AAAACAAAAAAAA8H8DGAUBEQMZBAAAMEEDGgMbAQVKAAEYAAAAAAAAAAAAAAAAAAEAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAgEAAQAAAQAAAAAAAQAAAAAAAgAAAAIAAAAAAPgAAAkAAAAAAAAAAAADSwAAAAADAAABAgAcowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAv8BBAAAAAAAwAIEADACARoFAAAAwAIGADACAfsHAAAAwAIIADACAXsJAAAAwAIKADACAfcLAAAAwAIMADACAZ0NAAAAwAIOABIAAQASAAAAggICAA8DHAQAAABAAx0DHgYAAwIGAQMFBgIDCwYDAw4GBAMWBgYGAAECAwQGAQABGAAAAAAAAAACAAIAAA8AAAQAAAoAAAYAACIAAAABAAAAAAedPl9fAStoplAxHfQW8Arv7SZIK6/6NV4=

-- decompilation:
local RunService = game:GetService("RunService")
local t1 = {
	Disconnect = function(p1) -- line: 5
		local _connection = p1._connection

		if _connection then
			p1._connection = nil
			_connection:Disconnect()
		end

		local _callbacks = p1._callbacks

		if #_callbacks > 0.0 then
			p1._callbacks = {}

			for _, v in ipairs(_callbacks) do
				v()
			end
		end
	end,
	IsConnected = function(p2) -- line: 20
		return p2._connection ~= nil
	end,
	Then = function(p3, p4) -- line: 24
		assert(type(p4) == "function")

		if not p3._connection then
			p4()

			return p3
		end

		table.insert(p3._callbacks, p4)

		return p3
	end,
	Wait = function(p5) -- line: 34
		while p5:IsConnected() do
			task.wait()
		end
	end,
	_Step = function(p6, p7) -- line: 40
		local _t = p6._t
		local _duration = p6._duration
		local _timeUnrestricted = p6._timeUnrestricted

		if not _timeUnrestricted then
			p7 = math.min(p7, _duration - _t)
		end

		local v17 = _t + p7

		if not _timeUnrestricted then
			v17 = math.min(v17, _duration)
		end

		p6._t = v17

		local v18

		if p6._timeScaled then
			if _duration == 1e999 then
				v18 = v17
			else
				p7 /= _duration
				v18 = v17 / _duration

				if not _timeUnrestricted then
					p7 = math.min(p7, 1.0 - v18)
					v18 = math.min(v18, 1.0)
				end
			end
		else
			v18 = v17
		end

		if p6._fn(p7, v18) or _duration <= v17 then
			p6:Disconnect()
		end
	end
}

return function(p8, p9, p10, p11) -- line: 74
	-- upvalues: t1 (copy), RunService (copy)
	assert(type(p8) == "function")

	if p9 ~= nil then
		assert(type(p9) == "number")
		assert(p9 > 0.0)
		assert(p9 == p9)
	end

	local v23 = setmetatable({
		_t = 0.0,
		_connection = nil,
		_fn = p8,
		_duration = p9 or 1e999,
		_timeScaled = p10 == true,
		_timeUnrestricted = p11 == true,
		_callbacks = {}
	}, {
		__index = t1
	})

	v23._connection = RunService.Heartbeat:Connect(function(dt) -- line: 90
		-- upvalues: v23 (copy)
		v23:_Step(dt)
	end)

	return v23
end

