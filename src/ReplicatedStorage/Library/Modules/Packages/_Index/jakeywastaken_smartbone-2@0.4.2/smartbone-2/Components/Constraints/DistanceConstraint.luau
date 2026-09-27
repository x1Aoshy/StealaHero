-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHCU1hZ25pdHVkZQRVbml0CFNhZmVVbml0BUJvbmVzC1BhcmVudEluZGV4CkZyZWVMZW5ndGgIUG9zaXRpb24AAwIBAAAAAAlNAQCqAAAAAA0BAwABAACAbwECAIIBAgBNAQAHAwAAAIIBAgAEAwECAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAMCAAEDARgAAAAAAQADAAACAAAAAAkDAAAAABlNBAJ4AAAAAE0FAM0BAAAAhwMEBQ4DEgBNBAB+AgAAAE0HAzsDAAAAJgYBB00HBqoEAAAADQcDAAUAAIBvBQYAZQACAE0FBgcHAAAATQcDOwMAAAAJCAUEQwYHCIIGAgCCAAEACAMEAwUDBgMHAwECAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAMCAAkAARgKAAAAAAIBAAEAAPIAAAABAAMADAAAAAQFAgAAAAACAAABAgAEowAAAMAAAADAAQEAggECAAIGAAYBAgABAQABGAAACAABAAAAAAKv9ywOkCt4sbMW4aq01VzO3+87ep0zRg8=

-- decompilation:
local function SafeUnit(p1) -- line: 1
	if p1.Magnitude == 0.0 then
		return (Vector3.new(0.0, 0.0, 0.0))
	end

	return p1.Unit
end

return function(p2, p3, p4) -- line: 9
	local v6 = p4.Bones[p2.ParentIndex]

	if v6 then
		local FreeLength = p2.FreeLength
		local v8 = p3 - v6.Position
		local v9 = if v8.Magnitude ~= 0.0 then v8.Unit else Vector3.new(0.0, 0.0, 0.0)

		return v6.Position + v9 * FreeLength
	end
end

