-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local RunService = game:GetService("RunService")
local t1 = {
	Disconnect = function(p1) -- line: 4
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
	IsConnected = function(p2) -- line: 18
		return p2._connection ~= nil
	end,
	Then = function(p3, p4) -- line: 21
		assert(type(p4) == "function")

		if not p3._connection then
			p4()

			return p3
		end

		table.insert(p3._callbacks, p4)

		return p3
	end,
	Wait = function(p5) -- line: 30
		while p5:IsConnected() do
			task.wait()
		end
	end,
	_Step = function(p6, p7) -- line: 35
		local _t = p6._t
		local _duration = p6._duration

		if not p6._timeUnrestricted then
			p7 = math.min(p7, _duration - _t)
		end

		local v16 = _t + p7

		if not p6._timeUnrestricted then
			v16 = math.min(v16, _duration)
		end

		p6._t = v16

		local v17

		if p6._timeScaled then
			if _duration == 1e999 then
				v17 = v16
			else
				p7 /= _duration
				v17 = v16 / _duration

				if not p6._timeUnrestricted then
					p7 = math.min(p7, 1.0 - v17)
					v17 = math.min(v17, 1.0)
				end
			end
		else
			v17 = v16
		end

		if p6._fn(p7, v17) or _duration <= v16 then
			p6:Disconnect()
		end
	end
}

return function(p8, p9, p10, p11) -- line: 67
	-- upvalues: t1 (copy), RunService (copy)
	assert(type(p8) == "function")

	if p9 ~= nil then
		assert(type(p9) == "number")
		assert(p9 > 0.0)
		assert(p9 == p9)
	end

	local v22 = setmetatable({
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

	v22._connection = RunService.Stepped:Connect(function(_, dt) -- line: 83
		-- upvalues: v22 (copy)
		v22:_Step(dt)
	end)

	return v22
end

