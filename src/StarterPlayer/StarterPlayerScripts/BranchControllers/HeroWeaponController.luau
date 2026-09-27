--!nonstrict
-- StarterPlayer.StarterPlayerScripts.BranchControllers.HeroWeaponController (Branch controller; injected by
-- scripts/inject/hero_weapons.luau, started by StarterPlayerScripts.BranchClient)
--
-- Owner 2026-09-27, "MISSION: replace the bat system with Hero Gadgets". The client half of the hero weapons
-- (ReplicatedStorage.Library.Modules.HeroWeapons; server: ServerScriptService.GearService). It only draws and moves
-- the local character when the server says so; it never sends anything.
--   * Attack: the owner's R15 attack clip of the weapon (ReplicatedStorage.Directory.WeaponAnimations.<Id>, generated
--     from assets/hero_weapons/animations/*.rbxmx) is played on the attacker's Motor6D.Transform in PreSimulation,
--     after the Animator (no animation asset): the upper body always, the hips and legs only while standing still, with
--     a short blend in and out of the Animator's pose. Every client plays it for every attacker: the local player's own
--     click starts it at once (same gates and cooldown as the server, the server's echo is ignored), the others come
--     from Network["Gear: BatFx"] { Action = "Swing", Weapon }. The Gum-Gum fist stretches and the Power Pole extends
--     along their clips (HeroWeaponTools.SetGomuTime / SetPoleTime); at the clip's Impact keyframe the attack's own
--     effect plays (Bakugo's blast, Mjolnir's ground slam and lightning, the pole / fist bursts).
--   * { Action = "Launch" }: the web line, the spinning batarang and Cap's thrown shield fly to the victim (the held
--     batarang / shield hide while they are away).
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

local function fxPart(props)
	local part = Instance.new(props.Shape and "Part" or "Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.Material = props.Material or Enum.Material.Neon
	part.Color = props.Color or Color3.new(1, 1, 1)
	part.Transparency = props.Transparency or 0
	part.Size = props.Size or Vector3.new(0.2, 0.2, 0.2)
	if props.Shape then
		part.Shape = props.Shape
	end
	part.Name = props.Name or "HeroWeaponFx"
	if props.CFrame then
		part.CFrame = props.CFrame
	end
	part.Parent = props.Parent or fxFolder()
	return part
end

local function later(seconds, instance)
	task.delay(seconds, function()
		if instance and instance.Parent then
			instance:Destroy()
		end
	end)
end

-- A segment part from a to b (thickness w).
local function placeSegment(part, a, b, w)
	local length = (b - a).Magnitude
	if length < 1e-3 then
		part.Transparency = 1
		return
	end
	part.Size = Vector3.new(w, w, length)
	part.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -length / 2)
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

local function characterOfPlayer(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player.Character
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
	local anchor = fxPart({ Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1, CFrame = CFrame.new(position) })
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

-- A Neon ball that swells and fades (explosions, flashes).
local function flashBall(position, color, fromSize, toSize, seconds, transparency)
	local ball = fxPart({ Shape = Enum.PartType.Ball, Color = color, Size = Vector3.one * fromSize,
		CFrame = CFrame.new(position), Transparency = transparency or 0.05 })
	TweenService:Create(ball, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * toSize, Transparency = 1 }):Play()
	later(seconds + 0.05, ball)
	return ball
end

-- A flat ring (a thin Neon disc) that spreads and fades on the ground.
local function shockwave(position, color, radius, seconds)
	local disc = fxPart({ Shape = Enum.PartType.Cylinder, Color = color, Size = Vector3.new(0.15, 1, 1),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.2 })
	TweenService:Create(disc, TweenInfo.new(seconds, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.15, radius * 2, radius * 2), Transparency = 1 }):Play()
	later(seconds + 0.05, disc)
end

-- A jagged bolt of Neon segments between a and b that flickers for `seconds`.
local function lightningBolt(a, b, color, width, seconds)
	local segments = 7
	local parts = {}
	for i = 1, segments do
		parts[i] = fxPart({ Color = color, Transparency = 0.05 })
	end
	local started = os.clock()
	local function redraw()
		local previous = a
		local axis = b - a
		for i = 1, segments do
			local point = if i == segments then b else a + axis * (i / segments)
				+ Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * (axis.Magnitude * 0.12)
			placeSegment(parts[i], previous, point, width)
			previous = point
		end
	end
	redraw()
	task.spawn(function()
		while os.clock() - started < seconds do
			task.wait(0.05)
			redraw()
		end
		for _, part in ipairs(parts) do
			part:Destroy()
		end
	end)
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

local playing = {} -- [character] = { weapon, clip, startedAt, impact, length, samples, legs, written = {}, tool, impacted }
local onImpact -- (character, play) forward declaration

local function stopClip(character)
	local play = playing[character]
	if not play then
		return
	end
	playing[character] = nil
	for name in pairs(play.written) do
		releaseJoint(jointEntry(character, name))
	end
	if play.tool and Kit and (play.weapon.Id == "GomuFist" or play.weapon.Id == "PowerPole") then
		pcall(Kit.SetStretch, play.tool, 1)
	end
	for _, part in ipairs(play.vfxParts or {}) do
		part.Transparency = 1 -- the weapon's "VFX" section only shows during the attack
	end
end

local function playClip(character, weapon)
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
	playing[character] = {
		weapon = weapon,
		clip = clip,
		startedAt = os.clock(),
		impact = impact,
		length = length,
		samples = {},
		legs = if humanoid.MoveDirection.Magnitude > 0.1 then 0 else 1,
		written = {},
		tool = heldTool(character),
		impacted = false,
		humanoid = humanoid,
	}
	local play = playing[character]
	play.vfxParts = {}
	for _, part in ipairs(play.tool and play.tool:GetChildren() or {}) do
		if part:IsA("BasePart") and part:GetAttribute("HeroSection") == "VFX" then
			part.Transparency = 0 -- e.g. the Power Pole's energy arc (local, every client does the same)
			table.insert(play.vfxParts, part)
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
	local still = play.humanoid.MoveDirection.Magnitude < 0.1 and play.humanoid.FloorMaterial ~= Enum.Material.Air
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
	if play.tool and Kit then
		if play.weapon.Id == "GomuFist" then
			pcall(Kit.SetGomuTime, play.tool, elapsed)
		elseif play.weapon.Id == "PowerPole" then
			pcall(Kit.SetPoleTime, play.tool, elapsed)
		end
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
	if weapon.Id == "BakugoGauntlet" then
		-- BOOM: the blast leaves the nozzle and rolls forward
		local nozzle = if handle then handle.Position + forward * 1 else root.Position + forward * 2.5
		for i = 0, 3 do
			task.delay(i * 0.04, function()
				flashBall(nozzle + forward * (i * 3.2), if i % 2 == 0 then weapon.Color else weapon.Accent,
					1.2 + i * 0.8, 5 + i * 1.6, 0.32 + i * 0.03)
			end)
		end
		burstAt(nozzle + forward * 2, T.explosion(), { Scale = 0.6, Max = 18 }, 2)
		popModel("Comic_Explosion", CFrame.lookAt(nozzle + forward * 3.5, nozzle + forward * 5), 0.4, 1.7, 0.22, 0.12)
		comicText(nozzle + forward * 3 + Vector3.new(0, 2, 0), "BOOM!", Color3.fromRGB(255, 150, 30), 5, 0.75)
		playPop(nozzle, { 0.55, 0.65 }, 1.4)
	elseif weapon.Id == "Mjolnir" then
		-- the slam: a lightning bolt strikes the hammer, a shockwave rolls out, rocks jump
		local point = root.Position + forward * (tonumber(weapon.Reach) or 3.5) - Vector3.new(0, root.Size.Y * 1.5, 0)
		if vfxTemplate("Mjolnir_Lightning") then
			-- the owner's bolt meshes stacked from the sky onto the hammer
			for k = 0, 5 do
				popModel("Mjolnir_Lightning", CFrame.new(point + Vector3.new(0, k * 2.6 - 1.7, 0))
					* CFrame.Angles(0, math.random() * math.pi * 2, 0), 1.9, 2.2, 0.08, 0.14)
			end
		else
			lightningBolt(point + Vector3.new(math.random(-3, 3), 28, math.random(-3, 3)), point, weapon.Color, 0.35, 0.3)
		end
		shockwave(point + Vector3.new(0, 0.15, 0), weapon.Color, tonumber(weapon.Radius) or 11, 0.5)
		shockwave(point + Vector3.new(0, 0.2, 0), weapon.Accent, (tonumber(weapon.Radius) or 11) * 0.6, 0.35)
		flashBall(point + Vector3.new(0, 0.8, 0), weapon.Accent, 1, 6, 0.25)
		burstAt(point + Vector3.new(0, 0.5, 0), T.ground(), { Max = 40 }, 2)
		burstAt(point + Vector3.new(0, 1, 0), T.lightning(), { Scale = 0.5, Max = 12 }, 1.5)
		playPop(point, { 0.5, 0.6 }, 1.5)
	elseif weapon.Id == "PowerPole" then
		local tip = sectionPart(tool, "Tip")
		local at = if tip then tip.Position else root.Position + forward * 12
		flashBall(at, weapon.Accent, 0.6, 3.2, 0.22)
		burstAt(at, T.lines(), { Scale = 0.5, Max = 7 }, 1)
	elseif weapon.Id == "GomuFist" then
		local fist = sectionPart(tool, "Fist")
		local at = if fist then fist.Position else root.Position + forward * 5
		flashBall(at, Color3.new(1, 1, 1), 1, 4.5, 0.2, 0.35)
		burstAt(at, T.slap(), { Max = 12 }, 1.2)
	elseif weapon.Id == "CapShield" then
		local at = if handle then handle.Position + forward * 0.8 else root.Position + forward * 3
		flashBall(at, Color3.fromRGB(235, 240, 255), 1, 3.6, 0.18, 0.45)
	end
end

----------------------------------------------------------------------------------------------------
-- projectiles (Launch)
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

local function targetPoint(victim, fallback)
	local character = characterOfPlayer(victim)
	local _, root = characterParts(character)
	return if root then root.Position else fallback
end

local function launchWeb(attackerCharacter, payload, weapon)
	local hand = rightHandOf(attackerCharacter)
	local _, root = characterParts(attackerCharacter)
	if not hand or not root then
		return
	end
	local direction = if typeof(payload.Direction) == "Vector3" then payload.Direction else root.CFrame.LookVector
	local fallback = hand.Position + direction * (tonumber(payload.Distance) or 30)
	local travel = math.clamp(tonumber(payload.Travel) or 0.2, 0.05, 0.6)
	local line = fxPart({ Color = weapon.Color, Material = Enum.Material.SmoothPlastic, Transparency = 0.05 })
	local ball = fxPart({ Shape = Enum.PartType.Ball, Color = weapon.Color, Material = Enum.Material.SmoothPlastic,
		Size = Vector3.one * 0.7 })
	local blob = vfxModel("Web_Blob") -- the owner's web blob rides the tip when imported
	if blob then
		ball.Transparency = 1
	end
	burstAt(hand.Position, T.puff(), { Max = 6 }, 1)
	local started = os.clock()
	local lastFrom = hand.Position
	animate(function(now)
		local alpha = (now - started) / travel
		if hand.Parent then
			lastFrom = hand.Position
		end
		local to = targetPoint(payload.Victim, fallback) + Vector3.new(0, 0.6, 0)
		local tip = lastFrom:Lerp(to, math.min(alpha, 1))
		placeSegment(line, lastFrom, tip, 0.12)
		ball.CFrame = CFrame.new(tip)
		if blob then
			blob:PivotTo(CFrame.lookAt(tip, tip + (to - lastFrom).Unit))
		end
		if alpha >= 1 then
			ball:Destroy()
			if blob then
				blob:Destroy()
			end
			TweenService:Create(line, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			later(0.32, line)
			return false
		end
		return true
	end)
end

-- A spinning copy flies flat to the victim (and back to the hand for Cap's shield) while the held one hides. Both the
-- shield and the batarang are authored facing grip -Z / +Z, so a quarter turn about X lays them flat.
local FLAT = CFrame.Angles(math.rad(90), 0, 0)
local function launchThrown(attackerCharacter, payload, weapon, sections, returns)
	local tool = heldTool(attackerCharacter)
	local _, root = characterParts(attackerCharacter)
	local model, layout, from = cloneWeaponParts(tool, sections)
	if not model or not root then
		if model then
			model:Destroy()
		end
		return
	end
	local direction = if typeof(payload.Direction) == "Vector3" then payload.Direction else root.CFrame.LookVector
	local travel = math.clamp(tonumber(payload.Travel) or 0.3, 0.05, 0.6)
	local fallback = from + direction * (tonumber(payload.Distance) or 25)
	setSectionHidden(tool, sections, true)
	local started = os.clock()
	local total = if returns then travel * 2 else travel
	local reached = fallback
	animate(function(now)
		local t = now - started
		local position
		if t <= travel then
			local out = t / travel
			reached = targetPoint(payload.Victim, fallback) + Vector3.new(0, 0.5, 0)
			position = from:Lerp(reached, out) + Vector3.new(0, math.sin(out * math.pi) * 1.2, 0)
		else
			local back = math.min((t - travel) / travel, 1)
			local hand = rightHandOf(attackerCharacter)
			local home = if hand and hand.Parent then hand.Position else from
			position = reached:Lerp(home, back)
		end
		local frame = CFrame.new(position) * CFrame.fromAxisAngle(Vector3.yAxis, t * 30) * FLAT
		for part, offset in pairs(layout) do
			part.CFrame = frame * offset
		end
		if t >= total then
			model:Destroy()
			setSectionHidden(tool, sections, false)
			return false
		end
		return true
	end)
	if weapon.Id == "Batarang" and not payload.Victim then
		task.delay(travel, function()
			burstAt(fallback, T.smokeBomb(), { Emit = 1, Scale = 0.45 }, 3.5) -- a miss still pops a little smoke
		end)
	end
end

local function onLaunch(payload)
	local weapon = HeroWeapons.Get(payload.Weapon)
	local character = characterOfPlayer(payload.Attacker)
	if not weapon or not characterParts(character) then
		return
	end
	if weapon.Id == "WebShooter" then
		launchWeb(character, payload, weapon)
	elseif weapon.Id == "Batarang" then
		launchThrown(character, payload, weapon, { Blade = true, Handle = true }, false)
	elseif weapon.Id == "CapShield" then
		launchThrown(character, payload, weapon, nil, true)
	end
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
		playPop(position, { 0.85, 1 }, 1.2)
	elseif effect == "Webbed" then
		for _ = 1, 6 do
			local dir = Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5).Unit
			local blob = fxPart({ Shape = Enum.PartType.Ball, Material = Enum.Material.SmoothPlastic,
				Color = weapon.Color, Size = Vector3.one * 0.5, CFrame = CFrame.new(position) })
			TweenService:Create(blob, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = CFrame.new(position + dir * 2.4), Transparency = 1 }):Play()
			later(0.4, blob)
		end
		local attackerCharacter = characterOfPlayer(payload.Attacker)
		local _, attackerRoot = characterParts(attackerCharacter)
		local facing = if attackerRoot then attackerRoot.Position else position + Vector3.new(0, 0, -5)
		popModel("Web_Net", CFrame.lookAt(position, Vector3.new(facing.X, position.Y, facing.Z)), 0.3, 1.5, 0.14, 0.35)
		playPop(position, { 1.1, 1.25 }, 1.1)
	elseif effect == "Electrocuted" then
		flashBall(position, weapon.Accent, 2, 6, 0.2, 0.3)
		playPop(position, { 0.6, 0.7 }, 1.3)
	elseif effect == "CleanKnockback" then
		flashBall(position, Color3.new(1, 1, 1), 1.5, 5, 0.2, 0.4)
		burstAt(position, T.slap(), { Max = 14 }, 1.2)
		comicText(position + Vector3.new(0, 3, 0), "POW!", weapon.Accent, 4, 0.6)
		playPop(position, { 0.7, 0.8 }, 1.4)
	elseif effect == "SmokeStun" then
		burstAt(position, T.slap(), { Max = 8 }, 1.2)
		playPop(position, { 0.9, 1 }, 1.1)
	elseif effect == "ExplosionBlast" then
		flashBall(position, weapon.Color, 2, 8, 0.35)
		flashBall(position, weapon.Accent, 1, 5, 0.25)
		burstAt(position, T.explosion(), { Scale = 0.7, Max = 18 }, 2)
		local cam = Workspace.CurrentCamera
		local toward = if cam then cam.CFrame.Position else position + Vector3.new(0, 0, 10)
		popModel("Comic_Explosion", CFrame.lookAt(position, toward), 0.5, 1.9, 0.25, 0.2)
		playPop(position, { 0.55, 0.65 }, 1.4)
	elseif effect == "SpinTornado" then
		burstAt(position - Vector3.new(0, 2.5, 0), T.twirl(), { Max = 8 }, 1.2)
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

-- A white web net wrapped around the victim (octagon rings, strands to a knot over the head, cross strands).
local function buildWebNet(state, root, color)
	local model = Instance.new("Model")
	model.Name = "HeroWebNet"
	model.Parent = fxFolder()
	table.insert(state.instances, model)
	local base = root.CFrame
	local rings = { { -2.6, 1.9 }, { -1.1, 1.75 }, { 0.5, 1.65 }, { 1.7, 1.25 } }
	local top = base.Position + base.UpVector * 2.9
	local ringPoints = {}
	for r, ring in ipairs(rings) do
		ringPoints[r] = {}
		for i = 1, 8 do
			local a = (i / 8) * math.pi * 2 + r * 0.2
			ringPoints[r][i] = (base * CFrame.new(math.cos(a) * ring[2], ring[1], math.sin(a) * ring[2])).Position
		end
	end
	local function strand(a, b, w)
		local part = fxPart({ Material = Enum.Material.SmoothPlastic, Color = color, Transparency = 0.08,
			Parent = model, Name = "Strand" })
		placeSegment(part, a, b, w or 0.09)
		weldTo(part, root, part.CFrame)
	end
	for r = 1, #rings do
		for i = 1, 8 do
			strand(ringPoints[r][i], ringPoints[r][i % 8 + 1], 0.1)
			if r < #rings then
				strand(ringPoints[r][i], ringPoints[r + 1][i % 8 + 1], 0.07)
			end
		end
	end
	for i = 1, 8, 2 do
		strand(ringPoints[#rings][i], top, 0.09)
	end
	local knot = fxPart({ Shape = Enum.PartType.Ball, Material = Enum.Material.SmoothPlastic, Color = color,
		Size = Vector3.one * 0.55, Parent = model, CFrame = CFrame.new(top) })
	weldTo(knot, root, knot.CFrame)
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
		local cocoon = vfxModel("Web_Cocoon") -- the owner's cocoon wraps the victim when imported
		if cocoon then
			table.insert(state.instances, cocoon)
			state.follow = { model = cocoon, base = cocoon:GetScale(), offset = root.CFrame:ToObjectSpace(feet), pop = 0.16 }
			cocoon:PivotTo(feet)
		else
			buildWebNet(state, root, weapon.Color)
		end
	elseif effect == "Electrocuted" then
		state.flash = highlightOn(state, character, weapon.Accent, 0.6, 0.2)
		state.arcs = {}
		for i = 1, 12 do
			state.arcs[i] = fxPart({ Color = weapon.Color, Transparency = 0.05, Name = "Arc" })
			table.insert(state.instances, state.arcs[i])
		end
		local attachment = rootAttachment(state, root, "HeroWeaponZap")
		for _, emitter in ipairs(attachEmitters(attachment, T.lightning(), { Enabled = true, Scale = 0.35, Rate = 14 })) do
			table.insert(state.emitters, emitter)
		end
		state.bolts = {}
		for _ = 1, 3 do
			local bolt = vfxModel("Mjolnir_Lightning") -- the owner's bolts crackle around the body when imported
			if bolt then
				table.insert(state.bolts, bolt)
				table.insert(state.instances, bolt)
			end
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
		state.streaks = {}
		for i = 1, 6 do
			state.streaks[i] = fxPart({ Color = Color3.fromRGB(235, 245, 255), Transparency = 0.35, Name = "Wind",
				Size = Vector3.new(0.14, 2.4, 0.14) })
			table.insert(state.instances, state.streaks[i])
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
			if state.arcs and (state.nextArc or 0) <= now then
				state.nextArc = now + 0.06
				local centre = root.Position
				for i = 1, #state.arcs, 3 do
					local previous = centre + Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 4, math.random() - 0.5) * 2.4
					for k = 0, 2 do
						local point = previous + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 1.8
						local arc = state.arcs[i + k]
						if arc then
							arc.Transparency = 0.05
							placeSegment(arc, previous, point, 0.1)
						end
						previous = point
					end
				end
				if state.flash then
					state.flash.FillTransparency = if state.flash.FillTransparency > 0.5 then 0.25 else 0.8
				end
				for _, bolt in ipairs(state.bolts or {}) do
					local offset = Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 1.6, math.random() - 0.5) * 2.2
					bolt:PivotTo(CFrame.new(centre + offset - Vector3.new(0, 1.7, 0))
						* CFrame.Angles(math.random() * 0.6 - 0.3, math.random() * math.pi * 2, math.random() * 0.6 - 0.3))
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
		elseif effect == "SpinTornado" and state.streaks then
			for i, streak in ipairs(state.streaks) do
				local a = t * 14 + (i / #state.streaks) * math.pi * 2
				local height = ((i % 3) - 1) * 1.3
				local radius = 1.7 + (i % 2) * 0.5
				streak.CFrame = CFrame.new(root.Position + Vector3.new(math.cos(a) * radius, height, math.sin(a) * radius))
					* CFrame.Angles(0, -a, math.rad(25))
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
			playClip(LocalPlayer.Character, weapon)
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

local targetHighlight = nil
local function refreshTarget()
	local character = LocalPlayer.Character
	local tool = heldTool(character)
	local weapon = tool and HeroWeapons.Of(tool)
	local _, root = characterParts(character)
	local best = nil
	if weapon and root and character:GetAttribute(HeroWeaponController.DEBUFF_ATTRIBUTE) == nil then
		local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		forward = if forward.Magnitude > 0.01 then forward.Unit else Vector3.new(0, 0, -1)
		local range = weapon.ThrowRange or weapon.Range
		local minDot = if weapon.Kind == "Slam" then -1 else (weapon.ThrowMinDot or weapon.MinDot)
		local bestDistance = math.huge
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= LocalPlayer then
				local otherCharacter = other.Character
				local humanoid, otherRoot = characterParts(otherCharacter)
				if humanoid and humanoid.Health > 0 and otherCharacter:GetAttribute("Ragdolled") ~= true then
					local offset = otherRoot.Position - root.Position
					local flat = Vector3.new(offset.X, 0, offset.Z)
					local distance = offset.Magnitude
					local inCone = flat.Magnitude < 0.01 or flat.Unit:Dot(forward) >= minDot
					if weapon.Kind == "Melee" and distance <= weapon.Range then
						inCone = flat.Magnitude < 0.01 or flat.Unit:Dot(forward) >= weapon.MinDot
					end
					if distance <= range and inCone and math.abs(offset.Y) <= 8 and distance < bestDistance then
						best, bestDistance = otherCharacter, distance
					end
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
				playing[character] = nil
				warnf("clip step failed: " .. tostring(err))
			end
		end
		local ok, err = pcall(stepStates, os.clock(), dt)
		if not ok then
			warnf("state step failed: " .. tostring(err))
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
	end)
end

-- test hooks
HeroWeaponController._onBatFx = function(payload)
	return onBatFx(payload)
end

return HeroWeaponController
