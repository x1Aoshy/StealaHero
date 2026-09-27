-- StarterPlayerScripts.Game.HeroBoard (owner HEROBOARD 2026-09-26, injected by scripts/inject/leaderboards.luau)
-- The hub's HERO BOARD (Workspace.Hub.HeroBoard, built by scripts/steps/post_x_hero_board.luau) shows one leaderboard
-- page at a time: TOTAL NETWORTH (default), TOTAL SPEED, IN-GAME TIME or EGGS HATCHED. A SurfaceGui parented under a
-- Workspace part receives no GUI input, so every tab has an invisible click part laid exactly over it
-- (HeroBoard.TabButtons.TabHit_<stat>, a ClickDetector: mouse clicks and touch taps). This script switches the page
-- LOCALLY for its own player: the pages live in Workspace (ServerScriptService.LeaderboardService fills all of them),
-- and a property a client sets on a replicated instance stays local as long as the server never writes it (the server
-- writes row texts / images / visibility, never a page's Visible nor a tab's look).
--   * selected tab: its stat colour (tab attribute OnColor), full-bright icon and caption, the pointer diamond toward
--     the list, a little pop (UIScale "Pop"); the others: OffColor, dimmed;
--   * hovered tab (MouseHoverEnter / MouseHoverLeave): a lighter OffColor;
--   * the hint under the tabs reads CLICK A TAB! / TAP A TAB! for the current input.
-- Everything degrades quietly: a missing board or tab just leaves the default page (NETWORTH) on screen.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WAIT_SECONDS = 60
local HOVER_MIX = 0.35 -- hovered tab colour: OffColor this far toward OnColor
local POP_SCALE = 1.08
local POP_TIME = 0.18

local hub = Workspace:WaitForChild("Hub", WAIT_SECONDS)
local board = hub and hub:WaitForChild("HeroBoard", WAIT_SECONDS)
if board == nil then
	return
end

local selected = board:GetAttribute("DefaultStat")
if type(selected) ~= "string" then
	selected = "Networth"
end
local hovered = nil

local function boardRoot()
	local screen = board:FindFirstChild("Screen")
	local gui = screen and screen:FindFirstChild("BoardGui")
	return gui and gui:FindFirstChild("Board")
end

-- stat -> tab / pointer / page (looked up each time: robust to the board being rebuilt or replicated late)
local function parts()
	local tabs, pointers, pages = {}, {}, {}
	local root = boardRoot()
	if root == nil then
		return tabs, pointers, pages
	end
	local tabFolder = root:FindFirstChild("Tabs")
	for _, child in ipairs(tabFolder and tabFolder:GetChildren() or {}) do
		local stat = child:GetAttribute("LeaderboardStat")
		if type(stat) == "string" and child:IsA("GuiObject") then
			if string.sub(child.Name, 1, 4) == "Tab_" then
				tabs[stat] = child
			elseif string.sub(child.Name, 1, 8) == "Pointer_" then
				pointers[stat] = child
			end
		end
	end
	local list = root:FindFirstChild("List")
	local pageFolder = list and list:FindFirstChild("Pages")
	for _, page in ipairs(pageFolder and pageFolder:GetChildren() or {}) do
		local stat = page:GetAttribute("LeaderboardStat")
		if type(stat) == "string" and page:IsA("GuiObject") then
			pages[stat] = page
		end
	end
	return tabs, pointers, pages
end

local function colorAttribute(inst, name, fallback)
	local value = inst:GetAttribute(name)
	return if typeof(value) == "Color3" then value else fallback
end

local function styleTab(tab, isSelected, isHovered)
	local on = colorAttribute(tab, "OnColor", Color3.fromRGB(43, 214, 60))
	local off = colorAttribute(tab, "OffColor", Color3.fromRGB(44, 50, 82))
	local color = if isSelected then on elseif isHovered then off:Lerp(on, HOVER_MIX) else off
	if tab.BackgroundColor3 ~= color then
		tab.BackgroundColor3 = color
	end
	local icon = tab:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		icon.ImageTransparency = if isSelected or isHovered then 0 else 0.3
	end
	local caption = tab:FindFirstChild("Caption")
	if caption and caption:IsA("TextLabel") then
		caption.TextTransparency = if isSelected or isHovered then 0 else 0.2
	end
end

local function apply()
	local tabs, pointers, pages = parts()
	if pages[selected] == nil then
		-- unknown stat (a renamed page): fall back to the board default
		local default = board:GetAttribute("DefaultStat")
		if type(default) == "string" and pages[default] then
			selected = default
		end
	end
	for stat, page in pairs(pages) do
		local visible = stat == selected
		if page.Visible ~= visible then
			page.Visible = visible
		end
	end
	for stat, tab in pairs(tabs) do
		styleTab(tab, stat == selected, stat == hovered)
	end
	for stat, pointer in pairs(pointers) do
		pointer.Visible = stat == selected
	end
end

local function pop(inst, from)
	local scale = inst and inst:FindFirstChild("Pop")
	if scale and scale:IsA("UIScale") then
		scale.Scale = from
		TweenService:Create(scale, TweenInfo.new(POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

local function playClick()
	local folder = SoundService:FindFirstChild("SpeedstersSfx")
	local sound = folder and folder:FindFirstChild("UI_CLICK")
	if sound and sound:IsA("Sound") then
		pcall(function()
			sound:Play()
		end)
	end
end

local function selectStat(stat)
	if stat == selected then
		return
	end
	selected = stat
	apply()
	playClick()
	local tabs, _, pages = parts()
	pop(tabs[stat], POP_SCALE)
	pop(pages[stat], 0.97)
end

-- ClickDetector events fire on this client for this player's own mouse / touch
local bound = setmetatable({}, { __mode = "k" })
local function bind(detector)
	if not detector:IsA("ClickDetector") or bound[detector] then
		return
	end
	local part = detector.Parent
	local stat = part and part:GetAttribute("LeaderboardStat")
	if type(stat) ~= "string" then
		return
	end
	bound[detector] = true
	detector.MouseClick:Connect(function()
		selectStat(stat)
	end)
	detector.MouseHoverEnter:Connect(function()
		hovered = stat
		apply()
	end)
	detector.MouseHoverLeave:Connect(function()
		if hovered == stat then
			hovered = nil
			apply()
		end
	end)
end

for _, descendant in ipairs(board:GetDescendants()) do
	bind(descendant)
end

-- late replication / a rebuilt board: re-bind and re-apply once per burst of additions
local reapplyQueued = false
board.DescendantAdded:Connect(function(descendant)
	bind(descendant)
	if not reapplyQueued then
		reapplyQueued = true
		task.defer(function()
			reapplyQueued = false
			apply()
		end)
	end
end)

-- the hint under the tabs, worded for the current input
local HINT = { touch = "TAP A TAB!", mouse = "CLICK A TAB!", gamepad = "PICK A TAB!" }
local function inputKind()
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
local function refreshHint()
	local root = boardRoot()
	local hint = root and root:FindFirstChild("Hint")
	local text = HINT[inputKind()]
	if hint and hint:IsA("TextLabel") and hint.Text ~= text then
		hint.Text = text
	end
end
UserInputService.LastInputTypeChanged:Connect(refreshHint)

apply()
refreshHint()
