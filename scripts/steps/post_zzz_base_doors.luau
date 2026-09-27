--!nocheck
-- scripts/steps/post_zzz_base_doors.luau
-- Build step (owner 2026-09-26: "make sure the doors open ... for all the bases ... when you go up" + "add some vfx to
-- the bases for each one, something related to their theme"). Runs after post_zz_base_themes ("zzz" sorts after
-- "zz_"), so the themed per-plot models in ServerStorage.BaseThemes exist.
--
-- The doors and the theme VFX are made on each CLIENT at runtime (StarterPlayerScripts.Game.Plots.BaseDoorController /
-- BaseThemeVfxController, modules ReplicatedStorage.Library.Modules.BaseDoors / BaseThemeVfx): the stored theme
-- models stay exactly the layouts' parts (inert, no extra children). This step only writes the data they need, as
-- attributes on every Workspace.Plots.<n>:
--   GateOrigin / GateOutward / GateRight (Vector3)  the StarterPen gate centre on the floor + the gate frame axes
--   GateHalfWidth (number)                          half the StarterPen gate (post centre to post centre)
--   PenOrigin (Vector3), PenHalfDepth, PenHalfWidth  the pen frame (post_zz_base_themes Step.measurePen)
--   DoorGeometry_<Key> (string)                     the clear opening of each look (6 theme keys + "None"), see
--                                                   BaseDoors.FormatGeometry: measured from the plot's modelled pen
--                                                   (the layout JSON pieces of the variant the plot uses; the part
--                                                   boxes of a procedural theme), BaseDoors.DefaultGeometry otherwise.
-- Measuring (gate frame: v across from the gate centre, u outward from the fence line, h up): the pieces standing in
-- the gate band (u -0.8 .. 3, above the floor details, |v| < 9); the opening's sides are the closest pieces left /
-- right of the centre that reach below 7.4; the lintel is the lowest piece over the opening (open sky: 7.5); each pylon
-- is the run of pieces (>= 2 studs tall, reaching up to about the lintel) flush with an opening side, at most 3.5 studs
-- wide (the upgrade terminal beside a pylon is lower, so it never counts).

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Themes = require("./post_zz_base_themes")

local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

local Step = {}

Step.MODULE_SOURCE = "src/ReplicatedStorage/Library/Modules/BaseDoors.luau"
Step.BAND = { -0.8, 3.0 } -- u range of the gate band
Step.FLOOR_TOP = 0.35 -- floor inlays / details stay under this
Step.CLEAR = 7.4 -- the opening's sides: what stands below this height
Step.REACH = 9 -- |v| limit of the pieces that count
Step.TALL_PIECE = 2 -- a pylon piece is at least this tall (glass panes / trims are not)
Step.PYLON_MAX = 3.5 -- a pylon is at most this wide
Step.OPEN_SKY = 7.5 -- lintel height when nothing spans the opening

local log = function(fmt, ...)
	print(string.format("[base_doors] " .. fmt, ...))
end

-- ReplicatedStorage.Library.Modules.BaseDoors, loaded with Lune (format + defaults shared with the client).
function Step.loadDoors()
	local env = setmetatable({
		Instance = roblox.Instance,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrame,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		typeof = typeof,
	}, { __index = _G })
	return luau.load(fs.readFile(Step.MODULE_SOURCE), { debugName = Step.MODULE_SOURCE, environment = env })()
end

-- boxes: { { vMin, vMax, uMin, uMax, hMin, hMax }, ... } in the gate frame. Returns the geometry table or nil, why.
function Step.measureOpening(boxes)
	local band = {}
	for _, b in ipairs(boxes) do
		if b[4] > Step.BAND[1] and b[3] < Step.BAND[2] and b[6] > Step.FLOOR_TOP and b[1] < Step.REACH and b[2] > -Step.REACH then
			table.insert(band, b)
		end
	end
	local vMin, vMax = -math.huge, math.huge
	for _, b in ipairs(band) do
		if b[5] < Step.CLEAR then
			if b[2] <= 0.05 then
				vMin = math.max(vMin, b[2])
			elseif b[1] >= -0.05 then
				vMax = math.min(vMax, b[1])
			end
		end
	end
	if vMin == -math.huge or vMax == math.huge then
		return nil, "no pylon on one side"
	end
	if vMax - vMin < 5 or vMax - vMin > 14 then
		return nil, string.format("implausible opening %.2f..%.2f", vMin, vMax)
	end
	local top = math.huge
	for _, b in ipairs(band) do
		if b[2] > vMin + 0.05 and b[1] < vMax - 0.05 and b[5] > 1 then
			top = math.min(top, b[5])
		end
	end
	if top == math.huge then
		top = Step.OPEN_SKY
	end
	local uMin, uMax = math.huge, -math.huge
	-- a pylon piece reaches up to (about) the lintel: the upgrade terminal next to a pylon stops lower
	local reach = math.min(top, Step.CLEAR) - 0.5
	local function pylon(sign, edge)
		local outer = edge
		local used = {}
		local grown = true
		while grown do
			grown = false
			for i, b in ipairs(band) do
				if not used[i] and b[5] < Step.CLEAR and b[6] >= reach and b[6] - b[5] >= Step.TALL_PIECE then
					local fits, touches
					if sign < 0 then
						fits = b[2] <= edge + 0.05 and b[1] >= edge - Step.PYLON_MAX
						touches = b[2] >= outer - 0.35
					else
						fits = b[1] >= edge - 0.05 and b[2] <= edge + Step.PYLON_MAX
						touches = b[1] <= outer + 0.35
					end
					if fits and touches then
						used[i] = true
						outer = if sign < 0 then math.min(outer, b[1]) else math.max(outer, b[2])
						uMin, uMax = math.min(uMin, b[3]), math.max(uMax, b[4])
						grown = true
					end
				end
			end
		end
		return math.abs(outer - edge)
	end
	local wLeft, wRight = pylon(-1, vMin), pylon(1, vMax)
	if uMin == math.huge then
		uMin, uMax = -0.6, 1.6
	end
	return { vMin = vMin, vMax = vMax, top = top, wLeft = wLeft, wRight = wRight, uMin = uMin, uMax = uMax }
end

-- The layout pieces of `variant` as gate-frame boxes (the modelled gate is the layout's v = 0, u = half_depth).
function Step.layoutBoxes(layout, variantName)
	local variant = layout and layout.variants and layout.variants[variantName]
	if type(variant) ~= "table" or type(variant.pieces) ~= "table" then
		return nil
	end
	local D = variant.half_depth
	local boxes = {}
	for _, piece in ipairs(variant.pieces) do
		local mn, mx = piece[2], piece[3]
		if type(mn) == "table" and type(mx) == "table" then
			table.insert(boxes, { mn[1], mx[1], mn[2] - D, mx[2] - D, mn[3], mx[3] })
		end
	end
	return boxes
end

-- Every BasePart of a procedural theme model (floor group excluded) as gate-frame boxes.
function Step.partBoxes(model, frame, gv, D, groundY)
	local boxes = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and string.sub(d.Name, 1, 10) ~= "ThemeFloor" and d:FindFirstAncestor("ThemeImportedPen") == nil then
			local cf, size = d.CFrame, d.Size
			local lo = Vector3.new(math.huge, math.huge, math.huge)
			local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
			for _, sx in ipairs({ -0.5, 0.5 }) do
				for _, sy in ipairs({ -0.5, 0.5 }) do
					for _, sz in ipairs({ -0.5, 0.5 }) do
						local p = frame:PointToObjectSpace(cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz))
						lo, hi = lo:Min(p), hi:Max(p)
					end
				end
			end
			-- frame: x = v, y = h (from groundY), z = -u (from the pen centre)
			table.insert(boxes, { lo.X - gv, hi.X - gv, -hi.Z - D, -lo.Z - D, lo.Y, hi.Y })
		end
	end
	return boxes
end

function Step.Apply(place, _spPlace, ctx)
	local ws = place:GetService("Workspace")
	local serverStorage = place:GetService("ServerStorage")
	local groundY = (ctx and ctx.groundY) or 2.05
	local plots = ws:FindFirstChild("Plots")
	assert(plots, "Workspace.Plots missing")
	local Doors = Step.loadDoors()
	local directory = Themes.loadDirectory()
	local store = serverStorage:FindFirstChild(Themes.SERVER_FOLDER)
	local A = Doors.ATTR

	local layouts = {}
	for _, key in ipairs(directory.Order) do
		local layout = Themes.findLayout(Themes.IMPORTS_ROOT, key)
		if layout then
			layouts[key] = layout
		end
	end

	local done, summary, fallbacks = 0, {}, {}
	local plotList = {}
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:IsA("Model") and tonumber(plot.Name) then
			table.insert(plotList, plot)
		end
	end
	table.sort(plotList, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	for _, plot in ipairs(plotList) do
		local geo = Themes.measurePen(plot, groundY)
		if not geo then
			log("!! plot %s: no StarterPen posts / GridCenter, no door data", plot.Name)
			continue
		end
		local frame = geo.frame
		local gate = frame * Vector3.new(geo.gv, 0, -geo.D)
		plot:SetAttribute(A.Origin, gate)
		plot:SetAttribute(A.Outward, frame.LookVector)
		plot:SetAttribute(A.Right, frame.RightVector)
		plot:SetAttribute(A.HalfWidth, geo.g)
		plot:SetAttribute(A.PenOrigin, frame.Position)
		plot:SetAttribute(A.PenHalfDepth, geo.D)
		plot:SetAttribute(A.PenHalfWidth, geo.W)

		-- the plain pen: the gate posts (1.2 studs, post_hub_remodel) at +-GateHalfWidth, the gate as tall as the posts
		local post = 1.2
		local none = { vMin = -(geo.g - post / 2), vMax = geo.g - post / 2, top = 4.2, wLeft = post, wRight = post, uMin = -post / 2, uMax = post / 2 }
		plot:SetAttribute(A.GeometryPrefix .. Doors.NONE, Doors.FormatGeometry(none))

		local keys = {}
		for _, key in ipairs(directory.Order) do
			local model = store and store:FindFirstChild(key)
			model = model and model:FindFirstChild(plot.Name)
			local boxes, source = nil, "default"
			if model and model:GetAttribute("HidesPenFence") == true and layouts[key] then
				local variant = model:GetAttribute("ImportedVariant")
				-- the modelled gate is the layout's v = 0: shift so the numbers are relative to the StarterPen gate
				boxes = Step.layoutBoxes(layouts[key], variant)
				if boxes then
					for _, b in ipairs(boxes) do
						b[1] -= geo.gv
						b[2] -= geo.gv
					end
					source = tostring(variant)
				end
			elseif model then
				boxes = Step.partBoxes(model, frame, geo.gv, geo.D, groundY)
				source = "parts"
			end
			local g, why = nil, "no themed model"
			if boxes then
				g, why = Step.measureOpening(boxes)
			end
			if g == nil then
				g = Doors.DefaultGeometry[key]
				source = "default"
				table.insert(fallbacks, string.format("%s/%s (%s)", key, plot.Name, tostring(why)))
			end
			plot:SetAttribute(A.GeometryPrefix .. key, Doors.FormatGeometry(g))
			table.insert(keys, string.format("%s[%s] %.2f..%.2f h%.2f w%.2f/%.2f u%.2f..%.2f", key, source, g.vMin, g.vMax, g.top,
				g.wLeft, g.wRight, g.uMin, g.uMax))
		end
		done += 1
		table.insert(summary, string.format("plot %s gate (%.2f, %.2f, %.2f) out (%.0f, %.0f): %s", plot.Name, gate.X, gate.Y, gate.Z,
			frame.LookVector.X, frame.LookVector.Z, table.concat(keys, "; ")))
	end
	for _, line in ipairs(summary) do
		log("%s", line)
	end
	if #fallbacks > 0 then
		log("!! %d opening(s) fell back to BaseDoors.DefaultGeometry: %s", #fallbacks, table.concat(fallbacks, ", ", 1, math.min(#fallbacks, 8)))
	end
	log("door + theme VFX data on %d plot(s) (clients build the doors: Game.Plots.BaseDoorController / BaseThemeVfxController)", done)
end

return Step
