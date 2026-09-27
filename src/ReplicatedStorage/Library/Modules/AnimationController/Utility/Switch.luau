-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKBl9zdGF0ZQNfZm4Nc3dpdGNoX3N3aXRjaApzd2l0Y2hfZ2V0IEEgZGVmYXVsdCBzdGF0ZSBtdXN0IGJlIHByb3ZpZGVkBmFzc2VydAZTd2l0Y2gDR2V0CnN3aXRjaF9uZXcDbmV3AAQFAgABAAcEAAAFAg8BDaMCAABNAgB1AAAAAPEBCAACAAAAMAEAdQAAAABNAgBoAQAAAFIDAQDdBAAAnwIAAYIAAQACAwEDAgAGAwEYAAEAAAABAAEAAAAAAgYAAAAAAgEAAAAAA00BAHUAAAAAggECAAEDAQANBAEYAAAADgAAAAAFAgIAAAcEAAAFAg8FFkcAAgAAAACAqQMAAakDAQCBAQMEAAAAAG8EAACkAgIAAAAQQJ8CAwHiAgcAMAECaAMAAAAwAAJ1BAAAAPsDAAAwAwKsBQAAAPsDAQAwAwJ/BgAAAIICAgAIAwUDBgQAABBAAwIDAQMHAwgFBAMEBQYAEgkBGAAAAAAAAAAAAAACAQABAAIAAAEAAAATAAAAAAQAAAECAAqjAAAAwAAAAMABAQDAAgIAEgAAABIAAQDiAwQAMAID7wMAAACCAwIABQYABgEGAgMKBQEDAwABAgEAARgABQcFAAAMAQAAAQAAAAAD3PtqqWibE1Ia9wqimZe3d6zjfd3uPwCo

-- decompilation:
local function switch_switch(p1, b1: boolean, ...) -- line: 6
	if b1 ~= p1._state then
		p1._state = b1
		p1._fn(b1, ...)
	end
end
local function switch_get(p2) -- line: 13
	return p2._state
end
local function switch_new(p3, p4: ((...any) -> ...any)) -- line: 18
	-- upvalues: switch_switch (copy), switch_get (copy)
	assert(p3 ~= nil, "A default state must be provided")

	return {
		_fn = p4,
		_state = p3,
		Switch = switch_switch,
		Get = switch_get
	}
end

return {
	new = switch_new
}

