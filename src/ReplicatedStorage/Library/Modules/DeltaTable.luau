-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLCERlZXBDb3B5BXBhaXJzBHR5cGUFdGFibGUOTWFrZURlbHRhVGFibGULX19kZWxldGlvbnMGaW5zZXJ0D0FwcGx5RGVsdGFUYWJsZQZjcmVhdGUERGVlcBNEZWVwQ29weVNoYXJlZFRhYmxlAAcOAwEAAABKRwEGAAAAAIBSBQIAvAMAhQAAAACfAwMAggMAAP8DAQAAAAAAjAQAAKQFAgAAABBAUgYCAJ8FAgQXBR4AhwoBCEcKAwAAAACAagkDCGUAGQCHCwIIuygLAqQKBAAAADBAnwoCAvAKDQAFAACA+woAAIcMAQiHDQIIvAoKgAYAAACfCgQDjAwAAGAMCgALAAAAlQQEB2oKAwhlAAYAhwoCCIcLAQjxCgMACwAAAJUEBAdqCgMIbgXh/wIAAACkBQIAAAAQQFIGAQCfBQIEFwUTAIcKAghHChEAAAAAgE0KAzYIAAAARwoFAAAAAID/CgAAAAAAADAKAzYIAAAATQsDNggAAACeNAsECAAAAFIMCACkCgoAACRQgJ8KAwFuBez/AgAAAIIDAwALAwEDAgQAABBAAwMEAAAwQAMEAwUCAAAAAAAA8D8DBgMHBAAkUIAABAUBGAAAAQAAAAADAAEBAAAAAAEAAAEAAgAAAAAAAAIAAAAAAAEAAAEBAAMBAQABAfAAFgAAAAABAAABAAAAAQAAAAIAAAAAAAAA+wAJBQAAAAANAwAAAAAyRwEDAAAAAID/AQAAAAAAAFIFAQC8AwCFAAAAAJ8DAwJHAwMAAAAAgP8DAAAAAAAApAQCAAAAEEBSBQIAnwQCBBcEEACHCgIHuygKAqQJBAAAADBAnwkCAvAJCAAFAACAhwsBB4cMAge8CQBIBgAAAJ8JBAJqCQMHZQACAIcJAgdqCQMHbgTv/wIAAABNBAM2BwAAAEcECwAAAAAApAQCAAAAEEBNBQM2BwAAAJ8EAgQXBAIAxgkAAGoJAwhuBP3/AgAAAIIDAgAIAwEDAgQAABBAAwMEAAAwQAMEAwgDBgAuCAEYAAABAAIAAAABAAEAAwAAAAABAAAAAAAAAQAAAAAAAAIA/AAIAAAAAQAAAAAAAQD/AAYvAAAAAAkBAQAAABmkAQIAAAQAgBwCAACfAQICpAIEAAAAMEBSAwAAnwICBBcCDQC7KAYDUggGAKQHBgAAAFBAnwcCAvAHBgAAAACA+wcAAFIIBgCfBwICagcBBWUAAQBqBgEFbgLy/wIAAACCAQIABwMEAwkEAAQAgAMCBAAAMEADAwQAAFBAAEoKARgAAAAAAQAAAAABAAAAAAAAAQAAAAAC/AAHSwAAAAAFAgAAAAAGwAIAABIAAgBSAwIAUgQBAJ8DAgKCAwIAAQYCAQJJAQEYAAALAAAASgAAAAAJAQEAAAAW/wEAAAAAAABSAgAAxgMAAMYEAABkAg0AuygGA1IIBgCkBwEAAAAAQJ8HAgLwBwYAAgAAgPsHAABSCAYAnwcCAmoHAQVlAAEAagYBBW4C8v8CAAAAggECAAMDAwQAAABAAwQAWQoBGAAAAQAAAAEAAAAAAAABAAAAAAL8AAdaAAAAAAUCAAAAAAbAAgAAEgACAFIDAgBSBAEAnwMCAoIDAgABBgQBBFgLARgAAAsAAABZAAAAAAIAAAECABGjAAAA/wADAAAAAADAAQAAEgAAADABAIABAAAAwAECADABAEgDAAAAwAEEADABAIUFAAAAwAEGADABAJAHAAAAggACAAgGAAMFBgEDCAYDAwEGBQMLBAABAwUBAAEYAAAAAwAAACoAABsAAA8AAA8BAAAAAAbMcEgLCyTCGSD4oG/u4ahrvGhff/60Igo=

-- decompilation:
local t1 = {}

function t1.MakeDeltaTable(p1, p2, p3) -- line: 4
	-- upvalues: t1 (copy)
	if p2 == nil then
		return p1:DeepCopy(p3)
	end

	local t2 = {}
	local n1 = 0.0

	for k, v in pairs(p3) do
		if p2[k] == nil then
			t2[k] = v
		elseif type(p3[k]) == "table" then
			local v9, v10 = t1:MakeDeltaTable(p2[k], p3[k])

			if v10 > 0.0 then
				n1 += 1.0
				t2[k] = v9
			end
		else
			local v11 = p3[k]

			if v11 ~= p2[k] then
				n1 += 1.0
				t2[k] = v11
			end
		end
	end

	for k, _ in pairs(p2) do
		if p3[k] == nil then
			if t2.__deletions == nil then
				t2.__deletions = {}
			end

			table.insert(t2.__deletions, k)
		end
	end

	return t2, n1
end
function t1.ApplyDeltaTable(p4, p5, p6) -- line: 46
	if p5 == nil then
		p5 = {}
	end

	local v17 = p4:DeepCopy(p5)

	if v17 == nil then
		v17 = {}
	end

	for k, _ in pairs(p6) do
		if type(p6[k]) == "table" then
			v17[k] = p4:ApplyDeltaTable(p5[k], p6[k])
		else
			v17[k] = p6[k]
		end
	end

	if v17.__deletions ~= nil then
		for _, v in pairs(v17.__deletions) do
			v17[v] = nil
		end
	end

	return v17
end
function t1.DeepCopy(_, p8) -- line: 73
	local function Deep(p9) -- line: 74
		-- upvalues: Deep (copy)
		local t3 = table.create(#p9)

		for k, v in pairs(p9) do
			if type(v) == "table" then
				t3[k] = Deep(v)
			else
				t3[k] = v
			end
		end

		return t3
	end

	return (Deep(p8))
end
function t1.DeepCopySharedTable(_, p11) -- line: 88
	local function Deep(p12) -- line: 89
		-- upvalues: Deep (copy)
		local t4 = {}

		for v34, v35 in p12 do
			if type(v35) == "table" then
				t4[v34] = Deep(v35)
			else
				t4[v34] = v35
			end
		end

		return t4
	end

	return (Deep(p11))
end

return t1

