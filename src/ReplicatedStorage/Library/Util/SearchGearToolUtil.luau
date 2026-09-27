-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBnN0cmluZw5GaW5kRmlyc3RDaGlsZARUb29sA0lzQQZpcGFpcnMOR2V0RGVzY2VuZGFudHMETmFtZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMJR2VhclRvb2xzAAIKAQIAAAYDAAAFAQMn+wEAAE0BAUEAAAAAUgIAAJ8BAgH7AQEAUgMAAKkEAQC8AQEDAQAAAJ8BBAIOAQYAbwQCALwCAf4DAAAAnwIDAg4CAQCCAQIApAIFAAAAQED7AwEAvAMDRwYAAACfAwIAnwIABFECCgBNBwa6BwAAAJoHBwAAAAAAbwkCALwHBv4DAAAAnwcDAg4HAQCCBgIAbgL1/wIAAICCAAEACAMBAwIDAwMEAwUEAABAQAMGAwcADQABGAAAAAAAAgAAAAAAAQAAAAAAAQMAAAAAAAAAAQAAAAAAAAAAAf4ABg4AAAAABAAAAQIAFKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICTQIAlwgAAADAAwkAEgABABIAAgCCAwIACgMIBAAAAEADCQMKAwsEAABAQAMMAw0DDgYAAQABAAEYAAMAAAAAAAMAAAAAAAADAAMAAAABAAAAAAHfaCcCuoBpd0JJACVk+Fvbr3Awdu2sTQM=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local GearTools = ReplicatedStorage.GearTools

return function(s1: string) -- line: 13
	-- upvalues: Asserts (copy), GearTools (copy)
	Asserts.string(s1)

	local s1_2 = GearTools:FindFirstChild(s1, true)

	if s1_2 and s1_2:IsA("Tool") then
		return s1_2
	end

	for _, descendant in ipairs(GearTools:GetDescendants()) do
		if s1 == descendant.Name and descendant:IsA("Tool") then
			return descendant
		end
	end
end

