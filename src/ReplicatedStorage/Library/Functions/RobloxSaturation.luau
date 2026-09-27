-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJAVIBRwFCBkNvbG9yMwNuZXcHcmVxdWlyZQZzY3JpcHQGUGFyZW50BExlcnAAAg0CAQAAACRNAgBzAAAAAE0DAGYBAAAATQQAYwIAAABbBwIDWwgDBEMGBwhbBwQFQwUGB/sGAABSBwUAUggCAIwKAQBDCQoBnwYEAvsHAABSCAUAUgkDAIwLAQBDCgsBnwcEAvsIAABSCQUAUgoEAIwMAQBDCwwBnwgEAqQJCAAAHGCAUgoGAFILBwBSDAgAnwkEAIIJAAAJAwEDAgMDAolBYOXQItM/AmIQWDm0yOI/Asl2vp8aL70/AwQDBQQAHGCAAAMAARgAAAEAAQABAAAAAAEAAAAAAAEAAAAAAAEAAAAAAAEAAAAAAAAEAAAAAAIAAAECAA2jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBXwUAAACfAAICwAEGABIAAACCAQIABwMGBAAAAEADBwQAACBAAwgDCQYAAQABAAEYAAAAAAAAAAAAAAIAAAEAAAAAATgu9ZBNozH71dH//G97v5xINuLkCuqfkQ==

-- decompilation:
local Lerp = require(script.Parent.Lerp)

return function(p1, p2) -- line: 3
	-- upvalues: Lerp (copy)
	local R = p1.R
	local G = p1.G
	local B = p1.B
	local v7 = R * 0.299 + G * 0.587 + B * 0.114
	local v8 = Lerp(v7, R, 1.0 + p2)
	local v9 = Lerp(v7, G, 1.0 + p2)
	local v10 = Lerp(v7, B, 1.0 + p2)

	return Color3.new(v8, v9, v10)
end

