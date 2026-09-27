-- scripts/tools/extract_r15_rig.luau (ANIMCORE, hero animation pipeline step 1)
-- Reads the owner's block R15 template (assets/hero_models/R15Template.rbxm, the body every converted hero rig is
-- built on, scripts/lib/rig_convert.luau) and writes assets/animations/r15_rig.json: the reference rig the Blender
-- animation tools (scripts/tools/blender/hero_anim/rig.py) build their "HeroRig" armature from and the Lune verifier
-- (scripts/tools/verify_hero_anims.luau) rebuilds posed parts with.
--
--   lune run scripts/tools/extract_r15_rig.luau                      write assets/animations/r15_rig.json
--   lune run scripts/tools/extract_r15_rig.luau --verify <place.rbxl> [HeroId ...]
--       compare the template with real ReplicatedStorage.AssetModels.<HeroId> rigs of a build (default Vegeta,
--       PeterParker, Hulk, AgentVenom): joint names, Part0 / Part1, C0 / C1 (rotation must be identity, positions may
--       only differ by a uniform rig scale), part sizes. Exit code 1 on a structural mismatch.
--
-- Rig space (the JSON's frame): origin on the ground under the HumanoidRootPart, +X = the rig's right, +Y = up,
-- +Z = back (the rig faces -Z, Roblox LookVector). CFrames are the 12 numbers of CFrame:GetComponents()
-- (x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22). Joints are listed parent before child.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

local TEMPLATE_PATH = "assets/hero_models/R15Template.rbxm"
local OUT_PATH = "assets/animations/r15_rig.json"

-- { Motor6D, Part0, Part1 } parent-before-child (the same order as RigConvert.R15_JOINTS)
local JOINTS = {
	{ "Root", "HumanoidRootPart", "LowerTorso" },
	{ "Waist", "LowerTorso", "UpperTorso" },
	{ "Neck", "UpperTorso", "Head" },
	{ "LeftShoulder", "UpperTorso", "LeftUpperArm" },
	{ "LeftElbow", "LeftUpperArm", "LeftLowerArm" },
	{ "LeftWrist", "LeftLowerArm", "LeftHand" },
	{ "RightShoulder", "UpperTorso", "RightUpperArm" },
	{ "RightElbow", "RightUpperArm", "RightLowerArm" },
	{ "RightWrist", "RightLowerArm", "RightHand" },
	{ "LeftHip", "LowerTorso", "LeftUpperLeg" },
	{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftAnkle", "LeftLowerLeg", "LeftFoot" },
	{ "RightHip", "LowerTorso", "RightUpperLeg" },
	{ "RightKnee", "RightUpperLeg", "RightLowerLeg" },
	{ "RightAnkle", "RightLowerLeg", "RightFoot" },
}

local function round(n: number, digits: number): number
	local m = 10 ^ digits
	local r = math.floor(n * m + 0.5) / m
	if r == 0 then
		return 0 -- no "-0"
	end
	return r
end

local function components(cf): { number }
	local out = { cf:GetComponents() }
	for i, v in ipairs(out) do
		out[i] = round(v, 5)
	end
	return out
end

local function findMotors(root)
	local motors = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Motor6D") then
			motors[d.Name] = d
		end
	end
	return motors
end

local function isIdentityRotation(cf): boolean
	return cf.RightVector:Dot(Vector3.new(1, 0, 0)) > 0.99999 and cf.UpVector:Dot(Vector3.new(0, 1, 0)) > 0.99999
end

local function loadTemplate()
	local roots = roblox.deserializeModel(fs.readFile(TEMPLATE_PATH))
	local template = roots[1]
	assert(template ~= nil, TEMPLATE_PATH .. " is empty")
	local hrp = template:FindFirstChild("HumanoidRootPart", true)
	assert(hrp ~= nil and hrp:IsA("BasePart"), TEMPLATE_PATH .. ": no HumanoidRootPart")
	return template, hrp
end

local function extract()
	local template, hrp = loadTemplate()
	local motors = findMotors(template)

	-- rig space: HRP axes, origin on the ground (sole of the lowest foot) under the HRP centre
	local lowest = math.huge
	for _, name in ipairs({ "LeftFoot", "RightFoot" }) do
		local foot = template:FindFirstChild(name, true)
		assert(foot ~= nil, TEMPLATE_PATH .. ": no " .. name)
		local rel = hrp.CFrame:ToObjectSpace(foot.CFrame)
		lowest = math.min(lowest, rel.Position.Y - foot.Size.Y * 0.5)
	end
	local rigOrigin = hrp.CFrame * CFrame.new(0, lowest, 0)

	local parts = {}
	local top = -math.huge
	local function addPart(part)
		local cf = rigOrigin:ToObjectSpace(part.CFrame)
		local shape = "box"
		if part.Name == "Head" then
			shape = "head" -- classic SpecialMesh head
		end
		parts[part.Name] = {
			size = { round(part.Size.X, 5), round(part.Size.Y, 5), round(part.Size.Z, 5) },
			cframe = components(cf),
			shape = shape,
		}
		if part.Name ~= "HumanoidRootPart" then
			top = math.max(top, cf.Position.Y + part.Size.Y * 0.5)
		end
	end
	addPart(hrp)

	local joints = {}
	for _, spec in ipairs(JOINTS) do
		local motor = motors[spec[1]]
		assert(motor ~= nil, TEMPLATE_PATH .. ": missing Motor6D " .. spec[1])
		assert(motor.Part0 ~= nil and motor.Part0.Name == spec[2], spec[1] .. ".Part0 must be " .. spec[2])
		assert(motor.Part1 ~= nil and motor.Part1.Name == spec[3], spec[1] .. ".Part1 must be " .. spec[3])
		assert(isIdentityRotation(motor.C0) and isIdentityRotation(motor.C1), spec[1] .. ": C0 / C1 must be axis aligned")
		addPart(motor.Part1)
		table.insert(joints, {
			name = spec[1],
			part0 = spec[2],
			part1 = spec[3],
			c0 = components(motor.C0),
			c1 = components(motor.C1),
		})
	end

	-- the posed-by-joints rest must agree with the saved part CFrames (proves the C0 / C1 reading)
	local rest = { HumanoidRootPart = rigOrigin:ToObjectSpace(hrp.CFrame) }
	local worst = 0
	for _, spec in ipairs(JOINTS) do
		local motor = motors[spec[1]]
		local p1 = rest[spec[2]] * motor.C0 * motor.C1:Inverse()
		rest[spec[3]] = p1
		local saved = rigOrigin:ToObjectSpace(motor.Part1.CFrame)
		worst = math.max(worst, (p1.Position - saved.Position).Magnitude)
	end
	assert(worst < 0.01, string.format("template joints disagree with its part CFrames (%.4f studs)", worst))

	local hipY = rest.LeftUpperLeg * motors.LeftHip.C1
	local data = {
		format = 1,
		source = TEMPLATE_PATH,
		units = "studs",
		space = "rig space: origin on the ground under the HumanoidRootPart, +X = the rig's right, +Y = up, +Z = back (the rig faces -Z)",
		cframeComponents = "x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 (CFrame:GetComponents())",
		height = round(top, 4),
		hipHeight = round(hipY.Position.Y, 4),
		hrpHeight = round(rest.HumanoidRootPart.Position.Y, 4),
		parts = parts,
		joints = joints,
	}
	if not fs.isDir("assets/animations") then
		fs.writeDir("assets/animations")
	end
	fs.writeFile(OUT_PATH, serde.encode("json", data, true))
	print(string.format("[extract_r15_rig] wrote %s: %d joints, height %.3f, hip %.3f, HRP centre %.3f (joint rest error %.5f)",
		OUT_PATH, #joints, data.height, data.hipHeight, data.hrpHeight, worst))
end

local function verify(placePath: string, heroIds: { string })
	local template = loadTemplate()
	local ref = findMotors(template)
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local assetModels = place:GetService("ReplicatedStorage"):FindFirstChild("AssetModels")
	assert(assetModels ~= nil, placePath .. ": no ReplicatedStorage.AssetModels")
	local failures = 0
	for _, heroId in ipairs(heroIds) do
		local model = assetModels:FindFirstChild(heroId)
		if model == nil then
			print("  !! " .. heroId .. ": no AssetModel")
			failures += 1
			continue
		end
		local motors = findMotors(model)
		local problems, scales, sizeNotes = {}, {}, {}
		for _, spec in ipairs(JOINTS) do
			local motor, r = motors[spec[1]], ref[spec[1]]
			if motor == nil then
				table.insert(problems, "missing " .. spec[1])
				continue
			end
			if motor.Part0 == nil or motor.Part0.Name ~= spec[2] or motor.Part1 == nil or motor.Part1.Name ~= spec[3] then
				table.insert(problems, spec[1] .. " Part0/Part1")
			end
			if not isIdentityRotation(motor.C0) or not isIdentityRotation(motor.C1) then
				table.insert(problems, spec[1] .. " rotated C0/C1")
			end
			for _, key in ipairs({ "C0", "C1" }) do
				local a, b = motor[key].Position, r[key].Position
				if b.Magnitude > 0.05 then
					table.insert(scales, a.Magnitude / b.Magnitude)
				end
			end
			local part = motor.Part1
			local refPart = r.Part1
			if part and refPart and (part.Size - refPart.Size).Magnitude > 0.01 then
				table.insert(sizeNotes, string.format("%s %.2fx%.2fx%.2f", part.Name, part.Size.X, part.Size.Y, part.Size.Z))
			end
		end
		table.sort(scales)
		local lo, hi = scales[1] or 1, scales[#scales] or 1
		local status = if #problems == 0 then "OK" else "MISMATCH"
		if #problems > 0 then
			failures += 1
		end
		print(string.format("  %-8s %-14s joints %d/15, joint offset scale %.3f..%.3f%s%s", status, heroId,
			15 - #problems, lo, hi, if #problems > 0 then " | " .. table.concat(problems, ", ") else "",
			if #sizeNotes > 0 then " | sizes differ: " .. table.concat(sizeNotes, ", ", 1, math.min(#sizeNotes, 4)) else " | sizes = template"))
	end
	if failures > 0 then
		print(string.format("[extract_r15_rig] verify: %d rig(s) do not match the template structure", failures))
		process.exit(1)
	end
	print("[extract_r15_rig] verify: every checked rig has the template's 15 joints (names, Part0/Part1, axis-aligned C0/C1)")
end

local args = process.args
if args[1] == "--verify" then
	assert(args[2] ~= nil, "usage: lune run scripts/tools/extract_r15_rig.luau --verify <place.rbxl> [HeroId ...]")
	local ids = {}
	for i = 3, #args do
		table.insert(ids, args[i])
	end
	if #ids == 0 then
		ids = { "Vegeta", "PeterParker", "Hulk", "AgentVenom" }
	end
	verify(args[2], ids)
else
	extract()
end
