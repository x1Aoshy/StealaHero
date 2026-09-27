--!nocheck
-- scripts/steps/post_zzz_night_wall.luau (owner 2026-09-27: "when night falls it stays half-open there")
-- The night wall (Workspace.__OBJECTS.Areas.WallStartVisual: Library.Client.AreaEggResetWall pops it up, opaque, for
-- the night and ResetStartTimer hangs the moon countdown on it) kept the base place's 146.8-stud width, but this game's
-- lane between the hub's east walls is ~172 studs wide (HubWall_EastSouth / HubWall_EastNorth inner faces): an
-- 11-15 stud gap stayed open on each side. The wall now spans the whole opening (half a stud into each hub wall),
-- centred on it; its length along the lane, height and orientation are unchanged. Idempotent.

local roblox = require("@lune/roblox")

local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

local Step = {}

Step.OVERLAP = 0.5 -- studs into each hub wall

local function zRange(part)
	-- world Z extent of an axis-aligned (or 90-degree turned) part
	local cf, size = part.CFrame, part.Size
	local half = math.abs(cf.RightVector.Z) * size.X / 2 + math.abs(cf.UpVector.Z) * size.Y / 2 + math.abs(cf.LookVector.Z) * size.Z / 2
	return cf.Position.Z - half, cf.Position.Z + half
end

function Step.Apply(place, _spPlace, _ctx)
	local ws = place:GetService("Workspace")
	local objects = ws:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local wall = areas and areas:FindFirstChild("WallStartVisual")
	local hubWalls = ws:FindFirstChild("WorldWalls") and ws.WorldWalls:FindFirstChild("Hub")
	local south = hubWalls and hubWalls:FindFirstChild("HubWall_EastSouth")
	local north = hubWalls and hubWalls:FindFirstChild("HubWall_EastNorth")
	if not (wall and wall:IsA("BasePart") and south and north) then
		print("[post_zzz_night_wall] WARN WallStartVisual or the hub's east walls missing; night wall left as is")
		return
	end
	local _, southInner = zRange(south)
	local northInner = zRange(north)
	local width = (northInner - southInner) + 2 * Step.OVERLAP
	local centreZ = (northInner + southInner) / 2
	-- the wall's local axis that runs across the lane (world Z)
	local cf, size = wall.CFrame, wall.Size
	local p = cf.Position
	if math.abs(cf.RightVector.Z) > 0.99 then
		wall.Size = Vector3.new(width, size.Y, size.Z)
	elseif math.abs(cf.LookVector.Z) > 0.99 then
		wall.Size = Vector3.new(size.X, size.Y, width)
	else
		print("[post_zzz_night_wall] WARN WallStartVisual is not turned across the lane; left as is")
		return
	end
	wall.CFrame = CFrame.new(p.X, p.Y, centreZ) * cf.Rotation
	print(string.format("[post_zzz_night_wall] night wall spans Z %.1f..%.1f (%.1f studs, was %.1f)", centreZ - width / 2,
		centreZ + width / 2, width, math.abs(cf.RightVector.Z) > 0.99 and size.X or size.Z))
end

return Step
