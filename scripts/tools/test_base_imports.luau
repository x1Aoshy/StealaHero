--!nocheck
-- scripts/tools/test_base_imports.luau
-- Offline tests for the Blender-modelled base themes (scripts/tools/blender/base_themes -> FBX -> Studio "Import 3D" ->
-- assets/models/bases/<Key>/<Name>.rbxm -> scripts/steps/post_zz_base_themes.luau section 4). Run from the repo root:
--
--   lune run scripts/tools/test_base_imports.luau obstacles <build.rbxl> [out.json]
--       Every plot's pen geometry and the boxes the props may not touch (functional parts, other plots, world), in the
--       pen frame (x = v, y = u, z = h, like the Blender scripts), with no margin, over the pen zone AND the landmark
--       zone behind the back fence (Step.plotZone: 24 studs behind it, 2 past the sides). Default output:
--       scripts/tools/blender/base_themes/plot_obstacles.json (run.py checks every theme's pieces against it).
--   lune run scripts/tools/test_base_imports.luau fake <outRoot> [Forest,Lake,...] [layoutsRoot]
--       Synthetic "Studio imports" of the themes' layouts (default: every theme with a layout JSON under layoutsRoot,
--       default assets/models/bases): one MeshPart per
--       object sized to the object's bounds, transformed the way an unknown importer might (90-degree yaw, x0.28
--       scale, an offset, 90-degree per-part orientations, ".001" name suffixes, SurfaceAppearance children, a stray
--       PointLight, a Neon part colour), stamped with the layout's geometry fingerprint like BaseThemesImport.lua does,
--       written with the layout to
--       <outRoot>/<Key>/<Name>.rbxm + .json.
--   lune run scripts/tools/test_base_imports.luau verify <build.rbxl> [Forest,Lake,...]
--       Checks a build made with STEALAHERO_BASE_IMPORTS=<outRoot>: per plot and theme, the variant used, the worst
--       placement error of every imported part against the layout, the flags, and that no backdrop is left anywhere
--       (owner 2026-09-24: the plots stay open), no Neon part and no light in any base (owner 2026-09-25), and every
--       landmark part (Lake / Desert / Jungle) inside its zone. Only layouts of the current format (Step.IMPORT_FORMAT,
--       API v3) count.
--   lune run scripts/tools/test_base_imports.luau stale <scratchDir> [assetsRoot]
--       The stale-import rules (post_zz_base_themes section 6) on the owner's REAL imports (<assetsRoot>/<Key>/<Name>.rbxm,
--       default assets/models/bases) and copies of their layouts: the import as it is loads; a palette / light-only
--       change of the layout keeps it; a geometry change (one piece moved) rejects it with "re-import <Name>.fbx"; a
--       stamp equal to the layout's fingerprint loads, any other stamp is rejected; an unstamped import of an unknown
--       name is rejected. Exit 1 on a failed rule.
--   lune run scripts/tools/test_base_imports.luau all <scratchDir> [Forest,Lake,...] [layoutsRoot]
--       fake + build (STEALAHERO_BASE_IMPORTS=<scratchDir>/imports, STEALAHERO_OUT=<scratchDir>/build.rbxl) + verify.
-- Exit code 1 when a verify finds a problem.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Step = require("../steps/post_zz_base_themes")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

local ROOT = "assets/models/bases"
local OBSTACLES_OUT = "scripts/tools/blender/base_themes/plot_obstacles.json"
local GROUND_Y = 2.05

local function round(x)
	return math.floor(x * 1000 + 0.5) / 1000
end

local function split(csv)
	local out = {}
	for item in string.gmatch(csv or "", "[^,%s]+") do
		table.insert(out, item)
	end
	return out
end

-- The theme layouts (format Step.IMPORT_FORMAT) under `root`: { [key] = { layout, path } }.
local function layouts(root, keys)
	local out = {}
	local wanted = nil
	if keys and #keys > 0 then
		wanted = {}
		for _, k in ipairs(keys) do
			wanted[k] = true
		end
	end
	for _, key in ipairs(fs.isDir(root) and fs.readDir(root) or {}) do
		if fs.isDir(root .. "/" .. key) and (wanted == nil or wanted[key]) then
			local layout, path = Step.findLayout(root, key)
			if layout then
				out[key] = { layout = layout, path = path }
			end
		end
	end
	return out
end

-- pen-frame box {v,u,h} min / max of a world AABB
local function penBox(frame, mn, mx)
	local a = Vector3.new(math.huge, math.huge, math.huge)
	local b = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, x in ipairs({ mn.X, mx.X }) do
		for _, y in ipairs({ mn.Y, mx.Y }) do
			for _, z in ipairs({ mn.Z, mx.Z }) do
				local p = frame:PointToObjectSpace(Vector3.new(x, y, z))
				local q = Vector3.new(p.X, -p.Z, p.Y)
				a, b = a:Min(q), b:Max(q)
			end
		end
	end
	return a, b
end

---------------------------------------------------------------------------------------------------
-- obstacles
---------------------------------------------------------------------------------------------------

local function cmdObstacles(placePath, outPath)
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local m = Step.OBSTACLE_MARGIN
	local report = {
		source = placePath,
		note = "pen frame x = v (right, looking out of the gate), y = u (toward the gate), z = h (above the pen ground); boxes without margin",
		zone = { back = Step.BACK_MAX, side = Step.SIDE_MAX, front = Step.FRONT_MAX, top = Step.TOP_MAX,
			landmark = { near = Step.LANDMARK.near, back = Step.LANDMARK.back, side = Step.LANDMARK.side, top = Step.LANDMARK.top } },
		plots = {},
	}
	for _, entry in ipairs(Step.measurePlots(place, GROUND_Y)) do
		local geo = entry.geo
		local boxes = {}
		for _, box in ipairs(entry.obstacles) do
			local mn, mx = penBox(geo.frame, box[1] + Vector3.new(m, m, m), box[2] - Vector3.new(m, m, m))
			local label = string.gsub(box[3], "^Workspace%.", "")
			table.insert(boxes, { label, { round(mn.X), round(mn.Y), round(mn.Z) }, { round(mx.X), round(mx.Y), round(mx.Z) } })
		end
		local sign = entry.plot:FindFirstChild("PlotUpgrade") and entry.plot.PlotUpgrade:FindFirstChild("Sign")
		local signAt = nil
		if sign and sign:IsA("BasePart") then
			local p = geo.frame:PointToObjectSpace(sign.CFrame.Position)
			signAt = { round(p.X), round(-p.Z), round(p.Y) }
		end
		table.insert(report.plots, {
			plot = entry.plot.Name,
			half_depth = round(geo.D),
			half_width = round(geo.W),
			gate_half = round(geo.g),
			gate_v = round(geo.gv),
			sign = signAt,
			obstacles = boxes,
		})
		print(string.format("plot %s: D %.2f W %.2f gate %.2f at v %.2f, sign %s, %d obstacle boxes in the zone", entry.plot.Name,
			geo.D, geo.W, geo.g, geo.gv, signAt and string.format("v %.2f u %.2f h %.2f", signAt[1], signAt[2], signAt[3]) or "none", #boxes))
	end
	fs.writeFile(outPath, serde.encode("json", report, true))
	print("wrote " .. outPath)
end

---------------------------------------------------------------------------------------------------
-- fake imports
---------------------------------------------------------------------------------------------------

local FAKE_IMPORTER = CFrame.new(100, 5, -40) * CFrame.Angles(0, math.rad(90), 0)
local FAKE_SCALE = 0.28
-- per-part orientations an importer may leave (Blender's FBX nodes carry the -90 degree X axis conversion); the part's
-- Size is in its own axes, so its world box stays the object's bounds
local FAKE_PART_ROTS = { CFrame.new(), CFrame.Angles(-math.pi / 2, 0, 0), CFrame.Angles(0, math.pi / 2, 0) }

local function cmdFake(outRoot, keys, layoutsRoot)
	local found = layouts(layoutsRoot or ROOT, keys)
	local made = 0
	for key, entry in pairs(found) do
		local layout = entry.layout
		local model = Instance.new("Model")
		model.Name = layout.name
		-- BaseThemesImport.lua stamps the geometry the import was made from (post_zz_base_themes section 6)
		model:SetAttribute("GeometryFingerprint", Step.geometryFingerprint(layout))
		local parts = 0
		for _, vname in ipairs(layout.variant_order) do
			local variant = layout.variants[vname]
			for role, b in pairs(variant.object_bounds) do
				local mn, mx = b[1], b[2] -- pen frame x = v, y = u, z = h
				-- Roblox axes after the FBX export (-Z forward, Y up): X = v, Y = h, Z = -u
				local centre = Vector3.new((mn[1] + mx[1]) / 2, (mn[3] + mx[3]) / 2, -(mn[2] + mx[2]) / 2)
				local size = Vector3.new(math.max(mx[1] - mn[1], 0.01), math.max(mx[3] - mn[3], 0.01), math.max(mx[2] - mn[2], 0.01))
				local rot = FAKE_PART_ROTS[parts % #FAKE_PART_ROTS + 1]
				local own = rot:VectorToObjectSpace(size)
				local part = Instance.new("MeshPart")
				part.Name = variant.prefix .. role .. ".001"
				part.Size = Vector3.new(math.abs(own.X), math.abs(own.Y), math.abs(own.Z)) * FAKE_SCALE
				part.CFrame = FAKE_IMPORTER * CFrame.new(centre * FAKE_SCALE) * rot
				local look = Instance.new("SurfaceAppearance")
				look.Parent = part
				if parts == 0 then
					-- importer / old-helper leftovers the loader must never keep: a light and a Neon material
					local light = Instance.new("PointLight")
					light.Parent = part
					part.Material = roblox.Enum.Material.Neon
				end
				part.Parent = model
				parts += 1
			end
		end
		-- importer noise the loader must ignore: a part of no role, a part of no variant
		for _, name in ipairs({ layout.variants[layout.variant_order[1]].prefix .. "Unknown.001", "Handle" }) do
			local extra = Instance.new("Part")
			extra.Name = name
			extra.Size = Vector3.new(1, 1, 1)
			extra.CFrame = FAKE_IMPORTER
			extra.Parent = model
		end
		local dir = outRoot .. "/" .. key
		if not fs.isDir(dir) then
			fs.writeDir(dir)
		end
		fs.writeFile(dir .. "/" .. layout.import, roblox.serializeModel({ model }))
		fs.writeFile(dir .. "/" .. layout.name .. ".json", fs.readFile(entry.path))
		print(string.format("fake import %s/%s (%d MeshParts, x%.2f, 90-degree yaw)", key, layout.import, parts, FAKE_SCALE))
		made += 1
	end
	if made == 0 then
		print("!! no theme layouts found under " .. (layoutsRoot or ROOT))
	end
	return made
end

---------------------------------------------------------------------------------------------------
-- verify
---------------------------------------------------------------------------------------------------

local function aabb(part)
	local cf, s = part.CFrame, part.Size
	local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, x in ipairs({ -0.5, 0.5 }) do
		for _, y in ipairs({ -0.5, 0.5 }) do
			for _, z in ipairs({ -0.5, 0.5 }) do
				local p = cf * Vector3.new(s.X * x, s.Y * y, s.Z * z)
				mn, mx = mn:Min(p), mx:Max(p)
			end
		end
	end
	return mn, mx
end

-- world AABB of a pen-frame box (x = v, y = u, z = h)
local function expectBox(frame, b)
	local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, v in ipairs({ b[1][1], b[2][1] }) do
		for _, u in ipairs({ b[1][2], b[2][2] }) do
			for _, h in ipairs({ b[1][3], b[2][3] }) do
				local w = frame * Vector3.new(v, h, -u)
				mn, mx = mn:Min(w), mx:Max(w)
			end
		end
	end
	return mn, mx
end

-- worst corner error of the parts of `group` (named Theme<Role>) against the variant's object bounds in `frame`
local function placementError(group, variant, frame, problems, tag)
	local worst, count = 0, 0
	for _, part in ipairs(group and group:GetChildren() or {}) do
		if part:IsA("BasePart") then
			local role = string.sub(part.Name, #Step.PREFIX + 1)
			local bounds = variant.object_bounds[role]
			if bounds == nil then
				table.insert(problems, tag .. ": unexpected part " .. part.Name)
			else
				local a, b = aabb(part)
				local ea, eb = expectBox(frame, bounds)
				worst = math.max(worst, (a - ea).Magnitude, (b - eb).Magnitude)
			end
			if part.Anchored ~= true or part.CanCollide or part.CanQuery or part.CanTouch then
				table.insert(problems, tag .. ": " .. part.Name .. " is not inert")
			end
			if part.Material == roblox.Enum.Material.Neon then
				table.insert(problems, tag .. ": " .. part.Name .. " is Neon (no neon in the bases, owner 2026-09-25)")
			end
			for _, child in ipairs(part:GetChildren()) do
				local generatedOrigin = child:IsA("Attachment") and child.Name == "SunnyOrigin"
					and part.Parent:HasTag("SunnyWindRig") and part.Name == Step.PREFIX .. "Floor_Base"
				if not generatedOrigin then
					table.insert(problems, tag .. ": " .. part.Name .. " kept importer child " .. child.ClassName)
				end
			end
			count += 1
		end
	end
	return worst, count
end

local function cmdVerify(placePath, keys, importsRoot)
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local found = layouts(importsRoot or ROOT, keys)
	local store = place:FindFirstChild("ServerStorage") and place.ServerStorage:FindFirstChild(Step.SERVER_FOLDER)
	local problems = {}
	local measured = Step.measurePlots(place, GROUND_Y)
	local rows = 0
	for key, entry in pairs(found) do
		local layout = entry.layout
		local folder = store and store:FindFirstChild(key)
		if folder == nil then
			table.insert(problems, key .. ": no ServerStorage.BaseThemes." .. key)
		end
		for _, m in ipairs(measured) do
			local plot, geo = m.plot, m.geo
			local tag = key .. "/" .. plot.Name
			local model = folder and folder:FindFirstChild(plot.Name)
			local pen = model and model:FindFirstChild(Step.PREFIX .. "ImportedPen")
			local vname = pen and pen:GetAttribute("ImportedVariant")
			local variant = vname and layout.variants[vname]
			if model == nil then
				table.insert(problems, tag .. ": no model")
			elseif pen == nil or variant == nil then
				print(string.format("%-12s procedural (HidesPenFence=%s)", tag, tostring(model:GetAttribute("HidesPenFence"))))
				table.insert(problems, tag .. ": no imported pen")
			else
				local penErr, penParts = placementError(pen, variant, geo.frame, problems, tag)
				local backdrops = 0
				for _, g in ipairs(model:GetChildren()) do
					if string.sub(g.Name, 1, #Step.PREFIX + 8) == Step.PREFIX .. "Backdrop" then
						backdrops += 1
					end
				end
				local expected = 0
				for _ in pairs(variant.object_bounds) do
					expected += 1
				end
				print(string.format("%-12s %-5s pen %2d/%2d parts err %.4f | backdrop groups %d | HidesPenFence=%s", tag, vname, penParts,
					expected, penErr, backdrops, tostring(model:GetAttribute("HidesPenFence"))))
				rows += 1
				if penErr > 0.01 then
					table.insert(problems, string.format("%s: placement error %.4f", tag, penErr))
				end
				if penParts ~= expected then
					table.insert(problems, tag .. ": missing imported parts")
				end
				if backdrops > 0 then
					table.insert(problems, tag .. ": a backdrop is left (" .. backdrops .. " group(s))")
				end
				if model:GetAttribute("HidesPenFence") ~= true then
					table.insert(problems, tag .. ": HidesPenFence not set")
				end
				if math.abs(layout.variants[vname].half_depth - geo.D) > 0.5 then
					table.insert(problems, tag .. ": variant " .. vname .. " on a pen of half depth " .. geo.D)
				end
			end
		end
		-- the Index preview: the canonical pen at the origin, or (scripts/steps/ui_80_plot_viewports.luau) a scaled copy of
		-- the reference plot's model: then every imported part must be that plot's part at one uniform scale
		local preview = place.ReplicatedStorage:FindFirstChild("Assets") and place.ReplicatedStorage.Assets:FindFirstChild(Step.PREVIEW_FOLDER)
		local pmodel = preview and preview:FindFirstChild(key)
		local ppen = pmodel and pmodel:FindFirstChild(Step.PREFIX .. "ImportedPen")
		if ppen == nil then
			table.insert(problems, key .. ": the Index preview has no imported pen")
		elseif pmodel:FindFirstChild("PlotPreview") then
			local ref = folder and folder:FindFirstChild("1")
			local refPen = ref and ref:FindFirstChild(Step.PREFIX .. "ImportedPen")
			local ratios, n = {}, 0
			for _, part in ipairs(ppen:GetChildren()) do
				local twin = part:IsA("BasePart") and refPen and refPen:FindFirstChild(part.Name)
				if twin then
					table.insert(ratios, part.Size.Magnitude / math.max(twin.Size.Magnitude, 1e-6))
					n += 1
				end
			end
			local lo, hi = math.huge, -math.huge
			for _, r in ipairs(ratios) do
				lo, hi = math.min(lo, r), math.max(hi, r)
			end
			local expected = refPen and #refPen:GetChildren() or -1
			print(string.format("%-12s rebuilt by ui_80_plot_viewports: %d/%d parts, scale %.3f..%.3f", key .. "/preview", n, expected, lo, hi))
			if n == 0 or n ~= expected or hi - lo > 0.01 * hi then
				table.insert(problems, key .. "/preview: the scaled pen does not match plot 1's")
			end
		else
			local vname = ppen:GetAttribute("ImportedVariant")
			local err = placementError(ppen, layout.variants[vname], CFrame.new(), problems, key .. "/preview")
			local fence = pmodel:FindFirstChild(Step.PREFIX .. "PreviewFence")
			local leftovers = 0
			for _, d in ipairs(fence and fence:GetChildren() or {}) do
				if d.Name ~= Step.PREFIX .. "PreviewGround" then
					leftovers += 1
				end
			end
			print(string.format("%-12s %-5s pen err %.4f, preview fence parts left %d", key .. "/preview", vname, err, leftovers))
			if err > 0.01 or leftovers > 0 then
				table.insert(problems, key .. "/preview: error " .. err .. ", " .. leftovers .. " preview fence parts left")
			end
		end
	end
	-- no Neon part and no light in any base, per-plot models and Index previews alike (owner 2026-09-25)
	for _, root in ipairs({ store, place.ReplicatedStorage:FindFirstChild("Assets") and place.ReplicatedStorage.Assets:FindFirstChild(Step.PREVIEW_FOLDER) }) do
		local neon, lights = 0, 0
		for _, d in ipairs(root and root:GetDescendants() or {}) do
			if d:IsA("BasePart") and d.Material == roblox.Enum.Material.Neon then
				neon += 1
			elseif d:IsA("Light") then
				lights += 1
			end
		end
		print(string.format("%-12s %d Neon part(s), %d light(s)", root and root.Name or "(missing)", neon, lights))
		if neon > 0 or lights > 0 then
			table.insert(problems, string.format("%s: %d Neon part(s), %d light(s) left in the bases", root and root:GetFullName() or "?", neon, lights))
		end
	end
	-- landmark parts (the layout's "landmark" pieces) stay in the landmark zone of their theme
	for key, entry in pairs(found) do
		for _, vname in ipairs(entry.layout.variant_order) do
			local variant = entry.layout.variants[vname]
			local D, W, L = variant.half_depth, variant.half_width, Step.LANDMARK
			for _, piece in ipairs(variant.pieces or {}) do
				if piece[4] == "landmark" then
					local a, b = piece[2], piece[3]
					if not Step.LANDMARK_KEYS[key] or b[2] > -D - L.near + 0.01 or a[2] < -D - L.back - 0.01 or math.abs(a[1]) > W + L.side + 0.01
						or math.abs(b[1]) > W + L.side + 0.01 or b[3] > L.top + 0.01 then
						table.insert(problems, string.format("%s %s: landmark piece %s outside the landmark zone", key, vname, piece[1]))
					end
				end
			end
		end
	end
	-- no backdrop anywhere (procedural or modelled), on any theme
	for _, folder in ipairs(store and store:GetChildren() or {}) do
		for _, model in ipairs(folder:GetChildren()) do
			for _, g in ipairs(model:GetChildren()) do
				if string.sub(g.Name, 1, #Step.PREFIX + 8) == Step.PREFIX .. "Backdrop" then
					table.insert(problems, folder.Name .. "/" .. model.Name .. ": backdrop group " .. g.Name)
					break
				end
			end
		end
	end
	print(string.format("verified %d plot pens of %d theme(s), %d problem(s)", rows, (function()
		local n = 0
		for _ in pairs(found) do
			n += 1
		end
		return n
	end)(), #problems))
	for _, p in ipairs(problems) do
		print("  !! " .. p)
	end
	return #problems == 0
end

---------------------------------------------------------------------------------------------------
-- stale-import rules (post_zz_base_themes section 6)
---------------------------------------------------------------------------------------------------

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = deepCopy(v)
	end
	return out
end

local function cmdStale(dir, assetsRoot)
	assetsRoot = assetsRoot or ROOT
	local failures, checks = {}, 0
	local function expect(label, ok, why, wantOk, wantText)
		checks += 1
		local pass = (ok == wantOk) and (wantText == nil or (why ~= nil and string.find(why, wantText, 1, true) ~= nil))
		print(string.format("  %s %-58s -> %s", if pass then "ok" else "!!", label, tostring(why)))
		if not pass then
			table.insert(failures, label)
		end
	end
	local savedRoot = Step.IMPORTS_ROOT
	for key, entry in pairs(layouts(assetsRoot, nil)) do
		local layout = entry.layout
		local rbxm = assetsRoot .. "/" .. key .. "/" .. tostring(layout.import)
		if not fs.isFile(rbxm) then
			print(string.format("%s: no import (%s), skipped", key, rbxm))
			continue
		end
		local roots = roblox.deserializeModel(fs.readFile(rbxm))
		local stamp = roots[1] and roots[1]:GetAttribute("GeometryFingerprint")
		print(string.format("%s (%s, %s): layout geometry %s", key, layout.name, if stamp then "stamped " .. stamp else "unstamped",
			Step.geometryFingerprint(layout)))
		-- 1. the import as it is
		Step.IMPORTS_ROOT = assetsRoot
		local theme, why = Step.loadImportedTheme(key, layout)
		checks += 1
		print(string.format("  %s %-58s -> %s", if theme then "ok" else "..", "the import as it is (current layout)", if theme then tostring(theme.geometry) else tostring(why)))
		local caseDir = dir .. "/" .. key
		if not fs.isDir(caseDir) then
			fs.writeDir(caseDir)
		end
		fs.writeFile(caseDir .. "/" .. tostring(layout.import), fs.readFile(rbxm))
		Step.IMPORTS_ROOT = dir
		-- 2. a palette / light-only change keeps an import that loads
		local recolour = deepCopy(layout)
		for _, look in pairs(recolour.palette) do
			look.rgb = { 10, 200, 30 }
			look.material = "Plastic"
		end
		for _, vname in ipairs(recolour.variant_order) do
			recolour.variants[vname].lights = { { 0, 0, 3, 12, 1, { 255, 0, 0 } } }
		end
		local ok2, why2 = Step.importIsCurrent(recolour, roots)
		expect("palette + lights changed: import stays valid", ok2, why2, theme ~= nil)
		if theme then
			local t2 = Step.loadImportedTheme(key, recolour)
			expect("palette + lights changed: the pen loads", t2 ~= nil, t2 and "loads" or "rejected", true)
		end
		-- 3. a geometry change (one piece moved 0.5 studs, bounds untouched) makes the import stale
		local moved = deepCopy(layout)
		local piece = moved.variants[moved.variant_order[1]].pieces[1]
		piece[2][3] += 0.5
		piece[3][3] += 0.5
		local t3, why3 = Step.loadImportedTheme(key, moved)
		expect("geometry changed: stale, re-import", t3 ~= nil, why3, false, "re-import " .. tostring(layout.fbx))
		-- 4. stamps: the layout's own fingerprint loads, another one is stale
		local ok4 = Step.importIsCurrent(layout, { { GetAttribute = function()
			return Step.geometryFingerprint(layout)
		end } })
		expect("stamped with the layout's fingerprint: current", ok4, "stamp = layout", true)
		local ok5, why5 = Step.importIsCurrent(layout, { { GetAttribute = function()
			return "g1:000000000000000000000000"
		end } })
		expect("stamped with another fingerprint: stale", ok5, why5, false, "re-import")
		-- 5. an unstamped import of a name the pre-stamp table does not know is stale
		local renamed = deepCopy(layout)
		renamed.name = layout.name .. "Renamed"
		local ok6, why6 = Step.importIsCurrent(renamed, { { GetAttribute = function()
			return nil
		end } })
		expect("unstamped import of an unknown name: stale", ok6, why6, false, "re-import")
	end
	Step.IMPORTS_ROOT = savedRoot
	print(string.format("stale-import rules: %d check(s), %d failure(s)", checks, #failures))
	return #failures == 0
end

---------------------------------------------------------------------------------------------------
-- main
---------------------------------------------------------------------------------------------------

local args = process.args
local cmd = args[1]
if cmd == "obstacles" and args[2] then
	cmdObstacles(args[2], args[3] or OBSTACLES_OUT)
elseif cmd == "fake" and args[2] then
	cmdFake(args[2], split(args[3]), args[4])
elseif cmd == "verify" and args[2] then
	if not cmdVerify(args[2], split(args[3]), process.env.STEALAHERO_BASE_IMPORTS) then
		process.exit(1)
	end
elseif cmd == "stale" and args[2] then
	if not fs.isDir(args[2]) then
		fs.writeDir(args[2])
	end
	if not cmdStale(args[2], args[3]) then
		process.exit(1)
	end
elseif cmd == "all" and args[2] then
	local dir = args[2]
	local imports = dir .. "/imports"
	if not fs.isDir(dir) then
		fs.writeDir(dir)
	end
	if cmdFake(imports, split(args[3]), args[4]) == 0 then
		process.exit(1)
	end
	local out = dir .. "/build.rbxl"
	print("building " .. out .. " with STEALAHERO_BASE_IMPORTS=" .. imports .. " ...")
	local env = table.clone(process.env)
	env.STEALAHERO_BASE_IMPORTS = imports
	env.STEALAHERO_OUT = out
	-- STEALAHERO_LUNE = the lune executable when it is not on PATH
	local result = process.exec(process.env.STEALAHERO_LUNE or "lune", { "run", "scripts/build_stealahero.luau" }, { env = env })
	fs.writeFile(dir .. "/build.log", result.stdout .. result.stderr)
	for line in string.gmatch(result.stdout, "[^\n]+") do
		if string.find(line, "[base_themes]", 1, true) then
			print(line)
		end
	end
	if not result.ok then
		print("!! the build failed, see " .. dir .. "/build.log")
		process.exit(1)
	end
	if not cmdVerify(out, split(args[3]), imports) then
		process.exit(1)
	end
else
	print("usage: lune run scripts/tools/test_base_imports.luau obstacles <build.rbxl> [out.json] | fake <outRoot> [keys]"
		.. " | verify <build.rbxl> [keys] | all <scratchDir> [keys] | stale <scratchDir> [assetsRoot]")
	process.exit(2)
end
