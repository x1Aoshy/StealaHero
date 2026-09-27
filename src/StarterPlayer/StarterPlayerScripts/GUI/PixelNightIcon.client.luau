-- StarterPlayer.StarterPlayerScripts.GUI.PixelNightIcon (LocalScript)
-- Owner 2026-09-27: "design a new icon for the night, make it pixel art", then "every moon image must be the new one,
-- all of them: you replaced only one". The pixel moon / sun are built by scripts/steps/ui_30_hud.luau from Frames (no
-- uploaded image):
--   * the night / day timer (PlayerGui.GameResetTimer.{TimeLeft, EndingSoon}.Main.Frame) carries SpPixelMoon and
--     SpPixelSun next to its ImageLabel. GameResetTimer.client keeps setting that ImageLabel to the moon (by day: time
--     until night) or the sun (by night); the matching pixel icon is shown and the image hidden.
--   * every other moon image carries an SpPixelIcon layer (a CanvasGroup with Moon and Sun inside): the start-of-night
--     countdown's SleepIcon / DayIcon, the egg tab's NightImage and the NightEggTimeSkip billboard over growing eggs,
--     plus any image the game shows at runtime with a moon or sun art (the layer is cloned from
--     ReplicatedStorage.Assets.UI.PixelIcons). The layer shows Moon or Sun from the image the game's scripts set, the
--     old art is blanked (Image set to none; an image the scripts later set to another picture is left alone), and the
--     scripts' ImageTransparency fades carry over to the layer's GroupTransparency.
-- Without the pixel icons (an older build) nothing changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local moonDigits = "91446334780160"
local sunDigits = "100486757307207"
do
	local directory = ReplicatedStorage:WaitForChild("Directory", 30)
	local module = directory and directory:FindFirstChild("AreaEggResetCycle")
	local ok, cycle = pcall(function()
		return module and require(module)
	end)
	if ok and type(cycle) == "table" then
		if type(cycle.MoonIcon) == "string" then
			moonDigits = string.match(cycle.MoonIcon, "(%d+)") or moonDigits
		end
		if type(cycle.SunIcon) == "string" then
			sunDigits = string.match(cycle.SunIcon, "(%d+)") or sunDigits
		end
	end
end
-- every moon / sun art the game uses: the reset cycle's icons, the countdown's sleep / day icons, the Demonic event's
-- red moon
local KIND_BY_ID = {
	[moonDigits] = "Moon",
	["131317614803230"] = "Moon",
	["97443431423842"] = "Moon",
	[sunDigits] = "Sun",
	["86038047961937"] = "Sun",
}

local function kindOf(image)
	local digits = string.match(image.Image, "(%d+)")
	return digits and KIND_BY_ID[digits] or nil
end

local bound = setmetatable({}, { __mode = "k" }) -- [image] = true once bound

-- the night / day timer (holder-level SpPixelMoon / SpPixelSun, bobbing)
local function bindTimer(image)
	if bound[image] then
		return
	end
	local holder = image.Parent
	local moon = holder and holder:FindFirstChild("SpPixelMoon")
	local sun = holder and holder:FindFirstChild("SpPixelSun")
	if not (moon and sun) then
		return
	end
	bound[image] = true
	local function refresh()
		local isMoon = string.find(image.Image, moonDigits, 1, true) ~= nil
		moon.Visible = isMoon
		sun.Visible = not isMoon
		image.ImageTransparency = 1
	end
	refresh()
	image:GetPropertyChangedSignal("Image"):Connect(refresh)
end

local template = nil
do
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local ui = assets and assets:FindFirstChild("UI")
	local folder = ui and ui:FindFirstChild("PixelIcons")
	template = folder and folder:FindFirstChild("SpPixelIcon")
end

local function bindLayer(image)
	if bound[image] then
		return
	end
	local layer = image:FindFirstChild("SpPixelIcon")
	if layer == nil then
		if template == nil or kindOf(image) == nil then
			return
		end
		layer = template:Clone()
		layer.ZIndex = image.ZIndex + 1
		layer.Parent = image
	end
	local moon, sun = layer:FindFirstChild("Moon"), layer:FindFirstChild("Sun") -- a layer may hold only the one it needs
	if not ((moon or sun) and layer:IsA("CanvasGroup")) then
		return
	end
	bound[image] = true
	local kind = nil
	local function refresh()
		local current = kindOf(image)
		if current ~= nil then
			kind = current
			image.Image = "" -- blank the old art; the pixel layer draws it
		elseif image.Image ~= "" then
			kind = nil -- a script put another picture here: show it
		end
		if moon then
			moon.Visible = kind == "Moon"
		end
		if sun then
			sun.Visible = kind == "Sun"
		end
	end
	local function fade()
		layer.GroupTransparency = image.ImageTransparency
	end
	refresh()
	fade()
	image:GetPropertyChangedSignal("Image"):Connect(refresh)
	image:GetPropertyChangedSignal("ImageTransparency"):Connect(fade)
end

local function consider(d)
	local className = d.ClassName
	if className ~= "ImageLabel" and className ~= "ImageButton" then
		return
	end
	if d:GetAttribute("PixelIcons") == true then
		bindTimer(d)
	elseif d:GetAttribute("PixelIcon") == true or kindOf(d) ~= nil then
		bindLayer(d)
	end
end

local function onGui(gui)
	if gui.Name == "GameResetTimer" then
		-- the timer's images may arrive after the ScreenGui itself
		for _, path in ipairs({ { "TimeLeft", "Main", "Frame", "ImageLabel" }, { "EndingSoon", "Main", "Frame", "ImageLabel" } }) do
			local node = gui
			for _, name in ipairs(path) do
				node = node and node:WaitForChild(name, 10)
			end
			if node and node:IsA("ImageLabel") and node:GetAttribute("PixelIcons") == true then
				bindTimer(node)
			end
		end
		return
	end
	consider(gui)
	for _, d in ipairs(gui:GetDescendants()) do
		consider(d)
	end
end

for _, gui in ipairs(playerGui:GetChildren()) do
	task.spawn(onGui, gui)
end
playerGui.ChildAdded:Connect(function(gui)
	task.spawn(onGui, gui)
end)
playerGui.DescendantAdded:Connect(function(d)
	if d.Parent ~= playerGui then
		task.defer(consider, d)
	end
end)
-- world billboards (the NightEggTimeSkip moon over growing eggs, and any other moon art on a BillboardGui)
Workspace.DescendantAdded:Connect(function(d)
	local className = d.ClassName
	if className == "ImageLabel" or className == "ImageButton" then
		task.defer(consider, d)
	end
end)
