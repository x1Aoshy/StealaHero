-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
return function() -- line: 1
	local Streamable = require(script.Parent.Streamable)
	local StreamableUtil = require(script.Parent.StreamableUtil)
	local Folder = nil

	local function CreateInstance(p1) -- line: 7
		-- upvalues: Folder (ref)
		local Folder2 = Instance.new("Folder")

		Folder2.Name = p1
		Folder2.Archivable = false
		Folder2.Parent = Folder

		return Folder2
	end

	beforeAll(function() -- line: 15
		-- upvalues: Folder (ref)
		Folder = Instance.new("Folder")
		Folder.Name = "KnitTest"
		Folder.Archivable = false
		Folder.Parent = workspace
	end)
	afterEach(function() -- line: 22
		-- upvalues: Folder (ref)
		Folder:ClearAllChildren()
	end)
	afterAll(function() -- line: 26
		-- upvalues: Folder (ref)
		Folder:Destroy()
	end)
	describe("Compound", function() -- line: 30
		-- upvalues: Streamable (copy), Folder (ref), StreamableUtil (copy)
		it("should capture multiple streams", function() -- line: 31
			-- upvalues: Streamable (copy), Folder (ref), StreamableUtil (copy)
			local v7 = Streamable.new(Folder, "ABC")
			local v8 = Streamable.new(Folder, "XYZ")
			local n1 = 0.0
			local n2 = 0.0

			StreamableUtil.Compound({
				S1 = v7,
				S2 = v8
			}, function(_, p3) -- line: 36
				-- upvalues: n1 (ref), n2 (ref)
				n1 += 1.0
				p3:Add(function() -- line: 38
					-- upvalues: n2 (ref)
					n2 += 1.0
				end)
			end)

			local Folder3 = Instance.new("Folder")

			Folder3.Name = "ABC"
			Folder3.Archivable = false
			Folder3.Parent = Folder

			local Folder4 = Instance.new("Folder")

			Folder4.Name = "XYZ"
			Folder4.Archivable = false
			Folder4.Parent = Folder
			task.wait()
			Folder3.Parent = nil
			task.wait()
			Folder3.Parent = Folder
			task.wait()
			Folder3.Parent = nil
			Folder4.Parent = nil
			task.wait()
			Folder4.Parent = Folder
			task.wait()
			expect(n1).to.equal(2.0)
			expect(n2).to.equal(2.0)
			v7:Destroy()
			v8:Destroy()
		end)
	end)
end

