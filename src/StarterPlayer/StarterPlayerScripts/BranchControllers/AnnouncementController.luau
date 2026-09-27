-- StarterPlayer.StarterPlayerScripts.BranchControllers.AnnouncementController (Branch controller; injected by
-- scripts/inject/admin_panel.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27: "put global announcements inside Server, with the stud UI style: nice, sober and simple". Draws the
-- announcements the Hero admin panel sends (ServerScriptService.BranchServices.HeroBroadcastService fires
-- Network["Announcement: Show"] { Kind = "Server" | "Global", Text }, the text already filtered by TextService on the
-- server). The banner is the build's StarterGui.HeroAnnouncements.Banner (scripts/steps/ui_86_announcements.luau: a dark
-- studded card with a gold accent, the kicker "SERVER ANNOUNCEMENT" / "GLOBAL ANNOUNCEMENT" and the text), top centre,
-- inside the core UI safe area (ScreenInsets CoreUISafeInsets: under the Roblox top bar and clear of a phone's notch).
--   * one at a time: a new one waits in a queue (at most MAX_QUEUE; beyond that the oldest waiting one is dropped);
--   * a gentle slide down + fade in (the Banner is a CanvasGroup: one GroupTransparency tween), a thin gold timer bar
--     that runs out, then a fade out; each stays DurationFor(text) seconds (~8 s, longer texts a little longer);
--   * sizes per device (PlayerGui attribute UiDeviceProfile, BranchControllers.UiScaleController): the card is the
--     screen width minus a margin, capped at the build's max width, and the text size follows TEXT_SIZES.
-- Anything malformed is ignored (Sanitize).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AnnouncementController = {}

AnnouncementController.REMOTE_NAME = "Announcement: Show"
AnnouncementController.GUI_NAME = "HeroAnnouncements"
AnnouncementController.MAX_QUEUE = 5
AnnouncementController.MAX_CHARS = 200 -- the server caps at 150 characters; '#' filtering keeps the length
AnnouncementController.MIN_SECONDS, AnnouncementController.MAX_SECONDS = 6, 11
AnnouncementController.SECONDS_PER_CHAR = 0.03
AnnouncementController.BASE_SECONDS = 5.5
AnnouncementController.TOP = 10 -- px under the safe area's top edge
AnnouncementController.SLIDE = 18 -- px it slides down while it fades in
AnnouncementController.IN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
AnnouncementController.OUT_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
AnnouncementController.LABELS = { Server = "SERVER ANNOUNCEMENT", Global = "GLOBAL ANNOUNCEMENT" }
-- text / kicker sizes (px) per UiScaleController profile
AnnouncementController.TEXT_SIZES = {
	desktop = { 20, 13 }, tablet = { 21, 13 }, phone = { 16, 11 }, console = { 26, 16 },
}

local queue = {}
local pumping = false
local banner = nil

-- payload -> { Kind, Label, Text } | nil
function AnnouncementController.Sanitize(payload)
	if type(payload) ~= "table" then
		return nil
	end
	local kind = payload.Kind
	if type(kind) ~= "string" or AnnouncementController.LABELS[kind] == nil then
		return nil
	end
	local text = payload.Text
	if type(text) ~= "string" or #text > AnnouncementController.MAX_CHARS * 4 or utf8.len(text) == nil then
		return nil
	end
	text = string.gsub(text, "[%z\1-\31\127]", " ")
	text = string.match(text, "^%s*(.-)%s*$") or ""
	local length = utf8.len(text) or 0
	if length == 0 then
		return nil
	end
	if length > AnnouncementController.MAX_CHARS then
		text = string.sub(text, 1, utf8.offset(text, AnnouncementController.MAX_CHARS + 1) - 1)
	end
	return { Kind = kind, Label = AnnouncementController.LABELS[kind], Text = text }
end

function AnnouncementController.DurationFor(text)
	local length = utf8.len(text or "") or 0
	return math.clamp(AnnouncementController.BASE_SECONDS + length * AnnouncementController.SECONDS_PER_CHAR,
		AnnouncementController.MIN_SECONDS, AnnouncementController.MAX_SECONDS)
end

local function profile()
	local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local value = playerGui and playerGui:GetAttribute("UiDeviceProfile")
	return if type(value) == "string" and AnnouncementController.TEXT_SIZES[value] then value else "desktop"
end

local function findBanner()
	if banner and banner.Parent then
		return banner
	end
	local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild(AnnouncementController.GUI_NAME)
	local node = gui and gui:FindFirstChild("Banner")
	banner = if node and node:IsA("CanvasGroup") then node else nil
	return banner
end

local function play(object, info, goal)
	local tween = TweenService:Create(object, info, goal)
	tween:Play()
	return tween
end

-- Shows one announcement and returns when it has gone (the default presenter; tests replace _present).
local function present(item)
	local node = findBanner()
	if node == nil then
		return
	end
	local card = node:FindFirstChild("Card")
	local content = card and card:FindFirstChild("Content")
	local kicker = content and content:FindFirstChild("Kicker")
	local body = content and content:FindFirstChild("Body")
	local timer = card and card:FindFirstChild("Timer")
	if not (kicker and body) then
		return
	end
	local sizes = AnnouncementController.TEXT_SIZES[profile()]
	kicker.Text = item.Label
	kicker.TextSize = sizes[2]
	body.Text = item.Text
	body.TextSize = sizes[1]
	local top = AnnouncementController.TOP
	node.Position = UDim2.new(0.5, 0, 0, top - AnnouncementController.SLIDE)
	node.GroupTransparency = 1
	node.Visible = true
	local duration = AnnouncementController.DurationFor(item.Text)
	play(node, AnnouncementController.IN_INFO, { Position = UDim2.new(0.5, 0, 0, top), GroupTransparency = 0 })
	if timer then
		timer.Size = UDim2.new(1, 0, 0, timer.Size.Y.Offset)
		play(timer, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, timer.Size.Y.Offset) })
	end
	task.wait(duration)
	local out = play(node, AnnouncementController.OUT_INFO, {
		Position = UDim2.new(0.5, 0, 0, top - AnnouncementController.SLIDE * 0.5), GroupTransparency = 1,
	})
	out.Completed:Wait()
	node.Visible = false
	task.wait(0.15)
end
AnnouncementController._present = present

local function pump()
	if pumping then
		return
	end
	pumping = true
	while #queue > 0 do
		local item = table.remove(queue, 1)
		local ok, err = pcall(AnnouncementController._present, item)
		if not ok then
			warn("[Announcement] " .. tostring(err))
		end
	end
	pumping = false
end

-- Queues a payload from the server (malformed ones are ignored). -> true when queued
function AnnouncementController.Push(payload)
	local item = AnnouncementController.Sanitize(payload)
	if item == nil then
		return false
	end
	table.insert(queue, item)
	while #queue > AnnouncementController.MAX_QUEUE do
		table.remove(queue, 1)
	end
	if not pumping then
		task.spawn(pump)
	end
	return true
end
AnnouncementController._queue = queue

function AnnouncementController:Start()
	local network = ReplicatedStorage:WaitForChild("Network", 30)
	local remote = network and network:WaitForChild(AnnouncementController.REMOTE_NAME, 30)
	if not (remote and remote:IsA("RemoteEvent")) then
		warn("[Announcement] Network['" .. AnnouncementController.REMOTE_NAME .. "'] missing: no announcements on this client")
		return
	end
	remote.OnClientEvent:Connect(AnnouncementController.Push)
	task.defer(findBanner)
end

return AnnouncementController
