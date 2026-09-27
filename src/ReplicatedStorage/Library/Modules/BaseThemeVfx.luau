-- ReplicatedStorage.Library.Modules.BaseThemeVfx
-- Themed ambience around the six themed bases (owner 2026-09-26: "add some vfx to the bases for each one, something
-- related to their theme, for example One Piece can be like gusts of wind around it"). Built on each client by
-- StarterPlayerScripts.Game.Plots.BaseThemeVfxController while a plot wears the theme (its BaseTheme attribute),
-- destroyed when the theme changes. Accents, not fog: low rates, high transparency.
--
--   Volcano  One Piece      sea-wind gusts swirling around the base, spray bursts along the wharf edge, drifting embers
--   Forest   Avengers       hologram data rings rising from the floor emblem and the tower, data motes, cyan
--                            electricity arcs crackling across the gate and at the corner pylons
--   Lake     Justice League soft celestial sunbeams slanting down into the pen, golden sparkles drifting down
--   Desert   Spider-Verse   magenta / cyan glitch flickers around the rooftop, drifting urban dust, web strands
--                            between the crest, the corner pylons and the skyline
--   Jungle   My Hero Aca.   training-arena dust kicks and explosive amber spark bursts (with a flash and a smoke puff)
--                            over a faint arena haze
--   Snow     Dragon Ball    blue / golden ki auras pulsing up from the floor (a ki ring at each pulse), rising sparks
--
-- Everything hangs on invisible anchor Parts (Transparency 1, Anchored, CanCollide / CanQuery / CanTouch / CastShadow
-- false) in a client folder: ParticleEmitters and Beams only, built-in engine particle textures only
-- (rbxasset://textures/particles/*), no light objects and no glowing materials. The controller switches a base off
-- beyond ACTIVE_DISTANCE studs from the camera and scales every rate by MOBILE_RATE_SCALE on touch devices.
-- Pen frame: CFrame.fromMatrix(PenOrigin, GateRight, up, -GateOutward): local x = v (across), y = h, z = -u (the gate
-- is at z = -PenHalfDepth). Loadable with Lune for the offline tests (no services at file scope).

local Vfx = {}

Vfx.ACTIVE_DISTANCE = 180 -- studs from the camera: farther bases are switched off
Vfx.UPDATE_INTERVAL = 0.1 -- the controller's tick (bursts / flicker / pulses)
Vfx.MOBILE_RATE_SCALE = 0.5 -- touch devices: half the particles
Vfx.RATE_BUDGET = 40 -- continuous particles per second of one base at full scale (bursts come on top, capped)
Vfx.BURST_CAP = 16 -- particles of one Emit call at full scale

Vfx.TEXTURES = {
	Sparkles = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Sparks = "rbxasset://textures/particles/fire_sparks_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Ring = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	Core = "rbxasset://textures/particles/explosion01_core_main.dds",
	Glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function seq(points)
	if type(points) == "number" then
		return NumberSequence.new(points)
	end
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function colours(a, b)
	return ColorSequence.new(a, b or a)
end

local function rand(a, b)
	return a + (b - a) * math.random()
end

-- pen-local point / frame: v across, h up, u toward the gate
local function at(v, h, u)
	return CFrame.new(v, h, -u)
end

---------------------------------------------------------------------------------------------------
-- building blocks
---------------------------------------------------------------------------------------------------

local Fx = {}
Fx.__index = Fx

local function anchor(fx, name, localCf, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size or Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = fx.frame * localCf
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Parent = fx.model
	table.insert(fx.anchors, part)
	return part
end

-- A ParticleEmitter on `part`. rate > 0: continuous (on while the base is active, rate x the device scale);
-- rate = 0: a burst emitter (stays disabled, the theme's update calls fx:Emit).
local function emitter(fx, part, name, rate, props)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = props.Texture or Vfx.TEXTURES.Sparkles
	e.Enabled = false
	e.Rate = rate * fx.rateScale
	e.LightInfluence = props.LightInfluence or 0.6
	e.LightEmission = props.LightEmission or 0
	e.Lifetime = props.Lifetime or NumberRange.new(1, 2)
	e.Speed = props.Speed or NumberRange.new(1, 2)
	e.Size = props.Size or seq(0.5)
	e.Transparency = props.Transparency or seq(0.3)
	e.Color = props.Color or colours(rgb(255, 255, 255))
	e.SpreadAngle = props.SpreadAngle or Vector2.new(0, 0)
	e.EmissionDirection = props.EmissionDirection or Enum.NormalId.Top
	e.Acceleration = props.Acceleration or Vector3.new(0, 0, 0)
	e.Drag = props.Drag or 0
	e.Rotation = props.Rotation or NumberRange.new(0, 360)
	e.RotSpeed = props.RotSpeed or NumberRange.new(0, 0)
	e.Orientation = props.Orientation or Enum.ParticleOrientation.FacingCamera
	if props.Squash then
		e.Squash = props.Squash
	end
	if props.Box then
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	end
	e.LockedToPart = false
	e.Parent = part
	local entry = { emitter = e, rate = rate, continuous = rate > 0 }
	table.insert(fx.emitters, entry)
	return entry
end

-- An attachment on `part` at part-local `cf`.
local function attach(part, name, cf)
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = cf
	a.Parent = part
	return a
end

local function newBeam(fx, part, name, a0, a1, props, static)
	local b = Instance.new("Beam")
	b.Name = name
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Enabled = false
	b.FaceCamera = true
	b.Segments = props.Segments or 1
	b.Width0 = props.Width0 or 0.1
	b.Width1 = props.Width1 or props.Width0 or 0.1
	b.Color = props.Color or colours(rgb(255, 255, 255))
	b.Transparency = props.Transparency or seq(0.3)
	b.LightEmission = props.LightEmission or 0
	b.LightInfluence = props.LightInfluence or 1
	b.CurveSize0 = props.CurveSize0 or 0
	b.CurveSize1 = props.CurveSize1 or 0
	b.Parent = part
	local entry = { beam = b, static = static }
	table.insert(fx.beams, entry)
	return entry
end

-- Emits `count` (x the device scale, at least 1, at most BURST_CAP) particles from a burst emitter.
function Fx:Emit(entry, count)
	local n = math.clamp(math.floor(count * self.rateScale + 0.5), 1, Vfx.BURST_CAP)
	local e = entry.emitter
	pcall(function()
		e:Emit(n)
	end)
end

-- Moves an anchor part to pen-local `localCf`.
function Fx:Place(part, localCf)
	part.CFrame = self.frame * localCf
end

function Fx:SetActive(active)
	self.active = active
	for _, entry in ipairs(self.emitters) do
		if entry.continuous then
			entry.emitter.Enabled = active
		end
	end
	for _, entry in ipairs(self.beams) do
		if entry.static or not active then
			entry.beam.Enabled = active and entry.static == true
		end
	end
end

-- A continuous emitter's rate x `factor` (gusts, pulses).
function Fx:Modulate(entry, factor)
	entry.emitter.Rate = entry.rate * self.rateScale * math.max(factor, 0)
end

-- One controller tick (only while active). The themes' timers run on the effect's own clock (seconds since its first
-- update), so every base starts its bursts / pulses at its own pace.
function Fx:Update(now, dt)
	if self.active and self.theme.update then
		if self.born == nil then
			self.born = now
		end
		self.theme.update(self, now - self.born, dt)
	end
end

function Fx:Destroy()
	self.active = false
	if self.model then
		self.model:Destroy()
	end
	self.emitters, self.beams, self.anchors = {}, {}, {}
end

-- Sum of the continuous rates at full scale (the offline tests hold it under RATE_BUDGET).
function Fx:BaseRate()
	local total = 0
	for _, entry in ipairs(self.emitters) do
		if entry.continuous then
			total += entry.rate * (entry.peak or 1)
		end
	end
	return total
end

---------------------------------------------------------------------------------------------------
-- themes
---------------------------------------------------------------------------------------------------

Vfx.Themes = {}

-- One Piece: sea-wind gusts looping around the base, spray on the wharf edge, embers drifting with the wind.
Vfx.Themes.Volcano = {
	Name = "Sea-wind gusts, wharf spray, embers",
	build = function(fx)
		local D, W = fx.D, fx.W
		local s = fx.state
		s.gusts = {}
		-- each side blows along the base (a loop: front +v, right toward the back, back -v, left toward the front) and
		-- curls a little toward the next side, so the wisps swirl around the corners
		local sides = {
			{ at(-0.15 * W, 6, D + 1.6), 0, 2 * W, Vector3.new(0, 0, 1) },
			{ at(W + 1.6, 6, 0.15 * D), -math.pi / 2, 2 * D, Vector3.new(-1, 0, 0) },
			{ at(0.15 * W, 6, -D - 1.6), math.pi, 2 * W, Vector3.new(0, 0, -1) },
			{ at(-W - 1.6, 6, -0.15 * D), math.pi / 2, 2 * D, Vector3.new(1, 0, 0) },
		}
		for i, side in ipairs(sides) do
			local part = anchor(fx, "Gust" .. i, side[1] * CFrame.Angles(0, side[2], 0), Vector3.new(side[3] * 0.7, 7, 1.5))
			local entry = emitter(fx, part, "SeaWind", 2.4, {
				Texture = Vfx.TEXTURES.Smoke,
				Box = true,
				EmissionDirection = Enum.NormalId.Right,
				Color = colours(rgb(232, 245, 255), rgb(200, 228, 255)),
				Transparency = seq({ { 0, 1 }, { 0.25, 0.8 }, { 0.75, 0.86 }, { 1, 1 } }),
				Size = seq({ { 0, 1.3 }, { 1, 3.4 } }),
				Squash = seq({ { 0, 1.1 }, { 1, 1.8 } }),
				Orientation = Enum.ParticleOrientation.VelocityParallel,
				Lifetime = NumberRange.new(1.0, 1.5),
				Speed = NumberRange.new(14, 19),
				SpreadAngle = Vector2.new(6, 10),
				Acceleration = fx.frame:VectorToWorldSpace(side[4] * 5),
				Drag = 0.3,
				LightEmission = 0.15,
				LightInfluence = 1,
			})
			entry.peak = 1.45
			table.insert(s.gusts, entry)
		end
		-- spray on the wharf edge (the front, under the Sunny's bow)
		s.spray = {}
		for i, v in ipairs({ -(W - 5), -0.45 * W, 0.45 * W, W - 5 }) do
			local part = anchor(fx, "Spray" .. i, at(v, 0.4, D + 2.1))
			local entry = emitter(fx, part, "Spray", 0, {
				Texture = Vfx.TEXTURES.Smoke,
				Color = colours(rgb(242, 250, 255), rgb(190, 230, 250)),
				Transparency = seq({ { 0, 0.35 }, { 1, 1 } }),
				Size = seq({ { 0, 0.5 }, { 1, 1.7 } }),
				Lifetime = NumberRange.new(0.8, 1.1),
				Speed = NumberRange.new(7, 11),
				SpreadAngle = Vector2.new(16, 16),
				Acceleration = Vector3.new(0, -24, 0),
				Drag = 1,
				LightEmission = 0.2,
				LightInfluence = 1,
				RotSpeed = NumberRange.new(-40, 40),
			})
			table.insert(s.spray, { entry = entry, nextAt = rand(0.2, 2) })
		end
		-- embers drifting up and away with the wind
		local embers = anchor(fx, "Embers", at(0, 0.8, 0), Vector3.new(2 * W - 6, 0.5, 2 * D - 6))
		emitter(fx, embers, "Embers", 3, {
			Box = true,
			Texture = Vfx.TEXTURES.Sparkles,
			Color = colours(rgb(255, 170, 70), rgb(255, 90, 40)),
			Transparency = seq({ { 0, 0.1 }, { 0.8, 0.4 }, { 1, 1 } }),
			Size = seq({ { 0, 0.22 }, { 1, 0.06 } }),
			Lifetime = NumberRange.new(4, 6),
			Speed = NumberRange.new(1.2, 2.4),
			SpreadAngle = Vector2.new(25, 25),
			Acceleration = fx.frame:VectorToWorldSpace(Vector3.new(1, 0.4, -0.6)),
			LightEmission = 1,
			LightInfluence = 0,
			RotSpeed = NumberRange.new(-90, 90),
		})
	end,
	update = function(fx, now)
		local s = fx.state
		for i, entry in ipairs(s.gusts) do
			-- gusts: every side swells and fades on its own beat
			local gust = math.max(0, math.sin(now * 0.9 + i * 1.7))
			fx:Modulate(entry, 0.55 + 0.9 * gust * gust)
		end
		for _, spot in ipairs(s.spray) do
			if now >= spot.nextAt then
				spot.nextAt = now + rand(1.0, 2.2)
				fx:Emit(spot.entry, 5)
			end
		end
	end,
}

-- Avengers: hologram data rings, data motes, cyan electricity arcs.
Vfx.Themes.Forest = {
	Name = "Hologram rings, data motes, electricity arcs",
	build = function(fx)
		local D, W, gx, g = fx.D, fx.W, fx.gx, fx.gate
		local cyan = rgb(95, 211, 255)
		local floor = anchor(fx, "Emblem", at(0, 0.35, 0), Vector3.new(1, 0.2, 1))
		emitter(fx, floor, "DataRings", 0.7, {
			Texture = Vfx.TEXTURES.Ring,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			Color = colours(cyan),
			Transparency = seq({ { 0, 1 }, { 0.12, 0.55 }, { 0.7, 0.72 }, { 1, 1 } }),
			Size = seq({ { 0, 4.5 }, { 0.5, 6.5 }, { 1, 7.5 } }),
			Lifetime = NumberRange.new(3.2, 3.8),
			Speed = NumberRange.new(1.6, 2.1),
			LightEmission = 0.9,
			LightInfluence = 0,
			RotSpeed = NumberRange.new(-15, 15),
		})
		local motes = anchor(fx, "Motes", at(0, 0.4, 0), Vector3.new(12, 0.2, 12))
		emitter(fx, motes, "DataMotes", 5, {
			Box = true,
			Texture = Vfx.TEXTURES.Sparkles,
			Color = colours(rgb(150, 230, 255), cyan),
			Transparency = seq({ { 0, 0.2 }, { 1, 1 } }),
			Size = seq({ { 0, 0.16 }, { 1, 0.05 } }),
			Lifetime = NumberRange.new(1.8, 2.6),
			Speed = NumberRange.new(1.5, 3),
			SpreadAngle = Vector2.new(8, 8),
			LightEmission = 1,
			LightInfluence = 0,
		})
		-- radar pings over the gate tower
		local towerV = gx + g.vMax + g.wRight / 2
		local tower = anchor(fx, "TowerTop", at(towerV, 15.9, D + (g.uMin + g.uMax) / 2), Vector3.new(0.5, 0.2, 0.5))
		emitter(fx, tower, "TowerRings", 0.45, {
			Texture = Vfx.TEXTURES.Ring,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			Color = colours(cyan),
			Transparency = seq({ { 0, 0.4 }, { 1, 1 } }),
			Size = seq({ { 0, 1.4 }, { 1, 3.6 } }),
			Lifetime = NumberRange.new(2.2, 2.8),
			Speed = NumberRange.new(0.8, 1.2),
			LightEmission = 0.9,
			LightInfluence = 0,
		})
		-- electricity arcs: three chained beams per arc, re-zig-zagged while an arc crackles
		local hub = anchor(fx, "Arcs", at(0, 0, 0))
		local uMid = D + (g.uMin + g.uMax) / 2
		local arcs = {
			{ Vector3.new(gx + g.vMin - g.wLeft / 2, math.min(g.top + 0.75, 8.3), -uMid), Vector3.new(gx + 0.75, 9.4, -uMid) },
			{ Vector3.new(-W, 3.3, -D), Vector3.new(-W + 3.6, 2.7, -D) },
			{ Vector3.new(W, 3.3, -D), Vector3.new(W, 2.7, -D + 3.6) },
			{ Vector3.new(-W, 3.3, D), Vector3.new(-W, 2.7, D - 3.6) },
			{ Vector3.new(W, 3.3, D), Vector3.new(W - 3.6, 2.7, D) },
		}
		fx.state.arcs = {}
		for i, ends in ipairs(arcs) do
			local points = {}
			for k = 0, 3 do
				points[k + 1] = attach(hub, string.format("Arc%d_%d", i, k), CFrame.new(ends[1]:Lerp(ends[2], k / 3)))
			end
			local beams = {}
			for k = 1, 3 do
				table.insert(beams, newBeam(fx, hub, "Arc" .. i, points[k], points[k + 1], {
					Width0 = 0.16,
					Width1 = 0.12,
					Color = colours(rgb(170, 235, 255)),
					Transparency = seq(0.05),
					LightEmission = 1,
					LightInfluence = 0,
				}, false))
			end
			table.insert(fx.state.arcs, { a = ends[1], b = ends[2], points = points, beams = beams, nextAt = rand(0.5, 3), endAt = 0 })
		end
	end,
	update = function(fx, now)
		for _, arc in ipairs(fx.state.arcs) do
			if now >= arc.nextAt then
				arc.nextAt = now + rand(1.5, 4.5)
				arc.endAt = now + 0.35
			end
			local live = now < arc.endAt
			if live then
				local span = arc.b - arc.a
				local jitter = math.max(span.Magnitude * 0.12, 0.35)
				for k = 2, 3 do
					local base = arc.a:Lerp(arc.b, (k - 1) / 3)
					arc.points[k].CFrame = CFrame.new(base + Vector3.new(rand(-jitter, jitter), rand(-jitter, jitter), rand(-jitter, jitter)))
				end
			end
			for _, entry in ipairs(arc.beams) do
				entry.beam.Enabled = live and math.random() < 0.8
			end
		end
	end,
}

-- Justice League: slanted celestial sunbeams and golden sparkles drifting down.
Vfx.Themes.Lake = {
	Name = "Celestial sunbeams, golden sparkles",
	build = function(fx)
		local D, W = fx.D, fx.W
		local sky = anchor(fx, "Sky", at(0, 0, 0))
		fx.state.rays = {}
		for i, spot in ipairs({ { -0.46, -0.3 }, { 0.27, 0.19 }, { 0.57, -0.57 }, { -0.19, 0.55 } }) do
			local v, u = spot[1] * W, spot[2] * D
			local foot = attach(sky, "RayFoot" .. i, CFrame.new(v, 0.3, -u))
			local head = attach(sky, "RayHead" .. i, CFrame.new(v + 6, 34, -u + 3))
			table.insert(fx.state.rays, newBeam(fx, sky, "Sunbeam", head, foot, {
				Width0 = 3.2,
				Width1 = 6.5,
				Color = colours(rgb(255, 240, 200), rgb(255, 226, 150)),
				Transparency = seq({ { 0, 1 }, { 0.25, 0.8 }, { 0.8, 0.86 }, { 1, 1 } }),
				LightEmission = 1,
				LightInfluence = 0,
			}, true))
		end
		local cloud = anchor(fx, "Sparkles", at(0, 11, 0), Vector3.new(2 * W - 8, 1, 2 * D - 8))
		emitter(fx, cloud, "GoldSparkles", 6, {
			Box = true,
			Texture = Vfx.TEXTURES.Sparkles,
			EmissionDirection = Enum.NormalId.Bottom,
			Color = colours(rgb(255, 214, 96), rgb(255, 245, 200)),
			Transparency = seq({ { 0, 0.1 }, { 1, 0.6 } }),
			Size = seq({ { 0, 0.1 }, { 0.2, 0.4 }, { 1, 0 } }),
			Lifetime = NumberRange.new(5, 7),
			Speed = NumberRange.new(1, 1.8),
			SpreadAngle = Vector2.new(15, 15),
			Drag = 0.3,
			LightEmission = 1,
			LightInfluence = 0,
			RotSpeed = NumberRange.new(-60, 60),
		})
	end,
	update = function(fx, now)
		for i, entry in ipairs(fx.state.rays) do
			entry.beam.Brightness = 0.8 + 0.35 * math.sin(now * 0.6 + i * 1.3)
		end
	end,
}

-- Spider-Verse: glitch flickers, urban dust, web strands.
Vfx.Themes.Desert = {
	Name = "Glitch flickers, urban dust, web strands",
	build = function(fx)
		local D, W, gx = fx.D, fx.W, fx.gx
		local s = fx.state
		local glitch = anchor(fx, "Glitch", at(0, 8, D))
		local function glitchEmitter(name, colour)
			return emitter(fx, glitch, name, 0, {
				Texture = Vfx.TEXTURES.Glow,
				Color = colours(colour),
				Transparency = seq(0.15),
				Size = seq(1.7),
				Squash = seq(-2.4),
				Lifetime = NumberRange.new(0.06, 0.14),
				Speed = NumberRange.new(0, 0),
				Rotation = NumberRange.new(0, 0),
				LightEmission = 1,
				LightInfluence = 0,
			})
		end
		s.glitchPart = glitch
		s.magenta = glitchEmitter("GlitchMagenta", rgb(255, 47, 180))
		s.cyan = glitchEmitter("GlitchCyan", rgb(34, 228, 255))
		s.spots = {
			{ gx - 3, 10.5, D + 0.5 }, { gx + 3, 11.5, D + 0.5 }, { -W, 8.2, D }, { W, 8.2, D }, { -W, 8.2, -D }, { W, 8.2, -D },
			{ -10, 20, -D - 6 }, { 8, 25, -D - 6 }, { 0, 29, -D - 8 },
		}
		s.nextAt, s.subs = 1, {}
		local dust = anchor(fx, "Dust", at(0, 1.6, 0), Vector3.new(2 * W, 2.5, 2 * D))
		emitter(fx, dust, "UrbanDust", 3, {
			Box = true,
			Texture = Vfx.TEXTURES.Smoke,
			Color = colours(rgb(196, 176, 160), rgb(160, 150, 150)),
			Transparency = seq({ { 0, 1 }, { 0.3, 0.9 }, { 0.7, 0.92 }, { 1, 1 } }),
			Size = seq({ { 0, 0.5 }, { 1, 1.4 } }),
			Lifetime = NumberRange.new(5, 8),
			Speed = NumberRange.new(0.4, 1.0),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = fx.frame:VectorToWorldSpace(Vector3.new(0.6, 0.05, 0.2)),
			RotSpeed = NumberRange.new(-25, 25),
			LightInfluence = 1,
		})
		-- web strands: attachments whose axis points down, so the curve sags like silk
		local web = anchor(fx, "Web", at(0, 0, 0))
		local function point(name, v, h, u)
			return attach(web, name, CFrame.fromMatrix(Vector3.new(v, h, -u), Vector3.new(0, -1, 0), Vector3.new(1, 0, 0)))
		end
		local crestL, crestR = point("CrestL", gx - 5.3, 13.2, D + 0.55), point("CrestR", gx + 5.3, 13.2, D + 0.55)
		local frontL, frontR = point("FrontL", -W, 7.6, D), point("FrontR", W, 7.6, D)
		local backL, backR = point("BackL", -W, 7.6, -D), point("BackR", W, 7.6, -D)
		local skyL, skyR = point("SkyL", -12, 23, -D - 5), point("SkyR", 12, 23, -D - 5)
		for i, strand in ipairs({
			{ crestL, frontL, 1.2 }, { crestR, frontR, 1.2 }, { frontL, backL, 3.5 }, { frontR, backR, 3.5 },
			{ backL, skyL, 1.5 }, { backR, skyR, 1.5 },
		}) do
			newBeam(fx, web, "WebStrand" .. i, strand[1], strand[2], {
				Width0 = 0.07,
				Width1 = 0.07,
				Segments = 16,
				Color = colours(rgb(236, 236, 246)),
				Transparency = seq(0.3),
				LightEmission = 0.2,
				LightInfluence = 1,
				CurveSize0 = strand[3],
				CurveSize1 = -strand[3],
			}, true)
		end
	end,
	update = function(fx, now)
		local s = fx.state
		if now >= s.nextAt then
			s.nextAt = now + rand(1.4, 3.2)
			local spot = s.spots[math.random(1, #s.spots)]
			for k = 0, 2 do
				table.insert(s.subs, { at = now + k * 0.1, v = spot[1] + rand(-0.6, 0.6), h = spot[2] + rand(-0.5, 0.5), u = spot[3] })
			end
		end
		for i = #s.subs, 1, -1 do
			local sub = s.subs[i]
			if now >= sub.at then
				table.remove(s.subs, i)
				fx:Place(s.glitchPart, at(sub.v, sub.h, sub.u))
				fx:Emit(s.magenta, 2)
				fx:Place(s.glitchPart, at(sub.v + 0.35, sub.h + 0.12, sub.u))
				fx:Emit(s.cyan, 2)
			end
		end
	end,
}

-- My Hero Academia: dust kicks on the training floor and explosive amber spark bursts.
Vfx.Themes.Jungle = {
	Name = "Arena dust kicks, explosive amber sparks",
	build = function(fx)
		local s = fx.state
		s.kickPart = anchor(fx, "Kick", at(0, 0.3, 0))
		s.kick = emitter(fx, s.kickPart, "DustKick", 0, {
			Texture = Vfx.TEXTURES.Smoke,
			Color = colours(rgb(228, 214, 168), rgb(200, 190, 160)),
			Transparency = seq({ { 0, 0.5 }, { 1, 1 } }),
			Size = seq({ { 0, 0.9 }, { 1, 3.0 } }),
			Lifetime = NumberRange.new(0.9, 1.4),
			Speed = NumberRange.new(3, 6.5),
			SpreadAngle = Vector2.new(65, 65),
			Acceleration = Vector3.new(0, -3, 0),
			Drag = 2.5,
			RotSpeed = NumberRange.new(-40, 40),
			LightInfluence = 1,
		})
		s.blastPart = anchor(fx, "Blast", at(0, 2, 0))
		s.sparks = emitter(fx, s.blastPart, "AmberSparks", 0, {
			Texture = Vfx.TEXTURES.Sparks,
			Color = colours(rgb(255, 200, 80), rgb(255, 110, 30)),
			Transparency = seq({ { 0, 0 }, { 1, 0.6 } }),
			Size = seq({ { 0, 0.6 }, { 1, 0.15 } }),
			Lifetime = NumberRange.new(0.35, 0.7),
			Speed = NumberRange.new(9, 17),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, -28, 0),
			Drag = 1.2,
			LightEmission = 1,
			LightInfluence = 0,
		})
		s.flash = emitter(fx, s.blastPart, "BlastFlash", 0, {
			Texture = Vfx.TEXTURES.Core,
			Color = colours(rgb(255, 210, 110)),
			Transparency = seq({ { 0, 0.25 }, { 1, 1 } }),
			Size = seq({ { 0, 1.2 }, { 1, 4.5 } }),
			Lifetime = NumberRange.new(0.16, 0.24),
			Speed = NumberRange.new(0, 0),
			LightEmission = 1,
			LightInfluence = 0,
		})
		s.puff = emitter(fx, s.blastPart, "BlastSmoke", 0, {
			Texture = Vfx.TEXTURES.Smoke,
			Color = colours(rgb(90, 84, 80)),
			Transparency = seq({ { 0, 0.55 }, { 1, 1 } }),
			Size = seq({ { 0, 1 }, { 1, 3.5 } }),
			Lifetime = NumberRange.new(0.8, 1.2),
			Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 2,
			LightInfluence = 1,
		})
		-- between bursts: a faint arena haze drifting over the pitch
		local haze = anchor(fx, "Haze", at(0, 1.2, 0), Vector3.new(2 * fx.W - 6, 1.5, 2 * fx.D - 6))
		emitter(fx, haze, "ArenaHaze", 2, {
			Box = true,
			Texture = Vfx.TEXTURES.Smoke,
			Color = colours(rgb(236, 224, 188)),
			Transparency = seq({ { 0, 1 }, { 0.3, 0.9 }, { 0.7, 0.92 }, { 1, 1 } }),
			Size = seq({ { 0, 0.6 }, { 1, 1.6 } }),
			Lifetime = NumberRange.new(4, 6),
			Speed = NumberRange.new(0.3, 0.8),
			SpreadAngle = Vector2.new(180, 180),
			RotSpeed = NumberRange.new(-20, 20),
			LightInfluence = 1,
		})
		s.kickAt, s.blastAt = rand(0.3, 1.5), rand(1, 3)
	end,
	update = function(fx, now)
		local s = fx.state
		local D, W = fx.D, fx.W
		if now >= s.kickAt then
			s.kickAt = now + rand(1.1, 2.4)
			fx:Place(s.kickPart, at(rand(-(W - 5), W - 5), 0.3, rand(-(D - 5), D - 5)))
			fx:Emit(s.kick, 7)
		end
		if now >= s.blastAt then
			s.blastAt = now + rand(2.8, 5.5)
			fx:Place(s.blastPart, at(rand(-(W - 6), W - 6), rand(1.2, 3), rand(-(D - 6), D - 6)))
			fx:Emit(s.sparks, 14)
			fx:Emit(s.flash, 1)
			fx:Emit(s.puff, 3)
		end
	end,
}

-- Dragon Ball: blue / golden ki auras pulsing up from the floor, a ki ring at each peak, rising golden sparks.
Vfx.Themes.Snow = {
	Name = "Ki aura pulses",
	build = function(fx)
		local D, W = fx.D, fx.W
		local blue = { rgb(90, 170, 255), rgb(180, 225, 255) }
		local gold = { rgb(255, 205, 70), rgb(255, 245, 190) }
		fx.state.auras = {}
		for i, spot in ipairs({ { -(W - 6), D - 6, blue }, { W - 6, D - 6, gold }, { 0, 0, gold }, { -(W - 6), -(D - 6), gold }, { W - 6, -(D - 6), blue } }) do
			local part = anchor(fx, "Aura" .. i, at(spot[1], 0.3, spot[2]), Vector3.new(2.4, 0.2, 2.4))
			local flame = emitter(fx, part, "KiAura", 5, {
				Box = true,
				Texture = Vfx.TEXTURES.Fire,
				Color = colours(spot[3][1], spot[3][2]),
				Transparency = seq({ { 0, 0.5 }, { 0.6, 0.72 }, { 1, 1 } }),
				Size = seq({ { 0, 1.1 }, { 0.45, 1.7 }, { 1, 0 } }),
				Lifetime = NumberRange.new(0.9, 1.4),
				Speed = NumberRange.new(2.5, 4),
				SpreadAngle = Vector2.new(6, 6),
				LightEmission = 1,
				LightInfluence = 0,
			})
			local ring = emitter(fx, part, "KiRing", 0, {
				Texture = Vfx.TEXTURES.Ring,
				Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				Color = colours(spot[3][1]),
				Transparency = seq({ { 0, 0.4 }, { 1, 1 } }),
				Size = seq({ { 0, 1.2 }, { 1, 4.2 } }),
				Lifetime = NumberRange.new(1.1, 1.3),
				Speed = NumberRange.new(2.6, 3.2),
				LightEmission = 1,
				LightInfluence = 0,
			})
			table.insert(fx.state.auras, { flame = flame, ring = ring, phase = i * 0.7, wasHigh = false })
		end
		local sparks = anchor(fx, "Sparks", at(0, 0.4, 0), Vector3.new(2 * W - 8, 0.3, 2 * D - 8))
		emitter(fx, sparks, "KiSparks", 2.5, {
			Box = true,
			Texture = Vfx.TEXTURES.Sparkles,
			Color = colours(gold[1], gold[2]),
			Transparency = seq({ { 0, 0.2 }, { 1, 1 } }),
			Size = seq({ { 0, 0.18 }, { 1, 0 } }),
			Lifetime = NumberRange.new(2, 3),
			Speed = NumberRange.new(1.5, 3),
			LightEmission = 1,
			LightInfluence = 0,
		})
	end,
	update = function(fx, now)
		for _, aura in ipairs(fx.state.auras) do
			local wave = math.max(0, math.sin(2 * math.pi * now / 3.4 + aura.phase))
			local pulse = wave * wave
			fx:Modulate(aura.flame, 0.12 + 0.88 * pulse)
			local high = pulse > 0.95
			if high and not aura.wasHigh then
				fx:Emit(aura.ring, 1)
			end
			aura.wasHigh = high
		end
	end,
}

---------------------------------------------------------------------------------------------------
-- api
---------------------------------------------------------------------------------------------------

-- The pen frame of a plot (nil when the build did not write the attributes).
function Vfx.PenFrame(plot)
	local origin = plot:GetAttribute("PenOrigin")
	local outward = plot:GetAttribute("GateOutward")
	local right = plot:GetAttribute("GateRight")
	if typeof(origin) ~= "Vector3" or typeof(outward) ~= "Vector3" or typeof(right) ~= "Vector3" then
		return nil
	end
	return CFrame.fromMatrix(origin, right.Unit, Vector3.new(0, 1, 0), -outward.Unit)
end

-- Builds the ambience of theme `key` (nil for a key without one). layout = { D = pen half depth, W = pen half width,
-- gx = the gate's v in the pen frame, gate = the theme's BaseDoors geometry }. Starts inactive.
function Vfx.Build(key, penFrame, layout, parent, rateScale)
	local theme = Vfx.Themes[key]
	if theme == nil then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "BaseVfx_" .. key
	local fx = setmetatable({
		key = key,
		theme = theme,
		frame = penFrame,
		D = layout.D,
		W = layout.W,
		gx = layout.gx or 0,
		gate = layout.gate,
		rateScale = rateScale or 1,
		model = model,
		anchors = {},
		emitters = {},
		beams = {},
		state = {},
		active = false,
		centre = penFrame.Position,
	}, Fx)
	theme.build(fx)
	model.Parent = parent
	return fx
end

return Vfx
