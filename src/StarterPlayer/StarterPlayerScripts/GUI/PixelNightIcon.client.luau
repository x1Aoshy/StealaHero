-- StarterPlayer.StarterPlayerScripts.GUI.PixelNightIcon (LocalScript)
-- Owner 2026-09-27: "design a new icon for the night, make it pixel art". The night / day timer
-- (PlayerGui.GameResetTimer.{TimeLeft, EndingSoon}.Main.Frame) carries two pixel-art icons built by
-- scripts/steps/ui_30_hud.luau: SpPixelMoon and SpPixelSun. GameResetTimer.client keeps setting the ImageLabel to the
-- moon (by day: time until night) or the sun (by night); this script shows the matching pixel icon instead and hides the
-- image. Without the pixel icons (an older build) nothing changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local moonDigits = "91446334780160"
do
	local directory = ReplicatedStorage:WaitForChild("Directory", 30)
	local module = directory and directory:FindFirstChild("AreaEggResetCycle")
	local ok, cycle = pcall(function()
		return module and require(module)
	end)
	if ok and type(cycle) == "table" and type(cycle.MoonIcon) == "string" then
		moonDigits = string.match(cycle.MoonIcon, "(%d+)") or moonDigits
	end
end

local function bind(image)
	local holder = image.Parent
	local moon = holder and holder:FindFirstChild("SpPixelMoon")
	local sun = holder and holder:FindFirstChild("SpPixelSun")
	if not (moon and sun) then
		return
	end
	local function refresh()
		local isMoon = string.find(image.Image, moonDigits, 1, true) ~= nil
		moon.Visible = isMoon
		sun.Visible = not isMoon
		image.ImageTransparency = 1
	end
	refresh()
	image:GetPropertyChangedSignal("Image"):Connect(refresh)
end

local function onGui(gui)
	if gui.Name ~= "GameResetTimer" then
		return
	end
	for _, path in ipairs({ { "TimeLeft", "Main", "Frame", "ImageLabel" }, { "EndingSoon", "Main", "Frame", "ImageLabel" } }) do
		local node = gui
		for _, name in ipairs(path) do
			node = node and node:WaitForChild(name, 10)
		end
		if node and node:IsA("ImageLabel") and node:GetAttribute("PixelIcons") == true then
			bind(node)
		end
	end
end

for _, gui in ipairs(playerGui:GetChildren()) do
	task.spawn(onGui, gui)
end
playerGui.ChildAdded:Connect(function(gui)
	task.spawn(onGui, gui)
end)
