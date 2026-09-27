-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOCU1hZ25pdHVkZQRVbml0CFNhZmVVbml0C1BhcmVudEluZGV4BUJvbmVzDVJvdGF0aW9uTGltaXQIUG9zaXRpb24EbWF0aANyYWQDRG90BGFjb3MFQ3Jvc3MGQ0ZyYW1lDWZyb21BeGlzQW5nbGUAAwIBAAAAAAlNAQCqAAAAAA0BAwABAACAbwECAIIBAgBNAQAHAwAAAIIBAgAEAwECAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAAAAMCAAEDARgAAAAAAQADAAACAAAAABIDAAAAAF1NAwDNAAAAAE0FAngBAAAAhwQFAysEAQCCAQIATQUEBgIAAACMBrQAfQYCAAUAAACCAQIATQcCeAEAAABNCATNAAAAAIcGBwgrBgEAggECAE0HBDsDAAAATQoEOwMAAABNCwY7AwAAACYJCgtNCgmqBAAAAA0KAwAFAACAbwgGAGUAAgBNCAkHBwAAACYJAQdNCQmqBAAAACYLAQdNDAuqBAAAAA0MAwAFAACAbwoGAGUAAgBNCgsHBwAAAIwLAAB9BQQACwAAAAkMCAlDCwcMggsCAE0MAAYCAAAAuxYMAqQLCgAAJICAnwsCAlIPCgC8DQgrCwAAAJ8NAwK7Aw0CpAwNAAAwgICfDAICxg0AAH0LFAAMAAAAUhEKALwPCLsOAAAAnw8DAk0QD6oEAAAADRADAAUAAIBvDgYAZQACAE0ODwcHAAAApA8RAABA8IBSEA4AUhELAJ8PAwIJDQ8IZQABAFINCgAJDg0JQwEHDoIBAgASAwQDBQMGAwcDAQIAAAAAAAAAAAcAAAAAAAAAAAAAAAAAAAAAAwIDCAMJBAAkgIADCgMLBAAwgIADDAMNAw4EAEDwgAAJAAEYCgABAAACAwMAAgAAAwMAAAAAAgMDAAEAAAAA3AAAAAEAAwAiAAAB2QAAAAEAAwAlAAADAAADAAAAAAABAAAAAAAAAAECAAEAAADMAAAAAQADADEAAAAAAAACAwAEAgAAAAACAAABAgAEowAAAMAAAADAAQEAggECAAIGAAYBAgABAQABGAAACAABAAAAAALGaEg64sBIMXd6Xif/N1k5tnBfTvSsIjs=

-- decompilation:
local function SafeUnit(p1) -- line: 1
	if p1.Magnitude == 0.0 then
		return (Vector3.new(0.0, 0.0, 0.0))
	end

	return p1.Unit
end

return function(p2, p3, p4) -- line: 9
	local ParentIndex = p2.ParentIndex
	local v7 = p4.Bones[ParentIndex]

	if not v7 then
		return p3
	end

	local RotationLimit = v7.RotationLimit

	if RotationLimit >= 180.0 then
		return p3
	end

	local v9 = p4.Bones[v7.ParentIndex]

	if not v9 then
		return p3
	end

	local Position = v7.Position
	local v11 = v7.Position - v9.Position
	local v12 = if v11.Magnitude ~= 0.0 then v11.Unit else Vector3.new(0.0, 0.0, 0.0)
	local Magnitude = (p3 - Position).Magnitude
	local v14 = p3 - Position
	local v15 = if v14.Magnitude ~= 0.0 then v14.Unit else Vector3.new(0.0, 0.0, 0.0)

	if RotationLimit <= 0.0 then
		return Position + v12 * Magnitude
	end

	local v16 = math.rad(p2.RotationLimit)

	if v16 <= math.acos((v12:Dot(v15))) then
		local v17 = v12:Cross(v15)
		local v18 = if v17.Magnitude ~= 0.0 then v17.Unit else Vector3.new(0.0, 0.0, 0.0)

		v15 = CFrame.fromAxisAngle(v18, v16) * v12
	end

	return Position + v15 * Magnitude
end

