-- StarterPlayer.StarterPlayerScripts.GUI.SellHeroes (LocalScript; injected by scripts/inject/windows.luau)
-- Drives the "Sell Heroes" window (VISUAL_PASS_PLAN D7, design/references/06). The window is the base place's
-- AutoSell tab (PlayerGui.AutoSell, a registered TabController tab whose Backpack button the base game hides),
-- re-laid out by scripts/steps/ui_20_windows.luau, which also sets the root attribute SellHeroesWindow = true. The hub
-- sell stall's "Sell All" prompt opens it (Game.Npcs.AssetSellerNpc).
--   HEROES tab: every hero of the Inventory that is not placed in the pen, not favorited and not in a fuse machine.
--   EGGS tab: the eggs waiting in the backpack (not placed: growing eggs stay in the base).
--     On both tabs cards are selected by clicking (or Select All); Sort By Size (Scale) or Value; Total Value is the
--     sum of the selection. Sell asks for a second click ("Confirm?") and then sends the whole selection in ONE
--     "ActiveAssets: RequestSell" call ({ Heroes = uids } / { Eggs = uids }, chunked above the server's MaxSellBatch).
--     The server (AssetService, "SELLING" section) re-validates every uid, pays, removes the Tools and answers
--     { Sold, SoldHeroes, SoldEggs, Earned, Money, Skipped, Note }; the window hides the sold cards at once and shows
--     "Sold 3 heroes for $12.4K!". Prices shown = what the server pays: hero floor(value x HeroSellMultiplier), egg
--     floor(EggItemUtil.GetSellPrice x EggSellMultiplier), multipliers read from the RequestSell remote's attributes.
--   Hero cards show a live headshot of the hero model (Library.Client.HeroPortrait, docs/HERO_MODELS_PLAN.md H3),
--     mounted once the card is scrolled into view; a hero without a model keeps its config Icon. Cards are kept per
--     uid between rebuilds (a sale only removes the sold cards), so portraits are not re-cloned on every save change.
--   Money shows the HUD's cash icon (scripts/steps/ui_79_sell_cash.luau): the Total Value icon and a small icon on every
--     card's price row, centred together with the price from the label's TextBounds; the image is re-read from the HUD
--     money row (PlayerGui.Money...CurrencyIcon, else the root's SpCashIcon attribute) so both always match.
-- Runs once per client (StarterPlayerScripts); the ScreenGui has ResetOnSpawn = false. Quietly does nothing when the
-- window was not converted by the build.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WAIT_TIMEOUT = 30
local TAB_NAME = "AutoSell"
local TAB_HEROES, TAB_EGGS = "heroes", "eggs"
local SORT_SIZE, SORT_VALUE = "size", "value"
-- fallbacks only: the server publishes the live values as attributes of the RequestSell remote (AssetService)
local DEFAULT_HERO_MULTIPLIER = 1.33
local DEFAULT_EGG_MULTIPLIER = 1
local DEFAULT_SELL_BATCH = 300
local SELL_CHUNK_GAP = 0.45 -- the server rate-limits sell requests (0.35 s)
local SELL_TIMEOUT = 15
local HIDE_SOLD_SECONDS = 10 -- sold cards stay hidden until the save update lands
local CONFIRM_SECONDS = 3
local COLUMNS = 4
local CARD_ASPECT = 1.18 -- card height / width
local EGG_ICON = "rbxassetid://96783034607256"
local WARN_COLOR = Color3.fromRGB(255, 170, 0)
local GOOD_COLOR = Color3.fromRGB(85, 255, 85)
local BAD_COLOR = Color3.fromRGB(255, 70, 70)

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui", WAIT_TIMEOUT)
local screenGui = playerGui and playerGui:WaitForChild(TAB_NAME, WAIT_TIMEOUT)
local root = screenGui and screenGui:WaitForChild("Frame", WAIT_TIMEOUT)
if not (root and root:GetAttribute("SellHeroesWindow") == true) then
	return
end

local Library = ReplicatedStorage:WaitForChild("Library", WAIT_TIMEOUT)
local Directory = ReplicatedStorage:WaitForChild("Directory", WAIT_TIMEOUT)
if not (Library and Directory) then
	warn("[SellHeroes] ReplicatedStorage.Library / Directory missing: window disabled")
	return
end

local Save = require(Library.Client.Save)
local Network = require(Library.Client.Network)
local TabController = require(Library.Client.TabController)
local ButtonFX = require(Library.Client.GUIFX.ButtonFX)
local Notify = require(Library.Client.NotificationCmds.Message)
local Simple = require(Library.Modules.FormatNumber.Simple)
local AssetItemSerialization = require(Library.Util.AssetItemSerialization)
local GetPriceValueForItem = require(Library.Util.GetPriceValueForItem)
local EggItemUtil = require(Library.Util.EggItemUtil)
local Assets = require(Directory.Assets)

-- optional: without HeroPortrait the cards show the config icons
local HeroPortrait = nil
do
	local module = Library.Client:FindFirstChild("HeroPortrait") or Library.Client:WaitForChild("HeroPortrait", 5)
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			HeroPortrait = result
		else
			warn("[SellHeroes] Library.Client.HeroPortrait failed to load: " .. tostring(result))
		end
	end
end
local PORTRAITS_PER_FRAME = 4

-- optional: the eggs tab shows each egg's own voxel egg (owner 2026-09-27), else the config icon
local EggPortrait = nil
do
	local module = Library.Client:FindFirstChild("EggPortrait") or Library.Client:WaitForChild("EggPortrait", 5)
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			EggPortrait = result
		end
	end
end

local activeAssets = Network.NET_MAP and Network.NET_MAP.ActiveAssets
local REQUEST_SELL = (activeAssets and activeAssets.REQUEST_SELL) or "ActiveAssets: RequestSell"

-- A number the server published on the RequestSell remote (HeroSellMultiplier / EggSellMultiplier / MaxSellBatch).
local function sellSetting(name: string, default: number): number
	local folder = ReplicatedStorage:FindFirstChild("Network")
	local remote = folder and folder:FindFirstChild(REQUEST_SELL)
	local value = remote and remote:GetAttribute(name)
	if type(value) == "number" and value == value and value >= 0 and value < math.huge then
		return value
	end
	return default
end

-- HOOK (HATCH, via LEAD): per-hero egg icons. Replace the body with the one-line lookup once the egg icons exist, e.g.
--   return EggIcons[category] or EGG_ICON
-- per-hero egg icon from Directory.EggIcons (0 = not uploaded yet -> the generic egg image)
local function eggIconFor(category: string?): string
	local ok, icon = pcall(function()
		return require((Directory :: any):FindFirstChild("EggIcons")).Resolve(category, EGG_ICON)
	end)
	return if ok and type(icon) == "string" and icon ~= "" then icon else EGG_ICON
end

-- window parts (built by scripts/steps/ui_20_windows.luau, Windows.AutoSell)
local function find(parent: Instance?, childPath: string): Instance?
	local node = parent
	for _, name in string.split(childPath, "/") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

local PARTS = {
	heroesTab = "SpTabs/HeroesTab",
	eggsTab = "SpTabs/EggsTab",
	sortSize = "SpSortPanel/SortSize",
	sortValue = "SpSortPanel/SortValue",
	selectAll = "SpSortPanel/SelectAll",
	selectAllLabel = "SpSortPanel/SelectAll/Label",
	list = "SpList",
	empty = "SpEmpty",
	totalLabel = "SpFooter/TotalLabel",
	cashIcon = "SpFooter/CashIcon",
	glow = "SpFooter/SpGlow",
	totalValue = "SpFooter/TotalValue",
	hint = "SpFooter/Hint",
	sellButton = "SpFooter/SellButton",
	sellLabel = "SpFooter/SellButton/Label",
	template = "SpCardTemplate",
}
local ui: { [string]: any } = {}
for key, childPath in PARTS do
	local node = find(root, childPath)
	if node == nil then
		warn("[SellHeroes] window part missing: " .. childPath)
		return
	end
	ui[key] = node
end
local grid = ui.list:FindFirstChildOfClass("UIGridLayout")
local padding = ui.list:FindFirstChildOfClass("UIPadding")
if grid == nil then
	warn("[SellHeroes] SpList.UIGridLayout missing")
	return
end
-- hero card portraits: mounted once scrolled into the list's view, a few per frame
local portraits = if HeroPortrait ~= nil then HeroPortrait.Lazy(ui.list, { PerStep = PORTRAITS_PER_FRAME }) else nil

local function colorAttribute(name: string, default: Color3): Color3
	local value = root:GetAttribute(name)
	return if typeof(value) == "Color3" then value else default
end
local ON_COLOR = colorAttribute("SpOnColor", Color3.fromRGB(43, 214, 60))
local OFF_COLOR = colorAttribute("SpOffColor", Color3.fromRGB(79, 86, 116))
local TAB_OFF_COLOR = colorAttribute("SpTabOffColor", Color3.fromRGB(29, 90, 43))

-- cash icon = the HUD money row's icon (build: ui_79_sell_cash; re-read here so a HUD change is followed)
do
	local function isImage(node: Instance?): boolean
		return node ~= nil and (node:IsA("ImageLabel") or node:IsA("ImageButton"))
	end
	local money = playerGui:FindFirstChild("Money")
	local hudIcon = money and find(money, "Bottom/Frame/Money/CurrencyIcon")
	local image = if isImage(hudIcon) then (hudIcon :: ImageLabel).Image else ""
	if image == "" then
		local attribute = root:GetAttribute("SpCashIcon")
		image = if type(attribute) == "string" then attribute else ""
	end
	if image ~= "" then
		for _, node in { ui.cashIcon, ui.template:FindFirstChild("CashIcon") } do
			if isImage(node) then
				(node :: ImageLabel).Image = image
			end
		end
	end
end

local templateStroke = ui.template:FindFirstChild("Rarity")
local BASE_STROKE = if templateStroke and templateStroke:IsA("UIStroke") then templateStroke.Thickness else 0.035

type Entry = {
	uid: string,
	name: string,
	icon: string?,
	category: string?, -- hero id (heroes tab): its portrait replaces the icon
	eggCategory: string?, -- hero id of an egg (eggs tab): its voxel egg replaces the icon
	size: number,
	value: number,
	color: Color3?,
	rank: number,
}

local state = {
	tab = TAB_HEROES,
	sort = SORT_VALUE,
	selected = {} :: { [string]: boolean },
	entries = {} :: { Entry },
	cards = {} :: { [string]: GuiButton },
	cardsTab = nil :: string?, -- the tab the live cards were built for
	confirmUntil = 0,
	selling = false,
	rebuildQueued = false,
	hidden = {} :: { [string]: number }, -- sold uid -> os.clock() until which its card stays hidden
}

local function isHidden(uid: string): boolean
	local untilClock = state.hidden[uid]
	return untilClock ~= nil and os.clock() < untilClock
end

local function isOpen(): boolean
	local ok, open = pcall(TabController.IsOpen, TAB_NAME)
	return ok and open == true
end

local function formatMoney(amount: number): string
	local ok, text = pcall(Simple.FormatCompact, amount, ".#")
	return "$" .. (if ok then tostring(text) else tostring(math.floor(amount)))
end

local function notify(message: string, color: Color3)
	pcall(Notify.Bottom, {
		Message = message,
		Time = 2.5,
		PreventDuplicateText = true,
		Color = color,
	})
end

local function directoryEntry(category: any)
	if type(category) ~= "string" then
		return nil
	end
	local ok, config = pcall(function()
		return Assets.Directory[category]
	end)
	return if ok and type(config) == "table" then config else nil
end

local function displayName(config, category: string): string
	local name = config and config.DisplayName
	if type(name) ~= "string" or name == "" then
		return category
	end
	return name
end

local function rarityOf(config): (Color3?, number)
	local rarity = config and config.Rarity
	if type(rarity) ~= "table" then
		return nil, 0
	end
	local color = if typeof(rarity.Color) == "Color3" then rarity.Color else nil
	return color, tonumber(rarity.RarityNumber) or 0
end

-- Heroes the player can sell: not placed in the pen, not favorited, not in a fuse machine.
local function heroEntries(save): { Entry }
	local list = {}
	local inventory = save and save.Inventory
	if type(inventory) ~= "table" then
		return list
	end
	-- kept out, same rules as the server (AssetService heroSellBlock): placed in the pen, favorited, in the fuse machine
	local kept = {}
	for _, field in { "EquippedAssets", "FusionSlots" } do
		if type(save[field]) == "table" then
			for _, uid in save[field] do
				kept[uid] = true
			end
		end
	end
	local favorites = if type(save.FavoriteAssets) == "table" then save.FavoriteAssets else {}
	local multiplier = sellSetting("HeroSellMultiplier", DEFAULT_HERO_MULTIPLIER)
	for uid, raw in inventory do
		if type(uid) == "string" and not kept[uid] and not favorites[uid] and not isHidden(uid) then
			local ok, item = pcall(AssetItemSerialization.Deserialize, raw)
			local config = if ok and type(item) == "table" then directoryEntry(item.Category) else nil
			if config and item.IsFavorite ~= true and not item.InFuse then
				-- priced from the raw save record, like the server prices its profile record
				local okPrice, price = pcall(GetPriceValueForItem, raw)
				if not (okPrice and type(price) == "number") then
					okPrice, price = pcall(GetPriceValueForItem, item)
				end
				local color, rank = rarityOf(config)
				table.insert(list, {
					uid = uid,
					name = displayName(config, item.Category),
					icon = if type(config.Icon) == "string" then config.Icon else nil,
					category = item.Category,
					size = tonumber(item.Scale) or 1,
					value = if okPrice and type(price) == "number" and price == price then math.max(math.floor(price * multiplier), 0) else 0,
					color = color,
					rank = rank,
				})
			end
		end
	end
	return list
end

-- Eggs waiting in the backpack (placed eggs are growing in the base).
local function eggEntries(save): { Entry }
	local list = {}
	local eggs = save and save.EggInventory
	if type(eggs) ~= "table" then
		return list
	end
	local multiplier = sellSetting("EggSellMultiplier", DEFAULT_EGG_MULTIPLIER)
	for uid, raw in eggs do
		if type(uid) == "string" and type(raw) == "table" and raw.Placement == nil and not isHidden(uid) then
			local ok, egg = pcall(EggItemUtil.DeserializeSavedEgg, raw)
			if ok and egg ~= nil then
				local okName, name = pcall(EggItemUtil.GetDisplayNameWithWeight, egg)
				local category = if type(egg.AssetCategory) == "string" then egg.AssetCategory else nil
				local config = directoryEntry(category)
				local color, rank = rarityOf(config)
				-- same price as the server: AssetService.eggSellPrice = floor(GetSellPrice(egg) x EggSellMultiplier)
				local okPrice, price = pcall(EggItemUtil.GetSellPrice, egg)
				table.insert(list, {
					uid = uid,
					name = if okName and type(name) == "string" then name else "Egg",
					icon = eggIconFor(category),
					eggCategory = category,
					size = tonumber(egg.AssetScale) or 1,
					value = if okPrice and type(price) == "number" and price == price then math.max(math.floor(price * multiplier), 0) else 0,
					color = color,
					rank = rank,
				})
			end
		end
	end
	return list
end

local function sortEntries(list: { Entry })
	table.sort(list, function(a: Entry, b: Entry)
		if state.sort == SORT_SIZE then
			if a.size ~= b.size then
				return a.size > b.size
			end
		elseif a.value ~= b.value then
			return a.value > b.value
		end
		if a.rank ~= b.rank then
			return a.rank > b.rank
		end
		return a.uid < b.uid
	end)
end

local function selection(): ({ string }, number)
	local uids, total = {}, 0
	for _, entry in state.entries do
		if state.selected[entry.uid] then
			table.insert(uids, entry.uid)
			total += entry.value
		end
	end
	return uids, total
end

-- Card cells: offsets computed from the list's width (UDim scale inside a ScrollingFrame follows the canvas).
local function layoutCells()
	local scale = 1
	local rootScale = root:FindFirstChildOfClass("UIScale")
	if rootScale and rootScale.Scale > 0 then
		scale = rootScale.Scale
	end
	local width = ui.list.AbsoluteSize.X / scale
	if width <= 0 then
		return
	end
	local inner = width - (if padding then padding.PaddingLeft.Offset + padding.PaddingRight.Offset else 22)
	local gap = math.max(4, math.floor(inner * 0.022))
	local cellWidth = math.max(40, math.floor((inner - gap * (COLUMNS - 1)) / COLUMNS))
	grid.CellPadding = UDim2.fromOffset(gap, gap)
	grid.CellSize = UDim2.fromOffset(cellWidth, math.floor(cellWidth * CARD_ASPECT))
end

local function paintCard(card: GuiButton, entry: Entry)
	local selected = state.selected[entry.uid] == true
	local check = card:FindFirstChild("Check")
	if check and check:IsA("GuiObject") then
		check.Visible = selected
	end
	local stroke = card:FindFirstChild("Rarity")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = if selected then ON_COLOR else (entry.color or Color3.new(1, 1, 1))
		stroke.Thickness = if selected then BASE_STROKE * 1.7 else BASE_STROKE
	end
end

local refreshFooter -- forward

local function toggleSelection(uid: string)
	if state.selling then
		return
	end
	state.selected[uid] = if state.selected[uid] then nil else true
	state.confirmUntil = 0
	local card = state.cards[uid]
	if card then
		for _, entry in state.entries do
			if entry.uid == uid then
				paintCard(card, entry)
				break
			end
		end
	end
	refreshFooter()
end

local function setText(parent: Instance, name: string, text: string)
	local label = parent:FindFirstChild(name)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function clearCards()
	for _, child in ui.list:GetChildren() do
		if child:GetAttribute("SellHeroesCard") == true then
			child:Destroy()
		end
	end
	table.clear(state.cards)
end

-- The hero's live headshot on the card Icon (its image hidden), else the entry icon (eggs, heroes without a model).
local function showIcon(icon: ImageLabel, entry: Entry)
	if EggPortrait ~= nil then
		EggPortrait.Clear(icon)
		if entry.eggCategory ~= nil and EggPortrait.Mount(icon, entry.eggCategory) ~= nil then
			if portraits ~= nil then
				portraits:Cancel(icon)
			end
			if HeroPortrait ~= nil then
				HeroPortrait.Clear(icon)
			end
			icon.Image = ""
			icon.ImageTransparency = 1
			return
		end
	end
	local category = entry.category
	if portraits ~= nil and category ~= nil and HeroPortrait.HasModel(category) then
		icon.Image = ""
		icon.ImageTransparency = 1
		portraits:Request(icon, category, {
			OnFailed = function()
				if icon.Parent ~= nil then
					icon.Image = entry.icon or ""
					icon.ImageTransparency = 0
				end
			end,
		})
		return
	end
	if portraits ~= nil then
		portraits:Cancel(icon)
		HeroPortrait.Clear(icon)
	end
	icon.Image = entry.icon or ""
	icon.ImageTransparency = 0
end

local function fillCard(card: GuiButton, entry: Entry, order: number)
	card.LayoutOrder = order
	local icon = card:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		showIcon(icon, entry)
	end
	setText(card, "HeroName", entry.name)
	setText(card, "SizeTag", string.format("%.1fx", entry.size))
	setText(card, "Value", formatMoney(entry.value))
	paintCard(card, entry)
end

-- Price row: the cash icon sits just left of the price text and the pair is centred on the card (from TextBounds;
-- the connections die with the card).
local function bindPriceRow(card: GuiButton)
	local label = card:FindFirstChild("Value")
	local icon = card:FindFirstChild("CashIcon")
	if not (label and label:IsA("TextLabel") and icon and icon:IsA("GuiObject")) then
		return
	end
	local rowY = label.Position.Y
	local iconY = icon.Position.Y
	label.AnchorPoint = Vector2.new(0.5, label.AnchorPoint.Y)
	icon.AnchorPoint = Vector2.new(0, icon.AnchorPoint.Y)
	local function place()
		local cardWidth = card.AbsoluteSize.X
		local iconWidth = icon.AbsoluteSize.X
		local textWidth = label.TextBounds.X
		if cardWidth <= 0 or iconWidth <= 0 or textWidth <= 0 then
			return
		end
		local gap = iconWidth * 0.15
		local left = math.max((cardWidth - (iconWidth + gap + textWidth)) / 2, cardWidth * 0.03)
		icon.Position = UDim2.new(left / cardWidth, 0, iconY.Scale, iconY.Offset)
		label.Position = UDim2.new((left + iconWidth + gap + textWidth / 2) / cardWidth, 0, rowY.Scale, rowY.Offset)
	end
	label:GetPropertyChangedSignal("TextBounds"):Connect(place)
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	icon:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
end

local function mountCard(entry: Entry, order: number)
	local card = ui.template:Clone() :: GuiButton
	card.Name = "Card"
	card.LayoutOrder = order
	card.Visible = true
	card:SetAttribute("SellHeroesCard", true)
	card:SetAttribute("Uid", entry.uid)
	local uid = entry.uid
	card.Activated:Connect(function()
		toggleSelection(uid)
	end)
	card.Parent = ui.list
	bindPriceRow(card)
	fillCard(card, entry, order)
	state.cards[entry.uid] = card
end

function refreshFooter()
	local onEggs = state.tab == TAB_EGGS
	local uids, total = selection()
	local count = #state.entries
	local canSell = #uids > 0 and not state.selling
	local confirming = canSell and os.clock() < state.confirmUntil

	-- eggs sell too now: the Total Value row shows on both tabs (the build's "can't be sold" hint stays hidden)
	ui.totalLabel.Visible = true
	ui.cashIcon.Visible = true
	ui.glow.Visible = true
	ui.totalValue.Visible = true
	ui.hint.Visible = false
	ui.totalValue.Text = formatMoney(total)

	ui.sellButton.BackgroundColor3 = if canSell then ON_COLOR else OFF_COLOR
	ui.sellLabel.Text = if state.selling then "Selling..." elseif confirming then "Confirm?" else "Sell"

	local allSelected = count > 0 and #uids == count
	ui.selectAll.BackgroundColor3 = if allSelected then ON_COLOR else OFF_COLOR
	if ui.selectAllLabel:IsA("TextLabel") then
		ui.selectAllLabel.Text = if allSelected then "Unselect All" else "Select All"
	end
	ui.sortSize.BackgroundColor3 = if state.sort == SORT_SIZE then ON_COLOR else OFF_COLOR
	ui.sortValue.BackgroundColor3 = if state.sort == SORT_VALUE then ON_COLOR else OFF_COLOR
	ui.heroesTab.BackgroundColor3 = if onEggs then TAB_OFF_COLOR else ON_COLOR
	ui.eggsTab.BackgroundColor3 = if onEggs then ON_COLOR else TAB_OFF_COLOR

	ui.empty.Visible = count == 0
	if ui.empty:IsA("TextLabel") then
		ui.empty.Text = if onEggs then "No eggs in your backpack." else "No heroes to sell yet!"
	end
end

local function rebuild()
	state.rebuildQueued = false
	local now = os.clock()
	for uid, untilClock in state.hidden do
		if now >= untilClock then
			state.hidden[uid] = nil
		end
	end
	local save = Save.Get()
	local entries = if state.tab == TAB_HEROES then heroEntries(save) else eggEntries(save)
	sortEntries(entries)
	local alive = {}
	for _, entry in entries do
		alive[entry.uid] = true
	end
	for uid in state.selected do
		if not alive[uid] then
			state.selected[uid] = nil
		end
	end
	state.entries = entries
	-- cards are kept per uid while the tab stays the same (their portraits too); a tab switch starts over
	if state.cardsTab ~= state.tab then
		clearCards()
		state.cardsTab = state.tab
	end
	for uid, card in state.cards do
		if not alive[uid] then
			card:Destroy()
			state.cards[uid] = nil
		end
	end
	for i, entry in entries do
		local card = state.cards[entry.uid]
		if card ~= nil and card.Parent ~= nil then
			fillCard(card, entry, i)
		else
			mountCard(entry, i)
		end
	end
	layoutCells()
	refreshFooter()
end

-- Save broadcasts arrive once per sold hero: rebuild once per frame at most.
local function queueRebuild()
	if state.rebuildQueued or not isOpen() then
		return
	end
	state.rebuildQueued = true
	task.defer(function()
		if isOpen() then
			rebuild()
		else
			state.rebuildQueued = false
		end
	end)
end

local function setTab(tab: string)
	if state.selling or state.tab == tab then
		return
	end
	state.tab = tab
	table.clear(state.selected)
	state.confirmUntil = 0
	rebuild()
end

local function setSort(sort: string)
	if state.sort == sort then
		return
	end
	state.sort = sort
	rebuild()
end

local function toggleSelectAll()
	if state.selling or #state.entries == 0 then
		return
	end
	local uids = selection()
	local selectEverything = #uids < #state.entries
	table.clear(state.selected)
	if selectEverything then
		for _, entry in state.entries do
			state.selected[entry.uid] = true
		end
	end
	state.confirmUntil = 0
	for _, entry in state.entries do
		local card = state.cards[entry.uid]
		if card then
			paintCard(card, entry)
		end
	end
	refreshFooter()
end

-- Network.Invoke with a deadline: a server that never answers must not leave the window stuck on "Selling...".
-- Returns (answered, success, resultOrMessage).
local function invokeSell(request): (boolean, any, any)
	local done, okCall, success, result = false, false, nil, nil
	task.spawn(function()
		okCall, success, result = pcall(Network.Invoke, REQUEST_SELL, request)
		done = true
	end)
	local deadline = os.clock() + SELL_TIMEOUT
	while not done and os.clock() < deadline do
		task.wait(0.1)
	end
	if not done then
		return false, nil, "The sale is taking too long - check your money in a moment."
	end
	if not okCall then
		warn("[SellHeroes] RequestSell failed: " .. tostring(success))
		return false, nil, "Selling failed - try again!"
	end
	return true, success, result
end

local function plural(count: number, one: string, many: string): string
	return string.format("%d %s", count, if count == 1 then one else many)
end

local function sellSelection()
	if state.selling then
		return
	end
	local onEggs = state.tab == TAB_EGGS
	local uids = selection()
	if #uids == 0 then
		notify(if onEggs then "Select the eggs you want to sell!" else "Select the heroes you want to sell!", WARN_COLOR)
		return
	end
	if os.clock() >= state.confirmUntil then
		state.confirmUntil = os.clock() + CONFIRM_SECONDS
		refreshFooter()
		task.delay(CONFIRM_SECONDS + 0.05, refreshFooter)
		return
	end
	state.confirmUntil = 0
	state.selling = true
	refreshFooter()

	local soldHeroes, soldEggs, earned = 0, 0, 0
	local note, failure = nil, nil
	local batch = math.max(1, math.floor(sellSetting("MaxSellBatch", DEFAULT_SELL_BATCH)))
	for first = 1, #uids, batch do
		if first > 1 then
			task.wait(SELL_CHUNK_GAP)
		end
		local chunk = table.move(uids, first, math.min(first + batch - 1, #uids), 1, {})
		local answered, success, result = invokeSell(if onEggs then { Eggs = chunk } else { Heroes = chunk })
		if answered and success == true and type(result) == "table" then
			soldHeroes += tonumber(result.SoldHeroes) or 0
			soldEggs += tonumber(result.SoldEggs) or 0
			earned += tonumber(result.Earned) or 0
			if note == nil and type(result.Note) == "string" and (tonumber(result.Skipped) or 0) > 0 then
				note = result.Note
			end
			local hideUntil = os.clock() + HIDE_SOLD_SECONDS
			for _, uid in (if type(result.Sold) == "table" then result.Sold else {}) do
				if type(uid) == "string" then
					state.hidden[uid] = hideUntil
					state.selected[uid] = nil
				end
			end
		else
			failure = if type(result) == "string" then result else "Selling failed - try again!"
			break
		end
	end
	state.selling = false

	if soldHeroes + soldEggs > 0 then
		local parts = {}
		if soldHeroes > 0 then
			table.insert(parts, plural(soldHeroes, "hero", "heroes"))
		end
		if soldEggs > 0 then
			table.insert(parts, plural(soldEggs, "egg", "eggs"))
		end
		notify(string.format("Sold %s for %s!", table.concat(parts, " and "), formatMoney(earned)), GOOD_COLOR)
		if note or failure then
			task.delay(0.6, notify, note or failure, WARN_COLOR)
		end
	else
		notify(failure or note or (if onEggs then "Those eggs could not be sold. Try again!" else "Those heroes could not be sold. Try again!"), BAD_COLOR)
	end
	if isOpen() then
		rebuild()
	else
		refreshFooter()
	end
end

local function bind(button: Instance, callback: () -> ())
	if button:IsA("GuiButton") then
		ButtonFX(button, nil, callback)
	end
end

bind(ui.heroesTab, function()
	setTab(TAB_HEROES)
end)
bind(ui.eggsTab, function()
	setTab(TAB_EGGS)
end)
bind(ui.sortSize, function()
	setSort(SORT_SIZE)
end)
bind(ui.sortValue, function()
	setSort(SORT_VALUE)
end)
bind(ui.selectAll, toggleSelectAll)
bind(ui.sellButton, function()
	task.spawn(sellSelection)
end)

ui.list:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutCells)

TabController.AddOpenListener(function(name)
	if name == TAB_NAME then
		state.confirmUntil = 0
		task.defer(rebuild)
	end
end)
TabController.AddCloseListener(function(name)
	if name == TAB_NAME and not state.selling then
		table.clear(state.selected)
		state.confirmUntil = 0
	end
end)

Save.ConnectForDataChanged({ "Inventory", "EquippedAssets", "EggInventory", "FavoriteAssets", "FusionSlots" }, queueRebuild)

if ui.hint:IsA("TextLabel") then
	ui.hint.Text = "" -- the build bakes "Eggs can't be sold" into it; eggs sell now
end
refreshFooter()
