-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local RunService = game:GetService("RunService")
local Signal = require(script.Parent.Signal)
local t1 = {}

function t1.new(n1: number, p1: ((...any) -> ...any)) -- line: 28
	-- upvalues: t1 (copy), Signal (copy), RunService (copy)
	local self = setmetatable({}, {
		__index = t1
	})

	self.TimeOut = n1
	self.Callback = p1
	self.TimeElapsed = 0.0
	self.Elapsed = Signal.new()
	self.Elapsed:Connect(p1)
	self.HeartbeatConnection = RunService.Heartbeat:Connect(function(dt) -- line: 40
		-- upvalues: self (copy)
		self:_Interval(dt)
	end)

	return self
end
function t1._Interval(t2: {[any]: any}, n2: number) -- line: 47
	t2.TimeElapsed = t2.TimeElapsed + n2

	if t2.TimeElapsed >= t2.TimeOut * 10.0 then
		t2.TimeElapsed = t2.TimeElapsed - math.floor(t2.TimeElapsed / t2.TimeOut) * t2.TimeOut

		return
	end

	if t2.TimeElapsed >= t2.TimeOut then
		t2.TimeElapsed = t2.TimeElapsed - t2.TimeOut
		t2.Elapsed:Fire()
	end
end
function t1.On(t3: {[any]: any}) -- line: 69
	-- upvalues: RunService (copy)
	if t3.HeartbeatConnection and t3.HeartbeatConnection.Connected then
		return
	end

	t3.HeartbeatConnection = RunService.Heartbeat:Connect(function(dt) -- line: 76
		-- upvalues: t3 (copy)
		t3:_Interval(dt)
	end)
end
function t1.Off(t4: {[any]: any}) -- line: 81
	if not t4.HeartbeatConnection then
		return
	end

	t4.HeartbeatConnection:Disconnect()
end
function t1.Destroy(t5: {[any]: any}) -- line: 91
	t5:Off()
	t5.Elapsed:Destroy()
	table.clear(t5)
end

return t1

