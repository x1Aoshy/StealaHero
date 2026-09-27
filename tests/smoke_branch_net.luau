--!nocheck
-- tests/smoke_branch_net.luau (owner 2026-09-27: "implement the Branch framework; bullet-proof network replication;
-- hyper-optimised client and server"). Joins the "smoke" filter. Checks, against the built place:
--   1. Branch 2.0.0 is installed at ReplicatedStorage.Packages.Branch (every module compiles), BranchServer / BranchClient
--      start the BranchServices / BranchControllers roots and every segment compiles;
--   2. NetGuardService, run in a sandbox: normal traffic passes, a sustained flood on one remote, a one-second burst and an
--      oversized payload each kick the sender, and leaving clears the counters;
--   3. the client segments: UiLifeController animates with engine tweens, PerfController caps plot billboards.

local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts

local branch = H.path(rs, "Packages/Branch")
local modules, broken = 0, {}
for _, m in ipairs(branch and { branch, table.unpack(branch:GetDescendants()) } or {}) do
	if m:IsA("ModuleScript") then
		modules += 1
		if not pcall(H.luau.compile, m.Source) then
			table.insert(broken, m:GetFullName())
		end
	end
end
T.check(branch ~= nil and modules >= 15 and #broken == 0 and H.has(branch.Source, 'Version = "2.0.0"'),
	"ReplicatedStorage.Packages.Branch (2.0.0) must be installed and compile (%d modules, broken: %s)", modules, table.concat(broken, ", "))
local server, client = sss:FindFirstChild("BranchServer"), sps:FindFirstChild("BranchClient")
T.check(server ~= nil and server:IsA("Script") and H.has(server.Source, "Branch:Start(script.Parent:WaitForChild(\"BranchServices\"))"),
	"ServerScriptService.BranchServer must start BranchServices")
T.check(client ~= nil and client:IsA("LocalScript") and H.has(client.Source, "Branch:Start(script.Parent:WaitForChild(\"BranchControllers\"))"),
	"StarterPlayerScripts.BranchClient must start BranchControllers")
for _, spec in ipairs({ { sss, "BranchServices", { "NetGuardService", "ServerStatsService" } },
	{ sps, "BranchControllers", { "UiLifeController", "PerfController" } } }) do
	for _, name in ipairs(spec[3]) do
		local m = H.path(spec[1], spec[2] .. "/" .. name)
		T.check(m ~= nil and m:IsA("ModuleScript") and pcall(H.luau.compile, m.Source), "%s.%s must be a compiling Branch segment", spec[2], name)
	end
end

-- 2. NetGuardService behaviour
local guardModule = H.path(sss, "BranchServices/NetGuardService")
if guardModule then
	local clock = 1000.2
	local fakeGame = { GetService = function(_, name)
		return { Name = name, GetDescendants = function() return {} end, DescendantAdded = H.mockSignal() }
	end }
	local chunk = H.sandbox(guardModule.Source, {
		game = fakeGame,
		os = { clock = function() return clock end },
		warn = function() end,
		typeof = function(v) return if type(v) == "table" and v.__instance then "Instance" else typeof(v) end,
	}, "NetGuardService")
	local ok, guard = pcall(chunk)
	if T.check(ok and type(guard) == "table" and type(guard._onEvent) == "function", "NetGuardService did not load in the sandbox: %s", tostring(guard)) then
		local function newPlayer(name)
			local p = { __instance = true, Name = name, UserId = 1, kicked = false }
			function p.Kick(self)
				self.kicked = true
			end
			return p
		end
		local remote = { GetFullName = function() return "ReplicatedStorage.Network.Test" end }
		local other = { GetFullName = function() return "ReplicatedStorage.Network.Other" end }
		-- normal play: 120 events/s on two remotes for 5 s
		local calm = newPlayer("Calm")
		for s = 0, 4 do
			clock = 1000.2 + s
			for _ = 1, 60 do
				guard._onEvent(remote, calm, 1, "x")
				guard._onEvent(other, calm, { a = 1 })
			end
		end
		T.check(not calm.kicked, "NetGuardService must let normal traffic through")
		-- sustained flood on one remote: 500/s for 4 s
		local flooder = newPlayer("Flood")
		for s = 10, 13 do
			clock = 1000.2 + s
			for _ = 1, 500 do
				guard._onEvent(remote, flooder)
			end
		end
		clock = 1000.2 + 14
		guard._onEvent(remote, flooder)
		T.check(flooder.kicked, "NetGuardService must kick a sustained flood on one remote")
		-- three separate bursts with quiet seconds between them are not a sustained flood
		local bursty = newPlayer("Bursty")
		for _, s in ipairs({ 20, 23, 26, 29 }) do
			clock = 1000.2 + s
			for _ = 1, 450 do
				guard._onEvent(remote, bursty)
			end
		end
		clock = 1000.2 + 32
		guard._onEvent(remote, bursty)
		T.check(not bursty.kicked, "NetGuardService must only count flood seconds in a row")
		-- one-second burst over every remote
		local burst = newPlayer("Burst")
		clock = 1100.2
		for _ = 1, 1000 do
			guard._onEvent(remote, burst)
		end
		T.check(burst.kicked, "NetGuardService must kick a burst over TOTAL_LIMIT")
		-- oversized payload
		local big = newPlayer("Big")
		clock = 1200.2
		guard._onEvent(remote, big, string.rep("a", 100001))
		T.check(big.kicked, "NetGuardService must kick an oversized payload")
		guard:PlayerRemoving(calm)
		T.check(guard.GetTraffic(calm) == nil, "NetGuardService must drop a leaving player's counters")
	end
end

-- 3. client segments
local life = H.path(sps, "BranchControllers/UiLifeController")
local lifeSrc = life and H.normalize(life.Source) or ""
T.check(H.has(lifeSrc, "TweenService:Create") and H.has(lifeSrc, "SpBreathe") and H.has(lifeSrc, "SpSweep") and H.has(lifeSrc, "isTopbar")
	and not H.has(lifeSrc, "RenderStepped"), "UiLifeController must animate with engine tweens (no per-frame loop) and skip the topbar")
local shop = H.path(place:GetService("StarterGui"), "Elements/Left/Tools/Shop/Button")
T.check(shop ~= nil and shop:GetAttribute("SpSweep") ~= nil, "the Shop button must carry its idle sweep (SpSweep)")
local perf = H.path(sps, "BranchControllers/PerfController")
T.check(perf ~= nil and H.has(perf.Source, "MaxDistance = PerfController.BILLBOARD_RANGE"), "PerfController must cap plot billboards")
