-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMAAAIEAgAAAAALJgIAAW8DAABgAwMAAgAAAHgDAgGCAwIAbwMCAGACAgADAAAAlQICAYICAgADAhgtRFT7IQlAAhgtRFT7IRlAAhgtRFT7IQnAAAEAARgAAQAAAQACAAABAgIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAQ==

-- decompilation:
return function(p1, p2) -- line: 1
	local v3 = p1 - p2

	if v3 > 3.141592653589793 then
		return v3 - 6.283185307179586
	end

	if v3 < -3.141592653589793 then
		v3 += 6.283185307179586
	end

	return v3
end

