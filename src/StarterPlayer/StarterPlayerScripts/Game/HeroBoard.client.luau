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
--   * the hint under the tabs reads CLICK A TAB! / TAP A TAB! for the current input;
--   * the podium follows the selected tab (owner 2026-09-27): LeaderboardService stands every page's top 3 (avatars
--     tagged PodiumStat, plates published as Spot attributes Name_<stat> / Value_<stat>); this client shows only the
--     selected tab's avatars (LocalTransparencyModifier) and writes that tab's plates and the "TOP 3 · <title>" sign;
--   * nobody gets stuck on one page: while the player has not clicked a tab for IDLE_SECONDS, the board moves to the
--     next tab every CYCLE_SECONDS (podium included).
-- Everything degrades quietly: a missing board or tab just leaves the default page (NETWORTH) on screen.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WAIT_SECONDS = 60
local HOVER_MIX = 0.35 -- hovered tab colour: OffColor this far toward OnColor
local POP_SCALE = 1.08
local POP_TIME = 0.18
local CYCLE_SECONDS = 10 -- auto-advance to the next tab ...
local IDLE_SECONDS = 30 -- ... once the player has not clicked a tab for this long

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
local lastClick = -math.huge

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

-- The podium for the selected stat: only its avatars show, its plates and the sign carry its names / title.
local function setHidden(model, hidden)
	local modifier = if hidden then 1 else 0
	for _, d in ipairs(model:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d.LocalTransparencyModifier ~= modifier then
			d.LocalTransparencyModifier = modifier
		end
	end
end

local function applyPodium(page)
	local podium = board:FindFirstChild("Podium")
	if podium == nil then
		return
	end
	local valueColor = page and page:GetAttribute("ValueColor")
	for _, spot in ipairs(podium:GetChildren()) do
		if spot:IsA("Model") and spot:GetAttribute("PodiumRank") then
			local plate = spot:FindFirstChild("FrontFace") and spot.FrontFace:FindFirstChild("NamePlate")
			local card = plate and plate:FindFirstChild("Card")
			local name = card and card:FindFirstChild("PlayerName")
			local value = card and card:FindFirstChild("Value")
			local nameText = spot:GetAttribute("Name_" .. selected)
			local valueText = spot:GetAttribute("Value_" .. selected)
			if name and name:IsA("TextLabel") then
				name.Text = if type(nameText) == "string" then nameText else "???"
			end
			if value and value:IsA("TextLabel") then
				value.Text = if type(valueText) == "string" then valueText else ""
				if typeof(valueColor) == "Color3" then
					value.TextColor3 = valueColor
				end
			end
			for _, child in ipairs(spot:GetChildren()) do
				local stat = child:IsA("Model") and child:GetAttribute("PodiumStat")
				if type(stat) == "string" then
					setHidden(child, stat ~= selected)
				end
			end
		end
	end
	local title = page and page:GetAttribute("LeaderboardTitle")
	local sign = podium:FindFirstChild("BaseSign")
	local label = sign and sign:FindFirstChild("Sign") and sign.Sign:FindFirstChild("Label")
	if label and label:IsA("TextLabel") and type(title) == "string" then
		label.Text = "TOP 3  \u{00B7}  " .. title
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
	applyPodium(pages[selected])
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

local function selectStat(stat, auto)
	if stat == selected then
		return
	end
	selected = stat
	apply()
	if not auto then
		playClick()
	end
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
		lastClick = os.clock()
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

-- the podium: a new avatar or plate value shows / hides at once for this viewer's tab
local podiumQueued = false
local function queuePodium()
	if not podiumQueued then
		podiumQueued = true
		task.defer(function()
			podiumQueued = false
			local _, _, pages = parts()
			applyPodium(pages[selected])
		end)
	end
end
local function watchPodium(podium)
	podium.DescendantAdded:Connect(queuePodium)
	for _, spot in ipairs(podium:GetChildren()) do
		spot.AttributeChanged:Connect(queuePodium)
	end
	podium.ChildAdded:Connect(function(spot)
		spot.AttributeChanged:Connect(queuePodium)
	end)
end
local podium = board:FindFirstChild("Podium")
if podium then
	watchPodium(podium)
else
	task.spawn(function()
		local found = board:WaitForChild("Podium", WAIT_SECONDS)
		if found then
			watchPodium(found)
			queuePodium()
		end
	end)
end

-- the tabs in board order (TabButtons.TabHit_<stat>, attribute TabIndex)
local function tabOrder()
	local order = {}
	local folder = board:FindFirstChild("TabButtons")
	for _, hit in ipairs(folder and folder:GetChildren() or {}) do
		local stat, index = hit:GetAttribute("LeaderboardStat"), hit:GetAttribute("TabIndex")
		if type(stat) == "string" and type(index) == "number" then
			table.insert(order, { stat = stat, index = index })
		end
	end
	table.sort(order, function(a, b)
		return a.index < b.index
	end)
	return order
end

-- auto-cycle while the player is not choosing a tab
task.spawn(function()
	while true do
		task.wait(CYCLE_SECONDS)
		if os.clock() - lastClick >= IDLE_SECONDS then
			local order = tabOrder()
			if #order > 1 then
				local nextIndex = 1
				for i, entry in ipairs(order) do
					if entry.stat == selected then
						nextIndex = i % #order + 1
					end
				end
				selectStat(order[nextIndex].stat, true)
			end
		end
	end
end)

apply()
refreshHint()
