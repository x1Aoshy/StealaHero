-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Modules = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules")
local v5 = require(Modules.LeftistHeap).new(function(p1, p2) -- line: 6
	return p1 - p2
end)
local t1 = {}
local n1 = 0.0

local function onStepped(_, p4) -- line: 13
	-- upvalues: n1 (ref), v5 (copy), t1 (copy), Debris (copy)
	n1 += p4

	while true do
		local v14, v15 = v5.tryMin()

		if not v14 or v15 > n1 then
			break
		end

		v5.popFast()

		local v16 = t1[v15]

		if v16 then
			t1[v15] = nil

			for _, v in ipairs(v16) do
				if v then
					pcall(function() -- line: 29
						-- upvalues: Debris (copy), v (copy)
						Debris:AddItem(v, 0.0)
					end)
				end
			end
		end
	end
end

RunService.Stepped:Connect(onStepped)

local function AddDebris(p5, n2: number?) -- line: 40
	-- upvalues: n1 (ref), t1 (copy), v5 (copy)
	assert(typeof(p5) == "Instance", "Instance must be an instance")

	local n3

	if n2 == nil then
		n3 = 0.0
	else
		assert(type(n2) == "number", "Lifetime must be a number")
		assert(n2 == n2, "Lifetime cannot be NaN")
		n3 = math.max(0.0, n2)

		if n3 == 1e999 then
			return function() -- line: 52
			end
		end
	end

	local v22 = n1 + n3
	local v23 = t1[v22]

	if v23 then
		table.insert(v23, p5)
	else
		t1[v22] = { p5 }
		v5.insert(v22)
	end

	local u24 = false

	return function() -- line: 67
		-- upvalues: u24 (ref), t1 (copy), v22 (copy), p5 (copy)
		if u24 then
			return
		end

		u24 = true

		local v25 = t1[v22]

		if v25 then
			for i = #v25, 1.0, -1.0 do
				if v25[i] == p5 then
					table.remove(v25, i)

					break
				end
			end

			if #v25 == 0.0 then
				t1[v22] = nil
			end
		end
	end
end

return AddDebris

