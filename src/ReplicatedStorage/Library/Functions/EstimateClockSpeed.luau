-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Players = game:GetService("Players")

local function benchmarkCpu() -- line: 3
	local elapsed = os.clock()
	local v8 = elapsed

	for i = 1.0, 1000000.0 do
		v8 = v8 + v8 - i
	end

	local elapsed2 = os.clock()

	if v8 == -1.0 then
		return -1.0
	end

	return elapsed2 - elapsed
end
local function measureCpu() -- line: 13
	local elapsed = os.clock()
	local v12 = elapsed

	for i = 1.0, 1000000.0 do
		v12 = v12 + v12 - i
	end

	local elapsed3 = os.clock()

	if v12 == -1.0 then
	else
		local _ = elapsed3 - elapsed
	end

	task.wait()

	local elapsed4 = os.clock()
	local v17 = elapsed4

	for i = 1.0, 1000000.0 do
		v17 = v17 + v17 - i
	end

	local elapsed5 = os.clock()

	if v17 == -1.0 then
	else
		local _ = elapsed5 - elapsed4
	end

	task.wait()

	local elapsed6 = os.clock()
	local v22 = elapsed6

	for i = 1.0, 1000000.0 do
		v22 = v22 + v22 - i
	end

	local elapsed7 = os.clock()
	local v25 = if v22 ~= -1.0 then elapsed7 - elapsed6 else -1.0
	local elapsed8 = os.clock()
	local v27 = elapsed8

	for i = 1.0, 1000000.0 do
		v27 = v27 + v27 - i
	end

	local elapsed9 = os.clock()
	local v30 = v25 + if v27 ~= -1.0 then elapsed9 - elapsed8 else -1.0
	local elapsed10 = os.clock()
	local v32 = elapsed10

	for i = 1.0, 1000000.0 do
		v32 = v32 + v32 - i
	end

	local elapsed11 = os.clock()
	local v35 = v30 + if v32 ~= -1.0 then elapsed11 - elapsed10 else -1.0
	local elapsed12 = os.clock()
	local v37 = elapsed12

	for i = 1.0, 1000000.0 do
		v37 = v37 + v37 - i
	end

	local elapsed13 = os.clock()

	return 0.01798125 / (v35 + (if v37 ~= -1.0 then elapsed13 - elapsed12 else -1.0)) / 4.0
end
local function isLoaded() -- line: 21
	-- upvalues: Players (copy)
	if game:IsLoaded() then
		local LocalPlayer = Players.LocalPlayer

		if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			if LocalPlayer:GetAttribute("__LOADED") then
				return true
			end

			return false
		end

		return false
	end

	return false
end

local u5 = nil
local elapsed = nil

return function() -- line: 37
	-- upvalues: u5 (ref), elapsed (ref), Players (copy), measureCpu (copy)
	if u5 then
		return u5
	end

	if not elapsed then
		local v42

		if game:IsLoaded() then
			local LocalPlayer = Players.LocalPlayer

			v42 = not not LocalPlayer and (not not LocalPlayer.Character and (not not LocalPlayer.Character:FindFirstChild("Humanoid") and not not LocalPlayer:GetAttribute("__LOADED")))
		else
			v42 = false
		end

		if v42 then
			elapsed = os.clock()
		end

		return nil
	end

	if os.clock() - elapsed < 10.0 then
		return nil
	end

	local v43 = measureCpu()

	u5 = v43

	return v43
end

