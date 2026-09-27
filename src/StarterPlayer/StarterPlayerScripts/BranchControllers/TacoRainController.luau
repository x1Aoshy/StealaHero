-- StarterPlayer.StarterPlayerScripts.BranchControllers.TacoRainController (Branch controller; injected by
-- scripts/inject/admin_panel.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27: "migrate the taco event to the admin panel: a rain of tacos ... the taco explosion VFX and the taco
-- particle emitter, with the taco music too". The client of ServerScriptService.BranchServices.TacoRainService. Assets:
-- ReplicatedStorage.Assets.VFX.TacoRain.{Taco, StruckVFX, TacoAmbient} (Steal a Brainrot's Raining Tacos event,
-- scripts/steps/post_taco_rain.luau) and the one music Sound SoundService.TacoRainMusic.
--   * while Workspace.TacoRainUntil is in the future (the server's clock) the rain blends in over BLEND_SECONDS and out
--     again at the end: a warm tint (a ColorCorrectionEffect of its own), TacoAmbient's sky of tacos and flakes over the
--     local player, decorative 3D tacos falling around them that burst into StruckVFX where they land, and the music
--     (faded in / out, the game's own music ducked while it plays; if Roblox refuses the audio the Sound just stays
--     silent and nothing is ducked).
--   * Network["TacoRain: Event"]: "Drop" drops a big taco from the sky onto the aimed egg in FallTime seconds (a StruckVFX
--     burst where it lands); "Hit" shows the floating "x3 TACO!" there and puts the Taco particles on the egg's model at
--     once (Library.Client.Eggs.EggRenderer.ApplyMutationParticles; later renders of that egg add them by themselves);
--     "Stop" ends the rain here even before the attribute replicates.
--   * light: the decorative tacos come from a small pool (at most DECOR_MAX in the air), nothing runs while there is no
--     rain, and on a phone / a low graphics level (PlayerGui.UiDeviceProfile, the saved quality level) the sky emits
--     LOW_POWER_RATE of its rate, fewer decorative tacos fall and only half of their landings burst.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local TacoRainController = {}

TacoRainController.REMOTE_NAME = "TacoRain: Event"
TacoRainController.UNTIL_ATTRIBUTE = "TacoRainUntil"
TacoRainController.BLEND_SECONDS = 1.5
TacoRainController.AMBIENT_HEIGHT = 42 -- studs over the player: the sky plane
TacoRainController.LOW_POWER_RATE = 0.35
TacoRainController.DECOR_INTERVAL = 0.22
TacoRainController.DECOR_INTERVAL_LOW = 0.4
TacoRainController.DECOR_MAX = 16
TacoRainController.DECOR_MAX_LOW = 7
TacoRainController.DECOR_RADIUS = { 5, 44 }
TacoRainController.DECOR_HEIGHT = 50
TacoRainController.DECOR_SPEED = { 52, 72 }
TacoRainController.DECOR_SCALE = 1.7 -- x the taco mesh's size
TacoRainController.DROP_SCALE = 2.4
TacoRainController.DROP_HEIGHT = 70
TacoRainController.BURSTS = 6 -- pooled StruckVFX copies
TacoRainController.MUSIC_VOLUME = 0.55
TacoRainController.DUCK = 0.15 -- the game's music volume while the taco song plays
TacoRainController.TINT = Color3.fromRGB(255, 226, 172)
TacoRainController.SATURATION = 0.22
TacoRainController.CONTRAST = 0.06
TacoRainController.HIT_LABEL = "x3 TACO!"

local player = Players.LocalPlayer
local assets = nil -- ReplicatedStorage.Assets.VFX.TacoRain
local eggRenderer = nil
local meshFailed = false

local weight = 0
local state = nil -- the running rain's instances, nil when none
local heartbeat = nil
local stoppedLocally = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

local function serverNow()
	return Workspace:GetServerTimeNow()
end

local function rainOn()
	if stoppedLocally then
		return false
	end
	local untilAt = Workspace:GetAttribute(TacoRainController.UNTIL_ATTRIBUTE)
	return type(untilAt) == "number" and untilAt > serverNow()
end

local function lowPower()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if gui and gui:GetAttribute("UiDeviceProfile") == "phone" then
		return true
	end
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	return ok and level ~= Enum.SavedQualitySetting.Automatic and level.Value <= 3
end

local function rootPart()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function fxFolder()
	local folder = Workspace:FindFirstChild("TacoRainFx")
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "TacoRainFx"
		folder.Parent = Workspace
	end
	return folder
end

-- The taco made of parts (Speedsters' TacoVisual fallback) when the taco mesh cannot load: shell halves, filling,
-- lettuce and tomato, welded to an invisible anchored root.
local function nativeTaco(root, scale)
	root.Transparency = 1
	local function piece(size, offset, color, shape)
		local part = Instance.new("Part")
		part.Size = size * scale
		part.CFrame = root.CFrame * (CFrame.new(offset.Position * scale) * offset.Rotation)
		part.Color = color
		part.Shape = shape or Enum.PartType.Block
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
		part.Massless = true
		part.Parent = root
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = root, part
		weld.Parent = part
	end
	for _, side in ipairs({ -1, 1 }) do
		for i = -2, 2 do
			local x = i * 0.46
			local height = math.sqrt(1.25 ^ 2 - x ^ 2)
			piece(Vector3.new(0.49, height, 0.16), CFrame.new(x, 0.45 - height / 2, side * 0.38), Color3.fromRGB(245, 181, 49))
		end
	end
	piece(Vector3.new(2.1, 0.45, 0.72), CFrame.new(0, 0.25, 0), Color3.fromRGB(111, 55, 28), Enum.PartType.Ball)
	for i = -1, 1 do
		piece(Vector3.new(0.85, 0.32, 0.86), CFrame.new(i * 0.65, 0.48, 0), Color3.fromRGB(92, 190, 49), Enum.PartType.Ball)
		piece(Vector3.new(0.3, 0.28, 0.32), CFrame.new(i * 0.62, 0.68, 0.08), Color3.fromRGB(240, 66, 43))
	end
end

local function newTaco(scale)
	local template = assets and assets:FindFirstChild("Taco")
	if template and not meshFailed then
		local part = template:Clone()
		part.Size = template.Size * scale
		part.Anchored = true
		part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
		return part
	end
	local root = Instance.new("Part")
	root.Name = "Taco"
	root.Size = Vector3.new(1, 1, 1)
	root.Anchored = true
	root.CanCollide, root.CanQuery, root.CanTouch, root.CastShadow = false, false, false, false
	nativeTaco(root, scale)
	return root
end

local function hide(part)
	part.Parent = nil -- pooled out of the world (spawnDecor puts it back)
end

----------------------------------------------------------------------------------------------------
-- bursts (StruckVFX) and the "x3 TACO!" label
----------------------------------------------------------------------------------------------------

local bursts, nextBurst = {}, 0

local function burst(position, multiplier)
	local template = assets and assets:FindFirstChild("StruckVFX")
	if template == nil then
		return
	end
	nextBurst = nextBurst % TacoRainController.BURSTS + 1
	local holder = bursts[nextBurst]
	if holder == nil or holder.Parent == nil then
		holder = template:Clone()
		holder.Anchored = true
		holder.Transparency = 1
		holder.Parent = fxFolder()
		bursts[nextBurst] = holder
	end
	holder.CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0))
	for _, emitter in ipairs(holder:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			local count = math.clamp(math.floor((tonumber(emitter:GetAttribute("EmitCount")) or 1) * (multiplier or 1) + 0.5), 1, 30)
			local delay = tonumber(emitter:GetAttribute("EmitDelay")) or 0
			if delay > 0 then
				task.delay(delay, emitter.Emit, emitter, count)
			else
				emitter:Emit(count)
			end
		end
	end
end
TacoRainController._burst = burst

local function hitLabel(position)
	local anchor = Instance.new("Part")
	anchor.Name = "TacoHitLabel"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = false, false, false
	anchor.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(7, 2.4)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 160
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = TacoRainController.HIT_LABEL
	label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	label.TextColor3 = Color3.fromRGB(255, 211, 70)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = billboard
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(11, 27, 61)
	stroke.Thickness = 3
	stroke.Parent = label
	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = label
	anchor.Parent = fxFolder()
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(billboard, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = Vector3.new(0, 4, 0) }):Play()
	task.delay(1.2, function()
		local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(label, info, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end)
	task.delay(2, function()
		anchor:Destroy()
	end)
end

-- The Taco particles on the egg's model right away (a stage egg re-renders with them too; a placed egg keeps its model).
local function decorateEgg(payload)
	local model = nil
	if payload.Kind == "Stage" then
		local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
		-- the client's own render, else a workspace model of that uid (Game.AreaEggs.WorkspaceEggVisibility)
		model = (folder and folder:FindFirstChild(tostring(payload.Uid))) or Workspace:FindFirstChild(tostring(payload.Uid))
	elseif payload.Kind == "Plot" then
		local folder = Workspace:FindFirstChild("PlacedEggRenders")
		model = folder and folder:FindFirstChild(tostring(payload.OwnerUserId) .. "_" .. tostring(payload.Uid))
	end
	if model and model:IsA("Model") and eggRenderer and type(eggRenderer.ApplyMutationParticles) == "function" then
		pcall(eggRenderer.ApplyMutationParticles, model, { Mutations = { "Taco" } })
	end
end

----------------------------------------------------------------------------------------------------
-- the rain
----------------------------------------------------------------------------------------------------

local function build()
	local low = lowPower()
	local s = {
		low = low,
		rateScale = if low then TacoRainController.LOW_POWER_RATE else 1,
		decor = {}, -- { part, pos, speed, drift, spin, angles, born }
		pool = {},
		nextDecor = 0,
		emitters = {},
	}
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "TacoRainTint"
	tint.Parent = Lighting
	s.tint = tint
	local ambientTemplate = assets and assets:FindFirstChild("TacoAmbient")
	if ambientTemplate then
		local sky = ambientTemplate:Clone()
		sky.Anchored = true
		sky.Transparency = 1
		sky.CFrame = CFrame.new(0, -10000, 0)
		for _, emitter in ipairs(sky:GetDescendants()) do
			if emitter:IsA("ParticleEmitter") then
				table.insert(s.emitters, { emitter = emitter, rate = tonumber(emitter:GetAttribute("TacoRainRate")) or emitter.Rate })
				emitter.Rate = 0
				emitter.Enabled = true
			end
		end
		sky.Parent = fxFolder()
		s.sky = sky
	end
	local music = SoundService:FindFirstChild("TacoRainMusic")
	if music and music:IsA("Sound") then
		s.music = music
		music.Volume = 0
		pcall(function()
			music:Play()
		end)
	end
	local musicGroup = SoundService:FindFirstChild("Music")
	local gameMusic = musicGroup and musicGroup:FindFirstChild("GameMusic")
	if gameMusic and gameMusic:IsA("SoundGroup") then
		s.gameMusic = gameMusic
		s.gameMusicVolume = gameMusic.Volume
	end
	return s
end

local function teardown()
	if state == nil then
		return
	end
	if state.tint then
		state.tint:Destroy()
	end
	if state.sky then
		state.sky:Destroy()
	end
	if state.music then
		state.music:Stop()
		state.music.Volume = 0
	end
	if state.gameMusic and state.gameMusicVolume then
		state.gameMusic.Volume = state.gameMusicVolume
	end
	for _, taco in ipairs(state.decor) do
		taco.part:Destroy()
	end
	for _, part in ipairs(state.pool) do
		part:Destroy()
	end
	state = nil
end

local function spawnDecor(s, center)
	local limit = if s.low then TacoRainController.DECOR_MAX_LOW else TacoRainController.DECOR_MAX
	if #s.decor >= limit then
		return
	end
	local part = table.remove(s.pool) or newTaco(TacoRainController.DECOR_SCALE)
	if part.Parent == nil then
		part.Parent = fxFolder()
	end
	local angle = math.random() * math.pi * 2
	local radius = TacoRainController.DECOR_RADIUS[1] + math.random() * (TacoRainController.DECOR_RADIUS[2] - TacoRainController.DECOR_RADIUS[1])
	local pos = center + Vector3.new(math.cos(angle) * radius, TacoRainController.DECOR_HEIGHT, math.sin(angle) * radius)
	table.insert(s.decor, {
		part = part,
		pos = pos,
		speed = TacoRainController.DECOR_SPEED[1] + math.random() * (TacoRainController.DECOR_SPEED[2] - TacoRainController.DECOR_SPEED[1]),
		drift = Vector3.new((math.random() - 0.5) * 6, 0, (math.random() - 0.5) * 6),
		spin = Vector3.new(math.random(-3, 3), math.random(-4, 4), math.random(-3, 3)),
		angles = Vector3.new(math.random() * 6, math.random() * 6, math.random() * 6),
		born = os.clock(),
	})
end

local function step(dt)
	local target = if rainOn() then 1 else 0
	weight = math.clamp(weight + (if target > weight then dt else -dt) / TacoRainController.BLEND_SECONDS, 0, 1)
	if state == nil then
		if weight <= 0 then
			return
		end
		state = build()
	end
	local s = state
	local t = weight
	local camera = Workspace.CurrentCamera
	local root = rootPart()
	local center = if root then root.Position elseif camera then camera.CFrame.Position else Vector3.zero

	s.tint.TintColor = Color3.new(1, 1, 1):Lerp(TacoRainController.TINT, t)
	s.tint.Saturation = TacoRainController.SATURATION * t
	s.tint.Contrast = TacoRainController.CONTRAST * t
	if s.sky then
		s.sky.CFrame = CFrame.new(center.X, center.Y + TacoRainController.AMBIENT_HEIGHT, center.Z)
		for _, entry in ipairs(s.emitters) do
			entry.emitter.Rate = entry.rate * s.rateScale * t
		end
	end
	if s.music then
		s.music.Volume = TacoRainController.MUSIC_VOLUME * t
		if s.gameMusic and s.gameMusicVolume and s.music.IsLoaded and s.music.IsPlaying then
			local ducked = s.gameMusicVolume * (1 - (1 - TacoRainController.DUCK) * t)
			s.gameMusic.Volume = ducked
		end
	end

	-- decorative tacos
	local now = os.clock()
	if target == 1 and t > 0.25 and now >= s.nextDecor then
		s.nextDecor = now + (if s.low then TacoRainController.DECOR_INTERVAL_LOW else TacoRainController.DECOR_INTERVAL)
		spawnDecor(s, center)
	end
	local exclude = { fxFolder() }
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Character then
			table.insert(exclude, other.Character)
		end
	end
	rayParams.FilterDescendantsInstances = exclude
	local i = 1
	while i <= #s.decor do
		local taco = s.decor[i]
		local nextPos = taco.pos + Vector3.new(taco.drift.X * dt, -taco.speed * dt, taco.drift.Z * dt)
		local hit = Workspace:Raycast(taco.pos, nextPos - taco.pos, rayParams)
		if hit or now - taco.born > 5 then
			if hit and (not s.low or math.random() < 0.5) then
				burst(hit.Position, 1)
			end
			hide(taco.part)
			table.insert(s.pool, taco.part)
			table.remove(s.decor, i)
		else
			taco.pos = nextPos
			taco.angles += taco.spin * dt
			taco.part.CFrame = CFrame.new(nextPos) * CFrame.Angles(taco.angles.X, taco.angles.Y, taco.angles.Z)
			i += 1
		end
	end

	if weight <= 0 and target == 0 then
		teardown()
		if heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
	end
end

local function ensureRunning()
	if heartbeat == nil and (rainOn() or weight > 0) then
		heartbeat = RunService.Heartbeat:Connect(function(dt)
			local ok, err = pcall(step, dt)
			if not ok then
				warn("[TacoRain] " .. tostring(err))
			end
		end)
	end
end

----------------------------------------------------------------------------------------------------
-- targeted drops
----------------------------------------------------------------------------------------------------

local function drop(payload)
	local target = payload.Position
	if typeof(target) ~= "Vector3" then
		return
	end
	local fallTime = math.clamp(tonumber(payload.FallTime) or 1.7, 0.3, 5)
	local taco = newTaco(TacoRainController.DROP_SCALE)
	local landing = target + Vector3.new(0, 1.2, 0)
	local start = landing + Vector3.new((math.random() - 0.5) * 16, TacoRainController.DROP_HEIGHT, (math.random() - 0.5) * 16)
	taco.CFrame = CFrame.new(start)
	taco.Parent = fxFolder()
	local spin = Vector3.new(math.random(-4, 4), math.random(-5, 5), math.random(-4, 4))
	local began = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local alpha = math.clamp((os.clock() - began) / fallTime, 0, 1)
		local eased = alpha * alpha -- falls faster and faster
		local elapsed = os.clock() - began
		taco.CFrame = CFrame.new(start:Lerp(landing, eased)) * CFrame.Angles(spin.X * elapsed, spin.Y * elapsed, spin.Z * elapsed)
		if alpha >= 1 then
			connection:Disconnect()
			taco:Destroy()
			burst(target, 2)
		end
	end)
end

local function onEvent(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.Action == "Drop" then
		drop(payload)
	elseif payload.Action == "Hit" and typeof(payload.Position) == "Vector3" then
		hitLabel(payload.Position)
		decorateEgg(payload)
	elseif payload.Action == "Stop" then
		stoppedLocally = true
		task.delay(3, function()
			stoppedLocally = false
		end)
	end
end

function TacoRainController:Start()
	task.spawn(function()
		local assetsFolder = ReplicatedStorage:WaitForChild("Assets", 30)
		local vfx = assetsFolder and assetsFolder:WaitForChild("VFX", 30)
		assets = vfx and vfx:WaitForChild("TacoRain", 30)
		local template = assets and assets:FindFirstChild("Taco")
		if template then
			local ok = pcall(function()
				game:GetService("ContentProvider"):PreloadAsync({ template }, function(_, status)
					if status ~= Enum.AssetFetchStatus.Success then
						meshFailed = true
					end
				end)
			end)
			if not ok then
				meshFailed = true
			end
		end
	end)
	task.spawn(function()
		local library = ReplicatedStorage:WaitForChild("Library", 30)
		local client = library and library:WaitForChild("Client", 30)
		local eggs = client and client:WaitForChild("Eggs", 30)
		local module = eggs and eggs:WaitForChild("EggRenderer", 30)
		if module then
			local ok, result = pcall(require, module)
			eggRenderer = if ok and type(result) == "table" then result else nil
		end
	end)
	Workspace:GetAttributeChangedSignal(TacoRainController.UNTIL_ATTRIBUTE):Connect(function()
		if Workspace:GetAttribute(TacoRainController.UNTIL_ATTRIBUTE) ~= nil then
			stoppedLocally = false
		end
		ensureRunning()
	end)
	ensureRunning()
	task.spawn(function()
		local network = ReplicatedStorage:WaitForChild("Network", 30)
		local remote = network and network:WaitForChild(TacoRainController.REMOTE_NAME, 30)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(function(payload)
				local ok, err = pcall(onEvent, payload)
				if not ok then
					warn("[TacoRain] " .. tostring(err))
				end
			end)
		end
	end)
end

-- Test hooks
function TacoRainController.IsRaining()
	return rainOn()
end
TacoRainController._onEvent = onEvent

return TacoRainController
