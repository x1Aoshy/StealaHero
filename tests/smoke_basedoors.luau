--!nocheck
-- tests/smoke_basedoors.luau (BASE DOORS + THEME VFX, owner 2026-09-26: "make sure the doors open ... for all the
-- bases ... when you go up" + "add some vfx to the bases for each one, something related to their theme")
-- Joins the "smoke" filter. Checks, against the built place:
--   1. the four scripts are injected (Modules.BaseDoors / BaseThemeVfx, Game.Plots.BaseDoorController /
--      BaseThemeVfxController), equal their src mirrors and compile; no glowing material / light object in them, the
--      10-stud trigger and 2.5 s close delay, built-in particle textures only, sounds only through Library.Audio;
--   2. every plot carries the gate data of scripts/steps/post_zzz_base_doors.luau (gate on the StarterPen gate within
--      1 stud, pointing out of the pen, the opening of all 6 themes + the plain pen);
--   3. offline (Lune): every door style built on every plot is inert, fits its opening closed (under the lintel,
--      covering the passage) and clears the walkway open (sliding segments park inside the pylons), at every pose;
--      every theme's VFX is inert / built-in textures / under the rate budget;
--   4. the open / close state machine, and both LocalScripts run with engine doubles: a player walking up opens the
--      door (with a sound cue), leaving closes it 2.5 s later, a theme swap rebuilds it, far doors are ignored, the
--      StarterPen leaves are hidden; the VFX follow the theme and switch off far from the camera.

local roblox = H.roblox
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local place = H.place()
local ws = place:GetService("Workspace")
local rs = place:GetService("ReplicatedStorage")
local KEYS = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }
local LOOKS = { "None", "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }
local BUILTIN = {
	["rbxasset://textures/particles/explosion01_implosion_main.dds"] = true,
	["rbxasset://textures/particles/explosion01_shockwave_main.dds"] = true,
	["rbxasset://textures/particles/explosion01_core_main.dds"] = true,
	["rbxasset://textures/particles/explosion01_smoke_main.dds"] = true,
	["rbxasset://textures/particles/smoke_main.dds"] = true,
	["rbxasset://textures/particles/sparkles_main.dds"] = true,
	["rbxasset://textures/particles/fire_main.dds"] = true,
	["rbxasset://textures/particles/fire_sparks_main.dds"] = true,
	["rbxasset://textures/particles/forcefield_glow_main.dds"] = true,
	["rbxasset://textures/particles/forcefield_vortex_main.dds"] = true,
}

local function list(t)
	return table.concat(t, ", ", 1, math.min(#t, 6))
end

---------------------------------------------------------------------------------------------------
-- 1. scripts
---------------------------------------------------------------------------------------------------
local SCRIPTS = {
	{ "ReplicatedStorage/Library/Modules/BaseDoors", "ModuleScript", "src/ReplicatedStorage/Library/Modules/BaseDoors.luau" },
	{ "ReplicatedStorage/Library/Modules/BaseThemeVfx", "ModuleScript", "src/ReplicatedStorage/Library/Modules/BaseThemeVfx.luau" },
	{ "StarterPlayer/StarterPlayerScripts/Game/Plots/BaseDoorController", "LocalScript", "src/StarterPlayer/StarterPlayerScripts/Game/Plots/BaseDoorController.client.luau" },
	{ "StarterPlayer/StarterPlayerScripts/Game/Plots/BaseThemeVfxController", "LocalScript", "src/StarterPlayer/StarterPlayerScripts/Game/Plots/BaseThemeVfxController.client.luau" },
}
local sources, broken = {}, {}
for _, entry in ipairs(SCRIPTS) do
	local segments = string.split(entry[1], "/")
	local node = place:GetService(segments[1])
	for i = 2, #segments do
		node = node and node:FindFirstChild(segments[i])
	end
	local ok = node ~= nil and node.ClassName == entry[2] and pcall(H.luau.compile, node.Source)
		and H.normalize(node.Source) == H.normalize(H.fs.readFile(entry[3]))
	if ok then
		sources[segments[#segments]] = node.Source
	else
		table.insert(broken, entry[1])
	end
end
T.check(#broken == 0, "base doors: scripts missing, not compiling or not equal to their src mirror: %s", list(broken))

local allSource = table.concat({ sources.BaseDoors or "", sources.BaseThemeVfx or "", sources.BaseDoorController or "", sources.BaseThemeVfxController or "" }, "\n")
local banned = {}
for _, word in ipairs({ "Neon", "PointLight", "SpotLight", "SurfaceLight", "Enum.Material.ForceField", "Instance.new(\"Sound\")", "SoundId", "rbxassetid", "http" }) do
	if H.has(allSource, word) then
		table.insert(banned, word)
	end
end
T.check(#banned == 0, "base doors / VFX sources must never name a glowing material, a light object, a raw sound or an uploaded asset: %s", list(banned))
local doorsSrc = H.normalize(sources.BaseDoors or "")
T.check(string.match(doorsSrc, "\nBaseDoors%.TRIGGER_RADIUS = 10 ") ~= nil and string.match(doorsSrc, "\nBaseDoors%.CLOSE_DELAY = 2%.5 ") ~= nil
	and string.match(doorsSrc, "\nBaseDoors%.CHECK_INTERVAL = 0%.1 ") ~= nil and string.match(doorsSrc, "\nBaseDoors%.FAR_DISTANCE = 150 ") ~= nil,
	"BaseDoors must open within 10 studs, close 2.5 s later, check at 10 Hz and skip doors > 150 studs from the camera")
local controllerSrc = sources.BaseDoorController or ""
T.check(H.has(controllerSrc, "BaseDoors.TRIGGER_RADIUS") and H.has(controllerSrc, "BaseDoors.FAR_DISTANCE") and H.has(controllerSrc, "Audio.Play")
	and H.has(controllerSrc, "Audio.SPEEDSTERS_AUDIO") and H.has(controllerSrc, "LocalTransparencyModifier") and H.has(controllerSrc, "Players:GetPlayers()"),
	"BaseDoorController must use the shared trigger / range, any player's character, the whitelisted Library.Audio cue and hide the StarterPen leaves")
local vfxSrc = sources.BaseThemeVfx or ""
local literals, badTextures = 0, {}
for uri in string.gmatch(vfxSrc .. (sources.BaseDoors or ""), "\"(rbxasset://[^\"]+)\"") do
	literals += 1
	if not BUILTIN[uri] then
		table.insert(badTextures, uri)
	end
end
T.check(literals >= 4 and #badTextures == 0, "base VFX must use built-in engine particle textures only (%d literals): %s", literals, list(badTextures))
T.check(H.has(sources.BaseThemeVfxController or "", "BaseThemeVfx.ACTIVE_DISTANCE") and H.has(sources.BaseThemeVfxController or "", "MOBILE_RATE_SCALE")
	and H.has(vfxSrc, "Vfx.ACTIVE_DISTANCE = 180"), "BaseThemeVfxController must switch bases off beyond 180 studs and scale rates on touch devices")
local audioSrc = (H.path(rs, "Library/Audio") and H.path(rs, "Library/Audio").Source) or ""
T.check(H.has(audioSrc, "UI_POP = 72264591133889"), "Library.Audio must still whitelist UI_POP (the door cue)")

---------------------------------------------------------------------------------------------------
-- load the modules with Lune
---------------------------------------------------------------------------------------------------
local ENV = {
	Instance = roblox.Instance,
	Vector3 = Vector3,
	Vector2 = roblox.Vector2,
	CFrame = CFrame,
	Color3 = roblox.Color3,
	Enum = roblox.Enum,
	UDim = roblox.UDim,
	UDim2 = roblox.UDim2,
	Font = roblox.Font,
	NumberSequence = roblox.NumberSequence,
	NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
	ColorSequence = roblox.ColorSequence,
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
	NumberRange = roblox.NumberRange,
	typeof = typeof,
}
local function loadModule(name)
	local source = sources[name]
	if source == nil then
		return nil
	end
	local ok, module = pcall(function()
		return H.luau.load(source, { debugName = name, environment = setmetatable(table.clone(ENV), { __index = _G }) })()
	end)
	T.check(ok and type(module) == "table", "%s does not load with Lune: %s", name, tostring(module))
	return if ok then module else nil
end
local BaseDoors = loadModule("BaseDoors")
local Vfx = loadModule("BaseThemeVfx")
if BaseDoors == nil or Vfx == nil then
	return
end

local missingStyles = {}
for _, key in ipairs(LOOKS) do
	local style = BaseDoors.Styles[key]
	local kindOk = style and (style.Kind == "swing" or style.Kind == "slide" or style.Kind == "rollup" or style.Kind == "sink")
	local cueOk = style and style.Sound and style.Sound.Open and style.Sound.Close and H.has(audioSrc, style.Sound.Open.Id .. " = ")
		and H.has(audioSrc, style.Sound.Close.Id .. " = ")
	if not (kindOk and cueOk and BaseDoors.DefaultGeometry[key]) then
		table.insert(missingStyles, key)
	end
	if key ~= "None" and Vfx.Themes[key] == nil then
		table.insert(missingStyles, "VFX " .. key)
	end
end
T.check(#missingStyles == 0, "door styles / defaults / sound cues / theme VFX must cover the 6 themes + the plain pen: %s", list(missingStyles))

---------------------------------------------------------------------------------------------------
-- 2. gate data on every plot
---------------------------------------------------------------------------------------------------
local plots = {}
for _, plot in ipairs(ws:FindFirstChild("Plots") and ws.Plots:GetChildren() or {}) do
	if plot:IsA("Model") and tonumber(plot.Name) then
		table.insert(plots, plot)
	end
end
table.sort(plots, function(a, b)
	return tonumber(a.Name) < tonumber(b.Name)
end)
T.check(#plots == 6, "expected 6 plots, found %d", #plots)
local A = BaseDoors.ATTR
local badGate, badGeometry = {}, {}
for _, plot in ipairs(plots) do
	local origin, outward, right = plot:GetAttribute(A.Origin), plot:GetAttribute(A.Outward), plot:GetAttribute(A.Right)
	local pen, D = plot:GetAttribute(A.PenOrigin), plot:GetAttribute(A.PenHalfDepth)
	local grid = H.path(plot, "ToUpdate/StarterPen/GridCenter")
	local ok = typeof(origin) == "Vector3" and typeof(outward) == "Vector3" and typeof(right) == "Vector3" and typeof(pen) == "Vector3"
		and type(D) == "number" and type(plot:GetAttribute(A.PenHalfWidth)) == "number" and type(plot:GetAttribute(A.HalfWidth)) == "number"
		and grid ~= nil
	if ok then
		local flat = Vector3.new(origin.X - grid.CFrame.Position.X, 0, origin.Z - grid.CFrame.Position.Z)
		ok = flat.Magnitude <= 1 and math.abs(origin.Y - 2.05) < 0.2
			and math.abs(outward.Magnitude - 1) < 1e-3 and math.abs(outward.Y) < 1e-3 and math.abs(right.Magnitude - 1) < 1e-3
			and math.abs(right.Y) < 1e-3 and math.abs(right:Dot(outward)) < 1e-3
			and (origin - pen):Dot(outward) > 0.8 * D
	end
	if not ok then
		table.insert(badGate, plot.Name)
	end
	for _, key in ipairs(LOOKS) do
		local g = BaseDoors.ParseGeometry(plot:GetAttribute(A.GeometryPrefix .. key))
		local def = BaseDoors.DefaultGeometry[key]
		local sane = g ~= nil and g.vMin < -3.4 and g.vMax > 3.4 and g.vMax - g.vMin <= 10 and g.top >= 4 and g.uMin < g.uMax
			and (BaseDoors.Styles[key].Kind ~= "slide" or (g.wLeft > 1 and g.wRight > 1))
		if sane then
			for _, field in ipairs(BaseDoors.GEOMETRY_FIELDS) do
				sane = sane and math.abs(g[field] - def[field]) <= 0.5 -- the fallback table follows the modelled pens
			end
		end
		if not sane then
			table.insert(badGeometry, plot.Name .. "/" .. key)
		end
	end
end
T.check(#badGate == 0, "plots without the gate frame (GateOrigin on the StarterPen gate within 1 stud, GateOutward out of the pen, GateRight across): %s", list(badGate))
T.check(#badGeometry == 0, "plots whose DoorGeometry_<Key> is missing / implausible / far from BaseDoors.DefaultGeometry (update the defaults after a re-import): %s", list(badGeometry))

---------------------------------------------------------------------------------------------------
-- 3. offline builds: fit, walkway, pylons, inertness
---------------------------------------------------------------------------------------------------
-- a stand-in plot for the module's attribute readers
local function plotStub(plot)
	local attributes = plot:GetAttributes()
	return {
		Name = plot.Name,
		GetAttribute = function(_, name)
			return attributes[name]
		end,
	}
end

-- part box in the door frame: x = v, y = h, z = -u
local function localBox(part, frame)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
	local cf, size = part.CFrame, part.Size
	for _, sx in ipairs({ -0.5, 0.5 }) do
		for _, sy in ipairs({ -0.5, 0.5 }) do
			for _, sz in ipairs({ -0.5, 0.5 }) do
				local p = frame:PointToObjectSpace(cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz))
				lo, hi = lo:Min(p), hi:Max(p)
			end
		end
	end
	return lo, hi
end

local sink = roblox.Instance.new("Folder")
local notInert, misfit, blocked, unparked, unfilled, buildErrors, heavy = {}, {}, {}, {}, {}, {}, {}
for _, plot in ipairs(plots) do
	local stub = plotStub(plot)
	local frame = BaseDoors.GateFrame(stub)
	if frame == nil then
		continue
	end
	for _, key in ipairs(LOOKS) do
		local tag = plot.Name .. "/" .. key
		local g = BaseDoors.ReadGeometry(stub, key)
		local ok, door = pcall(BaseDoors.Build, key, g, frame, sink)
		if not ok then
			table.insert(buildErrors, tag .. ": " .. tostring(door))
			continue
		end
		local style = door.style
		local c = (g.vMin + g.vMax) / 2
		if #door.parts > 64 then
			table.insert(heavy, tag .. "=" .. #door.parts)
		end
		for _, d in ipairs(door.model:GetDescendants()) do
			if d:IsA("BasePart") and (not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch or d.Material == roblox.Enum.Material.Neon) then
				table.insert(notInert, tag .. "." .. d.Name)
				break
			elseif d:IsA("Light") then
				table.insert(notInert, tag .. " light " .. d.Name)
				break
			end
		end
		for _, e in ipairs({ 0, 0.25, 0.5, 0.75, 1 }) do
			door:Pose(e)
			local covered = {}
			for _, part in ipairs(door.parts) do
				local lo, hi = localBox(part, frame)
				-- never above the lintel, never under the floor (a sinking door hides in the ground), never wider than the
				-- opening + its pylon pockets
				local sinks = style.Kind == "sink"
				if hi.Y > g.top + 0.02 or (lo.Y < -0.01 and not sinks) or lo.X < g.vMin - g.wLeft - 0.05 or hi.X > g.vMax + g.wRight + 0.05 then
					table.insert(misfit, string.format("%s.%s@%.2f", tag, part.Name, e))
				end
				if sinks and e == 1 and hi.Y > 0.02 then
					table.insert(misfit, string.format("%s.%s@1 not fully under the floor", tag, part.Name))
				end
				if style.Kind == "slide" and (lo.Z < -g.uMax - 0.02 or hi.Z > -g.uMin + 0.02) then
					table.insert(misfit, string.format("%s.%s@%.2f outside the pylon depth", tag, part.Name, e))
				end
				if e == 0 and lo.Y <= 2 and hi.Y >= 2 then
					table.insert(covered, { lo.X, hi.X })
				end
				if e == 1 then
					-- the walkway: 3.3 studs either side of the centre, up to 6.8 (or the plain gate's height)
					local clearTop = math.min(g.top, 7.2) - 0.4
					if hi.X > c - 3.3 and lo.X < c + 3.3 and hi.Y > 0.3 and lo.Y < clearTop then
						table.insert(blocked, tag .. "." .. part.Name)
					end
					if style.Kind == "slide" and part.Parent and string.find(part.Parent.Name, "^Segment") then
						local plus = string.find(part.Parent.Name, "PlusX") ~= nil
						local inside = if plus then (lo.X >= g.vMax - 0.01 and hi.X <= g.vMax + g.wRight + 0.01)
							else (hi.X <= g.vMin + 0.01 and lo.X >= g.vMin - g.wLeft - 0.01)
						if not inside then
							table.insert(unparked, tag .. "." .. part.Parent.Name .. "." .. part.Name)
						end
					end
				end
			end
			if e == 0 and key ~= "None" then
				-- the closed door fills the opening at chest height (no gap wider than 0.12 studs)
				table.sort(covered, function(a, b)
					return a[1] < b[1]
				end)
				local reach = g.vMin + 0.05
				for _, span in ipairs(covered) do
					if span[1] > reach + 0.12 then
						break
					end
					reach = math.max(reach, span[2])
				end
				if reach < g.vMax - 0.05 then
					table.insert(unfilled, string.format("%s (filled to %.2f of %.2f)", tag, reach, g.vMax))
				end
			end
		end
		local centre = frame:PointToObjectSpace(door.centre)
		if math.abs(centre.X - c) > 0.01 or math.abs(centre.Y - BaseDoors.CENTRE_HEIGHT) > 0.01 then
			table.insert(misfit, tag .. " trigger centre")
		end
		door:Destroy()
	end
end
T.check(#buildErrors == 0, "door builds failed: %s", list(buildErrors))
T.check(#notInert == 0, "door parts must be Anchored, never collide / query / touch, never Neon, no lights: %s", list(notInert))
T.check(#misfit == 0, "door parts outside their opening (above the lintel, past the pylons, out of the pylon depth): %s", list(misfit))
T.check(#unfilled == 0, "closed doors must fill their opening: %s", list(unfilled))
T.check(#blocked == 0, "open doors must leave the walkway clear: %s", list(blocked))
T.check(#unparked == 0, "open sliding segments must park inside their pylon: %s", list(unparked))
T.check(#heavy == 0, "doors must stay light (<= 64 parts): %s", list(heavy))

-- theme VFX: inert invisible anchors, built-in textures, the rate budget, on / off, a few update ticks
local vfxProblems = {}
for _, plot in ipairs(plots) do
	local stub = plotStub(plot)
	local penFrame = Vfx.PenFrame(stub)
	if penFrame == nil then
		table.insert(vfxProblems, plot.Name .. ": no pen frame")
		continue
	end
	for _, key in ipairs(KEYS) do
		local tag = plot.Name .. "/" .. key
		local layout = {
			D = plot:GetAttribute(A.PenHalfDepth),
			W = plot:GetAttribute(A.PenHalfWidth),
			gx = penFrame:PointToObjectSpace(plot:GetAttribute(A.Origin)).X,
			gate = BaseDoors.ReadGeometry(stub, key),
		}
		local ok, fx = pcall(Vfx.Build, key, penFrame, layout, sink, 1)
		if not ok or fx == nil then
			table.insert(vfxProblems, tag .. ": " .. tostring(fx))
			continue
		end
		local emitters, beams = 0, 0
		for _, d in ipairs(fx.model:GetDescendants()) do
			if d:IsA("BasePart") then
				if d.Transparency < 1 or not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch or d.CastShadow then
					table.insert(vfxProblems, tag .. ": visible / solid anchor " .. d.Name)
				end
				-- anchors stay around the base (plot zone + the skyline behind it)
				local p = penFrame:PointToObjectSpace(d.CFrame.Position)
				if math.abs(p.X) > layout.W + 3 or p.Z < -layout.D - 3 or p.Z > layout.D + 3 or p.Y < -0.5 or p.Y > 20 then
					table.insert(vfxProblems, tag .. ": anchor off the base " .. d.Name)
				end
			elseif d:IsA("ParticleEmitter") then
				emitters += 1
				if not BUILTIN[d.Texture] then
					table.insert(vfxProblems, tag .. ": texture " .. tostring(d.Texture))
				end
				if d.Enabled then
					table.insert(vfxProblems, tag .. ": emitter on before SetActive " .. d.Name)
				end
			elseif d:IsA("Beam") then
				beams += 1
			elseif d:IsA("Light") or d:IsA("Sound") or d:IsA("LuaSourceContainer") then
				table.insert(vfxProblems, tag .. ": " .. d.ClassName)
			end
		end
		if emitters + beams < 3 then
			table.insert(vfxProblems, string.format("%s: only %d emitters / beams", tag, emitters + beams))
		end
		if fx:BaseRate() > Vfx.RATE_BUDGET then
			table.insert(vfxProblems, string.format("%s: %.1f particles/s over the %d budget", tag, fx:BaseRate(), Vfx.RATE_BUDGET))
		end
		fx:SetActive(true)
		local anyOn = false
		for _, entry in ipairs(fx.emitters) do
			anyOn = anyOn or entry.emitter.Enabled
		end
		for _, entry in ipairs(fx.beams) do
			anyOn = anyOn or entry.beam.Enabled
		end
		local okTick, err = pcall(function()
			for i = 1, 60 do
				fx:Update(100 + i * Vfx.UPDATE_INTERVAL, Vfx.UPDATE_INTERVAL)
			end
		end)
		if not okTick then
			table.insert(vfxProblems, tag .. ": update failed: " .. tostring(err))
		end
		fx:SetActive(false)
		local anyLeft = false
		for _, entry in ipairs(fx.emitters) do
			anyLeft = anyLeft or entry.emitter.Enabled
		end
		for _, entry in ipairs(fx.beams) do
			anyLeft = anyLeft or entry.beam.Enabled
		end
		if not anyOn or anyLeft then
			table.insert(vfxProblems, tag .. ": SetActive does not switch it on / off")
		end
		fx:Destroy()
	end
end
T.check(#vfxProblems == 0, "theme VFX problems: %s", list(vfxProblems))

---------------------------------------------------------------------------------------------------
-- 4a. the state machine
---------------------------------------------------------------------------------------------------
do
	local s = BaseDoors.NewState()
	local events = {}
	local function sample(t, near)
		local ev = BaseDoors.Update(s, t, near)
		if ev then
			table.insert(events, string.format("%s@%.2f", ev, t))
		end
	end
	sample(0, false)
	sample(1.0, true)
	sample(1.1, true)
	sample(2.0, false)
	sample(3.5, false) -- 2.4 s since the last one in range
	sample(3.7, false) -- 2.6 s: closes
	sample(3.8, false)
	sample(4.0, true) -- back: opens again
	local order = table.concat(events, " ")
	T.check(order == "open@1.00 close@3.70 open@4.00", "door state machine: expected open@1.00 close@3.70 open@4.00, got %s", order)
	local style = BaseDoors.Styles.Forest
	local m = BaseDoors.NewState()
	BaseDoors.Update(m, 0, true)
	local frames, moving = 0, true
	while moving and frames < 1000 do
		moving = BaseDoors.Advance(m, 1 / 60, style)
		frames += 1
	end
	T.check(m.alpha == 1 and math.abs(frames / 60 - style.Open) < 0.05, "door opening must take its style's Open time (%.2f s, took %.2f)", style.Open, frames / 60)
	local monotonic = true
	for _, kind in ipairs({ "Sine", "Quad", "Cubic", "Quart", "Quint", "Linear" }) do
		local last = -1
		for i = 0, 20 do
			local v = BaseDoors.Ease(kind, i / 20)
			monotonic = monotonic and v >= last - 1e-9 and v >= 0 and v <= 1
			last = v
		end
		monotonic = monotonic and BaseDoors.Ease(kind, 0) == 0 and math.abs(BaseDoors.Ease(kind, 1) - 1) < 1e-9
	end
	T.check(monotonic, "door easing curves must run 0 -> 1 without overshoot")
end

---------------------------------------------------------------------------------------------------
-- 4b. the LocalScripts with engine doubles
---------------------------------------------------------------------------------------------------
local function signal()
	local s = { handlers = {} }
	function s:Connect(fn)
		local c = { fn = fn, Connected = true }
		function c.Disconnect()
			c.Connected = false
		end
		table.insert(s.handlers, c)
		return c
	end
	function s:Fire(...)
		for _, c in ipairs(table.clone(s.handlers)) do
			if c.Connected then
				c.fn(...)
			end
		end
	end
	function s:Count()
		local n = 0
		for _, c in ipairs(s.handlers) do
			n += if c.Connected then 1 else 0
		end
		return n
	end
	return s
end

-- a small cooperative scheduler + clock
local function newWorld()
	local W = { clock = 0, sleepers = {}, errors = {}, warnings = {}, heartbeat = signal() }
	local function resume(co, ...)
		local ok, res = coroutine.resume(co, ...)
		if not ok then
			table.insert(W.errors, tostring(res))
		elseif coroutine.status(co) ~= "dead" then
			table.insert(W.sleepers, { co = co, wake = W.clock + (tonumber(res) or 0) })
		end
	end
	W.task = {
		spawn = function(fn, ...)
			resume(coroutine.create(fn), ...)
		end,
		defer = function(fn, ...)
			resume(coroutine.create(fn), ...)
		end,
		wait = function(d)
			coroutine.yield(d or 0)
			return d or 0
		end,
	}
	function W.advance(seconds)
		local frames = math.max(1, math.floor(seconds * 60 + 0.5))
		for _ = 1, frames do
			W.clock += seconds / frames
			local due = {}
			for i = #W.sleepers, 1, -1 do
				if W.sleepers[i].wake <= W.clock + 1e-9 then
					table.insert(due, table.remove(W.sleepers, i))
				end
			end
			for _, s in ipairs(due) do
				resume(s.co)
			end
			W.heartbeat:Fire(seconds / frames)
		end
	end
	return W
end

-- a stand-in plot around the real plot's attributes, with a real StarterPen gate leaf to hide
local function mockPlot(plot, W)
	local attributes = plot:GetAttributes()
	local changed = {}
	local mp = { Name = plot.Name, attributes = attributes, AncestryChanged = signal() }
	local toUpdate = roblox.Instance.new("Model")
	toUpdate.Name = "ToUpdate"
	local pen = roblox.Instance.new("Model")
	pen.Name = "StarterPen"
	pen.Parent = toUpdate
	local gate = roblox.Instance.new("Model")
	gate.Name = "Gate"
	gate.Parent = pen
	local leaf = roblox.Instance.new("Model")
	leaf.Name = "GateLeft"
	leaf.Parent = gate
	mp.leafPart = roblox.Instance.new("Part")
	mp.leafPart.Parent = leaf
	function mp:GetAttribute(name)
		return self.attributes[name]
	end
	function mp:SetAttribute(name, value)
		self.attributes[name] = value
		if changed[name] then
			changed[name]:Fire()
		end
	end
	function mp:GetAttributeChangedSignal(name)
		changed[name] = changed[name] or signal()
		return changed[name]
	end
	function mp:IsA(class)
		return class == "Model"
	end
	function mp:IsDescendantOf(node)
		return self.Parent ~= nil and node == W.workspace
	end
	function mp:FindFirstChild(name)
		return if name == "ToUpdate" then toUpdate else nil
	end
	return mp
end

local function newGame(W, mocks, modules)
	local rsNode
	local function node(name)
		local n = { __name = name }
		function n:WaitForChild(child)
			return node(child)
		end
		function n:FindFirstChild(child)
			return node(child)
		end
		return n
	end
	rsNode = node("ReplicatedStorage")
	local services = {
		Players = mocks.players,
		ReplicatedStorage = rsNode,
		RunService = { Heartbeat = W.heartbeat },
		Workspace = W.workspace,
		UserInputService = { TouchEnabled = false, KeyboardEnabled = true },
	}
	local game = {}
	function game:GetService(name)
		return services[name]
	end
	local env = setmetatable(table.clone(ENV), { __index = _G })
	env.game = game
	env.workspace = W.workspace
	env.task = W.task
	env.os = { clock = function()
		return W.clock
	end }
	env.warn = function(...)
		table.insert(W.warnings, table.concat({ ... }, " "))
	end
	env.require = function(target)
		local module = type(target) == "table" and modules[target.__name]
		assert(module, "unexpected require " .. tostring(type(target) == "table" and target.__name or target))
		return module
	end
	return env
end

local function makeWorkspace(W, folderName, plotMocks)
	local folder = roblox.Instance.new("Folder")
	folder.Name = folderName
	local plotsNode = { ChildAdded = signal(), ChildRemoved = signal() }
	function plotsNode:GetChildren()
		return plotMocks
	end
	local wsMock = { CurrentCamera = { CFrame = CFrame.new(0, 10, 0) }, folder = folder, plots = plotsNode }
	function wsMock:FindFirstChild(name)
		return if name == folderName then folder else nil
	end
	function wsMock:WaitForChild(name)
		assert(name == "Plots", "unexpected WaitForChild " .. name)
		return plotsNode
	end
	W.workspace = wsMock
	for _, mp in ipairs(plotMocks) do
		mp.Parent = wsMock
	end
	return wsMock
end

local function pose(model)
	local out = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			out[d] = d.CFrame
		end
	end
	return out
end
local function samePose(a, b)
	for part, cf in pairs(a) do
		local other = b[part]
		if other == nil or (other.Position - cf.Position).Magnitude > 1e-3 then
			return false
		end
	end
	return true
end

if sources.BaseDoorController and #plots >= 2 then
	local W = newWorld()
	local root = { Position = Vector3.new(0, 1e4, 0) }
	function root:IsA(class)
		return class == "BasePart"
	end
	local character = { PrimaryPart = root }
	function character:FindFirstChild(name)
		return if name == "HumanoidRootPart" then root else nil
	end
	local players = {}
	function players:GetPlayers()
		return { { Character = character } }
	end
	local p1, p2 = mockPlot(plots[1], W), mockPlot(plots[2], W)
	p1.attributes.BaseTheme = ""
	p2.attributes.BaseTheme = "Volcano"
	local wsMock = makeWorkspace(W, "ClientBaseDoors", { p1, p2 })
	local cues = {}
	local audio = { SPEEDSTERS_AUDIO = { UI_POP = 72264591133889 } }
	function audio.Play(id, target, speed, volume, range)
		table.insert(cues, { id = id, target = target, speed = speed, volume = volume, range = range })
	end
	local env = newGame(W, { players = players }, { BaseDoors = BaseDoors, Audio = audio })
	local chunk, err = H.sandbox(sources.BaseDoorController, env, "BaseDoorController")
	local ran = chunk ~= nil and pcall(chunk)
	T.check(ran and #W.errors == 0, "BaseDoorController must run with engine doubles: %s %s", tostring(err), list(W.errors))
	if ran then
		local function doorOf(plot)
			return wsMock.folder:FindFirstChild("BaseDoor_" .. plot.Name)
		end
		local d1, d2 = doorOf(p1), doorOf(p2)
		T.check(d1 ~= nil and d2 ~= nil and d1:FindFirstChild("LeafPlusX") and d2:FindFirstChild("LeafPlusX"),
			"BaseDoorController must build every plot's door (plain pen + Volcano wharf gates) in Workspace.ClientBaseDoors")
		T.check(p1.leafPart.LocalTransparencyModifier == 1, "the StarterPen gate leaves must be hidden under the new door")
		if d1 and d2 then
			local closed1, closed2 = pose(d1), pose(d2)
			local frame1 = BaseDoors.GateFrame(p1)
			local centre = frame1 * Vector3.new(0, BaseDoors.CENTRE_HEIGHT, 0)
			wsMock.CurrentCamera.CFrame = CFrame.new(centre + Vector3.new(0, 20, 0))
			W.advance(1)
			T.check(samePose(closed1, pose(d1)) and #cues == 0, "a door must stay closed while nobody is near")
			-- walk up: 9 studs out in front of plot 1's gate
			root.Position = frame1 * Vector3.new(0, BaseDoors.CENTRE_HEIGHT, -9)
			W.advance(0.15)
			T.check(#cues == 1 and cues[1].id == 72264591133889 and cues[1].range == BaseDoors.SOUND_RANGE and cues[1].volume <= 0.6,
				"opening must play one quiet whitelisted cue with the door's roll-off range (%d cue(s))", #cues)
			W.advance(1.5)
			local open1 = pose(d1)
			T.check(not samePose(closed1, open1) and samePose(closed2, pose(d2)), "the near door must open (and only that one)")
			T.check(W.heartbeat:Count() == 0, "the animation Heartbeat must disconnect once every door is still")
			-- leave: still open 2 s later, closed after 2.5 s + the close time
			root.Position = Vector3.new(0, 1e4, 0)
			W.advance(2.0)
			T.check(samePose(open1, pose(d1)), "a door must stay open until CLOSE_DELAY has passed")
			W.advance(0.6 + BaseDoors.Styles.None.Close + 0.2)
			T.check(samePose(closed1, pose(d1)) and #cues == 2, "a door must close CLOSE_DELAY after the last player left (with its cue)")
			-- theme swap rebuilds the door in the new style
			p1:SetAttribute("BaseTheme", "Forest")
			local swapped = doorOf(p1)
			T.check(swapped ~= nil and swapped:FindFirstChild("SegmentPlusX1") ~= nil and swapped:FindFirstChild("LeafPlusX") == nil
				and #wsMock.folder:GetChildren() == 2, "equipping a theme must swap the plot's door for that theme's style")
			-- a door far from the camera is not checked
			if swapped then
				local closedF = pose(swapped)
				wsMock.CurrentCamera.CFrame = CFrame.new(centre + Vector3.new(0, 0, 400))
				root.Position = frame1 * Vector3.new(0, BaseDoors.CENTRE_HEIGHT, -3)
				W.advance(1)
				T.check(samePose(closedF, pose(swapped)), "doors farther than FAR_DISTANCE from the camera must be skipped")
				wsMock.CurrentCamera.CFrame = CFrame.new(centre + Vector3.new(0, 20, 0))
				W.advance(1.5)
				T.check(not samePose(closedF, pose(swapped)), "the themed door must open near a player")
			end
		end
		T.check(#W.errors == 0 and #W.warnings == 0, "BaseDoorController errors / warnings: %s %s", list(W.errors), list(W.warnings))
	end
end

if sources.BaseThemeVfxController and #plots >= 1 then
	local W = newWorld()
	local p = mockPlot(plots[1], W)
	p.attributes.BaseTheme = "Volcano"
	local wsMock = makeWorkspace(W, "ClientBaseVfx", { p })
	local env = newGame(W, { players = {} }, { BaseThemeVfx = Vfx, BaseDoors = BaseDoors })
	local chunk, err = H.sandbox(sources.BaseThemeVfxController, env, "BaseThemeVfxController")
	local ran = chunk ~= nil and pcall(chunk)
	T.check(ran and #W.errors == 0, "BaseThemeVfxController must run with engine doubles: %s %s", tostring(err), list(W.errors))
	if ran then
		local function emittersOn(model)
			local n = 0
			for _, d in ipairs(model and model:GetDescendants() or {}) do
				if d:IsA("ParticleEmitter") and d.Enabled then
					n += 1
				end
			end
			return n
		end
		local penFrame = Vfx.PenFrame(p)
		wsMock.CurrentCamera.CFrame = CFrame.new(penFrame.Position + Vector3.new(0, 30, 0))
		W.advance(0.5)
		local model = wsMock.folder:FindFirstChild("BaseVfx_" .. p.Name)
		T.check(model ~= nil and emittersOn(model) >= 4, "a themed plot near the camera must run its VFX (%d emitters on)", emittersOn(model))
		wsMock.CurrentCamera.CFrame = CFrame.new(penFrame.Position + Vector3.new(0, 0, 400))
		W.advance(0.5)
		T.check(model ~= nil and emittersOn(model) == 0, "VFX must switch off beyond ACTIVE_DISTANCE")
		p:SetAttribute("BaseTheme", "Snow")
		local snow = wsMock.folder:FindFirstChild("BaseVfx_" .. p.Name)
		T.check(snow ~= nil and snow:FindFirstChild("Aura1") ~= nil and #wsMock.folder:GetChildren() == 1, "a theme swap must swap the VFX")
		p:SetAttribute("BaseTheme", "")
		T.check(#wsMock.folder:GetChildren() == 0, "unequipping the theme must remove its VFX")
		T.check(#W.errors == 0 and #W.warnings == 0, "BaseThemeVfxController errors / warnings: %s %s", list(W.errors), list(W.warnings))
	end
end
