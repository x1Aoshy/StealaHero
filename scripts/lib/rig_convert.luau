-- scripts/lib/rig_convert.luau
-- Offline (Lune) character-rig normaliser used by scripts/hero_system_builder.luau and
-- scripts/tools/extract_hero_models.luau (docs/HERO_MODELS_PLAN.md H2).
--
-- RigConvert.ToR15(source, template, opts) turns one of the owner's character models (R6 or R15, as extracted into
-- assets/hero_models/*.rbxm) into a clean, standard R15 body:
--   * HumanoidRootPart + the 15 R15 body parts as direct children, the 15 standard Motor6Ds (Root, Waist, Neck,
--     Left/RightShoulder/Elbow/Wrist, Left/RightHip/Knee/Ankle) parented to their Part1 with C0/C1 taken from the
--     standard *RigAttachment pairs (what Humanoid:BuildRigFromAttachments does), so the default Roblox R15
--     animations (idle 507766388, walk 507777826, run 507767714...) drive every rig;
--   * rest pose, facing -Z, feet bottom at y = 0, HumanoidRootPart upright at x = z = 0;
--   * every accessory welded (AccessoryWeld) to the R15 part that owns its attachment, every other visible part
--     ("extras": capes, swords, armour meshes, hair meshes...) welded (HeroWeld) to the body part it hung on,
--     keeping its offset from that part;
--   * no Humanoid, no scripts / sounds / effects / values / constraints (the builder adds the Humanoid it needs).
--
-- R6 sources (H2): the R15 body is a whole clone of the default block R15 template (assets/hero_models/
-- R15Template.rbxm: the owner's standard Rig-Builder block meshes, so classic Shirt / Pants / ShirtGraphic render),
-- coloured from the source's BodyColors (or its limbs), with the source's R6 Head kept (SpecialMesh + face Decal +
-- its attachments, plus a NeckRigAttachment and the Neck Motor6D). Accessories go to the R15 attachment of the same
-- name; extras keep their offset from the R6 limb they hung on, mapped onto that limb's REST position (R6 and block
-- R15 occupy the same volume: torso 2 studs from y 2 to 4 above the feet, head centre 4.5), and are welded to the
-- nearest R15 part of that limb. CharacterMesh packages and limb meshes cannot carry over and are reported.
--
-- Rules (Lune 0.10.5): whole-subtree clones only (refs stay internal), no PivotTo / GetPivot, CFrame.lookAt is never
-- used (yaw via CFrame.Angles), Content props untouched.

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Enum = roblox.Enum

local RigConvert = {}

RigConvert.R15_PARTS = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

-- { Motor6D, Part0, Part1, rig attachment } in parent-before-child order (the snap order).
RigConvert.R15_JOINTS = {
	{ "Root", "HumanoidRootPart", "LowerTorso", "RootRigAttachment" },
	{ "Waist", "LowerTorso", "UpperTorso", "WaistRigAttachment" },
	{ "Neck", "UpperTorso", "Head", "NeckRigAttachment" },
	{ "LeftShoulder", "UpperTorso", "LeftUpperArm", "LeftShoulderRigAttachment" },
	{ "LeftElbow", "LeftUpperArm", "LeftLowerArm", "LeftElbowRigAttachment" },
	{ "LeftWrist", "LeftLowerArm", "LeftHand", "LeftWristRigAttachment" },
	{ "RightShoulder", "UpperTorso", "RightUpperArm", "RightShoulderRigAttachment" },
	{ "RightElbow", "RightUpperArm", "RightLowerArm", "RightElbowRigAttachment" },
	{ "RightWrist", "RightLowerArm", "RightHand", "RightWristRigAttachment" },
	{ "LeftHip", "LowerTorso", "LeftUpperLeg", "LeftHipRigAttachment" },
	{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg", "LeftKneeRigAttachment" },
	{ "LeftAnkle", "LeftLowerLeg", "LeftFoot", "LeftAnkleRigAttachment" },
	{ "RightHip", "LowerTorso", "RightUpperLeg", "RightHipRigAttachment" },
	{ "RightKnee", "RightUpperLeg", "RightLowerLeg", "RightKneeRigAttachment" },
	{ "RightAnkle", "RightLowerLeg", "RightFoot", "RightAnkleRigAttachment" },
}

RigConvert.R6_LIMBS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

-- R6 limb (BodyColors slot) -> the R15 parts that take its colour / material and carry what hung on it.
RigConvert.R6_GROUPS = {
	Head = { "Head" },
	Torso = { "UpperTorso", "LowerTorso" },
	["Left Arm"] = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	["Right Arm"] = { "RightUpperArm", "RightLowerArm", "RightHand" },
	["Left Leg"] = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
	["Right Leg"] = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
	HumanoidRootPart = { "UpperTorso", "LowerTorso" },
}
local BODY_COLOR_PROP = {
	Head = "HeadColor3", Torso = "TorsoColor3", ["Left Arm"] = "LeftArmColor3", ["Right Arm"] = "RightArmColor3",
	["Left Leg"] = "LeftLegColor3", ["Right Leg"] = "RightLegColor3",
}
local R15_TO_R6 = {}
for limb, parts in pairs(RigConvert.R6_GROUPS) do
	if limb ~= "HumanoidRootPart" then
		for _, p in ipairs(parts) do
			R15_TO_R6[p] = limb
		end
	end
end

-- names reserved for body parts: an extra carrying one is renamed (the guards need exactly one "Head"; A10)
local RESERVED = { HumanoidRootPart = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true,
	["Right Leg"] = true }
for _, n in ipairs(RigConvert.R15_PARTS) do
	RESERVED[n] = true
end

-- Never carried into a hero body: code, audio, animation data, the source Humanoid and its appearance data,
-- effects, value objects, layered-clothing cages, UI, physics movers. (Joints / constraints are handled apart.)
local STRIP = {
	Script = true, LocalScript = true, ModuleScript = true, Sound = true, SoundGroup = true, Tool = true,
	KeyframeSequence = true, Keyframe = true, Pose = true, Animation = true, Animator = true, AnimationController = true,
	Humanoid = true, HumanoidDescription = true, AccessoryDescription = true, BodyPartDescription = true,
	BodyColors = true, CharacterMesh = true, ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true,
	Sparkles = true, PointLight = true, SpotLight = true, SurfaceLight = true, Highlight = true, SurfaceAppearance = true,
	ForceField = true, BillboardGui = true, SurfaceGui = true, Camera = true, Dialog = true, DialogChoice = true,
	BindableEvent = true, BindableFunction = true, RemoteEvent = true, RemoteFunction = true, Backpack = true,
	WrapTarget = true, WrapLayer = true, FaceControls = true, ClickDetector = true, ProximityPrompt = true,
	Configuration = true,
}
RigConvert.STRIP = STRIP

local EPS_POS = 0.05
local EPS_DOT = 0.999

--------------------------------------------------------------------------------------------------
-- geometry helpers
--------------------------------------------------------------------------------------------------

local function rotOnly(cf)
	return cf - cf.Position
end

local function scaleCF(cf, s)
	return CFrame.new(cf.Position * s) * rotOnly(cf)
end

local function cframesMatch(a, b, eps)
	return (a.Position - b.Position).Magnitude <= (eps or EPS_POS)
		and a.LookVector:Dot(b.LookVector) >= EPS_DOT
		and a.UpVector:Dot(b.UpVector) >= EPS_DOT
end
RigConvert.CFramesMatch = cframesMatch

-- upright, yaw-only frame at cf's position, keeping cf's horizontal facing (LookVector)
local function uprightYaw(cf)
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if look.Magnitude < 1e-3 then
		-- lying down: use the up vector's horizontal part as a fallback facing
		look = Vector3.new(-cf.UpVector.X, 0, -cf.UpVector.Z)
		if look.Magnitude < 1e-3 then
			look = Vector3.new(0, 0, -1)
		end
	end
	look = look.Unit
	return CFrame.new(cf.Position) * CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
end
RigConvert.UprightYaw = uprightYaw

-- world AABB of one part (rotation aware)
local function partAabb(part)
	local cf, half = part.CFrame, part.Size * 0.5
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ext = Vector3.new(
		math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z
	)
	return cf.Position - ext, cf.Position + ext
end
RigConvert.PartAabb = partAabb

-- World AABB (min, max) over BaseParts under root accepted by `filter` (default: every BasePart).
function RigConvert.Bounds(root, filter)
	local minV, maxV
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and (filter == nil or filter(d)) then
			local a, b = partAabb(d)
			minV = if minV then minV:Min(a) else a
			maxV = if maxV then maxV:Max(b) else b
		end
	end
	return minV, maxV
end

-- distance from a world point to a part's box
local function distanceToPart(point, part)
	local l = part.CFrame:PointToObjectSpace(point)
	local h = part.Size * 0.5
	local c = Vector3.new(math.clamp(l.X, -h.X, h.X), math.clamp(l.Y, -h.Y, h.Y), math.clamp(l.Z, -h.Z, h.Z))
	return (l - c).Magnitude
end

-- Re-capture every WeldConstraint offset from the current part CFrames (what Studio would have saved).
function RigConvert.SyncWeldConstraints(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("WeldConstraint") and d.Part0 and d.Part1 then
			(d :: any).CFrame0 = d.Part0.CFrame:ToObjectSpace(d.Part1.CFrame)
		end
	end
end

-- Uniform scale about `pivot` (world CFrame): part sizes/positions, joint offsets, attachments, meshes.
-- `retarget` (optional) moves the pivot to a new world CFrame in the same pass.
function RigConvert.ScaleRig(root, factor, pivot, retarget)
	local target = retarget or pivot
	local rel = {}
	local list = root:GetDescendants()
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, d in ipairs(list) do
		if d:IsA("BasePart") then
			rel[d] = pivot:ToObjectSpace(d.CFrame)
		end
	end
	for _, d in ipairs(list) do
		if d:IsA("BasePart") then
			d.Size = d.Size * factor
			d.CFrame = target * scaleCF(rel[d], factor)
		elseif d:IsA("JointInstance") then
			d.C0 = scaleCF(d.C0, factor)
			d.C1 = scaleCF(d.C1, factor)
		elseif d:IsA("Attachment") then
			d.CFrame = scaleCF(d.CFrame, factor)
		elseif d:IsA("SpecialMesh") then
			-- FileMesh scale is absolute; Head/Brick/Sphere meshes scale with the part Size already.
			if d.MeshType == Enum.MeshType.FileMesh then
				d.Scale = d.Scale * factor
			end
			d.Offset = d.Offset * factor
		elseif d:IsA("DataModelMesh") then
			pcall(function()
				(d :: any).Offset = (d :: any).Offset * factor
			end)
		end
	end
	RigConvert.SyncWeldConstraints(root)
end

--------------------------------------------------------------------------------------------------
-- structure helpers
--------------------------------------------------------------------------------------------------

function RigConvert.RigType(model)
	if model:FindFirstChild("UpperTorso") and model:FindFirstChild("LowerTorso") then
		return "R15"
	elseif model:FindFirstChild("Torso") then
		return "R6"
	end
	return nil
end

local function isLink(inst)
	return inst:IsA("JointInstance") or inst:IsA("WeldConstraint")
		or (inst:IsA("Constraint") and not inst:IsA("NoCollisionConstraint"))
end

local function linkParts(inst)
	if inst:IsA("JointInstance") or inst:IsA("WeldConstraint") then
		return inst.Part0, inst.Part1
	end
	local ok0, a0 = pcall(function()
		return (inst :: any).Attachment0
	end)
	local ok1, a1 = pcall(function()
		return (inst :: any).Attachment1
	end)
	local p0 = ok0 and a0 and a0.Parent
	local p1 = ok1 and a1 and a1.Parent
	return (p0 and p0:IsA("BasePart")) and p0 or nil, (p1 and p1:IsA("BasePart")) and p1 or nil
end

-- adjacency over every joint / weld / constraint whose two parts are inside `model`
local function buildLinks(model)
	local adj = {}
	for _, d in ipairs(model:GetDescendants()) do
		if isLink(d) then
			local p0, p1 = linkParts(d)
			if p0 and p1 and p0 ~= p1 and p0:IsDescendantOf(model) and p1:IsDescendantOf(model) then
				adj[p0] = adj[p0] or {}
				adj[p1] = adj[p1] or {}
				table.insert(adj[p0], p1)
				table.insert(adj[p1], p0)
			end
		end
	end
	return adj
end

-- AABB of a part in the frame `cf`
local function localAabb(part, cf)
	local rel, h = cf:ToObjectSpace(part.CFrame), part.Size * 0.5
	local mn, mx
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local p = rel * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
				mn = if mn then mn:Min(p) else p
				mx = if mx then mx:Max(p) else p
			end
		end
	end
	return mn, mx
end

-- A loose part (no joint, not parented under a limb) found nearest to an arm / leg is often a skirt, cape, belt,
-- long hair or a hip sword: those follow the torso (or the head) rather than one limb. name = lower-case name(s),
-- mn / mx = its bounds in the source root frame.
local function refineNearest(name, mn, mx, best, ctx)
	if not ctx then
		return best
	end
	if string.find(name, "hair", 1, true) then
		return ctx.head
	end
	local kind = ctx.kind[best]
	local centre = (mn + mx) / 2
	for _, word in ipairs({ "cape", "cloak", "coat", "robe", "scarf" }) do
		if string.find(name, word, 1, true) then
			return ctx.torsoFor(math.huge) -- hangs from the shoulders
		end
	end
	local straddles = mn.X < -0.25 and mx.X > 0.25
	if straddles and kind ~= "head" then
		if centre.Y > ctx.neckY then
			return ctx.head
		end
		return ctx.torsoFor(centre.Y)
	end
	if kind == "leg" then
		local legCentre = ctx.rootCf:PointToObjectSpace(best.CFrame.Position)
		local _, legTop = localAabb(best, ctx.rootCf)
		if centre.Y > legCentre.Y or mx.Y > legTop.Y then
			return ctx.torsoFor(math.min(centre.Y, legTop.Y)) -- hip level: belt, holster, hanging sword
		end
	end
	return best
end

local function nearestBodyPart(point, bodyList)
	local best, bestD = nil, math.huge
	for _, b in ipairs(bodyList) do
		if b.Name ~= "HumanoidRootPart" then
			local d = distanceToPart(point, b)
			if d < bestD then
				best, bestD = b, d
			end
		end
	end
	return best
end

-- The body part `part` hangs on: first body part reached through links (never crossing another body part),
-- else the body part it is parented under, else the nearest body part (HumanoidRootPart excluded, see
-- refineNearest).
local function findAnchor(part, isBody, adj, bodyList, ctx)
	local seen, queue, head = { [part] = true }, { part }, 1
	while head <= #queue do
		local n = queue[head]
		head += 1
		for _, o in ipairs(adj[n] or {}) do
			if not seen[o] then
				seen[o] = true
				if isBody[o] then
					return o, "joint"
				end
				table.insert(queue, o)
			end
		end
	end
	local p = part.Parent
	while p do
		if isBody[p] then
			return p, "parent"
		end
		p = p.Parent
	end
	local best = nearestBodyPart(part.CFrame.Position, bodyList)
	local mn, mx = if ctx then localAabb(part, ctx.rootCf) else Vector3.new(), Vector3.new()
	local refined = refineNearest(string.lower(part.Name), mn, mx, best, ctx)
	return refined, if refined == best then "nearest" else "nearest+"
end

local function newWeld(part0, part1, name)
	local w = Instance.new("Weld")
	w.Name = name
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = part0.CFrame:Inverse() * part1.CFrame
	w.C1 = CFrame.new()
	w.Parent = part1
	return w
end

local function newMotor(name, part0, part1, c0, c1)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = c0
	m.C1 = c1
	m.Parent = part1
	return m
end

local function textureUri(inst)
	for _, prop in ipairs({ "TextureContent", "ColorMapContent" }) do
		local ok, v = pcall(function()
			return (inst :: any)[prop]
		end)
		if ok and typeof(v) == "Content" then
			local okUri, uri = pcall(function()
				return v.Uri
			end)
			if okUri and type(uri) == "string" and uri ~= "" then
				return uri
			end
		end
	end
	return nil
end
RigConvert.TextureUri = textureUri

-- Strip everything a hero body never carries (see STRIP), plus ValueBase objects and physics movers.
-- Returns the removed class counts.
function RigConvert.Strip(root, keep)
	local removed = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil then
			local cls = d.ClassName
			local strip = (STRIP[cls] == true or d:IsA("ValueBase") or d:IsA("BodyMover") or d:IsA("GuiBase3d")
				or d:IsA("LuaSourceContainer")) and not (keep and keep[cls])
			if strip then
				removed[cls] = (removed[cls] or 0) + 1
				d:Destroy()
			end
		end
	end
	return removed
end

-- Every accessory-like container (Accessory, legacy Hat)
local function accoutrements(model)
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Accoutrement") then
			table.insert(list, d)
		end
	end
	return list
end

--------------------------------------------------------------------------------------------------
-- R15 rest pose
--------------------------------------------------------------------------------------------------

-- Rebuild the 15 standard Motor6Ds of `body` from its rig attachments (fallbacks: the source Motor6D's C0/C1, then
-- the template's attachment), then snap every body part into the rest pose from the HumanoidRootPart at `rootCf`.
-- Existing joints must already be gone. Returns notes.
local function rebuildR15(body, rootCf, oldMotors, template, notes)
	local hrp = body.HumanoidRootPart
	hrp.CFrame = rootCf
	for _, spec in ipairs(RigConvert.R15_JOINTS) do
		local name, n0, n1, attName = spec[1], spec[2], spec[3], spec[4]
		local p0, p1 = body:FindFirstChild(n0), body:FindFirstChild(n1)
		local a0 = p0:FindFirstChild(attName)
		local a1 = p1:FindFirstChild(attName)
		local c0, c1
		if a0 and a0:IsA("Attachment") and a1 and a1:IsA("Attachment") then
			c0, c1 = a0.CFrame, a1.CFrame
		elseif oldMotors[name] then
			c0, c1 = oldMotors[name].C0, oldMotors[name].C1
			table.insert(notes, string.format("%s: rig attachment %s missing, kept the source Motor6D offsets", name, attName))
		elseif template then
			local t0 = template:FindFirstChild(n0):FindFirstChild(attName)
			local t1 = template:FindFirstChild(n1):FindFirstChild(attName)
			local s0 = p0.Size / template:FindFirstChild(n0).Size
			local s1 = p1.Size / template:FindFirstChild(n1).Size
			c0 = CFrame.new(t0.CFrame.Position * s0) * rotOnly(t0.CFrame)
			c1 = CFrame.new(t1.CFrame.Position * s1) * rotOnly(t1.CFrame)
			table.insert(notes, string.format("%s: no rig attachment / motor, used the template's", name))
		else
			error(string.format("[rig_convert] %s: cannot rebuild joint %s (no %s and no source Motor6D)", body.Name, name, attName))
		end
		-- make sure both rig attachments exist and agree with the motor (Humanoid:BuildRigFromAttachments)
		for _, pair in ipairs({ { p0, c0 }, { p1, c1 } }) do
			local part, cf = pair[1], pair[2]
			local a = part:FindFirstChild(attName)
			if not (a and a:IsA("Attachment")) then
				a = Instance.new("Attachment")
				a.Name = attName
				a.Parent = part
			end
			a.CFrame = cf
		end
		newMotor(name, p0, p1, c0, c1)
		p1.CFrame = p0.CFrame * c0 * c1:Inverse()
	end
end

local function feetBottom(body)
	local y = math.huge
	for _, n in ipairs({ "LeftFoot", "RightFoot" }) do
		local mn = partAabb(body[n])
		y = math.min(y, mn.Y)
	end
	return y
end

local function translateBody(body, bodySet, delta)
	for part in pairs(bodySet) do
		part.CFrame = part.CFrame + delta
	end
end

--------------------------------------------------------------------------------------------------
-- conversion
--------------------------------------------------------------------------------------------------

-- Prepare the block R15 template once per build: stripped, rest pose, feet at 0 (see ToR15).
function RigConvert.PrepareTemplate(raw)
	local body, notes = RigConvert.ToR15(raw, nil, { KeepNaturalScale = true, Label = "R15Template" })
	for _, c in ipairs(body:GetChildren()) do
		if c:IsA("Clothing") or c:IsA("ShirtGraphic") or c:IsA("Accoutrement") or c.Name == "Extras" then
			c:Destroy()
		end
	end
	for _, d in ipairs(body:GetDescendants()) do
		if d.Parent ~= nil and (d:IsA("Decal") or (d:IsA("BasePart") and d.Parent ~= body)) then
			d:Destroy()
		end
	end
	for _, d in ipairs(body:GetDescendants()) do
		if d.Parent ~= nil and d:IsA("Weld") and d.Name == "HeroWeld" then
			d:Destroy()
		end
	end
	return body, notes
end

-- opts = { KeepNaturalScale = bool (R6 sources drawn bigger / smaller than 2x2x1 are scaled back to their authored
--          size after the conversion; default true), HipHeight = number? (villains: the HumanoidRootPart becomes 2x2x1
--          with its bottom exactly this far above the feet; the body keeps its size), Label = string? }
-- Returns (body Model, notes {string}, info { SourceRig, Scale, HipHeight, Accessories, Extras, Lost = {} }).
function RigConvert.ToR15(source, template, opts)
	opts = opts or {}
	local label = opts.Label or source.Name
	local notes = {}
	local info = { SourceRig = RigConvert.RigType(source), Accessories = 0, Extras = 0, Lost = {}, AttachmentPlaced = 0,
		OffsetPlaced = 0 }
	assert(info.SourceRig, "[rig_convert] " .. label .. " is neither R6 nor R15")
	local src = source:Clone() -- whole subtree: internal refs follow the copy
	src.Name = label
	-- Lune keeps every deserialized file in its own DOM: moving ONE instance across DOMs drops its refs to
	-- instances left behind (a Motor6D moved alone loses its Part0). So the whole clone first moves (with its
	-- internal refs) into a work container of the default DOM, and every piecemeal move below stays inside it.
	local work = Instance.new("Model")
	work.Name = "RigConvertWork"
	src.Parent = work

	-- what cannot carry over (reported), then the junk
	local bodyColors = src:FindFirstChildOfClass("BodyColors")
	local bc = {}
	if bodyColors then
		for limb, prop in pairs(BODY_COLOR_PROP) do
			bc[limb] = (bodyColors :: any)[prop]
		end
	end
	for _, d in ipairs(src:GetDescendants()) do
		if d:IsA("CharacterMesh") then
			table.insert(info.Lost, "CharacterMesh " .. d.Name)
		elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight")
			or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") or d:IsA("Beam") then
			table.insert(info.Lost, d.ClassName .. " " .. d.Name)
		elseif d:IsA("SurfaceAppearance") then
			table.insert(info.Lost, "SurfaceAppearance " .. d:GetFullName())
		end
	end
	RigConvert.Strip(src)

	-- body parts of the source rig
	local isR15 = info.SourceRig == "R15"
	local bodyNames = if isR15 then { "HumanoidRootPart", table.unpack(RigConvert.R15_PARTS) }
		else { "HumanoidRootPart", table.unpack(RigConvert.R6_LIMBS) }
	local isBody, bodyList = {}, {}
	for _, n in ipairs(bodyNames) do
		local p = src:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			isBody[p] = true
			table.insert(bodyList, p)
		elseif n ~= "HumanoidRootPart" then
			error(string.format("[rig_convert] %s (%s) has no body part %s", label, info.SourceRig, n))
		end
	end

	-- R6: normalise the source to the standard 2x2x1 torso first (it is scaled back afterwards for heroes)
	local refPart = src:FindFirstChild("HumanoidRootPart") or (if isR15 then src.LowerTorso else src.Torso)
	local frame = uprightYaw(refPart.CFrame)
	local scale = 1
	if not isR15 then
		scale = src.Torso.Size.X / 2
		if math.abs(scale - 1) > 1e-3 then
			RigConvert.ScaleRig(src, 1 / scale, frame)
			table.insert(notes, string.format("R6 source scale %.3f normalised to 1 for the conversion", scale))
		end
	end
	info.Scale = scale

	-- links in the SOURCE pose, then every non-body part's anchor + offset
	local adj = buildLinks(src)
	local ctx = { rootCf = frame, kind = {}, head = src.Head, headHeight = src.Head.Size.Y }
	if isR15 then
		for _, n in ipairs(RigConvert.R15_PARTS) do
			local limb = R15_TO_R6[n]
			ctx.kind[src[n]] = if limb == "Head" then "head" elseif limb == "Torso" then "torso"
				elseif string.find(limb, "Arm", 1, true) then "arm" else "leg"
		end
		local _, utTop = localAabb(src.UpperTorso, frame)
		local _, ltTop = localAabb(src.LowerTorso, frame)
		ctx.neckY = utTop.Y
		ctx.torsoFor = function(y)
			return if y > ltTop.Y then src.UpperTorso else src.LowerTorso
		end
	else
		ctx.kind[src.Head] = "head"
		ctx.kind[src.Torso] = "torso"
		ctx.kind[src["Left Arm"]], ctx.kind[src["Right Arm"]] = "arm", "arm"
		ctx.kind[src["Left Leg"]], ctx.kind[src["Right Leg"]] = "leg", "leg"
		local _, torsoTop = localAabb(src.Torso, frame)
		ctx.neckY = torsoTop.Y
		ctx.torsoFor = function()
			return src.Torso
		end
	end
	local accs = accoutrements(src)
	local accOf = {}
	for _, acc in ipairs(accs) do
		for _, d in ipairs(acc:GetDescendants()) do
			if d:IsA("BasePart") then
				accOf[d] = acc
			end
		end
	end
	local extras = {}
	for _, d in ipairs(src:GetDescendants()) do
		if d:IsA("BasePart") and not isBody[d] and not accOf[d] then
			local anchor, how = findAnchor(d, isBody, adj, bodyList, ctx)
			table.insert(extras, { part = d, anchor = anchor, how = how })
		end
	end
	-- loose parts of one sub-model (a sword, a holster, a hair model...) move as one: a single anchor chosen from
	-- the sub-model's combined bounds and names
	local groups, groupOrder = {}, {}
	for _, e in ipairs(extras) do
		local parent = e.part.Parent
		if string.sub(e.how, 1, 7) == "nearest" and parent ~= src and (parent:IsA("Model") or parent:IsA("Folder")) then
			if not groups[parent] then
				groups[parent] = {}
				table.insert(groupOrder, parent)
			end
			table.insert(groups[parent], e)
		end
	end
	for _, parent in ipairs(groupOrder) do
		local members = groups[parent]
		if #members > 1 then
			local mn, mx
			local names = string.lower(parent.Name)
			for _, e in ipairs(members) do
				local a, b = localAabb(e.part, frame)
				mn = if mn then mn:Min(a) else a
				mx = if mx then mx:Max(b) else b
				names ..= " " .. string.lower(e.part.Name)
			end
			local best = nearestBodyPart(frame * ((mn + mx) / 2), bodyList)
			local anchor = refineNearest(names, mn, mx, best, ctx)
			for _, e in ipairs(members) do
				e.anchor = anchor
				e.how = "group"
			end
		end
	end
	for _, e in ipairs(extras) do
		e.offset = e.anchor.CFrame:ToObjectSpace(e.part.CFrame)
	end
	local accRecords = {}
	for _, acc in ipairs(accs) do
		local handle = acc:FindFirstChild("Handle")
		if not (handle and handle:IsA("BasePart")) then
			table.insert(notes, "accessory " .. acc.Name .. " has no Handle: dropped")
			acc:Destroy()
			continue
		end
		local anchor, how = findAnchor(handle, isBody, adj, bodyList, ctx)
		local rec = { acc = acc, handle = handle, anchor = anchor, how = how, offset = anchor.CFrame:ToObjectSpace(handle.CFrame),
			subs = {} }
		for _, d in ipairs(acc:GetDescendants()) do
			if d:IsA("BasePart") and d ~= handle then
				table.insert(rec.subs, { part = d, offset = handle.CFrame:ToObjectSpace(d.CFrame) })
			end
		end
		-- attachment-consistent in the source? (then the standard attachment placement reproduces it)
		for _, a in ipairs(handle:GetChildren()) do
			if a:IsA("Attachment") then
				for _, b in ipairs(bodyList) do
					local ba = b:FindFirstChild(a.Name)
					if ba and ba:IsA("Attachment") then
						rec.attName = a.Name
						rec.handleAtt = a
						rec.consistent = cframesMatch(handle.CFrame, b.CFrame * ba.CFrame * a.CFrame:Inverse(), EPS_POS)
						break
					end
				end
				if rec.attName then
					break
				end
			end
		end
		table.insert(accRecords, rec)
	end

	-- source motors (fallback offsets), then every joint / weld / constraint goes: the rig is rebuilt from scratch
	local oldMotors = {}
	for _, d in ipairs(src:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 and isBody[d.Part1] then
			oldMotors[d.Name] = { C0 = d.C0, C1 = d.C1 }
		end
	end
	for _, d in ipairs(src:GetDescendants()) do
		if d.Parent ~= nil and (isLink(d) or d:IsA("NoCollisionConstraint")) then
			d:Destroy()
		end
	end

	local body
	local newFrame = {} -- source body part -> its CFrame in the converted rest pose (template space)
	local groupOf -- source body part -> list of converted parts its hangers may weld to
	if isR15 then
		body = src
		-- a missing HumanoidRootPart is rebuilt as the standard 2x2x1 root
		if not body:FindFirstChild("HumanoidRootPart") then
			local hrp = Instance.new("Part")
			hrp.Name = "HumanoidRootPart"
			hrp.Size = Vector3.new(2, 2, 1)
			hrp.CFrame = frame
			hrp.Transparency = 1
			hrp.Parent = body
			table.insert(notes, "no HumanoidRootPart: created a 2x2x1 root")
		end
		rebuildR15(body, CFrame.new(0, 0, 0), oldMotors, template, notes)
		local bodySet = { [body.HumanoidRootPart] = true }
		for _, n in ipairs(RigConvert.R15_PARTS) do
			bodySet[body[n]] = true
		end
		translateBody(body, bodySet, Vector3.new(0, -feetBottom(body), 0))
		for _, b in ipairs(bodyList) do
			newFrame[b] = b.CFrame
		end
		groupOf = function(b)
			if b.Name == "HumanoidRootPart" then
				return { body.UpperTorso, body.LowerTorso }
			end
			return { b }
		end
		-- BodyColors -> parts (what the runtime Humanoid applies)
		if bodyColors then
			for _, n in ipairs(RigConvert.R15_PARTS) do
				local limb = R15_TO_R6[n]
				if bc[limb] then
					body[n].Color = bc[limb]
				end
			end
		end
	else
		assert(template, "[rig_convert] R6 source " .. label .. " needs the R15 template")
		body = template:Clone()
		body.Name = label
		body.Parent = work
		for _, d in ipairs(body:GetDescendants()) do
			if d:IsA("Decal") or (d:IsA("BasePart") and d.Parent ~= body) then
				d:Destroy()
			end
		end
		local root = body.HumanoidRootPart.CFrame
		-- rest frames of the R6 limbs in template space (R6 and block R15 share the volume)
		local t = src.Torso.Size
		local function limbSize(n)
			return src[n].Size
		end
		local rest = {}
		rest.Torso = root
		rest.HumanoidRootPart = root
		local la, ra, ll, rl = limbSize("Left Arm"), limbSize("Right Arm"), limbSize("Left Leg"), limbSize("Right Leg")
		rest["Left Arm"] = root * CFrame.new(-(t.X / 2 + la.X / 2), t.Y / 2 - la.Y / 2, 0)
		rest["Right Arm"] = root * CFrame.new(t.X / 2 + ra.X / 2, t.Y / 2 - ra.Y / 2, 0)
		rest["Left Leg"] = root * CFrame.new(-t.X / 4, -(t.Y / 2 + ll.Y / 2), 0)
		rest["Right Leg"] = root * CFrame.new(t.X / 4, -(t.Y / 2 + rl.Y / 2), 0)

		-- the R6 head replaces the template's: its bottom centre on the UpperTorso neck
		local head = src.Head
		local templateHead = body.Head
		local ut = body.UpperTorso
		local utNeck = ut:FindFirstChild("NeckRigAttachment")
		local half = head.Size.Y / 2
		local headCf = ut.CFrame * utNeck.CFrame * CFrame.new(0, half, 0)
		rest.Head = headCf
		local ratio = head.Size / templateHead.Size
		for _, a in ipairs(templateHead:GetChildren()) do
			if a:IsA("Attachment") and not head:FindFirstChild(a.Name) then
				local copy = a:Clone()
				copy.CFrame = CFrame.new(a.CFrame.Position * ratio) * rotOnly(a.CFrame)
				copy.Parent = head
			end
		end
		local headNeck = head:FindFirstChild("NeckRigAttachment")
		headNeck.CFrame = CFrame.new(0, -half, 0)
		templateHead:Destroy()
		head.Parent = body
		head.CFrame = headCf
		newMotor("Neck", ut, head, utNeck.CFrame, headNeck.CFrame)
		for _, b in ipairs(bodyList) do
			newFrame[b] = rest[b.Name]
		end
		groupOf = function(b)
			local list = {}
			for _, n in ipairs(RigConvert.R6_GROUPS[b.Name]) do
				table.insert(list, body[n])
			end
			return list
		end

		-- appearance: BodyColors (else the limb's colour) + the limb's material / transparency / reflectance
		for limb, parts in pairs(RigConvert.R6_GROUPS) do
			local srcLimb = src:FindFirstChild(limb)
			if srcLimb and limb ~= "HumanoidRootPart" then
				local color = bc[limb] or srcLimb.Color
				for _, n in ipairs(parts) do
					local p = body[n]
					p.Color = color
					if limb ~= "Head" then
						p.Material = srcLimb.Material
						p.Transparency = srcLimb.Transparency
						p.Reflectance = srcLimb.Reflectance
					end
				end
				if limb ~= "Head" then
					for _, c in ipairs(srcLimb:GetChildren()) do
						if c:IsA("DataModelMesh") then
							table.insert(info.Lost, string.format("%s %s on %s", c.ClassName, c.Name, limb))
						end
					end
				end
			end
		end

		-- clothing + non-empty torso decals
		for _, c in ipairs(src:GetChildren()) do
			if c:IsA("Clothing") or c:IsA("ShirtGraphic") then
				c.Parent = body
			end
		end
		for _, c in ipairs(src.Torso:GetChildren()) do
			if c:IsA("Decal") then
				if textureUri(c) then
					c.Parent = body.UpperTorso
					table.insert(notes, "torso decal " .. c.Name .. " moved to UpperTorso")
				end
			end
		end

		-- extras and accessories leave the R6 limbs (Folder "Extras" keeps sub-models together)
		local extrasFolder = Instance.new("Folder")
		extrasFolder.Name = "Extras"
		extrasFolder.Parent = body
		local limbSet = {}
		for _, b in ipairs(bodyList) do
			limbSet[b] = true
		end
		local function moveOut(inst)
			if inst:IsA("Accoutrement") then
				inst.Parent = body
			elseif inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Folder") then
				inst.Parent = extrasFolder
			end
		end
		for _, c in ipairs(src:GetChildren()) do
			if not limbSet[c] and c ~= head then
				moveOut(c)
			end
		end
		for _, b in ipairs(bodyList) do
			for _, c in ipairs(b:GetChildren()) do
				if b ~= head then
					moveOut(c)
				elseif c:IsA("BasePart") or c:IsA("Model") or c:IsA("Folder") then
					moveOut(c) -- parts under the kept head also go to Extras (welded back to it below)
				end
			end
		end
		if #extrasFolder:GetChildren() == 0 then
			extrasFolder:Destroy()
		end
	end

	-- place + weld the extras (offset kept from their anchor's rest frame)
	for _, e in ipairs(extras) do
		local p = e.part
		p.CFrame = newFrame[e.anchor] * e.offset
		local group = groupOf(e.anchor)
		local target, bestD = group[1], math.huge
		if #group > 1 then
			for _, g in ipairs(group) do
				local d = distanceToPart(p.CFrame.Position, g)
				if d < bestD then
					target, bestD = g, d
				end
			end
		end
		newWeld(target, p, "HeroWeld")
		info.Extras += 1
	end

	-- accessories: standard attachment placement when the source used it, else their offset from the anchor
	local function ownerOf(attName)
		for _, n in ipairs({ "HumanoidRootPart", table.unpack(RigConvert.R15_PARTS) }) do
			local part = body:FindFirstChild(n)
			local a = part and part:FindFirstChild(attName)
			if a and a:IsA("Attachment") then
				return part, a
			end
		end
		return nil, nil
	end
	for _, rec in ipairs(accRecords) do
		local handle = rec.handle
		local ownerPart, ownerAtt = nil, nil
		if rec.attName then
			ownerPart, ownerAtt = ownerOf(rec.attName)
		end
		if rec.consistent and ownerPart then
			handle.CFrame = ownerPart.CFrame * ownerAtt.CFrame * rec.handleAtt.CFrame:Inverse()
			local w = Instance.new("Weld")
			w.Name = "AccessoryWeld"
			w.Part0 = handle
			w.Part1 = ownerPart
			w.C0 = rec.handleAtt.CFrame
			w.C1 = ownerAtt.CFrame
			w.Parent = handle
			info.AttachmentPlaced += 1
		else
			handle.CFrame = newFrame[rec.anchor] * rec.offset
			local target = ownerPart
			if not target then
				local group = groupOf(rec.anchor)
				local bestD = math.huge
				for _, g in ipairs(group) do
					local d = distanceToPart(handle.CFrame.Position, g)
					if d < bestD then
						target, bestD = g, d
					end
				end
			end
			newWeld(target, handle, "HeroWeld")
			info.OffsetPlaced += 1
			table.insert(notes, string.format("accessory %s kept its authored offset as plain welded parts (on %s%s)", rec.acc.Name,
				target.Name, if rec.attName then ", " .. rec.attName .. " not at the standard spot" else ", no matching attachment"))
		end
		for _, s in ipairs(rec.subs) do
			s.part.CFrame = handle.CFrame * s.offset
			newWeld(handle, s.part, "AccessorySubWeld")
		end
		if rec.consistent and ownerPart then
			if rec.acc.Parent ~= body then
				rec.acc.Parent = body
			end
			info.Accessories += 1
		else
			-- Not placed by attachments: kept as plain parts (Extras.<accessory name>) so no Humanoid ever re-welds it
			-- to an attachment spot the owner did not use.
			local extrasFolder = body:FindFirstChild("Extras")
			if not extrasFolder then
				extrasFolder = Instance.new("Folder")
				extrasFolder.Name = "Extras"
				extrasFolder.Parent = body
			end
			local holder = Instance.new("Folder")
			holder.Name = rec.acc.Name
			for _, c in ipairs(rec.acc:GetChildren()) do
				c.Parent = holder
			end
			rec.acc:Destroy()
			holder.Parent = extrasFolder
			info.Extras += 1 + #rec.subs
		end
	end

	if not isR15 then
		-- the R6 skeleton is gone: limbs (their meshes / decals were reported above), root, container
		for _, b in ipairs(bodyList) do
			if b.Name ~= "Head" then
				b:Destroy()
			end
		end
		src:Destroy()
	end

	-- names reserved for body parts stay unique (the guards need exactly one "Head"; A10 limb names)
	local finalBody = { [body.HumanoidRootPart] = true }
	for _, n in ipairs(RigConvert.R15_PARTS) do
		finalBody[body[n]] = true
	end
	for _, d in ipairs(body:GetDescendants()) do
		if d:IsA("BasePart") and RESERVED[d.Name] and not finalBody[d] then
			table.insert(notes, "renamed extra part " .. d:GetFullName() .. " -> " .. d.Name .. "Detail")
			d.Name = d.Name .. "Detail"
		end
	end
	local hrp = body.HumanoidRootPart
	for _, d in ipairs(body:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = d ~= hrp
		end
	end
	hrp.Transparency = 1
	body.PrimaryPart = hrp

	-- size: heroes keep the source's natural scale; villains get exact standard legs
	local hip = hrp.CFrame.Position.Y - hrp.Size.Y / 2
	if not isR15 and opts.HipHeight == nil and opts.KeepNaturalScale ~= false and math.abs(scale - 1) > 1e-3 then
		RigConvert.ScaleRig(body, scale, CFrame.new())
		table.insert(notes, string.format("scaled back to the source's natural x%.3f", scale))
		hip = hrp.CFrame.Position.Y - hrp.Size.Y / 2
	end
	if opts.HipHeight then
		-- The body keeps its authored size (RigScale 1 = the owner's model); only the invisible HumanoidRootPart is
		-- re-seated: 2x2x1 with its bottom exactly HipHeight above the feet (the guard contract: HipHeight = 2 x
		-- RigScale). The Root joint and everything jointed to the root keep their world positions.
		if math.abs(hip - opts.HipHeight) > 1e-3 then
			table.insert(notes, string.format("HumanoidRootPart re-seated: authored hip height %.2f -> %.2f", hip, opts.HipHeight))
		end
		local target = CFrame.new(0, opts.HipHeight + 1, 0)
		local delta = hrp.CFrame:ToObjectSpace(target)
		local inv = delta:Inverse()
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.CFrame = target
		for _, a in ipairs(hrp:GetChildren()) do
			if a:IsA("Attachment") then
				a.CFrame = inv * a.CFrame
			end
		end
		for _, d in ipairs(body:GetDescendants()) do
			if d:IsA("JointInstance") then
				if d.Part0 == hrp then
					d.C0 = inv * d.C0
				end
				if d.Part1 == hrp then
					d.C1 = inv * d.C1
				end
			end
		end
		hip = opts.HipHeight
	end
	info.HipHeight = hip
	-- the geometry already has its final size: Model.Scale (ScaleFactor) metadata 1, pivot on the root
	pcall(function()
		(body :: any).Scale = 1
	end)
	pcall(function()
		(body :: any).WorldPivotData = hrp.CFrame
	end)
	RigConvert.SyncWeldConstraints(body)
	body.Parent = nil
	work:Destroy()
	return body, notes, info
end

--------------------------------------------------------------------------------------------------
-- checks
--------------------------------------------------------------------------------------------------

-- Joint integrity under `root`: refs internal, joints solved, every BasePart reachable from `rootPart`.
-- Returns the BasePart count; appends "label: problem" strings to errs.
function RigConvert.CheckJoints(root, rootPart, errs, label)
	local function E(s)
		table.insert(errs, label .. ": " .. s)
	end
	local adj = {}
	local function link(a, b)
		adj[a] = adj[a] or {}
		adj[b] = adj[b] or {}
		table.insert(adj[a], b)
		table.insert(adj[b], a)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			local p0, p1 = d.Part0, d.Part1
			if p0 == nil or p1 == nil then
				E("joint with nil Part0/Part1: " .. d:GetFullName())
			elseif not p0:IsDescendantOf(root) or not p1:IsDescendantOf(root) then
				E("joint points outside the model: " .. d:GetFullName())
			else
				link(p0, p1)
				if d:IsA("JointInstance") then
					if not cframesMatch(p0.CFrame * d.C0, p1.CFrame * d.C1, 0.02) then
						E("joint not solved (Part0*C0 ~= Part1*C1): " .. d:GetFullName())
					end
				else
					local ok, c0 = pcall(function()
						return (d :: any).CFrame0
					end)
					if not ok or not cframesMatch(p0.CFrame * c0, p1.CFrame, 0.02) then
						E("WeldConstraint CFrame0 stale: " .. d:GetFullName())
					end
				end
			end
		end
	end
	local seen, queue = { [rootPart] = true }, { rootPart }
	while #queue > 0 do
		local n = table.remove(queue)
		for _, o in ipairs(adj[n] or {}) do
			if not seen[o] then
				seen[o] = true
				table.insert(queue, o)
			end
		end
	end
	local count = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			count += 1
			if not seen[d] then
				E("BasePart not jointed to the root: " .. d:GetFullName())
			end
		end
	end
	return count
end

return RigConvert
