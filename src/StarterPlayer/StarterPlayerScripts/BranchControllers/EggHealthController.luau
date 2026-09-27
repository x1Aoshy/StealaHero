-- StarterPlayer.StarterPlayerScripts.BranchControllers.EggHealthController (Branch controller; injected by
-- scripts/inject/branch.luau, started by StarterPlayerScripts.BranchClient)
-- Owner 2026-09-27: "the eggs no longer appear, the stages are empty". The server had spawned every egg and the client
-- log said nothing. This watches the client side from outside the egg script: CHECK_AFTER seconds after joining (and
-- again whenever eggs exist but none are drawn), it logs one line with what the egg client has done
--   - whether Game.AreaEggs is in PlayerScripts and enabled;
--   - the start-up step it reached (attribute AreaEggsStage, "ready" once it started);
--   - how many egg records the client holds (Library.Client.EggCmds) and how many egg models are drawn
--     (Workspace.AreaEggSlotsClient).
-- Silent while everything is fine: it only writes when the stages should show eggs and show none.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EggHealthController = {}

EggHealthController.CHECK_AFTER = 20
EggHealthController.RECHECK_EVERY = 60

local function describe()
	local player = Players.LocalPlayer
	local scripts = player:FindFirstChildOfClass("PlayerScripts")
	local gameFolder = scripts and scripts:FindFirstChild("Game")
	local eggScript = gameFolder and gameFolder:FindFirstChild("AreaEggs")
	local stage = player:GetAttribute("AreaEggsStage")
	local records = -1
	local ok, count = pcall(function()
		local EggCmds = require(ReplicatedStorage.Library.Client.EggCmds)
		return #EggCmds.GetAreaEggSnapshot().Records
	end)
	if ok then
		records = count
	end
	local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
	local drawn = folder and #folder:GetChildren() or -1
	return {
		script = if eggScript then (if eggScript:IsA("LocalScript") and eggScript.Enabled then "enabled" else "DISABLED") else "MISSING",
		stage = if type(stage) == "string" then stage else "never started",
		records = records,
		drawn = drawn,
	}
end
EggHealthController._describe = describe

local function check()
	local state = describe()
	if state.stage == "ready" and (state.records <= 0 or state.drawn > 0) then
		return true -- started, and either nothing to draw yet or eggs are drawn
	end
	warn(string.format("[EggHealth] egg client: script %s, start-up step '%s', %d egg records, %d egg models drawn",
		state.script, state.stage, state.records, state.drawn))
	return false
end

function EggHealthController:Start()
	task.spawn(function()
		task.wait(EggHealthController.CHECK_AFTER)
		while true do
			local ok, healthy = pcall(check)
			if not ok then
				warn("[EggHealth] check failed: " .. tostring(healthy))
			end
			task.wait(EggHealthController.RECHECK_EVERY)
		end
	end)
end

return EggHealthController
