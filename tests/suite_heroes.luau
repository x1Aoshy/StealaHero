--!nocheck
-- Heroes (docs/STAGES_PLAN.md §2, A1, A11 + docs/VISUAL_PASS_PLAN.md D1, D4, D5 + docs/HERO_MODELS_PLAN.md H1/H2): the 38
-- game-plan heroes as R15 AssetModels (runtime contract C1) built from the OWNER'S models (assets/hero_models/*.rbxm,
-- converted to R15 where they are R6), their template rigs, configs (plan rarity, EarningRate = base x stage factor,
-- GrowthTime, drop weight, R15 animations) and eggs; the 6 villains built from the owner's models; the D1 purge (only the
-- 38 heroes exist: no legacy animal / brainrot asset, no legacy Speedsters hero, old saves migrated); the 6 stage
-- DropTables exactly per §2 (retired area configs removed); the generated HeroCatalog; and the 10 Speedsters treadmill
-- skins (no video screen, D4). No procedural / "authentic" look is left: every body is the owner's model, every
-- accessory sits on its R15 attachment, the default R15 animations drive the standard joints.

local place = H.place()
local rs = place.ReplicatedStorage
local PLAN = H.PLAN
local Enum = H.roblox.Enum
local Vector3 = H.roblox.Vector3

local R15_PARTS = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm",
	"RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
-- { Motor6D, Part0, Part1, rig attachment }: the standard R15 joints, each parented to its Part1, C0/C1 = the rig
-- attachments (Humanoid:BuildRigFromAttachments) so the default Roblox R15 animations pose them correctly
local R15_MOTORS = {
	{ "Root", "HumanoidRootPart", "LowerTorso", "RootRigAttachment" }, { "Waist", "LowerTorso", "UpperTorso", "WaistRigAttachment" },
	{ "Neck", "UpperTorso", "Head", "NeckRigAttachment" },
	{ "LeftShoulder", "UpperTorso", "LeftUpperArm", "LeftShoulderRigAttachment" }, { "LeftElbow", "LeftUpperArm", "LeftLowerArm", "LeftElbowRigAttachment" },
	{ "LeftWrist", "LeftLowerArm", "LeftHand", "LeftWristRigAttachment" },
	{ "RightShoulder", "UpperTorso", "RightUpperArm", "RightShoulderRigAttachment" }, { "RightElbow", "RightUpperArm", "RightLowerArm", "RightElbowRigAttachment" },
	{ "RightWrist", "RightLowerArm", "RightHand", "RightWristRigAttachment" },
	{ "LeftHip", "LowerTorso", "LeftUpperLeg", "LeftHipRigAttachment" }, { "LeftKnee", "LeftUpperLeg", "LeftLowerLeg", "LeftKneeRigAttachment" },
	{ "LeftAnkle", "LeftLowerLeg", "LeftFoot", "LeftAnkleRigAttachment" },
	{ "RightHip", "LowerTorso", "RightUpperLeg", "RightHipRigAttachment" }, { "RightKnee", "RightUpperLeg", "RightLowerLeg", "RightKneeRigAttachment" },
	{ "RightAnkle", "RightLowerLeg", "RightFoot", "RightAnkleRigAttachment" },
}
local FORBIDDEN = { "LuaSourceContainer", "Sound", "Highlight", "Tool", "KeyframeSequence", "SurfaceAppearance", "ParticleEmitter",
	"CharacterMesh", "BodyColors", "Constraint" }
local CHICKEN_ICON = "87733160598688"
local IDLE, WALK = tostring(PLAN.R15_ANIMATIONS.idle), tostring(PLAN.R15_ANIMATIONS.walk)

local assetModels = rs:FindFirstChild("AssetModels")
local configs = H.path(rs, "Directory/Assets/_Index")
local rarityIndex = H.path(rs, "Directory/Rarity/_Index")
local eggs = H.path(rs, "Assets/Models/Eggs")
local templateRigs = H.path(rs, "Assets/Models/Heroes")
T.check(assetModels ~= nil, "ReplicatedStorage.AssetModels missing")
T.check(configs ~= nil, "ReplicatedStorage.Directory.Assets._Index missing")

---------------------------------------------------------------------------------------------------
-- 0. the owner's models on disk (assets/hero_models, extracted once from the read-only snapshot)
---------------------------------------------------------------------------------------------------
local function loadModels(path)
	local ok, list = pcall(function()
		return H.roblox.deserializeModel(H.fs.readFile(path))
	end)
	if not T.check(ok and type(list) == "table", "%s missing or unreadable (run scripts/tools/extract_hero_models.luau)", path) then
		return {}
	end
	local byName = {}
	for _, m in ipairs(list) do
		T.check(byName[m.Name] == nil, "%s holds two models named %s", path, m.Name)
		byName[m.Name] = m
	end
	return byName, list
end
local heroSources, heroSourceList = loadModels(PLAN.MODEL_FILES.heroes)
local villainSources, villainSourceList = loadModels(PLAN.MODEL_FILES.villains)
local extraSources, extraSourceList = loadModels(PLAN.MODEL_FILES.extras)
local _, templateList = loadModels(PLAN.MODEL_FILES.template)
T.check(#(heroSourceList or {}) == #PLAN.HEROES, "%s must hold one model per roster hero (%d), holds %d", PLAN.MODEL_FILES.heroes,
	#PLAN.HEROES, #(heroSourceList or {}))
for _, row in ipairs(PLAN.HEROES) do
	local id = row[1]
	local m = heroSources[id]
	local want = PLAN.HERO_SOURCES[id]
	if T.check(m ~= nil, "%s has no model %s", PLAN.MODEL_FILES.heroes, id) then
		T.check(m:GetAttribute("SourceName") == want[1] and m:GetAttribute("SourceRig") == want[2],
			"%s.%s must be the owner's %q (%s) per the mapping, is %q (%s)", PLAN.MODEL_FILES.heroes, id, want[1], want[2],
			tostring(m:GetAttribute("SourceName")), tostring(m:GetAttribute("SourceRig")))
		T.check(H.countClass(m, "LuaSourceContainer") == 0 and H.countClass(m, "Sound") == 0, "%s.%s must carry no code / audio",
			PLAN.MODEL_FILES.heroes, id)
	end
end
local villainIds = {}
for _, stage in ipairs(PLAN.STAGES) do
	villainIds[stage.villain] = true
	local m = villainSources[stage.villain]
	local want = PLAN.VILLAIN_SOURCES[stage.villain]
	if T.check(m ~= nil, "%s has no model %s", PLAN.MODEL_FILES.villains, stage.villain) then
		T.check(m:GetAttribute("SourceName") == want[1] and m:GetAttribute("SourceRig") == want[2],
			"%s.%s must be the owner's %q (%s), is %q", PLAN.MODEL_FILES.villains, stage.villain, want[1], want[2], tostring(m:GetAttribute("SourceName")))
	end
end
T.check(#(villainSourceList or {}) == #PLAN.STAGES, "%s must hold exactly the %d villains", PLAN.MODEL_FILES.villains, #PLAN.STAGES)
for _, id in ipairs(PLAN.EXTRA_MODELS) do
	T.check(extraSources[id] ~= nil, "%s must keep the extra model %s for later", PLAN.MODEL_FILES.extras, id)
end
for _, m in ipairs(extraSourceList or {}) do
	for _, sonic in ipairs(PLAN.SONIC_FAMILY) do
		T.check(m.Name ~= sonic and m:GetAttribute("SourceName") ~= sonic, "the Sonic family is excluded, but %s holds %s", PLAN.MODEL_FILES.extras, m.Name)
	end
end
T.check(#(templateList or {}) == 1 and templateList[1]:FindFirstChild("UpperTorso") ~= nil,
	"%s must hold the one default block R15 body the R6 heroes are converted onto", PLAN.MODEL_FILES.template)

---------------------------------------------------------------------------------------------------
-- rig helpers
---------------------------------------------------------------------------------------------------
local function near(a, b, eps)
	return (a.Position - b.Position).Magnitude <= (eps or 0.02) and a.LookVector:Dot(b.LookVector) >= 0.9995 and a.UpVector:Dot(b.UpVector) >= 0.9995
end

-- Shirt / Pants / ShirtGraphic template ids of a model's direct children, sorted ("S123", "P456", "G789")
local function clothingOf(model)
	local list = {}
	for _, c in ipairs(model:GetChildren()) do
		local tag, value = nil, nil
		if c:IsA("Shirt") then
			tag, value = "S", c.ShirtTemplate
		elseif c:IsA("Pants") then
			tag, value = "P", c.PantsTemplate
		elseif c:IsA("ShirtGraphic") then
			local ok, g = pcall(function()
				return c.Graphic
			end)
			if not ok or type(g) ~= "string" then
				g = H.uri(c, "GraphicContent")
			end
			tag, value = "G", g
		end
		if tag then
			table.insert(list, tag .. tostring(string.match(tostring(value or ""), "(%d+)") or value))
		end
	end
	table.sort(list)
	return list
end

-- The 15 standard Motor6Ds wired to the right parts with C0/C1 = the rig attachments; returns the problems.
local function checkMotors(body, root)
	local bad = {}
	for _, spec in ipairs(R15_MOTORS) do
		local part1 = body:FindFirstChild(spec[3])
		local motor = part1 and part1:FindFirstChild(spec[1])
		local part0 = motor and motor:IsA("Motor6D") and motor.Part0
		local ok = part0 ~= nil and motor.Part1 == part1 and part0.Name == spec[2] and (spec[1] ~= "Root" or part0 == root)
		if ok then
			local a0, a1 = part0:FindFirstChild(spec[4]), part1:FindFirstChild(spec[4])
			ok = a0 ~= nil and a1 ~= nil and near(motor.C0, a0.CFrame, 0.01) and near(motor.C1, a1.CFrame, 0.01)
				and near(part0.CFrame * motor.C0, part1.CFrame * motor.C1)
		end
		if not ok then
			table.insert(bad, spec[1])
		end
	end
	return bad
end

-- Every BasePart reachable from `root` through joints, every joint solved.
local function checkJointed(model, root)
	local adj, unsolved = {}, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			local p0, p1 = d.Part0, d.Part1
			if p0 and p1 then
				adj[p0] = adj[p0] or {}
				adj[p1] = adj[p1] or {}
				table.insert(adj[p0], p1)
				table.insert(adj[p1], p0)
				if d:IsA("JointInstance") and not near(p0.CFrame * d.C0, p1.CFrame * d.C1) then
					table.insert(unsolved, d:GetFullName())
				end
			end
		end
	end
	local seen, queue = { [root] = true }, { root }
	while #queue > 0 do
		local n = table.remove(queue)
		for _, o in ipairs(adj[n] or {}) do
			if not seen[o] then
				seen[o] = true
				table.insert(queue, o)
			end
		end
	end
	local loose = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not seen[d] then
			table.insert(loose, d:GetFullName())
		end
	end
	return loose, unsolved
end

-- The owner's look carried over: clothing, every source accessory (on its R15 attachment, or kept as plain welded
-- parts under Extras when the owner had placed it elsewhere), no procedural leftovers.
local function checkOwnerLook(label, body, source)
	local props = {}
	for _, d in ipairs(body:GetDescendants()) do
		if d:GetAttribute("PropOf") ~= nil or (d.Name == "Props" and d:IsA("Folder")) then
			table.insert(props, d:GetFullName())
		end
	end
	T.check(#props == 0, "%s: procedural look leftovers (part-built props) %s", label, table.concat(props, ", ", 1, math.min(#props, 3)))
	if source then
		local want, got = table.concat(clothingOf(source), ","), table.concat(clothingOf(body), ",")
		T.check(want == got, "%s: clothing must be the owner's (%s), found (%s)", label, want, got)
		local accessories = {}
		for _, d in ipairs(source:GetDescendants()) do
			if d:IsA("Accoutrement") then
				accessories[d.Name] = (accessories[d.Name] or 0) + 1
			end
		end
		local extras = body:FindFirstChild("Extras")
		for name, count in pairs(accessories) do
			local have = 0
			for _, c in ipairs(body:GetChildren()) do
				if c:IsA("Accoutrement") and c.Name == name then
					have += 1
				end
			end
			for _, c in ipairs(extras and extras:GetChildren() or {}) do
				if c.Name == name and c:IsA("Folder") then
					have += 1
				end
			end
			T.check(have == count, "%s: the owner's accessory %q x%d must carry over, found %d", label, name, count, have)
		end
	end
	for _, acc in ipairs(body:GetChildren()) do
		if acc:IsA("Accoutrement") then
			local handle = acc:FindFirstChild("Handle")
			local weld = handle and handle:FindFirstChild("AccessoryWeld")
			local ok = weld ~= nil and weld:IsA("Weld") and weld.Part0 == handle and weld.Part1 ~= nil and weld.Part1.Parent == body
			if ok then
				ok = false
				for _, a in ipairs(handle:GetChildren()) do
					local ba = a:IsA("Attachment") and weld.Part1:FindFirstChild(a.Name)
					if ba and ba:IsA("Attachment") and near(weld.C0, a.CFrame, 0.01) and near(weld.C1, ba.CFrame, 0.01) then
						ok = true
					end
				end
			end
			T.check(ok, "%s: accessory %s must be AccessoryWeld'ed to the R15 part owning its attachment", label, acc.Name)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- AssetModel contract C1 (what ItemDisplay / AssetInvertedModelPresentation / AssetComponent rely on)
---------------------------------------------------------------------------------------------------
local function checkAssetModel(id, model)
	T.check(model:IsA("Model"), "%s: AssetModel must be a Model", id)
	T.check(model:GetAttribute("HeroId") == id and model:GetAttribute("RigType") == "R15", "%s: attributes HeroId=%s / RigType=R15 missing", id, id)
	local want = PLAN.HERO_SOURCES[id]
	T.check(model:GetAttribute("SourceFile") == PLAN.MODEL_FILES.heroes and model:GetAttribute("SourceModel") == want[1]
		and model:GetAttribute("SourceRig") == want[2] and model:GetAttribute("ConvertedFromR6") == (want[2] == "R6"),
		"%s: must be built from %s (%q, %s), attributes say %s / %q / %s", id, PLAN.MODEL_FILES.heroes, want[1], want[2],
		tostring(model:GetAttribute("SourceFile")), tostring(model:GetAttribute("SourceModel")), tostring(model:GetAttribute("SourceRig")))
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not T.check(hrp ~= nil and hrp:IsA("BasePart") and model.PrimaryPart == hrp, "%s: PrimaryPart must be the outer HumanoidRootPart", id) then
		return
	end
	T.check((hrp.Size - Vector3.new(2, 2, 1)).Magnitude < 1e-3 and hrp.Transparency >= 1 and hrp.Massless and not hrp.CanCollide and not hrp.CanTouch and not hrp.CanQuery,
		"%s: outer HumanoidRootPart must be 2x2x1, invisible, massless, non-colliding/touching/querying", id)
	local inner = model:FindFirstChild("Model")
	if not T.check(inner ~= nil and inner:IsA("Model"), "%s: inner Model missing", id) then
		return
	end
	local innerRoot = inner:FindFirstChild("HumanoidRootPart")
	T.check(innerRoot ~= nil and inner.PrimaryPart == innerRoot, "%s: inner Model.PrimaryPart must be its HumanoidRootPart", id)
	local weld = hrp:FindFirstChild("AssetWeld")
	T.check(weld ~= nil and weld.ClassName == "WeldConstraint" and weld.Part0 == hrp and weld.Part1 == innerRoot,
		"%s: AssetWeld must be a WeldConstraint outer HumanoidRootPart -> Model.HumanoidRootPart (runtime asserts the class)", id)
	local center = model:FindFirstChild("CENTER")
	local centerWeld = center and center:FindFirstChild("CenterWeld")
	T.check(center ~= nil and center:IsA("BasePart") and center.Transparency >= 1 and center.Massless and not center.CanCollide,
		"%s: CENTER must be an invisible, massless, non-colliding part", id)
	T.check(centerWeld ~= nil and centerWeld.ClassName == "WeldConstraint" and centerWeld.Part0 == hrp and centerWeld.Part1 == center,
		"%s: CENTER.CenterWeld must be a WeldConstraint outer HumanoidRootPart -> CENTER", id)
	local anim = inner:FindFirstChildOfClass("AnimationController")
	T.check(anim ~= nil and anim:FindFirstChildOfClass("Animator") ~= nil, "%s: inner AnimationController > Animator missing (AssetComponent plays Idle/Walk on it)", id)

	local missing = {}
	for _, part in ipairs(R15_PARTS) do
		local p = inner:FindFirstChild(part)
		if not (p and p:IsA("BasePart")) then
			table.insert(missing, part)
		end
	end
	T.check(#missing == 0, "%s: missing R15 parts %s", id, table.concat(missing, ", "))
	for _, n in ipairs({ "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
		T.check(inner:FindFirstChild(n) == nil, "%s: R6 limb %s left over after the R15 conversion", id, n)
	end
	local badMotors = checkMotors(inner, innerRoot)
	T.check(#badMotors == 0, "%s: standard R15 Motor6Ds missing, miswired or not built from the rig attachments: %s", id, table.concat(badMotors, ", "))
	T.check(H.countClass(inner, "Motor6D") == #R15_MOTORS, "%s: exactly the %d standard Motor6Ds expected (extras are welded), found %d", id,
		#R15_MOTORS, H.countClass(inner, "Motor6D"))
	local bad = H.badJoints(model)
	T.check(#bad == 0, "%s: %d broken joints (%s)", id, #bad, bad[1] or "")
	local loose, unsolved = checkJointed(model, hrp)
	T.check(#loose == 0, "%s: %d part(s) not welded to the rig (%s)", id, #loose, loose[1] or "")
	T.check(#unsolved == 0, "%s: %d joint(s) not solved (%s)", id, #unsolved, unsolved[1] or "")
	for _, className in ipairs(FORBIDDEN) do
		T.check(H.countClass(model, className) == 0, "%s: must not contain %s", id, className)
	end

	local minY, maxY, headTop = math.huge, -math.huge, -math.huge
	local physical, unprotected = {}, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Anchored or d.CanCollide then
				table.insert(physical, d.Name)
			end
			if d.Name == "Segment1" then
				T.check(false, "%s: part named Segment1 (ItemDisplay would make it the PrimaryPart)", id)
			end
			if d:IsDescendantOf(inner) and d ~= innerRoot and d:GetAttribute("DontModify") ~= true then
				table.insert(unprotected, d.Name)
			end
			if d.Transparency < 1 and d:IsDescendantOf(inner) then
				local mn, mx = H.aabb(d)
				minY, maxY = math.min(minY, mn.Y), math.max(maxY, mx.Y)
				if d.Name == "Head" then
					headTop = mx.Y
				end
			end
		end
	end
	T.check(#physical == 0, "%s: all parts must be Anchored=false, CanCollide=false (%s)", id, table.concat(physical, ", ", 1, math.min(#physical, 3)))
	T.check(#unprotected == 0, "%s: every body part keeps the owner's colours (DontModify), unprotected: %s", id,
		table.concat(unprotected, ", ", 1, math.min(#unprotected, 3)))
	T.check(maxY - minY >= PLAN.HERO_HEIGHT.min and maxY - minY <= PLAN.HERO_HEIGHT.max, "%s: visible height %.2f outside %d..%d studs", id,
		maxY - minY, PLAN.HERO_HEIGHT.min, PLAN.HERO_HEIGHT.max)
	if center then
		T.check(center.CFrame.Position.Y > headTop, "%s: CENTER (billboard anchor) must sit above the head", id)
	end

	-- classic clothing renders only on a Humanoid model: Shirt/Pants/ShirtGraphic need the render-only clothing Humanoid
	local clothed = #clothingOf(inner) > 0
	local humanoids = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Humanoid") then
			table.insert(humanoids, d)
		end
	end
	T.check(#humanoids <= 1, "%s: more than one Humanoid", id)
	if #humanoids == 1 then
		local h = humanoids[1]
		T.check(h.Parent == inner and h.EvaluateStateMachine == false and h:FindFirstChildOfClass("Animator") == nil and clothed
			and h.RigType == Enum.HumanoidRigType.R15,
			"%s: a Humanoid is only allowed as the render-only R15 clothing Humanoid (inner Model, no state machine, no Animator)", id)
	end
	if clothed then
		T.check(#humanoids == 1, "%s: Shirt/Pants/ShirtGraphic without a Humanoid never render", id)
	end
	checkOwnerLook(id, inner, heroSources[id])
end

-- Look fingerprint: clothing + accessories + body colours (two heroes must never be the same model).
local function fingerprint(model)
	local inner = model:FindFirstChild("Model")
	local parts = {}
	for _, name in ipairs(R15_PARTS) do
		local p = inner and inner:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			local c = p.Color
			table.insert(parts, string.format("%d,%d,%d", c.R * 255, c.G * 255, c.B * 255))
		end
	end
	local extras = {}
	for _, d in ipairs(inner and inner:GetDescendants() or {}) do
		if d:IsA("Accoutrement") or (d:IsA("BasePart") and d.Parent ~= inner) then
			table.insert(extras, d.Name)
		end
	end
	table.sort(extras)
	return table.concat(parts, ";") .. "|" .. table.concat(extras, ";") .. "|" .. table.concat(inner and clothingOf(inner) or {}, ";")
end


---------------------------------------------------------------------------------------------------
-- Config modules (Directory.Assets._Index.<HeroId>)
---------------------------------------------------------------------------------------------------
local function num(src, pattern)
	return tonumber(string.match(src, pattern))
end

local function checkConfig(id, hero)
	local config = configs and configs:FindFirstChild(id)
	if not T.check(config ~= nil and config:IsA("ModuleScript"), "config Directory.Assets._Index.%s missing", id) then
		return
	end
	local src = config.Source
	T.check(pcall(H.luau.compile, src), "%s config does not compile", id)
	T.check(H.has(src, IDLE) and H.has(src, WALK), "%s config must use the R15 idle/walk animations (%s/%s)", id, IDLE, WALK)
	local icon = string.match(src, 'Icon%s*=%s*"([^"]+)"')
	T.check(icon ~= nil and icon ~= "" and not H.has(icon, CHICKEN_ICON), "%s: hero icon must be set and not the Chicken (%s)", id, tostring(icon))
	local rarity = string.match(src, "Rarity%s*=%s*Rarity%.Rarities%.(%w+)")
	T.check(rarity ~= nil and rarityIndex ~= nil and rarityIndex:FindFirstChild(rarity) ~= nil,
		"%s: config rarity %s must exist in Directory.Rarity (Rarities is a strict table)", id, tostring(rarity))
	local dontRoll = string.find(src, "\n%s*DontRoll%s*=%s*true") ~= nil
	if legacy then
		T.check(dontRoll, "legacy hero %s must be DontRoll = true (A11)", id)
		return
	end
	T.check(not dontRoll, "%s is a game-plan hero and must roll (no DontRoll)", id)
	T.check(string.match(src, 'DisplayName%s*=%s*"([^"]*)"') == hero.displayName, "%s: DisplayName must be %q (§2)", id, hero.displayName)
	T.check(rarity == hero.rarity, "%s: rarity must be %s (§2), found %s", id, hero.rarity, tostring(rarity))
	local rate = num(src, "\n%s*EarningRate%s*=%s*([%d%.]+)")
	T.check(rate ~= nil and math.abs(rate - hero.earningRate) < 1e-6, "%s: EarningRate must be %d (%s %d x stage %d factor), found %s", id,
		hero.earningRate, hero.rarity, PLAN.BASE_INCOME[hero.rarity], hero.stage, tostring(rate))
	local growth = num(src, "GrowthTime%s*=%s*([%d%.]+)")
	T.check(growth ~= nil and math.abs(growth - hero.growthTime) < 1e-6, "%s: egg GrowthTime must be %d (%s), found %s", id, hero.growthTime, hero.rarity, tostring(growth))
	local weight = num(src, "\n%s*DropWeight%s*=%s*([%d%.]+)")
	T.check(weight ~= nil and math.abs(weight - hero.dropWeight) < 1e-6, "%s: DropWeight must be %s (§2), found %s", id, tostring(hero.dropWeight), tostring(weight))
	local eggName = string.match(src, "Egg%s*=%s*{.-DisplayName%s*=%s*\"([^\"]*)\"")
	T.check(eggName ~= nil and H.has(eggName, hero.displayName), "%s: egg name %s must name the hero", id, tostring(eggName))
end

---------------------------------------------------------------------------------------------------
-- 1. the 38 roster heroes (AssetModels, configs, eggs) + their template rigs (Assets.Models.Heroes)
---------------------------------------------------------------------------------------------------
local prints = {}
for _, hero in ipairs(PLAN.HEROES) do
	local id = hero[1]
	local info = PLAN.HERO_BY_ID[id]
	local model = assetModels and assetModels:FindFirstChild(id)
	if T.check(model ~= nil, "AssetModels.%s missing", id) then
		checkAssetModel(id, model)
		local fp = fingerprint(model)
		T.check(prints[fp] == nil, "%s looks identical to %s (same clothing, accessories and colours)", id, tostring(prints[fp]))
		prints[fp] = id
	end
	checkConfig(id, info)
	local egg = eggs and eggs:FindFirstChild(id)
	T.check(egg ~= nil and egg:IsA("Model") and egg.PrimaryPart ~= nil and egg:GetAttribute("HeroId") == id,
		"egg model Assets.Models.Eggs.%s missing (Model with PrimaryPart and HeroId)", id)
end
-- template rigs: exactly the roster, each a plain R15 character of the owner's model
if T.check(templateRigs ~= nil, "ReplicatedStorage.Assets.Models.Heroes missing") then
	local names = {}
	for _, c in ipairs(templateRigs:GetChildren()) do
		names[c.Name] = true
		T.check(PLAN.HERO_BY_ID[c.Name] ~= nil, "Assets.Models.Heroes.%s is not a game-plan hero", c.Name)
	end
	for _, hero in ipairs(PLAN.HEROES) do
		local id = hero[1]
		local rig = templateRigs:FindFirstChild(id)
		if T.check(names[id] == true and rig ~= nil and rig:IsA("Model"), "Assets.Models.Heroes.%s (template rig) missing", id) then
			local label = "Assets.Models.Heroes." .. id
			local root = rig:FindFirstChild("HumanoidRootPart")
			local humanoid = rig:FindFirstChildOfClass("Humanoid")
			T.check(rig:GetAttribute("HeroId") == id and rig:GetAttribute("RigType") == "R15" and rig:GetAttribute("SourceFile") == PLAN.MODEL_FILES.heroes,
				"%s: attributes HeroId / RigType=R15 / SourceFile missing", label)
			T.check(root ~= nil and rig.PrimaryPart == root, "%s: PrimaryPart must be the HumanoidRootPart", label)
			T.check(humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R15, "%s: needs an R15 Humanoid (it dresses the classic clothing)", label)
			if root then
				local badMotors = checkMotors(rig, root)
				T.check(#badMotors == 0, "%s: standard R15 Motor6Ds missing or miswired: %s", label, table.concat(badMotors, ", "))
				local loose = checkJointed(rig, root)
				T.check(#loose == 0, "%s: %d part(s) not welded to the rig (%s)", label, #loose, loose[1] or "")
			end
			for _, className in ipairs(FORBIDDEN) do
				T.check(H.countClass(rig, className) == 0, "%s: must not contain %s", label, className)
			end
			checkOwnerLook(label, rig, heroSources[id])
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 1b. the 6 villains are the owner's models too (the guard contract itself is checked in suite_world)
---------------------------------------------------------------------------------------------------
local guardAreas = H.path(place.Workspace, "__OBJECTS/Areas/GuardAreas")
for _, stage in ipairs(PLAN.STAGES) do
	local guard = guardAreas and H.path(guardAreas, stage.key .. "/Guard")
	local label = stage.key .. ".Guard (" .. stage.villain .. ")"
	if T.check(guard ~= nil, "%s missing", label) then
		local want = PLAN.VILLAIN_SOURCES[stage.villain]
		T.check(guard:GetAttribute("SourceFile") == PLAN.MODEL_FILES.villains and guard:GetAttribute("SourceModel") == want[1]
			and guard:GetAttribute("SourceRig") == want[2],
			"%s: must be built from %s (%q, %s), attributes say %s / %q", label, PLAN.MODEL_FILES.villains, want[1], want[2],
			tostring(guard:GetAttribute("SourceFile")), tostring(guard:GetAttribute("SourceModel")))
		-- owner 2026-09-23: the body is flattened into the guard (one Humanoid moves, animates and dresses it)
		local body = guard
		local root = guard:FindFirstChild("HumanoidRootPart")
		T.check(guard:FindFirstChild("Model") == nil, "%s: the body must be flattened into the guard (no nested Guard.Model)", label)
		local humanoids = 0
		for _, d in ipairs(guard:GetDescendants()) do
			if d:IsA("Humanoid") then
				humanoids += 1
			end
		end
		T.check(humanoids == 1, "%s: exactly one Humanoid (the driving one) expected, found %d", label, humanoids)
		if T.check(root ~= nil, "%s: HumanoidRootPart missing", label) then
			local badMotors = checkMotors(body, root)
			T.check(#badMotors == 0, "%s: standard R15 Motor6Ds missing or miswired (the default R15 run / idle drive them): %s", label,
				table.concat(badMotors, ", "))
			T.check(H.countClass(body, "Motor6D") == #R15_MOTORS, "%s: exactly the %d standard Motor6Ds expected, found %d", label, #R15_MOTORS,
				H.countClass(body, "Motor6D"))
			local loose, unsolved = checkJointed(guard, root)
			T.check(#loose == 0, "%s: %d part(s) not welded to the rig (%s)", label, #loose, loose[1] or "")
			T.check(#unsolved == 0, "%s: %d joint(s) not solved (%s)", label, #unsolved, unsolved[1] or "")
			checkOwnerLook(label, body, villainSources[stage.villain])
			local heads = 0
			for _, d in ipairs(guard:GetDescendants()) do
				if d:IsA("BasePart") and d.Name == "Head" then
					heads += 1
				end
			end
			T.check(heads == 1, "%s: exactly one part named Head (GuardComponent finds the AlertGui through it), found %d", label, heads)
			local humanoid = guard:FindFirstChildOfClass("Humanoid")
			T.check(humanoid ~= nil and humanoid:FindFirstChildOfClass("Animator") ~= nil and H.countClass(guard, "AnimationController") == 0,
				"%s: GuardChaseService animates through Guard.Humanoid.Animator (no AnimationController allowed)", label)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 2. D1 purge: only the 38 plan heroes exist; every legacy animal/brainrot asset and the 10 legacy Speedsters
--    heroes are gone (configs, models, eggs, drops, limited/admin eggs, mutations), and old saves are migrated
---------------------------------------------------------------------------------------------------
local roster = {}
for _, row in ipairs(PLAN.HEROES) do
	roster[row[1]] = true
end
for _, folderPath in ipairs({ "Directory/Assets/_Index", "AssetModels", "Assets/Models/Eggs", "Assets/Models/Heroes" }) do
	local folder = H.path(rs, folderPath)
	if T.check(folder ~= nil, "ReplicatedStorage.%s missing", folderPath) then
		local extra, have = {}, 0
		for _, c in ipairs(folder:GetChildren()) do
			if roster[c.Name] then
				have += 1
			else
				table.insert(extra, c.Name)
			end
		end
		T.check(#extra == 0 and have == #PLAN.HEROES, "ReplicatedStorage.%s must hold exactly the %d plan heroes (D1), found %d + extra: %s", folderPath,
			#PLAN.HEROES, have, table.concat(extra, ", ", 1, math.min(#extra, 6)))
	end
end

-- the purged ids: the base game's animal/brainrot assets (its Directory.Assets._Index minus the roster) + the 10
-- legacy Speedsters heroes
local purged, purgedList = {}, {}
local function addPurged(id)
	if not roster[id] and not purged[id] then
		purged[id] = true
		table.insert(purgedList, id)
	end
end
for _, id in ipairs(PLAN.PURGED_HEROES) do
	T.check(PLAN.HERO_BY_ID[id] == nil, "plan data: %s is both a roster hero and purged", id)
	addPurged(id)
end
local basePlace = H.basePlace()
local baseIndex = basePlace and H.path(basePlace.ReplicatedStorage, "Directory/Assets/_Index")
if baseIndex then
	for _, m in ipairs(baseIndex:GetChildren()) do
		addPurged(m.Name)
	end
else
	for _, id in ipairs(PLAN.PURGED_ANIMALS_SAMPLE) do
		addPurged(id)
	end
end
T.check(#purgedList > #PLAN.PURGED_HEROES, "no purged animal ids found (base place Directory.Assets._Index)")
local named = {}
for _, d in ipairs(place:GetDescendants()) do
	if purged[d.Name] and not d:IsA("BasePart") then
		table.insert(named, d:GetFullName() .. " <" .. d.ClassName .. ">")
	end
end
T.check(#named == 0, "%d instance(s) are still named after a purged legacy asset (D1): %s", #named, table.concat(named, ", ", 1, math.min(#named, 5)))

for _, p in ipairs({
	"Directory/Products/_Index/LimitedEggs", "Assets/Models/PetAssets", "Assets/Animations/PetAnimations", "Assets/Models/AssetEggModels",
	"Assets/Models/AssetEggModelsWithBones", "Assets/VFX/WildBrainrots", "Assets/Models/LuckyBlocks/Random Brainrot Block",
	"AssetMutationTargets", "AssetMutationReplacements",
}) do
	T.check(H.path(rs, p) == nil, "ReplicatedStorage.%s must be removed (D1: legacy animal/brainrot assets)", p)
end
local debugAttrs = {}
for key in pairs(place.Workspace:GetAttributes()) do
	if string.sub(key, 1, 6) == "Claude" then
		table.insert(debugAttrs, key)
	end
end
T.check(#debugAttrs == 0, "Workspace carries debug attributes %s", table.concat(debugAttrs, ", "))

-- limited / admin-abuse eggs roll nothing (their drop tables held only animals)
local function loadDirectoryModule(name)
	local module = H.path(rs, "Directory/" .. name)
	if not T.check(module ~= nil and module:IsA("ModuleScript"), "ReplicatedStorage.Directory.%s missing", name) then
		return nil
	end
	local chunk, err = H.sandbox(module.Source, {}, name)
	local ok, result = false, err
	if chunk then
		ok, result = pcall(chunk)
	end
	if T.check(ok and type(result) == "table", "Directory.%s does not load: %s", name, tostring(result)) then
		return result
	end
	return nil
end
local limited = loadDirectoryModule("LimitedEgg")
if limited then
	T.check(type(limited.DropTable) == "table" and #limited.DropTable == 0 and type(limited.Entries) == "table" and #limited.Entries == 0,
		"Directory.LimitedEgg must have empty DropTable and Entries (D1)")
end
local admin = loadDirectoryModule("AdminAbuseEgg")
if admin then
	local okEvent, isEvent = pcall(admin.IsEventCategory, "Chicken")
	local okRoll, rolled = pcall(admin.Roll)
	T.check(okEvent and isEvent == false and okRoll and rolled == nil, "Directory.AdminAbuseEgg must roll nothing (IsEventCategory false, Roll nil) (D1), got %s / %s",
		tostring(isEvent), tostring(rolled))
end

-- old saves: the Database migration drops inventory entries whose asset no longer exists
local database = H.path(place:GetService("ServerScriptService"), "Library/Database")
T.check(database ~= nil and H.has(database.Source, "purgeRetiredAssets"), "ServerScriptService.Library.Database must purge retired assets from old saves (D1 purgeRetiredAssets)")

if database then
	-- behaviour: an old save naming purged ids is cleaned, roster heroes / eggs / lucky blocks survive
	local pieces = { "local purgedProfiles = setmetatable({}, { __mode = \"k\" })\nlocal knownAssetIds = nil" }
	local okPieces = true
	for _, name in ipairs({ "getKnownAssetIds", "assetIdOf", "purgeRetiredAssets" }) do
		local body = H.extractFunction(database.Source, name)
		okPieces = T.check(body ~= nil, "Database: local function %s not found (D1 purge)", name) and okPieces
		table.insert(pieces, body or "")
	end
	if okPieces then
		table.insert(pieces, "return purgeRetiredAssets")
		local warnings = {}
		local chunk, err = H.sandbox(table.concat(pieces, "\n"), {
			ReplicatedStorage = rs,
			warn = function(...)
				table.insert(warnings, table.concat({ ... }, " "))
			end,
		}, "Database.purgeRetiredAssets")
		local ok, purge = false, err
		if chunk then
			ok, purge = pcall(chunk)
		end
		if T.check(ok and type(purge) == "function", "Database purge code does not load: %s", tostring(purge)) then
			local luckyBlocks = H.path(rs, "Assets/Models/LuckyBlocks")
			local lucky = luckyBlocks and luckyBlocks:GetChildren()[1]
			local oldAnimal = purgedList[#purgedList]
			local profile = {
				Inventory = { u1 = { Category = "Hawkeye" }, u2 = { Category = oldAnimal }, u3 = { Category = "Zoom" }, u4 = lucky and { Category = lucky.Name } or nil },
				EggInventory = { e1 = { AssetCategory = oldAnimal }, e2 = { AssetCategory = "Goku" } },
				EquippedAssets = { "u1", "u2", "u3" },
				FavoriteAssets = { u1 = true, u2 = true },
				Index = { Hawkeye = true, [oldAnimal] = true },
				FusionReward = { Category = "Sonic" },
				FusionEggReward = { Egg = { AssetCategory = oldAnimal } },
			}
			local okRun, runErr = pcall(purge, profile)
			if T.check(okRun, "Database purgeRetiredAssets failed: %s", tostring(runErr)) then
				T.check(profile.Inventory.u1 ~= nil and profile.Inventory.u2 == nil and profile.Inventory.u3 == nil,
					"D1 migration: Inventory must keep the roster hero and drop the purged %s / Zoom entries", oldAnimal)
				T.check(lucky == nil or profile.Inventory.u4 ~= nil, "D1 migration: a lucky-block inventory item must survive")
				T.check(profile.EggInventory.e1 == nil and profile.EggInventory.e2 ~= nil, "D1 migration: EggInventory must drop the purged egg and keep the Goku egg")
				T.check(#profile.EquippedAssets == 1 and profile.EquippedAssets[1] == "u1", "D1 migration: EquippedAssets must keep only the surviving uid")
				T.check(profile.FavoriteAssets.u1 == true and profile.FavoriteAssets.u2 == nil, "D1 migration: FavoriteAssets must drop removed uids")
				T.check(profile.Index.Hawkeye == true and profile.Index[oldAnimal] == nil, "D1 migration: Index must drop purged categories")
				T.check(profile.FusionReward == nil and profile.FusionEggReward == false, "D1 migration: pending fusion rewards naming purged ids must be cleared")
				T.check(#warnings == 1, "D1 migration: one summary warning expected, got %d", #warnings)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 3. stage area configs: DisplayName, StageNumber, Emoji, DropTable exactly per §2 (A1: retired ones empty)
---------------------------------------------------------------------------------------------------
local areas = H.path(rs, "Directory/Areas/_Index")
local function dropTable(src)
	local block = string.match(src, "DropTable%s*=%s*(%b{})")
	if not block then
		return nil
	end
	local list = {}
	for id, weight in string.gmatch(block, "\"([^\"]+)\"%s*,%s*(%-?[%d%.]+)") do
		table.insert(list, { id = id, weight = tonumber(weight) })
	end
	return list
end
local dropped = {}
if T.check(areas ~= nil, "ReplicatedStorage.Directory.Areas._Index missing") then
	for _, stage in ipairs(PLAN.STAGES) do
		local mod = areas:FindFirstChild(stage.key)
		if T.check(mod ~= nil and mod:IsA("ModuleScript"), "area config Areas._Index.%s missing", stage.key) then
			local src = mod.Source
			T.check(pcall(H.luau.compile, src), "area config %s does not compile", stage.key)
			T.check(H.has(src, string.format("DisplayName = %q,", stage.name)), "area %s: DisplayName must be %q (§2)", stage.key, stage.name)
			T.check(string.find(src, "StageNumber%s*=%s*" .. stage.number .. "%s*,") ~= nil, "area %s: StageNumber must be %d", stage.key, stage.number)
			local emoji = string.match(src, "Emoji%s*=%s*\"([^\"]*)\"")
			T.check(emoji ~= nil and emoji ~= "", "area %s: stage Emoji missing (A11)", stage.key)
			local list = dropTable(src)
			if T.check(list ~= nil, "area %s: DropTable missing", stage.key) then
				local expected = {}
				for _, hero in ipairs(PLAN.HEROES_BY_STAGE[stage.number]) do
					expected[hero.id] = hero
				end
				local seen = {}
				for _, entry in ipairs(list) do
					local hero = expected[entry.id]
					T.check(hero ~= nil, "area %s DropTable lists %s, which is not a stage %d hero (§2: only its own heroes)", stage.key, entry.id, stage.number)
					T.check(not seen[entry.id], "area %s DropTable lists %s twice", stage.key, entry.id)
					seen[entry.id] = true
					if hero then
						T.check(math.abs(entry.weight - hero.dropWeight) < 1e-6, "area %s: %s (%s) weight must be %s, found %s", stage.key, entry.id,
							hero.rarity, tostring(hero.dropWeight), tostring(entry.weight))
					end
					T.check(dropped[entry.id] == nil, "%s drops in two stages (%s and %s)", entry.id, tostring(dropped[entry.id]), stage.key)
					dropped[entry.id] = stage.key
					T.check(configs and configs:FindFirstChild(entry.id) ~= nil and assetModels and assetModels:FindFirstChild(entry.id) ~= nil,
						"area %s DropTable id %s has no config/AssetModel", stage.key, entry.id)
				end
				for id in pairs(expected) do
					T.check(seen[id] == true, "area %s DropTable misses its stage hero %s", stage.key, id)
				end
			end
		end
	end
	for _, key in ipairs(PLAN.RETIRED) do
		T.check(areas:FindFirstChild(key) == nil, "retired area config Areas._Index.%s must be removed (D5)", key)
	end
	T.check(#areas:GetChildren() == #PLAN.STAGES, "Areas._Index must hold exactly the %d stage configs, found %d", #PLAN.STAGES, #areas:GetChildren())
	for _, mod in ipairs(areas:GetChildren()) do
		T.check(PLAN.STAGE_BY_KEY[mod.Name] ~= nil, "unexpected area config Areas._Index.%s", mod.Name)
	end
end
for _, id in ipairs(purgedList) do
	T.check(dropped[id] == nil, "purged asset %s must be in no DropTable (D1)", id)
end

---------------------------------------------------------------------------------------------------
-- 4. HeroCatalog (A11): generated from the roster, same file in src/, Get/GetStageHeroes work
---------------------------------------------------------------------------------------------------
local catalogModule = H.path(rs, "Directory/HeroCatalog")
if T.check(catalogModule ~= nil and catalogModule:IsA("ModuleScript"), "ReplicatedStorage.Directory.HeroCatalog missing") then
	local srcPath = "src/ReplicatedStorage/Directory/HeroCatalog.luau"
	T.check(H.fs.isFile(srcPath) and H.normalize(H.fs.readFile(srcPath)) == H.normalize(catalogModule.Source),
		"HeroCatalog in the place differs from %s (rebuild; the builder writes it back)", srcPath)
	local chunk, err = H.sandbox(catalogModule.Source, { Color3 = H.roblox.Color3 }, "HeroCatalog")
	local ok, catalog = false, err
	if chunk then
		ok, catalog = pcall(chunk)
	end
	if T.check(ok and type(catalog) == "table", "HeroCatalog does not load: %s", tostring(catalog)) then
		T.check(type(catalog.List) == "table" and #catalog.List == #PLAN.HEROES, "HeroCatalog.List must hold the %d roster heroes, found %d", #PLAN.HEROES,
			type(catalog.List) == "table" and #catalog.List or -1)
		T.check(type(catalog.Get) == "function" and type(catalog.GetStageHeroes) == "function", "HeroCatalog.Get / GetStageHeroes missing")
		T.check(type(catalog.Legacy) == "table" and #catalog.Legacy == 0 and (type(catalog.LegacyById) ~= "table" or next(catalog.LegacyById) == nil),
			"HeroCatalog.Legacy must be empty (D1: no legacy hero is kept)")
		local order = type(catalog.RarityOrder) == "table" and table.concat(catalog.RarityOrder, ",") or ""
		T.check(order == table.concat(PLAN.RARITY_ORDER, ","), "HeroCatalog.RarityOrder must be %s", table.concat(PLAN.RARITY_ORDER, ","))
		if type(catalog.Get) == "function" then
			for _, row in ipairs(PLAN.HEROES) do
				local hero = PLAN.HERO_BY_ID[row[1]]
				local c = catalog.Get(hero.id)
				T.check(c ~= nil and c.DisplayName == hero.displayName and c.Stage == hero.stage and c.Rarity == hero.rarity
					and c.EarningRate == hero.earningRate and c.GrowthTime == hero.growthTime and c.DropWeight == hero.dropWeight,
					"HeroCatalog.Get(%q) must match §2 (%s, stage %d, %s, $%d/s)", hero.id, hero.displayName, hero.stage, hero.rarity, hero.earningRate)
			end
			for _, id in ipairs(PLAN.PURGED_HEROES) do
				T.check(catalog.Get(id) == nil, "HeroCatalog.Get(%q) must be nil: the legacy hero was purged (D1)", id)
			end
		end
		if type(catalog.GetStageHeroes) == "function" then
			for _, stage in ipairs(PLAN.STAGES) do
				local got = {}
				for _, h in ipairs(catalog.GetStageHeroes(stage.number)) do
					table.insert(got, h.Id)
				end
				local want = {}
				for _, h in ipairs(PLAN.HEROES_BY_STAGE[stage.number]) do
					table.insert(want, h.id)
				end
				table.sort(got)
				table.sort(want)
				T.check(table.concat(got, ",") == table.concat(want, ","), "HeroCatalog.GetStageHeroes(%d) = {%s}, plan says {%s}", stage.number,
					table.concat(got, ","), table.concat(want, ","))
				local s = type(catalog.Stages) == "table" and catalog.Stages[stage.number]
				T.check(s and s.Key == stage.key and s.Name == stage.name and s.Villain == stage.villain and s.IncomeFactor == stage.incomeFactor,
					"HeroCatalog.Stages[%d] must be %s / %s / %s / x%d", stage.number, stage.key, stage.name, stage.villain, stage.incomeFactor)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 5. 10 treadmill tiers, all Speedsters designs; D4: no video screen / swap buttons left on any skin
---------------------------------------------------------------------------------------------------
local skins = H.path(rs, "Assets/Models/Treadmills")
T.check(skins ~= nil and #skins:GetChildren() == 10, "expected 10 treadmill skins, found %d", skins and #skins:GetChildren() or 0)
local VIDEO_PARTS = { VideoFeedScreen = true, VideoDecorationPart = true, SwapLeft = true, SwapRight = true }
for _, tool in ipairs(skins and skins:GetChildren() or {}) do
	T.check(tool:FindFirstChild("Root") ~= nil and tool:FindFirstChild("BoundingBoxPart") ~= nil and tool:FindFirstChild("SpeedPerSecond") ~= nil,
		"%s: functional Root/BoundingBoxPart/SpeedPerSecond missing", tool.Name)
	local video = {}
	for _, d in ipairs(tool:GetDescendants()) do
		if VIDEO_PARTS[d.Name] then
			table.insert(video, d.Name)
		end
	end
	T.check(#video == 0, "%s: the treadmill video player is removed (D4), found %s", tool.Name, table.concat(video, ", "))
	T.check(type(tool:GetAttribute("SourceAsset")) == "string", "%s: not converted to a Speedsters design (no SourceAsset attribute)", tool.Name)
	for _, className in ipairs({ "LuaSourceContainer", "Sound", "Highlight" }) do
		T.check(H.countClass(tool, className) == 0, "%s: skin must not contain %s", tool.Name, className)
	end
end

---------------------------------------------------------------------------------------------------
-- 6. H1: the procedural / "authentic" look code is gone (dead code must go); the build reads assets/hero_models
---------------------------------------------------------------------------------------------------
local builderSrc = H.fs.isFile("scripts/hero_system_builder.luau") and H.fs.readFile("scripts/hero_system_builder.luau") or ""
local factorySrc = H.fs.isFile("scripts/r15_rig_factory.luau") and H.fs.readFile("scripts/r15_rig_factory.luau") or ""
for _, token in ipairs({ "Look = {", "Props = join", "hairCap", "BuildBody", "AddProps", "AttachSuit", "SkinRigs", "SonicHead",
	"World2Path", "World1Update3New", "Factory.new(", "SuitCatalog", "lookFor(" }) do
	T.check(not H.has(builderSrc, token), "scripts/hero_system_builder.luau still carries procedural look code (%s)", token)
	T.check(not H.has(factorySrc, token), "scripts/r15_rig_factory.luau still carries procedural look code (%s)", token)
end
for _, path in ipairs({ PLAN.MODEL_FILES.heroes, PLAN.MODEL_FILES.villains, PLAN.MODEL_FILES.template }) do
	T.check(H.has(builderSrc, path), "scripts/hero_system_builder.luau must build from %s", path)
end
T.check(string.find(builderSrc, '%.rbxl"') == nil,
	"the hero builder must read assets/hero_models/*.rbxm, never a place file (the generated StealaHero.rbxl or the snapshot)")
