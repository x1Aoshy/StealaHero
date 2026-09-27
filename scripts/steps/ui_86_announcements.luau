--!nocheck
-- scripts/steps/ui_86_announcements.luau (owner 2026-09-27: "put global announcements inside Server, with the stud UI
-- style: nice, sober and simple")
-- Builds the announcement banner every client shows when a Hero admin sends an announcement (admin panel > SERVER):
-- StarterGui.HeroAnnouncements, a ScreenGui (ResetOnSpawn off, DisplayOrder above the HUD and the menus, ScreenInsets
-- CoreUISafeInsets: under the Roblox top bar, clear of a phone's notch) holding one hidden template:
--   Banner    CanvasGroup (the one fade: GroupTransparency), top centre, the screen width minus MARGIN capped at
--             MAX_WIDTH (UISizeConstraint), AutomaticSize Y (the height follows the text), a small padding so the card's
--             ink rim is not clipped by the group
--     Card    the kit's dark studded body (#211d3c + the stud texture, the ink rim and the light inner rim), square
--       Accent   a gold bar down the left edge (the admin panel's band gradient)
--       Timer    a thin gold bar along the bottom the client runs out while it shows
--       Content  UIPadding + UIListLayout: Kicker ("SERVER ANNOUNCEMENT" / "GLOBAL ANNOUNCEMENT", GothamSSm Bold, gold)
--                and Body (the text, FredokaOne, white with the ink outline, wraps, AutomaticSize Y)
-- BranchControllers.AnnouncementController fills and animates it; the remote Network["Announcement: Show"] (server ->
-- client) is created here too (BranchServices.HeroBroadcastService re-creates it if a place lacks it). No emoji, no
-- sound, no new asset: the stud texture is the kit's.

local roblox = require("@lune/roblox")
local UiKit = require("../lib/ui_kit")
local Kit = UiKit.Kit

local Instance = roblox.Instance
local UDim = roblox.UDim
local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum
local hex = Kit.hex

local Step = {}

Step.NAME = "HeroAnnouncements"
Step.REMOTE = "Announcement: Show"
Step.DISPLAY_ORDER = 50 -- over the HUD (<= 34) and the admin panel (40), under the full-screen fades / tutorial
Step.MAX_WIDTH = 560
Step.MARGIN = 32 -- px of screen left free (16 each side) on a narrow phone
Step.TOP = 10
Step.RIM_ROOM = 4
Step.ACCENT_W = 6
Step.TIMER_H = 3
Step.PADDING = { left = 20, right = 16, top = 10, bottom = 13 }
Step.TEXT_SIZE, Step.KICKER_SIZE = 20, 13
Step.COLORS = {
	body = hex("#211d3c"),
	rimLight = hex("#4a4484"),
	gold = hex("#ffd35a"),
	timer = hex("#ffb627"),
	accent = { { 0, "#ffe98a" }, { 0.45, "#ffb627" }, { 1, "#f0681c" } },
}

local function log(fmt, ...)
	print(string.format("[ui_86_announcements] " .. fmt, ...))
end

local function label(parent, name, text, kind, size, color, order)
	local node = UiKit.layer(parent, "TextLabel", name, 4)
	node.BackgroundTransparency = 1
	node.Text = text
	node.TextScaled = false
	node.TextWrapped = true
	node.TextSize = size
	node.RichText = false
	node.TextXAlignment = Enum.TextXAlignment.Left
	node.TextYAlignment = Enum.TextYAlignment.Top
	node.Size = UDim2.new(1, 0, 0, 0)
	node.AutomaticSize = Enum.AutomaticSize.Y
	node.LayoutOrder = order
	Kit.styleText(node, kind, { color = color })
	return node
end

function Step.build()
	local gui = Instance.new("ScreenGui")
	gui.Name = Step.NAME
	gui.ResetOnSpawn = false
	gui.Enabled = true
	gui.DisplayOrder = Step.DISPLAY_ORDER
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("BuiltBy", "scripts/steps/ui_86_announcements.luau")

	local banner = UiKit.layer(gui, "CanvasGroup", "Banner", 1)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, Step.TOP)
	banner.Size = UDim2.new(1, -Step.MARGIN, 0, 0)
	banner.AutomaticSize = Enum.AutomaticSize.Y
	banner.BackgroundTransparency = 1
	banner.GroupTransparency = 1
	banner.Visible = false
	local limit = Kit.ensureChild(banner, "UISizeConstraint", "SpMaxWidth")
	limit.MaxSize = Vector2.new(Step.MAX_WIDTH, 10000)
	limit.MinSize = Vector2.new(0, 0)
	local room = Kit.ensureChild(banner, "UIPadding", "SpRimRoom")
	for _, side in ipairs({ "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" }) do
		room[side] = UDim.new(0, Step.RIM_ROOM)
	end

	local card = UiKit.layer(banner, "Frame", "Card", 1)
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Step.COLORS.body
	card.BackgroundTransparency = 0.04
	Kit.setCorner(card, 0)
	Kit.addStroke(card, { name = Kit.Names.stroke, color = UiKit.INK, thickness = 3, sizing = "FixedSize", mode = "Border" })
	Kit.addStroke(card, { name = "SpRimLight", color = Step.COLORS.rimLight, transparency = 0.35, thickness = 1, sizing = "FixedSize",
		borderOffset = UDim.new(0, -3), zIndex = 2, mode = "Border" })
	UiKit.studs(card, 1, { transparency = 0.62 })

	local accent = UiKit.layer(card, "Frame", "Accent", 2)
	accent.BackgroundColor3 = UiKit.WHITE
	accent.BackgroundTransparency = 0
	accent.AnchorPoint = Vector2.new(0, 0)
	accent.Position = UDim2.new(0, 0, 0, 0)
	accent.Size = UDim2.new(0, Step.ACCENT_W, 1, 0)
	Kit.addGradient(accent, Step.COLORS.accent, 90, "SpAccentGradient")

	local timer = UiKit.layer(card, "Frame", "Timer", 3)
	timer.BackgroundColor3 = Step.COLORS.timer
	timer.BackgroundTransparency = 0.15
	timer.AnchorPoint = Vector2.new(0, 1)
	timer.Position = UDim2.new(0, 0, 1, 0)
	timer.Size = UDim2.new(1, 0, 0, Step.TIMER_H)

	local content = UiKit.layer(card, "Frame", "Content", 3)
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	local padding = Kit.ensureChild(content, "UIPadding", "SpPadding")
	padding.PaddingLeft = UDim.new(0, Step.PADDING.left)
	padding.PaddingRight = UDim.new(0, Step.PADDING.right)
	padding.PaddingTop = UDim.new(0, Step.PADDING.top)
	padding.PaddingBottom = UDim.new(0, Step.PADDING.bottom)
	local list = Kit.ensureChild(content, "UIListLayout", "SpList")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 3)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Left
	label(content, "Kicker", "SERVER ANNOUNCEMENT", "subtitle", Step.KICKER_SIZE, Step.COLORS.gold, 1)
	label(content, "Body", "Announcements from the Steal a Hero team show here.", "body", Step.TEXT_SIZE, UiKit.WHITE, 2)
	return gui
end

function Step.Apply(place_, _spPlace, _ctx)
	local starterGui = place_:GetService("StarterGui")
	local old = starterGui:FindFirstChild(Step.NAME)
	if old then
		old:Destroy()
	end
	local gui = Step.build()
	gui.Parent = starterGui

	local rs = place_:GetService("ReplicatedStorage")
	local network = rs:FindFirstChild("Network")
	if network == nil then
		network = Instance.new("Folder")
		network.Name = "Network"
		network.Parent = rs
	end
	local remote = network:FindFirstChild(Step.REMOTE)
	if remote and not remote:IsA("RemoteEvent") then
		remote:Destroy()
		remote = nil
	end
	if remote == nil then
		remote = Instance.new("RemoteEvent")
		remote.Name = Step.REMOTE
		remote.Parent = network
	end
	log("StarterGui.%s built (top-centre banner, max %d px wide, DisplayOrder %d), remote Network[%q]", Step.NAME, Step.MAX_WIDTH,
		Step.DISPLAY_ORDER, Step.REMOTE)
end

return Step
