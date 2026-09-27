-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMBUFycmF5B19faW5kZXgKX19uZXdpbmRleAVfX2xlbghuZXdwcm94eQxnZXRtZXRhdGFibGUDbmV3C2dldE9uZUluZGV4BHB1c2gFdGFibGUEc29ydANwb3AACQUCAQAAAAb7AwAATQMD/QAAAACVBAEBhwIDBIICAgACAwECAAAAAAAA8D8ACQIBGAAAAAAAAAoAAAAABQMBAAAABvsDAABNAwP9AAAAAJUEAQFqAgMEggABAAIDAQIAAAAAAADwPwANAwEYAAAAAAABDgAAAAACAAEAAAAF+wEAAE0BAf0AAAAAHAABAIIAAgABAwEAEQQBGAAAAAAAEgAAAAAEAQAAAAAcpAEBAAAAAECpAgEAnwECArs8AQNSAwEApAIDAAAAIECfAgICUgMAACsDAgD/AwAAAAAAADADAv0EAAAA2QMAABIAAgAwAwJuBQAAANkDAQASAAIAMAMCzgYAAADZAwIAEgACADADAtQHAAAAggECAAgDBQQAAABAAwYEAAAgQAMBAwIDAwMEAwABAgMHARgAAAAAAQAAAAACAAAAAAACAAAABAAAAAQAAAAEBAAAAAADAQAAAAAIuzwAA1ICAACkAQEAAAAAQJ8BAgJNAgH9AgAAAIICAgADAwYEAAAAQAMBABgIARgAAAAAAAEAABkAAAAAAwIAAAAAAxwCAABqAQACggABAAAAHQkBGAAAAR4AAAAABQIBAAAACqQCAgAABACA+wMAAE0DA8cDAAAAUgQAAJ8DAgJSBAEAnwIDAYIAAQAEAwoDCwQABACAAwgAIQsBGAAAAAAAAAAAAAEiAAAAAAQBAAAAAAYcAgAAeAECAIcCAAHGAwAAagMAAYICAgABAgAAAAAAAPA/ACUMARgAAAEBAAEmAAAAAAIAAAECABSjAAAA/wAEAAAAAADAAQAAMAEA7wEAAADAAQIAMAEAxwMAAADAAQQAMAEAOQUAAADAAQYAEgAAADABAOoHAAAAwAEIADABALQJAAAAggACAAoGAwMHBgQDCAYFAwkGBgMLBgcDDAUDBAUGBwEAARgAAAACAAAVAAAFAAAEAAAABAAABwEAAAAACHQudyT//fDtd8XcBhkiMzYENmBQRuodJQ==

-- decompilation:
local t1 = {
	new = function(p1) -- line: 3
		local v3 = newproxy(true)
		local mt = getmetatable(v3)

		mt.Array = p1 or {}

		function mt.__index(_, p3) -- line: 9
			-- upvalues: mt (copy)
			return mt.Array[p3 + 1.0]
		end
		function mt.__newindex(_, p5, p6) -- line: 13
			-- upvalues: mt (copy)
			mt.Array[p5 + 1.0] = p6
		end
		function mt.__len() -- line: 17
			-- upvalues: mt (copy)
			return #mt.Array
		end

		return v3
	end,
	getOneIndex = function(p7) -- line: 24
		return getmetatable(p7).Array
	end,
	push = function(p8, p9) -- line: 29
		p8[#p8] = p9
	end
}

function t1.sort(p10, p11) -- line: 33
	-- upvalues: t1 (copy)
	table.sort(t1.getOneIndex(p10), p11)
end
function t1.pop(p12) -- line: 37
	local v11 = #p12 - 1.0
	local v12 = p12[v11]

	p12[v11] = nil

	return v12
end

return t1

