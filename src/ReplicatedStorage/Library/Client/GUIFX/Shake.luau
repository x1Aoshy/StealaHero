-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Library = game:GetService("ReplicatedStorage"):WaitForChild("Library")
local Functions = require(Library.Functions)
local t1 = {}

return function(p1, p2, p3, p4, p5) -- line: 6
	-- upvalues: t1 (copy), Functions (copy)
	if not t1[p1] then
		t1[p1] = true
		task.spawn(function() -- line: 9
			-- upvalues: p1 (copy), p2 (copy), p3 (ref), p4 (ref), p5 (ref), Functions (copy), t1 (copy)
			local p1Rotation = p1.Rotation
			local v13 = p1Rotation + p2
			local v14 = p1Rotation - p2

			if p3 == nil then
				p3 = Enum.EasingStyle.Linear
			end

			if p4 == nil then
				p4 = 0.075
			end

			assert(p4)

			if p5 == nil then
				p5 = 1.0
			end

			assert(p5)

			for i = 1.0, p5 do
				Functions.Tween(p1, {
					Rotation = v13
				}, {
					p4,
					p3,
					"Out"
				}).Completed:Connect(function() -- line: 26
					-- upvalues: Functions (copy), p1 (copy), p1Rotation (copy), p4 (ref), p3 (ref), v14 (copy), i (copy), p5 (ref), t1 (copy)
					Functions.Tween(p1, {
						Rotation = p1Rotation
					}, {
						p4,
						p3,
						"Out"
					}).Completed:Connect(function() -- line: 28
						-- upvalues: Functions (copy), p1 (copy), v14 (copy), p4 (ref), p3 (ref), p1Rotation (copy), i (copy), p5 (ref), t1 (copy)
						Functions.Tween(p1, {
							Rotation = v14
						}, {
							p4,
							p3,
							"Out"
						}).Completed:Connect(function() -- line: 34
							-- upvalues: Functions (copy), p1 (copy), p1Rotation (copy), p4 (ref), p3 (ref), i (copy), p5 (ref), t1 (copy)
							Functions.Tween(p1, {
								Rotation = p1Rotation
							}, {
								p4,
								p3,
								"Out"
							}).Completed:Connect(function() -- line: 40
								-- upvalues: i (copy), p5 (ref), t1 (copy), p1 (copy)
								if i == p5 then
									t1[p1] = nil

									return true
								end
							end)
						end)
					end)
				end)
				task.wait(p4 * 4.0)
			end
		end)
	end
end

