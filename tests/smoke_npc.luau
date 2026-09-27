--!nocheck
-- Smoke checks for the NPC pass (2026-09-26): players never collide with NPCs (collision groups Players / NPCs /
-- Guards / HoverProbe, Bootstrap), pen heroes never get stuck (wander simulation fixes, measured by
-- scripts/tools/sim_pen_wander.luau "stuck" / "retarget"), no invisible blockers in the world (static audit + the gear
-- tools that reached the world at runtime). Runs with the "smoke" filter.

local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local ws = place:GetService("Workspace")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local aac = sps and H.path(sps, "Game/Plots/ActiveAssetsController")

local function list(t)
	return table.concat(t, ", ", 1, math.min(#t, 6)) .. (if #t > 6 then string.format(" (+%d)", #t - 6) else "")
end

---------------------------------------------------------------------------------------------------
-- 1. Bootstrap, run in a sandbox with a PhysicsService / Players mock: the collision matrix it leaves and the
--    unconditional "Players" group on every character part. "NPCs" is registered beforehand (the hub podium registers
--    it defensively) and RegisterCollisionGroup errors on an existing name, like the engine.
---------------------------------------------------------------------------------------------------
local registered = { Default = true }
local rules = {}
local function pairKey(a, b)
	if a > b then
		a, b = b, a
	end
	return a .. "|" .. b
end
local function collidable(a, b)
	local v = rules[pairKey(a, b)]
	if v == nil then
		return true
	end
	return v
end
local PhysicsMock = {}
function PhysicsMock:IsCollisionGroupRegistered(name)
	return registered[name] == true
end
function PhysicsMock:RegisterCollisionGroup(name)
	if registered[name] then
		error("Collision group '" .. tostring(name) .. "' already registered")
	end
	registered[name] = true
end
function PhysicsMock:CollisionGroupSetCollidable(a, b, value)
	if not (registered[a] and registered[b]) then
		error("CollisionGroupSetCollidable on an unregistered group: " .. tostring(a) .. " / " .. tostring(b))
	end
	rules[pairKey(a, b)] = value
end
PhysicsMock:RegisterCollisionGroup("NPCs") -- the podium got there first

local PlayersMock = { PlayerAdded = H.mockSignal(), _list = {} }
function PlayersMock:GetPlayers()
	return self._list
end
local folderMock = {}
function folderMock:WaitForChild(name)
	return setmetatable({ Name = name }, { __index = folderMock })
end
function folderMock:FindFirstChild()
	return nil
end
function folderMock:GetFullName()
	return "Mock." .. tostring(self.Name)
end
local services = { PhysicsService = PhysicsMock, Players = PlayersMock, ServerScriptService = setmetatable({ Name = "SSS" }, { __index = folderMock }) }
local gameMock = {}
function gameMock:GetService(name)
	return assert(services[name], "Bootstrap sandbox: unexpected service " .. tostring(name))
end

local bootstrap = H.path(sss, "Bootstrap")
local bootOk, bootErr = false, "Bootstrap missing"
if bootstrap then
	local chunk, err = H.sandbox(bootstrap.Source, {
		game = gameMock,
		warn = function() end,
		require = function()
			return {}
		end,
	}, "Bootstrap")
	if chunk then
		bootOk, bootErr = pcall(chunk)
	else
		bootErr = err
	end
end
T.check(bootOk, "Bootstrap must run (with NPCs already registered by another script): %s", tostring(bootErr))
local missing = {}
for _, g in ipairs({ "Players", "NPCs", "Guards", "HoverProbe" }) do
	if not registered[g] then
		table.insert(missing, g)
	end
end
T.check(#missing == 0, "Bootstrap must register the collision groups: missing %s", list(missing))
local matrix = {
	{ "Players", "NPCs", false }, { "Players", "Guards", false }, { "Guards", "NPCs", false }, { "Guards", "Guards", false },
	{ "NPCs", "NPCs", false }, { "HoverProbe", "Guards", false }, { "Players", "Players", true }, { "Guards", "Default", true },
	{ "HoverProbe", "NPCs", true }, { "HoverProbe", "Default", true },
}
local wrong = {}
for _, m in ipairs(matrix) do
	if collidable(m[1], m[2]) ~= m[3] then
		table.insert(wrong, string.format("%s/%s should be %s", m[1], m[2], tostring(m[3])))
	end
end
T.check(#wrong == 0, "collision matrix: %s", list(wrong))

-- a player joins, spawns, then equips a tool: every part is "Players"
local function mockPart(isPart)
	return {
		CollisionGroup = "Default",
		IsA = function(_, className)
			return isPart and (className == "BasePart")
		end,
	}
end
local character = { _parts = { mockPart(true), mockPart(true), mockPart(false) }, DescendantAdded = H.mockSignal() }
function character:GetDescendants()
	return self._parts
end
local player = { CharacterAdded = H.mockSignal(), Character = nil }
local joinOk, joinErr = pcall(function()
	PlayersMock.PlayerAdded:Fire(player)
	player.Character = character
	player.CharacterAdded:Fire(character)
end)
local late = mockPart(true)
pcall(function()
	character.DescendantAdded:Fire(late)
end)
T.check(joinOk and character._parts[1].CollisionGroup == "Players" and character._parts[2].CollisionGroup == "Players"
	and late.CollisionGroup == "Players",
	"Bootstrap must put every character part (and parts added later) in the Players group, unconditionally: %s", tostring(joinErr))

-- the six stage villains are filed in "Guards" (all parts), so a sleeping villain never blocks a player
local villains, unfiled = 0, {}
for _, zone in ipairs((H.path(ws, "__OBJECTS/Areas/GuardAreas") or ws):GetChildren()) do
	local guard = zone:FindFirstChild("Guard")
	if guard and guard:IsA("Model") and zone.Parent and zone.Parent.Name == "GuardAreas" then
		villains += 1
		for _, d in ipairs(guard:GetDescendants()) do
			if d:IsA("BasePart") and d.CollisionGroup ~= "Guards" then
				table.insert(unfiled, zone.Name .. "." .. d.Name)
			end
		end
	end
end
T.check(villains == 6 and #unfiled == 0, "every villain part must be in the Guards collision group (%d villains): %s", villains, list(unfiled))

-- GuardChaseService stays self-sufficient and agrees (villains pass through NPCs too)
local chase = H.path(sss, "Controllers/GuardChaseService")
local ensure = chase and H.extractFunction(chase.Source, "ensureCollisionGroups") or ""
T.check(H.has(chase and chase.Source, 'local NPC_COLLISION_GROUP = "NPCs"') and H.has(ensure, "IsCollisionGroupRegistered(name)")
	and H.has(ensure, "CollisionGroupSetCollidable(GUARD_COLLISION_GROUP, NPC_COLLISION_GROUP, false)")
	and H.has(ensure, "CollisionGroupSetCollidable(PLAYER_COLLISION_GROUP, NPC_COLLISION_GROUP, false)"),
	"GuardChaseService.ensureCollisionGroups must register NPCs and keep Guards/NPCs and Players/NPCs non-colliding")

---------------------------------------------------------------------------------------------------
-- 2. Pen heroes: every part in "NPCs", never colliding (also parts added later); the hover raycast still sees them.
---------------------------------------------------------------------------------------------------
local itemDisplay = H.path(rs, "Library/Modules/ItemDisplay")
local idSrc = itemDisplay and H.normalize(itemDisplay.Source) or ""
local wander = string.match(idSrc, "function t1%.CreateWanderingAssetModel(.-)\nend\n") or ""
local setter = H.extractFunction(idSrc, "setNpcCollision") or ""
T.check(H.has(idSrc, 'local NPC_COLLISION_GROUP = "NPCs"') and H.has(setter, "part.CanCollide = false")
	and H.has(setter, "part.CollisionGroup = NPC_COLLISION_GROUP") and H.has(wander, "descendant.CanCollide = false")
	and H.has(wander, "setNpcCollision(descendant)") and H.has(wander, ".DescendantAdded:Connect(")
	and not H.has(wander, "CanCollide = true"),
	"ItemDisplay.CreateWanderingAssetModel must put every hero part (and later ones) in NPCs with CanCollide = false")

local hover = H.path(rs, "Library/Client/UI/ModelMouseHover")
local hoverGroup, hoverKey, hoverErr = nil, nil, "ModelMouseHover missing"
if hover then
	local asserts = setmetatable({}, {
		__index = function()
			return function() end
		end,
	})
	local model = { Parent = ws }
	local hit = { IsDescendantOf = function(_, m)
		return m == model
	end }
	local libraryMock = { Asserts = "ASSERTS", Types = { CollisionGroups = "COLLISION_GROUPS" } }
	local hoverServices = { ReplicatedStorage = { Library = libraryMock }, PhysicsService = PhysicsMock }
	local chunk, err = H.sandbox(hover.Source, {
		game = { GetService = function(_, name)
			return assert(hoverServices[name], "ModelMouseHover sandbox: unexpected service " .. tostring(name))
		end },
		require = function(target)
			if target == "ASSERTS" then
				return asserts
			end
			return { PLAYER_COLLISION_GROUP = "Players" }
		end,
		RaycastParams = { new = function()
			return {}
		end },
		workspace = {
			CurrentCamera = { ViewportPointToRay = function()
				return { Origin = H.roblox.Vector3.new(0, 10, 0), Direction = H.roblox.Vector3.new(0, -1, 0) }
			end },
			Raycast = function(_, _, _, params)
				hoverGroup = params.CollisionGroup
				-- the ray only reaches a hero when its group collides with the hero's group
				if collidable(params.CollisionGroup or "Default", "NPCs") then
					return { Instance = hit }
				end
				return nil
			end,
		},
	}, "ModelMouseHover")
	if chunk then
		local ok, module = pcall(chunk)
		if ok and type(module) == "table" then
			local okKey, key = pcall(module.GetHoveredKey, { hero = model }, H.roblox.Vector2.new(10, 10), 200)
			hoverKey, hoverErr = if okKey then key else nil, if okKey then nil else tostring(key)
		else
			hoverErr = tostring(module)
		end
	else
		hoverErr = tostring(err)
	end
end
T.check(hoverGroup == "HoverProbe" and hoverKey == "hero",
	"ModelMouseHover must raycast as HoverProbe (it ran as Players, which no longer sees NPC heroes): group %s, key %s, %s",
	tostring(hoverGroup), tostring(hoverKey), tostring(hoverErr))

---------------------------------------------------------------------------------------------------
-- 3. Heroes getting stuck: the wander fixes are in the built modules, and the pen simulation (the tool, sandboxed on
--    this place: a crowd with a terminal and two eggs, the owner strolls through then leaves) has no stuck hero.
---------------------------------------------------------------------------------------------------
local sim = aac and aac:FindFirstChild("AssetWanderSimulator")
local simSrc = sim and H.normalize(sim.Source) or ""
local space = aac and aac:FindFirstChild("AssetPenSpace")
local retreat = aac and aac:FindFirstChild("AssetRetreatMotion")
T.check(H.has(simSrc, "function t1._watchProgress(") and H.has(simSrc, "function t1._retreatReplan(")
	and H.has(simSrc, "function t1._beginCower(") and H.has(simSrc, "function t1._unstick(")
	and H.has(simSrc, "v157 ~= nil and p37:_tryRetreatFromOwner(cFrame, v157, n19)")
	and not H.has(simSrc, "(v157 == nil or p37:_tryRetreatFromOwner")
	and H.has(simSrc, "if p37:_watchProgress(n19, cFramePosition, followFar) then")
	and H.has(simSrc, "AssetPenSpace.Resolve(space, clamped, n19, halfX, halfZ)")
	and H.has(simSrc, "AssetPenSpace.PathClear(space, from, candidate)"),
	"AssetWanderSimulator must commit retreats, wander with the owner away, watch progress (walks, approaches, followers) and plan clear paths")
T.check(space ~= nil and H.has(space.Source, "function AssetPenSpace.PathClear(") and H.has(space.Source, "local function exitInside(")
	and retreat ~= nil and not H.has(retreat.Source, "return AssetWanderArea.RandomPoint(p3, p4, margin)"),
	"AssetPenSpace needs PathClear + a fence-aware Resolve; AssetRetreatMotion must not fall back to a random point when cornered")

local simResult, simErr = nil, "not run"
do
	local simPath = "scripts/tools/sim_pen_wander.luau"
	local placeToken = "<smoke_npc place>"
	local fakeRoblox = setmetatable({ deserializePlace = function()
		return place
	end }, { __index = H.roblox })
	local fakeFs = setmetatable({
		isFile = function(p)
			return p == placeToken or H.fs.isFile(p)
		end,
		readFile = function(p)
			if p == placeToken then
				return ""
			end
			return H.fs.readFile(p)
		end,
	}, { __index = H.fs })
	local fakeProcess = { args = { placeToken, "14", "40" }, env = {}, exit = function(code)
		error("sim_pen_wander exit " .. tostring(code), 0)
	end, simResultSink = function(result)
		simResult = result
	end }
	local env = {
		print = function() end,
		require = function(name)
			if name == "@lune/roblox" then
				return fakeRoblox
			elseif name == "@lune/fs" then
				return fakeFs
			elseif name == "@lune/luau" then
				return H.luau
			elseif name == "@lune/process" then
				return fakeProcess
			end
			error("sim sandbox: unexpected require " .. tostring(name))
		end,
	}
	if H.fs.isFile(simPath) then
		local chunk, err = H.sandbox(H.fs.readFile(simPath), env, "sim_pen_wander")
		if chunk then
			local ok, runErr = pcall(chunk)
			simErr = if ok then nil else tostring(runErr)
		else
			simErr = tostring(err)
		end
	end
	-- the tool adds a stand-in terminal and two eggs to the (shared) place: take them out again
	for _, d in ipairs(ws:GetDescendants()) do
		if d.Name == "SimTerminal" and d:IsA("BasePart") then
			d:Destroy()
		end
	end
	for _, d in ipairs(ws:GetChildren()) do
		if d.Name == "PlacedEggRenders" and d:IsA("Folder") and d:FindFirstChild("SimEgg1") then
			d:Destroy()
		end
	end
end
T.check(simResult ~= nil and simResult.polished, "sim_pen_wander must run on the built place: %s", tostring(simErr))
if simResult then
	T.check(simResult.stuck <= 0.005 and simResult.stuckLongest <= 5.0,
		"pen heroes get stuck: %.2f%% of hero-time, %d heroes, longest %.1f s (legacy 27%%, 34 s)", simResult.stuck * 100,
		simResult.stuckHeroes, simResult.stuckLongest)
	T.check(simResult.retarget <= 15, "pen heroes re-plan mid-walk %.1f times / hero-minute (the old retreat re-picked every frame)",
		simResult.retarget)
	T.check(simResult.fence == 0 and simResult.obstacle <= simResult.heroFrames * 0.002,
		"pen heroes cross the fence (%d frames) or stand in the terminal / eggs (%d frames)", simResult.fence, simResult.obstacle)
end

---------------------------------------------------------------------------------------------------
-- 4. Invisible blockers: the static Workspace audit (scripts/tools/audit_invisible_colliders.luau) finds only the legit
--    ones, nothing invisible-ish collides in the plots, and no gear tool part collides (held tools are part of the
--    character: the slap block snagged doorways).
---------------------------------------------------------------------------------------------------
local LEGIT = {
	"^Workspace%.StageEnvironments%.[^%.]+%.Boundary%.", -- stage map-edge walls, lined up with the visible walls
	"^Workspace%.StageEnvironments%.EndWall%.SideWalls%.",
	"^Workspace%.__OBJECTS%.Areas%.GuardAreas%.[^%.]+%.Guard%.Collider$", -- villain colliders: Guards group, never Players
}
local stray = {}
for _, d in ipairs(ws:GetDescendants()) do
	if d:IsA("BasePart") and d.CanCollide and d.Transparency >= 0.95 and not d:IsA("Terrain") then
		local name = d:GetFullName()
		local ok = d.CFrame.Position.Y < -20 -- base-place leftovers under the map (InvisibleRenderSpace, FuseMachine)
		for _, pattern in ipairs(LEGIT) do
			ok = ok or string.find(name, pattern) ~= nil
		end
		if not ok then
			table.insert(stray, name)
		end
	end
end
T.check(#stray == 0, "invisible colliders outside the legit list (stage edge walls, villain colliders, under-map leftovers): %s", list(stray))
local plots = ws:FindFirstChild("Plots")
local ghostly = {}
for _, d in ipairs(plots and plots:GetDescendants() or {}) do
	if d:IsA("BasePart") and d.CanCollide and d.Transparency >= 0.8 then
		table.insert(ghostly, d:GetFullName())
	end
end
T.check(plots ~= nil and #ghostly == 0, "near-invisible colliders in the plots: %s", list(ghostly))
local gearTools = rs:FindFirstChild("GearTools")
local collidingGear = {}
for _, d in ipairs(gearTools and gearTools:GetDescendants() or {}) do
	if d:IsA("BasePart") and d.CanCollide then
		table.insert(collidingGear, d:GetFullName())
	end
end
local gearService = H.path(sss, "GearService")
local prepare = gearService and H.extractFunction(gearService.Source, "prepareGearTool") or ""
T.check(gearTools ~= nil and #collidingGear == 0 and H.has(prepare, "descendant.CanCollide = false"),
	"gear tools must not collide (templates + GearService.prepareGearTool): %s", list(collidingGear))
