-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
return function() -- line: 1
	local Parent = require(script.Parent)
	local Option = require(script.Parent.Parent.Option)

	describe("SerializeArgs", function() -- line: 5
		-- upvalues: Option (copy), Parent (copy)
		it("should serialize an option", function() -- line: 6
			-- upvalues: Option (copy), Parent (copy)
			local v3 = Option.Some(32.0)
			local v4 = table.unpack(Parent.SerializeArgs(v3))

			expect(v4.ClassName).to.equal("Option")
			expect(v4.Value).to.equal(32.0)
		end)
	end)
	describe("SerializeArgsAndUnpack", function() -- line: 14
		-- upvalues: Option (copy), Parent (copy)
		it("should serialize an option", function() -- line: 15
			-- upvalues: Option (copy), Parent (copy)
			local v5 = Option.Some(32.0)
			local v6 = Parent.SerializeArgsAndUnpack(v5)

			expect(v6.ClassName).to.equal("Option")
			expect(v6.Value).to.equal(32.0)
		end)
	end)
	describe("DeserializeArgs", function() -- line: 23
		-- upvalues: Parent (copy), Option (copy)
		it("should deserialize args to option", function() -- line: 24
			-- upvalues: Parent (copy), Option (copy)
			local t1 = {
				ClassName = "Option",
				Value = 32.0
			}
			local v8 = table.unpack(Parent.DeserializeArgs(t1))

			expect(Option.Is(v8)).to.equal(true)
			expect(v8:Contains(32.0)).to.equal(true)
		end)
	end)
	describe("DeserializeArgsAndUnpack", function() -- line: 35
		-- upvalues: Parent (copy), Option (copy)
		it("should deserialize args to option", function() -- line: 36
			-- upvalues: Parent (copy), Option (copy)
			local t2 = {
				ClassName = "Option",
				Value = 32.0
			}
			local v10 = Parent.DeserializeArgsAndUnpack(t2)

			expect(Option.Is(v10)).to.equal(true)
			expect(v10:Contains(32.0)).to.equal(true)
		end)
	end)
end

