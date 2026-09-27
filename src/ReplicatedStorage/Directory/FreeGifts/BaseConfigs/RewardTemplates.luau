-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBXRhYmxlBWNsb25lAklkFmNsb25lQXNzZXRSZXdhcmRXaXRoSWQXY2xvbmVSYW5kb21SZXdhcmRXaXRoSWQuQ2xvbmVDdXJyZW50U3BlZWRQb3dlck9yQ3VycmVudFN0ZXBNb25leVJld2FyZDJDbG9uZUVwaWNDdXJyZW50U3BlZWRQb3dlck9yQ3VycmVudFN0ZXBNb25leVJld2FyZDdDbG9uZUxlZ2VuZGFyeUN1cnJlbnRTcGVlZFBvd2VyT3JDdXJyZW50U3RlcE1vbmV5UmV3YXJkEUNsb25lTGltaXRlZEJsb2NrBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkFVHlwZXMJRnJlZUdpZnRzAApUZW1wbGF0ZUlkCkx1Y2t5QmxvY2sIQ2F0ZWdvcnkNTGltaXRlZCBCbG9jaylSYW5kb21DdXJyZW50U3BlZWRQb3dlck9yQ3VycmVudFN0ZXBNb25leRFTcGVlZFBvd2VyUGVyY2VudAxNb25leVNlY29uZHMKQ3VycmVuY3lJZAVNb25leQAHBAIAAAAHBAAABQIPAwekAgIAAAQAgFIDAACfAgICMAEClAMAAACCAgIABAMBAwIEAAQAgAMDAC0EARgAAAAAAQABLgAAAAAEAgAAAAcEAAAFAg8DB6QCAgAABACAUgMAAJ8CAgIwAQKUAwAAAIICAgAEAwEDAgQABACAAwMAMwUBGAAAAAABAAE3AAAAAAUBAQAABgMAAAUBAwn7AgAApAMCAAAEAIBSBAIAnwMCAjAAA5QDAAAAUgEDAIIBAgAEAwEDAgQABACAAwMAPAYBGAj4AAAAAQABADcAAAAABQEBAAAGAwAABQEDCfsCAACkAwIAAAQAgFIEAgCfAwICMAADlAMAAABSAQMAggECAAQDAQMCBAAEAIADAwBCBwEYDvIAAAABAAEANwAAAAAFAQEAAAYDAAAFAQMJ+wIAAKQDAgAABACAUgQCAJ8DAgIwAAOUAwAAAFIBAwCCAQIABAMBAwIEAAQAgAMDAEgIARgU7AAAAAEAAQA3AAAAAAUBAQAABgMAAAUBAwn7AgAApAMCAAAEAIBSBAIAnwMCAjAAA5QDAAAAUgEDAIIBAgAEAwEDAgQABACAAwMATgkBGCPdAAAAAQABAC4AAAAACgAAAQIAKaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQIC7wcAAABNAgKxCAAAAJ8BAgL/AgMAAAAAAOIDDwDiBBcA4gUaAOIGHQDABx4AwAgfAMAJIAASAAQAMAkC4CEAAADACSIAEgAFADAJAv4jAAAAwAkkABIABgAwCQK8JQAAAMAJJgASAAMAMAkCsCcAAACCAgIAKAMKBAAAAEADCwMMAw0EAABAQAMOAw8DEAMDAxEDEgMTAxQDFQgDCQoAAAALDAAAAA0OAAAAAxYDFwK4HoXrUbiePwMYAgAAAAAAAE5AAxkDGggFCQoAAAALEAAAABESAAAAExQAAAAVFgAAAAJ7FK5H4XqkPwIAAAAAAMBSQAgFCQoAAAALEAAAABEYAAAAExkAAAAVFgAAAAKamZmZmZmpPwIAAAAAAIBWQAgFCQoAAAALEAAAABEbAAAAExwAAAAVFgAAAAYABgEGAgMGBgMDBwYEAwgGBQMJBgABAgMEBQEAARgAAwAAAAAAAwAAAAAAAAAABwACBggHCAYJAAAABgAAAAYAAAAGAAAABwEAAAAABrly6LhVnO+F8SZeaVSdVJvJav/Mi7aCuQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Types.FreeGifts)

local t1 = {}
local t2 = {
	Id = "",
	TemplateId = "LuckyBlock",
	Category = "Limited Block"
}
local t3 = {
	Id = "",
	TemplateId = "RandomCurrentSpeedPowerOrCurrentStepMoney",
	SpeedPowerPercent = 0.03,
	MoneySeconds = 60.0,
	CurrencyId = "Money"
}
local t4 = {
	Id = "",
	TemplateId = "RandomCurrentSpeedPowerOrCurrentStepMoney",
	SpeedPowerPercent = 0.04,
	MoneySeconds = 75.0,
	CurrencyId = "Money"
}
local t5 = {
	Id = "",
	TemplateId = "RandomCurrentSpeedPowerOrCurrentStepMoney",
	SpeedPowerPercent = 0.05,
	MoneySeconds = 90.0,
	CurrencyId = "Money"
}

local function cloneAssetRewardWithId(p1, s1: string) -- line: 45
	local v11 = table.clone(p1)

	v11.Id = s1

	return v11
end
local function cloneRandomRewardWithId(p2, s2: string) -- line: 51
	local v14 = table.clone(p2)

	v14.Id = s2

	return v14
end

function t1.CloneCurrentSpeedPowerOrCurrentStepMoneyReward(s3: string) -- line: 60
	-- upvalues: t3 (copy)
	local v16 = t3
	local v17 = table.clone(v16)

	v17.Id = s3

	return v17
end
function t1.CloneEpicCurrentSpeedPowerOrCurrentStepMoneyReward(s4: string) -- line: 66
	-- upvalues: t4 (copy)
	local v19 = t4
	local v20 = table.clone(v19)

	v20.Id = s4

	return v20
end
function t1.CloneLegendaryCurrentSpeedPowerOrCurrentStepMoneyReward(s5: string) -- line: 72
	-- upvalues: t5 (copy)
	local v22 = t5
	local v23 = table.clone(v22)

	v23.Id = s5

	return v23
end
function t1.CloneLimitedBlock(s6: string) -- line: 78
	-- upvalues: t2 (copy)
	local v25 = t2
	local v26 = table.clone(v25)

	v26.Id = s6

	return v26
end

return t1

