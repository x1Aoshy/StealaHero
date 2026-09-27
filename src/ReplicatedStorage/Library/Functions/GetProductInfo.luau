-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJDmdldFByb2R1Y3RJbmZvBEVudW0ISW5mb1R5cGUHUHJvZHVjdARJbmZvB3JlcXVpcmUGc2NyaXB0BlBhcmVudAxQcm9kdWN0Q2FjaGUAAgUCAQAAAAz7AgAATQIClQAAAABSAwAAUgQBACsEAgCkBAQAAwgQwJ8CAwJNAgJ6BQAAAIICAgAGAwEDAgMDAwQEAwgQwAMFAAMAARgAAAAAAAAAAAAAAAAEAAAAAAIAAAECAA2jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBxwUAAACfAAICwAEGABIAAACCAQIABwMGBAAAAEADBwQAACBAAwgDCQYAAQABAAEYAAAAAAAAAAAAAAIAAAEAAAAAAfJvNXD3FA0CCYJ3/cBGOzeCdyIEwKtfcQ==

-- decompilation:
local ProductCache = require(script.Parent.ProductCache)

return function(p1, p2) -- line: 3
	-- upvalues: ProductCache (copy)
	return ProductCache.getProductInfo(p1, p2 or Enum.InfoType.Product).Info
end

