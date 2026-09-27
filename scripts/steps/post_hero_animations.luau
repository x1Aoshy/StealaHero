-- scripts/steps/post_hero_animations.luau (ANIMCORE, hero animation pipeline)
-- Build hook (scripts/build_stealahero.luau step 12b, post_* in name order, after the hero builder): publishes the
-- authored hero clips. Every src/ReplicatedStorage/Directory/HeroAnimations/<HeroId>.luau (generated in Blender by
-- scripts/tools/blender/hero_anim/run.py; no manifest edit per hero) becomes the ModuleScript
-- ReplicatedStorage.Directory.HeroAnimations.<HeroId>, which HeroClipPlayer (injected by scripts/inject/gekko_anims.luau)
-- plays on the pen hero. Each module is checked here the way the game will read it: it compiles, returns a Format 1
-- table whose HeroId matches the file, has looping Idle + Move clips (Special one-shot), ordered keys with known easings
-- and 4 (+3 for Root) numbers per key, and names a hero that exists in ReplicatedStorage.AssetModels. A broken module
-- fails the build (strict) instead of silently falling back to the default animations in game. Idempotent.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance

local Step = {}

Step.SOURCE_DIR = "src/ReplicatedStorage/Directory/HeroAnimations"
Step.JOINTS = {
	Root = true, Waist = true, Neck = true,
	LeftShoulder = true, LeftElbow = true, LeftWrist = true, RightShoulder = true, RightElbow = true, RightWrist = true,
	LeftHip = true, LeftKnee = true, LeftAnkle = true, RightHip = true, RightKnee = true, RightAnkle = true,
}
Step.EASINGS = { linear = true, constant = true }
for _, family in ipairs({ "sine", "quad", "cubic", "quart", "quint", "circ", "back", "bounce" }) do
	for _, direction in ipairs({ "_in", "_out", "_inout" }) do
		Step.EASINGS[family .. direction] = true
	end
end
Step.EFFECTS = { Web = true, Charge = true, Burst = true, Accent = true }

local function log(fmt, ...)
	print(string.format("[post_hero_animations] " .. fmt, ...))
end

-- Returns a list of problems (empty = valid).
function Step.Validate(heroId: string, data: any): { string }
	local problems = {}
	local function bad(fmt, ...)
		table.insert(problems, string.format(fmt, ...))
	end
	if type(data) ~= "table" then
		bad("does not return a table")
		return problems
	end
	if data.Format ~= 1 then
		bad("Format must be 1")
	end
	if data.HeroId ~= heroId then
		bad("HeroId %s does not match the file name", tostring(data.HeroId))
	end
	if type(data.Clips) ~= "table" then
		bad("Clips missing")
		return problems
	end
	for _, required in ipairs({ "Idle", "Move" }) do
		local clip = data.Clips[required]
		if type(clip) ~= "table" or clip.Loop ~= true then
			bad("%s clip missing or not looping", required)
		end
	end
	if type(data.Clips.Special) == "table" and data.Clips.Special.Loop == true then
		bad("Special must not loop")
	end
	for name, clip in pairs(data.Clips) do
		if type(clip) ~= "table" or type(clip.Length) ~= "number" or clip.Length <= 0 or type(clip.Tracks) ~= "table" then
			bad("clip %s needs Length > 0 and Tracks", tostring(name))
			continue
		end
		for joint, keys in pairs(clip.Tracks) do
			if not Step.JOINTS[joint] then
				bad("%s: unknown joint %s", name, tostring(joint))
				continue
			end
			local last = -math.huge
			local width = if joint == "Root" then 9 else 6
			for i, key in ipairs(keys) do
				if type(key) ~= "table" or #key ~= width or type(key[1]) ~= "number" or key[1] < last or key[1] > clip.Length + 1e-3 then
					bad("%s.%s key %d malformed (want %d values, ordered times within Length)", name, joint, i, width)
					break
				end
				if not Step.EASINGS[key[2]] then
					bad("%s.%s key %d: unknown easing %s", name, joint, i, tostring(key[2]))
					break
				end
				local q = key[3] * key[3] + key[4] * key[4] + key[5] * key[5] + key[6] * key[6]
				if math.abs(q - 1) > 0.01 then
					bad("%s.%s key %d: quaternion not normalised", name, joint, i)
					break
				end
				last = key[1]
			end
		end
		for i, effect in ipairs(type(clip.Effects) == "table" and clip.Effects or {}) do
			if type(effect) ~= "table" or not Step.EFFECTS[effect.Type] then
				bad("%s: effect %d has an unknown Type", name, i)
			end
		end
	end
	return problems
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local directory = rs:FindFirstChild("Directory")
	assert(directory ~= nil, "ReplicatedStorage.Directory missing")
	local assetModels = rs:FindFirstChild("AssetModels")

	local folder = directory:FindFirstChild("HeroAnimations")
	if folder ~= nil and not folder:IsA("Folder") then
		folder:Destroy()
		folder = nil
	end
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "HeroAnimations"
		folder.Parent = directory
	end
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end

	local files = {}
	if fs.isDir(Step.SOURCE_DIR) then
		for _, fileName in ipairs(fs.readDir(Step.SOURCE_DIR)) do
			if string.sub(fileName, -5) == ".luau" then
				table.insert(files, fileName)
			end
		end
	end
	table.sort(files)

	local published, clipCount, errors = {}, 0, {}
	for _, fileName in ipairs(files) do
		local heroId = string.sub(fileName, 1, -6)
		local path = Step.SOURCE_DIR .. "/" .. fileName
		local source = fs.readFile(path)
		local okCompile, compileErr = pcall(luau.compile, source)
		if not okCompile then
			table.insert(errors, string.format("%s: does not compile: %s", path, tostring(compileErr)))
			continue
		end
		local okLoad, data = pcall(function()
			return luau.load(source, { debugName = path, environment = {}, injectGlobals = false })()
		end)
		if not okLoad then
			table.insert(errors, string.format("%s: fails to load: %s", path, tostring(data)))
			continue
		end
		local problems = Step.Validate(heroId, data)
		if assetModels ~= nil and assetModels:FindFirstChild(heroId) == nil then
			table.insert(problems, "no ReplicatedStorage.AssetModels." .. heroId)
		end
		if #problems > 0 then
			table.insert(errors, string.format("%s: %s", path, table.concat(problems, "; ")))
			continue
		end
		local module = Instance.new("ModuleScript")
		module.Name = heroId
		module.Source = source
		module.Parent = folder
		for _ in pairs(data.Clips) do
			clipCount += 1
		end
		table.insert(published, heroId)
	end

	if #errors > 0 then
		error("[post_hero_animations] invalid hero animation module(s):\n  " .. table.concat(errors, "\n  "))
	end
	log("published %d hero animation module(s) (%d clips) in ReplicatedStorage.Directory.HeroAnimations: %s",
		#published, clipCount, if #published > 0 then table.concat(published, ", ") else "(none)")
end

return Step
