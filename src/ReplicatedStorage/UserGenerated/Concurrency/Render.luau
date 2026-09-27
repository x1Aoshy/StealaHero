-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Logging = require(ReplicatedStorage.UserGenerated.Logging)
local Asserts = require(ReplicatedStorage.UserGenerated.Lang.Asserts)
local t1 = {
	Disconnect = function(p1) -- line: 51
		p1.Connection:Disconnect()
		p1:OnDisconnected()
	end,
	OnDisconnected = function(p2) -- line: 56
		if p2.Vars.Disconnected then
			return
		end

		p2.Vars.Disconnected = true

		for _, v in ipairs(p2.Callbacks) do
			task.spawn(v)
		end

		table.clear(p2.Callbacks)
	end,
	Then = function(p3, p4) -- line: 67
		-- upvalues: Asserts (copy)
		Asserts.Function(p4)

		if p3.Vars.Disconnected then
			task.spawn(p4)

			return
		end

		table.insert(p3.Callbacks, p4)
	end
}
local v6 = table.freeze({
	__index = table.freeze(t1)
})

function new(n1: number, p5: ((...any) -> ...any)) -- line: 79
	-- upvalues: Asserts (copy), v6 (copy), RunService (copy), Logging (copy)
	Asserts.FiniteNonNegative(n1)
	Asserts.Function(p5)

	local v15 = setmetatable({
		Connection = nil,
		Callbacks = {},
		Vars = {
			Disconnected = false
		}
	}, v6)
	local n2 = 0.0
	local connection = nil

	connection = RunService.RenderStepped:Connect(function(dt) -- line: 94
		-- upvalues: n2 (ref), n1 (copy), connection (ref), p5 (copy), Logging (copy), v15 (copy)
		local v19 = false
		local v20 = n2

		n2 += dt

		if n2 >= n1 then
			n2 = n1
			connection:Disconnect()
			v19 = true
		end

		local v21 = if not (n2 >= n1) then n2 / n1 else 1.0
		local v22 = n2
		local v23 = n2 - v20
		local ok, result = pcall(p5, v21, v22, v23)

		if not ok then
			Logging.Warn("RenderError", result)
		end

		if not ok or result ~= nil then
			connection:Disconnect()
			v19 = true
		end

		if v19 then
			v15:OnDisconnected()
		end
	end)
	v15.Connection = connection
	table.freeze(v15)

	return v15
end

return new

