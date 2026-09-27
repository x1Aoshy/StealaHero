-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMDBG1hdGgFY2xhbXADUG9yAAIHAgAAAAAUjAQAAIwFAQA0LgAEBAUAAFIDAACkAgIAAAQAgJ8CBAKMBQAAjAYBADQuAQQFBgAAUgQBAKQDAgAABACAnwMEAkMFAgMJBgIDJgQFBoIEAgADAwEDAgQABACAAAEDARgAAAAAAAAAAAEAAAAAAAAAAQAAAAIAAAAAAQAAAQIAB6MAAADAAAAAGAAABgEAAAA1AAAGAQAAAIIAAgACBgADAwEAAQABGAAAAAAGAAABAAAAAAE=

-- decompilation:
function Por(p1, p2) -- line: 1
	local v3 = math.clamp(p1, 0.0, 1.0)
	local v4 = math.clamp(p2, 0.0, 1.0)

	return v3 + v4 - v3 * v4
end

return Por

