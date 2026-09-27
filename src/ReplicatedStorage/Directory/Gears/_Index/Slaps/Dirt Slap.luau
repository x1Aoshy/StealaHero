-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUeXBlcwlJbnRlcmZhY2ULQmFzZUNvbmZpZ3MHRGVmYXVsdARJY29uHHJieGFzc2V0aWQ6Ly8xMjY0MTYzMzEyMDY4NzELRGlzcGxheU5hbWUJTW9uZXlDb3N0DlNob3BEcm9wV2VpZ2h0FE1pblNob3BTdG9ja1F1YW50aXR5FE1heFNob3BTdG9ja1F1YW50aXR5DlRvb2xDb250cm9sbGVyBFNsYXAOQ29udHJvbGxlckRhdGEJU2xhcFBvd2VyC0Rlc2NyaXB0aW9uWUEgaGVhdnkgY2xvZCBvZiBkaXJ0IHRoYXQgc3BsYXR0ZXJzIG9wcG9uZW50cywgbGVhdmluZyB0aGVtIHN0dW5uZWQgYW5kIGNvdmVyZWQgaW4gZ3JpbWUuBlJhcml0eQZDb21tb24KUGVyc2lzdGVudA5TaW5nbGVQdXJjaGFzZQROYW1lBlBsYXllcghCcmFpbnJvdAhEdXJhdGlvbgVGb3JjZQ5CcmFpbnJvdERhbWFnZRJNYXhCcmFpbnJvdFRhcmdldHMHX19pbmRleAxzZXRtZXRhdGFibGUAAQYAAAECADijAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQEkBAAAAE0BAe8FAAAATQEBDwYAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICJAQAAABNAgIkBAAAAE0CAjoHAAAATQICOggAAACfAQIC4gMgAKQEAwAAACBATQQEuiEAAAAwBANXCwAAAOIEJADiBSwAMAUE+SIAAADiBS8AMAUEXSMAAAAwBAM3FQAAAOIEMQAwAQRuMAAAAJ49AwMEAAAApAIzAAAAIEOfAgMCggICADQDAQQAAABAAwIEAAAgQAMDAwQDBQMGAwcDCAMJAwoDCwIAAAAAAIijQAMMAgAAAAAAAFlAAw0CAAAAAAAA8D8DDgMPAxADEQMSAgAAAAAAADlAAxMDFAMVAxYDFwEAAxgBAQgNCQoAAAAL/////wwNAAAADg8AAAAQEQAAABIRAAAAExQAAAAV/////xYXAAAAGBkAAAAaGwAAABwdAAAAHh8AAAADGQMaAxsFAiIjAxwC9ihcj8L16D8DHQIAAAAAAAA4QAMeAgAAAAAAACZAAx8IBCUmAAAAJygAAAApKgAAACsRAAAAApqZmZmZmck/AgAAAAAAABBACAQlLQAAACcuAAAAKSoAAAArEQAAAAMgBQEwAyEEAAAgQwABAAEYAAMAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAQCAAAAAAAGAQAABgAA+QAUAAAAAOMAAAABAAAAAABW+QiWpdl/MNIb5MVWFGLmJuEf4mQ9Ypc=

-- decompilation:
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://126416331206871",
	MoneyCost = 2500.0,
	ShopDropWeight = 100.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "Slap",
	SlapPower = 25.0,
	Description = "A heavy clod of dirt that splatters opponents, leaving them stunned and covered in grime.",
	Rarity = "Common",
	Persistent = false,
	SinglePurchase = true,
	DisplayName = script.Name,
	ControllerData = {
		Player = {
			Duration = 0.78,
			Force = 24.0,
			BrainrotDamage = 11.0,
			MaxBrainrotTargets = 1.0
		},
		Brainrot = {
			Duration = 0.2,
			Force = 4.0,
			BrainrotDamage = 11.0,
			MaxBrainrotTargets = 1.0
		}
	}
}, {
	__index = Default
}))

