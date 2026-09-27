-- scripts/r15_rig_factory.luau
-- Offline (Lune) wrapper + validator for the hero rigs, used by scripts/hero_system_builder.luau.
--
-- The rigs themselves are the owner's models (assets/hero_models/*.rbxm, docs/HERO_MODELS_PLAN.md H1), normalised
-- to standard R15 bodies by scripts/lib/rig_convert.luau (H2). This module turns such a body into:
--   * a hero AssetModel     (contract C1: ReplicatedStorage.AssetModels.<HeroId>, what ItemDisplay /
--                            AssetComponent / AssetViewport consume)
--   * a hero template rig   (ReplicatedStorage.Assets.Models.Heroes.<HeroId>: a plain R15 character)
--   * a zone guard villain  (contract C2: Workspace.__OBJECTS.Areas.GuardAreas.<Zone>.Guard, what
--                            GuardChaseService / the GuardAreas client runtime drive)
-- and validates all three. Lune has no ScaleTo/PivotTo/GetBoundingBox, so rescaling and placement are CFrame math.
--
-- Rules this module relies on (verified with probes):
--   * Clone WHOLE subtrees only. A per-child clone keeps Motor6D/Weld refs pointing at the source rig and
--     they serialize as nil.
--   * WeldConstraint.CFrame0 is serialized; every WeldConstraint emitted here is re-captured after placement.
--   * Classic Shirt / Pants / ShirtGraphic render only on limbs that are direct children of a Humanoid's parent:
--     every clothed body gets a render-only Humanoid in the same Model.

local roblox = require("@lune/roblox")
local RigConvert = require("./lib/rig_convert")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Enum = roblox.Enum

local Factory = {}

Factory.R15_PARTS = RigConvert.R15_PARTS

-- { Motor6D name, Part0 name, Part1 name }; each Motor6D is parented to its Part1 (standard R15 layout).
Factory.R15_MOTORS = {}
for _, spec in ipairs(RigConvert.R15_JOINTS) do
	table.insert(Factory.R15_MOTORS, { spec[1], spec[2], spec[3] })
end

-- Legacy-style CENTER billboard anchor: 10.5 x 4.9 stud data billboard.
Factory.CENTER_SIZE = Vector3.new(0.6, 0.535, 0.001)

-- Visible height of a scale-1 body (the owner's models: Krillin 5.0 ... All Might 7.05 studs).
Factory.MIN_HEIGHT = 4
Factory.MAX_HEIGHT = 8

-- Never allowed inside a hero rig. Guards additionally allow ParticleEmitters under their SleepVFXAttachment
-- (sleep "Zzz" effect authored in the base place).
local FORBIDDEN_CLASSES = {
	Script = true, LocalScript = true, ModuleScript = true, Tool = true, Sound = true, KeyframeSequence = true,
	SurfaceAppearance = true, ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true,
	Sparkles = true, PointLight = true, SpotLight = true, SurfaceLight = true, BodyColors = true, Highlight = true,
	CharacterMesh = true, HumanoidDescription = true, WrapTarget = true, WrapLayer = true,
	BallSocketConstraint = true, RigidConstraint = true, AnimationConstraint = true, NoCollisionConstraint = true,
}
Factory.FORBIDDEN_CLASSES = FORBIDDEN_CLASSES

Factory.Bounds = RigConvert.Bounds
Factory.SyncWeldConstraints = RigConvert.SyncWeldConstraints
Factory.ScaleRig = RigConvert.ScaleRig
Factory.CheckJoints = RigConvert.CheckJoints

--------------------------------------------------------------------------------------------------
-- small helpers
--------------------------------------------------------------------------------------------------

local function rotOnly(cf)
	return cf - cf.Position
end

local function isJoint(inst)
	return inst:IsA("JointInstance") or inst:IsA("WeldConstraint")
end

local function isVisible(part)
	return part.Transparency < 1
end

local function destroyDanglingJoints(root)
	local removed = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil and isJoint(d) then
			local p0, p1 = d.Part0, d.Part1
			if p0 == nil or p1 == nil or not p0:IsDescendantOf(root) or not p1:IsDescendantOf(root) then
				d:Destroy()
				removed += 1
			end
		end
	end
	return removed
end

local function invisiblePart(name, size, cf)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Transparency = 1
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	return p
end

-- classic clothing that needs a Humanoid to render
local function hasClothing(model)
	for _, c in ipairs(model:GetChildren()) do
		if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") then
			return true
		end
	end
	return false
end
Factory.HasClothing = hasClothing

-- Render-only Humanoid: classic Shirt/Pants/ShirtGraphic are composited only onto limbs that are direct children
-- of the Humanoid's parent, so it must sit in the same Model as the limbs and the clothing. No Animator
-- (AssetViewport and the guards pick their Animator elsewhere), no state machine, no name/health UI.
local function addRenderOnlyHumanoid(parent, name, hipHeight)
	local h = Instance.new("Humanoid")
	h.Name = name
	h.RigType = Enum.HumanoidRigType.R15
	h.EvaluateStateMachine = false
	h.RequiresNeck = false
	h.BreakJointsOnDeath = false
	h.AutomaticScalingEnabled = false
	h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	h.NameDisplayDistance = 0
	h.HealthDisplayDistance = 0
	h.HipHeight = hipHeight
	h.Parent = parent
	return h
end

local function isRenderOnlyHumanoid(h)
	return h:IsA("Humanoid") and h.EvaluateStateMachine == false and h:FindFirstChildWhichIsA("Animator") == nil
		and h.RigType == Enum.HumanoidRigType.R15 and h.AutomaticScalingEnabled == false
		and h.DisplayDistanceType == Enum.HumanoidDisplayDistanceType.None
end

--------------------------------------------------------------------------------------------------
-- look policy + provenance
--------------------------------------------------------------------------------------------------

-- The owner's models ARE the characters: no runtime colour variant (AssetColorUtil skips DontModify) may repaint
-- them, and the Golden / Silver mutations (Mutations skips MutationsDontModify) must not wipe a texture.
function Factory.ProtectLook(body)
	for _, d in ipairs(body:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d:SetAttribute("DontModify", true)
			local textured = RigConvert.TextureUri(d) ~= nil
			for _, c in ipairs(d:GetChildren()) do
				if c:IsA("SpecialMesh") and RigConvert.TextureUri(c) ~= nil then
					textured = true
				end
			end
			if textured then
				d:SetAttribute("MutationsDontModify", true)
			end
		end
	end
end

-- source = { File = "assets/hero_models/Heroes.rbxm", Model = <owner's model name>, Rig = "R6"|"R15", Path = ... }
function Factory.TagSource(inst, source)
	inst:SetAttribute("SourceFile", source.File)
	inst:SetAttribute("SourceModel", source.Model)
	inst:SetAttribute("SourceRig", source.Rig)
	inst:SetAttribute("SourcePath", source.Path)
	inst:SetAttribute("ConvertedFromR6", source.Rig == "R6")
end

--------------------------------------------------------------------------------------------------
-- C1: hero AssetModel
--------------------------------------------------------------------------------------------------

-- Wrap a body from RigConvert.ToR15 into the runtime AssetModel structure (contract C1).
-- opts.ClothingHumanoid: add the render-only Humanoid when the body wears Shirt/Pants/ShirtGraphic.
-- opts.HipHeight: that Humanoid's HipHeight (the body's measured hip height).
function Factory.WrapAssetModel(heroId, body, opts)
	opts = opts or {}
	local root = body.HumanoidRootPart.CFrame

	local am = Instance.new("Model")
	am.Name = heroId
	local outer = invisiblePart("HumanoidRootPart", Vector3.new(2, 2, 1), root)
	outer.Parent = am
	am.PrimaryPart = outer

	local inner = Instance.new("Model")
	inner.Name = "Model"
	inner.Parent = am
	for _, c in ipairs(body:GetChildren()) do
		c.Parent = inner -- Parent moves keep refs
	end
	body:Destroy()

	local innerRoot = inner.HumanoidRootPart
	innerRoot.Transparency = 1
	innerRoot.Massless = true
	innerRoot.CanCollide = false
	innerRoot.CanTouch = false
	innerRoot.CanQuery = false
	inner.PrimaryPart = innerRoot

	local ac = Instance.new("AnimationController")
	ac.Name = "AnimationController"
	ac.Parent = inner
	local animator = Instance.new("Animator")
	animator.Name = "Animator"
	animator.Parent = ac

	if opts.ClothingHumanoid and hasClothing(inner) then
		-- AssetViewport picks the first Animator recursively: the AnimationController's, since this one has none
		addRenderOnlyHumanoid(inner, "Humanoid", opts.HipHeight or 2)
	end

	local aw = Instance.new("WeldConstraint")
	aw.Name = "AssetWeld"
	aw.Part0 = outer
	aw.Part1 = innerRoot
	aw.Parent = outer

	local _, maxV = Factory.Bounds(inner, isVisible)
	local top = maxV.Y
	local centerSize = opts.CenterSize or Factory.CENTER_SIZE
	-- billboard (7 * CENTER.Y / 0.767 studs tall, centred on CENTER) sits on top of the head
	local centerY = top + centerSize.Y * 7 / 0.767 / 2
	local center = invisiblePart("CENTER", centerSize, CFrame.new(root.Position.X, centerY, root.Position.Z) * rotOnly(root))
	center.Parent = am
	local cw = Instance.new("WeldConstraint")
	cw.Name = "CenterWeld"
	cw.Part0 = outer
	cw.Part1 = center
	cw.Parent = center

	for _, d in ipairs(am:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
		end
	end
	-- Model.Scale serializes as ScaleFactor; runtime asserts GetScale() == 1 for every AssetModel
	inner.Scale = 1
	am.Scale = 1
	am:SetAttribute("HeroId", heroId)
	am:SetAttribute("RigType", "R15")
	Factory.SyncWeldConstraints(am)
	return am
end

--------------------------------------------------------------------------------------------------
-- hero template rig (Assets.Models.Heroes.<HeroId>)
--------------------------------------------------------------------------------------------------

-- A plain R15 character: the body's parts as direct children, one Humanoid (R15, no state machine, no Animator)
-- so the classic clothing renders in a ViewportFrame, the root anchored so a stray clone never falls.
function Factory.WrapTemplateRig(heroId, body, hipHeight)
	body.Name = heroId
	local h = addRenderOnlyHumanoid(body, "Humanoid", hipHeight or 2)
	h.DisplayName = heroId
	body.HumanoidRootPart.Anchored = true
	body.PrimaryPart = body.HumanoidRootPart
	pcall(function()
		(body :: any).WorldPivotData = body.HumanoidRootPart.CFrame
	end)
	body:SetAttribute("HeroId", heroId)
	body:SetAttribute("RigType", "R15")
	body:SetAttribute("HipHeight", hipHeight or 2)
	return body
end

--------------------------------------------------------------------------------------------------
-- C2: zone guard
--------------------------------------------------------------------------------------------------

local GUARD_KEEP = { HumanoidRootPart = true, Collider = true, EggPoint = true, HumanoidMass = true }

-- a visible villain body part (the guard's own root / collider / egg point / mass parts are not the body)
local function isBodyVisible(part)
	return part.Transparency < 1 and not (part.Parent ~= nil and part.Parent:IsA("Model") and GUARD_KEEP[part.Name])
end

-- Find the authored alert/sleep presentation, preferring one under a part named Head.
local function findPresentation(guard, name)
	local best
	for _, d in ipairs(guard:GetDescendants()) do
		if d.Name == name then
			if d.Parent and d.Parent.Name == "Head" then
				return d
			end
			best = best or d
		end
	end
	return best
end

local function removeJointsOn(part, guard)
	for _, d in ipairs(guard:GetDescendants()) do
		if d.Parent ~= nil and isJoint(d) and (d.Part0 == part or d.Part1 == part) then
			d:Destroy()
		end
	end
end

local function weldToRoot(part, hrp, name)
	local w = Instance.new("WeldConstraint")
	w.Name = name
	w.Part0 = part
	w.Part1 = hrp
	w.Parent = part
	return w
end

-- Rebuild `guard` (Workspace.__OBJECTS.Areas.GuardAreas.<Zone>.Guard) as the stage villain (contract C2).
-- body: from RigConvert.ToR15 with HipHeight = 2 (2x2x1 root on 2-stud legs, feet at y = 0); it is scaled by
-- `scale` (RigScale) here. Returns a list of notes.
function Factory.ApplyGuard(guard, zone, heroId, body, scale, groundTop)
	local notes = {}
	local hrp = guard:FindFirstChild("HumanoidRootPart")
	assert(hrp and hrp:IsA("BasePart"), guard:GetFullName() .. " has no HumanoidRootPart")
	local humanoid = guard:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Name = "Humanoid"
		humanoid.Parent = guard
		table.insert(notes, "created missing Humanoid")
	end

	-- home: authored X/Z and yaw, upright, standing on the floor
	local authored = hrp.CFrame
	local flat = Vector3.new(authored.LookVector.X, 0, authored.LookVector.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local hrpSize = Vector3.new(2, 2, 1) * scale
	local hipHeight = 2 * scale
	local homePos = Vector3.new(authored.Position.X, groundTop + hipHeight + hrpSize.Y / 2, authored.Position.Z)
	-- yaw-only rotation; NOT CFrame.lookAt: Lune 0.10.5's lookAt/new(pos, target) mirror Z (look at -Z gives +Z)
	local look = flat.Unit
	local home = CFrame.new(homePos) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
	assert(home.LookVector:Dot(look) > 0.9999, "guard home facing math is wrong")

	-- keep the authored alert / sleep presentation, detached while the old body is removed
	local alertGui = findPresentation(guard, "AlertGui")
	local sleepVfx = findPresentation(guard, "SleepVFXAttachment")
	if alertGui then
		alertGui.Parent = nil
	end
	if sleepVfx then
		sleepVfx.Parent = nil
	end
	for _, d in ipairs(guard:GetDescendants()) do
		if d.Parent ~= nil and (d.Name == "AlertGui" or d.Name == "SleepVFXAttachment") then
			d:Destroy() -- duplicates (Desert had two of each)
		end
	end

	-- the previous body: inner Model, top-level Head/HeadProxy/CENTER and any other stray parts
	for _, c in ipairs(guard:GetChildren()) do
		if c.Name == "Model" or c.Name == "Extras" or (c:IsA("BasePart") and not GUARD_KEEP[c.Name]) or c:IsA("Accoutrement")
			or c:IsA("Clothing") or c:IsA("ShirtGraphic") or c:IsA("BodyColors") then
			table.insert(notes, "removed " .. c.ClassName .. " " .. c.Name)
			c:Destroy()
		end
	end
	for _, d in ipairs(guard:GetDescendants()) do
		if d.Parent ~= nil and (d:IsA("Animator") or d:IsA("AnimationController")) then
			d:Destroy()
		end
	end

	-- scale + place the villain body so its root lands exactly on the guard root
	local bodyRoot = body.HumanoidRootPart
	Factory.ScaleRig(body, scale, bodyRoot.CFrame, home)

	hrp.Size = bodyRoot.Size
	hrp.CFrame = home
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	for _, a in ipairs(bodyRoot:GetChildren()) do
		if a:IsA("Attachment") then
			local old = hrp:FindFirstChild(a.Name)
			if old then
				old:Destroy()
			end
			a.Parent = hrp -- same size/CFrame as the body root, so offsets stay valid
		end
	end

	-- Limbs, accessories, extras and clothing become DIRECT children of the guard, exactly like a player character:
	-- the driving Guard.Humanoid then dresses the Shirt/Pants and its Animator drives the standard R15 joints.
	-- (Owner 2026-09-23: with the body in a nested Guard.Model next to a second, render-only Humanoid the villains fell
	-- over and never played the default run.) The body first moves WHOLE into the guard (the place's DOM, internal refs
	-- intact); only then are its children moved one by one (a cross-DOM single move drops refs in Lune).
	body.Parent = guard
	local moved = {}
	for _, c in ipairs(body:GetChildren()) do
		if c ~= bodyRoot then
			c.Parent = guard
			table.insert(moved, c)
		end
	end
	local lowerTorso = guard:FindFirstChild("LowerTorso")
	local rootMotor = lowerTorso and lowerTorso:FindFirstChild("Root")
	assert(rootMotor and rootMotor:IsA("Motor6D") and rootMotor.Part0 == bodyRoot, "villain body lost its Root motor")
	for _, d in ipairs(guard:GetDescendants()) do
		if isJoint(d) and (d.Part0 == bodyRoot or d.Part1 == bodyRoot) then
			if d.Part0 == bodyRoot then
				d.Part0 = hrp
			else
				d.Part1 = hrp
			end
		end
	end
	body:Destroy()
	-- ScaleFactor metadata only (base guards carried the animals' 0.8-11.8); RigScale records the real scale
	guard.Scale = 1
	for _, c in ipairs(moved) do
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.Massless = true
			end
		end
		if c:IsA("BasePart") then
			c.CanCollide = false
			c.Massless = true
		end
	end

	-- Head presentation (client GuardComponent.new: WaitFor.Descendant(Guard,"Head") -> WaitFor.Descendant(head,"AlertGui"))
	local head = guard.Head
	if alertGui then
		-- Adornee stays unset (nil in every base guard): the billboard follows its parent Head.
		-- It is only a template: GuardComponent._showAlert shows an Enabled clone for 3 s.
		-- The icon floats above whatever tops the head (hair, horns, helmets), not inside it.
		local _, visTop = Factory.Bounds(guard, isBodyVisible)
		local aboveHead = math.max(head.Size.Y / 2, visTop.Y - head.CFrame.Position.Y)
		alertGui.Enabled = false
		alertGui.Size = roblox.UDim2.new(3, 0, 3, 0)
		alertGui.StudsOffset = Vector3.new(0, 0, 0)
		alertGui.StudsOffsetWorldSpace = Vector3.new(0, aboveHead + 1.75, 0)
		alertGui.Parent = head
	else
		table.insert(notes, "WARNING: no authored AlertGui found (client GuardComponent needs one)")
	end
	if sleepVfx then
		sleepVfx.CFrame = CFrame.new(0.35 * scale, head.Size.Y / 2 + 0.6 * scale, 0)
		sleepVfx.Parent = head
	end

	-- Humanoid: R15, standard hip height for the scaled rig, Animator for server-driven animation
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = hipHeight
	humanoid.AutomaticScalingEnabled = false
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local animator = Instance.new("Animator")
	animator.Name = "Animator"
	animator.Parent = humanoid

	-- Guard.Humanoid is the only Humanoid: its parent holds the limbs and the Shirt/Pants, so it dresses them.

	local _, bodyMax = Factory.Bounds(guard, isBodyVisible)

	-- Collider: body-sized box, bottom half a stud above the floor, welded to the root
	local collider = guard:FindFirstChild("Collider")
	if collider and collider:IsA("BasePart") then
		removeJointsOn(collider, guard)
		local bottom = groundTop + 0.5
		local height = math.max(bodyMax.Y - bottom, 4 * scale)
		collider.Size = Vector3.new(4 * scale, height, 3 * scale)
		collider.CFrame = CFrame.new(home.Position.X, bottom + height / 2, home.Position.Z) * rotOnly(home)
		collider.CanCollide = true
		collider.Massless = true
		collider.Transparency = 1
		weldToRoot(collider, hrp, "ColliderWeld")
	else
		table.insert(notes, "WARNING: guard has no Collider")
	end

	-- EggPoint: carried/retrieved egg sits in front of the chest
	local eggPoint = guard:FindFirstChild("EggPoint")
	if eggPoint and eggPoint:IsA("BasePart") then
		removeJointsOn(eggPoint, guard)
		eggPoint.CFrame = home * CFrame.new(0, 0.2 * scale, -1.4 * scale)
		eggPoint.Massless = true
		eggPoint.CanCollide = false
		weldToRoot(eggPoint, hrp, "EggPointWeld")
	end

	local mass = guard:FindFirstChild("HumanoidMass")
	if mass and mass:IsA("BasePart") then
		removeJointsOn(mass, guard)
		mass.CFrame = home
		mass.CanCollide = false
		weldToRoot(mass, hrp, "MassWeld")
	end

	destroyDanglingJoints(guard)

	guard.PrimaryPart = hrp
	pcall(function()
		(guard :: any).WorldPivotData = home
	end)
	for _, d in ipairs(guard:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true -- whole guard anchored in the file; GuardChaseService frees non-root parts
		end
	end

	guard:SetAttribute("HeroId", heroId)
	guard:SetAttribute("RigType", "R15")
	guard:SetAttribute("RigScale", scale)
	guard:SetAttribute("HeadLookAtDisabled", true)
	guard:SetAttribute("HeadLookAtBoneName", nil)
	guard:SetAttribute("HeadLookAtMotorName", nil)
	-- runtime attributes captured mid-chase in the base place (Snow) are reset to the sleeping state
	guard:SetAttribute("GuardState", "Sleeping")
	guard:SetAttribute("Sleeping", true)
	guard:SetAttribute("TargetPlayer", "")
	guard:SetAttribute("WakeTargetPlayer", "")
	zone:SetAttribute("ServerChase", true)

	Factory.SyncWeldConstraints(guard)
	return notes
end

--------------------------------------------------------------------------------------------------
-- validation
--------------------------------------------------------------------------------------------------

local function checkR15Skeleton(body, expectedRoot, errs, label)
	local function E(s)
		table.insert(errs, label .. ": " .. s)
	end
	for _, n in ipairs(Factory.R15_PARTS) do
		local p = body:FindFirstChild(n)
		if not (p and p:IsA("BasePart")) then
			E("missing R15 part " .. n)
		end
	end
	for _, n in ipairs({ "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
		if body:FindFirstChild(n) then
			E("still has R6 part " .. n)
		end
	end
	for _, spec in ipairs(Factory.R15_MOTORS) do
		local p1 = body:FindFirstChild(spec[3])
		local m = p1 and p1:FindFirstChild(spec[1])
		local ok = m and m:IsA("Motor6D") and m.Part1 == p1 and m.Part0 ~= nil and m.Part0.Name == spec[2]
		if ok and spec[1] == "Root" then
			ok = m.Part0 == expectedRoot
		elseif ok then
			ok = m.Part0.Parent == body
		end
		if not ok then
			E(string.format("Motor6D %s must be %s -> %s (parented to %s)", spec[1], spec[2], spec[3], spec[3]))
		end
	end
end

local function checkClasses(root, errs, label, allowParticlesUnder)
	for _, d in ipairs(root:GetDescendants()) do
		if FORBIDDEN_CLASSES[d.ClassName] or d:IsA("LuaSourceContainer") then
			local allowed = allowParticlesUnder and d:IsA("ParticleEmitter") and d:IsDescendantOf(allowParticlesUnder)
			if not allowed then
				table.insert(errs, label .. ": forbidden " .. d.ClassName .. " " .. d:GetFullName())
			end
		end
		if d:IsA("BasePart") and d.Name == "Segment1" then
			table.insert(errs, label .. ": part named Segment1 (ItemDisplay would make it the PrimaryPart)")
		end
	end
end

-- The owner's look, not a procedural one: no part-built props, every accessory on its attachment.
local function checkLook(body, errs, label)
	local function E(s)
		table.insert(errs, label .. ": " .. s)
	end
	if body:FindFirstChild("Props") then
		E("procedural Props folder left over")
	end
	for _, d in ipairs(body:GetDescendants()) do
		if d:GetAttribute("PropOf") ~= nil then
			E("procedural prop left over: " .. d:GetFullName())
		end
		if d:IsA("Accoutrement") then
			local handle = d:FindFirstChild("Handle")
			local weld = handle and handle:FindFirstChild("AccessoryWeld")
			local ok = weld ~= nil and weld:IsA("Weld") and weld.Part0 == handle and weld.Part1 ~= nil and weld.Part1.Parent == body
			if ok then
				local named = false
				for _, a in ipairs(handle:GetChildren()) do
					local ba = a:IsA("Attachment") and weld.Part1:FindFirstChild(a.Name)
					if ba and ba:IsA("Attachment") and RigConvert.CFramesMatch(weld.C0, a.CFrame, 0.01)
						and RigConvert.CFramesMatch(weld.C1, ba.CFrame, 0.01) then
						named = true
					end
				end
				ok = named
			end
			if not ok then
				E("accessory " .. d.Name .. " is not AccessoryWeld'ed to the body part owning its attachment")
			end
		end
	end
end

-- Contract C1. Returns (errors, stats).
function Factory.ValidateAssetModel(am, heroId)
	local errs = {}
	local label = "AssetModels." .. heroId
	local function E(s)
		table.insert(errs, label .. ": " .. s)
	end
	local stats = {}
	if not am:IsA("Model") then
		E("not a Model")
		return errs, stats
	end
	if (am :: any).Scale ~= 1 then
		E("Model.Scale ~= 1")
	end
	if am:GetAttribute("HeroId") ~= heroId or am:GetAttribute("RigType") ~= "R15" then
		E("attributes HeroId/RigType missing")
	end
	if type(am:GetAttribute("SourceFile")) ~= "string" or type(am:GetAttribute("SourceModel")) ~= "string" then
		E("attributes SourceFile/SourceModel missing (the owner's model it was built from)")
	end
	local hrp = am:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart") and am.PrimaryPart == hrp) then
		E("PrimaryPart must be the direct child HumanoidRootPart")
		return errs, stats
	end
	if (hrp.Size - Vector3.new(2, 2, 1)).Magnitude > 1e-3 or hrp.Transparency < 1 or not hrp.Massless
		or hrp.CanCollide or hrp.CanTouch or hrp.CanQuery then
		E("outer HumanoidRootPart must be 2x2x1, invisible, massless, non-colliding/touching/querying")
	end
	local inner = am:FindFirstChild("Model")
	if not (inner and inner:IsA("Model")) then
		E("inner Model missing")
		return errs, stats
	end
	local innerRoot = inner:FindFirstChild("HumanoidRootPart")
	if not (innerRoot and innerRoot:IsA("BasePart") and inner.PrimaryPart == innerRoot) then
		E("inner Model.PrimaryPart must be its HumanoidRootPart")
	end
	if (inner :: any).Scale ~= 1 then
		E("inner Model.Scale ~= 1")
	end
	local aw = hrp:FindFirstChild("AssetWeld")
	if not (aw and aw.ClassName == "WeldConstraint" and aw.Part0 == hrp and aw.Part1 == innerRoot) then
		E("AssetWeld must be a WeldConstraint outer HumanoidRootPart -> Model.HumanoidRootPart")
	end
	local center = am:FindFirstChild("CENTER")
	local cw = center and center:FindFirstChild("CenterWeld")
	if not (center and center:IsA("BasePart") and center.Transparency >= 1 and center.Massless and not center.CanCollide) then
		E("CENTER must be an invisible, massless, non-colliding BasePart")
	end
	if not (cw and cw.ClassName == "WeldConstraint" and cw.Part0 == hrp and cw.Part1 == center) then
		E("CENTER.CenterWeld must be a WeldConstraint outer HumanoidRootPart -> CENTER")
	end
	local ac = inner:FindFirstChildWhichIsA("AnimationController")
	if not (ac and ac:FindFirstChildWhichIsA("Animator")) then
		E("inner Model needs a direct AnimationController with an Animator")
	end
	checkR15Skeleton(inner, innerRoot, errs, label)
	checkClasses(am, errs, label, nil)
	checkLook(inner, errs, label)

	local humanoids = {}
	for _, d in ipairs(am:GetDescendants()) do
		if d:IsA("Humanoid") then
			table.insert(humanoids, d)
		end
	end
	if #humanoids > 1 then
		E("more than one Humanoid")
	elseif #humanoids == 1 then
		local h = humanoids[1]
		if h.Parent ~= inner or not isRenderOnlyHumanoid(h) or not hasClothing(inner) then
			E("Humanoid allowed only as the render-only clothing Humanoid (inner Model, no state machine, no Animator, with Shirt/Pants)")
		end
	end
	if hasClothing(inner) and #humanoids == 0 then
		E("Shirt/Pants/ShirtGraphic present but no clothing Humanoid (classic clothing would not render)")
	end
	stats.humanoid = #humanoids == 1

	for _, d in ipairs(am:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Anchored or d.CanCollide then
				E("parts must be Anchored=false, CanCollide=false: " .. d:GetFullName())
			end
			if d:IsDescendantOf(inner) and d ~= innerRoot and not d:GetAttribute("DontModify") then
				E("part without DontModify (AssetColorUtil would repaint the owner's model): " .. d:GetFullName())
			end
		end
	end

	stats.parts = Factory.CheckJoints(am, hrp, errs, label)
	local minV, maxV = Factory.Bounds(inner, isVisible)
	stats.height = if minV then maxV.Y - minV.Y else 0
	if stats.height < Factory.MIN_HEIGHT or stats.height > Factory.MAX_HEIGHT then
		E(string.format("visible height %.2f outside %d..%d studs", stats.height, Factory.MIN_HEIGHT, Factory.MAX_HEIGHT))
	end
	if center and maxV and center.CFrame.Position.Y <= maxV.Y then
		E("CENTER must sit above the head")
	end
	return errs, stats
end

-- Assets.Models.Heroes.<HeroId>. Returns errors.
function Factory.ValidateTemplateRig(rig, heroId)
	local errs = {}
	local label = "Assets.Models.Heroes." .. heroId
	local function E(s)
		table.insert(errs, label .. ": " .. s)
	end
	if rig:GetAttribute("HeroId") ~= heroId or rig:GetAttribute("RigType") ~= "R15" then
		E("attributes HeroId/RigType missing")
	end
	if type(rig:GetAttribute("SourceFile")) ~= "string" then
		E("attribute SourceFile missing")
	end
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart") and rig.PrimaryPart == hrp) then
		E("PrimaryPart must be the HumanoidRootPart")
		return errs
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not (humanoid and humanoid.RigType == Enum.HumanoidRigType.R15) then
		E("needs an R15 Humanoid")
	end
	checkR15Skeleton(rig, hrp, errs, label)
	checkClasses(rig, errs, label, nil)
	checkLook(rig, errs, label)
	Factory.CheckJoints(rig, hrp, errs, label)
	return errs
end

-- Contract C2. Returns (errors, stats).
function Factory.ValidateGuard(guard, zone, heroId, scale, groundTop)
	local errs = {}
	local label = zone.Name .. ".Guard"
	local function E(s)
		table.insert(errs, label .. ": " .. s)
	end
	local stats = {}
	if zone:GetAttribute("ServerChase") ~= true then
		E("zone attribute ServerChase must be true")
	end
	if guard:GetAttribute("HeroId") ~= heroId or guard:GetAttribute("RigType") ~= "R15" or guard:GetAttribute("RigScale") ~= scale
		or guard:GetAttribute("HeadLookAtDisabled") ~= true then
		E("attributes HeroId/RigType/RigScale/HeadLookAtDisabled wrong")
	end
	if guard:GetAttribute("HeadLookAtBoneName") ~= nil or guard:GetAttribute("HeadLookAtMotorName") ~= nil then
		E("HeadLookAtBoneName/HeadLookAtMotorName must be cleared")
	end
	if type(guard:GetAttribute("SourceFile")) ~= "string" then
		E("attribute SourceFile missing (the owner's model it was built from)")
	end
	local hrp = guard:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart") and guard.PrimaryPart == hrp) then
		E("PrimaryPart must be the direct child HumanoidRootPart")
		return errs, stats
	end
	local hipHeight = 2 * scale
	if (hrp.Size - Vector3.new(2, 2, 1) * scale).Magnitude > 1e-3 or hrp.Transparency < 1 or hrp.CanCollide or not hrp.Anchored then
		E("HumanoidRootPart must be 2x2x1*scale, invisible, CanCollide=false, Anchored")
	end
	if hrp.CFrame.UpVector.Y < 0.999 then
		E("HumanoidRootPart must be upright")
	end
	local expectedY = groundTop + hipHeight + hrp.Size.Y / 2
	if math.abs(hrp.CFrame.Position.Y - expectedY) > 0.01 then
		E(string.format("HumanoidRootPart centre Y %.3f ~= groundTop + HipHeight + Size.Y/2 = %.3f", hrp.CFrame.Position.Y, expectedY))
	end
	-- flattened body (owner 2026-09-23): limbs + clothing are direct children of the guard, one Humanoid
	if guard:FindFirstChild("Model") then
		E("the villain body must be flattened into the guard (no Guard.Model)")
	end
	local driving, animators = {}, 0
	for _, d in ipairs(guard:GetDescendants()) do
		if d:IsA("Humanoid") then
			if d.Parent == guard then
				table.insert(driving, d)
			else
				E("unexpected Humanoid " .. d:GetFullName() .. " (only the driving Guard.Humanoid is allowed)")
			end
		elseif d:IsA("Animator") then
			animators += 1
		elseif (d:IsA("Clothing") or d:IsA("ShirtGraphic")) and d.Parent ~= guard then
			E(d.ClassName .. " must be a direct child of the guard (Guard.Humanoid dresses its parent's direct-child limbs)")
		end
	end
	stats.clothed = hasClothing(guard)
	local humanoid = guard:FindFirstChildOfClass("Humanoid")
	if not humanoid or #driving ~= 1 or humanoid.Name ~= "Humanoid" then
		E("exactly one Humanoid named Humanoid (direct child) required")
	elseif guard:FindFirstChild("Humanoid", true) ~= humanoid then
		E("a by-name Humanoid lookup under Guard must resolve Guard.Humanoid")
	else
		if humanoid.RigType ~= Enum.HumanoidRigType.R15 or math.abs(humanoid.HipHeight - hipHeight) > 1e-3 then
			E("Humanoid must be RigType R15 with HipHeight = 2*scale")
		end
		if not humanoid:FindFirstChildOfClass("Animator") or animators ~= 1 then
			E("exactly one Animator, parented to the Humanoid")
		end
	end
	local collider = guard:FindFirstChild("Collider")
	if not (collider and collider:IsA("BasePart") and collider.CanCollide and collider.Massless) then
		E("Collider must exist with CanCollide=true, Massless")
	else
		local bottom = collider.CFrame.Position.Y - collider.Size.Y / 2
		if bottom < groundTop + 0.5 - 1e-3 then
			E(string.format("Collider bottom %.2f below groundTop + 0.5", bottom))
		end
		local welded = false
		for _, d in ipairs(collider:GetChildren()) do
			if d:IsA("WeldConstraint") and ((d.Part0 == collider and d.Part1 == hrp) or (d.Part1 == collider and d.Part0 == hrp)) then
				welded = true
			end
		end
		if not welded then
			E("Collider must be WeldConstraint'ed to the HumanoidRootPart")
		end
	end
	local eggPoint = guard:FindFirstChild("EggPoint")
	if eggPoint then
		local welded = false
		for _, d in ipairs(eggPoint:GetChildren()) do
			if d:IsA("WeldConstraint") and d.Part1 == hrp then
				welded = true
			end
		end
		if not welded or not eggPoint.Massless then
			E("EggPoint must be massless and WeldConstraint'ed to the HumanoidRootPart")
		end
	end
	checkR15Skeleton(guard, hrp, errs, label)
	checkLook(guard, errs, label)
	local heads = 0
	for _, d in ipairs(guard:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Name == "Head" then
				heads += 1
			end
			if not d.Anchored then
				E("BasePart not anchored in the file: " .. d:GetFullName())
			end
			if not (d.Parent == guard and GUARD_KEEP[d.Name]) and (d.CanCollide or not d.Massless) then
				E("body parts must be CanCollide=false, Massless=true: " .. d:GetFullName())
			end
		end
	end
	local head = guard:FindFirstChild("Head")
	if heads ~= 1 then
		E(string.format("exactly one BasePart named Head expected (client GuardComponent looks it up recursively), found %d", heads))
	end
	local alert = head and head:FindFirstChild("AlertGui")
	if not (alert and alert:IsA("BillboardGui")) then
		E("Guard.Head must carry the AlertGui BillboardGui")
	elseif alert.Enabled then
		E("AlertGui is a template (GuardComponent shows Enabled clones) and must be Enabled=false")
	end
	local sleep = guard:FindFirstChild("SleepVFXAttachment", true)
	if sleep and sleep.Parent ~= head then
		E("SleepVFXAttachment must live under Guard.Head")
	end
	checkClasses(guard, errs, label, sleep)
	stats.parts = Factory.CheckJoints(guard, hrp, errs, label)
	local minV, maxV = Factory.Bounds(guard, isBodyVisible)
	stats.height = if minV then maxV.Y - minV.Y else 0
	-- the feet stand on the floor (a long cloak may dip below them, as authored)
	local feetMin = math.huge
	for _, n in ipairs({ "LeftFoot", "RightFoot" }) do
		local foot = guard:FindFirstChild(n)
		if foot and foot:IsA("BasePart") then
			feetMin = math.min(feetMin, (RigConvert.PartAabb(foot)).Y)
		end
	end
	stats.feetGap = if feetMin < math.huge then feetMin - groundTop else 0
	if math.abs(stats.feetGap) > 0.05 then
		E(string.format("feet are %.2f studs off the floor", stats.feetGap))
	end
	-- the scale-1 body height range, scaled by the villain's RigScale (Kaido 1.9 is ~12 studs tall by design)
	if stats.height < Factory.MIN_HEIGHT * scale or stats.height > Factory.MAX_HEIGHT * scale then
		E(string.format("visible height %.2f outside %.2f..%.2f studs (%d..%d x RigScale %.2f)", stats.height,
			Factory.MIN_HEIGHT * scale, Factory.MAX_HEIGHT * scale, Factory.MIN_HEIGHT, Factory.MAX_HEIGHT, scale))
	end
	stats.hasAlert = alert ~= nil
	stats.hasSleepVfx = sleep ~= nil
	return errs, stats
end

return Factory
