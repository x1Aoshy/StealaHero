-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJASUNRm9ybWF0UGVyY2VudARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQ1Vc2VyR2VuZXJhdGVkB1N0cmluZ3MNRm9ybWF0RmlndXJlcwACCAEBAAAHAwEABQECDwn7BAAAWwUAAIwGBACMBwUAnwQEAlICBABvAwEAcwECA4IBAgACAgAAAAAAAFlAAwEAGAIBGAAAAAAAAAAAABkAAAAAAwAAAQMPAAADDwABEg8BBwwPAhADE6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAOAGAAAATQICHwcAAABNAgIWCAAAAJ8BAgLAAgkAEgABAIICAgAKAwMEAAAAQAMEAwUDBgQAAEBAAwcDCAMJBgABAAEAARgAEwAAAAAAAgAAAAAAAAAAAgAEAQAAAAABY43u/x/QT0HAzaxcUK5ynhOV+YtRSYT+

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatFigures = require(ReplicatedStorage.UserGenerated.Strings.FormatFigures)

local function FormatPercent(n1: number) -- line: 24
	-- upvalues: FormatFigures (copy)
	return FormatFigures(n1 * 100.0, 4.0, 5.0) .. "%"
end

return FormatPercent

