-- scripts/inject/windows.luau
-- WINDOWS injection manifest (VISUAL_PASS_PLAN D7; scripts/build_stealahero.luau step 13b). Every create = false entry
-- is a base-place script patched per CONTRACTS section 0 rule 4: its src mirror was checked equal (CRLF aside) to the
-- Source in "Steal An Egg with treadmill V2.rbxl" before the patch, so the injected Source = base + the patch only.
-- (GUI.GroupRewards, the Free Gift! claim client, is injected by scripts/inject/nogroup.luau from its src file.)
return {
	{
		-- New: drives the Sell Heroes window (PlayerGui.AutoSell re-laid out by scripts/steps/ui_20_windows.luau).
		target = "StarterPlayer/StarterPlayerScripts/GUI/SellHeroes",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/SellHeroes.client.luau",
		create = true,
	},
	{
		-- Sell stall: "Sell All" opens the Sell Heroes window; the held hero OR unhatched egg sells through the validated
		-- "ActiveAssets: RequestSell" with a result toast; prices shown = the server payout; "pets" -> "heroes".
		target = "StarterPlayer/StarterPlayerScripts/Game/Npcs/AssetSellerNpc",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Npcs/AssetSellerNpc.client.luau",
		create = false,
	},
	{
		-- Free Gift!: granted once per profile without a group-membership check (community step is informational).
		target = "ServerScriptService/Controllers/GroupRewardService",
		class = "ModuleScript",
		source = "src/ServerScriptService/Controllers/GroupRewardService.luau",
		create = false,
	},
	-- "Pets" -> "Heroes" in text the scripts write at runtime (the GUI text pass is scripts/steps/ui_90_terms.luau)
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GuardTutorialController/Steps/PlacePet",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GuardTutorialController/Steps/PlacePet.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Tools/AssetToolEquipController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Tools/AssetToolEquipController.client.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Library/Shared/Variables",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Shared/Variables/init.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/AssetInteractionPrompt",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/ActiveAssetsController/AssetInteractionPrompt.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Assets/ToolTemplates/PetTemplate/PetToolLocal",
		class = "LocalScript",
		source = "src/ReplicatedStorage/Assets/ToolTemplates/PetTemplate/PetToolLocal.client.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/FuseMachine",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/FuseMachine.client.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/FuseMachine",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/FuseMachine/init.client.luau",
		create = false,
	},
}
