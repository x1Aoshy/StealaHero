--!nonstrict
-- StarterPlayer.StarterPlayerScripts.BranchControllers.HeroWeaponController (Branch controller; injected by
-- scripts/inject/hero_weapons.luau, started by StarterPlayerScripts.BranchClient)
--
-- Owner 2026-09-27, "MISSION: replace the bat system with Hero Gadgets". The client half of the hero weapons
-- (ReplicatedStorage.Library.Modules.HeroWeapons; server: ServerScriptService.GearService). It draws, moves the local
-- character when the server says so, and sends one thing: the aim point of an aimed weapon's click
-- (Network["Gear: WeaponAim"]: the mouse, a tap in the world, else the red target / the camera's heading).
--   * Attack: the owner's R15 attack clip of the weapon (ReplicatedStorage.Directory.WeaponAnimations.<Id>, generated
--     from assets/hero_weapons/animations/*.rbxmx) is played on the attacker's Motor6D.Transform in PreSimulation,
--     after the Animator (no animation asset): the upper body always, the hips and legs only while standing still, with
--     a short blend in and out of the Animator's pose. Every client plays it for every attacker: the local player's own
--     click starts it at once (same gates and cooldown as the server, the server's echo is ignored), the others come
--     from Network["Gear: BatFx"] { Action = "Swing", Weapon }. The Gum-Gum fist stretches and the Power Pole extends
--     along their clips (HeroWeaponTools.SetGomuTime / SetPoleTime); at the clip's Impact keyframe the attack's own
--     effect plays (Bakugo's blast, Mjolnir's ground slam and lightning, the pole / fist bursts).
--   * Owner 2026-09-27 (round 9): Mjolnir is a jump and a slam into the ground; the Power Pole grows out of the hand
--     (Extend keys of its clip) and sweeps a full turn; the clips marked FullBody play the legs even while running; the
--     attacker's own camera gets a light shake at the Impact keyframe (weapon.Shake).
--   * { Action = "Launch" } / { Action = "ProjectileEnd" }: the aimed throws fly the path the server flies
--     (HeroWeapons.PathPoint): Cap's shield leaves the hand, curves out and comes back, the batarang curves to the aim
--     point and explodes there (Speedsters' Eggman missile blast), the web shoots straight. The thrower's own client
--     starts its throw at once (predicted from its own aim) and adopts the server's flight when it arrives.
--   * { Action = "Hit" }: a themed burst and the whitelisted pop on the victim.
--   * { Action = "Debuff" } / { Action = "DebuffEnd" }: the victim's 2.5 s state, drawn on every client
--       Webbed          a white web net wrapped around them, struggling
--       Electrocuted    flickering lightning arcs, a blue flash, a comic shake
--       CleanKnockback  speed lines and dust while they slide back standing
--       Dazed           yellow stars circling the head, a woozy sway
--       SmokeStun       a smoke cloud where they stand, "?" over the head, a slow sway
--       ExplosionBlast  a comic "BOOM!" explosion, soot on the body, smoke puffs
--       SpinTornado     wind streaks whirling around them
--     and, when the victim is this player, the movement: the knockback slide (CleanKnockback / ExplosionBlast, along
--     Direction for Push studs), the spin (SpinTornado) and the greyed-out screen (SmokeStun). The server holds the
--     WalkSpeed / jump meanwhile.
--   * While a hero weapon is equipped, the rival it would hit glows red (the legacy bat highlight is gone with the
--     old bat scripts).
-- Every effect is local and short-lived; missing optional pieces (particle templates, Audio) just skip that part.
-- Particle textures come from templates already in the place (ReplicatedStorage.Assets); nothing is uploaded.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HeroWeaponController = {}

HeroWeaponController.REMOTE_NAME = "Gear: BatFx"
HeroWeaponController.BLEND_IN = 0.07
HeroWeaponController.BLEND_OUT = 0.12
HeroWeaponController.HIT_SOUND = "rbxassetid://72264591133889" -- Library.Audio UI_POP (audio whitelist)
HeroWeaponController.CARRY_ATTRIBUTE = "CarryingEgg"
HeroWeaponController.DEBUFF_ATTRIBUTE = "HeroDebuff"
HeroWeaponController.TARGET_REFRESH = 0.12
-- Humanoid states in which the character is down: no attacks from there
HeroWeaponController.DOWN_STATES = {
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.Physics] = true,
	[Enum.HumanoidStateType.PlatformStanding] = true,
	[Enum.HumanoidStateType.GettingUp] = true,
	[Enum.HumanoidStateType.Dead] = true,
}
HeroWeaponController.LEG_JOINTS = {
	Root = true, LeftHip = true, LeftKnee = true, LeftAnkle = true, RightHip = true, RightKnee = true, RightAnkle = true,
}

local LocalPlayer = Players.LocalPlayer
local HeroWeapons, Kit, ClipMath = nil, nil, nil
local stepSignal = RunService.Stepped
pcall(function()
	stepSignal = RunService.PreSimulation
end)

local function warnf(message)
	warn("[HeroWeaponController] " .. message)
end

local function requireOptional(parent, name)
	local module = parent and parent:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			return result
		end
		warnf(name .. " failed to load: " .. tostring(result))
	end
	return nil
end

----------------------------------------------------------------------------------------------------
-- small helpers
----------------------------------------------------------------------------------------------------

local effectsFolder = nil
local function fxFolder()
	if effectsFolder == nil or effectsFolder.Parent == nil then
		effectsFolder = Workspace:FindFirstChild("HeroWeaponFx")
		if not effectsFolder then
			effectsFolder = Instance.new("Folder")
			effectsFolder.Name = "HeroWeaponFx"
			effectsFolder.Parent = Workspace
		end
	end
	return effectsFolder
end

local function later(seconds, instance)
	task.delay(seconds, function()
		if instance and instance.Parent then
			instance:Destroy()
		end
	end)
end

local function characterParts(character)
	if not character or not character.Parent then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return nil
	end
	return humanoid, root
end

-- A victim's character: a Player's, or the admin panel's training dummy Model itself.
local function characterOfPlayer(victim)
	if typeof(victim) == "Instance" then
		if victim:IsA("Player") then
			return victim.Character
		elseif victim:IsA("Model") then
			return victim
		end
	end
	return nil
end

local function rightHandOf(character)
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	return if hand and hand:IsA("BasePart") then hand else nil
end

local function heldTool(character)
	for _, child in ipairs(character and character:GetChildren() or {}) do
		if child:IsA("Tool") and child:GetAttribute("HeroWeaponId") ~= nil then
			return child
		end
	end
	return nil
end

-- Hides / shows the parts of a tool's section (a thrown batarang / shield) on this client only.
local function setSectionHidden(tool, sections, hidden)
	for _, part in ipairs(tool and tool:GetChildren() or {}) do
		if part:IsA("BasePart") then
			local section = part:GetAttribute("HeroSection")
			if sections == nil or sections[section or "Handle"] then
				part.LocalTransparencyModifier = if hidden then 1 else 0
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
-- particle templates already in the place (ReplicatedStorage.Assets)
----------------------------------------------------------------------------------------------------

local templateCache = {}
-- The ParticleEmitters under ReplicatedStorage.<path> (optionally only the named ones), cached.
local function emittersAt(path, names)
	local key = path .. "|" .. (names and table.concat(names, ",") or "*")
	local cached = templateCache[key]
	if cached then
		return cached
	end
	local node = ReplicatedStorage
	for segment in string.gmatch(path, "[^/]+") do
		node = node and node:FindFirstChild(segment)
	end
	local list = {}
	if node then
		local wanted = nil
		if names then
			wanted = {}
			for _, name in ipairs(names) do
				wanted[name] = true
			end
		end
		local all = node:GetDescendants()
		if node:IsA("ParticleEmitter") then
			table.insert(all, node)
		end
		for _, d in ipairs(all) do
			if d:IsA("ParticleEmitter") and (wanted == nil or wanted[d.Name]) then
				table.insert(list, d)
			end
		end
	end
	templateCache[key] = list
	return list
end

local function scaledSequence(sequence, factor)
	local points = {}
	for _, point in ipairs(sequence.Keypoints) do
		table.insert(points, NumberSequenceKeypoint.new(point.Time, point.Value * factor, point.Envelope * factor))
	end
	return NumberSequence.new(points)
end

-- Clones the templates onto `attachment`. options: Emit (count; else the template's EmitCount attribute), Enabled
-- (keep emitting), Scale (size factor), Color (ColorSequence override), Max (cap per emitter).
local function attachEmitters(attachment, templates, options)
	options = options or {}
	local made = {}
	for _, template in ipairs(templates) do
		local emitter = template:Clone()
		emitter.Enabled = options.Enabled == true
		emitter.LockedToPart = options.Locked == true
		if options.Scale and options.Scale ~= 1 then
			emitter.Size = scaledSequence(emitter.Size, options.Scale)
		end
		if options.Color then
			emitter.Color = options.Color
		end
		if options.Rate then
			emitter.Rate = options.Rate
		end
		if options.Orientation then
			emitter.Orientation = options.Orientation
		end
		if options.Direction then
			emitter.EmissionDirection = options.Direction
		end
		if options.Speed then
			emitter.Speed = options.Speed
		end
		if options.Lifetime then
			emitter.Lifetime = options.Lifetime
		end
		if options.SpeedScale and options.SpeedScale ~= 1 then
			emitter.Speed = NumberRange.new(emitter.Speed.Min * options.SpeedScale, emitter.Speed.Max * options.SpeedScale)
		end
		emitter.Parent = attachment
		if options.Enabled ~= true then
			local count = options.Emit or tonumber(template:GetAttribute("EmitCount")) or 6
			count = math.clamp(math.floor(count), 1, options.Max or 40)
			pcall(emitter.Emit, emitter, count)
		end
		table.insert(made, emitter)
	end
	return made
end

-- A world-space burst at `position` that cleans itself up.
local function burstAt(position, templates, options, lifetime)
	if #templates == 0 then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "HeroWeaponBurst"
	attachment.Position = position -- Terrain attachments live in world space
	attachment.Parent = Workspace.Terrain
	attachEmitters(attachment, templates, options)
	later(lifetime or 2, attachment)
end

local T = {
	slap = function()
		return emittersAt("Assets/Particles/SlapVFX")
	end,
	stars = function()
		return emittersAt("Assets/VFX/LightningStrike/starfx", { "star" })
	end,
	lightning = function()
		return emittersAt("Assets/VFX/LightningStrike/fx/Attachment", { "lightning", "shard2" })
	end,
	smokeBomb = function()
		return emittersAt("Assets/VFX/SmokeBomb/Part")
	end,
	puff = function()
		return emittersAt("Assets/Particles/Pets/Smoke")
	end,
	explosion = function()
		return emittersAt("Assets/Particles/Damage")
	end,
	lines = function()
		return emittersAt("Assets/VFX/Dash", { "Lines1", "Lines2" })
	end,
	dust = function()
		return emittersAt("Assets/VFX/Dash/Dust")
	end,
	twirl = function()
		return emittersAt("Assets/VFX/Dash/eff/Attachment2", { "Twirl", "Rings", "SmokeBLD" })
	end,
	ground = function()
		return emittersAt("Assets/Particles/HitGroundAttach")
	end,
	flash = function() -- a white-hot glow + star spark (LightningStrike), tinted per weapon
		return emittersAt("Assets/VFX/LightningStrike/fx/Attachment", { "big", "Spark" })
	end,
	ring = function() -- an expanding ring, laid flat for ground shockwaves
		return emittersAt("Assets/VFX/LightningStrike/fx/Attachment", { "Ring" })
	end,
	wind = function() -- swirling wind crescents
		return emittersAt("Assets/VFX/LightningStrike/fx/Attachment", { "wind1", "wind2" })
	end,
	strike = function() -- the lightning strike's bolts and shards
		return emittersAt("Assets/VFX/LightningStrike/fx", { "lightning1", "shard", "ring" })
	end,
	sparks = function()
		return emittersAt("Assets/Particles/Damage", { "Hitspark" })
	end,
	-- round 9 (vendor/weapon_vfx.rbxm, published by post_hero_weapons): Speedsters' Eggman missile blast (its "Mid"
	-- set), Steal a Brainrot's Ban Hammer toon lightning strike and electric impact
	eggmanBlast = function()
		return emittersAt("Assets/VFX/HeroWeapons/EggmanBlast",
			{ "darkfire", "smoke", "smoke_2", "sw", "rock", "Sparks", "circle3", "groundwind", "1" })
	end,
	toonLightning = function()
		return emittersAt("Assets/VFX/HeroWeapons/ToonLightning")
	end,
	electricImpact = function()
		return emittersAt("Assets/VFX/HeroWeapons/ElectricImpact")
	end,
	-- the base place's thunderstorm lightning hit and the Shocked mutation's crackle
	lightningHit = function()
		return emittersAt("Assets/Weather/ThunderstormWeather/LightningHit")
	end,
	shocked = function()
		return emittersAt("Mutation_FX/Shocked")
	end,
}

-- The owner's effect models (their FBX imported in Studio, published by post_hero_weapons as
-- ReplicatedStorage.HeroWeaponVfx.<Name>): cloned locally when present; without them the procedural effect plays.
local function vfxTemplate(name)
	local folder = ReplicatedStorage:FindFirstChild("HeroWeaponVfx")
	local template = folder and folder:FindFirstChild(name)
	return if template and template:IsA("Model") then template else nil
end

local function vfxModel(name)
	local template = vfxTemplate(name)
	if not template then
		return nil
	end
	local model = template:Clone()
	model.Parent = fxFolder()
	return model
end

local function fadeModel(model, seconds, after)
	task.delay(after or 0, function()
		if model.Parent == nil then
			return
		end
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Transparency = 1 }):Play()
			end
		end
		later(seconds + 0.05, model)
	end)
end

local animate -- (fn(now) -> keep) forward declaration, defined with the projectiles

-- A mesh effect that pops at `cframe` (scale `from` -> `to` over `seconds`), holds, then fades. nil without the model.
local function popModel(name, cframe, from, to, seconds, hold)
	local model = vfxModel(name)
	if not model then
		return nil
	end
	local base = model:GetScale()
	model:PivotTo(cframe)
	model:ScaleTo(base * from)
	local started = os.clock()
	animate(function(now)
		if model.Parent == nil then
			return false
		end
		local alpha = math.min((now - started) / seconds, 1)
		model:ScaleTo(base * (from + (to - from) * (1 - (1 - alpha) ^ 3)))
		model:PivotTo(cframe)
		return alpha < 1
	end)
	fadeModel(model, 0.35, seconds + (hold or 0))
	return model
end

local Audio = nil
local audioLoaded = false
local function playPop(position, pitch, volume)
	if not audioLoaded then
		audioLoaded = true
		Audio = requireOptional(ReplicatedStorage:FindFirstChild("Library"), "Audio")
	end
	if Audio and type(Audio.Play) == "function" and typeof(position) == "Vector3" then
		pcall(Audio.Play, HeroWeaponController.HIT_SOUND, position, pitch or { 0.8, 0.95 }, volume or 1.2, 90)
	end
end

-- Pop-up comic text over a point ("BOOM!").
local function comicText(position, text, color, size, seconds)
	local anchor = Instance.new("Attachment")
	anchor.Name = "HeroWeaponText"
	anchor.Position = position -- Terrain space = world space
	anchor.Parent = Workspace.Terrain
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(size, size * 0.5)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 140
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.fromRGB(30, 16, 8)
	label.TextStrokeTransparency = 0
	label.Rotation = math.random(-12, 12)
	label.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = label
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(gui, TweenInfo.new(seconds or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0) }):Play()
	task.delay((seconds or 0.8) * 0.6, function()
		TweenService:Create(label, TweenInfo.new((seconds or 0.8) * 0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	later(seconds or 0.8, anchor)
end

-- Owner 2026-09-27: "make sure the VFX look good and pretty - no VFX made of meshes anywhere, apart from the ones I
-- sent" (their 7 effect models). Every effect below is particles (templates already in the place), Beams and Trails.

-- A tinted flash of light about `size` studs across.
local function flashAt(position, color, size, count)
	burstAt(position, T.flash(), { Scale = size / 65, Color = ColorSequence.new(color), Emit = count or 1, Max = 3 }, 0.6)
end

-- A ring spreading flat on the ground to `radius` studs.
local function ringAt(position, color, radius)
	burstAt(position, T.ring(), {
		Scale = radius * 2 / 52,
		Color = ColorSequence.new(color),
		Emit = 1,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		Direction = Enum.NormalId.Top,
		Speed = NumberRange.new(0.01),
	}, 0.8)
end

-- A white streak following a flying weapon (a Trail between two attachments on its centre).
local function trailOn(part, color, width)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = part
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.18
	trail.MinLength = 0.05
	trail.LightEmission = 0.8
	trail.FaceCamera = true
	trail.Parent = part
	return trail
end

----------------------------------------------------------------------------------------------------
-- joint writing on top of the Animator (clips and the victims' wobbles share it)
----------------------------------------------------------------------------------------------------

local jointCache = setmetatable({}, { __mode = "k" }) -- [character] = { [motorName] = entry | false }

local function jointEntry(character, name)
	local joints = jointCache[character]
	if not joints then
		joints = {}
		jointCache[character] = joints
	end
	local entry = joints[name]
	if entry == nil then
		entry = false
		for _, motor in ipairs(character:GetDescendants()) do
			if motor.Name == name and motor:IsA("Motor6D") and motor:FindFirstAncestorOfClass("Tool") == nil
				and motor:FindFirstAncestorOfClass("Accessory") == nil then
				entry = { motor = motor, base = nil, written = nil }
				break
			end
		end
		joints[name] = entry
	end
	if entry and entry.motor.Parent == nil then
		joints[name] = nil
		return nil
	end
	return entry or nil
end

-- The Animator's pose under this joint this frame (never our own last output).
local function basePose(entry)
	local current = entry.motor.Transform
	local base = if entry.written ~= nil and current == entry.written then (entry.base or CFrame.identity) else current
	entry.base = base
	return base
end

local function writeJoint(entry, cframe)
	if entry.motor.Enabled then
		entry.motor.Transform = cframe
		entry.written = cframe
	end
end

-- Hands a joint back to the Animator exactly as it left it.
local function releaseJoint(entry)
	if entry and entry.motor.Parent and entry.written ~= nil and entry.motor.Transform == entry.written then
		entry.motor.Transform = entry.base or CFrame.identity
	end
	if entry then
		entry.written = nil
	end
end

----------------------------------------------------------------------------------------------------
-- attack clips
----------------------------------------------------------------------------------------------------

local preparedClips = {}
local function clipFor(weaponId)
	local cached = preparedClips[weaponId]
	if cached ~= nil then
		return cached or nil
	end
	local data = HeroWeapons and HeroWeapons.Clip(weaponId)
	local clip = false
	if data and ClipMath then
		local ok, result = pcall(ClipMath.PrepareClip, weaponId, data)
		if ok then
			clip = result
		else
			warnf("clip " .. weaponId .. " invalid: " .. tostring(result))
		end
	end
	preparedClips[weaponId] = clip
	return clip or nil
end

local playing = {} -- [character] = { weapon, clip, data, startedAt, impact, length, samples, legs, written, tool, ... }
local onImpact -- (character, play) forward declaration

-- A light camera shake on this client (owner 2026-09-27: "Mjolnir: a light shake on the client that uses it"):
-- `magnitude` degrees at the start, fading out over `seconds`. Applied after the camera scripts every frame.
local shake = { magnitude = 0, startedAt = 0, seconds = 0.3, applied = nil }
local function shakeLocal(magnitude, seconds)
	local now = os.clock()
	local left = if now - shake.startedAt < shake.seconds then shake.magnitude * (1 - (now - shake.startedAt) / shake.seconds) else 0
	shake.magnitude = math.max(left, magnitude)
	shake.startedAt = now
	shake.seconds = seconds or 0.3
end

-- The Power Pole grows out of the hand (owner 2026-09-27: "make it big, stretch it out of the hand"): its Handle and
-- every part welded to it lengthen along the pole, the end behind the hand stays put (the engine's RightGrip slides the
-- Handle outward), and it thickens a little as it grows. Local on every client, undone by stopClip.
local function poleCache(play)
	if play.pole ~= nil then
		return play.pole or nil
	end
	play.pole = false
	local tool = play.tool
	local handle = tool and tool:FindFirstChild("Handle")
	local hand = rightHandOf(play.character)
	local grip = hand and hand:FindFirstChild("RightGrip")
	if not (handle and handle:IsA("BasePart") and grip and grip:IsA("JointInstance")) then
		return nil
	end
	local size = handle.Size
	local axis = if size.Y >= size.X and size.Y >= size.Z then Vector3.yAxis
		elseif size.X >= size.Z then Vector3.xAxis else Vector3.zAxis
	-- outward = the end in the hand's -Z (the kit's grip lays the pole along it; the clip turns it along the arm)
	local gripFromHand = tool:GetAttribute("GripFromHand")
	local outward = 1
	if typeof(gripFromHand) == "CFrame" and gripFromHand:VectorToWorldSpace(axis):Dot(Vector3.new(0, 0, -1)) < 0 then
		outward = -1
	end
	local cache = { handle = handle, size = size, axis = axis, sign = outward, grip = grip, c1 = grip.C1, parts = {},
		length = math.max(size.X, size.Y, size.Z) }
	for _, part in ipairs(tool:GetChildren()) do
		local weld = part:IsA("BasePart") and part ~= handle and part:FindFirstChild("HeroWeaponWeld")
		if weld and weld:IsA("Weld") and weld.Part0 == handle then
			local localAxis = weld.C0.Rotation:Inverse() * axis
			local ax = math.abs(localAxis.X)
			local ay = math.abs(localAxis.Y)
			local az = math.abs(localAxis.Z)
			table.insert(cache.parts, { part = part, size = part.Size, weld = weld, c0 = weld.C0,
				along = if ay >= ax and ay >= az then "Y" elseif ax >= az then "X" else "Z" })
		end
	end
	play.pole = cache
	return cache
end

local function scaledSize(size, along, k, thick)
	return Vector3.new(if along == "X" then size.X * k else size.X * thick,
		if along == "Y" then size.Y * k else size.Y * thick,
		if along == "Z" then size.Z * k else size.Z * thick)
end

local function extendPole(play, k)
	local cache = poleCache(play)
	if not cache or cache.handle.Parent == nil then
		return
	end
	local thick = 1 + 0.55 * math.clamp((k - 1) / 2.6, 0, 1)
	local handleAlong = if cache.axis == Vector3.xAxis then "X" elseif cache.axis == Vector3.yAxis then "Y" else "Z"
	cache.handle.Size = scaledSize(cache.size, handleAlong, k, thick)
	if cache.grip.Parent then
		-- slide the Handle outward by half the growth: its inner end stays where the hand holds it
		cache.grip.C1 = CFrame.new(-cache.axis * cache.sign * (cache.length * (k - 1) / 2)) * cache.c1
	end
	for _, entry in ipairs(cache.parts) do
		if entry.part.Parent then
			entry.part.Size = scaledSize(entry.size, entry.along, k, thick)
			local p = entry.c0.Position
			entry.weld.C0 = CFrame.new(p + cache.axis * (p:Dot(cache.axis) * (k - 1))) * entry.c0.Rotation
		end
	end
	-- a gold ribbon sweeping behind the tip while the pole is long
	if k > 1.4 and not cache.trail then
		local a0 = Instance.new("Attachment")
		a0.Name = "HeroPoleTrail0"
		a0.Parent = cache.handle
		local a1 = Instance.new("Attachment")
		a1.Name = "HeroPoleTrail1"
		a1.Parent = cache.handle
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 236, 170), Color3.fromRGB(255, 170, 50))
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
		trail.LightEmission = 1
		trail.Lifetime = 0.16
		trail.MinLength = 0.05
		trail.FaceCamera = false
		trail.Parent = cache.handle
		cache.trail = { trail, a0, a1 }
	end
	if cache.trail then
		local half = cache.length * k / 2
		cache.trail[2].Position = cache.axis * cache.sign * (half - 0.2)
		cache.trail[3].Position = cache.axis * cache.sign * (half * 0.35)
		cache.trail[1].Enabled = k > 1.4
	end
end

local function restorePole(play)
	local cache = play.pole
	if not cache then
		return
	end
	play.pole = nil
	if cache.handle.Parent then
		cache.handle.Size = cache.size
	end
	if cache.grip.Parent then
		cache.grip.C1 = cache.c1
	end
	for _, entry in ipairs(cache.parts) do
		if entry.part.Parent then
			entry.part.Size = entry.size
			entry.weld.C0 = entry.c0
		end
	end
	for _, instance in ipairs(cache.trail or {}) do
		instance:Destroy()
	end
end

local function keyed(keys, elapsed)
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if elapsed >= a[1] and elapsed <= b[1] then
			local f = (elapsed - a[1]) / math.max(b[1] - a[1], 1e-4)
			f = f * f * (3 - 2 * f)
			return a[2] + (b[2] - a[2]) * f
		end
	end
	return if #keys > 0 then keys[#keys][2] else 1
end

local function stopClip(character)
	local play = playing[character]
	if not play then
		return
	end
	playing[character] = nil
	for name in pairs(play.written) do
		releaseJoint(jointEntry(character, name))
	end
	if play.tool and Kit and (play.stretch or play.weapon.Id == "GomuFist") then
		pcall(Kit.SetStretch, play.tool, 1)
	end
	restorePole(play)
	for _, emitter in ipairs(play.charge or {}) do
		emitter.Enabled = false
	end
end

local function playClip(character, weapon, options)
	local humanoid = characterParts(character)
	if not humanoid or character:GetAttribute("Ragdolled") == true then
		return
	end
	local clip = clipFor(weapon.Id)
	if not clip then
		return
	end
	stopClip(character)
	local impact, length = HeroWeapons.Timing(weapon.Id)
	local data = HeroWeapons.Clip(weapon.Id) or {}
	local tool = heldTool(character)
	local play = {
		weapon = weapon,
		clip = clip,
		character = character,
		startedAt = os.clock(),
		impact = impact,
		length = length,
		samples = {},
		fullBody = data.FullBody == true,
		extend = if type(data.Extend) == "table" then data.Extend else nil,
		stretch = if type(data.Stretch) == "table" then data.Stretch else nil, -- Luffy's rubber arm length keys
		legs = if data.FullBody == true or humanoid.MoveDirection.Magnitude <= 0.1 then 1 else 0,
		written = {},
		tool = tool,
		impacted = false,
		humanoid = humanoid,
		predicted = type(options) == "table" and options.predicted == true, -- this client's own click
		seq = type(options) == "table" and options.seq or nil,
	}
	playing[character] = play
	if weapon.Id == "Mjolnir" and tool then
		-- the hammer crackles with electricity through the leap (particles on its head)
		local head, biggest = nil, 0
		for _, part in ipairs(tool:GetChildren()) do
			if part:IsA("BasePart") and part.Size.Magnitude > biggest then
				head, biggest = part, part.Size.Magnitude
			end
		end
		if head then
			local attachment = Instance.new("Attachment")
			attachment.Name = "HeroMjolnirCharge"
			attachment.Parent = head
			play.charge = attachEmitters(attachment, T.shocked(), { Enabled = true, Scale = 0.7, Locked = true })
			for _, emitter in ipairs(attachEmitters(attachment, T.toonLightning(), { Enabled = true, Rate = 5, Scale = 0.18,
				Locked = true, Color = ColorSequence.new(weapon.Color) })) do
				table.insert(play.charge, emitter)
			end
			later(length + 1, attachment)
		end
	end
end

local function stepClip(character, play, dt)
	local elapsed = os.clock() - play.startedAt
	if elapsed >= play.length or not character.Parent or character:GetAttribute("Ragdolled") == true
		or play.humanoid.Health <= 0 then
		stopClip(character)
		return
	end
	local config = HeroWeaponController
	local weight = math.min(1, elapsed / config.BLEND_IN) * math.min(1, (play.length - elapsed) / config.BLEND_OUT)
	weight = math.clamp(weight, 0, 1)
	local still = play.fullBody
		or (play.humanoid.MoveDirection.Magnitude < 0.1 and play.humanoid.FloorMaterial ~= Enum.Material.Air)
	play.legs += ((if still then 1 else 0) - play.legs) * math.min(1, dt * 12)
	ClipMath.SampleClip(play.clip, elapsed, play.samples)
	for joint, sample in pairs(play.samples) do
		local entry = jointEntry(character, joint)
		if entry then
			local w = if config.LEG_JOINTS[joint] then weight * play.legs else weight
			local base = basePose(entry)
			local target = ClipMath.ToCFrame(sample, 1)
			writeJoint(entry, if w >= 0.999 then target else base:Lerp(target, w))
			play.written[joint] = true
		end
	end
	if play.tool and Kit and play.stretch then
		pcall(Kit.SetStretch, play.tool, keyed(play.stretch, elapsed)) -- the long Gum-Gum Pistol
	elseif play.tool and Kit and play.weapon.Id == "GomuFist" then
		pcall(Kit.SetGomuTime, play.tool, elapsed)
	end
	if play.extend then
		extendPole(play, keyed(play.extend, elapsed))
	end
	if play.charge and elapsed > play.impact + 0.15 then
		for _, emitter in ipairs(play.charge) do
			emitter.Enabled = false
		end
		play.charge = nil
	end
	if not play.impacted and elapsed >= play.impact then
		play.impacted = true
		local ok, err = pcall(onImpact, character, play)
		if not ok then
			warnf("impact effect failed: " .. tostring(err))
		end
	end
end

----------------------------------------------------------------------------------------------------
-- the attack's own effect at the Impact keyframe (every client, for every attacker)
----------------------------------------------------------------------------------------------------

local function sectionPart(tool, section)
	for _, part in ipairs(tool and tool:GetChildren() or {}) do
		if part:IsA("BasePart") and part:GetAttribute("HeroSection") == section then
			return part
		end
	end
	return nil
end

-- The ground under a point (the first collidable surface below it), else the point itself.
local function groundBelow(position, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore or {}
	params.RespectCanCollide = true
	local result = Workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), params)
	return if result then result.Position else position
end

local launchLocal -- (character, play) forward declaration: the thrower's own flight, started at once

-- The server's gates at the Impact keyframe (GearService.resolveWeaponContact), checked again before predicting.
local function stillAbleToThrow(character, play)
	local humanoid = characterParts(character)
	if not humanoid or humanoid.Health <= 0 or not play.tool or play.tool.Parent ~= character then
		return false
	end
	if character:GetAttribute("Ragdolled") == true or character:GetAttribute("IsTrapped") == true
		or character:GetAttribute(HeroWeaponController.DEBUFF_ATTRIBUTE) ~= nil
		or LocalPlayer:GetAttribute(HeroWeaponController.CARRY_ATTRIBUTE) == true then
		return false
	end
	local okState, current = pcall(humanoid.GetState, humanoid)
	return not (humanoid.PlatformStand or (okState and HeroWeaponController.DOWN_STATES[current]))
end

onImpact = function(character, play)
	local _, root = characterParts(character)
	if not root then
		return
	end
	local weapon = play.weapon
	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	forward = if forward.Magnitude > 0.01 then forward.Unit else Vector3.new(0, 0, -1)
	local tool = play.tool
	local handle = tool and tool:FindFirstChild("Handle")
	local up = Vector3.yAxis
	if character == LocalPlayer.Character then
		shakeLocal((tonumber(weapon.Shake) or 0.5) * 1.8, 0.32)
	end
	if weapon.Aimed then
		-- the weapon leaves the hand: the thrower's client flies it now (its own click, if nothing stopped it during the
		-- wind-up - the server checks the same), the others when the server's Launch arrives
		if character == LocalPlayer.Character and play.predicted and stillAbleToThrow(character, play) then
			launchLocal(character, play)
		end
		local hand = rightHandOf(character)
		if hand then
			burstAt(hand.Position, T.puff(), { Max = 4, Scale = 0.6, Color = ColorSequence.new(Color3.fromRGB(235, 240, 250)) }, 1)
		end
		return
	end
	if weapon.Id == "BakugoGauntlet" then
		-- BOOM: the owner's comic explosion bursts out of the gauntlet, fire and sparks roll forward
		local nozzle = if handle then handle.Position + forward * 1 else root.Position + forward * 2.5
		flashAt(nozzle + forward * 1.5, weapon.Color, 6, 2)
		for i = 1, 3 do
			task.delay(i * 0.05, function()
				burstAt(nozzle + forward * (i * 2.6), T.explosion(), { Scale = 0.45 + i * 0.12, Max = 12 }, 2)
			end)
		end
		burstAt(nozzle + forward * 2, T.sparks(), { Max = 4, Color = ColorSequence.new(weapon.Accent) }, 1)
		popModel("Comic_Explosion", CFrame.lookAt(nozzle + forward * 3.5, nozzle + forward * 5), 0.4, 1.7, 0.22, 0.12)
		comicText(nozzle + forward * 3 + Vector3.new(0, 2.2, 0), "BOOM!", Color3.fromRGB(255, 150, 30), 5, 0.75)
		playPop(nozzle, { 0.55, 0.65 }, 1.4)
	elseif weapon.Id == "Mjolnir" then
		-- the slam (particles only, owner 2026-09-27): a toon bolt crashes onto the hammer, the electric impact and the
		-- storm's lightning hit burst from the ground, shock rings roll out, rocks and dust jump, sparks race outward
		local radius = tonumber(weapon.Radius) or 12
		local point = groundBelow(root.Position + forward * (tonumber(weapon.Reach) or 4), { character, fxFolder() })
		burstAt(point + up * 3.2, T.toonLightning(), { Scale = 0.75, Max = 6, Color = ColorSequence.new(weapon.Color) }, 1.2)
		task.delay(0.06, function()
			burstAt(point + up * 1.6 + forward * 1.4, T.toonLightning(), { Scale = 0.5, Max = 4 }, 1)
		end)
		burstAt(point + up * 0.6, T.electricImpact(), { Scale = 0.55, Max = 10 }, 1.2)
		burstAt(point + up * 1.4, T.lightningHit(), { Scale = 0.45, SpeedScale = 0.45, Max = 16 }, 1.5)
		ringAt(point + up * 0.2, weapon.Color, radius)
		ringAt(point + up * 0.3, weapon.Accent, radius * 0.55)
		flashAt(point + up, weapon.Accent, 7, 2)
		burstAt(point + up * 0.4, T.ground(), { Max = 40 }, 2)
		burstAt(point + up * 0.3, T.dust(), { Emit = 14, Max = 14 }, 2)
		for i = 0, 5 do
			local angle = i / 6 * math.pi * 2 + math.random() * 0.4
			local out = Vector3.new(math.cos(angle), 0, math.sin(angle))
			task.delay(0.03 * i, function()
				burstAt(point + out * radius * 0.55 + up * 0.4, T.sparks(), { Max = 2, Scale = 0.6,
					Color = ColorSequence.new(weapon.Color) }, 1)
			end)
		end
		playPop(point, { 0.5, 0.6 }, 1.5)
	elseif weapon.Id == "PowerPole" then
		-- the sweep: a gold ring and wind whirl out at the pole's length, dust spins off the feet
		local radius = tonumber(weapon.Radius) or 12
		local feet = groundBelow(root.Position, { character, fxFolder() })
		ringAt(feet + up * 0.25, weapon.Accent, radius)
		burstAt(root.Position, T.wind(), {
			Scale = 0.09, Emit = 3, Max = 3, Color = ColorSequence.new(Color3.fromRGB(255, 244, 214)),
			Direction = Enum.NormalId.Top, Speed = NumberRange.new(0.01), Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		}, 1)
		burstAt(feet + up * 0.3, T.twirl(), { Max = 8 }, 1.2)
		burstAt(feet + up * 0.3, T.dust(), { Emit = 16, Max = 16 }, 1.5)
		playPop(root.Position, { 0.8, 0.9 }, 1.2)
	elseif weapon.Id == "GomuFist" then
		-- the fist at the end of the stretched arm: a slap burst and speed lines where it lands
		local fist = sectionPart(tool, "Fist")
		local at = if fist then fist.Position else root.Position + forward * 14
		flashAt(at, Color3.new(1, 1, 1), 4.5, 1)
		burstAt(at, T.slap(), { Max = 12 }, 1.2)
		burstAt(at, T.lines(), { Scale = 0.5, Max = 7 }, 1)
	end
end

----------------------------------------------------------------------------------------------------
-- aimed throws: the flights (Launch / ProjectileEnd)
----------------------------------------------------------------------------------------------------

local animations = {} -- { fn(now) -> keep }
animate = function(fn)
	table.insert(animations, fn)
end

-- An anchored copy of a tool's visible parts (optionally only some sections) for a thrown weapon. Returns the model
-- and each copy's layout: its CFrame relative to the weapon's centre, in the tool's grip space (the Handle's frame).
local function cloneWeaponParts(tool, sections)
	local handle = tool and tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "HeroWeaponThrown"
	local copies = {}
	for _, part in ipairs(tool:GetChildren()) do
		if part:IsA("BasePart") and (sections == nil or sections[part:GetAttribute("HeroSection") or "Handle"]) then
			local copy = part:Clone()
			for _, child in ipairs(copy:GetChildren()) do
				child:Destroy()
			end
			copy.Anchored = true
			copy.CanCollide = false
			copy.CanQuery = false
			copy.CanTouch = false
			copy.LocalTransparencyModifier = 0
			copy.CFrame = part.CFrame
			copy.Parent = model
			copies[copy] = handle.CFrame:ToObjectSpace(part.CFrame)
		end
	end
	if next(copies) == nil then
		model:Destroy()
		return nil
	end
	local centre = model:GetBoundingBox()
	local centreLocal = handle.CFrame:PointToObjectSpace(centre.Position)
	local layout = {}
	for copy, relative in pairs(copies) do
		layout[copy] = CFrame.new(-centreLocal) * relative
	end
	model.Parent = fxFolder()
	return model, layout, centre.Position
end

-- Workspace raycast that only stops at collidable world geometry (the server's rule for a throw's end).
local function wallRaycast()
	local exclude = { fxFolder() }
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	local dummies = Workspace:FindFirstChild("HeroWeaponDummies")
	if dummies then
		table.insert(exclude, dummies)
	end
	local traps = Workspace:FindFirstChild("PlacedTraps")
	if traps then
		table.insert(exclude, traps)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	params.RespectCanCollide = true
	params.IgnoreWater = true
	return function(origin, vector)
		local result = Workspace:Raycast(origin, vector, params)
		return if result then result.Position else nil
	end
end

local flights = {} -- every flight drawn here (ended ones linger a few seconds so a late ProjectileEnd finds them)
local FLAT = CFrame.Angles(math.rad(90), 0, 0) -- the shield / batarang lie flat (both are authored facing their Z)

local function explodeAt(weapon, position)
	-- Speedsters' Eggman missile blast, scaled to the batarang's blast, and Batman's smoke pellet cloud
	local blast = tonumber(weapon.BlastRadius) or 8
	local scale = blast / 22
	burstAt(position, T.eggmanBlast(), { Scale = scale, SpeedScale = scale, Max = 14 }, 3.2)
	burstAt(position, T.smokeBomb(), { Emit = 1, Scale = 0.5 }, 3.5)
	flashAt(position, Color3.fromRGB(255, 214, 120), 6, 1)
	ringAt(groundBelow(position, { fxFolder() }) + Vector3.new(0, 0.2, 0), weapon.Accent, blast)
	playPop(position, { 0.55, 0.65 }, 1.4)
	local _, root = characterParts(LocalPlayer.Character)
	if root then
		local distance = (root.Position - position).Magnitude
		if distance < 30 then
			shakeLocal(1.4 * (1 - distance / 30), 0.3)
		end
	end
end

local function finishFlight(flight, position, reason)
	if flight.ended then
		return
	end
	flight.ended = true
	flight.endedAt = os.clock()
	if flight.model then
		flight.model:Destroy()
	end
	local weapon = flight.weapon
	if weapon.Kind == "Grenade" then
		if reason ~= "Gone" then
			explodeAt(weapon, position or flight.path.End)
		end
		task.delay(0.35, function() -- a new batarang in the hand
			setSectionHidden(flight.tool, nil, false)
			local hand = rightHandOf(flight.character)
			if hand then
				burstAt(hand.Position, T.puff(), { Max = 3, Scale = 0.5 }, 1)
			end
		end)
	elseif weapon.Kind == "Boomerang" then
		setSectionHidden(flight.tool, nil, false)
		local hand = rightHandOf(flight.character)
		if hand and reason ~= "Gone" then
			flashAt(hand.Position, Color3.fromRGB(225, 235, 255), 2.6, 1) -- the catch
			burstAt(hand.Position, T.sparks(), { Max = 2, Scale = 0.5 }, 0.8)
		end
	elseif weapon.Kind == "Shot" then
		local at = position or flight.position or flight.path.End
		if flight.tip then
			flight.tip.Position = at
		end
		if flight.blob then
			flight.blob:Destroy()
		end
		burstAt(at, T.puff(), { Max = 8, Color = ColorSequence.new(weapon.Color) }, 1.2)
		if flight.beam then
			TweenService:Create(flight.beam, TweenInfo.new(0.3), { Width0 = 0, Width1 = 0 }):Play()
		end
		later(0.32, flight.origin)
		later(0.32, flight.tip)
	end
end

-- Draws one flight along `path` (HeroWeapons.PathPoint, the server's own path). Every client also stops it at walls
-- the way the server does (the shield turns back there); the thrower's own grenade / shot waits a moment at its end
-- for the server's ProjectileEnd, so the blast / splat shows where the server resolved it (an early hit on a rival).
local function startFlight(character, weapon, path, isLocal)
	local tool = heldTool(character)
	local hand = rightHandOf(character)
	local startAt = if hand then hand.Position else path.Origin
	local flight = { weapon = weapon, character = character, path = path, startedAt = os.clock(), tool = tool,
		isLocal = isLocal, last = path.Origin }
	if weapon.Kind == "Shot" then
		-- the web line: a Beam from the wrist to its tip flying out, the owner's web blob riding the tip
		local origin = Instance.new("Attachment")
		origin.Name = "HeroWebOrigin"
		origin.Parent = hand or Workspace.Terrain
		if not hand then
			origin.Position = startAt
		end
		local tip = Instance.new("Attachment")
		tip.Name = "HeroWebTip"
		tip.Position = startAt
		tip.Parent = Workspace.Terrain
		local beam = Instance.new("Beam")
		beam.Attachment0 = origin
		beam.Attachment1 = tip
		beam.Color = ColorSequence.new(weapon.Color)
		beam.Transparency = NumberSequence.new(0.05)
		beam.Width0 = 0.16
		beam.Width1 = 0.1
		beam.FaceCamera = true
		beam.LightEmission = 0.35
		beam.LightInfluence = 0.4
		beam.Segments = 2
		beam.Parent = origin
		flight.origin, flight.tip, flight.beam = origin, tip, beam
		flight.blob = vfxModel("Web_Blob")
		burstAt(startAt, T.puff(), { Max = 5, Color = ColorSequence.new(weapon.Color) }, 1)
	else
		local model, layout = cloneWeaponParts(tool, nil)
		if model then
			flight.model, flight.layout = model, layout
			local anchorPart = next(layout)
			if anchorPart then
				trailOn(anchorPart, if weapon.Kind == "Boomerang" then Color3.fromRGB(235, 240, 255)
					else Color3.fromRGB(140, 140, 160), 1.4)
			end
		end
		setSectionHidden(tool, nil, true) -- the held one is the one flying
	end
	table.insert(flights, flight)
	local raycast = wallRaycast()

	-- the thrower's own grenade / shot reached its end: hold it there until the server's ProjectileEnd (or a moment)
	local function holdForServer(at)
		flight.holding = true
		flight.position = at
		if flight.model then
			flight.model:Destroy()
			flight.model = nil
		end
		task.delay(0.45, function()
			if not flight.ended then
				finishFlight(flight, at, "End")
			end
		end)
	end

	local function step(now)
		if flight.ended or flight.holding then
			return false
		end
		if not character.Parent then
			finishFlight(flight, nil, "Gone")
			return false
		end
		local t = now - flight.startedAt
		local home = nil
		if path.Returns then
			local _, root = characterParts(character)
			home = if root then HeroWeapons.ReturnHome(root.CFrame) else path.Origin
		end
		local position, finished = HeroWeapons.PathPoint(path, t, home)
		-- walls: the same per-step test as the server (the grenade / shot end there, the shield turns back)
		local wall = raycast(flight.last, position - flight.last)
		if wall and not (path.Returns and t >= path.OutTime) then
			local direction = position - flight.last
			direction = if direction.Magnitude > 1e-3 then direction.Unit else Vector3.new(0, 0, -1)
			local stop = wall - direction * 0.5
			if path.Returns then
				path.End = stop
				path.BackTime = HeroWeapons.Travel(weapon, (stop - path.Origin).Magnitude, weapon.ReturnSpeed)
				path.OutTime = t
				flight.turned = true
				position = stop
			elseif flight.isLocal then
				holdForServer(stop)
				return false
			else
				finishFlight(flight, stop, "End")
				return false
			end
		end
		flight.last = position
		local shown = position
		local blend = math.clamp(t / 0.08, 0, 1) -- off the hand onto the path
		if blend < 1 then
			shown = startAt:Lerp(position, blend)
		end
		flight.position = shown
		if flight.model then
			local spin = if weapon.Kind == "Boomerang" then 26 else 32
			local frame = CFrame.new(shown) * CFrame.fromAxisAngle(Vector3.yAxis, t * spin) * FLAT
			for part, offset in pairs(flight.layout) do
				part.CFrame = frame * offset
			end
		end
		if flight.tip then
			flight.tip.Position = shown
			if flight.blob then
				local heading = path.End - path.Origin
				if heading.Magnitude > 0.01 then
					flight.blob:PivotTo(CFrame.lookAt(shown, shown + heading.Unit))
				end
			end
		end
		if finished then
			if path.Returns then
				finishFlight(flight, nil, "End")
			elseif flight.isLocal then
				holdForServer(path.End)
			else
				finishFlight(flight, path.End, "End")
			end
			return false
		end
		return true
	end
	animate(function(now)
		local ok, keep = pcall(step, now)
		if not ok then
			warnf("flight failed: " .. tostring(keep))
			pcall(finishFlight, flight, nil, "Gone") -- never leave the copy flying or the held weapon hidden
			return false
		end
		return keep
	end)
	return flight
end

local lastAim = nil -- { point, at, seq }: this client's last aim point (sent to the server with the click)
local throwSeq = 0 -- this client's throw number, echoed back in the server's Launch

launchLocal = function(character, play)
	local _, root = characterParts(character)
	if not root then
		return
	end
	local weapon = play.weapon
	local aim = if lastAim and os.clock() - lastAim.at < 1.5 then lastAim.point
		else root.Position + HeroWeapons.Flat(root.CFrame.LookVector, Vector3.new(0, 0, -1)) * 30
	local origin = HeroWeapons.ThrowOrigin(root.CFrame, aim)
	local finish = HeroWeapons.AimEnd(weapon, origin, aim, wallRaycast())
	local distance = (finish - origin).Magnitude
	local returns = weapon.Kind == "Boomerang"
	local flight = startFlight(character, weapon, {
		Origin = origin,
		End = finish,
		Side = if returns then 1 else -1,
		Curve = if weapon.Kind == "Shot" then 0 else (tonumber(weapon.Curve) or 0),
		OutTime = HeroWeapons.Travel(weapon, distance),
		Returns = returns,
		BackTime = if returns then HeroWeapons.Travel(weapon, distance, weapon.ReturnSpeed) else nil,
	}, true)
	flight.awaitingServer = true
	flight.seq = play.seq
end

local function pruneFlights()
	local now = os.clock()
	for index = #flights, 1, -1 do
		local flight = flights[index]
		if flight.awaitingServer and now - flight.startedAt > 1.5 then
			flight.awaitingServer = false -- the server never launched it (it stopped the throw): not adoptable
		end
		if flight.ended and now - (flight.endedAt or now) > 4 then
			table.remove(flights, index)
		end
	end
end

local function onLaunch(payload)
	pruneFlights()
	local weapon = HeroWeapons.Get(payload.Weapon)
	local character = characterOfPlayer(payload.Attacker)
	if not weapon or not characterParts(character) or typeof(payload.Origin) ~= "Vector3"
		or typeof(payload.End) ~= "Vector3" then
		return
	end
	if payload.Attacker == LocalPlayer then
		-- our own throw, already in the air: the one with the echoed throw number, else the newest waiting one
		local adopt = nil
		for _, flight in ipairs(flights) do
			if flight.isLocal and flight.awaitingServer and flight.weapon == weapon then
				if payload.Seq ~= nil and flight.seq == payload.Seq then
					adopt = flight
					break
				elseif payload.Seq == nil and (adopt == nil or flight.startedAt > adopt.startedAt) then
					adopt = flight
				end
			end
		end
		if adopt then
			adopt.awaitingServer = false
			adopt.serverId = payload.Id
			return
		end
	end
	local path = {
		Origin = payload.Origin,
		End = payload.End,
		Side = tonumber(payload.Side) or 1,
		Curve = math.clamp(tonumber(payload.Curve) or 0, 0, 1),
		OutTime = math.clamp(tonumber(payload.OutTime) or 0.3, 0.05, 1),
		Returns = payload.Returns == true,
		BackTime = math.clamp(tonumber(payload.BackTime) or 0.3, 0.05, 1),
	}
	local flight = startFlight(character, weapon, path, false)
	flight.serverId = payload.Id
end

local function flightOf(id)
	for _, flight in ipairs(flights) do
		if flight.serverId ~= nil and flight.serverId == id then
			return flight
		end
	end
	return nil
end

local function onProjectileEnd(payload)
	local position = if typeof(payload.Position) == "Vector3" then payload.Position else nil
	local flight = flightOf(payload.Id)
	if flight then
		if not flight.ended then
			finishFlight(flight, position, payload.Reason)
		elseif position and flight.weapon.Kind == "Grenade" and payload.Reason == "Explode" and flight.position
			and (flight.position - position).Magnitude > 3 then
			explodeAt(flight.weapon, position) -- it blew up somewhere else on the server (an early hit)
		end
		return
	end
	local weapon = HeroWeapons.Get(payload.Weapon)
	if weapon and weapon.Kind == "Grenade" and payload.Reason == "Explode" and position then
		explodeAt(weapon, position) -- a flight this client never drew (it joined mid-throw)
	end
end

-- The server's shield hit a wall and turned back (every client turns at walls itself; this catches the rest).
local function onProjectileTurn(payload)
	local flight = flightOf(payload.Id)
	if not flight or flight.ended or flight.turned or typeof(payload.Position) ~= "Vector3" then
		return
	end
	local path = flight.path
	path.End = payload.Position
	path.OutTime = math.max(os.clock() - flight.startedAt, 0.05)
	path.BackTime = math.clamp(tonumber(payload.BackTime) or 0.3, 0.05, 1)
	flight.turned = true
end

----------------------------------------------------------------------------------------------------
-- hits and the victims' states
----------------------------------------------------------------------------------------------------

local function onHit(payload)
	local weapon = HeroWeapons.Get(payload.Weapon)
	local character = characterOfPlayer(payload.Victim)
	local _, root = characterParts(character)
	local position = if root then root.Position elseif typeof(payload.Position) == "Vector3" then payload.Position else nil
	if not weapon or not position then
		return
	end
	local effect = payload.Effect
	if effect == "Dazed" then
		burstAt(position + Vector3.new(0, 2.5, 0), T.stars(), { Max = 20, Scale = 0.5 }, 1)
		burstAt(position, T.slap(), { Max = 10 }, 1.2)
		flashAt(position, Color3.fromRGB(255, 235, 160), 3.5, 1)
		playPop(position, { 0.85, 1 }, 1.2)
	elseif effect == "Webbed" then
		burstAt(position, T.puff(), { Max = 10, Color = ColorSequence.new(weapon.Color) }, 1.2)
		flashAt(position, weapon.Color, 3, 1)
		local attackerCharacter = characterOfPlayer(payload.Attacker)
		local _, attackerRoot = characterParts(attackerCharacter)
		local facing = if attackerRoot then attackerRoot.Position else position + Vector3.new(0, 0, -5)
		popModel("Web_Net", CFrame.lookAt(position, Vector3.new(facing.X, position.Y, facing.Z)), 0.3, 1.5, 0.14, 0.35)
		playPop(position, { 1.1, 1.25 }, 1.1)
	elseif effect == "Electrocuted" then
		flashAt(position, weapon.Color, 6, 2)
		burstAt(position, T.strike(), { Scale = 0.25, Max = 10, Color = ColorSequence.new(weapon.Color) }, 1)
		playPop(position, { 0.6, 0.7 }, 1.3)
	elseif effect == "CleanKnockback" then
		flashAt(position, Color3.new(1, 1, 1), 5, 1)
		burstAt(position, T.slap(), { Max = 14 }, 1.2)
		comicText(position + Vector3.new(0, 3, 0), "POW!", weapon.Accent, 4, 0.6)
		playPop(position, { 0.7, 0.8 }, 1.4)
	elseif effect == "SmokeStun" then
		burstAt(position, T.slap(), { Max = 8 }, 1.2)
		playPop(position, { 0.9, 1 }, 1.1)
	elseif effect == "ExplosionBlast" then
		flashAt(position, weapon.Color, 8, 2)
		burstAt(position, T.explosion(), { Scale = 0.7, Max = 18 }, 2)
		burstAt(position, T.sparks(), { Max = 4, Color = ColorSequence.new(weapon.Accent) }, 1)
		local cam = Workspace.CurrentCamera
		local toward = if cam then cam.CFrame.Position else position + Vector3.new(0, 0, 10)
		popModel("Comic_Explosion", CFrame.lookAt(position, toward), 0.5, 1.9, 0.25, 0.2)
		playPop(position, { 0.55, 0.65 }, 1.4)
	elseif effect == "SpinTornado" then
		burstAt(position - Vector3.new(0, 2.5, 0), T.twirl(), { Max = 8 }, 1.2)
		ringAt(position - Vector3.new(0, 2.6, 0), weapon.Accent, 4)
		playPop(position, { 0.95, 1.1 }, 1.2)
	end
	if payload.Dropped and character then
		comicText(position + Vector3.new(0, 4, 0), "DROP!", Color3.fromRGB(255, 96, 96), 3.5, 0.7)
	end
end

local states = {} -- [token] = state
local stateByCharacter = setmetatable({}, { __mode = "k" }) -- [character] = state (the wobble in the step)

local function weldTo(part, root, cframe)
	part.Massless = true
	part.CFrame = cframe
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = part
	weld.C0 = root.CFrame:ToObjectSpace(cframe)
	weld.Parent = part
	part.Anchored = false -- welded first, so it never drops for a frame
end

local function starBillboards(state, head, count, glyph, color)
	local marks = {}
	for i = 1, count do
		local attachment = Instance.new("Attachment")
		attachment.Name = "HeroWeaponMark"
		attachment.Parent = head
		table.insert(state.instances, attachment)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(0.9, 0.9)
		gui.LightInfluence = 0
		gui.MaxDistance = 120
		gui.Parent = attachment
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.Text = glyph
		label.TextScaled = true
		label.TextWrapped = true
		label.TextColor3 = color
		label.TextStrokeColor3 = Color3.fromRGB(40, 28, 10)
		label.TextStrokeTransparency = 0
		label.Parent = gui
		marks[i] = attachment
	end
	return marks
end

local function highlightOn(state, character, fill, fillTransparency, outlineTransparency)
	local highlight = Instance.new("Highlight")
	highlight.Name = "HeroWeaponState"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = fill
	highlight.OutlineColor = fill
	highlight.FillTransparency = fillTransparency
	highlight.OutlineTransparency = outlineTransparency or 1
	highlight.Parent = character
	table.insert(state.instances, highlight)
	return highlight
end

local function rootAttachment(state, root, name, offset)
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Position = offset or Vector3.zero
	attachment.Parent = root
	table.insert(state.instances, attachment)
	return attachment
end

-- Local-only screen effect for the smoke stun.
local function smokeScreen(state, duration)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "HeroWeaponSmoke"
	cc.Saturation = -0.85
	cc.Contrast = -0.15
	cc.TintColor = Color3.fromRGB(205, 205, 210)
	cc.Parent = Lighting
	local blur = Instance.new("BlurEffect")
	blur.Name = "HeroWeaponSmoke"
	blur.Size = 12
	blur.Parent = Lighting
	table.insert(state.instances, cc)
	table.insert(state.instances, blur)
	task.delay(math.max(duration - 0.5, 0), function()
		if cc.Parent then
			TweenService:Create(cc, TweenInfo.new(0.5), { Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }):Play()
			TweenService:Create(blur, TweenInfo.new(0.5), { Size = 0 }):Play()
		end
	end)
end

-- Owner 2026-09-27: "the ragdoll bugs: it does not get back up right after it ends, and the weapons can be used
-- while down". A knockback slide / blast hop made the victim's Humanoid trip (engine FallingDown / Ragdoll states),
-- which nothing stood back up. While the local player is in a weapon state those trip states are off, the slide keeps
-- the body upright, and when the state ends a body still lying from a trip gets up where it is.
local TRIP_STATES = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll }
local TRIPPED = { [Enum.HumanoidStateType.FallingDown] = true, [Enum.HumanoidStateType.Ragdoll] = true }

local function holdUpright(state, humanoid)
	state.humanoid = humanoid
	state.tripStates = {}
	for _, stateType in ipairs(TRIP_STATES) do
		local ok, enabled = pcall(humanoid.GetStateEnabled, humanoid, stateType)
		state.tripStates[stateType] = if ok then enabled else true
		pcall(humanoid.SetStateEnabled, humanoid, stateType, false)
	end
end

local function uprightRoot(root)
	local _, yaw = root.CFrame:ToOrientation()
	root.CFrame = CFrame.new(root.Position) * CFrame.fromOrientation(0, yaw, 0)
	root.AssemblyAngularVelocity = Vector3.zero
end

local function standBackUp(state)
	local humanoid = state.humanoid
	if not humanoid then
		return
	end
	for stateType, enabled in pairs(state.tripStates or {}) do
		pcall(humanoid.SetStateEnabled, humanoid, stateType, enabled)
	end
	task.defer(function()
		-- a villain catch's ragdoll (GearService, Physics state) owns the body: leave it to GearRagdollController
		if humanoid.Parent == nil or humanoid.Health <= 0 or humanoid.PlatformStand
			or state.character:GetAttribute("Ragdolled") == true then
			return
		end
		local ok, current = pcall(humanoid.GetState, humanoid)
		local root = humanoid.RootPart
		if ok and TRIPPED[current] and root then
			uprightRoot(root)
			pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.GettingUp)
		end
	end)
end

local function endState(token)
	local state = states[token]
	if not state then
		return
	end
	states[token] = nil
	if stateByCharacter[state.character] == state then
		stateByCharacter[state.character] = nil
	end
	for name in pairs(state.written) do
		releaseJoint(jointEntry(state.character, name))
	end
	if state.humanoid then
		standBackUp(state)
	end
	for _, emitter in ipairs(state.emitters) do
		emitter.Enabled = false -- the last particles fade out instead of vanishing
	end
	for _, instance in ipairs(state.instances) do
		if instance.Parent then
			if instance:IsA("Attachment") and instance:FindFirstChildOfClass("ParticleEmitter") then
				table.insert(state.lingering, instance)
			else
				instance:Destroy()
			end
		end
	end
	task.delay(1.5, function()
		for _, attachment in ipairs(state.lingering) do
			if attachment.Parent then
				attachment:Destroy()
			end
		end
	end)
end

local localMovement = nil -- the local player's slide / spin while they are the victim

local function onDebuff(payload)
	local weapon = HeroWeapons.Get(payload.Weapon)
	local character = characterOfPlayer(payload.Victim)
	local humanoid, root = characterParts(character)
	local token = payload.Token
	if not weapon or not humanoid or type(token) ~= "number" then
		return
	end
	local previous = stateByCharacter[character]
	if previous then
		endState(previous.token)
	end
	local duration = math.clamp(tonumber(payload.Duration) or 2.5, 0.2, 5)
	local effect = payload.Effect
	local state = {
		token = token,
		effect = effect,
		character = character,
		weapon = weapon,
		startedAt = os.clock(),
		duration = duration,
		instances = {},
		emitters = {},
		lingering = {},
		written = {},
		seed = math.random() * 10,
	}
	states[token] = state
	stateByCharacter[character] = state
	local head = character:FindFirstChild("Head")
	head = if head and head:IsA("BasePart") then head else root

	local feet = root.CFrame * CFrame.new(0, -(humanoid.HipHeight + root.Size.Y / 2), 0)
	if effect == "Webbed" then
		local cocoon = vfxModel("Web_Cocoon") -- the owner's cocoon wraps the victim
		if cocoon then
			table.insert(state.instances, cocoon)
			state.follow = { model = cocoon, base = cocoon:GetScale(), offset = root.CFrame:ToObjectSpace(feet), pop = 0.16 }
			cocoon:PivotTo(feet)
		end
		-- loose silk puffs while they struggle
		local silk = rootAttachment(state, root, "HeroWeaponSilk")
		for _, emitter in ipairs(attachEmitters(silk, T.puff(), { Enabled = true, Rate = 5, Color = ColorSequence.new(weapon.Color) })) do
			table.insert(state.emitters, emitter)
		end
	elseif effect == "Electrocuted" then
		-- particles only (owner 2026-09-27): the Shocked mutation's crackle on the body, lightning sparks, a flicker
		state.flash = highlightOn(state, character, weapon.Accent, 0.6, 0.2)
		state.zap = true
		local attachment = rootAttachment(state, root, "HeroWeaponZap")
		for _, emitter in ipairs(attachEmitters(attachment, T.lightning(), { Enabled = true, Scale = 0.35, Rate = 14 })) do
			table.insert(state.emitters, emitter)
		end
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		torso = if torso and torso:IsA("BasePart") then torso else root
		local crackle = rootAttachment(state, torso, "HeroWeaponShock")
		for _, emitter in ipairs(attachEmitters(crackle, T.shocked(), { Enabled = true, Scale = 0.9, Locked = true })) do
			table.insert(state.emitters, emitter)
		end
	elseif effect == "CleanKnockback" then
		local attachment = rootAttachment(state, root, "HeroWeaponSlide")
		local feet = rootAttachment(state, root, "HeroWeaponDust", Vector3.new(0, -root.Size.Y * 1.4, 0))
		for _, emitter in ipairs(attachEmitters(attachment, T.lines(), { Enabled = true, Scale = 0.6 })) do
			table.insert(state.emitters, emitter)
		end
		for _, emitter in ipairs(attachEmitters(feet, T.dust(), { Enabled = true, Rate = 60 })) do
			table.insert(state.emitters, emitter)
		end
		local slide = tonumber(payload.Slide) or 0.7
		task.delay(slide, function()
			for _, emitter in ipairs(state.emitters) do
				emitter.Enabled = false
			end
		end)
	elseif effect == "Dazed" then
		local ring = vfxModel("Dazed_Stars") -- the owner's star ring when imported
		if ring then
			table.insert(state.instances, ring)
			state.starRing = { model = ring, head = head }
		else
			state.marks = starBillboards(state, head, 4, "★", Color3.fromRGB(255, 220, 60))
		end
	elseif effect == "SmokeStun" then
		local cloud = Instance.new("Attachment")
		cloud.Name = "HeroWeaponSmokeCloud"
		cloud.Position = root.Position -- Terrain space = world space
		cloud.Parent = Workspace.Terrain
		table.insert(state.lingering, cloud)
		local smoke = vfxModel("Bat_Smoke_Cloud") -- the owner's bat smoke cloud when imported
		if smoke then
			smoke:PivotTo(feet)
			smoke:ScaleTo(smoke:GetScale() * 1.5)
			fadeModel(smoke, 0.45, math.max(duration - 0.45, 0.1))
			attachEmitters(cloud, T.smokeBomb(), { Emit = 1, Scale = 0.45 })
		else
			attachEmitters(cloud, T.smokeBomb(), { Emit = 2, Scale = 0.55 })
		end
		local puffs = rootAttachment(state, head, "HeroWeaponPuffs", Vector3.new(0, 0.8, 0))
		for _, emitter in ipairs(attachEmitters(puffs, T.puff(), { Enabled = true })) do
			table.insert(state.emitters, emitter)
		end
		state.marks = starBillboards(state, head, 1, "?", Color3.fromRGB(235, 235, 240))
	elseif effect == "ExplosionBlast" then
		state.soot = highlightOn(state, character, Color3.fromRGB(38, 30, 24), 0.3, 1)
		TweenService:Create(state.soot, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ FillTransparency = 1 }):Play()
		comicText(root.Position + Vector3.new(0, 3, 0), "BOOM!", Color3.fromRGB(255, 150, 30), 5, 0.8)
		local puffs = rootAttachment(state, head, "HeroWeaponPuffs", Vector3.new(0, 0.8, 0))
		for _, emitter in ipairs(attachEmitters(puffs, T.puff(), { Enabled = true })) do
			table.insert(state.emitters, emitter)
		end
	elseif effect == "SpinTornado" then
		local feet = rootAttachment(state, root, "HeroWeaponTwirl", Vector3.new(0, -root.Size.Y * 1.3, 0))
		for _, emitter in ipairs(attachEmitters(feet, T.twirl(), { Enabled = true })) do
			table.insert(state.emitters, emitter)
		end
		-- wind crescents whirl flat around the body at three heights
		for _, height in ipairs({ -1.6, 0, 1.6 }) do
			local ring = rootAttachment(state, root, "HeroWeaponWind", Vector3.new(0, height, 0))
			for _, emitter in ipairs(attachEmitters(ring, T.wind(), {
				Enabled = true,
				Rate = 7,
				Scale = 0.045,
				Color = ColorSequence.new(Color3.fromRGB(235, 245, 255)),
				Direction = Enum.NormalId.Top,
				Speed = NumberRange.new(0.01),
				Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			})) do
				table.insert(state.emitters, emitter)
			end
		end
	end

	-- the victim's own client moves the body it owns (and keeps it on its feet)
	if payload.Victim == LocalPlayer then
		holdUpright(state, humanoid)
		if effect == "CleanKnockback" or effect == "ExplosionBlast" then
			local direction = if typeof(payload.Direction) == "Vector3" then payload.Direction else -root.CFrame.LookVector
			direction = Vector3.new(direction.X, 0, direction.Z)
			direction = if direction.Magnitude > 0.01 then direction.Unit else -root.CFrame.LookVector
			local push = math.clamp(tonumber(payload.Push) or 30, 5, 80)
			local slide = math.clamp(tonumber(payload.Slide) or 0.6, 0.2, 1.5)
			localMovement = {
				kind = "slide",
				token = token,
				direction = direction,
				speed = 2 * push / slide,
				slide = slide,
				startedAt = os.clock(),
				hop = if effect == "ExplosionBlast" then 20 else 0,
			}
		elseif effect == "SpinTornado" then
			localMovement = { kind = "spin", token = token, startedAt = os.clock(), duration = duration }
		elseif effect == "SmokeStun" then
			smokeScreen(state, duration)
		end
	end
	task.delay(duration + 0.25, endState, token) -- DebuffEnd normally comes first
end

-- Per frame: the victims' look (arcs, stars, wind) and wobble, and the local slide / spin.
local function stepStates(now, dt)
	for _, state in pairs(states) do
		local character = state.character
		local humanoid, root = characterParts(character)
		if not humanoid then
			continue
		end
		local t = now - state.startedAt
		local effect = state.effect
		local waist = jointEntry(character, "Waist")
		local neck = jointEntry(character, "Neck")
		local wobbleWaist, wobbleNeck = nil, nil
		if state.follow and state.follow.model.Parent then
			local follow = state.follow
			local pop = math.min(t / follow.pop, 1)
			follow.model:ScaleTo(follow.base * (0.6 + 0.4 * (1 - (1 - pop) ^ 3)))
			follow.model:PivotTo(root.CFrame * follow.offset)
		end
		if state.starRing and state.starRing.model.Parent then
			local head = state.starRing.head
			state.starRing.model:PivotTo(CFrame.new(head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.6, 0))
				* CFrame.Angles(0, t * 5, 0))
		end
		if effect == "Electrocuted" then
			wobbleWaist = CFrame.Angles(math.rad(math.random(-9, 9)), math.rad(math.random(-14, 14)), math.rad(math.random(-9, 9)))
			wobbleNeck = CFrame.Angles(math.rad(math.random(-14, 14)), math.rad(math.random(-18, 18)), 0)
			if state.zap and (state.nextArc or 0) <= now then
				state.nextArc = now + 0.06
				local centre = root.Position
				if state.flash then
					state.flash.FillTransparency = if state.flash.FillTransparency > 0.5 then 0.25 else 0.8
				end
				-- small toon bolts snap around the body now and then, and a crackle of sparks
				if math.random() < 0.18 then
					local offset = Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 1.6, math.random() - 0.5) * 2.2
					burstAt(centre + offset, T.toonLightning(), { Scale = 0.22, Max = 2,
						Color = ColorSequence.new(state.weapon.Color) }, 0.6)
				end
				if math.random() < 0.35 then
					burstAt(centre + Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 3, math.random() - 0.5),
						T.sparks(), { Max = 1, Scale = 0.35, Color = ColorSequence.new(state.weapon.Color) }, 0.8)
				end
			end
		elseif effect == "Webbed" then
			wobbleWaist = CFrame.Angles(0, math.rad(math.sin(t * 22) * 10), math.rad(math.sin(t * 17) * 5))
			wobbleNeck = CFrame.Angles(0, math.rad(math.sin(t * 19 + 1) * 14), 0)
		elseif effect == "Dazed" or effect == "SmokeStun" then
			wobbleWaist = CFrame.Angles(0, 0, math.rad(math.sin(t * 5 + state.seed) * 9))
			wobbleNeck = CFrame.Angles(math.rad(math.sin(t * 4) * 8), 0, math.rad(math.cos(t * 5 + state.seed) * 14))
			if state.marks then
				local count = #state.marks
				for i, mark in ipairs(state.marks) do
					local a = t * 5 + (i / count) * math.pi * 2
					local radius = if count > 1 then 1.3 else 0.2
					mark.Position = Vector3.new(math.cos(a) * radius, 1.4 + math.sin(t * 6 + i) * 0.15, math.sin(a) * radius)
				end
			end
		end
		if wobbleWaist and waist then
			writeJoint(waist, basePose(waist) * wobbleWaist)
			state.written.Waist = true
		end
		if wobbleNeck and neck then
			writeJoint(neck, basePose(neck) * wobbleNeck)
			state.written.Neck = true
		end
	end

	local movement = localMovement
	if movement then
		local character = LocalPlayer.Character
		local humanoid, root = characterParts(character)
		if not humanoid or states[movement.token] == nil and movement.kind == "spin" then
			localMovement = nil
			return
		end
		local t = now - movement.startedAt
		if movement.kind == "slide" then
			if t >= movement.slide then
				localMovement = nil
				return
			end
			local speed = movement.speed * (1 - t / movement.slide)
			if root.CFrame.UpVector.Y < 0.97 then
				uprightRoot(root) -- slide back standing, never tumbling
			end
			local vy = root.AssemblyLinearVelocity.Y
			if movement.hop > 0 then
				vy = movement.hop
				movement.hop = 0
			end
			root.AssemblyLinearVelocity = Vector3.new(movement.direction.X * speed, vy, movement.direction.Z * speed)
		elseif movement.kind == "spin" then
			if t >= movement.duration then
				localMovement = nil
				return
			end
			local spin = 26 - 16 * (t / movement.duration)
			root.CFrame = root.CFrame * CFrame.Angles(0, spin * dt, 0)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- the local player's own attacks (instant) and the red target glow
----------------------------------------------------------------------------------------------------

local lastLocalAttackAt = -math.huge
local lastLocalWeapon = nil
local guard = nil

local function canAttackLocally(tool, weapon)
	local character = LocalPlayer.Character
	local humanoid = characterParts(character)
	if not humanoid or humanoid.Health <= 0 or tool.Parent ~= character then
		return false
	end
	if os.clock() - lastLocalAttackAt < (tonumber(weapon.Cooldown) or 0.7) then
		return false
	end
	if character:GetAttribute("Ragdolled") == true or character:GetAttribute("IsTrapped") == true
		or character:GetAttribute(HeroWeaponController.DEBUFF_ATTRIBUTE) ~= nil
		or LocalPlayer:GetAttribute(HeroWeaponController.CARRY_ATTRIBUTE) == true then
		return false
	end
	local okState, current = pcall(humanoid.GetState, humanoid)
	if humanoid.PlatformStand or (okState and HeroWeaponController.DOWN_STATES[current]) then
		return false -- no attacking while down (owner 2026-09-27)
	end
	if guard and type(guard.CanActivateLocal) == "function" then
		local ok, allowed = pcall(guard.CanActivateLocal, tool) -- shows "Cannot use items in the safe zone!"
		if ok and allowed ~= true then
			return false
		end
	end
	return true
end

local targetHighlight = nil -- the red glow on the rival the weapon would hit (refreshTarget)
local aimRemote = nil -- Network["Gear: WeaponAim"]
local lastTouch = nil -- { position = Vector2, at }: the last tap in the world (mobile aim)

-- Where this player aims an aimed weapon: the mouse (PC), the last tap in the world (touch), else the red target or
-- 30 studs along the camera's heading (gamepad). A character under the pointer is aimed at its middle, the ground a
-- little above it (the throw flies at body height).
local function aimPoint(character, root)
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local ray = nil
	local lastType = UserInputService:GetLastInputType()
	if lastType == Enum.UserInputType.Touch then
		if lastTouch and os.clock() - lastTouch.at < 0.6 then
			ray = camera:ScreenPointToRay(lastTouch.position.X, lastTouch.position.Y)
		end
	elseif not string.find(lastType.Name, "Gamepad") then
		local mouse = UserInputService:GetMouseLocation()
		ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	end
	if ray then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character, fxFolder() }
		params.RespectCanCollide = true
		local result = Workspace:Raycast(ray.Origin, ray.Direction * 800, params)
		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			local middle = humanoid and model:FindFirstChild("HumanoidRootPart")
			if middle and middle:IsA("BasePart") then
				return middle.Position
			end
			return result.Position + Vector3.new(0, 1.5, 0)
		end
		return ray.Origin + ray.Direction * 200
	end
	local adornee = targetHighlight and targetHighlight.Adornee
	local middle = adornee and adornee:FindFirstChild("HumanoidRootPart")
	if middle and middle:IsA("BasePart") then
		return middle.Position
	end
	return root.Position + HeroWeapons.Flat(camera.CFrame.LookVector, HeroWeapons.Flat(root.CFrame.LookVector, Vector3.new(0, 0, -1))) * 30
end

-- An aimed weapon's click: remember the aim, send it to the server, and turn to face it.
local function aimAndFace(tool)
	local character = LocalPlayer.Character
	local _, root = characterParts(character)
	if not root then
		return
	end
	local point = aimPoint(character, root)
	if not point then
		return
	end
	throwSeq += 1
	lastAim = { point = point, at = os.clock(), seq = throwSeq }
	if aimRemote then
		pcall(aimRemote.FireServer, aimRemote, tool, point, throwSeq)
	end
	local heading = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
	if heading.Magnitude > 0.5 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + heading.Unit)
	end
end

local hookedTools = setmetatable({}, { __mode = "k" })
local function hookTool(tool)
	if hookedTools[tool] or not tool:IsA("Tool") then
		return
	end
	local weapon = HeroWeapons.Of(tool)
	if not weapon or tool:GetAttribute("HeroWeaponId") == nil then
		return
	end
	hookedTools[tool] = true
	tool.Activated:Connect(function()
		if canAttackLocally(tool, weapon) then
			lastLocalAttackAt = os.clock()
			lastLocalWeapon = weapon
			if weapon.Aimed then
				aimAndFace(tool)
			end
			playClip(LocalPlayer.Character, weapon, { predicted = true, seq = if weapon.Aimed then throwSeq else nil })
		end
	end)
end

local function watchContainer(container)
	if not container then
		return
	end
	for _, child in ipairs(container:GetChildren()) do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

local function refreshTarget()
	local character = LocalPlayer.Character
	local tool = heldTool(character)
	local weapon = tool and HeroWeapons.Of(tool)
	local _, root = characterParts(character)
	local best = nil
	if weapon and root and character:GetAttribute(HeroWeaponController.DEBUFF_ATTRIBUTE) == nil then
		local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		forward = if forward.Magnitude > 0.01 then forward.Unit else Vector3.new(0, 0, -1)
		local range = weapon.Range
		local minDot = if weapon.Kind == "Slam" or weapon.Kind == "Spin" then -1 elseif weapon.Aimed then 0.3
			else weapon.MinDot
		local bestDistance = math.huge
		local candidates = {}
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= LocalPlayer and other.Character then
				table.insert(candidates, other.Character)
			end
		end
		local dummies = Workspace:FindFirstChild("HeroWeaponDummies")
		for _, dummy in ipairs(dummies and dummies:GetChildren() or {}) do
			if dummy:IsA("Model") then
				table.insert(candidates, dummy)
			end
		end
		for _, otherCharacter in ipairs(candidates) do
			local humanoid, otherRoot = characterParts(otherCharacter)
			if humanoid and humanoid.Health > 0 and otherCharacter:GetAttribute("Ragdolled") ~= true then
				local offset = otherRoot.Position - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local distance = offset.Magnitude
				local inCone = flat.Magnitude < 0.01 or flat.Unit:Dot(forward) >= minDot
				if distance <= range and inCone and math.abs(offset.Y) <= 8 and distance < bestDistance then
					best, bestDistance = otherCharacter, distance
				end
			end
		end
	end
	if best then
		if not targetHighlight or targetHighlight.Parent == nil then
			targetHighlight = Instance.new("Highlight")
			targetHighlight.Name = "HeroWeaponTarget"
			targetHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
			targetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
			targetHighlight.OutlineColor = Color3.fromRGB(107, 0, 0)
			targetHighlight.FillTransparency = 0.55
			targetHighlight.OutlineTransparency = 0.15
		end
		if targetHighlight.Adornee ~= best then
			targetHighlight.Adornee = best
			targetHighlight.Parent = best
		end
	elseif targetHighlight then
		targetHighlight.Adornee = nil
		targetHighlight.Parent = nil
	end
end

----------------------------------------------------------------------------------------------------
-- server broadcasts
----------------------------------------------------------------------------------------------------

local function onBatFx(payload)
	if type(payload) ~= "table" or type(payload.Weapon) ~= "string" and payload.Action ~= "DebuffEnd" then
		return -- classic bat swings / hits stay with Game.Tools.BatCombatFx
	end
	local action = payload.Action
	if action == "Swing" then
		local weapon = HeroWeapons.Get(payload.Weapon)
		local attacker = payload.Attacker
		if not weapon or typeof(attacker) ~= "Instance" or not attacker:IsA("Player") then
			return
		end
		if attacker == LocalPlayer then
			local echoWindow = (tonumber(weapon.Cooldown) or 0.7) - 0.05
			if lastLocalWeapon == weapon and os.clock() - lastLocalAttackAt < echoWindow then
				return -- already playing our own predicted attack
			end
			lastLocalAttackAt = os.clock()
			lastLocalWeapon = weapon
		end
		playClip(attacker.Character, weapon)
	elseif action == "Launch" then
		onLaunch(payload)
	elseif action == "ProjectileEnd" then
		onProjectileEnd(payload)
	elseif action == "ProjectileTurn" then
		onProjectileTurn(payload)
	elseif action == "Hit" then
		onHit(payload)
	elseif action == "Debuff" then
		onDebuff(payload)
	elseif action == "DebuffEnd" then
		if type(payload.Token) == "number" then
			endState(payload.Token)
			if localMovement and localMovement.token == payload.Token and localMovement.kind == "spin" then
				localMovement = nil
			end
		end
	end
end

function HeroWeaponController:Start()
	local library = ReplicatedStorage:WaitForChild("Library", 30)
	local modules = library and library:WaitForChild("Modules", 30)
	HeroWeapons = requireOptional(modules, "HeroWeapons")
	Kit = requireOptional(modules, "HeroWeaponTools")
	ClipMath = requireOptional(modules, "HeroClipMath")
	guard = requireOptional(library and library:FindFirstChild("Client"), "ToolGameplayGuard")
	if not HeroWeapons or not ClipMath then
		warnf("HeroWeapons / HeroClipMath missing - hero weapon attacks will not animate.")
		return
	end

	stepSignal:Connect(function(dt)
		for character, play in pairs(playing) do
			local ok, err = pcall(stepClip, character, play, dt)
			if not ok then
				pcall(stopClip, character) -- the joints, the pole and the charge go back
				playing[character] = nil
				warnf("clip step failed: " .. tostring(err))
			end
		end
		local ok, err = pcall(stepStates, os.clock(), dt)
		if not ok then
			warnf("state step failed: " .. tostring(err))
		end
	end)
	-- the attacker's light camera shake, after the camera scripts; last frame's offset is taken back off before they
	-- run, so the camera scripts never read it back (no drift)
	RunService:BindToRenderStep("HeroWeaponShakeUndo", Enum.RenderPriority.Camera.Value - 1, function()
		local camera = Workspace.CurrentCamera
		if camera and shake.applied then
			camera.CFrame = camera.CFrame * shake.applied:Inverse()
		end
		shake.applied = nil
	end)
	RunService:BindToRenderStep("HeroWeaponShake", Enum.RenderPriority.Camera.Value + 1, function()
		local elapsed = os.clock() - shake.startedAt
		local camera = Workspace.CurrentCamera
		if camera and shake.magnitude > 0 and elapsed < shake.seconds then
			local fade = 1 - elapsed / shake.seconds
			local m = math.rad(shake.magnitude) * fade * fade
			local t = os.clock() * 38
			local offset = CFrame.Angles(math.noise(t, 0.3) * m * 2, math.noise(t, 7.1) * m * 2, math.noise(t, 13.7) * m)
			camera.CFrame = camera.CFrame * offset
			shake.applied = offset
		end
	end)
	-- mobile aim: the last tap in the world (not the move stick's corner)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local camera = Workspace.CurrentCamera
		local size = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
		if input.Position.X < size.X * 0.35 and input.Position.Y > size.Y * 0.5 then
			return
		end
		lastTouch = { position = Vector2.new(input.Position.X, input.Position.Y), at = os.clock() }
	end)
	UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
		if not processedByUI then
			lastTouch = { position = position, at = os.clock() }
		end
	end)
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for index = #animations, 1, -1 do
			local ok, keep = pcall(animations[index], now)
			if not ok or not keep then
				table.remove(animations, index)
				if not ok then
					warnf("projectile failed: " .. tostring(keep))
				end
			end
		end
	end)

	local function onCharacterAdded(character)
		watchContainer(character)
		watchContainer(LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:WaitForChild("Backpack", 10))
	end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	if LocalPlayer.Character then
		task.spawn(onCharacterAdded, LocalPlayer.Character)
	end
	Players.PlayerRemoving:Connect(function(player)
		if player.Character then
			stopClip(player.Character)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(HeroWeaponController.TARGET_REFRESH)
			local ok, err = pcall(refreshTarget)
			if not ok then
				warnf("target glow failed: " .. tostring(err))
				task.wait(2)
			end
		end
	end)

	task.spawn(function()
		local network = ReplicatedStorage:WaitForChild("Network", 30)
		local remote = network and network:WaitForChild(HeroWeaponController.REMOTE_NAME, 30)
		if not (remote and remote:IsA("RemoteEvent")) then
			warnf("Network[\"" .. HeroWeaponController.REMOTE_NAME .. "\"] missing - other players' attacks will not show.")
			return
		end
		remote.OnClientEvent:Connect(function(payload)
			local ok, err = pcall(onBatFx, payload)
			if not ok then
				warnf(tostring(err))
			end
		end)
		local aim = network:WaitForChild(HeroWeapons.AIM_REMOTE, 30)
		if aim and aim:IsA("RemoteEvent") then
			aimRemote = aim
		else
			warnf("Network[\"" .. HeroWeapons.AIM_REMOTE .. "\"] missing - aimed throws go straight ahead.")
		end
	end)
end

-- test hooks
HeroWeaponController._onBatFx = function(payload)
	return onBatFx(payload)
end

return HeroWeaponController
