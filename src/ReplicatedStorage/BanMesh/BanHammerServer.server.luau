-- BanHammerServer
-- Tool "BanMesh": animacion epica a 2 manos (via tween del Grip: lo levanta
-- atras como preparando el golpe y lo estampa contra el suelo) + efectos
-- (Explosion visual + sonido) + hitbox (el propio Handle/mesh detecta por
-- Touched durante el golpe). Si golpea a un jugador, ese jugador recibe el
-- mismo trato que el "kick" del panel Troll: NO es un ban/kick real del
-- servidor, es un respawn suave (LoadCharacter) — "como si el server se
-- reseteara para el, pero sin sacarlo del juego".

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local WINDUP_TIME = 0.28
local SLAM_TIME = 0.12
local RETURN_TIME = 0.3
local HIT_WINDOW = 0.18   -- ventana activa alrededor del impacto (golpe en area, no 1 solo objetivo)
local COOLDOWN = 1.8

-- Grip por defecto (identity, 1 mano) vs. "2 manos hacia atras" (windup) vs.
-- "estampado hacia abajo" (slam). Los angulos son aproximados: como no hay una
-- Animation real (skeletal), esto simula el swing tweando el Grip del Tool.
local NORMAL_GRIP = CFrame.new()
local WINDUP_GRIP = CFrame.new(0, 1.2, 1.5) * CFrame.Angles(math.rad(130), 0, 0)
local SLAM_GRIP = CFrame.new(0, -1.5, -2) * CFrame.Angles(math.rad(-40), 0, 0)

local remoteGui = RS:FindFirstChild("RemoteGUI")
local notifyEvent = remoteGui and remoteGui:FindFirstChild("UNotifyEvent")
local function notify(player, title, kind)
	if notifyEvent then
		notifyEvent:FireClient(player, title, 4, kind or "Success")
	end
end

local hitSound = RS:FindFirstChild("Sounds") and RS.Sounds:FindFirstChild("Sound_RKO")
local function playImpactFX(atPos)
	-- Explosion visual (BlastPressure=0 -> no mueve nada, solo el efecto +
	-- el camera-shake nativo de Roblox para los jugadores cercanos).
	local ex = Instance.new("Explosion")
	ex.Position = atPos
	ex.BlastRadius = 14
	ex.BlastPressure = 0
	ex.DestroyJointRadiusPercent = 0
	ex.Parent = workspace

	if hitSound then
		local s = hitSound:Clone()
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(1, 1, 1)
		part.Position = atPos
		part.Parent = workspace
		s.Parent = part
		s:Play()
		Debris:AddItem(part, 4)
	end
end

local banHammerParticleTemplate = RS:FindFirstChild("Particles") and RS.Particles:FindFirstChild("BanHammerParticle")
local function spawnBanParticle(atCFrame)
	if not banHammerParticleTemplate then return end
	local clone = banHammerParticleTemplate:Clone()
	clone.Anchored = true
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	clone.CFrame = atCFrame
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			d.Enabled = true
		end
	end
	clone.Parent = workspace
	Debris:AddItem(clone, 5) -- aparece 5s y desaparece
end

local function kickChar(target)
	-- "kick" = reset/respawn suave, NO desconecta (mismo criterio que
	-- TrollActionServer.Kick). LoadCharacter respawnea en su plot via
	-- RespawnLocation (lo fija PlotServer).
	pcall(function() target:LoadCharacter() end)
end

local active = false
local hitThisSwing = {}
local lastUse = 0

local function doSwing()
	local owner = tool.Parent and Players:GetPlayerFromCharacter(tool.Parent)
	if not owner then return end

	-- 1) Windup: lo lleva atras con las 2 manos.
	local windupTween = TweenService:Create(tool, TweenInfo.new(WINDUP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Grip = WINDUP_GRIP })
	windupTween:Play()
	windupTween.Completed:Wait()

	-- 2) Slam: golpe rapido y brutal hacia el suelo.
	local slamTween = TweenService:Create(tool, TweenInfo.new(SLAM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Grip = SLAM_GRIP })
	slamTween:Play()
	slamTween.Completed:Wait()

	-- 3) Impacto: FX + sonido + ventana de hitbox activa (golpe en area).
	active = true
	hitThisSwing = {}
	playImpactFX(handle.Position)
	task.delay(HIT_WINDOW, function()
		active = false
	end)

	-- 4) Vuelve a la posicion normal.
	task.wait(0.05)
	local returnTween = TweenService:Create(tool, TweenInfo.new(RETURN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Grip = NORMAL_GRIP })
	returnTween:Play()
end

tool.Activated:Connect(function()
	local now = os.clock()
	if now - lastUse < COOLDOWN then return end
	lastUse = now
	task.spawn(doSwing)
end)

handle.Touched:Connect(function(hit)
	if not active then return end

	local owner = tool.Parent and Players:GetPlayerFromCharacter(tool.Parent)
	if not owner then return end

	local char = hit.Parent
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum then return end

	local victim = Players:GetPlayerFromCharacter(char)
	if not victim or victim == owner then return end
	if hitThisSwing[char] then return end
	hitThisSwing[char] = true

	-- "justo donde has dado": capturar la posicion ANTES de LoadCharacter
	-- (destruye el char viejo al instante).
	if hrp then
		spawnBanParticle(hrp.CFrame)
	end
	kickChar(victim)
	notify(owner, "Le diste con el martillo a " .. victim.Name .. "!", "Success")
	notify(victim, owner.Name .. " te reseteo con el BanHammer!", "Error")
	print(("[BanHammer] %s golpeo a %s"):format(owner.Name, char.Name))
end)