-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIBXBjYWxsDVJlbmRlclN0ZXBwZWQEV2FpdAZ1bnBhY2sEZ2FtZQpTdGFydGVyR3VpCkdldFNlcnZpY2UKUnVuU2VydmljZQACCgECAQAAIqMBAAD/AQAAAAAAAIwEAQCMAggAjAMBAKgCFQD/BQAAAQAAAKQGAQAAAABA+wgAAIcHCAD7CAAA3QkAAJ8GAADFBQYAAQAAAFIBBQATBQEAKwUHAPsFAQBNBQXPAgAAALwFBfcDAAAAnwUCAYsC6/+7NQEDUgMBAKQCBQAAAEBAnwICAIICAAAGAwEEAAAAQAMCAwMDBAQAAEBAAAMAARgAAQABAAAAAQAAAAAAAAAAAAAAAQADAAAAAAD7BwAAAAAAAwAAAAAEAAABAgARowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAsACBQASAAAAEgABAIICAgAGAwUEAAAAQAMGAwcDCAYAAQABAAEYAAAAAAAAAAEAAAAAAAEAAAABAAAAAAHGQOewuU83hk6eUTnIGP5EtljwxPSEjbE=

-- decompilation:
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

return function(p1, ...) -- line: 3
	-- upvalues: StarterGui (copy), RunService (copy)
	local t1 = {}

	for _ = 1.0, 8.0 do
		t1 = { pcall(StarterGui[p1], StarterGui, ...) }

		if t1[1.0] then
			return unpack(t1)
		end

		RunService.RenderStepped:Wait()
	end

	return unpack(t1)
end

