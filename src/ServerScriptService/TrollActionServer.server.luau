local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local FXsFolder = ReplicatedStorage:FindFirstChild("FXs")
local function emitStars(cframe)
	local template = FXsFolder and FXsFolder:FindFirstChild("Box_Star")
	if not (template and template:IsA("BasePart")) then return end
	local fx = template:Clone()
	fx.Anchored = true
	fx.CanCollide = false
	fx.CanTouch = false
	fx.CanQuery = false
	fx.Transparency = 1
	fx.CFrame = cframe
	fx.Parent = workspace
	for _, d in ipairs(fx:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			d.Enabled = true
			d:Emit(d:GetAttribute("EmitCount") or 15)
		end
	end
	Debris:AddItem(fx, 2)
end

local events = ReplicatedStorage:WaitForChild("Events")
local setTrollTarget = events:FindFirstChild("SetTrollTarget")
if not setTrollTarget then
	setTrollTarget = Instance.new("RemoteEvent")
	setTrollTarget.Name = "SetTrollTarget"
	setTrollTarget.Parent = events
end

local runTrollAction = ServerStorage:FindFirstChild("RunTrollAction")
if not runTrollAction then
	runTrollAction = Instance.new("BindableEvent")
	runTrollAction.Name = "RunTrollAction"
	runTrollAction.Parent = ServerStorage
end

local remoteGui = ReplicatedStorage:FindFirstChild("RemoteGUI")
local notifyEvent = remoteGui and remoteGui:FindFirstChild("UNotifyEvent")
local function notify(player, message, kind)
	if notifyEvent then
		notifyEvent:FireClient(player, message, 4, kind or "Success")
	end
end

local trollTargets = {}
setTrollTarget.OnServerEvent:Connect(function(player, targetPlayer)
	if typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") and targetPlayer ~= player and targetPlayer.Parent == Players then
		trollTargets[player.UserId] = targetPlayer
	else
		trollTargets[player.UserId] = nil
	end
end)

Players.PlayerRemoving:Connect(function(player)
	trollTargets[player.UserId] = nil
	for buyerId, target in pairs(trollTargets) do
		if target == player then trollTargets[buyerId] = nil end
	end
end)

local function forceRespawnIfStuck(target, deadCharacter)
	task.spawn(function()
		for _, delaySeconds in ipairs({0.5, 2, 5}) do
			task.wait(delaySeconds)
			if not (target.Parent and target.Character == deadCharacter) then return end
			pcall(function() target:LoadCharacter() end)
			if target.Parent and target.Character ~= deadCharacter then return end
		end
	end)
end

local function killCharacter(target)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.Health = 0 end
	if character then forceRespawnIfStuck(target, character) end
end

local function flingCharacter(target)
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local direction = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	if direction.Magnitude < 0.1 then direction = Vector3.new(1, 0, 0) end
	local velocity = Instance.new("BodyVelocity")
	velocity.Name = "TrollFling"
	velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	velocity.Velocity = direction.Unit * 350 + Vector3.new(0, 300, 0)
	velocity.Parent = root
	Debris:AddItem(velocity, 0.3)
	task.delay(5, function()
		if target.Parent and target.Character == character then killCharacter(target) end
	end)
end

local function explodeCharacter(target)
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local explosion = Instance.new("Explosion")
	explosion.Position = root.Position
	explosion.BlastRadius = 8
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	killCharacter(target)
end

local function freezeCharacter(target)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and humanoid and root) or character:GetAttribute("_Frozen") then return end
	character:SetAttribute("_Frozen", true)
	local oldWalkSpeed, oldJumpPower, oldJumpHeight, oldAutoRotate = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate
	humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate = 0, 0, 0, false
	local _, size = character:GetBoundingBox()
	local ice = Instance.new("Part")
	ice.Name = "TrollFreezeBlock"
	ice.Material = Enum.Material.Ice
	ice.Color = Color3.fromRGB(150, 220, 255)
	ice.Transparency = 0.25
	ice.Anchored = true
	ice.CanCollide = false
	ice.CanQuery = false
	ice.CanTouch = false
	ice.Size = size + Vector3.new(1, 1, 1)
	ice.CFrame = character:GetPivot()
	ice.Parent = workspace
	local connection = root:GetPropertyChangedSignal("CFrame"):Connect(function()
		if ice.Parent then ice.CFrame = character:GetPivot() end
	end)
	task.delay(8, function()
		connection:Disconnect()
		ice:Destroy()
		if character.Parent and humanoid.Parent then
			humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate = oldWalkSpeed, oldJumpPower, oldJumpHeight, oldAutoRotate
			character:SetAttribute("_Frozen", nil)
		end
	end)
end

local function tripCharacter(target)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and humanoid and root) or character:GetAttribute("_Tripped") then return end
	character:SetAttribute("_Tripped", true)
	humanoid.PlatformStand = true
	emitStars(root.CFrame)
	task.delay(1.5, function()
		if humanoid.Parent then humanoid.PlatformStand = false end
		if character.Parent then character:SetAttribute("_Tripped", nil) end
	end)
end

local actions = {Fling = flingCharacter, Explode = explodeCharacter, Freeze = freezeCharacter, Trip = tripCharacter, Kill = killCharacter, Kick = function(target) pcall(function() target:LoadCharacter() end) end}

local function dispatchTrollAction(buyer, actionName)
	if typeof(actionName) ~= "string" then return end
	local isAll = actionName:sub(-3) == "All"
	local base = isAll and actionName:sub(1, -4) or actionName
	local action = actions[base]
	if not action then warn("[TrollActionServer] Unknown action: " .. actionName) return end
	if isAll then
		local count = 0
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= buyer then action(player) count += 1 end
		end
		notify(buyer, base .. " applied to " .. count .. " players!", "Success")
	else
		local target = trollTargets[buyer.UserId]
		if not (target and target.Parent == Players) then notify(buyer, "Select a player first!", "Error") return end
		action(target)
		notify(buyer, base .. " applied to " .. target.Name .. "!", "Success")
		notify(target, buyer.Name .. " used " .. base .. " on you!", "Error")
	end
end

runTrollAction.Event:Connect(dispatchTrollAction)

local freeTrollAction = events:FindFirstChild("FreeTrollAction")
if not freeTrollAction then
	freeTrollAction = Instance.new("RemoteEvent")
	freeTrollAction.Name = "FreeTrollAction"
	freeTrollAction.Parent = events
end

local freePlayerName = "thehalconyt1"
freeTrollAction.OnServerEvent:Connect(function(player, actionName)
	if player.Name == freePlayerName and player:GetAttribute("TrollFree") then dispatchTrollAction(player, actionName) end
end)