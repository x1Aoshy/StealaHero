-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMCFlNldFJvdW5kVHV0b3JpYWxBY3RpdmUVSXNSb3VuZFR1dG9yaWFsQWN0aXZlAAMBAQEAAAYDAAAFAQEC3gAAAIIAAQAAAAoBARgAAQsAAAAAAQABAAAAAvsAAACCAAIAAAAOAgEYAAAPAAAAAAMAAAECAA6jAAAAqQAAAP8BAgAAAAAA2QIAABIBAP8wAgE3AAAAANkCAQASAQD/MAIBUQEAAADBAAAAggECAAIDAQMCAgABAQABGAADAwADAAAABAAAAAQAAQAAAAAC

-- decompilation:
local u1 = false

return {
	SetRoundTutorialActive = function(b1: boolean) -- line: 10
		-- upvalues: u1 (ref)
		u1 = b1
	end,
	IsRoundTutorialActive = function() -- line: 14
		-- upvalues: u1 (ref)
		return u1
	end
}

