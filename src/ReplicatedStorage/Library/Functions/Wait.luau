-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMFCk5leHROdW1iZXIEdGFzawR3YWl0BlJhbmRvbQNuZXcAAgYCAQAAAA0OAQcA+wIAAFIEAABSBQEAvAIChQAAAACfAgQCUgACAKQCAwAACBCAUgMAAJ8CAgGCAAEABAMBAwIDAwQACBCAAAMAARgAAQAAAAAAAAIAAAABBAAAAAACAAABAgAHowAAAKQAAgAABACAnwABAsABAwASAAAAggECAAQDBAMFBAAEAIAGAAEAAQABGAAAAAACAAABAAAAAAE=

-- decompilation:
local random = Random.new()

return function(p1, p2) -- line: 3
	-- upvalues: random (copy)
	if p2 then
		p1 = random:NextNumber(p1, p2)
	end

	task.wait(p1)
end

