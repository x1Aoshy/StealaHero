-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBlBvaW50cwlObyBwb2ludHMGYXNzZXJ0D3RyYW5zbGF0ZVZlY3RvcgZpcGFpcnMJTWFnbml0dWRlD1NlcGFyYXRpb25MaW1pdAhfQ29tcGlsZQNHZXQDbmV3El9Db3B5Q29uZmlndXJhdGlvbgVDbG9uZQxzZXRtZXRhdGFibGUHcmVxdWlyZQZzY3JpcHQGUGFyZW50B0FsZ2VicmEMV2FpdEZvckNoaWxkBlZlY3RvcgZNYXRyaXgGU29sdmVyB19faW5kZXgABA0CAAAAADZNBQAtAAAAABwEBQCMBQAAtwUCAAQAAACpAwABqQMBAIEBAwQBAAAAbwQBAKQCAwAAACBAnwIDAU0CAL8EAAAAUgMBAJ8CAgJSAQIATQIALQAAAADGAwAAbwQFAMYFAACMBgAApAcHAAAAYEBSCAIAnwcCBFEHDQAmDAsBTQwMqggAAAAOAwIAYAwDAAQAAABSAwsAUgQMAA4FAgBgBgMADAAAAFIFCwBSBgwAbgfy/wIAAIBNCAACCQAAAOwHBAhSCgEAUgsHALwIAAgKAAAAnwgEAIIIAAALAwEDAgMDBAAAIEADBAIAAAAAAADwfwMFBAAAYEADBgMHAwgADgkBGAAAAAAAAAAAAAAAAAAAAQAAAAACAAEBAQECAAAAAAEAAAEAAAEBAgAAAQH4AAwAAAMAAAAAAA8AAAAABQEBAAAACfsBAABNAQHvAAAAAJ8BAQJSBAEAvAIADAEAAACfAgMAggIAAAIDCgMLACoMARgAAAAAAQAAAAArAAAAAAQAAgEAABKjAAAA+wAAAE0AAO8AAAAA3QEAAJ8AAAL/AQAAAAAAADABAC0BAAAA+wMBAJ49AAQDAAAAUgIAAKQBAwAAACBAnwEDAYIAAgAEAwoDAQMNBAAAIEAALwoBGAABAAAAAAEAAAABAAAAAAAAAS8AAAAABwAAAQIARqMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAG8DBQC8AQHTBgAAAJ8BAwJvAwcAvAEB0wYAAACfAQMAnwAAAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAAbwQFALwCAtMGAAAAnwIDAm8ECAC8AgLTBgAAAJ8CAwCfAQACpAIBAAAAAECkAwMAAAAgQE0DAyQEAAAAbwUJALwDA9MGAAAAnwMDAJ8CAAL/AwMAAAAAADADA24KAAAAwAQLADAEA38MAAAAwAQNABIAAwAwBAM6DgAAAMAEDwASAAIAEgADADAEA+8QAAAAnj0DBQIAAABSBQMAUgYCAKQEEgAAABBBnwQDAYIDAgATAw4EAAAAQAMPBAAAIEADEAMRAxIDEwMUAxUDFgYAAwkGAQMMBgIDCgMNBAAAEEEDAAECAQABGAABAAAAAAAAAAAAAAAAAAAAAAMAAAAAAAAAAAAAAAAAAAAAAwAAAAAAAAAAAAADAAEAAgAAHAAAAAUAAAAABwAAAAAAAAIBAAAAAAO7xwjiWszOnP/jzLayNqhyy98flokDYuM=

-- decompilation:
require(script.Parent.Parent:WaitForChild("Algebra"):WaitForChild("Vector"))
require(script.Parent.Parent:WaitForChild("Algebra"):WaitForChild("Matrix"))

local Solver = require(script.Parent:WaitForChild("Solver"))
local t1 = {}

t1.__index = t1

function t1.Get(p1, p2) -- line: 14
	assert(#p1.Points > 0.0, "No points")

	local v5 = p1.translateVector(p2)
	local Points = p1.Points
	local v7 = nil
	local n1 = 1e999
	local v9 = nil
	local n2 = 0.0

	for _, v in ipairs(Points) do
		local Magnitude = (v - v5).Magnitude

		if not v7 or Magnitude < n1 then
			v7 = v
			n1 = Magnitude
		end

		if not v9 or n2 < Magnitude then
			v9 = v
			n2 = Magnitude
		end
	end

	return p1:_Compile(v5, n1 / p1.SeparationLimit)
end
function t1.Clone(p3) -- line: 42
	-- upvalues: t1 (copy)
	return p3:_CopyConfiguration((t1.new()))
end
function t1.new(...) -- line: 47
	-- upvalues: Solver (copy), t1 (copy)
	local v15 = Solver.new(...)

	v15.Points = {}
	setmetatable(v15, t1)

	return v15
end

setmetatable(t1, Solver)

return t1

