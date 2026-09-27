-- ServerScriptService.AdminStatusHandler
-- Grants admin status for the AdminPanel + Cmdr admin commands.
-- The client (AdminPanel GUI, AdminCmdrClient, and Cmdr BeforeRun) all fire
-- AdminPanel_CheckAdminStatus on startup and wait for
-- AdminPanel_AdminStatusResponse:FireClient(player, true) to initialize their
-- Cmdr binding + admin UI. Nothing on the server was firing that back, so
-- Cmdr never bound its F2 hotkey. This module answers those requests using
-- its own whitelist.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = ReplicatedStorage:WaitForChild("Network")
local CheckAdminStatusRemote = Network:WaitForChild("AdminPanel_CheckAdminStatus")
local AdminStatusResponseRemote = Network:WaitForChild("AdminPanel_AdminStatusResponse")

-- Add UserIds here to grant them admin/Cmdr access.
local ADMIN_USER_IDS = {
	[4596856585] = true, -- Pulse
	[4959610813] = true,
	[10993723144] = true,
}

local function isAdmin(player)
	return ADMIN_USER_IDS[player.UserId] == true
end

local function respond(player)
	if not player or not player.Parent then return end
	local ok, err = pcall(function()
		AdminStatusResponseRemote:FireClient(player, isAdmin(player))
	end)
	if not ok then
		warn("[AdminStatusHandler] Failed to fire ADMIN_STATUS_RESPONSE to " .. player.Name .. ": " .. tostring(err))
	end
end

-- Answer explicit client requests.
CheckAdminStatusRemote.OnServerEvent:Connect(function(player)
	respond(player)
end)

-- Also push proactively as soon as they join, in case the client already has
-- its listener wired before it fires CHECK_ADMIN_STATUS.
Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		task.wait(1)
		respond(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(respond, player)
end

print("[AdminStatusHandler] loaded, admin UserIds: 4859204475, 4959610813, 10993723144")
