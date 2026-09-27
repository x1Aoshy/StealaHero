-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMDC05leHRJbnRlZ2VyBlJhbmRvbQNuZXcAAgoCAQAAABJSAgEAKwIBAPsCAAAcBQAAjAMCAIwE//+oAwoAjAgBAFIJBQC8BgKMAAAAAJ8GBAKHBwAGhwgABWoHAAVqCAAGiwP2/4IAAgABAwEAAwABGAAAAAEAAAABAAAAAAEAAAD+BAQAAAAAAgAAAQIAB6MAAACkAAIAAAQAgJ8AAQLAAQMAEgAAAIIBAgAEAwIDAwQABACABgABAAEAARgAAAAAAgAAAQAAAAAB

-- decompilation:
local random = Random.new()

return function(p1, p2) -- line: 3
	-- upvalues: random (copy)
	local v4 = p2 or random

	for i = #p1, 2.0, -1.0 do
		local v6 = v4:NextInteger(1.0, i)
		local v7 = p1[v6]
		local v8 = p1[i]

		p1[i] = v7
		p1[v6] = v8
	end

	return p1
end

