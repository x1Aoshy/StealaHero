-- ServerScriptService.Controllers.TreadmillGamepassService
-- Grants the matching real Robux gamepass shortcut for the 3 best treadmills shown in
-- Btn_TreadmillUpgrade.Icon_VP (client). Confirmed real level order from
-- ReplicatedStorage.Directory.Treadmills.GetByUpgradeLevel: 8=HackerTreadmill(x500),
-- 9=DemonicTreadmill(x1000), 10=AngelicTreadmill(x2000) -- the top of the normal
-- Money-upgrade ladder (TreadmillService.RequestUpgrade). This is a Robux SKIP-AHEAD on top
-- of that ladder: per the user's request, buying only upgrades if it's BETTER than what the
-- player currently has (never downgrades) -- "si da mas que la que tenia".
--
-- Sesion 12: el user creo 6 de los 9 gamepasses reales en su propio Dashboard (captura de
-- pantalla, juego "Stealz a Egg (Getz Adminz)") -- IDs reales sustituidos abajo para los tiers
-- 2-7. Los 3 de arriba (Hacker/Demonic/Angelic, tiers 8-10) siguen siendo los que vinieron del
-- rip (de otra cuenta, "My Roleplays Studios", confirmado con GetProductInfo) -- pendiente que
-- el user cree esos 3 tambien y me pase los IDs reales.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local SpeedService = require(game.ServerScriptService.Controllers.SpeedService)
local Treadmills = require(ReplicatedStorage.Directory.Treadmills)

local TreadmillGamepassService = {}

-- Pass ID -> treadmill upgrade level it grants (skips straight to that level if better).
local GAMEPASS_LEVELS = {
	[1954567487] = 2, -- Sci-FiTreadmill (real, Dashboard del user)
	[1955443420] = 3, -- FlameTreadmill (real, Dashboard del user)
	[1955581402] = 4, -- CelebrityTreadmill (real, Dashboard del user)
	[1952896047] = 5, -- GoldenTreadmill (real, Dashboard del user)
	[1954157730] = 6, -- The FreezeTreadmill (real, Dashboard del user)
	[1955257463] = 7, -- Lucky BlockTreadmill (real, Dashboard del user)
	[1955574745] = 8, -- HackerTreadmill (TODO: aun no es real, de otra cuenta)
	[1955652727] = 9, -- DemonicTreadmill (TODO: aun no es real, de otra cuenta)
	[1954974815] = 10, -- AngelicTreadmill (TODO: aun no es real, de otra cuenta)
}

local function grantIfBetter(player, level)
	local profile = Database.Get(player)
	if not profile then
		return
	end
	local current = profile.TreadmillUpgradeLevel or 1
	if level <= current then
		return -- ya tiene una igual o mejor -- no se toca (nunca degrada).
	end
	local config = Treadmills.GetByUpgradeLevel(level)
	if not config then
		warn("[TreadmillGamepassService] No treadmill config for level " .. tostring(level))
		return
	end
	Database.SetAndBroadcast(player, { TreadmillUpgradeLevel = level })
	SpeedService.Refresh(player)
	print(string.format("[TreadmillGamepassService] Granted %s (level %d) to %s via gamepass", config._id, level, player.Name))
end

local function checkAllOwned(player)
	for passId, level in pairs(GAMEPASS_LEVELS) do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if not ok then
			warn("[TreadmillGamepassService] UserOwnsGamePassAsync failed for pass " .. tostring(passId) .. ": " .. tostring(owns))
		elseif owns then
			grantIfBetter(player, level)
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
	if wasPurchased and GAMEPASS_LEVELS[gamepassId] then
		grantIfBetter(player, GAMEPASS_LEVELS[gamepassId])
	end
end)

return TreadmillGamepassService
