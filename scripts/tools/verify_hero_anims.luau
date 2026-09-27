-- scripts/tools/verify_hero_anims.luau (ANIMCORE, hero animation pipeline)
-- Proves the exported hero clips pose the game rig exactly like Blender did:
--   lune run scripts/tools/verify_hero_anims.luau [HeroId ...]     (default: every module with a round-trip dump)
-- For each hero:
--   * src/ReplicatedStorage/Directory/HeroAnimations/<HeroId>.luau compiles, loads with no globals, and passes
--     HeroClipMath.PrepareModule (Format 1, Idle + Move looping, known easings, ordered keys) and the contract checks
--     (Special optional and one-shot, effects well formed)
--   * for every sample of assets/animations/roundtrip/<HeroId>.json (Blender's posed mannequin, written by run.py) the
--     game's own HeroClipMath (src/ReplicatedStorage/Library/Modules/HeroClipMath.luau) evaluates each joint's
--     Motor6D.Transform, the parts are rebuilt with Part1 = Part0 * C0 * Transform * C1:Inverse() from the rig of
--     assets/animations/r15_rig.json, and 8 corners of every part are compared: max error must stay < 0.01 studs.
-- Exit code 1 on any failure.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

local MODULE_DIR = "src/ReplicatedStorage/Directory/HeroAnimations"
local DUMP_DIR = "assets/animations/roundtrip"
local MATH_PATH = "src/ReplicatedStorage/Library/Modules/HeroClipMath.luau"
local RIG_PATH = "assets/animations/r15_rig.json"
local TOLERANCE = 0.01

local EFFECT_FIELDS = {
	Web = { "Hand", "Anchor" },
	Charge = { "Hand" },
	Burst = { "Hand", "Time" },
	Accent = { "Boost" },
}

local function cframeOf(c)
	return CFrame.new(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
end

local HeroClipMath = luau.load(fs.readFile(MATH_PATH), {
	debugName = MATH_PATH,
	environment = { CFrame = CFrame },
})()

local rig = serde.decode("json", fs.readFile(RIG_PATH))
local joints = {}
for _, j in ipairs(rig.joints) do
	table.insert(joints, { name = j.name, part0 = j.part0, part1 = j.part1, c0 = cframeOf(j.c0), c1inv = cframeOf(j.c1):Inverse() })
end
local sizes = {}
for name, part in pairs(rig.parts) do
	sizes[name] = Vector3.new(part.size[1], part.size[2], part.size[3])
end
local hrp = CFrame.new(0, rig.hrpHeight, 0)

local function loadModule(heroId: string)
	local path = MODULE_DIR .. "/" .. heroId .. ".luau"
	assert(fs.isFile(path), path .. " not found")
	local source = fs.readFile(path)
	luau.compile(source) -- throws on a syntax error
	local data = luau.load(source, { debugName = path, environment = {}, injectGlobals = false })()
	assert(type(data) == "table", path .. " must return a table")
	assert(data.HeroId == heroId, string.format("%s: HeroId %s does not match the file name", path, tostring(data.HeroId)))
	local clips = HeroClipMath.PrepareModule(data)
	if clips.Special ~= nil then
		assert(not clips.Special.Loop, heroId .. ": Special must not loop")
	end
	local every = data.SpecialEvery
	assert(type(every) == "table" and type(every[1]) == "number" and type(every[2]) == "number" and every[1] <= every[2],
		heroId .. ": SpecialEvery must be { min, max }")
	for name, clip in pairs(clips) do
		for i, effect in ipairs(clip.Effects) do
			local fields = EFFECT_FIELDS[effect.Type]
			assert(fields ~= nil, string.format("%s.%s: effect %d has unknown Type %s", heroId, name, i, tostring(effect.Type)))
			for _, field in ipairs(fields) do
				assert(effect[field] ~= nil, string.format("%s.%s: %s effect %d misses %s", heroId, name, effect.Type, i, field))
			end
		end
		for _, track in ipairs(clip.Tracks) do
			local known = false
			for _, j in ipairs(joints) do
				known = known or j.name == track.Joint
			end
			assert(known, string.format("%s.%s: track for unknown joint %s", heroId, name, track.Joint))
		end
	end
	return clips
end

local function pose(clip, t)
	local samples = {}
	HeroClipMath.SampleClip(clip, t, samples)
	local parts = { HumanoidRootPart = hrp }
	for _, j in ipairs(joints) do
		local s = samples[j.name]
		local transform = if s then HeroClipMath.ToCFrame(s, 1) else CFrame.new()
		parts[j.part1] = parts[j.part0] * j.c0 * transform * j.c1inv
	end
	return parts
end

local CORNERS = {}
for _, x in ipairs({ -0.5, 0.5 }) do
	for _, y in ipairs({ -0.5, 0.5 }) do
		for _, z in ipairs({ -0.5, 0.5 }) do
			table.insert(CORNERS, Vector3.new(x, y, z))
		end
	end
end

local function verifyHero(heroId: string): (boolean, string)
	local okLoad, clipsOrErr = pcall(loadModule, heroId)
	if not okLoad then
		return false, "module: " .. tostring(clipsOrErr)
	end
	local clips = clipsOrErr
	local dumpPath = DUMP_DIR .. "/" .. heroId .. ".json"
	if not fs.isFile(dumpPath) then
		return false, dumpPath .. " missing (run scripts/tools/blender/hero_anim/run.py)"
	end
	local dump = serde.decode("json", fs.readFile(dumpPath))
	local worst, worstAt, count = 0, "", 0
	for clipName, clipDump in pairs(dump.clips) do
		local clip = clips[clipName]
		if clip == nil then
			return false, "clip " .. clipName .. " is in the dump but not in the module"
		end
		if math.abs(clip.Length - clipDump.length) > 1e-4 or clip.Loop ~= clipDump.loop then
			return false, clipName .. ": Length / Loop differ between the module and Blender"
		end
		for _, sample in ipairs(clipDump.samples) do
			local parts = pose(clip, sample.t)
			for partName, comps in pairs(sample.parts) do
				local want = cframeOf(comps)
				local got = parts[partName]
				local size = sizes[partName]
				for _, corner in ipairs(CORNERS) do
					local local_ = corner * size
					local err = ((want * local_) - (got * local_)).Magnitude
					count += 1
					if err > worst then
						worst = err
						worstAt = string.format("%s @%.3fs %s", clipName, sample.t, partName)
					end
				end
			end
		end
	end
	local line = string.format("%d corners, max error %.6f studs (%s)", count, worst, worstAt)
	return worst < TOLERANCE, line
end

local heroIds = {}
for _, arg in ipairs(process.args) do
	table.insert(heroIds, arg)
end
if #heroIds == 0 then
	for _, fileName in ipairs(fs.readDir(DUMP_DIR)) do
		if string.sub(fileName, -5) == ".json" then
			table.insert(heroIds, string.sub(fileName, 1, -6))
		end
	end
	table.sort(heroIds)
end

local failures = 0
for _, heroId in ipairs(heroIds) do
	local ok, line = verifyHero(heroId)
	print(string.format("[verify_hero_anims] %-4s %-14s %s", if ok then "OK" else "FAIL", heroId, line))
	if not ok then
		failures += 1
	end
end
if failures > 0 then
	print(string.format("[verify_hero_anims] %d hero(es) failed", failures))
	process.exit(1)
end
print(string.format("[verify_hero_anims] %d hero(es) verified: the game's HeroClipMath reproduces Blender's poses", #heroIds))
