-- scripts/tools/sim_hero_clips.luau (ANIMCORE, hero animation pipeline)
-- Runs the game's HeroClipPlayer (as built into a place) offline on the real pen hero models, frame by frame:
--   lune run scripts/tools/sim_hero_clips.luau <built place.rbxl> [HeroId ...]    (default: every published hero)
--   "HeroId@ModelId" plays HeroId's clips on another hero's model (e.g. Vegeta@AgentVenom: a 1.25x rig).
-- For each hero with ReplicatedStorage.Directory.HeroAnimations.<HeroId> it clones ReplicatedStorage.AssetModels.<HeroId>,
-- builds the player the way AssetComponent does, then scripts idle -> move -> long idle (Special) -> silent -> far camera
-- and checks: every Motor6D gets a finite Transform, the Idle pose is the clip's pose, Move takes over within the
-- cross-fade, Special triggers while idling, clip effects (Web beam, Charge emitters) switch on in their windows and
-- off afterwards, the silent path and the far LOD write nothing, the motion modifiers / accent boost stay in range, and
-- Destroy(true) resets the joints and removes every HeroClipFx instance. Exit code 1 on any failure.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3

roblox.implementMethod("ParticleEmitter", "Emit", function(self, count)
	self:SetAttribute("SimEmitted", (self:GetAttribute("SimEmitted") or 0) + (count or 0))
end)

local placePath = process.args[1]
assert(placePath ~= nil and fs.isFile(placePath), "usage: lune run scripts/tools/sim_hero_clips.luau <place.rbxl> [HeroId ...]")
local place = roblox.deserializePlace(fs.readFile(placePath))
local rs = place:GetService("ReplicatedStorage")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

-- minimal Random (Roblox API subset used by the player)
local Random = {}
Random.__index = Random
function Random.new(seed)
	return setmetatable({ state = (math.floor(seed or 0) % 2147483647) + 1 }, Random)
end
function Random:_next()
	self.state = (self.state * 48271) % 2147483647
	return self.state / 2147483647
end
function Random:NextNumber(a, b)
	a, b = a or 0, b or 1
	return a + (b - a) * self:_next()
end
function Random:NextInteger(a, b)
	return math.floor(self:NextNumber(a, b + 1))
end

local camera = { CFrame = CFrame.new(0, 6, 20) }
local workspaceStub = { CurrentCamera = camera }
local services = { ReplicatedStorage = rs, Workspace = workspaceStub }
local game = {
	GetService = function(_, name)
		return assert(services[name], "sim: no service " .. tostring(name))
	end,
}
local warnings = {}
local env
local loaded = {}
local function simRequire(module)
	if loaded[module] == nil then
		local chunk = luau.load(module.Source, { debugName = module:GetFullName(), environment = env })
		loaded[module] = chunk()
	end
	return loaded[module]
end
env = {
	game = game,
	workspace = workspaceStub,
	Random = Random,
	Instance = roblox.Instance,
	CFrame = CFrame,
	Vector3 = Vector3,
	Vector2 = roblox.Vector2,
	Color3 = roblox.Color3,
	ColorSequence = roblox.ColorSequence,
	NumberSequence = roblox.NumberSequence,
	NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
	NumberRange = roblox.NumberRange,
	Enum = roblox.Enum,
	require = simRequire,
	warn = function(...)
		local parts = {}
		for _, v in ipairs({ ... }) do
			table.insert(parts, tostring(v))
		end
		table.insert(warnings, table.concat(parts, " "))
	end,
}

local playerModule = sps and sps:FindFirstChild("HeroClipPlayer", true)
assert(playerModule ~= nil, "HeroClipPlayer is not in the built place")
local HeroClipPlayer = simRequire(playerModule)
local mathModule = rs.Library.Modules:FindFirstChild("HeroClipMath")
assert(mathModule ~= nil, "HeroClipMath is not in the built place")
local HeroClipMath = simRequire(mathModule)
local folder = rs.Directory:FindFirstChild("HeroAnimations")
assert(folder ~= nil, "ReplicatedStorage.Directory.HeroAnimations missing")

local heroIds = {}
for i = 2, #process.args do
	table.insert(heroIds, process.args[i])
end
if #heroIds == 0 then
	for _, module in ipairs(folder:GetChildren()) do
		table.insert(heroIds, module.Name)
	end
	table.sort(heroIds)
end

local function angleOf(cf)
	local _, angle = cf:ToAxisAngle()
	return math.deg(math.abs(angle))
end

local function finite(cf)
	for _, v in ipairs({ cf:GetComponents() }) do
		if v ~= v or v == math.huge or v == -math.huge then
			return false
		end
	end
	return true
end

local function simulate(spec)
	local heroId, modelId = string.match(spec, "^([^@]+)@(.+)$")
	heroId = heroId or spec
	modelId = modelId or spec
	local problems = {}
	local function check(ok, fmt, ...)
		if not ok then
			table.insert(problems, string.format(fmt, ...))
		end
	end
	local model = rs.AssetModels:FindFirstChild(modelId)
	if model == nil then
		return { "no AssetModels." .. modelId }
	end
	model = model:Clone()
	model.Parent = place:GetService("Workspace")
	local motors = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			motors[d.Name] = d
		end
	end
	local player = HeroClipPlayer.new(model, heroId, 12345)
	if player == nil then
		model:Destroy()
		return { "HeroClipPlayer.new returned nil" }
	end
	local data = simRequire(folder:FindFirstChild(heroId))
	local clips = HeroClipMath.PrepareModule(data)
	local dt = 1 / 60
	local t = 0
	local function run(seconds, moving, speed, silent, hidden, each)
		local frames = math.floor(seconds / dt + 0.5)
		for _ = 1, frames do
			player:Step(dt, moving, speed, silent, hidden)
			t += dt
			if each then
				each()
			end
		end
	end
	local function fxNamed(name)
		local out = {}
		for _, d in ipairs(model:GetDescendants()) do
			if d.Name == name then
				table.insert(out, d)
			end
		end
		return out
	end
	local function anyEnabled(name)
		for _, d in ipairs(fxNamed(name)) do
			if d.Enabled then
				return true
			end
		end
		return false
	end

	-- 1. idle: the pose is the Idle clip's pose at the player's clock
	run(1.0, false, 0, false, false)
	local samples = {}
	HeroClipMath.SampleClip(clips.Idle, player._tIdle, samples)
	local worst = 0
	for name, motor in pairs(motors) do
		check(finite(motor.Transform), "%s Transform not finite", name)
		local want = if samples[name] then HeroClipMath.ToCFrame(samples[name], player._scale) else CFrame.new()
		worst = math.max(worst, (motor.Transform.Position - want.Position).Magnitude, angleOf(motor.Transform:ToObjectSpace(want)) / 57.3)
	end
	check(worst < 1e-3, "Idle pose differs from the clip by %.4f", worst)

	-- 2. move: Move takes over within the cross-fade, its effects run
	local moveWebOn, moveRoot = false, 0
	run(3.0, true, 8, false, false, function()
		-- only once Move owns the pose: an Idle web (Hawkeye's arrow) may still show during the cross-fade
		moveWebOn = moveWebOn or (player._wMove > 0.5 and anyEnabled("HeroClipFxWeb"))
	end)
	check(player._wMove == 1, "Move weight %.2f after 3 s of moving", player._wMove)
	samples = {}
	HeroClipMath.SampleClip(clips.Move, player._tMove, samples)
	worst = 0
	for name, motor in pairs(motors) do
		local want = if samples[name] then HeroClipMath.ToCFrame(samples[name], player._scale) else CFrame.new()
		worst = math.max(worst, angleOf(motor.Transform:ToObjectSpace(want)) / 57.3, (motor.Transform.Position - want.Position).Magnitude)
	end
	check(worst < 1e-3, "Move pose differs from the clip by %.4f", worst)
	moveRoot = angleOf(motors.Root.Transform)
	local hasWeb = false
	for _, e in ipairs(clips.Move.Effects) do
		hasWeb = hasWeb or e.Type == "Web"
	end
	check(moveWebOn == hasWeb, "Move Web effect: expected %s, beam on = %s", tostring(hasWeb), tostring(moveWebOn))
	local lift, lean = player:GetMotionModifiers()
	check(math.abs(lift - clips.Move.Lift) < 1e-6 and math.abs(lean - clips.Move.Lean) < 1e-6, "motion modifiers %.2f/%.2f != Move's", lift, lean)

	-- 3. long idle: the Special plays (fades in, effects in their windows), then ends
	local specialSeen, chargeOn, maxBoost, emitted = false, false, 1, false
	run(45.0, false, 0, false, false, function()
		specialSeen = specialSeen or player._wSpecial > 0.95
		chargeOn = chargeOn or anyEnabled("HeroClipFxCharge") or anyEnabled("HeroClipFxWeb")
		maxBoost = math.max(maxBoost, player:GetAccentBoost())
	end)
	for _, d in ipairs(fxNamed("HeroClipFxBurst")) do
		emitted = emitted or (d:GetAttribute("SimEmitted") or 0) > 0
	end
	if clips.Special then
		check(specialSeen, "Special never played in 45 s of idling")
		local hasCharge, hasBurst, hasAccent = false, false, false
		for _, e in ipairs(clips.Special.Effects) do
			hasCharge = hasCharge or e.Type == "Charge" or e.Type == "Web"
			hasBurst = hasBurst or e.Type == "Burst"
			hasAccent = hasAccent or e.Type == "Accent"
		end
		check(chargeOn == hasCharge, "Special Charge/Web effects on = %s, expected %s", tostring(chargeOn), tostring(hasCharge))
		check(emitted == hasBurst, "Special Burst emitted = %s, expected %s", tostring(emitted), tostring(hasBurst))
		check((maxBoost > 1.5) == hasAccent, "accent boost peaked at %.2f (Accent effect: %s)", maxBoost, tostring(hasAccent))
	end
	check(player._specialState == nil or player._wSpecial <= 1, "special state stuck")

	-- 4. silent path: nothing written, effects off
	local before = {}
	for name, motor in pairs(motors) do
		before[name] = motor.Transform
	end
	run(0.5, true, 8, true, false)
	local changed = 0
	for name, motor in pairs(motors) do
		if motor.Transform ~= before[name] then
			changed += 1
		end
	end
	check(changed == 0, "silent path wrote %d joints", changed)
	check(not anyEnabled("HeroClipFxWeb") and not anyEnabled("HeroClipFxCharge"), "effects left on on the silent path")

	-- 5. far camera: the pose freezes
	camera.CFrame = CFrame.new(0, 6, 5000)
	run(1.0, true, 8, false, false)
	for name, motor in pairs(motors) do
		before[name] = motor.Transform
	end
	run(0.5, true, 8, false, false)
	changed = 0
	for name, motor in pairs(motors) do
		if motor.Transform ~= before[name] then
			changed += 1
		end
	end
	check(changed == 0, "far LOD wrote %d joints", changed)
	camera.CFrame = CFrame.new(0, 6, 20)

	-- 6. destroy resets and cleans up
	player:Destroy(true)
	local dirty = 0
	for _, motor in pairs(motors) do
		if angleOf(motor.Transform) > 1e-4 or motor.Transform.Position.Magnitude > 1e-6 then
			dirty += 1
		end
	end
	check(dirty == 0, "%d joints not reset by Destroy(true)", dirty)
	local leftovers = 0
	for _, d in ipairs(model:GetDescendants()) do
		if string.sub(d.Name, 1, 9) == "HeroClipF" then
			leftovers += 1
		end
	end
	check(leftovers == 0, "%d HeroClipFx instances left after Destroy", leftovers)
	model:Destroy()
	return problems, string.format("scale %.2f, Move root %.0f deg, special %s, boost %.1f", player._scale, moveRoot,
		if clips.Special then "played" else "none", maxBoost)
end

local failures = 0
for _, heroId in ipairs(heroIds) do
	local ok, problems, info = pcall(simulate, heroId)
	if not ok then
		problems = { tostring(problems) }
	end
	local good = #problems == 0
	print(string.format("[sim_hero_clips] %-4s %-14s %s", if good then "OK" else "FAIL", heroId, if good then info else table.concat(problems, "; ")))
	if not good then
		failures += 1
	end
end
for _, w in ipairs(warnings) do
	print("[sim_hero_clips] warn: " .. w)
end
if failures > 0 then
	process.exit(1)
end
print(string.format("[sim_hero_clips] %d hero(es): HeroClipPlayer drives the real rigs as authored", #heroIds))
