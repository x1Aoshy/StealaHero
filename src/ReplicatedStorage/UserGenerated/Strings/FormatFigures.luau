-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKDUZvcm1hdEZpZ3VyZXMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUNVXNlckdlbmVyYXRlZARNYXRoDFJvdW5kRmlndXJlcwdTdHJpbmdzBkNvbW1hcwACCgQCAAALBgIABQQCgoKFDw8J+wQAAPsFAQBSBgAAUgcBAFIIAgBSCQMAnwUFAJ8EAACCBAAAAAAsAQEYAAAAAAAAAAAALQAAAAAEAAABAxMAAAQPAAEcDwEHFg8CEA0PAxkEHaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAOAGAAAATQICjAcAAABNAgK9CAAAAJ8BAgKkAgUAAABAQE0DAOAGAAAATQMDHwkAAABNAwPOCgAAAJ8CAgLAAwsAEgACABIAAQCCAwIADAMCBAAAAEADAwMEAwUEAABAQAMGAwcDCAMJAwoGAAEAAQABGAATAAAAAAACAAAAAAAAAAABAAAAAAAAAAAVAAAEAQAAAAAB00ago/XASICokmCmDSbSl6Net9fhgsqi

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFigures = require(ReplicatedStorage.UserGenerated.Math.RoundFigures)
local Commas = require(ReplicatedStorage.UserGenerated.Strings.Commas)

local function FormatFigures(n1: number, n2: number?, n3: number?, p1: ((...any) -> ...any)?) -- line: 44
	-- upvalues: Commas (copy), RoundFigures (copy)
	return Commas(RoundFigures(n1, n2, n3, p1))
end

return FormatFigures

