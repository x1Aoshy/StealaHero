-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMODUFzc2V0SXRlbURhdGEGYXNzZXJ0FUdldFJhdGVXaXRob3V0UmViaXJ0aARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQlEaXJlY3RvcnkGQXNzZXRzB0xpYnJhcnkFVHlwZXMJQXNzZXRJdGVtBFV0aWwTQXNzZXRHZW5lcmF0aW9uVXRpbAACBAECAAAAEPsCAABNAgK8AAAAAFIDAACfAgIATAEAAqQBAgAAABBAnwEAAfsCAQBNAgIzBAAAAFIDAACfAgICWwECA4IBAgAFAwEDAgQAABBAAgAAAAAAAFlAAwMADQABGAAAAAAAAAAAAAIAAAAAAAAOAAAAAAUAAAECACSjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgCRBgAAAE0CAoEHAAAAnwECAqQCBQAAAEBATQMAaggAAABNAwPvCQAAAE0DA+YKAAAAnwICAqQDBQAAAEBATQQAaggAAABNBASeCwAAAE0EBLcMAAAAnwMCAsAEDQASAAIAEgADAIIEAgAOAwQEAAAAQAMFAwYDBwQAAEBAAwgDCQMKAwsDDAMNAw4GAAEAAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAAAgAAAAAAAAAAAwAAAAEAAAAAAc4LKtN7Ysy7Uyj+SJlluTC+Ez2n/M9A0g==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Directory.Assets)

local AssetItem = require(ReplicatedStorage.Library.Types.AssetItem)
local AssetGenerationUtil = require(ReplicatedStorage.Library.Util.AssetGenerationUtil)

return function(p1) -- line: 13
	-- upvalues: AssetItem (copy), AssetGenerationUtil (copy)
	assert(AssetItem.AssetItemData(p1))

	return AssetGenerationUtil.GetRateWithoutRebirth(p1) * 100.0
end

