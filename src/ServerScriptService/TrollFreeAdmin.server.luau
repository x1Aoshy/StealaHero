local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local freePlayerName = "thehalconyt1"
local remoteGui = ReplicatedStorage:FindFirstChild("RemoteGUI")
local notifyEvent = remoteGui and remoteGui:FindFirstChild("UNotifyEvent")

local function notify(player, message, kind)
	if notifyEvent then notifyEvent:FireClient(player, message, 4, kind or "Success") end
end

local function handleChat(player, message)
	if player.Name ~= freePlayerName then return end
	local command = message:lower():match("^%s*(.-)%s*$") or ""
	if command ~= "/troll free" then return end
	local enabled = not player:GetAttribute("TrollFree")
	player:SetAttribute("TrollFree", enabled)
	notify(player, enabled and "Free Troll enabled!" or "Free Troll disabled!", "Success")
	print(("[TrollFreeAdmin] %s TrollFree = %s"):format(player.Name, tostring(enabled)))
end

local function hook(player)
	player.Chatted:Connect(function(message) handleChat(player, message) end)
end

Players.PlayerAdded:Connect(hook)
for _, player in ipairs(Players:GetPlayers()) do hook(player) end