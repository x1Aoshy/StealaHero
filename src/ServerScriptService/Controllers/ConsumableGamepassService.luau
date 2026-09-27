-- ServerScriptService.Controllers.ConsumableGamepassService
--
-- Money packs / SpeedPower packs / Grow All Eggs -- the user created these 11 as Game Passes on
-- their Dashboard (captura de pantalla) instead of Developer Products like the rip originally had
-- them (see AmonetizationPurchaseService.MONEY_PACK_PRODUCTS/SPEED_POWER_PACK_PRODUCTS/
-- EGG_GROW_ALL_PRODUCT_ID -- those stay in place, dead/harmless, their ProductIds are from the
-- rip's original account and will never actually be purchasable).
--
-- 🔴 IMPORTANT DIFFERENCE from TreadmillGamepassService/SpeedBoostGamepassService: those grant a
-- PERMANENT STATE (tier N), so re-checking "do they own it" on every join and re-applying is
-- perfectly safe (idempotent -- "you have tier N" is a fact, setting it again changes nothing).
-- These 11 are the OPPOSITE: one-shot CONSUMABLE grants (+money, +speed, finish eggs). A Game
-- Pass, once bought, is owned FOREVER -- if this synced on every join like the other 2 services,
-- a player could leave and rejoin to farm infinite free money/speed. So this service ONLY grants
-- on the live PromptGamePassPurchaseFinished moment (the actual instant of purchase), never on
-- join. Trade-off worth knowing: unlike a Developer Product receipt (which Roblox keeps retrying
-- until ProcessReceipt returns PurchaseGranted), a missed/failed grant here from a dropped
-- connection right at that instant has no automatic retry -- accepted as-is since the user chose
-- Game Passes for all of these deliberately (same as Treadmill/SpeedBoost).

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Database = require(game.ServerScriptService.Library.Database)
local SpeedService = require(game.ServerScriptService.Controllers.SpeedService)

-- Pass ID -> {Kind, Amount}. IDs reales del Dashboard del user.
-- ECON 2026-09-24: Money amounts /125 with the whole money economy (was 800K / 4M / 24K / 8M / 200K; 24K/125 = 192
-- rounded to 200). The Shop titles (StarterGui.Shop MoneyTop/MoneyBottom) are rewritten to match by
-- scripts/steps/ui_96_econ_texts.luau. SpeedPower packs are untouched.
local GAMEPASS_GRANTS = {
	[1954255697] = { Kind = "Money", Amount = 6400 },
	[1955743405] = { Kind = "Money", Amount = 32000 },
	[1951726310] = { Kind = "Money", Amount = 200 },
	[1954885469] = { Kind = "Money", Amount = 64000 },
	[1954543508] = { Kind = "Money", Amount = 1600 },

	[1956078268] = { Kind = "SpeedPower", Amount = 150000 },
	[1954711483] = { Kind = "SpeedPower", Amount = 1000000 },
	[1955641361] = { Kind = "SpeedPower", Amount = 10000000 },
	[1954031693] = { Kind = "SpeedPower", Amount = 50000000 },
	[1955713378] = { Kind = "SpeedPower", Amount = 500000000 },
	[1952727973] = { Kind = "SpeedPower", Amount = 1000000000 },

	[1951948299] = { Kind = "EggGrowAll" },
}

local ConsumableGamepassService = {}

local function grantMoney(player, amount)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	Database.SetAndBroadcast(player, { Money = (profile.Money or 0) + amount })
	print(string.format("[ConsumableGamepassService] Granted +%d Money to %s (gamepass)", amount, player.Name))
	return true
end

local function grantSpeedPower(player, amount)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	Database.SetAndBroadcast(player, { SpeedPower = (profile.SpeedPower or 10) + amount })
	SpeedService.Refresh(player)
	print(string.format("[ConsumableGamepassService] Granted +%d SpeedPower to %s (gamepass)", amount, player.Name))
	return true
end

local function grantEggGrowAll(player)
	local profile = Database.Get(player)
	if not profile then
		return false
	end
	local grownCount = 0
	for _, egg in pairs(profile.EggInventory) do
		if egg.Placement and egg.Placement.ReadyAt == nil then
			egg.Placement.ReadyAt = os.time()
			grownCount += 1
		end
	end
	Database.Set(player, { EggInventory = profile.EggInventory })
	print(string.format("[ConsumableGamepassService] Granted Grow All Eggs to %s via gamepass (%d egg(s) finished)", player.Name, grownCount))
	return true
end

local function applyGrant(player, entry)
	if entry.Kind == "Money" then
		return grantMoney(player, entry.Amount)
	elseif entry.Kind == "SpeedPower" then
		return grantSpeedPower(player, entry.Amount)
	elseif entry.Kind == "EggGrowAll" then
		return grantEggGrowAll(player)
	end
	return false
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased then
		return
	end
	local entry = GAMEPASS_GRANTS[gamepassId]
	if not entry then
		return
	end
	applyGrant(player, entry)
end)

return ConsumableGamepassService
