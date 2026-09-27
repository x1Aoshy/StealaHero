-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.AssetWanderArea
-- (decompiled base module, reworked by ANIMPOLISH: injected from this mirror by scripts/inject/animpolish.luau)
-- Pen rectangle helpers of the wander simulation. The wander rectangle is the PetArea shrunk by a margin: 1.75 studs
-- by default (the old fixed value, still what IsPositionInside uses for "is the owner in the pen"), or a hero's own
-- margin (AssetWanderSimulator: its footprint radius + clearance) so a big hero never pokes through the fence.

local DEFAULT_MARGIN = 1.75

local t1 = {}

t1.DefaultMargin = DEFAULT_MARGIN

-- Half extents (X, Z) of the wander rectangle in the area's local space. A margin wider than the pen keeps 0.
function t1.HalfExtents(p1, margin: number?)
	local p1Size = p1.Size
	local m = if typeof(margin) == "number" then margin else DEFAULT_MARGIN

	return math.max(p1Size.X * 0.5 - m, 0.0), (math.max(p1Size.Z * 0.5 - m, 0.0))
end

function t1.ClampedPointToward(p2, vector3: Vector3, margin: number?)
	local v6, v7 = t1.HalfExtents(p2, margin)
	local v8 = p2.CFrame:PointToObjectSpace(vector3)
	local v9 = math.clamp(v8.X, -v6, v6)
	local v10 = math.clamp(v8.Z, -v7, v7)

	return (p2.CFrame * CFrame.new(v9, 0.0, v10)).Position
end

-- Same as ClampedPointToward but keeps the point's height (used on the simulation CFrame every frame).
function t1.ClampKeepHeight(p2, vector3: Vector3, margin: number?): (Vector3, boolean)
	local v6, v7 = t1.HalfExtents(p2, margin)
	local v8 = p2.CFrame:PointToObjectSpace(vector3)
	local x = math.clamp(v8.X, -v6, v6)
	local z = math.clamp(v8.Z, -v7, v7)

	if x == v8.X and z == v8.Z then
		return vector3, false
	end

	local flat = (p2.CFrame * CFrame.new(x, 0.0, z)).Position

	return Vector3.new(flat.X, vector3.Y, flat.Z), true
end

function t1.RandomPoint(p3, p4, margin: number?)
	local v13, v14 = t1.HalfExtents(p3, margin)
	local v15 = p4:NextNumber(-v13, v13)
	local v16 = p4:NextNumber(-v14, v14)

	return (p3.CFrame * CFrame.new(v15, 0.0, v16)).Position
end

function t1.IsPositionInside(p5, vector3: Vector3, margin: number?)
	local v19, v20 = t1.HalfExtents(p5, margin)
	local v21 = p5.CFrame:PointToObjectSpace(vector3)

	return v19 >= math.abs(v21.X) and v20 >= math.abs(v21.Z)
end

function t1.PointNearOwner(p6, vector3: Vector3, vector3_2: Vector3, margin: number?)
	return t1.ClampedPointToward(p6, vector3 + vector3_2, margin)
end

return t1
