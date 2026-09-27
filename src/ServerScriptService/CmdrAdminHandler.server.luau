-- ServerScriptService.CmdrAdminHandler
-- Server end of the Cmdr admin commands (giveMoney, setSpeedPower). The Cmdr
-- command definitions live in ReplicatedStorage.CmdrClient.Commands and fire
-- CmdrAdmin_GiveMoney / CmdrAdmin_SetSpeedPower :FireServer(userIds, amount).
-- We resolve those UserIds to Players, validate the CALLER is on the admin
-- whitelist, and update the real Database profile so it broadcasts to the
-- client + persists through the autosave.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game:GetService("ServerScriptService").Library.Database)
local SpeedService

local ADMIN_USER_IDS = {
	[4596856585] = true, -- Pulse
	[4959610813] = true,
	[10993723144] = true,
}

local function isAdmin(player)
	return player and ADMIN_USER_IDS[player.UserId] == true
end

local function getOrCreateRemote(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing end
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end

local GiveMoneyRemote = getOrCreateRemote("CmdrAdmin_GiveMoney")
local SetSpeedPowerRemote = getOrCreateRemote("CmdrAdmin_SetSpeedPower")

-- Lazy-require SpeedService so we survive if it's not loaded (it's registered
-- in Bootstrap earlier than us, but a warn is still safer than a hard error).
local function refreshSpeed(target)
	if not SpeedService then
		local ok, mod = pcall(require, game:GetService("ServerScriptService").Controllers.SpeedService)
		if ok then SpeedService = mod end
	end
	if SpeedService and SpeedService.Refresh then
		local ok, err = pcall(SpeedService.Refresh, target)
		if not ok then warn("[CmdrAdminHandler] SpeedService.Refresh error: " .. tostring(err)) end
	end
end

local function resolveTargets(userIds)
	local out = {}
	if type(userIds) ~= "table" then return out end
	for _, id in ipairs(userIds) do
		local n = tonumber(id)
		if n then
			local p = Players:GetPlayerByUserId(n)
			if p then table.insert(out, p) end
		end
	end
	return out
end

GiveMoneyRemote.OnServerEvent:Connect(function(caller, userIds, amount)
	if not isAdmin(caller) then
		warn("[CmdrAdminHandler] Non-admin " .. caller.Name .. " tried giveMoney")
		return
	end
	amount = tonumber(amount)
	if not amount or amount ~= amount then return end
	for _, target in ipairs(resolveTargets(userIds)) do
		local profile = Database.Get(target)
		if profile then
			local current = tonumber(profile.Money) or 0
			Database.SetAndBroadcast(target, { Money = current + amount })
			print(string.format("[CmdrAdminHandler] %s gave %d money to %s (new total: %d)",
				caller.Name, amount, target.Name, current + amount))
		end
	end
end)

SetSpeedPowerRemote.OnServerEvent:Connect(function(caller, userIds, amount)
	if not isAdmin(caller) then
		warn("[CmdrAdminHandler] Non-admin " .. caller.Name .. " tried setSpeedPower")
		return
	end
	amount = tonumber(amount)
	if not amount or amount ~= amount then return end
	amount = math.max(0, amount) -- SpeedPower can't be negative
	for _, target in ipairs(resolveTargets(userIds)) do
		local profile = Database.Get(target)
		if profile then
			Database.SetAndBroadcast(target, { SpeedPower = amount })
			refreshSpeed(target)
			print(string.format("[CmdrAdminHandler] %s set %s SpeedPower to %d",
				caller.Name, target.Name, amount))
		end
	end
end)

print("[CmdrAdminHandler] loaded")
