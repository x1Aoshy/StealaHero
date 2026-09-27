-- StarterPlayerScripts.GUI.SecretHeroAnnouncer (injected by scripts/inject/secretannounce.luau)
-- Owner 2026-09-26: "when the current secret and more secrets to come [spawn] the global messages says [Server] A
-- SECRET HERO, JOYBOY HAS SPAWNED IN ONE PIECE! in chat and on your screen".
-- The server (Controllers.AreaEggService.announceSecretSpawn) fires Network["Eggs: SecretHeroSpawned"] to every client
-- the moment an egg of Secret rarity or better spawns in a stage nest. Per announcement this client:
--   1. posts a cyan bold system line in the chat: [SERVER] A SECRET HERO, <HERO> HAS SPAWNED IN <STAGE>!
--   2. drops a gold/cyan glowing banner from the top of the screen for BANNER_SECONDS (studded glossy band in the Free
--      Gift / Sell window style, rotating rays glow, the hero's costume egg spinning in a viewport), with a fanfare
--      (Library.Audio whitelisted "winner!" sound).
-- Announcements queue (one banner at a time) and each egg is announced once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local BANNER_SECONDS = 6
local CHAT_COLOR = "#00FFCC"
local FANFARE_ID = 127039883737564 -- Library.Audio whitelist: Speedsters "winner!"
local STUD_IMAGE = "rbxassetid://6927295847" -- the UI kit's stud tile (Kit.Images.stud)
local RAYS_IMAGE = "rbxassetid://72314714453458" -- the UI kit's shine rays (Kit.Images.shine)
local INK = Color3.fromRGB(11, 27, 45)
local GOLD = Color3.fromRGB(255, 205, 58)
local CYAN = Color3.fromRGB(0, 255, 204)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Audio = nil
do
	local ok, result = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Audio"))
	end)
	if ok then
		Audio = result
	end
end

local network = ReplicatedStorage:WaitForChild("Network")
local remote = network:WaitForChild("Eggs: SecretHeroSpawned", 60)
if remote == nil or not remote:IsA("RemoteEvent") then
	warn("[SecretHeroAnnouncer] Network['Eggs: SecretHeroSpawned'] missing: secret spawn announcements disabled")
	return
end

local function escapeRichText(text: string): string
	return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

local function postChatLine(message: string)
	local line = string.format("<font color='%s'><b>[SERVER] %s</b></font>", CHAT_COLOR, escapeRichText(message))
	local ok, err = pcall(function()
		if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			local channels = TextChatService:FindFirstChild("TextChannels")
			local channel = (channels and (channels:FindFirstChild("RBXSystem") or channels:FindFirstChild("RBXGeneral")))
				or TextChatService:FindFirstChild("GameSystem")
			if channel and channel:IsA("TextChannel") then
				channel:DisplaySystemMessage(line)
			end
		else
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = "[SERVER] " .. message,
				Color = CYAN,
				Font = Enum.Font.FredokaOne,
				FontSize = Enum.FontSize.Size18,
			})
		end
	end)
	if not ok then
		warn("[SecretHeroAnnouncer] chat line failed: " .. tostring(err))
	end
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(parent: Instance, color: Color3, thickness: number, mode: Enum.ApplyStrokeMode?)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
end

local function label(parent: Instance, name: string, text: string, color: Color3, size: UDim2, position: UDim2)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Font = Enum.Font.FredokaOne
	l.Text = text
	l.TextColor3 = color
	l.TextScaled = true
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 6
	stroke(l, INK, 2.5, Enum.ApplyStrokeMode.Contextual)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 40
	limit.Parent = l
	l.Parent = parent
	return l
end

-- The hero's costume egg (ReplicatedStorage.Assets.Models.Eggs.<HeroId>) spinning in a ViewportFrame.
local function eggViewport(parent: Instance, heroId: string)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "EggViewport"
	viewport.BackgroundTransparency = 1
	viewport.SizeConstraint = Enum.SizeConstraint.RelativeYY
	viewport.Position = UDim2.new(0, 6, 0.5, 0)
	viewport.AnchorPoint = Vector2.new(0, 0.5)
	viewport.Size = UDim2.new(1.25, 0, 1.25, 0)
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.ZIndex = 5
	viewport.Parent = parent
	local template = nil
	pcall(function()
		template = ReplicatedStorage.Assets.Models.Eggs:FindFirstChild(heroId)
			or ReplicatedStorage.Assets.Models:FindFirstChild("BossEggs") and ReplicatedStorage.Assets.Models.BossEggs:FindFirstChild(heroId)
	end)
	if not (template and template:IsA("Model")) then
		return nil
	end
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local egg = template:Clone()
	egg.Parent = world
	local cf, size = egg:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local distance = math.max(size.X, size.Y, size.Z) / (2 * math.tan(math.rad(15))) * 1.15
	camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.08, -distance), cf.Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local pivot = egg:GetPivot()
	local centre = cf.Position
	local angle = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not viewport.Parent then
			connection:Disconnect()
			return
		end
		angle += dt * 1.6
		local spin = CFrame.new(centre) * CFrame.Angles(0, angle, 0) * CFrame.new(-centre)
		egg:PivotTo(spin * pivot)
	end)
	return viewport
end

local function buildBanner(data)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SecretHeroBanner"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, -170)
	holder.Size = UDim2.new(0.62, 0, 0, 104)
	holder.BackgroundTransparency = 1
	holder.Parent = gui
	local limits = Instance.new("UISizeConstraint")
	limits.MaxSize = Vector2.new(760, 104)
	limits.MinSize = Vector2.new(300, 84)
	limits.Parent = holder

	-- glow: rotating rays behind the band
	local rays = Instance.new("ImageLabel")
	rays.Name = "Rays"
	rays.BackgroundTransparency = 1
	rays.Image = RAYS_IMAGE
	rays.ImageColor3 = CYAN
	rays.ImageTransparency = 0.35
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.new(0.5, 0, 0.5, 0)
	rays.Size = UDim2.new(1.35, 0, 3.2, 0)
	rays.ZIndex = 1
	rays.Parent = holder

	local band = Instance.new("Frame")
	band.Name = "Band"
	band.Size = UDim2.new(1, 0, 1, 0)
	band.BackgroundColor3 = Color3.new(1, 1, 1)
	band.ZIndex = 2
	band.Parent = holder
	corner(band, 16)
	local bandStroke = stroke(band, INK, 4)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GOLD),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 236, 140)),
		ColorSequenceKeypoint.new(0.55, CYAN),
		ColorSequenceKeypoint.new(1, GOLD),
	})
	gradient.Rotation = 12
	gradient.Parent = band

	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.BackgroundTransparency = 1
	studs.Image = STUD_IMAGE
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(20, 20)
	studs.ImageTransparency = 0.8
	studs.Size = UDim2.new(1, 0, 1, 0)
	studs.ZIndex = 3
	studs.Parent = band
	corner(studs, 16)

	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.72
	gloss.BorderSizePixel = 0
	gloss.Size = UDim2.new(1, -12, 0.42, 0)
	gloss.Position = UDim2.new(0, 6, 0, 5)
	gloss.ZIndex = 4
	gloss.Parent = band
	corner(gloss, 12)
	local glossFade = Instance.new("UIGradient")
	glossFade.Rotation = 90
	glossFade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	glossFade.Parent = gloss

	-- the egg viewport is 1.25x the band height (it pokes out of the band); the text starts right of it
	local viewport = eggViewport(band, tostring(data.HeroId))
	local textLeft = if viewport then 142 else 20

	label(band, "Title", "SECRET HERO SPAWNED!", Color3.new(1, 1, 1), UDim2.new(1, -textLeft - 16, 0.44, 0),
		UDim2.new(0, textLeft, 0.1, 0))
	local message = string.format("%s has spawned in %s!", tostring(data.HeroName or data.HeroId),
		tostring(data.StageName or data.AreaId or "a stage"))
	local sub = label(band, "Message", message, Color3.fromRGB(12, 44, 70), UDim2.new(1, -textLeft - 16, 0.34, 0),
		UDim2.new(0, textLeft, 0.56, 0))
	local subStroke = sub:FindFirstChildOfClass("UIStroke")
	if subStroke then
		subStroke.Color = Color3.new(1, 1, 1)
		subStroke.Thickness = 1.5
	end

	gui.Parent = playerGui
	return gui, holder, band, rays, gradient, bandStroke
end

local queue = {}
local announced = {}
local busy = false

local function play(data)
	local gui, holder, band, rays, gradient, bandStroke = buildBanner(data)
	if Audio then
		pcall(Audio.Play, FANFARE_ID, script, 1.0, 0.9)
	end
	local alive = true
	-- shimmer: the gold/cyan gradient sweeps, the rays turn, the ink rim pulses cyan
	task.spawn(function()
		local t = 0
		while alive and gui.Parent do
			local dt = RunService.RenderStepped:Wait()
			t += dt
			gradient.Offset = Vector2.new(math.sin(t * 2.2) * 0.35, 0)
			rays.Rotation = (rays.Rotation + dt * 40) % 360
			local pulse = (math.sin(t * 6) + 1) / 2
			bandStroke.Color = INK:Lerp(CYAN, pulse * 0.55)
			band.Rotation = math.sin(t * 3) * 0.6
		end
	end)
	local dropIn = TweenService:Create(holder, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 58) })
	dropIn:Play()
	task.wait(BANNER_SECONDS)
	local leave = TweenService:Create(holder, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 0, -170) })
	leave:Play()
	leave.Completed:Wait()
	alive = false
	gui:Destroy()
end

local function pump()
	if busy then
		return
	end
	busy = true
	while #queue > 0 do
		local data = table.remove(queue, 1)
		local ok, err = pcall(play, data)
		if not ok then
			warn("[SecretHeroAnnouncer] banner failed: " .. tostring(err))
		end
	end
	busy = false
end

remote.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	local key = tostring(data.EggUid or "")
	if key ~= "" then
		if announced[key] then
			return
		end
		announced[key] = true
	end
	local message = type(data.Message) == "string" and data.Message
		or string.format("A SECRET HERO, %s HAS SPAWNED IN %s!", string.upper(tostring(data.HeroName or data.HeroId)),
			string.upper(tostring(data.StageName or "")))
	postChatLine(message)
	table.insert(queue, data)
	task.spawn(pump)
end)
