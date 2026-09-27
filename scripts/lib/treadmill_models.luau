-- scripts/lib/treadmill_models.luau
-- Build-time helpers for the treadmill models of assets/treadmills/Treadmills.rbxl (TREADMILL owner, used by
-- scripts/steps/treadmill.luau). Lune only: nothing here ships in the place.
--
-- Every model there is one Model per treadmill: TMxx_Frame_0N MeshParts (the frame / console, a SurfaceAppearance each),
-- one TMxx_Belt MeshPart (its belt Beam scrolls a texture: the moving-belt look), invisible "Control Pannel" /
-- "Treadmill" Parts that only host ParticleEmitters, and a free-model showcase Script (never shipped).
--
-- Mesh geometry. Lune cannot load meshes, but every MeshPart carries its collision hulls in PhysicalConfigData:
--   "CSGPHS" | int32 version (8) | 2 bytes | zstd frame
-- and the frame decompresses to 9 little-endian int32 (hull count, vertex count, triangle count, 3 unknowns, bit count,
-- bitfield bytes, vertex bytes), the mesh-space bounding box (6 float32 = -InitialSize/2 .. InitialSize/2), a bitfield
-- (hull connectivity, unused here) and the vertices (float32 x, y, z), hull after hull. The vertex cloud (each convex
-- piece's corners) is a faithful outline of the visible mesh: it places the phone screen on the console and checks
-- that nothing of the mesh stands in front of it. ParseHull refuses any other layout (the caller falls back to boxes).

local serde = require("@lune/serde")

local M = {}

M.HULL_MAGIC = "CSGPHS"

-- Mesh-space hull vertices ({ x, y, z } triples) of a PhysicalConfigData blob, or nil + reason.
function M.ParseHull(blob)
	if type(blob) ~= "string" or #blob < 13 or string.sub(blob, 1, 6) ~= M.HULL_MAGIC then
		return nil, "no CSGPHS physics data"
	end
	local version = string.unpack("<i4", blob, 7)
	local ok, raw = pcall(serde.decompress, "zstd", string.sub(blob, 13))
	if not ok or type(raw) ~= "string" or #raw < 60 then
		return nil, "CSGPHS v" .. tostring(version) .. ": not a zstd frame"
	end
	local header = {}
	for i = 1, 9 do
		header[i] = string.unpack("<i4", raw, 1 + (i - 1) * 4)
	end
	local count, bitBytes, vertexBytes = header[2], header[8], header[9]
	if count <= 0 or vertexBytes ~= count * 12 or 60 + bitBytes + vertexBytes ~= #raw then
		return nil, string.format("CSGPHS v%d: unexpected layout (%d bytes, header %s)", version, #raw, table.concat(header, ","))
	end
	local vertices = table.create(count)
	local offset = 61 + bitBytes
	for i = 1, count do
		local x, y, z = string.unpack("<fff", raw, offset + (i - 1) * 12)
		vertices[i] = { x, y, z }
	end
	return vertices
end

-- World-space hull points of a MeshPart at its current CFrame / Size (mesh space is scaled by Size / InitialSize), or
-- nil + reason when the part has no readable hull data.
function M.MeshPoints(roblox, part)
	local okBlob, blob = pcall(function()
		return (part :: any).PhysicalConfigData
	end)
	local okInitial, initial = pcall(function()
		return (part :: any).InitialSize
	end)
	if not (okBlob and okInitial) or initial == nil or initial.X <= 0 or initial.Y <= 0 or initial.Z <= 0 then
		return nil, "no PhysicalConfigData / InitialSize"
	end
	local vertices, err = M.ParseHull(blob)
	if not vertices then
		return nil, err
	end
	local k = part.Size / initial
	local points = table.create(#vertices)
	for i, v in ipairs(vertices) do
		points[i] = part.CFrame * roblox.Vector3.new(v[1] * k.X, v[2] * k.Y, v[3] * k.Z)
	end
	return points
end

-- The 8 corners of a part's box (the fallback outline of a part without hull data).
function M.BoxCorners(roblox, cf, size)
	local h = size / 2
	local out = {}
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				table.insert(out, cf * roblox.Vector3.new(sx * h.X, sy * h.Y, sz * h.Z))
			end
		end
	end
	return out
end

-- Outline points of a part: the hull cloud of a MeshPart, else its box corners. Second result: true when exact.
function M.PartPoints(roblox, part)
	if part:IsA("MeshPart") then
		local points = M.MeshPoints(roblox, part)
		if points and #points > 0 then
			return points, true
		end
	end
	return M.BoxCorners(roblox, part.CFrame, part.Size), false
end

-- Reads one treadmill model: its belt MeshPart (name ending in "_Belt"), the visible frame MeshParts, and S, the
-- belt-top-centre frame (LookVector along the belt toward the console end, the end holding the tall parts), the belt
-- length / width. Returns nil + reason when the model does not look like one of these treadmills.
function M.Analyze(roblox, model)
	local Vector3, CFrame = roblox.Vector3, roblox.CFrame
	local belt, frames = nil, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("MeshPart") then
			if string.sub(d.Name, -5) == "_Belt" then
				if belt ~= nil then
					return nil, "two belt MeshParts (" .. belt.Name .. ", " .. d.Name .. ")"
				end
				belt = d
			elseif d.Transparency < 0.99 then
				table.insert(frames, d)
			end
		end
	end
	if belt == nil then
		return nil, "no <name>_Belt MeshPart"
	end
	if #frames == 0 then
		return nil, "no visible frame MeshPart"
	end
	local bcf, bsize = belt.CFrame, belt.Size
	if math.abs(bcf.UpVector.Y) < 0.99 then
		return nil, "the belt is not level"
	end
	local axis, length, width
	if bsize.Z >= bsize.X then
		axis, length, width = bcf.LookVector, bsize.Z, bsize.X
	else
		axis, length, width = bcf.RightVector, bsize.X, bsize.Z
	end
	axis = Vector3.new(axis.X, 0, axis.Z).Unit
	local topCentre = bcf.Position + Vector3.new(0, bsize.Y / 2 * math.abs(bcf.UpVector.Y), 0)
	-- The console end: where the frame rises well above the belt.
	local sum, n, points, exact = 0, 0, {}, true
	for _, part in ipairs(frames) do
		local pts, isExact = M.PartPoints(roblox, part)
		exact = exact and isExact
		for _, p in ipairs(pts) do
			table.insert(points, p)
			if p.Y > topCentre.Y + 3 then
				sum += (p - topCentre):Dot(axis)
				n += 1
			end
		end
	end
	if n == 0 then
		return nil, "no console found (no frame point 3 studs above the belt)"
	end
	local look = if sum / n < 0 then -axis else axis
	local S = CFrame.fromMatrix(topCentre, look:Cross(Vector3.yAxis).Unit, Vector3.yAxis, -look)
	return {
		model = model,
		belt = belt,
		frames = frames,
		S = S,
		beltLength = length,
		beltWidth = width,
		framePoints = points, -- world space, source pose
		exact = exact,
	}
end

return M
