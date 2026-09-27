-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPDUNvbG9yU2VxdWVuY2UDbmV3FUNvbG9yU2VxdWVuY2VLZXlwb2ludA5OdW1iZXJTZXF1ZW5jZRZOdW1iZXJTZXF1ZW5jZUtleXBvaW50BlN0cm9rZQhHcmFkaWVudAhJbnN0YW5jZQ5TZXRPZmZzZXRTcGVlZBpTZXRUcmFuc3BhcmVuY3lPZmZzZXRTcGVlZAdFZmZlY3RzB3JlcXVpcmUGc2NyaXB0BlBhcmVudAZDb2xvcjMBDwACDgQBAAAJBgAABQQHAgJAXKQEAgAABACA/wUAAAMAAACkBgQAAAQwgIwHAABSCAMAnwYDAqQHBAAABDCAbwgFAFIJAwCfBwMCpAgEAAAEMICMCQEAUgoDAJ8IAwDFBQYAAQAAAJ8EAgKkBQcAAARggP8GAAAFAAAApAcJAAAEgICMCAAAjAkAAJ8HAwKkCAkAAASAgG8JCgCMCgEAnwgDAqQJCQAABICAbwoFAIwLAQCfCQMCpAoJAAAEgIBvCwsAjAwBAJ8KAwKkCwkAAASAgIwMAQCMDQAAnwsDAMUGBwABAAAAnwUCAvsGAABNBgalDAAAAE0GBu8BAAAAUgcAAFIIAgCfBgMC+wcAAE0HBz0NAAAATQcH7wEAAABNCAb0DgAAAFIJBABSCgUAnwcEAlIKAQCMCwEAvAgHWg8AAACfCAQBWwoBEIwLAQC8CAeZEQAAAJ8IBAHiCBMA/wkAAAIAAABSCgcAUgsGAMUJCgMBAAAAMAkIlxIAAACCCAIAFAMBAwIEAAQAgAMDBAAEMIACAAAAAAAA4D8DBAQABGCAAwUEAASAgAIAAAAAAADQPwIAAAAAAADoPwMGAwcDCAMJAs3MzMzMzOw/AwoDCwUBEgADAAEYAAAAAAEAAAAAAQAAAAABAAAAAAAA/QYAAAABAAAAAAEAAAAAAQAAAAABAAAAAAEAAAAAAAD7CAAAAAAAAAABAAAAAAAAAAAAAQAAAAABAAAAAAEBAAAAAAAAAAAEAAAAAAIAAAECAA2jAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAACfAAICwAEFABIAAACCAQIABgMMBAAAAEADDQQAACBAAw4GAAEAAQABGAAAAAAAAAAAAAACAAABAAAAAAE+6ymhpKS9NCRlQIpNxEIjTvM+1QwvQ6A=

-- decompilation:
local Parent = require(script.Parent.Parent)

return function(p1, n1: number, n2: number, color3: Color3) -- line: 3
	-- upvalues: Parent (copy)
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, color3),
		ColorSequenceKeypoint.new(0.5, color3),
		ColorSequenceKeypoint.new(1.0, color3)
	})
	local numberSequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.0),
		NumberSequenceKeypoint.new(0.25, 1.0),
		NumberSequenceKeypoint.new(0.5, 1.0),
		NumberSequenceKeypoint.new(0.75, 1.0),
		NumberSequenceKeypoint.new(1.0, 0.0)
	})
	local v8 = Parent.Stroke.new(p1, n2)
	local v9 = Parent.Gradient.new(v8.Instance, colorSequence, numberSequence)

	v9:SetOffsetSpeed(n1, 1.0)
	v9:SetTransparencyOffsetSpeed(n1 * 0.9, 1.0)

	return {
		Effects = {
			v9,
			v8
		}
	}
end

