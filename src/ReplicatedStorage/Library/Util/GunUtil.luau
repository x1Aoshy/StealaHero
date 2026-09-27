-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRBXRhYmxlBWNsb25lEEdldEF2YWlsYWJsZUd1bnMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUJRGlyZWN0b3J5BUdlYXJzBVR5cGVzC1Rvb2xDb25maWdzBXBhaXJzDlRvb2xDb250cm9sbGVyA0d1bgNfaWQGaW5zZXJ0BmZyZWV6ZQACAgABAAAABaQAAgAABACA+wEAAJ8AAgCCAAAAAwMBAwIEAAQAgAAcAwEYAAAAAAAdAAAAAAwAAAEAADqjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgCRBgAAAE0CArMHAAAATQIC7wgAAABNAgKpCQAAAJ8BAgKkAgUAAABAQE0DAJEGAAAATQMDswcAAACfAgIC/wMAAAAAAACkBAsAAACgQE0FApEGAAAAnwQCBBcEDABNCQifDAAAAPAJCQANAACATQsI0w4AAACeNAMECwAAAFIKAwCkCREAAEDwgJ8JAwFuBPP/AgAAAKQEEwAASPCAUgUDAJ8EAgH/BAEAAAAAAMAFFAASAAMAMAUEqRUAAACCBAIAFgMEBAAAAEADBQMGAwcEAABAQAMIAwkDCgMLAwwEAACgQAMNAw4DDwMBAxAEAEDwgAMRBABI8IAGAAMDAQABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAQAAAAAAAAYAAgAAAAAAAQAAAAQAAAAAAAAA+wAHAAAAAwACAAAABAEAAAAAAQ6u9LyjmmNMhdcvP7yfvd5+tuPIPGqevQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Directory.Gears.Types.ToolConfigs)

local Gears = require(ReplicatedStorage.Directory.Gears)
local t1 = {}

for _, v in pairs(Gears.Directory) do
	if v.ToolController == "Gun" then
		table.insert(t1, v._id)
	end
end

table.freeze(t1)

return {
	GetAvailableGuns = function() -- line: 28
		-- upvalues: t1 (copy)
		return table.clone(t1)
	end
}

