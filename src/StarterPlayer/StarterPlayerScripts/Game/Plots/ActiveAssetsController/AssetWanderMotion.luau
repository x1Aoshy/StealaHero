-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.AssetWanderMotion
-- (decompiled base module, reworked by ANIMPOLISH: injected from this mirror by scripts/inject/animpolish.luau)
-- Steering helpers of the wander simulation (pure functions, no allocation besides the returned CFrame).
--   Turning (StepYawToward): proportional with a rate limit - a big turn starts at TURN_RATE_MAX, a small correction
--   eases out instead of stopping dead (the movement batch smooths the rendered rotation on top), so heroes curve
--   into their heading instead of snapping.
--   Moving (StepMoveToward): the hero walks where it FACES (plus a pull toward the target that grows close to it), at
--   a speed that falls off with the heading error: it turns on the spot first, then sets off - no crab-walking, no
--   moonwalking. Returned speed = the ground speed actually covered (the clip player's cadence follows it).
--   `avoid` (optional Vector3, flat) bends the heading away from neighbours / obstacles (AssetPenSpace).

local AssetWanderArea = require(script.Parent.AssetWanderArea)

local TURN_RATE_MAX = 4.2 -- rad/s (~240 deg/s)
local TURN_GAIN = 7.0 -- 1/s: proportional part, the last ~35 deg of a turn ease out
local FACE_OWNER_RATE = 2.0 -- FaceOwnerCFrame(..., fast) turns this much faster (was an instant snap)
local SPEED_FALLOFF = 0.45 -- cos(angle between facing and the way it would move) below this: turn on the spot
local ARRIVE_PULL = 1.6 -- studs: under this distance the heading is pulled straight at the target

local t1 = {
	YawFromFlatDirection = function(vector3: Vector3) -- line: 18
		return (math.atan2(-vector3.X, -vector3.Z))
	end,
	ShortestYawDelta = function(n1: number, n2: number) -- line: 22
		local v6 = n2 - n1

		return (math.atan2(math.sin(v6), (math.cos(v6))))
	end
}

-- One turning step from yaw n3 toward n4 over dt n5 (rateScale speeds it up). Returns the new yaw and the step.
function t1.StepYawToward(n3: number, n4: number, n5: number, rateScale: number?)
	local v10 = t1.ShortestYawDelta(n3, n4)
	local scale = if typeof(rateScale) == "number" then rateScale else 1.0
	local maxStep = n5 * TURN_RATE_MAX * scale
	local wanted = v10 * (1.0 - math.exp(-TURN_GAIN * scale * n5))
	local v12 = math.clamp(wanted, -maxStep, maxStep)

	return n3 + v12, v12
end

function t1.StepMoveToward(n6: number, cFrame: CFrame, vector3: Vector3, n7: number, avoid: Vector3?)
	local cFramePosition = cFrame.Position
	local v18 = vector3 - cFramePosition
	local vector3_2 = Vector3.new(v18.X, 0.0, v18.Z)
	local Magnitude = vector3_2.Magnitude

	if Magnitude <= 1e-4 then
		return cFrame, false, 0.0
	end

	local Unit = vector3_2.Unit
	local steer = Unit

	if avoid ~= nil then
		local bent = Unit + Vector3.new(avoid.X, 0.0, avoid.Z)

		if bent.Magnitude > 1e-3 then
			steer = bent.Unit
		end
	end

	local LookVector = cFrame.LookVector
	local vector3_3 = Vector3.new(LookVector.X, 0.0, LookVector.Z)
	local v25 = if not (vector3_3.Magnitude > 0.0) then steer else vector3_3.Unit
	local v26 = t1.YawFromFlatDirection(v25)
	local v27 = t1.YawFromFlatDirection(steer)
	local v28, v29 = t1.StepYawToward(v26, v27, n6)
	local facing = Vector3.new(-math.sin(v28), 0.0, -math.cos(v28))
	-- walk along the facing; near the target, straight at it (so the hero lands on it instead of circling it) - still
	-- bent by the avoidance, so a hero never walks into another one standing on its way
	local pull = math.clamp(ARRIVE_PULL / Magnitude, 0.0, 1.0)
	local direction = facing * (1.0 - pull) + steer * pull

	if direction.Magnitude > 1e-4 then
		direction = direction.Unit
	else
		direction = Unit
	end

	-- the speed falls off with how far the steering wants to go from the facing (and the actual move from it)
	local alignment = math.clamp((math.min(facing:Dot(steer), facing:Dot(direction)) - SPEED_FALLOFF) / (1.0 - SPEED_FALLOFF), 0.0, 1.0)
	local v30 = alignment * alignment * (3.0 - 2.0 * alignment)

	local v21 = math.min(Magnitude, n7 * n6 * v30)
	local v31 = cFramePosition + direction * v21

	return CFrame.new(v31) * CFrame.Angles(0.0, v28, 0.0), v30 > 0.0 or math.abs(v29) > 0.008726646259971648, if n6 > 0 then v21 / n6 else 0.0
end

-- Turns toward the owner in place; b1 = a quick turn (arrival), still eased (the old instant snap popped).
function t1.FaceOwnerCFrame(cFrame: CFrame, vector3: Vector3, n8: number, b1: boolean?)
	local cFramePosition = cFrame.Position
	local vector3_4 = Vector3.new(vector3.X - cFramePosition.X, 0.0, vector3.Z - cFramePosition.Z)

	if vector3_4.Magnitude <= 0.0 then
		return cFrame
	end

	local LookVector = cFrame.LookVector
	local vector3_5 = Vector3.new(LookVector.X, 0.0, LookVector.Z)

	if vector3_5.Magnitude <= 0.0 then
		return cFrame
	end

	local v40 = t1.YawFromFlatDirection(vector3_5.Unit)
	local v41 = t1.YawFromFlatDirection(vector3_4.Unit)
	local v42 = t1.StepYawToward(v40, v41, n8, if b1 == true then FACE_OWNER_RATE else 1.0)

	return CFrame.new(cFramePosition) * CFrame.Angles(0.0, v42, 0.0)
end

function t1.StepFollowOwner(p1, n9: number, cFrame: CFrame, vector3: Vector3, vector3_6: Vector3, n10: number, n11: number, margin: number?, avoid: Vector3?)
	local v50 = AssetWanderArea.PointNearOwner(p1, vector3, vector3_6, margin)
	local v51, v52, v53 = t1.StepMoveToward(n9, cFrame, v50, n10, avoid)

	if n11 >= Vector3.new(v50.X - v51.Position.X, 0.0, v50.Z - v51.Position.Z).Magnitude then
		v51 = t1.FaceOwnerCFrame(v51, vector3, n9)
	end

	return v51, v52, v53
end

function t1.OwnerMoveVector(n12: number, vector3: Vector3?, vector3_7: Vector3?)
	if vector3 == nil then
		return Vector3.new(0.0, 0.0, 0.0), nil
	end

	if vector3_7 == nil or n12 <= 0.0 then
		return Vector3.new(0.0, 0.0, 0.0), vector3
	end

	local v57 = vector3 - vector3_7

	return Vector3.new(v57.X, 0.0, v57.Z) / n12, vector3
end

-- Orbit around the owner (greeting). The heading turns like everywhere else (no snap to the orbit tangent).
function t1.OrbitGreetingCFrame(p2, n13: number, cFrame: CFrame, vector3: Vector3, vector3_8: Vector3, n14: number, n15: number, n16: number, margin: number?)
	local cFramePosition = cFrame.Position
	local vector3_9 = Vector3.new(cFramePosition.X - vector3.X, 0.0, cFramePosition.Z - vector3.Z)
	local Unit

	if vector3_9.Magnitude == 0.0 then
		local LookVector = p2.CFrame.LookVector
		local vector3_10 = Vector3.new(LookVector.X, 0.0, LookVector.Z)

		if vector3_10.Magnitude <= 0.0 then
			return cFrame, false, 0.0
		end

		Unit = vector3_10.Unit
	else
		local Unit2 = vector3_9.Unit

		Unit = (Vector3.new(-Unit2.Z, 0.0, Unit2.X) + Unit2 * math.clamp((n14 - vector3_9.Magnitude) / n14, -n16, n16)).Unit
	end

	local v72 = Unit * n15 + vector3_8
	local vector3_11 = Vector3.new(v72.X, 0.0, v72.Z)

	if vector3_11.Magnitude <= 0.0 then
		return cFrame, false, 0.0
	end

	local v75 = AssetWanderArea.ClampedPointToward(p2, cFramePosition + v72 * n13, margin)
	local vector3_12 = Vector3.new(v75.X - cFramePosition.X, 0.0, v75.Z - cFramePosition.Z)

	if vector3_12.Magnitude <= 0.0 then
		return cFrame, false, 0.0
	end

	local LookVector = cFrame.LookVector
	local flatLook = Vector3.new(LookVector.X, 0.0, LookVector.Z)
	local yaw = t1.YawFromFlatDirection(vector3_12.Unit)

	if flatLook.Magnitude > 0.0 then
		yaw = t1.StepYawToward(t1.YawFromFlatDirection(flatLook.Unit), yaw, n13, 1.5)
	end

	return CFrame.new(v75) * CFrame.Angles(0.0, yaw, 0.0), true, if n13 > 0 then vector3_12.Magnitude / n13 else 0.0
end

return t1
