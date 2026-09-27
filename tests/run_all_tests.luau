-- tests/run_all_tests.luau
-- Steal a Hero test suite (v3: the 6-stage game of docs/STAGES_PLAN.md + the visual pass docs/VISUAL_PASS_PLAN.md
-- D1-D9). Static and sandboxed behavioural checks
-- on the built place file; run from the project root:
--   lune run tests/run_all_tests.luau            (all suites against StealaHero.rbxl)
--   lune run tests/run_all_tests.luau ui world   (only suites whose name contains a filter)
--   lune run tests/run_all_tests.luau smoke      (quick ~50-check pass; the default loop: smoke, then compile)
--   STEALAHERO_PLACE=<path> lune run tests/run_all_tests.luau
-- Each suite is loaded in its own environment with `H` (helpers) and `T` (checks) injected, so a crash
-- or syntax error in one suite never hides the others. Exit code is non-zero when any check fails.
-- H.PLAN is the game plan as data (tests/plan_data.luau): suites check the build against it, never against the
-- build scripts' own tables.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local PLACE_PATH = process.env.STEALAHERO_PLACE or "StealaHero.rbxl"
local BASE_PATH = "Steal An Egg with treadmill V2.rbxl"
local PLAN_PATH = "tests/plan_data.luau"

local SUITES = {
	"tests/suite_build.luau",
	"tests/suite_world.luau",
	"tests/suite_heroes.luau",
	"tests/suite_ui.luau",
	"tests/suite_gameplay.luau",
	"tests/suite_audio_vfx.luau",
	"tests/suite_eggs.luau",
	"tests/smoke.luau", -- quick ~50-check pass: run with the "smoke" filter (skipped by a plain full run)
}
-- Feature smoke files (tests/smoke_<feature>.luau) join the "smoke" filter too, one file per feature owner.
do
	local extra = {}
	for _, name in ipairs(fs.readDir("tests")) do
		if string.match(name, "^smoke_.+%.luau$") then
			table.insert(extra, "tests/" .. name)
		end
	end
	table.sort(extra)
	for _, path in ipairs(extra) do
		table.insert(SUITES, path)
	end
end

---------------------------------------------------------------------------------------------------
-- Helpers shared by every suite
---------------------------------------------------------------------------------------------------
local H = {}
H.roblox = roblox
H.fs = fs
H.luau = luau

do
	local ok, plan = pcall(function()
		return luau.load(fs.readFile(PLAN_PATH), { debugName = PLAN_PATH })()
	end)
	if ok and type(plan) == "table" then
		H.PLAN = plan
	else
		print("!! " .. PLAN_PATH .. " failed to load: " .. tostring(plan))
	end
end

local placeBytes = fs.readFile(PLACE_PATH)
local placeCache = nil
-- The built place. Suites only read it; it is deserialized once and shared (a suite that needs to mutate
-- instances must use H.freshPlace()).
function H.place()
	if placeCache == nil then
		placeCache = roblox.deserializePlace(placeBytes)
	end
	return placeCache
end
function H.freshPlace()
	return roblox.deserializePlace(placeBytes)
end
local baseCache = nil
function H.basePlace()
	if baseCache == nil and fs.isFile(BASE_PATH) then
		baseCache = roblox.deserializePlace(fs.readFile(BASE_PATH))
	end
	return baseCache
end

-- "A/B/C" path lookup (plain names; nil when any segment is missing).
function H.path(root, path)
	local node = root
	for segment in string.gmatch(path, "[^/]+") do
		if node == nil then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

-- Content properties (ImageContent, AudioContent, TextureContent, MeshContent) as a plain uri string.
function H.uri(inst, prop)
	local ok, value = pcall(function()
		return (inst :: any)[prop]
	end)
	if not ok or value == nil then
		return nil
	end
	local okUri, uri = pcall(function()
		return value.Uri
	end)
	if okUri and type(uri) == "string" and uri ~= "" then
		return uri
	end
	return nil
end

function H.assetId(uri)
	if type(uri) ~= "string" then
		return nil
	end
	return tonumber(string.match(uri, "id=(%d+)") or string.match(uri, "rbxassetid://(%d+)") or string.match(uri, "^(%d+)$"))
end

function H.imageId(inst)
	return H.assetId(H.uri(inst, "ImageContent"))
end

function H.normalize(src)
	return (string.gsub(src or "", "\r\n", "\n"))
end

function H.has(src, needle)
	return string.find(src or "", needle, 1, true) ~= nil
end

-- Joints whose Part0/Part1 are nil or outside `root`.
function H.badJoints(root)
	local bad = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			for _, key in ipairs({ "Part0", "Part1" }) do
				local part = d[key]
				if part == nil or not (part == root or part:IsDescendantOf(root)) then
					table.insert(bad, d:GetFullName() .. "." .. key)
				end
			end
		end
	end
	return bad
end

function H.countClass(root, className)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA(className) then
			n += 1
		end
	end
	return n
end

-- World axis-aligned bounds of one BasePart (rotation aware): min, max (Vector3).
function H.aabb(part)
	local cf, half = part.CFrame, part.Size * 0.5
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ext = roblox.Vector3.new(
		math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z
	)
	local p = cf.Position
	return p - ext, p + ext
end

-- World bounds of every BasePart in `root` (and root itself): min, max, or nil when there is none.
function H.groupAabb(root)
	local mn, mx
	local function add(part)
		local a, b = H.aabb(part)
		if not mn then
			mn, mx = a, b
		else
			mn = roblox.Vector3.new(math.min(mn.X, a.X), math.min(mn.Y, a.Y), math.min(mn.Z, a.Z))
			mx = roblox.Vector3.new(math.max(mx.X, b.X), math.max(mx.Y, b.Y), math.max(mx.Z, b.Z))
		end
	end
	if root:IsA("BasePart") then
		add(root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			add(d)
		end
	end
	return mn, mx
end

-- Source text of a top-level `local function <name>(...) ... end` or of a forward-declared
-- `<name> = function(...) ... end` (the closing `end` at column 0), or nil.
function H.extractFunction(src, name)
	src = H.normalize(src)
	local start = string.find(src, "\nlocal function " .. name .. "%(")
	if not start then
		start = string.find(src, "\n" .. name .. " = function%(")
	end
	if not start then
		return nil
	end
	local finish = string.find(src, "\nend\n", start + 1, true) or string.find(src, "\nend$", start + 1)
	if not finish then
		return nil
	end
	return string.sub(src, start + 1, finish + 4)
end

-- Numeric value of a top-level `local NAME = <number>` constant, or nil.
function H.constant(src, name)
	return tonumber(string.match(H.normalize(src), "\nlocal " .. name .. "%s*=%s*(%-?[%d%.]+)"))
end

-- Loads `source` with `globals` layered over the Lune globals (free names in the chunk resolve to `globals`
-- first). Returns the chunk function or nil, err.
function H.sandbox(source, globals, debugName)
	local env = setmetatable(globals or {}, { __index = _G })
	local ok, chunk = pcall(luau.load, source, { debugName = debugName or "sandbox", environment = env })
	if not ok then
		return nil, chunk
	end
	return chunk, env
end

-- Minimal RBXScriptSignal stand-in for sandboxed product scripts.
function H.mockSignal()
	local signal = { handlers = {} }
	function signal:Connect(fn)
		table.insert(self.handlers, fn)
		return { Disconnect = function() end, Connected = true }
	end
	function signal:Fire(...)
		for _, fn in ipairs(self.handlers) do
			fn(...)
		end
	end
	return signal
end

-- Every LuaSourceContainer's Source, by full name (cached).
local sourcesCache = nil
function H.allSources()
	if sourcesCache == nil then
		sourcesCache = {}
		for _, d in ipairs(H.place():GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				sourcesCache[d:GetFullName()] = d.Source
			end
		end
	end
	return sourcesCache
end

---------------------------------------------------------------------------------------------------
-- Runner
---------------------------------------------------------------------------------------------------
local filters = process.args
local function selected(path)
	if #filters == 0 then
		return path ~= "tests/smoke.luau" -- the full run already covers the smoke checks
	end
	for _, f in ipairs(filters) do
		if string.find(path, f, 1, true) then
			return true
		end
	end
	return false
end

print("=============================================")
print(" STEAL A HERO — TEST SUITE v3 (6 stages)")
print(" place: " .. PLACE_PATH)
print("=============================================")

local results, anyFailed, ran = {}, false, 0
for _, path in ipairs(SUITES) do
	if selected(path) then
		ran += 1
		local T = { checks = 0, failures = {} }
		function T.check(cond, fmt, ...)
			T.checks += 1
			if not cond then
				table.insert(T.failures, string.format(fmt, ...))
			end
			return cond
		end
		local started = os.clock()
		local okLoad, chunk = pcall(luau.load, fs.readFile(path), {
			debugName = path,
			environment = setmetatable({ H = H, T = T }, { __index = _G }),
		})
		local okRun, err = false, chunk
		if okLoad then
			if H.PLAN == nil then
				okRun, err = false, PLAN_PATH .. " did not load"
			else
				okRun, err = pcall(chunk)
			end
		end
		if not okRun then
			table.insert(T.failures, "suite crashed: " .. tostring(err))
		end
		local passed = #T.failures == 0
		anyFailed = anyFailed or not passed
		table.insert(results, { path = path, T = T, passed = passed, seconds = os.clock() - started })
		print(string.format("\n[%s] %s  (%d checks, %d failed, %.1fs)", passed and "PASS" or "FAIL", path, T.checks, #T.failures, os.clock() - started))
		for i, msg in ipairs(T.failures) do
			if i > 40 then
				print(string.format("   ... and %d more", #T.failures - 40))
				break
			end
			print("   - " .. msg)
		end
	end
end

print("\n=============================================")
local total, failed = 0, 0
for _, r in ipairs(results) do
	total += r.T.checks
	failed += #r.T.failures
	print(string.format(" %s  %-28s %5d checks  %3d failed", r.passed and "PASS" or "FAIL", r.path, r.T.checks, #r.T.failures))
end
print(string.format(" %d suites, %d checks, %d failed", #results, total, failed))
print("=============================================")

if ran == 0 then
	print("no suite matched the filters: " .. table.concat(filters, ", "))
	process.exit(1)
end
if anyFailed then
	process.exit(1)
end
