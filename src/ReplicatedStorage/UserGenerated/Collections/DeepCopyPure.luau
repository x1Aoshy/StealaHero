-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGBHR5cGUFdGFibGUMZ2V0bWV0YXRhYmxlBmFzc2VydARuZXh0DERlZXBDb3B5UHVyZQACDQIAAAAfBAAGBQIPhA8JJQsPCioGDwckDA8IJAwPAhIjDwMeFzW7KAADUgMAAKQCAQAAAABAnwICAvACAgACAAAAggACALs8AANSBQAApAQEAAAAMECfBAICVgMEALsBAwKkAgYAAABQQJ8CAgFSAgEAKwICAP8CAAAAAAAAhwUCAFYEBQC7AQQCpAMGAAAAUECfAwIBqQMBAGoDAgD/AwAAAAAAAKQECAAAAHBAUgUAAMYGAAAXBAsANQkAEgkAAABSCgcAUgsCAJ8JAwI1CgASCQAAAFILCABSDAIAnwoDAmoKAwluBPT/AgAAAMYEAABqBAIAggMCAAoDAQQAAABAAwIDAwQAADBAAwQEAABQQAMFBAAAcEADBgAfBgEYAAAAAAAAAAEEAAAAAAAAAAAAAwAAAAEAAAAAAAEAAwABAAAAAAEAAAAAAQAAAAAB/QAFAAEgAAAAAAEAAAEDAAejAAAAwAAAABgAABIBAAAANQAAEgEAAACCAAIAAgYAAwYBAAEAARgAHgAAGAAAAQAAAAABHiEshAZ6TSDyM/T50Sirn245O/As5UaF

-- decompilation:
--!native
function DeepCopyPure(p1, t1: {[any]: any}?) -- line: 31
	if type(p1) ~= "table" then
		return p1
	end

	assert(not getmetatable(p1))

	local v3 = t1 or {}

	assert(not v3[p1])
	v3[p1] = true

	local t2 = {}

	for k, v in next, p1 do
		t2[DeepCopyPure(k, v3)] = DeepCopyPure(v, v3)
	end

	v3[p1] = nil

	return t2
end

return DeepCopyPure

