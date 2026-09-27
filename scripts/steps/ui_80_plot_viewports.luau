--!nocheck
-- scripts/steps/ui_80_plot_viewports.luau (owner UIFIX, 2026-09-24)
-- Owner report: "Anade una nueva imagen de los plots en el UI, salen los plots viejos ahi; anade una nueva imagen de
-- ellos o viewport o render". Audit of every image the place draws (StarterGui, ReplicatedStorage.Assets UI templates,
-- world SurfaceGuis / BillboardGuis and every rbxassetid a script writes, all thumbnailed): no ImageLabel shows a
-- plot / base picture (PlotUpgrade / TreadmillUpgrade signs = treadmill / arrows art, BaseUpgradeTransitionGui = a
-- white flash, Directory.Bases has no images, the only landscape, ReplicatedStorage.Assets.Interface.Islands, is an
-- unused base-game template). The one place the UI shows a plot is the Index "STAGE BASES" page: its 3D preview
-- (Content.SpBaseThemesPage.Detail.Preview, a ViewportFrame filled by StarterPlayerScripts.GUI.BaseThemes with a clone
-- of ReplicatedStorage.Assets.BaseThemes.<Key>) drew a stand-in pen: a plain 52.5-stud fence that is not the plot the
-- player owns (no navy studded fence, no gate, no upgrade signs, no treadmill) - the "old plots".
--
-- This step (ui_* pass, after ui_75_base_themes; every post_* step, the hub remodel's fences and the base themes are
-- final by then) rebuilds each ReplicatedStorage.Assets.BaseThemes.<Key> from the CURRENT plot:
--   PlotPreview      a clean clone of Workspace.Plots.<REFERENCE_PLOT> (pen fence, gate, upgrade signs, treadmill):
--                    scripts, GUIs, prompts, click detectors, sounds, lights, effects, constraints and invisible
--                    helper parts removed; its StarterPen fence recoloured by role exactly like PlotService does for
--                    the theme (Directory.BaseThemes Fence / FenceMaterials), or hidden (gate kept) when the theme
--                    brings its own modelled pen (HidesPenFence);
--   Theme*           the theme's props built for that same plot (ServerStorage.BaseThemes.<Key>.<REFERENCE_PLOT>, the
--                    model PlotService clones onto the plot), attributes copied (ImportedPen, HidesPenFence, ...);
--   PreviewDiorama   a chunky studded toy tile under it (grass top, dirt and rock layers);
-- all anchored and inert (no CollectionService tags, so the real plot's scripts never pick a preview up), moved into the
-- canonical preview frame (pen centred on the origin, gate toward -Z, ground at Y 0), then uniformly scaled and centred
-- on GUI.BaseThemes' camera target (target, offset, FOV and sway read from its source) at the largest scale that keeps
-- the whole plot in frame at every sway angle - the isometric hero shot of the real base. Built once here: the client
-- only clones it once per theme. A theme whose per-plot props are missing (or whose rebuild fails) keeps its old
-- preview (logged). Checked offline by rendering the exported parts with the same camera (UIFIX scratch render.py).
-- No neon, no lights (owner 2026-09-25: "remove ALL the neon from the bases"): the previews keep no light (sanitize), a
-- Neon part of the plot clone or a theme's Neon fence material becomes SmoothPlastic, and the step FAILS THE BUILD if a
-- Neon part or a light is left in ReplicatedStorage.Assets.BaseThemes (post_zz_base_themes Step.assertNoNeon checks the
-- per-plot models). A landmark behind a pen (Lake / Desert / Jungle) is part of the themed props, so the fit frames it.
-- Lune: explicit CFrame math only (no lookAt / PivotTo), WorldPivotData, whole-subtree clones.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local Step = {}

Step.REFERENCE_PLOT = "1" -- a standard (52.5-stud, not rotated) pen
Step.DIRECTORY_SOURCE = "src/ReplicatedStorage/Directory/BaseThemes.luau"
Step.CLIENT_SOURCE = "src/StarterPlayer/StarterPlayerScripts/GUI/BaseThemes.client.luau"
Step.PREVIEW_FOLDER = "BaseThemes" -- ReplicatedStorage.Assets.BaseThemes.<Key>
Step.STORE_FOLDER = "BaseThemes" -- ServerStorage.BaseThemes.<Key>.<plot>
Step.PLOT_NAME = "PlotPreview"
Step.DIORAMA_NAME = "PreviewDiorama"
-- GUI.BaseThemes camera (fallbacks; the real values are parsed from Step.CLIENT_SOURCE)
Step.CAMERA = {
	target = Vector3.new(0, 9, 10),
	offset = Vector3.new(0, 40, -96),
	fov = 40, -- vertical, degrees
	sway = 0.5, -- yaw amplitude, radians
	aspect = 2.3, -- Detail.Preview width / height (0.96 x 0.44 of the detail card, ~2.34)
	marginV = 1.5, -- degrees kept free at the top / bottom
	marginH = 3,
}
Step.MIN_SCALE = 0.5
Step.MAX_SCALE = 1.4

local LOG_PREFIX = "[ui_80_plot_viewports]"
local function log(fmt, ...)
	print(string.format(LOG_PREFIX .. " " .. fmt, ...))
end

---------------------------------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------------------------------

local function hex(s)
	return Color3.fromRGB(tonumber(string.sub(s, 2, 3), 16), tonumber(string.sub(s, 4, 5), 16), tonumber(string.sub(s, 6, 7), 16))
end

local function loadDirectory()
	local chunk = luau.load(fs.readFile(Step.DIRECTORY_SOURCE), { debugName = Step.DIRECTORY_SOURCE, environment = { Color3 = Color3 } })
	return chunk()
end

local function parseVector(source, name)
	local body = string.match(source, name .. "%s*=%s*Vector3%.new%(([^%)]*)%)")
	if not body then
		return nil
	end
	local parts = string.split(body, ",")
	local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
	return if x and y and z then Vector3.new(x, y, z) else nil
end

-- The preview camera of GUI.BaseThemes (so the fit follows the client if its framing changes).
local function readCamera()
	local cam = table.clone(Step.CAMERA)
	if fs.isFile(Step.CLIENT_SOURCE) then
		local source = fs.readFile(Step.CLIENT_SOURCE)
		cam.target = parseVector(source, "PREVIEW_TARGET") or cam.target
		cam.offset = parseVector(source, "PREVIEW_OFFSET") or cam.offset
		cam.fov = tonumber(string.match(source, "previewCamera%.FieldOfView%s*=%s*([%d%.]+)")) or cam.fov
		cam.sway = tonumber(string.match(source, "local yaw = math%.sin%([^%)]*%)%s*%*%s*([%d%.]+)")) or cam.sway
	end
	return cam
end

local function readPivot(model)
	local ok, pivot = pcall(function()
		return model.WorldPivotData
	end)
	return if ok and typeof(pivot) == "CFrame" then pivot else nil
end

local function writePivot(model, pivot)
	pcall(function()
		model.WorldPivotData = pivot
	end)
end

-- Every renderable a ViewportFrame draws; anything else is stripped from a preview clone.
local KEEP_CLASSES = {
	Model = true, Folder = true, SpecialMesh = true, BlockMesh = true, CylinderMesh = true, FileMesh = true,
	Decal = true, Texture = true, SurfaceAppearance = true,
}

local function hasDecal(part)
	for _, c in ipairs(part:GetChildren()) do
		if c:IsA("Decal") then
			return true
		end
	end
	return false
end

-- Strips a preview clone down to static geometry; with dropInvisible, invisible helper parts (no decal, no child parts)
-- go too. Every remaining part is anchored and inert (no collision, query, touch, shadow). CollectionService tags go
-- (a tagged clone would be picked up by the scripts that drive the real plot, e.g. SpeedsterTreadmillDisplay), and with
-- clearAttributes every attribute too.
local function sanitize(root, dropInvisible, clearAttributes)
	local removed = 0
	local all = root:GetDescendants()
	table.insert(all, root)
	for _, d in ipairs(all) do
		for _, tag in ipairs(d:GetTags()) do
			d:RemoveTag(tag)
		end
		if clearAttributes then
			for name in pairs(d:GetAttributes()) do
				if string.sub(name, 1, 3) ~= "RBX" then -- engine-reserved (e.g. RBX_ScriptVersion), not writable
					pcall(function()
						d:SetAttribute(name, nil)
					end)
				end
			end
		end
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil and not (d:IsA("BasePart") or KEEP_CLASSES[d.ClassName]) then
			d:Destroy()
			removed += 1
		end
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil and d:IsA("BasePart") then
			if dropInvisible and d.Transparency >= 0.999 and not hasDecal(d) and d:FindFirstChildWhichIsA("BasePart", true) == nil then
				d:Destroy()
				removed += 1
			else
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.CastShadow = false
				if d.Material == Enum.Material.Neon then
					d.Material = Enum.Material.SmoothPlastic -- no neon in a base preview (owner 2026-09-25)
				end
			end
		end
	end
	return removed
end

-- Fails the build when a preview holds a Neon part or a light (owner 2026-09-25: no neon, no lights in the bases).
local function assertNoNeon(root)
	local neon, lights = {}, {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
			table.insert(neon, d:GetFullName())
		elseif d:IsA("Light") then
			table.insert(lights, d:GetFullName())
		end
	end
	if #neon > 0 or #lights > 0 then
		error(string.format("%s NO NEON / NO LIGHTS in the base previews (owner 2026-09-25): %d Neon part(s) (%s), %d light(s) (%s)",
			LOG_PREFIX, #neon, table.concat(neon, ", ", 1, math.min(#neon, 6)), #lights, table.concat(lights, ", ", 1, math.min(#lights, 6))))
	end
end

-- Applies `cf` (world -> preview) to every part and model pivot under root.
local function transform(root, cf)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = cf * d.CFrame
		elseif d:IsA("Model") then
			local pivot = readPivot(d)
			if pivot then
				writePivot(d, cf * pivot)
			end
		end
	end
	if root:IsA("Model") then
		local pivot = readPivot(root)
		writePivot(root, if pivot then cf * pivot else cf)
	end
end

-- Uniform scale about the preview origin (sizes, positions, file-mesh scales, mesh offsets, texture tiling).
local function scaleAbout(root, k)
	local function scaleCFrame(cf)
		local p = cf.Position
		return CFrame.new(p * k) * (cf - p)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Size = d.Size * k
			d.CFrame = scaleCFrame(d.CFrame)
		elseif d:IsA("SpecialMesh") then
			pcall(function()
				if d.MeshType == Enum.MeshType.FileMesh then
					d.Scale = d.Scale * k
				end
				d.Offset = d.Offset * k
			end)
		elseif d:IsA("BlockMesh") or d:IsA("CylinderMesh") then
			pcall(function()
				d.Offset = d.Offset * k
			end)
		elseif d:IsA("Texture") then
			pcall(function()
				d.StudsPerTileU = d.StudsPerTileU * k
				d.StudsPerTileV = d.StudsPerTileV * k
				d.OffsetStudsU = d.OffsetStudsU * k
				d.OffsetStudsV = d.OffsetStudsV * k
			end)
		elseif d:IsA("Model") then
			local pivot = readPivot(d)
			if pivot then
				writePivot(d, scaleCFrame(pivot))
			end
		end
	end
end

-- World AABB corners of a part.
local function corners(part)
	local cf, s = part.CFrame, part.Size / 2
	local out = {}
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				table.insert(out, cf * Vector3.new(sx * s.X, sy * s.Y, sz * s.Z))
			end
		end
	end
	return out
end

-- AABB of the visible parts under root, plus per-8-stud-cell AABBs (the fit's sample points).
local function measure(root)
	local mn, mx = nil, nil
	local cells = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.999 then
			local center = d.CFrame.Position
			local key = math.floor(center.X / 8) .. ":" .. math.floor(center.Z / 8)
			local cell = cells[key]
			for _, c in ipairs(corners(d)) do
				mn = if mn then Vector3.new(math.min(mn.X, c.X), math.min(mn.Y, c.Y), math.min(mn.Z, c.Z)) else c
				mx = if mx then Vector3.new(math.max(mx.X, c.X), math.max(mx.Y, c.Y), math.max(mx.Z, c.Z)) else c
				if cell == nil then
					cell = { c, c }
					cells[key] = cell
				else
					cell[1] = Vector3.new(math.min(cell[1].X, c.X), math.min(cell[1].Y, c.Y), math.min(cell[1].Z, c.Z))
					cell[2] = Vector3.new(math.max(cell[2].X, c.X), math.max(cell[2].Y, c.Y), math.max(cell[2].Z, c.Z))
				end
			end
		end
	end
	local points = {}
	for _, cell in pairs(cells) do
		local a, b = cell[1], cell[2]
		for _, x in ipairs({ a.X, b.X }) do
			for _, y in ipairs({ a.Y, b.Y }) do
				for _, z in ipairs({ a.Z, b.Z }) do
					table.insert(points, { x, y, z })
				end
			end
		end
	end
	return mn, mx, points
end

---------------------------------------------------------------------------------------------------
-- camera fit
---------------------------------------------------------------------------------------------------

local function cameraFrames(cam)
	local frames = {}
	for _, t in ipairs({ -1, -0.5, 0, 0.5, 1 }) do
		local yaw = t * cam.sway
		local ox, oy, oz = cam.offset.X, cam.offset.Y, cam.offset.Z
		-- CFrame.Angles(0, yaw, 0) * offset
		local rx, rz = ox * math.cos(yaw) + oz * math.sin(yaw), -ox * math.sin(yaw) + oz * math.cos(yaw)
		local ex, ey, ez = cam.target.X + rx, cam.target.Y + oy, cam.target.Z + rz
		local fx, fy, fz = cam.target.X - ex, cam.target.Y - ey, cam.target.Z - ez
		local fl = math.sqrt(fx * fx + fy * fy + fz * fz)
		fx, fy, fz = fx / fl, fy / fl, fz / fl
		-- right = forward x up(0,1,0) = (-fz, 0, fx); up' = right x forward
		local rxx, rzz = -fz, fx
		local rl = math.sqrt(rxx * rxx + rzz * rzz)
		rxx, rzz = rxx / rl, rzz / rl
		local ux, uy, uz = 0 * fz - rzz * fy, rzz * fx - rxx * fz, rxx * fy - 0 * fx
		table.insert(frames, { ex, ey, ez, fx, fy, fz, rxx, rzz, ux, uy, uz })
	end
	return frames
end

-- Smallest free margin (fraction of the half frame) of the points after scale k and shift d; < 0 = clipped.
local function fitMargin(points, frames, k, dx, dy, dz, tanV, tanH)
	local worst = math.huge
	for _, f in ipairs(frames) do
		local ex, ey, ez, fx, fy, fz, rx, rz, ux, uy, uz = table.unpack(f)
		for _, p in ipairs(points) do
			local vx, vy, vz = p[1] * k + dx - ex, p[2] * k + dy - ey, p[3] * k + dz - ez
			local depth = vx * fx + vy * fy + vz * fz
			if depth <= 1 then
				return -1
			end
			local sx = math.abs(vx * rx + vz * rz) / depth
			local sy = math.abs(vx * ux + vy * uy + vz * uz) / depth
			local m = math.min(1 - sx / tanH, 1 - sy / tanV)
			if m < worst then
				worst = m
			end
		end
	end
	return worst
end

-- The largest scale (MIN_SCALE .. MAX_SCALE) at which the content stays in frame at every sway angle, with its
-- bounding-box centre on the camera target plus the best small nudge (up / down, toward / away from the camera): the
-- biggest hero shot that never clips. Binary search on the scale (fit is monotonic in it), grid search on the nudge.
local function solveFit(points, cam, center)
	local frames = cameraFrames(cam)
	local tanV = math.tan(math.rad(cam.fov / 2 - cam.marginV))
	local tanH = math.tan(math.atan(math.tan(math.rad(cam.fov / 2)) * cam.aspect) - math.rad(cam.marginH))
	local function bestAt(k)
		local best = nil
		for ny = -8, 8, 2 do
			for nz = -16, 16, 2 do
				local dx, dy, dz = cam.target.X - center.X * k, cam.target.Y - center.Y * k + ny, cam.target.Z - center.Z * k + nz
				local m = fitMargin(points, frames, k, dx, dy, dz, tanV, tanH)
				if best == nil or m > best.margin then
					best = { k = k, dx = dx, dy = dy, dz = dz, margin = m }
				end
			end
		end
		return best
	end
	local top = bestAt(Step.MAX_SCALE)
	if top.margin >= 0 then
		return top
	end
	local low = bestAt(Step.MIN_SCALE)
	if low.margin < 0 then
		return low
	end
	local lo, hi, found = Step.MIN_SCALE, Step.MAX_SCALE, low
	for _ = 1, 9 do
		local mid = (lo + hi) / 2
		local fit = bestAt(mid)
		if fit.margin >= 0 then
			lo, found = mid, fit
		else
			hi = mid
		end
	end
	return found
end

---------------------------------------------------------------------------------------------------
-- plot clone
---------------------------------------------------------------------------------------------------

-- PlotService.fenceRole (kept in step: a visible StarterPen part's role from its name / shape).
local function fenceRole(part, groundY)
	local parentName = part.Parent and part.Parent.Name or ""
	if parentName == "GateLeft" or parentName == "GateRight" then
		return if part.Name == "Hinge" then "Hinge" else "Gate"
	end
	if part.Name == "HubFenceCap" then
		return "Cap"
	elseif part.Name == "HubFenceGem" then
		return "Gem"
	elseif part.Name == "HubFenceBrace" then
		return "Brace"
	end
	local size = part.Size
	if size.Y >= 3 and size.X <= 2 and size.Z <= 2 then
		return "Post"
	end
	if math.max(size.X, size.Z) >= 4 then
		local level = part.CFrame.Position.Y - groundY
		if level < 1.4 then
			return "RailLow"
		elseif level > 3 then
			return "RailTop"
		end
		return "Brace"
	end
	return nil
end

local function materialNamed(name)
	if type(name) ~= "string" then
		return nil
	end
	if name == "Neon" then
		return Enum.Material.SmoothPlastic -- never Neon in a base preview (owner 2026-09-25)
	end
	local ok, material = pcall(function()
		return Enum.Material[name]
	end)
	return if ok then material else nil
end

-- Theme look on the clone's StarterPen (world coordinates, before the preview transform), as PlotService applies it.
local function dressPen(plot, theme, hidesFence)
	local toUpdate = plot:FindFirstChild("ToUpdate")
	local pen = toUpdate and toUpdate:FindFirstChild("StarterPen")
	if pen == nil then
		return 0
	end
	local visible = {}
	local groundY = tonumber(plot:GetAttribute("TreadmillFloorY"))
	for _, part in ipairs(pen:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			table.insert(visible, part)
			local bottom = part.CFrame.Position.Y - part.Size.Y / 2
			if not groundY or bottom < groundY then
				groundY = bottom
			end
		end
	end
	local changed = 0
	if hidesFence then
		for _, part in ipairs(visible) do
			local parentName = part.Parent and part.Parent.Name or ""
			if parentName ~= "GateLeft" and parentName ~= "GateRight" then
				part:Destroy()
				changed += 1
			end
		end
		return changed
	end
	if type(theme) ~= "table" or type(theme.Fence) ~= "table" then
		return 0
	end
	local materials = if type(theme.FenceMaterials) == "table" then theme.FenceMaterials else {}
	for _, part in ipairs(visible) do
		local role = fenceRole(part, groundY or 0)
		local color = role and theme.Fence[role]
		if typeof(color) == "Color3" then
			part.Color = color
			local material = materialNamed(materials[role])
			if material then
				part.Material = material
				part.MaterialVariant = ""
			end
			changed += 1
		end
	end
	return changed
end

-- World -> preview frame of a plot: pen centre (visible StarterPen parts) to the origin, gate (StarterPen.GridCenter)
-- toward -Z, the pen's ground to Y 0.
local function penFrame(plot)
	local toUpdate = plot:FindFirstChild("ToUpdate")
	local pen = toUpdate and toUpdate:FindFirstChild("StarterPen")
	assert(pen, plot:GetFullName() .. ".ToUpdate.StarterPen missing")
	local mn, mx, groundY = nil, nil, nil
	for _, part in ipairs(pen:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local p = part.CFrame.Position
			mn = if mn then Vector3.new(math.min(mn.X, p.X), 0, math.min(mn.Z, p.Z)) else p
			mx = if mx then Vector3.new(math.max(mx.X, p.X), 0, math.max(mx.Z, p.Z)) else p
			local bottom = p.Y - part.Size.Y / 2
			groundY = if groundY then math.min(groundY, bottom) else bottom
		end
	end
	assert(mn and mx, plot:GetFullName() .. ": StarterPen has no visible parts")
	groundY = tonumber(plot:GetAttribute("TreadmillFloorY")) or groundY
	local cx, cz = (mn.X + mx.X) / 2, (mn.Z + mx.Z) / 2
	local gate = pen:FindFirstChild("GridCenter", true)
	assert(gate and gate:IsA("BasePart"), plot:GetFullName() .. ": StarterPen.GridCenter missing")
	local gx, gz = gate.CFrame.Position.X - cx, gate.CFrame.Position.Z - cz
	local dx, dz = 0, 0
	if math.abs(gx) >= math.abs(gz) then
		dx = if gx >= 0 then 1 else -1
	else
		dz = if gz >= 0 then 1 else -1
	end
	-- CFrame.Angles(0, a, 0) sends (dx, 0, dz) to (0, 0, -1) for a = atan2(dx, -dz)
	local yaw = math.atan2(dx, -dz)
	return CFrame.Angles(0, yaw, 0) * CFrame.new(-cx, -groundY, -cz), Vector3.new(cx, groundY, cz)
end

local function newSlab(parent, name, size, position, color, studs)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if studs then
		part.Material = Enum.Material.Plastic
		part.MaterialVariant = "Studs"
	else
		part.Material = Enum.Material.SmoothPlastic
	end
	part.Parent = parent
	return part
end

-- Toy diorama tile under the plot: studded grass top, a dirt band and a darker rock foot, each a step narrower.
local function buildDiorama(parent, mn, mx)
	local model = Instance.new("Model")
	model.Name = Step.DIORAMA_NAME
	model.Parent = parent
	local margin = 1.5
	local w, d = (mx.X - mn.X) + 2 * margin, (mx.Z - mn.Z) + 2 * margin
	local cx, cz = (mn.X + mx.X) / 2, (mn.Z + mx.Z) / 2
	newSlab(model, "Grass", Vector3.new(w, 0.8, d), Vector3.new(cx, -0.4, cz), hex("#58c742"), true)
	newSlab(model, "GrassLip", Vector3.new(w + 0.5, 0.35, d + 0.5), Vector3.new(cx, -0.975, cz), hex("#3f9e2e"), false)
	newSlab(model, "Dirt", Vector3.new(w - 0.6, 1.8, d - 0.6), Vector3.new(cx, -2.05, cz), hex("#8b5a2b"), true)
	newSlab(model, "Rock", Vector3.new(w - 2, 1.2, d - 2), Vector3.new(cx, -3.55, cz), hex("#5d5f6e"), true)
	writePivot(model, CFrame.new(cx, 0, cz))
	return model
end

---------------------------------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------------------------------

function Step.Apply(place, _spPlace, _ctx)
	local ws = place:GetService("Workspace")
	local rs = place:GetService("ReplicatedStorage")
	local ss = place:GetService("ServerStorage")
	local plots = ws:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild(Step.REFERENCE_PLOT)
	local assets = rs:FindFirstChild("Assets")
	local previews = assets and assets:FindFirstChild(Step.PREVIEW_FOLDER)
	local store = ss:FindFirstChild(Step.STORE_FOLDER)
	if not (plot and previews) then
		log("skipped: Workspace.Plots.%s or ReplicatedStorage.Assets.%s missing", Step.REFERENCE_PLOT, Step.PREVIEW_FOLDER)
		return
	end
	local okDir, directory = pcall(loadDirectory)
	if not okDir or type(directory) ~= "table" then
		log("Directory.BaseThemes did not load (%s): fences keep the plot's colours", tostring(directory))
		directory = nil
	end
	local cam = readCamera()
	local toPreview = penFrame(plot)
	local order = directory and directory.Order or {}
	if #order == 0 then
		for _, child in ipairs(previews:GetChildren()) do
			table.insert(order, child.Name)
		end
	end
	local done, kept = {}, {}
	for _, key in ipairs(order) do
		local preview = previews:FindFirstChild(key)
		local themeModel = store and store:FindFirstChild(key) and store[key]:FindFirstChild(Step.REFERENCE_PLOT)
		if preview == nil or themeModel == nil then
			table.insert(kept, key)
			continue
		end
		local theme = directory and directory.Themes and directory.Themes[key]
		local hides = themeModel:GetAttribute("HidesPenFence") == true

		-- fresh content, built next to the old preview, swapped in only when complete (a failure keeps the old one)
		local staging = Instance.new("Model")
		staging.Name = "__staging_" .. key
		staging.Parent = previews -- inside the place DOM before anything moves in (Lune drops cross-DOM refs)
		local okBuild, result = pcall(function()
			local plotClone = plot:Clone()
			plotClone.Parent = staging
			plotClone.Name = Step.PLOT_NAME
			local dressed = dressPen(plotClone, theme, hides)
			local stripped = sanitize(plotClone, true, true)
			transform(plotClone, toPreview)

			local themeClone = themeModel:Clone()
			themeClone.Parent = staging
			sanitize(themeClone, false, false)
			transform(themeClone, toPreview)
			for _, child in ipairs(themeClone:GetChildren()) do
				child.Parent = staging
			end
			themeClone:Destroy()

			local mn, mx = measure(staging)
			assert(mn and mx, "the preview has no visible parts")
			buildDiorama(staging, mn, mx)
			local bmin, bmax, points = measure(staging)
			local fit = solveFit(points, cam, (bmin + bmax) / 2)
			scaleAbout(staging, fit.k)
			transform(staging, CFrame.new(fit.dx, fit.dy, fit.dz))
			writePivot(staging, CFrame.new())
			return { fit = fit, dressed = dressed, stripped = stripped }
		end)
		if not okBuild then
			staging:Destroy()
			table.insert(kept, key .. " (" .. tostring(result) .. ")")
			continue
		end
		local fit, dressed, stripped = result.fit, result.dressed, result.stripped

		-- swap: the preview Model keeps its identity and attributes (ThemeName) + the per-plot model's attributes
		for _, child in ipairs(preview:GetChildren()) do
			child:Destroy()
		end
		for _, child in ipairs(staging:GetChildren()) do
			child.Parent = preview
		end
		staging:Destroy()
		for name, value in pairs(themeModel:GetAttributes()) do
			preview:SetAttribute(name, value)
		end
		preview:SetAttribute("PreviewPlot", Step.REFERENCE_PLOT)
		preview:SetAttribute("PreviewScale", math.floor(fit.k * 1000 + 0.5) / 1000)
		writePivot(preview, CFrame.new())
		local parts = 0
		for _, d in ipairs(preview:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		table.insert(done, string.format("%s(%d parts, fence %s %d, scale %.3f, shift %.1f/%.1f/%.1f, margin %.2f, %d stripped)", key, parts,
			if hides then "hidden" else "recoloured", dressed, fit.k, fit.dx, fit.dy, fit.dz, fit.margin, stripped))
	end
	assertNoNeon(previews)
	log("Index STAGE BASES previews rebuilt from Workspace.Plots.%s (current plot + its themed props, toy diorama, framed for GUI.BaseThemes' camera): %s",
		Step.REFERENCE_PLOT, table.concat(done, ", "))
	log("no-neon guard: previews hold 0 Neon parts and 0 lights")
	if #kept > 0 then
		log("kept the old preview (no per-plot themed props for plot %s, or the rebuild failed): %s", Step.REFERENCE_PLOT, table.concat(kept, ", "))
	end
end

return Step
