--!nocheck
-- Audio: only the whitelisted Speedsters sounds can play (no 403s). VFX: the ported SAB effects are present,
-- silent, disabled until triggered, and wired by a client controller. 6-stage world: environments, gates and board
-- are silent, the stage-2 rain (client StageWeather, H5) uses built-in textures only, and the chase/hazard/ambience/
-- weather scripts never add sounds.

local place = H.place()
local WHITELIST = {
	[77120543307812] = "ui-bubble-click",
	[72264591133889] = "ui-pop-sound",
	[127039883737564] = "winner!",
	[136993031050456] = "SuccessSfx",
	[80736831159506] = "UpgradeBought",
	[142376088] = "Taco Rain music", -- owner request 2026-09-27 (scripts/steps/audio.luau OWNER_AUDIO; one Sound)
}

local offenders, audible = {}, 0
for _, d in ipairs(place:GetDescendants()) do
	if d:IsA("Sound") then
		local uri = H.uri(d, "AudioContent")
		if uri then
			local id = H.assetId(uri)
			if id and WHITELIST[id] then
				audible += 1
			elseif string.sub(uri, 1, 11) ~= "rbxasset://" then
				table.insert(offenders, d:GetFullName() .. " = " .. uri)
			end
		end
	end
end
T.check(#offenders == 0, "%d non-whitelisted sounds would 403: %s", #offenders, table.concat(offenders, "; ", 1, math.min(#offenders, 5)))
T.check(audible >= 5, "expected the Speedsters SFX to be audible, found %d whitelisted sounds", audible)

local vfx = H.path(place.ReplicatedStorage, "Assets/VFX/SAB")
local EXPECTED = { "Aura_Epic", "Aura_Legendary", "Aura_Mythic", "Aura_Secret", "Aura_Villain", "Aura_Carry", "Burst_Hatch", "Burst_Escape", "Sparkle_Cash", "Trail_Speed" }
if T.check(vfx ~= nil, "ReplicatedStorage.Assets.VFX.SAB missing") then
	for _, name in ipairs(EXPECTED) do
		T.check(vfx:FindFirstChild(name) ~= nil, "VFX %s missing", name)
	end
	for _, d in ipairs(vfx:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			T.check(not d.Enabled, "%s must start disabled", d:GetFullName())
			T.check(H.uri(d, "TextureContent") ~= nil, "%s has no texture", d:GetFullName())
		end
	end
	for _, className in ipairs({ "Sound", "LuaSourceContainer", "Highlight" }) do
		T.check(H.countClass(vfx, className) == 0, "VFX must not contain %s", className)
	end
end
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
T.check(sps and sps:FindFirstChild("SabVfxController", true) ~= nil, "SabVfxController LocalScript missing")

-- 6-stage world (docs/STAGES_PLAN.md §3, A9, A12): environments, gates and board are silent; environment particles use
-- built-in rbxasset textures; the chase presentation never adds sounds.
local ws = place.Workspace
for _, rootName in ipairs({ "StageEnvironments", "Hub" }) do
	local root = ws:FindFirstChild(rootName)
	if T.check(root ~= nil, "Workspace.%s missing", rootName) then
		T.check(H.countClass(root, "Sound") == 0, "Workspace.%s must not contain sounds (§3)", rootName)
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				local uri = H.uri(d, "TextureContent")
				T.check(uri ~= nil and string.sub(uri, 1, 11) == "rbxasset://", "%s: environment particles must use a built-in rbxasset texture, found %s", d:GetFullName(), tostring(uri))
			end
		end
	end
end
-- H5 (docs/HERO_MODELS_PLAN.md): ONE rain, drawn by the client script StageWeather (ZeroDown technique). The Lake
-- only declares where it rains (Rain.RainVolume); no ParticleEmitter is left in the stage.
local lake = H.path(ws, "StageEnvironments/Lake")
local lakeStage = H.PLAN.STAGE_BY_KEY.Lake
local marker = lake and H.path(lake, "Rain/RainVolume")
if T.check(marker ~= nil and marker:IsA("BasePart"), "H5: Workspace.StageEnvironments.Lake.Rain.RainVolume (the rain region marker) missing") then
	local mn, mx = H.aabb(marker)
	T.check(marker.Transparency >= 1 and not marker.CanCollide and not marker.CanQuery and not marker.CanTouch and marker.Anchored and not marker.CastShadow,
		"H5: RainVolume must be invisible, anchored, non-collidable, non-queryable, non-touchable and shadowless")
	T.check(marker:GetAttribute("Weather") == "Rain", "H5: RainVolume.Weather must be \"Rain\"")
	local intensity = marker:GetAttribute("Intensity")
	T.check(type(intensity) == "number" and intensity > 0, "H5: RainVolume.Intensity must be a positive number, found %s", tostring(intensity))
	T.check(type(marker:GetAttribute("Lightning")) == "boolean", "H5: RainVolume.Lightning must be a boolean")
	T.check(marker:GetAttribute("StreakTexture") == "", "H5: RainVolume.StreakTexture must default to \"\" (built-in streak texture)")
	T.check(mn.X <= lakeStage.xMin + 1 and mx.X >= lakeStage.xMax - 1 and mn.X >= lakeStage.xMin - 1 and mx.X <= lakeStage.xMax + 1,
		"H5: the rain region must cover exactly stage 2's X range %d..%d, found %.1f..%.1f", lakeStage.xMin, lakeStage.xMax, mn.X, mx.X)
	T.check(mn.Z <= -80 and mx.Z >= 80, "H5: the rain region must span the stage between its side walls (Z %.1f..%.1f)", mn.Z, mx.Z)
	T.check(math.abs(mn.Y - 2.07) < 0.6 and mx.Y - mn.Y >= 20, "H5: the rain region must stand on the floor (bottom %.2f) and be tall (%.1f)", mn.Y, mx.Y - mn.Y)
end
T.check(lake ~= nil and H.countClass(lake, "ParticleEmitter") == 0, "H5: one rain only: no ParticleEmitter may stay in Workspace.StageEnvironments.Lake (StageWeather draws it)")

local BUILTIN_PARTICLE_TEXTURES = {
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
local weather = sps and H.path(sps, "Game/StageWeather")
if T.check(weather ~= nil and weather.ClassName == "LocalScript", "H5: StarterPlayerScripts.Game.StageWeather (LocalScript) missing") then
	local source = weather.Source
	T.check(not H.has(source, "rbxassetid") and not H.has(source, "http"), "H5: StageWeather must only use built-in rbxasset:// textures (no uploaded / third-party ids)")
	local literals = 0
	for uri in string.gmatch(source, "\"(rbxasset://[^\"]+)\"") do
		literals += 1
		T.check(BUILTIN_PARTICLE_TEXTURES[uri] == true, "H5: StageWeather texture %s is not a built-in engine particle texture", uri)
	end
	T.check(literals >= 2, "H5: StageWeather must name its built-in textures (found %d)", literals)
	T.check(not string.find(source, "Instance%.new%(%s*\"Sound\"") and not H.has(source, "SoundId"), "H5: the rain must stay silent (audio whitelist)")

	-- Sandboxed run: fake engine objects, the real marker from the build, a scripted camera and RenderStepped.
	local roblox = H.roblox
	local Vector3, CFrame = roblox.Vector3, roblox.CFrame
	local floorTop = 2.076
	local sched = { threads = {}, errors = {} }
	sched.task = {}
	function sched.task.spawn(fn, ...)
		local co = if type(fn) == "thread" then fn else coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			table.insert(sched.errors, tostring(err))
		elseif coroutine.status(co) ~= "dead" then
			table.insert(sched.threads, co)
		end
		return co
	end
	sched.task.defer = sched.task.spawn
	function sched.task.delay(_, fn, ...)
		return sched.task.spawn(fn, ...)
	end
	function sched.task.wait(seconds)
		return coroutine.yield(seconds)
	end
	function sched.tick()
		local live = {}
		for _, co in ipairs(sched.threads) do
			local ok, err = coroutine.resume(co)
			if not ok then
				table.insert(sched.errors, tostring(err))
			elseif coroutine.status(co) ~= "dead" then
				table.insert(live, co)
			end
		end
		sched.threads = live
	end

	local function newSignal()
		local signal = { handlers = {} }
		function signal:Connect(fn)
			local entry = { fn = fn }
			table.insert(self.handlers, entry)
			return { Disconnect = function()
				local index = table.find(self.handlers, entry)
				if index then
					table.remove(self.handlers, index)
				end
			end }
		end
		function signal:Fire(...)
			for _, entry in ipairs(table.clone(self.handlers)) do
				entry.fn(...)
			end
		end
		return signal
	end

	local created, emits, flashPeak = {}, {}, 0
	local BASE_CLASSES = { Part = "BasePart", ColorCorrectionEffect = "PostEffect" }
	local function makeInstance(className)
		local props = { ClassName = className, Name = className }
		local inst = {}
		local methods = {}
		function methods:IsA(name)
			return name == className or BASE_CLASSES[className] == name or name == "Instance"
		end
		function methods:Emit(count)
			local host = props.Parent
			local at = host and rawget(getmetatable(host), "props").Position
			table.insert(emits, { name = props.Name, count = count or 1, at = at })
		end
		function methods:Destroy()
			props.Parent = nil
		end
		function methods:GetPropertyChangedSignal()
			return newSignal()
		end
		setmetatable(inst, {
			props = props,
			__index = function(_, key)
				return methods[key] or props[key]
			end,
			__newindex = function(_, key, value)
				if className == "ColorCorrectionEffect" and key == "Brightness" and type(value) == "number" then
					flashPeak = math.max(flashPeak, value)
				end
				props[key] = value
			end,
		})
		table.insert(created, inst)
		return inst
	end
	local function propsOf(inst)
		return getmetatable(inst).props
	end

	local camera = makeInstance("Camera")
	table.clear(created)
	local root = { Position = Vector3.new(37, floorTop + 3, 0) }
	local character = { FindFirstChild = function(_, name)
		return if name == "HumanoidRootPart" then root else nil
	end }
	local function placeCamera(x, z)
		root.Position = Vector3.new(x, floorTop + 3, z)
		camera.CFrame = CFrame.new(x, floorTop + 18, z + 16) * CFrame.Angles(-0.45, 0, 0)
	end
	placeCamera(37, 0)

	local floorPart = { Transparency = 0, IsA = function(_, name)
		return name == "BasePart"
	end }
	local boundsPart = { Transparency = 1, IsA = function(_, name)
		return name == "BasePart"
	end }
	local roofPart = { Transparency = 0, IsA = function(_, name)
		return name == "BasePart"
	end }
	local roof, raycasts, boundsHits = false, 0, 0
	local function filtered(params, part)
		for _, inst in ipairs(params and params.FilterDescendantsInstances or {}) do
			if inst == part then
				return true
			end
		end
		return false
	end
	local renderStepped = newSignal()
	local wsMock = {
		CurrentCamera = camera,
		FindFirstChild = function(_, name)
			return ws:FindFirstChild(name)
		end,
		GetPropertyChangedSignal = function()
			return newSignal()
		end,
		Raycast = function(_, origin, direction, params)
			raycasts += 1
			if direction.Y > 0 then
				return if roof then { Position = origin + Vector3.new(0, 12, 0), Normal = Vector3.new(0, -1, 0), Instance = roofPart } else nil
			end
			-- an invisible zone-bounds box sits over the floor until the script lets the rain through it
			if not filtered(params, boundsPart) then
				boundsHits += 1
				return { Position = Vector3.new(origin.X, floorTop + 30, origin.Z), Normal = Vector3.new(0, 1, 0), Instance = boundsPart }
			end
			return { Position = Vector3.new(origin.X, floorTop, origin.Z), Normal = Vector3.new(0, 1, 0), Instance = floorPart }
		end,
	}
	local warnings = {}
	local chunk, err = H.sandbox(source, {
		game = { GetService = function(_, name)
			if name == "Players" then
				return { LocalPlayer = { Character = character } }
			elseif name == "RunService" then
				return { RenderStepped = renderStepped, Heartbeat = newSignal() }
			elseif name == "ReplicatedStorage" then
				return { FindFirstChild = function()
					return nil
				end }
			elseif name == "Workspace" then
				return wsMock
			end
			error("StageWeather asked for an unexpected service " .. tostring(name))
		end },
		workspace = wsMock,
		Instance = { new = makeInstance },
		RaycastParams = { new = function()
			return {}
		end },
		Enum = roblox.Enum,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrame,
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		task = sched.task,
		require = function()
			error("StageWeather required an unexpected module")
		end,
		warn = function(...)
			table.insert(warnings, table.concat({ ... }, " "))
		end,
	}, "StageWeather")
	if T.check(chunk ~= nil, "H5: StageWeather does not load: %s", tostring(err)) then
		sched.task.spawn(chunk)
		T.check(#sched.threads == 1, "H5: StageWeather must keep exactly one polling loop")
		local function frames(count)
			for i = 1, count do
				renderStepped:Fire(1 / 60)
				if i % 15 == 0 then
					sched.tick()
				end
			end
		end
		local function byName(pattern)
			local list = {}
			for _, inst in ipairs(created) do
				local p = propsOf(inst)
				if string.match(p.Name, pattern) and p.ClassName == "ParticleEmitter" then
					table.insert(list, p)
				end
			end
			return list
		end
		local function streakRate()
			local total = 0
			for _, p in ipairs(byName("^Streaks%d$")) do
				total += if p.Enabled then p.Rate else 0
			end
			return total
		end

		-- hub, stage 1 and stage 3: nothing is built, nothing runs
		for _, x in ipairs({ 37, 120, 165, 330, 420 }) do
			placeCamera(x, -30)
			frames(30)
		end
		T.check(#created == 0 and #renderStepped.handlers == 0, "H5: outside the Lake no rain may be built or run (created %d, render handlers %d)", #created, #renderStepped.handlers)

		-- walk into the Lake: built once, fades in
		placeCamera(lakeStage.xMin + 3, -30)
		frames(15)
		T.check(#renderStepped.handlers == 1, "H5: entering the Lake must start the per-frame rain update")
		placeCamera(243, -30)
		frames(240)
		local builtCount = #created
		local classes = {}
		for _, inst in ipairs(created) do
			local p = propsOf(inst)
			classes[p.ClassName] = (classes[p.ClassName] or 0) + 1
			if p.ClassName == "ParticleEmitter" then
				T.check(type(p.Texture) == "string" and BUILTIN_PARTICLE_TEXTURES[p.Texture] == true, "H5: %s texture %s is not built-in", p.Name, tostring(p.Texture))
				T.check(p.LockedToPart == false, "H5: %s particles must stay in the world (LockedToPart = false)", p.Name)
			elseif p.ClassName == "Part" then
				T.check(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch and p.Transparency == 1 and not p.CastShadow,
					"H5: weather part %s must be invisible, anchored and non-interactive", p.Name)
			end
		end
		T.check(classes.Sound == nil, "H5: StageWeather must not create sounds")
		T.check((classes.ParticleEmitter or 0) >= 6 and (classes.Attachment or 0) >= 8, "H5: expected rain emitters and a splash pool, found %d emitters / %d attachments",
			classes.ParticleEmitter or 0, classes.Attachment or 0)
		local folder = nil
		for _, inst in ipairs(created) do
			if propsOf(inst).ClassName == "Folder" then
				folder = propsOf(inst)
			end
		end
		T.check(folder ~= nil and folder.Parent == camera, "H5: the weather instances must live under the local camera (client only)")
		local farRate = streakRate()
		T.check(farRate > 150, "H5: inside the Lake the rain ceiling must emit streaks (total rate %.0f)", farRate)
		for _, p in ipairs(byName("^Streaks%d$")) do
			T.check(p.Rate <= 420 and tostring(p.Orientation) == "Enum.ParticleOrientation.VelocityParallel" and tostring(p.EmissionDirection) == "Enum.NormalId.Bottom",
				"H5: streak emitters fall downward as velocity-aligned streaks, capped per emitter")
		end
		local ceiling = nil
		for _, inst in ipairs(created) do
			if propsOf(inst).Name == "RainCeiling" then
				ceiling = propsOf(inst)
			end
		end
		if T.check(ceiling ~= nil, "H5: RainCeiling sheet missing") then
			local cp = ceiling.CFrame.Position
			local camPos = camera.CFrame.Position
			T.check(cp.Y > camPos.Y + 30 and math.abs(cp.X - camPos.X) < 60 and math.abs(cp.Z - camPos.Z) < 60,
				"H5: the rain ceiling must follow the camera from above (ceiling %s, camera %s)", tostring(cp), tostring(camPos))
		end
		local splashes, onFloor, inRegion = 0, 0, 0
		for _, e in ipairs(emits) do
			if e.name == "Ripple" then
				splashes += 1
				if e.at and math.abs(e.at.Y - floorTop) < 0.2 then
					onFloor += 1
				end
				if e.at and e.at.X >= lakeStage.xMin - 0.5 and e.at.X <= lakeStage.xMax + 0.5 then
					inRegion += 1
				end
			end
		end
		T.check(splashes > 100, "H5: the rain must splash on the ground (%d ripples in 4 s)", splashes)
		T.check(onFloor == splashes and inRegion == splashes, "H5: splashes must land on the surface under the rain inside the stage (%d/%d on the floor, %d in the stage)", onFloor, splashes, inRegion)
		T.check(boundsHits >= 1 and boundsHits <= 3, "H5: an invisible part over the floor must be excluded once, not block the splashes (%d hits)", boundsHits)

		-- keep raining while moving around (to the stage edge): no instance is created per frame, the sheet stays in the stage
		local emitsBefore = #emits
		for step = 0, 20 do
			placeCamera(250 + step * 3.2, -30 + step)
			frames(30)
		end
		T.check(#created == builtCount, "H5: no instance may be created per frame (%d -> %d)", builtCount, #created)
		T.check(#emits > emitsBefore + 200, "H5: splashes must keep coming while it rains")
		if ceiling then
			local cp, size = ceiling.CFrame.Position, ceiling.Size
			T.check(cp.X + size.X / 2 <= lakeStage.xMax + 1, "H5: the rain must stop at the stage border (ceiling reaches X %.1f)", cp.X + size.X / 2)
		end
		T.check(flashPeak > 0.05, "H5: lightning flashes must happen while it rains (peak brightness %.2f)", flashPeak)

		-- under a roof most of the streaks stop
		placeCamera(243, -30)
		frames(60)
		local openRate = streakRate()
		roof = true
		frames(90)
		local roofRate = streakRate()
		T.check(roofRate < openRate * 0.4, "H5: under a roof the streaks must thin out (%.0f -> %.0f)", openRate, roofRate)
		roof = false
		frames(90)

		-- leave the Lake: everything fades out and stops
		placeCamera(420, -30)
		frames(180)
		T.check(streakRate() == 0 and #renderStepped.handlers == 0, "H5: leaving the Lake must stop the rain (rate %.0f, render handlers %d)", streakRate(), #renderStepped.handlers)
		for _, p in ipairs(byName(".")) do
			if p.Name ~= "Ripple" and p.Name ~= "Droplets" and p.Name ~= "Puff" then
				T.check(not p.Enabled, "H5: %s must be disabled outside the Lake", p.Name)
			end
		end
		local emitsOut = #emits
		frames(60)
		T.check(#emits == emitsOut, "H5: no splashes outside the Lake")

		-- back in: the same instances are reused
		placeCamera(200, 30)
		frames(180)
		T.check(streakRate() > 150 and #created == builtCount, "H5: re-entering the Lake must reuse the rain (rate %.0f, created %d -> %d)", streakRate(), builtCount, #created)
		for _ = 1, 20 do
			sched.tick()
		end
		T.check(#sched.errors == 0, "H5: StageWeather errored: %s", table.concat(sched.errors, " | "))
		T.check(#warnings == 0, "H5: StageWeather warned: %s", table.concat(warnings, " | "))
	end
end

for _, path in ipairs({ "Game/VillainChaseFx", "Game/StageAmbience", "Game/StageWeather" }) do
	local script = sps and H.path(sps, path)
	if T.check(script ~= nil, "StarterPlayerScripts.%s missing", path) then
		T.check(not string.find(script.Source, "Instance%.new%(%s*\"Sound\""), "%s must not create sounds (A12: silent chase effects)", path)
	end
end
local hazardService = place:GetService("ServerScriptService"):FindFirstChild("StageHazardService")
T.check(hazardService ~= nil and not string.find(hazardService.Source, "Instance%.new%(%s*\"Sound\""), "StageHazardService must stay silent")
