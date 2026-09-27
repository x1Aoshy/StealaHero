-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBGxlcnAEZWFzZQZ0eXBlb2YHVmVjdG9yMgdWZWN0b3IzBXRhYmxlDGdldG1ldGF0YWJsZQh0eXBlTGVycAZpbnNlcnQFc29sdmUGYXNzZXJ0EW5vdCBlbm91Z2ggcG9pbnRzBmJlemllcgdyZXF1aXJlBnNjcmlwdAZQYXJlbnQFVHlwZXMGVmVjdG9yDFdhaXRGb3JDaGlsZAZNYXRyaXgHX19pbmRleARMZXJwBEVhc2UBBAAHBwMBAAAABvsDAABSBAAAUgUBAFIGAgCfAwQAggMAAAAAJwEBGAAAAAAAACgAAAAABwMBAAAABvsDAABSBAAAUgUBAFIGAgCfAwQAggMAAAAANAIBGAAAAAAAADUAAAAABwMCAAAIBQAABQMPDwIxuywAA1IEAACkAwEAAAAAQJ8DAgLwAwcAAgAAgPsDAABSBAAAUgUBAFIGAgCfAwQAggMAALssAANSBAAApAMBAAAAAECfAwIC8AMHAAMAAID7AwAAUgQAAFIFAQBSBgIAnwMEAIIDAAC7LAADUgQAAKQDAQAAAABAnwMCAvADDwAEAACAuzwAA1IEAACkAwYAAABQQJ8DAgL7BAEAmgMHAAQAAAD7AwAAUgQAAFIFAQBSBgIAnwMEAIIDAADGAwAAggMCAAcDAwQAAABAAwQDBQMGAwcEAABQQABECAEYAAAAAAAAAAEAAAAAAAEAAAAAAAABAAAAAAABAAAAAAAAAAAAAAAAAAABAAAAAAACAEUAAAAADQIDAAAHBAAABQICBCf/AgAAAAAAAMADAAASAgAAEgIBAIwGAQAcBwEAeAQHAYwFAQCoBBIAhwcBBpUJBgGHCAEJUgkDAFIKBwBSCwgAUgwAAJ8JBAJHCQgAAAAAAJ40AgUJAAAAUgsCAFIMCQCkCgQAAAwggJ8KAwGLBO7/HAQCAIwFAQB9BAMABQAAABMEAgCCBAIA+wQCAFIFAABSBgIAnwQDAIIEAAAFBgICAAAAAAAA8D8DBgMJBAAMIIABAkIKARgAAAEAAAsAAAAAAQEAAQAAAAABAAEAAAAAAAD7CAAAAAEAAgAAAABDAAAAAAQBAgAAABb7AwAARwMCAAAAAICpAgABqQIBALsBAgKkAQEAAAAAQJ8BAgH7AQEAUgIAAPsDAACfAQMCRwECAAAAAICpAwABqQMBALsBAwKkAgEAAAAAQJ8CAgGCAQIAAgMLBAAAAEAAXgABGAAAAAAAAAAAAAEAAAABAAAAAAAAAAFfAAAAAAUAAgEAABqjAAAA/wAAAAAAAADdAQAAxQABAAEAAAAcAwAAjAQBALcEAgADAAAAqQIAAakCAQCBAQIEAAAAAG8DAACkAQIAAAAQQJ8BAwHAAQMAEgIAABICAQASAAEA2QIBABIAAAASAAEAggICAAQDDAMLBAAAEEAGAwIDBD8NARgAAQAAAAABAAAAAAAAAAAAAAABAAAAHAAAAD8AAAAABwAAAQIAQKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQHvBQAAAJ8AAgKkAQEAAAAAQKQCAwAAACBAbwQGALwCAtMHAAAAnwIDAJ8BAAKkAgEAAAAAQKQDAwAAACBAbwUIALwDA9MHAAAAnwMDAJ8CAAL/AwQAAAAAADADA24JAAAAMAEDSgYAAAAwAgPxCAAAAKQEAQAAAABApAUDAAAAIEBNBQVfCgAAAJ8EAgLABQsAEgAEADAFA78MAAAApAUBAAAAAECkBgMAAAAgQE0GBi0NAAAAnwUCAsAGDgASAAUAMAYDTQ8AAADABhAAEgAEABIAAQAwBgMGEQAAAIIDAgASAw4EAAAAQAMPBAAAIEADEAMRAxIDEwMUAxUDFgYAAwEDFwYBAwIGBQMNAwABBQEAARgAAgAAAAAAAAAABQAAAAAAAAAAAgAAAAAAAAAABQABAAYABgAKAAAAAAAAAQAAAAwAAAAAAAABAAAACwAAAAAmAQAAAAAGrbX4s+Un6uDdUNEIN2YPdt2t78efcZKy

-- decompilation:
require(script.Parent.Types)

local Vector = require(script:WaitForChild("Vector"))
local Matrix = require(script:WaitForChild("Matrix"))
local t1 = {}

t1.__index = t1
t1.Vector = Vector
t1.Matrix = Matrix

local Lerp = require(script.Lerp)

function t1.lerp(p1, p2, p3) -- line: 39
	-- upvalues: Lerp (copy)
	return Lerp(p1, p2, p3)
end

local Ease = require(script.Ease)

function t1.ease(p4, p5, p6) -- line: 52
	-- upvalues: Ease (copy)
	return Ease(p4, p5, p6)
end
function t1.bezier(...) -- line: 63
	-- upvalues: Lerp (copy), Vector (copy)
	local t2 = { ... }

	assert(#t2 > 1.0, "not enough points")

	local function solve(n1: number, t3: {[any]: any}) -- line: 66
		-- upvalues: Lerp (copy), Vector (copy), solve (copy)
		local t4 = {}

		local function typeLerp(p7, p8, n2: number) -- line: 68
			-- upvalues: Lerp (copy), Vector (copy)
			if typeof(p7) == "Vector2" then
				return Lerp(p7, p8, n2)
			end

			if typeof(p7) == "Vector3" then
				return Lerp(p7, p8, n2)
			end

			if typeof(p7) == "table" and getmetatable(p7) == Vector then
				return Lerp(p7, p8, n2)
			end

			return nil
		end

		for i = 1.0, #t3 - 1.0 do
			local v19 = typeLerp(t3[i], t3[i + 1.0], n1)

			if v19 ~= nil then
				table.insert(t4, v19)
			end
		end

		if #t4 <= 1.0 then
			return t4[1.0]
		end

		return solve(n1, t4)
	end

	return function(p9) -- line: 94
		-- upvalues: t2 (copy), solve (copy)
		assert(t2 ~= nil)

		local v21 = solve(p9, t2)

		assert(v21 ~= nil)

		return v21
	end
end

return t1

