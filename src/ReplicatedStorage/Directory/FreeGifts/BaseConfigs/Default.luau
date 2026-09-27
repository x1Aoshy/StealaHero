-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MPUmV3YXJkVGVtcGxhdGVzBFR5cGUERWFzeQdSZXdhcmRzLkNsb25lQ3VycmVudFNwZWVkUG93ZXJPckN1cnJlbnRTdGVwTW9uZXlSZXdhcmQETmFtZQABBgAAAQIAKqMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BAe8FAAAATQEBDwYAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgI6BwAAAE0CApUIAAAAnwECAuICDAD/AwAAAQAAAE0EAeANAAAApAUDAAAAIEBNBQW6DgAAAJ8EAgDFAwQAAQAAADADAhULAAAAggICAA8DAQQAAABAAwIEAAAgQAMDAwQDBQMGAwcDCAMJAwoIAgkKAAAAC/////8DCwMMAAEAARgAAwAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAADAgABAAAAAAAAAAD/AAABAAAAAADmaXZL6OOPetXfbBirBviylnFhP9StHEo=

-- decompilation:
require(script.Parent.Parent.Types.Interface)

local RewardTemplates = require(script.Parent.Parent.BaseConfigs.RewardTemplates)

return {
	Type = "Easy",
	Rewards = { RewardTemplates.CloneCurrentSpeedPowerOrCurrentStepMoneyReward(script.Name) }
}

