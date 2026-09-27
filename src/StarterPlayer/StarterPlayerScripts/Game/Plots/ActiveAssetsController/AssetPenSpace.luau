-- StarterPlayerScripts.Game.Plots.ActiveAssetsController.AssetPenSpace (ANIMPOLISH, "hero spacing in the pen")
-- Who and what shares a pen, for the wander simulations (AssetWanderSimulator). One space per PetArea part:
--   members    every hero wandering in that pen (position, footprint radius, current destination)
--   obstacles  what a hero must walk around inside the pen rectangle: any VISIBLE part of the plot standing on the pen
--              floor (terminal, sign posts, props a base theme puts inside the fence...), rebuilt every
--              OBSTACLE_REFRESH s, and the placed eggs (workspace.PlacedEggRenders), refreshed every EGG_REFRESH s
--              because they grow. Invisible prompt / trigger parts, floor inlays and anything covering a big share
--              of the pen are ignored.
-- API (all cheap, no allocation per call besides the Vector3 results):
--   Join(area, radius) -> member | Leave(member) | Move(member, position, dt) | SetDestination(member, point)
--   Steer(member, position, vx, vz) -> flat Vector3 to add to the unit heading: neighbours push it away now and where
--       they will be within HORIZON s at the current velocities (walkers sidestep each other instead of bumping), the
--       obstacles push it away
--   Clearance(member, point) -> studs of free room around a candidate destination (heroes, their destinations,
--       obstacles; minus the hero's own radius)
--   Resolve(member, position, dt, halfX?, halfZ?) -> position pushed out of obstacles (hard) and slowly out of deep hero
--       overlaps; with the hero's wander rectangle (area-local half extents) the push-out picks an exit inside it (NPC
--       pass 2026-09-26: pushing a hero through the fence made the simulator's clamp pull it back in every frame)
--   PathClear(member, from, to) -> false when the straight walk from -> to crosses an obstacle / egg (NPC pass: such
--       destinations rank last, the hero would push into the obstacle)
--   Crowded(member, position) -> true while another hero overlaps this one by more than CROWD_SHARE
-- Never throws: a missing plot / egg folder just means no obstacles.

local Workspace = game:GetService("Workspace")

local GAP = 0.9 -- studs kept between two heroes' footprints
local OBSTACLE_GAP = 0.6
local OBSTACLE_REFRESH = 10.0
local EGG_REFRESH = 0.75
local MIN_HEIGHT = 0.35 -- above the pen floor: lower parts are floor decoration
local MAX_HEIGHT = 7.0
local MAX_SHARE = 0.25 -- a part covering more of the pen than this is not an obstacle (zones, floors)
local CROWD_SHARE = 0.3
local PUSH_RATE = 0.8 -- studs/s a deeply overlapped hero drifts apart (the rest is steering / walking off)
local HORIZON = 1.5 -- s: how far ahead walkers see each other coming
local SEE_RANGE2 = 22 * 22 -- neighbours farther than this (studs, squared) are not looked at
local VELOCITY_SMOOTH = 10.0

local AssetPenSpace = {}

type Member = {
	Area: BasePart,
	Radius: number,
	X: number,
	Z: number,
	DestX: number,
	DestZ: number,
	HasDest: boolean,
}

local spaces: { [BasePart]: any } = {} -- one per PetArea (the six plots live as long as the place)

local function plotOf(area: BasePart): Instance?
	local plots = Workspace:FindFirstChild("Plots")
	local node: Instance? = area
	while node and node.Parent and node.Parent ~= plots and node.Parent ~= Workspace do
		node = node.Parent
	end
	if node and node.Parent == plots then
		return node
	end
	return area.Parent
end

-- area-local footprint (centre x, z, half extents) and vertical span of a part
local function footprint(areaCFrame: CFrame, cf: CFrame, size: Vector3)
	local rel = areaCFrame:ToObjectSpace(cf)
	local r00, r01, r02, r10, r11, r12, r20, r21, r22 = select(4, rel:GetComponents())
	local sx, sy, sz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
	local hx = math.abs(r00) * sx + math.abs(r01) * sy + math.abs(r02) * sz
	local hy = math.abs(r10) * sx + math.abs(r11) * sy + math.abs(r12) * sz
	local hz = math.abs(r20) * sx + math.abs(r21) * sy + math.abs(r22) * sz
	local p = rel.Position
	return p.X, p.Y, p.Z, hx, hy, hz
end

local function rebuildObstacles(space)
	local area: BasePart = space.Area
	local list = {}
	local plot = plotOf(area)
	if plot ~= nil and area.Parent ~= nil then
		local areaCFrame = area.CFrame
		local halfX, halfZ = area.Size.X * 0.5, area.Size.Z * 0.5
		local floor = area.Size.Y * 0.5
		local penArea = area.Size.X * area.Size.Z
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("BasePart") and d ~= area and d.Transparency < 0.9 and not d:IsA("Terrain") then
				local cx, cy, cz, hx, hy, hz = footprint(areaCFrame, d.CFrame, d.Size)
				if cy + hy > floor + MIN_HEIGHT and cy - hy < floor + MAX_HEIGHT
					and math.abs(cx) - hx < halfX and math.abs(cz) - hz < halfZ
					and (hx * hz * 4) < penArea * MAX_SHARE then
					table.insert(list, { cx, cz, hx, hz })
				end
			end
		end
	end
	space.Obstacles = list
end

local function rebuildEggs(space)
	local area: BasePart = space.Area
	local list = space.Eggs
	table.clear(list)
	local folder = Workspace:FindFirstChild("PlacedEggRenders")
	if folder == nil or area.Parent == nil then
		return
	end
	local areaCFrame = area.CFrame
	local halfX, halfZ = area.Size.X * 0.5, area.Size.Z * 0.5
	for _, egg in ipairs(folder:GetChildren()) do
		local ok, cf, size = false, nil, nil
		if egg:IsA("Model") then
			ok, cf, size = pcall(egg.GetBoundingBox, egg)
		elseif egg:IsA("BasePart") then
			ok, cf, size = true, egg.CFrame, egg.Size
		end
		if ok and cf and size then
			local cx, _, cz, hx, _, hz = footprint(areaCFrame, cf, size)
			if math.abs(cx) - hx < halfX and math.abs(cz) - hz < halfZ then
				table.insert(list, { cx, cz, math.max(hx, hz) })
			end
		end
	end
end

local function spaceOf(area: BasePart)
	local space = spaces[area]
	if space == nil then
		space = { Area = area, Members = {}, Obstacles = {}, Eggs = {}, ObstacleAge = -math.huge, EggAge = -math.huge }
		spaces[area] = space
	end
	return space
end

-- Refreshes the obstacle lists of a space when due (called from the members' steps; the clock is shared).
local function refresh(space, now: number)
	if now - space.ObstacleAge >= OBSTACLE_REFRESH then
		space.ObstacleAge = now
		local ok = pcall(rebuildObstacles, space)
		if not ok then
			space.Obstacles = {}
		end
	end
	if now - space.EggAge >= EGG_REFRESH then
		space.EggAge = now
		if not pcall(rebuildEggs, space) then
			table.clear(space.Eggs)
		end
	end
end

function AssetPenSpace.Join(area: BasePart, radius: number): Member
	local space = spaceOf(area)
	local p = area.Position
	local member = { Area = area, Radius = math.max(radius, 0.5), X = p.X, Z = p.Z, VX = 0, VZ = 0, DestX = p.X, DestZ = p.Z,
		HasDest = false, Space = space }
	table.insert(space.Members, member)
	return member :: any
end

function AssetPenSpace.Leave(member)
	local space = member and member.Space
	if space == nil then
		return
	end
	local index = table.find(space.Members, member)
	if index then
		table.remove(space.Members, index)
	end
	member.Space = nil
end

function AssetPenSpace.SetRadius(member, radius: number)
	member.Radius = math.max(radius, 0.5)
end

function AssetPenSpace.Move(member, position: Vector3, dt: number?)
	if typeof(dt) == "number" and dt > 1e-4 then
		local k = math.min(dt * VELOCITY_SMOOTH, 1)
		member.VX += ((position.X - member.X) / dt - member.VX) * k
		member.VZ += ((position.Z - member.Z) / dt - member.VZ) * k
	end
	member.X, member.Z = position.X, position.Z
	local space = member.Space
	if space then
		refresh(space, os.clock())
	end
end

function AssetPenSpace.SetDestination(member, point: Vector3?)
	if point == nil then
		member.HasDest = false
		return
	end
	member.DestX, member.DestZ, member.HasDest = point.X, point.Z, true
end

-- distance from (lx, lz) to an area-local rectangle and the outward direction (inside: toward the nearest edge)
local function rectDistance(lx: number, lz: number, o): (number, number, number)
	local cx, cz, hx, hz = o[1], o[2], o[3], o[4]
	local dx, dz = lx - cx, lz - cz
	local ox, oz = math.abs(dx) - hx, math.abs(dz) - hz
	if ox <= 0 and oz <= 0 then
		-- inside: leave through the closest side
		if ox > oz then
			return ox, if dx >= 0 then 1 else -1, 0
		end
		return oz, 0, if dz >= 0 then 1 else -1
	end
	local qx, qz = math.max(ox, 0), math.max(oz, 0)
	local d = math.sqrt(qx * qx + qz * qz)
	return d, (if dx >= 0 then 1 else -1) * qx / d, (if dz >= 0 then 1 else -1) * qz / d
end

function AssetPenSpace.Steer(member, position: Vector3, vx: number?, vz: number?): Vector3
	local space = member.Space
	if space == nil then
		return Vector3.zero
	end
	local ax, az = 0.0, 0.0
	local px, pz = position.X, position.Z
	local mvx, mvz = vx or member.VX, vz or member.VZ
	local r = member.Radius
	for _, other in ipairs(space.Members) do
		local dx, dz = px - other.X, pz - other.Z
		local d2 = dx * dx + dz * dz
		if other ~= member and d2 < SEE_RANGE2 then
			local reach = r + other.Radius + GAP
			if d2 < reach * reach then
				if d2 > 1e-6 then
					local d = math.sqrt(d2)
					local w = (reach - d) / reach
					ax += dx / d * w * 2.2
					az += dz / d * w * 2.2
				else
					ax += 0.7 -- exactly on top of each other: any side
				end
			end
			-- where the two will be closest within HORIZON (relative motion): steer off that point, a little to the right
			local rvx, rvz = mvx - other.VX, mvz - other.VZ
			local vv = rvx * rvx + rvz * rvz
			if vv > 0.04 and d2 < (reach + math.sqrt(vv) * HORIZON) ^ 2 then
				local t = math.clamp(-(dx * rvx + dz * rvz) / vv, 0, HORIZON)
				if t > 0 then
					local cx, cz = dx + rvx * t, dz + rvz * t
					local cd = math.sqrt(cx * cx + cz * cz)
					if cd < reach then
						local w = (reach - cd) / reach * (1 - 0.5 * t / HORIZON) * 1.8
						local speed = math.sqrt(vv)
						local sx, sz = -rvz / speed, rvx / speed -- sidestep direction (right of the relative motion)
						if cd > 1e-3 then
							ax += (cx / cd + sx * 0.6) * w
							az += (cz / cd + sz * 0.6) * w
						else
							ax += sx * w
							az += sz * w
						end
					end
				end
			end
		end
	end
	local area = space.Area
	local obstacles, eggs = space.Obstacles, space.Eggs
	if #obstacles > 0 or #eggs > 0 then
		local l = area.CFrame:PointToObjectSpace(position)
		local lx, lz = l.X, l.Z
		local bx, bz = 0.0, 0.0
		local reach = r + OBSTACLE_GAP
		for _, o in ipairs(obstacles) do
			local d, nx, nz = rectDistance(lx, lz, o)
			if d < reach then
				local w = if d <= 0 then 1.5 else (reach - d) / reach
				bx += nx * w * 3
				bz += nz * w * 3
			end
		end
		for _, e in ipairs(eggs) do
			local dx, dz = lx - e[1], lz - e[2]
			local d = math.sqrt(dx * dx + dz * dz)
			local eggReach = reach + e[3]
			if d < eggReach and d > 1e-4 then
				local w = (eggReach - d) / eggReach
				bx += dx / d * w * 3
				bz += dz / d * w * 3
			end
		end
		if bx ~= 0 or bz ~= 0 then
			local world = area.CFrame:VectorToWorldSpace(Vector3.new(bx, 0, bz))
			ax += world.X
			az += world.Z
		end
	end
	if ax == 0 and az == 0 then
		return Vector3.zero
	end
	return Vector3.new(ax, 0, az)
end

function AssetPenSpace.Clearance(member, point: Vector3): number
	local space = member.Space
	if space == nil then
		return math.huge
	end
	local best = math.huge
	local px, pz = point.X, point.Z
	for _, other in ipairs(space.Members) do
		if other ~= member then
			local dx, dz = px - other.X, pz - other.Z
			best = math.min(best, math.sqrt(dx * dx + dz * dz) - other.Radius)
			if other.HasDest then
				dx, dz = px - other.DestX, pz - other.DestZ
				best = math.min(best, math.sqrt(dx * dx + dz * dz) - other.Radius)
			end
		end
	end
	local obstacles, eggs = space.Obstacles, space.Eggs
	if #obstacles > 0 or #eggs > 0 then
		local l = space.Area.CFrame:PointToObjectSpace(point)
		for _, o in ipairs(obstacles) do
			best = math.min(best, (rectDistance(l.X, l.Z, o)))
		end
		for _, e in ipairs(eggs) do
			local dx, dz = l.X - e[1], l.Z - e[2]
			best = math.min(best, math.sqrt(dx * dx + dz * dz) - e[3])
		end
	end
	return best - member.Radius
end

-- Liang-Barsky: does the segment (ax, az) -> (bx, bz) touch the rectangle centred (cx, cz) with half extents (hx, hz)?
local function segmentHitsRect(ax: number, az: number, bx: number, bz: number, cx: number, cz: number, hx: number, hz: number): boolean
	local t0, t1 = 0.0, 1.0
	local dx, dz = bx - ax, bz - az
	for axis = 1, 2 do
		local p, d, lo, hi
		if axis == 1 then
			p, d, lo, hi = ax, dx, cx - hx, cx + hx
		else
			p, d, lo, hi = az, dz, cz - hz, cz + hz
		end
		if math.abs(d) < 1e-9 then
			if p < lo or p > hi then
				return false
			end
		else
			local ta, tb = (lo - p) / d, (hi - p) / d
			if ta > tb then
				ta, tb = tb, ta
			end
			t0 = math.max(t0, ta)
			t1 = math.min(t1, tb)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

function AssetPenSpace.PathClear(member, from: Vector3, to: Vector3): boolean
	local space = member.Space
	if space == nil then
		return true
	end
	local obstacles, eggs = space.Obstacles, space.Eggs
	if #obstacles == 0 and #eggs == 0 then
		return true
	end
	local cf = space.Area.CFrame
	local a = cf:PointToObjectSpace(from)
	local b = cf:PointToObjectSpace(to)
	local ax, az, bx, bz = a.X, a.Z, b.X, b.Z
	local r = member.Radius * 0.75
	for _, o in ipairs(obstacles) do
		local cx, cz, hx, hz = o[1], o[2], o[3] + r, o[4] + r
		-- an obstacle the hero already stands in is being left (Resolve pushes it out): it does not block
		local inside = math.abs(ax - cx) <= hx and math.abs(az - cz) <= hz
		if not inside and segmentHitsRect(ax, az, bx, bz, cx, cz, hx, hz) then
			return false
		end
	end
	local dx, dz = bx - ax, bz - az
	local len2 = dx * dx + dz * dz
	for _, e in ipairs(eggs) do
		local reach = e[3] + r
		local ex, ez = ax - e[1], az - e[2]
		if ex * ex + ez * ez > reach * reach then
			local t = if len2 > 1e-9 then math.clamp(-(ex * dx + ez * dz) / len2, 0.0, 1.0) else 0.0
			local qx, qz = ex + dx * t, ez + dz * t
			if qx * qx + qz * qz < reach * reach then
				return false
			end
		end
	end
	return true
end

-- The nearest point outside obstacle rectangle `o` (grown by r) along the four axis exits that lies inside the wander
-- rectangle (|x| <= halfX, |z| <= halfZ); nil when every exit is outside it (the obstacle blocks a whole corner).
local function exitInside(lx: number, lz: number, o, r: number, halfX: number, halfZ: number): (number?, number?)
	local cx, cz, hx, hz = o[1], o[2], o[3] + r, o[4] + r
	local bestX, bestZ, bestD = nil, nil, math.huge
	local exits = { { cx + hx, lz }, { cx - hx, lz }, { lx, cz + hz }, { lx, cz - hz } }
	for _, e in ipairs(exits) do
		local ex, ez = e[1], e[2]
		if math.abs(ex) <= halfX + 1e-3 and math.abs(ez) <= halfZ + 1e-3 then
			local d = math.abs(ex - lx) + math.abs(ez - lz)
			if d < bestD then
				bestX, bestZ, bestD = ex, ez, d
			end
		end
	end
	return bestX, bestZ
end

function AssetPenSpace.Resolve(member, position: Vector3, dt: number, halfX: number?, halfZ: number?): Vector3
	local space = member.Space
	if space == nil then
		return position
	end
	local area = space.Area
	local obstacles, eggs = space.Obstacles, space.Eggs
	local r = member.Radius * 0.75
	local bounded = typeof(halfX) == "number" and typeof(halfZ) == "number"
	local moved = false
	local px, pz = position.X, position.Z
	-- heroes: a slow drift out of deep overlaps (the steering handles the rest)
	for _, other in ipairs(space.Members) do
		if other ~= member then
			local dx, dz = px - other.X, pz - other.Z
			local reach = (member.Radius + other.Radius) * 0.7
			local d2 = dx * dx + dz * dz
			if d2 < reach * reach and d2 > 1e-6 then
				local d = math.sqrt(d2)
				local step = math.min(reach - d, PUSH_RATE * dt)
				px += dx / d * step
				pz += dz / d * step
				moved = true
			end
		end
	end
	if #obstacles > 0 or #eggs > 0 then
		local world = if moved then Vector3.new(px, position.Y, pz) else position
		local l = area.CFrame:PointToObjectSpace(world)
		local lx, lz = l.X, l.Z
		local pushed = false
		for _, o in ipairs(obstacles) do
			local d, nx, nz = rectDistance(lx, lz, o)
			if d < r then
				local qx, qz = lx + nx * (r - d), lz + nz * (r - d)
				if bounded and (math.abs(qx) > halfX :: number or math.abs(qz) > halfZ :: number) then
					-- the plain push leaves the wander rectangle: take the nearest exit that stays inside it
					local ex, ez = exitInside(lx, lz, o, r, halfX :: number, halfZ :: number)
					if ex ~= nil then
						qx, qz = ex, ez :: number
					end
				end
				lx, lz = qx, qz
				pushed = true
			end
		end
		for _, e in ipairs(eggs) do
			local dx, dz = lx - e[1], lz - e[2]
			local d = math.sqrt(dx * dx + dz * dz)
			local reach = r + e[3]
			if d < reach then
				local nx, nz = 1.0, 0.0
				if d > 1e-4 then
					nx, nz = dx / d, dz / d
				end
				local qx, qz = lx + nx * (reach - d), lz + nz * (reach - d)
				if bounded and (math.abs(qx) > halfX :: number or math.abs(qz) > halfZ :: number) then
					-- an egg by the fence: slide along the fence line out of the egg instead of through the fence
					local hx, hz = halfX :: number, halfZ :: number
					qx, qz = math.clamp(qx, -hx, hx), math.clamp(qz, -hz, hz)
					local rx, rz = qx - e[1], qz - e[2]
					if rx * rx + rz * rz < reach * reach then
						if math.abs(qx) >= hx - 1e-3 then
							local along = math.sqrt(math.max(reach * reach - rx * rx, 0.0))
							qz = e[2] + (if dz >= 0 then along else -along)
						else
							local along = math.sqrt(math.max(reach * reach - rz * rz, 0.0))
							qx = e[1] + (if dx >= 0 then along else -along)
						end
					end
				end
				lx, lz = qx, qz
				pushed = true
			end
		end
		if pushed then
			local w = area.CFrame:PointToWorldSpace(Vector3.new(lx, l.Y, lz))
			return Vector3.new(w.X, position.Y, w.Z)
		end
		return world
	end
	if moved then
		return Vector3.new(px, position.Y, pz)
	end
	return position
end

function AssetPenSpace.Crowded(member, position: Vector3): boolean
	local space = member.Space
	if space == nil then
		return false
	end
	for _, other in ipairs(space.Members) do
		if other ~= member then
			local dx, dz = position.X - other.X, position.Z - other.Z
			local reach = (member.Radius + other.Radius) * (1 - CROWD_SHARE)
			if dx * dx + dz * dz < reach * reach then
				return true
			end
		end
	end
	return false
end

return AssetPenSpace
