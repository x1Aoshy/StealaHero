-- scripts/steps/plots.luau
-- Build step "plots" (owner: ARCHITECT; Phase 3 sign restyle: UI-WORLD). Runs after build_stealahero.luau
-- has shifted the plots to their final world positions:
--   1. PlayerPlotSign on every plot in the Speedsters Escape material (CONTRACTS_PHASE3 D1): white @0.15 card
--      over the Speedsters window art, ink Border stroke + inner highlight, scale corners, circular headshot
--      with a Speedsters cyan ring and an ink rim, GothamSSm Bold name with an ink outline. PlotService fills
--      name + headshot and toggles Enabled at runtime; PlotSignManager asserts the BillboardGui and writes
--      AlwaysOnTop. Kept contract: BillboardGui PlayerPlotSign > Frame (first UIStroke = Border, UICorner) >
--      PlayerName TextLabel + PlayerIcon ImageLabel (circular UICorner, first UIStroke = the ring).
--   2. Unowned plots start at BaseUpgradeLevel 0 (PlotService syncs the owner's level at runtime).
--   3. The hub SpawnLocation is moved out of plot geometry, only if it overlaps a plot.
--
-- Lune notes: FontFace (not Font), the four per-corner UICorner radii (not CornerRadius on an
-- existing corner), ImageContent (not Image) are the only writes that survive serialization. The sign uses
-- the shared kit (scripts/lib/speedsters_ui_kit.luau), which only writes those.

local Plots = {}

-- Speedsters list-row proportion (row.list_item AR 3.6917): 236 x 64 px, constant on screen (offset size).
local SIGN_WIDTH, SIGN_HEIGHT = 236, 64
local SIGN_MAX_DISTANCE = 350
local SIGN_CORNER = 0.25 -- row / pill corner (scale)
local SIGN_BORDER = 0.05 -- ink Border stroke, ScaledSize (about 3 px on the 64 px card)
local SIGN_HIGHLIGHT = 0.03 -- inner white @0.5 stroke (afk.stat_box highlight)
local ICON_SIZE, ICON_X = 48, 9
local RING, RING_RIM = 0.08, 0.13 -- headshot ring / ink rim (ScaledSize of the 48 px icon)
local NAME_STROKE = 0.08

local SPAWN_CLEARANCE = 1 -- studs kept free around the spawn pad
local SPAWN_MAX_X = 70 -- pad edge stays on the hub side of the SeparationLine (X = 72.2)
local SPAWN_CHECK_HEIGHT = 8 -- parts up to this far above the pad count as obstacles
local MARKER_FOOTPRINT = 150 -- huge invisible volumes (Ground, walls, lines) are not obstacles

local function worldAabb(part, Vector3)
	local cf, size = part.CFrame, part.Size
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, sx in ipairs({ -0.5, 0.5 }) do
		for _, sy in ipairs({ -0.5, 0.5 }) do
			for _, sz in ipairs({ -0.5, 0.5 }) do
				local corner = cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz)
				minV = minV:Min(corner)
				maxV = maxV:Max(corner)
			end
		end
	end
	return minV, maxV
end

local function boxesOverlap(aMin, aMax, bMin, bMax)
	return aMin.X < bMax.X and aMax.X > bMin.X
		and aMin.Y < bMax.Y and aMax.Y > bMin.Y
		and aMin.Z < bMax.Z and aMax.Z > bMin.Z
end

local function styleSigns(plots, ctx)
	local roblox = ctx.roblox
	local Instance, Enum = roblox.Instance, roblox.Enum
	local UDim, UDim2, Vector2 = roblox.UDim, roblox.UDim2, roblox.Vector2
	-- Required here (not at file scope) so a kit problem fails only this sub-step, not the plot attributes
	-- or the hub spawn.
	local Kit = require("../lib/speedsters_ui_kit")
	local ringColor = Kit.Colors.levelFill -- #00eaff, the Speedsters HUD level/speed fill

	-- The name of `parent`'s first UIStroke ("UIStroke" when it has none): tests and older readers take the
	-- first stroke, so the primary stroke is always written on that one.
	local function firstStrokeName(parent)
		local stroke = parent:FindFirstChildOfClass("UIStroke")
		return stroke and stroke.Name or "UIStroke"
	end

	local function ensureNamed(parent, name, className)
		local existing = parent:FindFirstChild(name)
		if existing and existing:IsA(className) then
			return existing
		end
		if existing then
			existing:Destroy() -- wrong class in a broken base place; PlotService needs this class
		end
		local created = Instance.new(className)
		created.Name = name
		created.Parent = parent
		return created
	end

	local styled = 0
	for _, plot in ipairs(plots:GetChildren()) do
		local sign = plot:FindFirstChild("PlotSign")
		local billboard = sign and sign:FindFirstChild("PlayerPlotSign")
		local frame = billboard and billboard:FindFirstChild("Frame")
		if not (billboard and billboard:IsA("BillboardGui") and frame and frame:IsA("Frame")) then
			print(string.format("[plots] Plot %s has no PlotSign.PlayerPlotSign.Frame; sign left as is.", plot.Name))
			continue
		end

		billboard.Size = UDim2.fromOffset(SIGN_WIDTH, SIGN_HEIGHT)
		billboard.MaxDistance = SIGN_MAX_DISTANCE
		billboard.LightInfluence = 0
		billboard.ClipsDescendants = false
		billboard.Enabled = false -- PlotService enables it when the plot gets an owner

		-- Card: white @0.15 over the Speedsters window art, ink Border stroke + inner white highlight.
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Kit.Colors.windowFill
		frame.BackgroundTransparency = Kit.Sizes.window.fillTransparency
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = false
		Kit.setCorner(frame, SIGN_CORNER)
		Kit.addStroke(frame, {
			name = firstStrokeName(frame), color = Kit.Colors.ink, mode = "Border", thickness = SIGN_BORDER, zIndex = 1,
		})
		Kit.addStroke(frame, {
			name = Kit.Names.strokeLight, color = Kit.Colors.white, mode = "Border", thickness = SIGN_HIGHLIGHT,
			borderOffset = -SIGN_HIGHLIGHT, transparency = 0.5, zIndex = 2,
		})
		local art = Kit.ensureChild(frame, "ImageLabel", Kit.Names.background)
		Kit.setImage(art, Kit.Images.windowArt)
		art.ImageColor3 = Kit.Colors.white
		art.ImageTransparency = Kit.Sizes.window.artTransparency
		art.ScaleType = Enum.ScaleType.Crop -- a 3.7:1 card crops the art instead of stretching it
		art.BackgroundTransparency = 1
		art.BorderSizePixel = 0
		art.AnchorPoint = Vector2.new(0.5, 0.5)
		art.Position = UDim2.fromScale(0.5, 0.5)
		art.Size = UDim2.fromScale(1, 1)
		art.ZIndex = 1
		Kit.setCorner(art, SIGN_CORNER)

		-- Headshot: circle on an ink disc (shown until PlotService's rbxthumb loads), Speedsters cyan ring over
		-- a wider ink rim (two Outer Border strokes, the ring on top).
		local icon = ensureNamed(frame, "PlayerIcon", "ImageLabel")
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, ICON_X, 0.5, 0)
		icon.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
		icon.ScaleType = Enum.ScaleType.Crop
		icon.BackgroundColor3 = Kit.Colors.ink
		icon.BackgroundTransparency = 0
		icon.BorderSizePixel = 0
		icon.ImageContent = roblox.Content.none -- rbxthumb headshot is set by PlotService at runtime
		icon.ZIndex = 3
		Kit.setCorner(icon, UDim.new(1, 0)) -- circle
		Kit.addStroke(icon, { name = firstStrokeName(icon), color = ringColor, mode = "Border", thickness = RING, zIndex = 2 })
		Kit.addStroke(icon, { name = Kit.Names.strokeDark, color = Kit.Colors.ink, mode = "Border", thickness = RING_RIM, zIndex = 1 })
		local aspect = icon:FindFirstChildOfClass("UIAspectRatioConstraint")
			or Kit.ensureChild(icon, "UIAspectRatioConstraint", "UIAspectRatioConstraint")
		aspect.AspectRatio = 1

		-- Owner name: GothamSSm Bold white with the ink Contextual ScaledSize outline (window.title recipe).
		local nameLabel = ensureNamed(frame, "PlayerName", "TextLabel")
		local nameX = ICON_X + ICON_SIZE + 12
		nameLabel.AnchorPoint = Vector2.new(0, 0.5)
		nameLabel.Position = UDim2.new(0, nameX, 0.5, 0)
		nameLabel.Size = UDim2.new(1, -(nameX + 14), 0.62, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = ""
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextYAlignment = Enum.TextYAlignment.Center
		nameLabel.ZIndex = 3
		Kit.styleText(nameLabel, "title", { strokeThickness = NAME_STROKE, scaled = true })
		local textSize = nameLabel:FindFirstChildOfClass("UITextSizeConstraint")
			or Kit.ensureChild(nameLabel, "UITextSizeConstraint", "UITextSizeConstraint")
		textSize.MaxTextSize = 30
		textSize.MinTextSize = 10

		styled += 1
	end
	print(string.format("[plots] Styled %d PlayerPlotSigns (Speedsters card %dx%d over window art, %d px circular headshot with #00eaff ring, GothamSSm Bold name, MaxDistance %d).",
		styled, SIGN_WIDTH, SIGN_HEIGHT, ICON_SIZE, SIGN_MAX_DISTANCE))
end

local function resetPlotAttributes(plots)
	local reset = {}
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:IsA("Model") and tonumber(plot.Name) then
			local current = plot:GetAttribute("BaseUpgradeLevel")
			if current ~= 0 then
				table.insert(reset, string.format("%s(%s)", plot.Name, tostring(current)))
			end
			plot:SetAttribute("BaseUpgradeLevel", 0)
		end
	end
	table.sort(reset)
	print(string.format("[plots] Unowned plots start at BaseUpgradeLevel 0 (reset: %s).",
		#reset > 0 and table.concat(reset, ", ") or "none"))
end

local function placeHubSpawn(ws, plots, ctx)
	local roblox = ctx.roblox
	local Vector3, CFrame = roblox.Vector3, roblox.CFrame
	local spawn = ws:FindFirstChild("SpawnLocation")
	if not (spawn and spawn:IsA("BasePart")) then
		print("[plots] Workspace.SpawnLocation missing; hub spawn not checked.")
		return
	end

	local plotBoxes = {}
	local plotParts = {}
	for _, plot in ipairs(plots:GetChildren()) do
		local minV, maxV = nil, nil
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("BasePart") then
				local a, b = worldAabb(d, Vector3)
				table.insert(plotParts, { a, b, plot.Name .. "." .. d.Name })
				minV = minV and minV:Min(a) or a
				maxV = maxV and maxV:Max(b) or b
			end
		end
		if minV then
			table.insert(plotBoxes, { minV, maxV, plot.Name })
		end
	end

	local spawnPos = spawn.CFrame.Position
	local half = Vector3.new(spawn.Size.X / 2, spawn.Size.Y / 2, spawn.Size.Z / 2)
	local function padBox(center, clearance)
		local grow = Vector3.new(clearance, 0, clearance)
		return center - half - grow, center + half + grow + Vector3.new(0, SPAWN_CHECK_HEIGHT, 0)
	end

	-- Does the pad currently overlap any plot part?
	local curMin, curMax = padBox(spawnPos, 0)
	local hits = {}
	for _, entry in ipairs(plotParts) do
		if boxesOverlap(curMin, curMax, entry[1], entry[2]) then
			table.insert(hits, entry[3])
		end
	end
	if #hits == 0 then
		print(string.format("[plots] Hub SpawnLocation at (%.1f, %.2f, %.1f) is clear of plot geometry; not moved.",
			spawnPos.X, spawnPos.Y, spawnPos.Z))
		return
	end

	-- Obstacles outside the plots: everything near floor level except terrain/baseplate and
	-- huge invisible marker volumes.
	local obstacles = {}
	local groundY = ctx.groundY or (spawnPos.Y - half.Y)
	for _, d in ipairs(ws:GetDescendants()) do
		if d:IsA("BasePart") and d ~= spawn and d.ClassName ~= "Terrain" and d.Name ~= "Baseplate"
			and not d:IsDescendantOf(plots) then
			local a, b = worldAabb(d, Vector3)
			local footprint = math.max(b.X - a.X, b.Z - a.Z)
			local isMarker = footprint > MARKER_FOOTPRINT and (d.Transparency >= 1 or not d.CanCollide)
			if not isMarker and b.Y > groundY - 0.5 and a.Y < groundY + SPAWN_CHECK_HEIGHT + 1
				and b.X > -200 and a.X < SPAWN_MAX_X + 20 and b.Z > -300 and a.Z < 300 then
				table.insert(obstacles, { a, b })
			end
		end
	end

	local candidates = {}
	for x = -120, SPAWN_MAX_X - math.ceil(half.X) do
		for z = -250, 250 do
			local dx, dz = x - spawnPos.X, z - spawnPos.Z
			table.insert(candidates, { x, z, dx * dx + dz * dz })
		end
	end
	table.sort(candidates, function(a, b)
		return a[3] < b[3]
	end)

	for _, cand in ipairs(candidates) do
		local center = Vector3.new(cand[1], spawnPos.Y, cand[2])
		local minV, maxV = padBox(center, SPAWN_CLEARANCE)
		local blocked = false
		for _, box in ipairs(plotBoxes) do
			-- plot bounds are checked over the full height (a plot's footprint is off limits)
			if minV.X < box[2].X and maxV.X > box[1].X and minV.Z < box[2].Z and maxV.Z > box[1].Z then
				blocked = true
				break
			end
		end
		if not blocked then
			for _, box in ipairs(obstacles) do
				if boxesOverlap(minV, maxV, box[1], box[2]) then
					blocked = true
					break
				end
			end
		end
		if not blocked then
			spawn.CFrame = CFrame.new(center) * spawn.CFrame.Rotation
			print(string.format("[plots] Hub SpawnLocation overlapped %d plot part(s) (e.g. Plots.%s); moved (%.1f, %.2f, %.1f) -> (%.1f, %.2f, %.1f), %.1f studs, clear of all plot bounds and %d hub obstacles.",
				#hits, hits[1], spawnPos.X, spawnPos.Y, spawnPos.Z, center.X, center.Y, center.Z, math.sqrt(cand[3]), #obstacles))
			return
		end
	end
	error("[plots] Hub SpawnLocation overlaps plot geometry and no clear hub spot was found")
end

function Plots.Apply(place, spPlace, ctx)
	assert(type(ctx) == "table" and ctx.roblox, "plots step needs ctx.roblox")
	local ws = place.Workspace
	local plots = ws:FindFirstChild("Plots")
	assert(plots, "Workspace.Plots not found")

	-- Independent sub-steps: one failing must not skip the others; failures are re-raised at the end
	-- so the lenient build still reports this step as failed.
	local failures = {}
	for _, sub in ipairs({
		{ "signs", function() styleSigns(plots, ctx) end },
		{ "attributes", function() resetPlotAttributes(plots) end },
		{ "spawn", function() placeHubSpawn(ws, plots, ctx) end },
	}) do
		local ok, err = pcall(sub[2])
		if not ok then
			table.insert(failures, sub[1] .. ": " .. tostring(err))
			print("[plots] !! sub-step '" .. sub[1] .. "' failed: " .. tostring(err))
		end
	end
	if #failures > 0 then
		error("plots step failed: " .. table.concat(failures, " | "))
	end
end

return Plots
