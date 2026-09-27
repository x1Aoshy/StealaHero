-- ServerScriptService.StageHazardService (docs/STAGES_PLAN.md A8, injected by scripts/inject/stages.luau)
-- Stage hazards: parts under Workspace.StageEnvironments with the attribute StageHazard = "Slow" and a number
-- attribute Factor (0.4-0.8) slow the players standing in them. Villains are NPCs and never affected; the hub
-- (X <= 75) never slows anyone. The slow multiplies the player's current WalkSpeed and is undone through
-- SpeedService.Refresh (the authoritative SpeedPower walk speed) when they step out.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local HUB_MAX_X = 75
local CHECK_INTERVAL = 0.2
local FEET_BELOW = 1 -- studs under a hazard's top that still count as standing in it
local BODY_ABOVE = 7 -- a HumanoidRootPart floats ~3 studs over the floor
local MIN_FACTOR, MAX_FACTOR, DEFAULT_FACTOR = 0.2, 1, 0.6
local LOOKUP_TIMEOUT = 60

local hazards = {} -- BasePart -> factor
local slowed = {} -- Player -> { Humanoid = Humanoid, Base = number, Applied = number }

-- Bootstrap requires SpeedService; it is looked up lazily so this script never runs it first.
local speedService = nil
local function getSpeedService()
	if speedService == nil then
		speedService = false
		local controllers = ServerScriptService:FindFirstChild("Controllers")
		local module = controllers and controllers:FindFirstChild("SpeedService")
		if module then
			local ok, result = pcall(require, module)
			if ok and type(result) == "table" and type(result.Refresh) == "function" then
				speedService = result
			end
		end
	end
	return speedService or nil
end

local function readHazard(instance)
	if not instance:IsA("BasePart") or instance:GetAttribute("StageHazard") ~= "Slow" then
		return nil
	end
	local factor = tonumber(instance:GetAttribute("Factor")) or DEFAULT_FACTOR
	return math.clamp(factor, MIN_FACTOR, MAX_FACTOR)
end

local function track(instance)
	local factor = readHazard(instance)
	if factor then
		hazards[instance] = factor
	end
end

task.spawn(function()
	local root = Workspace:FindFirstChild("StageEnvironments") or Workspace:WaitForChild("StageEnvironments", LOOKUP_TIMEOUT)
	if not root then
		warn("[StageHazardService] Workspace.StageEnvironments not found; no stage hazards.")
		return
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		track(descendant)
	end
	root.DescendantAdded:Connect(track)
	root.DescendantRemoving:Connect(function(descendant)
		hazards[descendant] = nil
	end)
end)

-- True when `position` (a HumanoidRootPart) stands in the hazard. Orientation independent: the env steps lay
-- cylinders on their side (local X = world up) to make round puddles and spills, so the part's local axis
-- closest to world up is taken as its thickness and the other two as its footprint (a circle for a flat
-- cylinder disc or a ball, else a rectangle).
local function standsIn(part, position)
	local cf = part.CFrame
	local relative = cf:PointToObjectSpace(position)
	local half = part.Size * 0.5
	local xUp, yUp, zUp = cf.XVector.Y, cf.YVector.Y, cf.ZVector.Y
	local height, halfHeight, u, halfU, v, halfV
	local axisIsX = false
	if math.abs(xUp) >= math.abs(yUp) and math.abs(xUp) >= math.abs(zUp) then
		height = if xUp < 0 then -relative.X else relative.X
		halfHeight, u, halfU, v, halfV = half.X, relative.Y, half.Y, relative.Z, half.Z
		axisIsX = true
	elseif math.abs(yUp) >= math.abs(zUp) then
		height = if yUp < 0 then -relative.Y else relative.Y
		halfHeight, u, halfU, v, halfV = half.Y, relative.X, half.X, relative.Z, half.Z
	else
		height = if zUp < 0 then -relative.Z else relative.Z
		halfHeight, u, halfU, v, halfV = half.Z, relative.X, half.X, relative.Y, half.Y
	end
	if height < -halfHeight - FEET_BELOW or height > halfHeight + BODY_ABOVE then
		return false
	end
	local shape = if part:IsA("Part") then part.Shape else nil
	if shape == Enum.PartType.Ball or (shape == Enum.PartType.Cylinder and axisIsX) then
		local radius = math.min(halfU, halfV)
		return u * u + v * v <= radius * radius
	end
	return math.abs(u) <= halfU and math.abs(v) <= halfV
end

-- Strongest slow (lowest factor) of the hazards the position stands in, or nil.
local function hazardFactorAt(position)
	if position.X <= HUB_MAX_X then
		return nil
	end
	local best = nil
	for part, factor in pairs(hazards) do
		if part.Parent == nil then
			hazards[part] = nil
		elseif standsIn(part, position) then
			best = if best then math.min(best, factor) else factor
		end
	end
	return best
end

local function clearSlow(player)
	local state = slowed[player]
	if not state then
		return
	end
	slowed[player] = nil
	local humanoid = state.Humanoid
	if humanoid.Parent == nil or humanoid.Health <= 0 then
		return
	end
	-- Only undo our own value: a trap freeze or a speed upgrade meanwhile owns WalkSpeed now.
	if math.abs(humanoid.WalkSpeed - state.Applied) > 0.01 then
		return
	end
	local speed = getSpeedService()
	if speed then
		pcall(speed.Refresh, player)
	end
	if math.abs(humanoid.WalkSpeed - state.Applied) <= 0.01 then
		humanoid.WalkSpeed = state.Base
	end
end

local function applySlow(player, humanoid, factor)
	local state = slowed[player]
	if state and state.Humanoid ~= humanoid then
		slowed[player] = nil
		state = nil
	end
	local current = humanoid.WalkSpeed
	local ours = state ~= nil and math.abs(current - state.Applied) <= 0.01
	if ours and state.Factor == factor then
		return
	end
	-- Anything else changed WalkSpeed since (speed upgrade, trap release): that is the new base.
	local base = if ours then state.Base else current
	local applied = base * factor
	humanoid.WalkSpeed = applied
	slowed[player] = { Humanoid = humanoid, Base = base, Applied = applied, Factor = factor }
end

local function step()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health <= 0 then
			slowed[player] = nil
		elseif character:GetAttribute("IsTrapped") == true or character:GetAttribute("HeroDebuff") ~= nil then
			-- GearService froze this player (trap, or a hero weapon's 2.5 s state) and restores its own saved
			-- WalkSpeed: leave it alone.
		else
			local factor = hazardFactorAt(root.Position)
			if factor and factor < 1 then
				applySlow(player, humanoid, factor)
			else
				clearSlow(player)
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	slowed[player] = nil
end)

task.spawn(function()
	local errors = 0
	while true do
		task.wait(CHECK_INTERVAL)
		if next(hazards) ~= nil or next(slowed) ~= nil then
			local ok, err = pcall(step)
			if not ok and errors < 3 then
				errors += 1
				warn("[StageHazardService] " .. tostring(err))
			end
		end
	end
end)
