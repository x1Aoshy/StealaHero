local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserGenerated = ReplicatedStorage:WaitForChild("UserGenerated")
local Analytics = UserGenerated:WaitForChild("Analytics")
local ClientKit = Analytics:WaitForChild("ClientKit")

for _, child in ipairs(ClientKit:GetChildren()) do
	if child:IsA("RemoteEvent") or child:IsA("UnreliableRemoteEvent") then
		child.OnServerEvent:Connect(function() end)
	end
end
