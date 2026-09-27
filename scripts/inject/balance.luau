-- scripts/inject/balance.luau (LEAD)
-- Balancing pass approved by the owner on 2026-09-23 (economy simulation): treadmill prices up and the MODDED x3
-- multipliers reverted, trails repriced with smaller multipliers, the free gift 10K -> 1K Speed. Every source was
-- checked equal to the base place before patching. Base costs: Directory/Bases.luau (copied by the build) and
-- PlotService (architect.luau). Villain speeds / spawn rule: scripts/inject/balance_chase.luau.
-- ECON 2026-09-24 (owner: "lower the entire money system, Black Widow as a basis ~4/s max"): the whole money economy
-- /125 with the 2026-09-23 pacing kept. Hero income: AssetGenerationUtil (x5 -> x0.04, MONEY_SCALE); prices: the
-- Treadmill / Trail configs below, Directory/Bases.luau + PlotService BASE_TIERS; rewards: AreaEggService bounties,
-- Database starting cash, TreadmillGrindService coins, ConsumableGamepassService / AmonetizationPurchaseService money
-- packs (Shop titles: scripts/steps/ui_96_econ_texts.luau); old saves: OfflineAssetsService (MoneyScaleVersion).
-- The four new entries below were checked equal to the base place Source before patching.
return {
	{ target = "ReplicatedStorage/Library/Util/AssetGenerationUtil", class = "ModuleScript", source = "src/ReplicatedStorage/Library/Util/AssetGenerationUtil.luau", create = false },
	{ target = "ServerScriptService/Controllers/ConsumableGamepassService", class = "ModuleScript", source = "src/ServerScriptService/Controllers/ConsumableGamepassService.luau", create = false },
	{ target = "StarterPlayer/StarterPlayerScripts/Game/Plots/OfflineMoney/OfflineMoneyInPlotUI", class = "LocalScript", source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/OfflineMoney/OfflineMoneyInPlotUI.client.luau", create = false },
	{ target = "StarterPlayer/StarterPlayerScripts/Game/Plots/OfflineMoney/OfflineMoneyBucketPiles/MoneyPiles", class = "ModuleScript", source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/OfflineMoney/OfflineMoneyBucketPiles/MoneyPiles.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/Treadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/Treadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/Sci-FiTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/Sci-FiTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/FlameTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/FlameTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/CelebrityTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/CelebrityTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/GoldenTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/GoldenTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/The FreezeTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/The FreezeTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/Lucky BlockTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/Lucky BlockTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/HackerTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/HackerTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/DemonicTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/DemonicTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Treadmills/_Index/AngelicTreadmill", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Treadmills/_Index/AngelicTreadmill.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/GreyTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/GreyTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/GreenTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/GreenTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/BlueTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/BlueTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/PurpleTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/PurpleTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/GoldenTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/GoldenTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/RedTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/RedTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/GalaxyTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/GalaxyTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/SecretTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/SecretTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/EternalTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/EternalTrail.luau", create = false },
	{ target = "ReplicatedStorage/Directory/Trails/_Index/DivineTrail", class = "ModuleScript", source = "src/ReplicatedStorage/Directory/Trails/_Index/DivineTrail.luau", create = false },
	{ target = "ReplicatedStorage/Library/Types/GroupReward", class = "ModuleScript", source = "src/ReplicatedStorage/Library/Types/GroupReward.luau", create = false },
}
