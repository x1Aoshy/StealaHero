local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local customSpeedEvent = ReplicatedStorage:WaitForChild("CustomSpeedEvent")
local MIN_SPEED = 1
local MAX_SPEED = 300

local function applySpeed(player: Player, requestedSpeed: any)
	if typeof(requestedSpeed) ~= "number" or requestedSpeed ~= requestedSpeed then
		return
	end

	local speed = math.clamp(math.floor(requestedSpeed), MIN_SPEED, MAX_SPEED)
	if requestedSpeed < MIN_SPEED or requestedSpeed > MAX_SPEED then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
		print("[CustomSpeedServer] Applied speed " .. speed .. " to " .. player.Name)
	end
end

customSpeedEvent.OnServerEvent:Connect(applySpeed)

Players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
end)

print("[CustomSpeedServer] Ready; allowed range: " .. MIN_SPEED .. "-" .. MAX_SPEED)
