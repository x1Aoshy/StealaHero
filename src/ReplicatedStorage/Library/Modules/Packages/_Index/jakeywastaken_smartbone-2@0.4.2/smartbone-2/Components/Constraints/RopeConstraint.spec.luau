-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local RopeConstraint = require(script.Parent:WaitForChild("RopeConstraint"))

local function CreateBone(p1, p2, p3) -- line: 3
	return {
		Position = p1,
		FreeLength = p2,
		ParentIndex = p3
	}
end

return function() -- line: 11
	-- upvalues: RopeConstraint (copy)
	local t1 = {
		Bones = {
			{
				Position = Vector3.new(0.0, 0.0, 0.0),
				FreeLength = 3.0,
				ParentIndex = 0.0
			},
			{
				Position = Vector3.new(0.0, 10.0, 0.0),
				FreeLength = 3.0,
				ParentIndex = 1.0
			}
		}
	}

	describe("Rope Constraint", function() -- line: 19
		-- upvalues: t1 (copy), RopeConstraint (copy)
		local v7 = t1.Bones[2.0]
		local n1 = 0.0
		local u9 = nil

		local function LimitCallback() -- line: 25
			-- upvalues: RopeConstraint (copy), v7 (copy), t1 (copy), u9 (ref)
			local v12 = RopeConstraint(v7, v7.Position, t1)

			expect(v12.Magnitude).to.equal(v7.FreeLength)
			v7.FreeLength = math.random(1.0, 20.0)
			u9()
		end
		local function SameCallback() -- line: 35
			-- upvalues: RopeConstraint (copy), v7 (copy), t1 (copy), u9 (ref)
			local v13 = RopeConstraint(v7, v7.Position, t1)

			expect(v13.Magnitude).to.equal(v7.Position.Magnitude)
			v7.FreeLength = math.random(1.0, 20.0)
			u9()
		end

		function u9() -- line: 45
			-- upvalues: n1 (ref), v7 (copy), SameCallback (copy), LimitCallback (copy)
			if n1 >= 10.0 then
				return
			end

			n1 += 1.0

			if v7.Position.Magnitude < v7.FreeLength then
				it(`Should stay the same #{ n1 }`, SameCallback)

				return
			end

			it(`Should limit to { v7.FreeLength } studs #{ n1 }`, LimitCallback)
		end

		u9()
	end)
end

