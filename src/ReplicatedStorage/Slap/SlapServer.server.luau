-- SlapServer
-- Tool "Slap": igual mecanica que Void Slap (Handle.FlingPart welded a la mano
-- detecta por Touched durante el swing) pero MAS FLOJO — manda a volar un poco,
-- no super lejos.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local flingPart = handle:WaitForChild("FlingPart")

local FLING_POWER = 130   -- velocidad horizontal (studs/s) — mas flojo que Void Slap (400)
local UP_BOOST = 90       -- componente vertical — mas flojo que Void Slap (250)
local FORCE_DURATION = 0.25
local SWING_WINDOW = 0.35
local COOLDOWN = 1

local remoteGui = RS:FindFirstChild("RemoteGUI")
local notifyEvent = remoteGui and remoteGui:FindFirstChild("UNotifyEvent")
local function notify(player, title, kind)
	if notifyEvent then
		notifyEvent:FireClient(player, title, 4, kind or "Success")
	end
end

local hitSound = RS:FindFirstChild("Sounds") and RS.Sounds:FindFirstChild("Sound_Hit")
local function playHitSound(atPos)
	if not hitSound then return end
	local s = hitSound:Clone()
	if atPos then
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
		Debris:AddItem(part, 4)
	else
		s.Parent = workspace
	end
	s:Play()
	Debris:AddItem(s, 4)
end

local active = false
local hitThisSwing = {}
local lastUse = 0

tool.Activated:Connect(function()
	local now = os.clock()
	if now - lastUse < COOLDOWN then return end
	lastUse = now
	active = true
	hitThisSwing = {}
	task.delay(SWING_WINDOW, function()
		active = false
	end)
end)

flingPart.Touched:Connect(function(hit)
	if not active then return end

	local owner = tool.Parent and Players:GetPlayerFromCharacter(tool.Parent)
	if not owner then return end

	local char = hit.Parent
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return end

	local victim = Players:GetPlayerFromCharacter(char)
	if victim == owner then return end
	if hitThisSwing[char] then return end
	hitThisSwing[char] = true

	local ownerHrp = tool.Parent:FindFirstChild("HumanoidRootPart")
	local dir = ownerHrp and (hrp.Position - ownerHrp.Position) or Vector3.new(0, 0, 0)
	if dir.Magnitude < 0.5 then
		dir = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	end
	dir = dir.Unit

	local bv = Instance.new("BodyVelocity")
	bv.Name = "SlapFling"
	bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
	bv.Velocity = dir * FLING_POWER + Vector3.new(0, UP_BOOST, 0)
	bv.Parent = hrp
	Debris:AddItem(bv, FORCE_DURATION)

	playHitSound(hrp.Position)
	notify(owner, "Le diste un Slap a " .. (victim and victim.Name or char.Name) .. "!", "Success")
	if victim then
		notify(victim, (owner.Name) .. " te dio un Slap!", "Error")
	end
	print(("[Slap] %s golpeo a %s"):format(owner.Name, char.Name))
end)