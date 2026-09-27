-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBEVudW0ISW5mb1R5cGUHUHJvZHVjdAhHYW1lUGFzcw5nZXRQcm9kdWN0SW5mbwRJbmZvCUlzRm9yU2FsZQxQcmljZUluUm9idXgEdHlwZQZudW1iZXIEd2Fybh1GYWlsZWQgdG8gZ3JhYiBwcmljZSBmb3IgSUQgKAEpB3JlcXVpcmUGc2NyaXB0BlBhcmVudAxQcm9kdWN0Q2FjaGUAAgoCAQAABwQAAAUCAoEwDgEDAKQCAwACBADAKwICAKQCBQAEBADA+wMAAE0DA5UGAAAAUgQAAFIFAgCfAwMCUgQDAA4EAgBNBAN6BwAAAA4EFQBNBQQbCAAAAA4FDwBNBQQbCQAAALsoBQNSBwUApAYLAAAAoECfBgIC8AYEAAwAAIBSBgUAqQcBAIIGAwCMBgAAqQcAAIIGAwCMBQAAqQYAAIIFAwCkBQ4AAADQQG8HDwBSCAAAbwkQAHMGBwmfBQIBjAUAAKkGAACCBQMAEQMBAwIDAwQCBADAAwQEBAQAwAMFAwYDBwMIAwkEAACgQAMKAwsEAADQQAMMAw0AAwABGAAAAAAAAAEAAAAAAAEAAAABAQAAAQABAAAAAAAAAQAAAgAAAwAAAwAAAAAAAAEAAAQAAAAAAgAAAQIADaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQHHBQAAAJ8AAgLAAQYAEgAAAIIBAgAHAw4EAAAAQAMPBAAAIEADEAMRBgABAAEAARgAAAAAAAAAAAAAAgAAAQAAAAABa4se1dhqRx1WpSKFy6GiLxuTCaFZT3TU

-- decompilation:
local ProductCache = require(script.Parent.ProductCache)

return function(n1: number, b1: boolean?) -- line: 3
	-- upvalues: ProductCache (copy)
	local v4 = b1 and Enum.InfoType.Product or Enum.InfoType.GamePass
	local v5 = ProductCache.getProductInfo(n1, v4)
	local v6 = v5 and v5.Info

	if v6 then
		if v6.IsForSale then
			local PriceInRobux = v6.PriceInRobux

			if type(PriceInRobux) == "number" then
				return PriceInRobux, true
			end

			return 0.0, false
		end

		return 0.0, false
	end

	warn("Failed to grab price for ID (" .. n1 .. ")")

	return 0.0, false
end

