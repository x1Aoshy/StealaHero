-- ServerScriptService.Controllers.SpeedBoostGamepassService
--
-- Grants the SpeedBoost tier (x2 hasta x4096, "DoubleYourSpeed" en el Shop/cartel) por posesion
-- de Game Pass. El rip original tenia esto como 12 Developer Products
-- (Directory.Products._Index.SpeedBoost.SpeedBoostTierN, ver AmonetizationPurchaseService.
-- SPEED_BOOST_TIER_PRODUCTS/grantSpeedBoostTierIfBetter -- se queda ahi, muerto/inofensivo, sus
-- ProductId son de la cuenta del rip y nunca se van a poder comprar de verdad). El user creo los
-- 12 reales como Game Passes en su propio Dashboard en vez de Developer Products (captura de
-- pantalla), asi que este es el servicio nuevo del lado gamepass -- mismo patron exacto que
-- TreadmillGamepassService (sync al entrar + PromptGamePassPurchaseFinished, nunca degrada).

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Database = require(game.ServerScriptService.Library.Database)
local SpeedService = require(game.ServerScriptService.Controllers.SpeedService)
local TreadmillUtil = require(game:GetService("ReplicatedStorage").Library.Util.TreadmillUtil)

local SpeedBoostGamepassService = {}

-- Pass ID -> tier index que otorga (1=x2 ... 12=x4096). IDs reales del Dashboard del user.
local GAMEPASS_TIERS = {
	[1954819472] = 1, -- x2
	[1954975461] = 2, -- x4
	[1953743679] = 3, -- x8
	[1953783709] = 4, -- x16
	[1954193673] = 5, -- x32
	[1954293702] = 6, -- x64
	[1953113697] = 7, -- x128
	[1954585542] = 8, -- x256
	[1952608010] = 9, -- x512
	[1954157725] = 10, -- x1024
	[1952571993] = 11, -- x2048
	[1954441424] = 12, -- x4096
}

local function grantIfBetter(player, tierIndex)
	local profile = Database.Get(player)
	if not profile then
		return
	end
	local current = profile.SpeedBoostTierIndex or 0
	if tierIndex <= current then
		return -- ya tiene este tier o uno mejor -- nunca degrada.
	end
	Database.SetAndBroadcast(player, { SpeedBoostTierIndex = tierIndex })
	SpeedService.Refresh(player)
	local multiplier = TreadmillUtil.GetSpeedBoostMultiplierForTierIndex(tierIndex)
	print(string.format("[SpeedBoostGamepassService] Granted SpeedBoostTier %d (x%d) to %s via gamepass", tierIndex, multiplier, player.Name))
end

local function checkAllOwned(player)
	for passId, tierIndex in pairs(GAMEPASS_TIERS) do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if not ok then
			warn("[SpeedBoostGamepassService] UserOwnsGamePassAsync failed for pass " .. tostring(passId) .. ": " .. tostring(owns))
		elseif owns then
			grantIfBetter(player, tierIndex)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(checkAllOwned, player)
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(checkAllOwned, player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased and GAMEPASS_TIERS[gamepassId] then
		grantIfBetter(player, GAMEPASS_TIERS[gamepassId])
	end
end)

return SpeedBoostGamepassService
