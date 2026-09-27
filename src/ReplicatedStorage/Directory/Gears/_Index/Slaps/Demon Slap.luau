-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uHHJieGFzc2V0aWQ6Ly8xMDMyMzU0NzIxOTcyODgLRGlzcGxheU5hbWUJTW9uZXlDb3N0DlNob3BEcm9wV2VpZ2h0FE1pblNob3BTdG9ja1F1YW50aXR5FE1heFNob3BTdG9ja1F1YW50aXR5DlRvb2xDb250cm9sbGVyBFNsYXAOQ29udHJvbGxlckRhdGEJU2xhcFBvd2VyC0Rlc2NyaXB0aW9uRVVubGVhc2ggYSBkZW1vbmljIHNsYXAgdGhhdCByYWdkb2xscyB2aWN0aW1zIHdpdGggb3ZlcndoZWxtaW5nIGZvcmNlLgZSYXJpdHkJUHJpc21hdGljClBlcnNpc3RlbnQOU2luZ2xlUHVyY2hhc2UETmFtZQZQbGF5ZXIIQnJhaW5yb3QIRHVyYXRpb24FRm9yY2UOQnJhaW5yb3REYW1hZ2USTWF4QnJhaW5yb3RUYXJnZXRzB19faW5kZXgMc2V0bWV0YXRhYmxlAAEGAAABAgA4owAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEBJAQAAABNAQHvBQAAAE0BAQ8GAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAiQEAAAATQICJAQAAABNAgI6BwAAAE0CAjoIAAAAnwECAuIDIACkBAMAAAAgQE0EBLohAAAAMAQDVwsAAADiBCQA4gUsADAFBPkiAAAA4gUuADAFBF0jAAAAMAQDNxUAAADiBDAAMAEEbi8AAACePQMDBAAAAKQCMgAAABBDnwIDAoICAgAzAwEEAAAAQAMCBAAAIEADAwMEAwUDBgMHAwgDCQMKAwsCAAAAAODIUEEDDAIAAAAAAADQPwMNAgAAAAAAAPA/Aw4DDwMQAxEDEgIAAAAAAABUQAMTAxQDFQMWAxcBAAMYAQEIDQkKAAAAC/////8MDQAAAA4PAAAAEBEAAAASEQAAABMUAAAAFf////8WFwAAABgZAAAAGhsAAAAcHQAAAB4fAAAAAxkDGgMbBQIiIwMcAnsUrkfhevA/Ax0CAAAAAACAQUADHgIAAAAAAABEQAMfCAQlJgAAACcoAAAAKSoAAAArEQAAAAIAAAAAAADgPwgEJS0AAAAnKAAAACkqAAAAKxEAAAADIAUBLwMhBAAAEEMAAQABGAADAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAEAgAAAAAABgEAAAYAAPkAFAAAAADjAAAAAQAAAAAAGfUanW7mZlXiHsxGWkYaPmntDekrMXCc

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://103235472197288",
	MoneyCost = 4400000.0,
	ShopDropWeight = 0.25,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "Slap",
	SlapPower = 80.0,
	Description = "Unleash a demonic slap that ragdolls victims with overwhelming force.",
	Rarity = "Prismatic",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name,
	ControllerData = {
		Player = {
			Duration = 1.03,
			Force = 35.0,
			BrainrotDamage = 40.0,
			MaxBrainrotTargets = 1.0
		},
		Brainrot = {
			Duration = 0.5,
			Force = 35.0,
			BrainrotDamage = 40.0,
			MaxBrainrotTargets = 1.0
		}
	}
}, {
	__index = Default
}))

