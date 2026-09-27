-- StarterPlayerScripts.Game.HeroPark (HUB LAYOUT pass 2026-09-26, injected by scripts/inject/heropark.luau)
-- The Hero Park in the south of the hub (Workspace.Hub.HeroPark, built by scripts/steps/post_hub_zlayout.luau):
--   * Hero Fountain: its "Toss a Coin" prompt (Fountain.CoinPrompt) throws a gold coin (a local part) in an arc into
--     the pool, bursts the splash emitters of Fountain.SplashPoint (CoinSplash / CoinRing / CoinSparkle), plays the
--     whitelisted pop through Library.Audio and shows a fun top notification. 3 s cooldown (the prompt hides meanwhile).
--   * Statues: each Statues.Statue_<HeroId>.InfoPrompt ("View Hero") opens the Hall of Heroes card
--     (PlayerGui.HeroParkCard, built by scripts/steps/ui_85_hero_park.luau in the Free Gift / Sell Heroes window style):
--     live portrait (Library.Client.HeroPortrait), name, stage, rarity and a line about the hero. It closes with the X,
--     the AWESOME! button or by walking away from the statue.
--   * Champions' garden: Garden.TrophyPrompt ("Admire") sparkles the trophy's star and cheers.
-- The place streams (Workspace.StreamingEnabled): the park's parts arrive when the player comes near, so nothing is
-- waited for up front. One ProximityPromptService.PromptTriggered listener routes every park prompt by its host's name
-- and every piece (splash point, trophy star, card) is looked up when it is needed.
-- Purely cosmetic and local: no remote, no currency, no save data. Every optional piece degrades quietly.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WAIT_SECONDS = 30
local PARK_NAME = "HeroPark"
local COIN_COOLDOWN = 3
local TROPHY_COOLDOWN = 4
local CARD_CLOSE_DISTANCE = 22
local POP_SOUND = 72264591133889 -- Library.Audio whitelist: UI_POP
local SUCCESS_SOUND = 136993031050456 -- Library.Audio whitelist: SUCCESS

local LocalPlayer = Players.LocalPlayer

local function optionalModule(getter)
	local ok, result = pcall(getter)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

local Library = ReplicatedStorage:WaitForChild("Library", WAIT_SECONDS)
local LibraryClient = Library and Library:WaitForChild("Client", WAIT_SECONDS)
local Audio = Library and optionalModule(function()
	return require(Library:WaitForChild("Audio", WAIT_SECONDS))
end)
local NotificationCmds = LibraryClient and optionalModule(function()
	return require(LibraryClient:WaitForChild("NotificationCmds", WAIT_SECONDS))
end)
local HeroPortrait = LibraryClient and optionalModule(function()
	return require(LibraryClient:WaitForChild("HeroPortrait", 10))
end)
local HeroCatalog = optionalModule(function()
	return require(ReplicatedStorage:WaitForChild("Directory", WAIT_SECONDS):WaitForChild("HeroCatalog", WAIT_SECONDS))
end)

local function playSound(id, target, speed, volume)
	if Audio == nil or typeof(target) ~= "Instance" then
		return
	end
	pcall(Audio.Play, id, target, speed or 1, volume or 1)
end

local function notify(message, color)
	if NotificationCmds == nil or NotificationCmds.Message == nil then
		return
	end
	pcall(NotificationCmds.Message.Top, {
		Message = message,
		Time = 3.5,
		Color = color or Color3.fromRGB(255, 226, 90),
	})
end

local function rootPart()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function emit(parent, name, count)
	local emitter = parent and parent:FindFirstChild(name)
	if emitter and emitter:IsA("ParticleEmitter") then
		emitter:Emit(count)
	end
end

local random = Random.new()
local function pick(list)
	return list[random:NextInteger(1, #list)]
end

---------------------------------------------------------------------------------------------------
-- Hero Fountain: toss a coin
---------------------------------------------------------------------------------------------------

local COIN_WISHES = {
	"Splash! Iron Man gives your wish a thumbs up.",
	"Plop! All Might shouts: PLUS ULTRA!",
	"Your coin sparkles... Goku senses your power rising!",
	"Luffy grins: \"I'm gonna be King of the Heroes!\"",
	"Superman nods. Your wish is safe with the Justice League.",
	"Venom says: \"WE like shiny coins.\"",
	"A perfect toss! The fountain glows for you.",
	"Wish made! May your next egg hatch something legendary.",
}

local function flyCoin(from, to, onLanded)
	local coin = Instance.new("Part")
	coin.Name = "HeroParkCoin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.16, 0.9, 0.9)
	coin.Color = Color3.fromRGB(255, 194, 26)
	coin.Material = Enum.Material.SmoothPlastic
	coin.Reflectance = 0.2
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanQuery = false
	coin.CanTouch = false
	coin.CastShadow = false
	coin.CFrame = CFrame.new(from)
	coin.Parent = Workspace:FindFirstChild("__DEBRIS") or Workspace
	local lift = 5 -- arc apex over the straight line from the hand to the water
	local progress = Instance.new("NumberValue")
	progress.Value = 0
	local connection = progress.Changed:Connect(function(t)
		local flat = from:Lerp(to, t)
		local height = from.Y + (to.Y - from.Y) * t + lift * 4 * t * (1 - t)
		coin.CFrame = CFrame.new(flat.X, height, flat.Z) * CFrame.Angles(t * 18, 0, t * 5)
	end)
	local tween = TweenService:Create(progress, TweenInfo.new(0.7, Enum.EasingStyle.Linear), { Value = 1 })
	tween.Completed:Connect(function()
		connection:Disconnect()
		progress:Destroy()
		coin:Destroy()
		onLanded()
	end)
	tween:Play()
end

local lastToss = -math.huge
local function tossCoin(prompt, host)
	local now = os.clock()
	if now - lastToss < COIN_COOLDOWN then
		return
	end
	lastToss = now
	prompt.Enabled = false -- (local only: the prompt hides for this player during the cooldown)
	task.delay(COIN_COOLDOWN, function()
		prompt.Enabled = true
	end)
	local fountain = host.Parent
	local splashPoint = fountain and fountain:FindFirstChild("SplashPoint")
	local target = if splashPoint and splashPoint:IsA("BasePart") then splashPoint.Position else host.Position
	local root = rootPart()
	local from = if root then root.Position + Vector3.new(0, 1.5, 0) else target + Vector3.new(0, 6, 0)
	flyCoin(from, target, function()
		if splashPoint and splashPoint.Parent then
			emit(splashPoint, "CoinSplash", 26)
			emit(splashPoint, "CoinRing", 2)
			emit(splashPoint, "CoinSparkle", 14)
			playSound(POP_SOUND, splashPoint, 1 + random:NextNumber(0, 0.25), 0.9)
		end
	end)
	task.delay(0.55, function()
		notify(pick(COIN_WISHES))
	end)
end

---------------------------------------------------------------------------------------------------
-- Statues: the Hall of Heroes card
---------------------------------------------------------------------------------------------------

-- Display text per statue (the catalog supplies the stage, the rarity and its colour when available).
local HEROES = {
	IronMan = { Name = "IRON MAN", Stage = 1, Team = "THE AVENGERS", Bio = "Genius inventor in a flying suit of armor. Catch him in Stage 1!" },
	Superman = { Name = "SUPERMAN", Stage = 2, Team = "JUSTICE LEAGUE", Bio = "Faster than a speeding bullet. The pride of Stage 2!" },
	Venom = { Name = "VENOM", Stage = 3, Team = "SPIDER-VERSE", Bio = "A hungry symbiote anti-hero lurking in Stage 3." },
	AllMight = { Name = "ALL MIGHT", Stage = 4, Team = "MY HERO ACADEMIA", Bio = "The Symbol of Peace! Go beyond in Stage 4." },
	Goku = { Name = "GOKU", Stage = 5, Team = "DRAGON BALL", Bio = "A Saiyan who never stops training. Find him in Stage 5." },
	Luffy = { Name = "LUFFY", Stage = 6, Team = "ONE PIECE", Bio = "The rubber pirate who will be King. Sail to Stage 6!" },
}
local MYTHIC_COLOR = Color3.fromRGB(255, 40, 80)

local function catalogEntry(heroId)
	if HeroCatalog == nil or type(HeroCatalog.List) ~= "table" then
		return nil
	end
	for _, entry in ipairs(HeroCatalog.List) do
		if entry.Id == heroId then
			return entry
		end
	end
	return nil
end

local function heroFacts(heroId)
	local facts = HEROES[heroId] or { Name = string.upper(heroId), Stage = 1, Team = "", Bio = "" }
	local entry = catalogEntry(heroId)
	local stageNumber = (entry and entry.Stage) or facts.Stage
	local team = facts.Team
	if HeroCatalog and type(HeroCatalog.Stages) == "table" and HeroCatalog.Stages[stageNumber] then
		team = string.upper(HeroCatalog.Stages[stageNumber].Name or team)
	end
	local rarity = (entry and entry.Rarity) or "Mythic"
	local rarityColor = MYTHIC_COLOR
	if HeroCatalog and type(HeroCatalog.Rarities) == "table" and HeroCatalog.Rarities[rarity] then
		rarityColor = HeroCatalog.Rarities[rarity].Color or rarityColor
	end
	return {
		name = facts.Name,
		stage = string.format("STAGE %d  \u{2022}  %s", stageNumber, team),
		rarity = string.upper(rarity),
		rarityColor = rarityColor,
		bio = facts.Bio,
	}
end

local card = nil -- PlayerGui.HeroParkCard.Card, found on first use
local cardScale = nil
local openStatue = nil -- the prompt host the open card belongs to
local closing = false

local function closeCard()
	if card == nil or not card.Visible or closing then
		return
	end
	closing = true
	openStatue = nil
	local tween = TweenService:Create(cardScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 })
	tween.Completed:Connect(function()
		card.Visible = false
		cardScale.Scale = 1
		closing = false
	end)
	tween:Play()
end

local function findCard()
	if card and card.Parent then
		return card
	end
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild("HeroParkCard")
	local found = gui and gui:FindFirstChild("Card")
	if found == nil or not found:IsA("GuiObject") then
		return nil
	end
	card = found
	cardScale = card:FindFirstChild("HeroParkPop") or Instance.new("UIScale")
	cardScale.Name = "HeroParkPop"
	cardScale.Scale = 1
	cardScale.Parent = card
	for _, name in ipairs({ "Close", "OkButton" }) do
		local button = card:FindFirstChild(name)
		if button and button:IsA("GuiButton") then
			button.Activated:Connect(closeCard)
		end
	end
	return card
end

local function setText(name, text)
	local label = card and card:FindFirstChild(name)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function openCard(heroId, host)
	if findCard() == nil then
		return
	end
	local facts = heroFacts(heroId)
	setText("HeroName", facts.name)
	setText("Stage", facts.stage)
	setText("Bio", facts.bio)
	local pill = card:FindFirstChild("Rarity")
	if pill and pill:IsA("GuiObject") then
		pill.BackgroundColor3 = facts.rarityColor
		local label = pill:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Text = facts.rarity
		end
	end
	local holder = card:FindFirstChild("Portrait")
	if HeroPortrait and holder and holder:IsA("GuiObject") then
		pcall(HeroPortrait.Mount, holder, heroId, { Framing = "Bust", ZIndex = holder.ZIndex + 1 })
	end
	openStatue = host
	closing = false
	local reopening = card.Visible
	card.Visible = true
	if not reopening then
		cardScale.Scale = 0.6
		TweenService:Create(cardScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	playSound(POP_SOUND, host, 1.1, 0.8)
end

-- walking away from the statue closes the card (checked a few times a second while it is open)
task.spawn(function()
	while true do
		task.wait(0.4)
		if openStatue and card and card.Visible then
			local root = rootPart()
			if root == nil or openStatue.Parent == nil or (root.Position - openStatue.Position).Magnitude > CARD_CLOSE_DISTANCE then
				closeCard()
			end
		end
	end
end)

local function viewStatue(host)
	local statue = host.Parent
	local heroId = host:GetAttribute("HeroId") or (statue and statue:GetAttribute("StatueOf"))
	if type(heroId) ~= "string" then
		return
	end
	if openStatue == host and card and card.Visible then
		closeCard()
	else
		openCard(heroId, host)
	end
end

---------------------------------------------------------------------------------------------------
-- Champions' garden: admire the trophy
---------------------------------------------------------------------------------------------------

local CHEERS = {
	"CHAMPION! Keep collecting heroes!",
	"The trophy shines... one day your name goes on it!",
	"Heroes never give up. Neither do you!",
	"You feel the power of every champion before you!",
}

local lastCheer = -math.huge
local function admireTrophy(host)
	local now = os.clock()
	if now - lastCheer < TROPHY_COOLDOWN then
		return
	end
	lastCheer = now
	local garden = host.Parent
	emit(garden and garden:FindFirstChild("Star"), "Sparkles", 18)
	playSound(SUCCESS_SOUND, host, 1, 0.7)
	notify(pick(CHEERS), Color3.fromRGB(255, 214, 64))
end

---------------------------------------------------------------------------------------------------
-- one listener for every park prompt
---------------------------------------------------------------------------------------------------

local ROUTES = {
	CoinPrompt = function(prompt, host)
		tossCoin(prompt, host)
	end,
	InfoPrompt = function(_, host)
		viewStatue(host)
	end,
	TrophyPrompt = function(_, host)
		admireTrophy(host)
	end,
}

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if player ~= LocalPlayer then
		return
	end
	local host = prompt.Parent
	local route = host and ROUTES[host.Name]
	if route and host:IsA("BasePart") and prompt:FindFirstAncestor(PARK_NAME) ~= nil then
		route(prompt, host)
	end
end)
