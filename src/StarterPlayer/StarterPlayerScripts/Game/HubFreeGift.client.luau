-- StarterPlayerScripts.Game.HubFreeGift (docs/VISUAL_PASS_PLAN.md D6, injected by scripts/inject/hub.luau)
-- The hub's Free Gift corner (Workspace.Hub.FreeGift, built by scripts/steps/post_hub_remodel.luau) holds the
-- "CLICK TO CLAIM" board and the gift chest. There is no ad system in this game, so the board is not an ad: a
-- click / tap on the board or on the chest opens the Free Gift window (StarterGui.GroupReward), the same tab the
-- chest's Workspace.__OBJECTS.GroupReward prompt (on the chest lid) toggles through GUI/GroupRewards. The window's own
-- Claim button does the server-verified claim (GroupRewardService); this script only opens the window.
-- The "TAP TO OPEN" pill over the chest (GiftChest.Lid.OpenHint, UIFIX 2026-09-24): its world copy is disabled and a
-- clone lives in PlayerGui (adorned to the lid) so a tap / click on the pill itself opens the window too. The pill is
-- worded for the current input (TAP TO OPEN / CLICK TO OPEN / OPEN ME!), bobs gently (one looping tween), steps aside
-- while the chest's prompt is shown (the prompt takes its place) and goes away once the gift is claimed. The board's
-- button reads TAP TO CLAIM on touch. Everything optional degrades quietly (no pill -> clicks and the prompt still work).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local TAB_NAME = "GroupReward"
local WAIT_SECONDS = 30
local HINT_NAME = "OpenHint"
local BOB_STUDS = 0.22
local BOB_SECONDS = 0.9

local TabController = nil
do
	local ok, result = pcall(function()
		local library = ReplicatedStorage:WaitForChild("Library", WAIT_SECONDS)
		local client = library and library:WaitForChild("Client", WAIT_SECONDS)
		local module = client and client:WaitForChild("TabController", WAIT_SECONDS)
		return module and require(module)
	end)
	if not ok or type(result) ~= "table" or type(result.OpenTab) ~= "function" then
		warn("[HubFreeGift] TabController unavailable, the Free Gift board stays decorative: " .. tostring(result))
		return
	end
	TabController = result
end

local hub = Workspace:WaitForChild("Hub", WAIT_SECONDS)
local freeGift = hub and hub:WaitForChild("FreeGift", WAIT_SECONDS)
if freeGift == nil then
	return
end

local function openFreeGift()
	local okOpen, isOpen = pcall(TabController.IsOpen, TAB_NAME)
	if okOpen and isOpen then
		return
	end
	local ok, err = pcall(TabController.OpenTab, TAB_NAME)
	if not ok then
		warn("[HubFreeGift] could not open the Free Gift window: " .. tostring(err))
	end
end

local function bind(instance)
	if instance:IsA("ClickDetector") then
		instance.MouseClick:Connect(openFreeGift)
	end
end

for _, descendant in ipairs(freeGift:GetDescendants()) do
	bind(descendant)
end
freeGift.DescendantAdded:Connect(bind)

---------------------------------------------------------------------------------------------------
-- the TAP TO OPEN pill and the board's wording
---------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", WAIT_SECONDS)
local chest = freeGift:WaitForChild("GiftChest", WAIT_SECONDS)

local worldHint = nil
if chest then
	for _, descendant in ipairs(chest:GetDescendants()) do
		if descendant:IsA("BillboardGui") and descendant.Name == HINT_NAME then
			worldHint = descendant
			break
		end
	end
end

local hint = nil -- the PlayerGui clone
local hintLabels = {} -- Label + LabelDrop
if worldHint and playerGui then
	local adornee = worldHint.Adornee or worldHint.Parent
	if adornee and adornee:IsA("BasePart") then
		hint = worldHint:Clone()
		hint.Name = "HubFreeGiftHint"
		hint.Adornee = adornee
		hint.ResetOnSpawn = false
		hint.Parent = playerGui
		worldHint.Enabled = false
		local button = hint:FindFirstChild("Button")
		if button and button:IsA("GuiButton") then
			button.Activated:Connect(openFreeGift)
		end
		for _, descendant in ipairs(hint:GetDescendants()) do
			if descendant:IsA("TextLabel") and (descendant.Name == "Label" or descendant.Name == "LabelDrop") then
				table.insert(hintLabels, descendant)
			end
		end
		-- gentle bob: one looping tween (engine-driven, no per-frame script work)
		local base = hint.StudsOffsetWorldSpace
		hint.StudsOffsetWorldSpace = base - Vector3.new(0, BOB_STUDS / 2, 0)
		local bob = TweenService:Create(hint, TweenInfo.new(BOB_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			StudsOffsetWorldSpace = base + Vector3.new(0, BOB_STUDS / 2, 0),
		})
		bob:Play()
	end
end

-- the board's CLICK TO CLAIM button text (Label + LabelDrop on ClaimSign's face)
local boardLabels = {}
local claimSign = freeGift:FindFirstChild("ClaimSign")
if claimSign then
	for _, descendant in ipairs(claimSign:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Text == "CLICK TO CLAIM" then
			table.insert(boardLabels, descendant)
		end
	end
end

local function setTexts(labels, text)
	for _, label in ipairs(labels) do
		if label.Parent ~= nil and label.Text ~= text then
			label.Text = text
		end
	end
end

local function inputKind(): string
	local last = UserInputService:GetLastInputType()
	if last == Enum.UserInputType.Touch then
		return "touch"
	elseif string.sub(last.Name, 1, 7) == "Gamepad" then
		return "gamepad"
	elseif last == Enum.UserInputType.MouseButton1 or last == Enum.UserInputType.MouseMovement or last == Enum.UserInputType.Keyboard then
		return "mouse"
	end
	return if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then "touch" else "mouse"
end

local HINT_TEXT = { touch = "TAP TO OPEN", mouse = "CLICK TO OPEN", gamepad = "OPEN ME!" }
local BOARD_TEXT = { touch = "TAP TO CLAIM", mouse = "CLICK TO CLAIM", gamepad = "OPEN THE CHEST" }
local currentKind = nil
local function refreshWording()
	local kind = inputKind()
	if kind == currentKind then
		return
	end
	currentKind = kind
	setTexts(hintLabels, HINT_TEXT[kind])
	setTexts(boardLabels, BOARD_TEXT[kind])
end
refreshWording()
UserInputService.LastInputTypeChanged:Connect(refreshWording)

-- visibility: hidden while the chest's own prompt is shown (the prompt takes the pill's place) and once claimed
local giftPrompt = nil
do
	local objects = Workspace:FindFirstChild("__OBJECTS") or Workspace:WaitForChild("__OBJECTS", WAIT_SECONDS)
	local part = objects and objects:WaitForChild("GroupReward", WAIT_SECONDS)
	giftPrompt = part and part:FindFirstChildOfClass("ProximityPrompt")
end

local promptShown = false
local claimed = false
local function refreshHint()
	if hint then
		hint.Enabled = not promptShown and not claimed
	end
end

if giftPrompt then
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt == giftPrompt then
			promptShown = true
			refreshHint()
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		if prompt == giftPrompt then
			promptShown = false
			refreshHint()
		end
	end)
end

local Save = nil
do
	local ok, result = pcall(function()
		local library = ReplicatedStorage:FindFirstChild("Library")
		local client = library and library:FindFirstChild("Client")
		local module = client and client:FindFirstChild("Save")
		return module and require(module)
	end)
	if ok and type(result) == "table" then
		Save = result
	end
end

local function refreshClaimed()
	local ok, save = pcall(function()
		return Save.Get()
	end)
	claimed = ok and type(save) == "table" and save.ClaimedGroupReward == true
	refreshHint()
end

if Save and hint then
	refreshClaimed()
	pcall(function()
		Save.ConnectForDataChanged({ "ClaimedGroupReward" }, refreshClaimed)
	end)
	pcall(function()
		if not Save.IsLocalDataLoaded() then
			Save.LoadedStats:Connect(refreshClaimed)
		end
	end)
end
refreshHint()
