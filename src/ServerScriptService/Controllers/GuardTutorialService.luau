-- ServerScriptService.Controllers.GuardTutorialService
-- Persists profile.GuardTutorialProgress. The tutorial itself is 100% client-authoritative
-- (StarterPlayer...GuardTutorialController.MilestoneAdapter checks real observable state --
-- egg inventory, position, equipped tools, etc. -- to decide when each step is satisfied); the
-- server's only job here is to store whatever the client resolved so a returning player resumes
-- instead of restarting from step 1. Contract confirmed by reading GuardTutorialController in
-- full (_syncProgress calls this with its locally-resolved {Completed, CurrentStepId}) and
-- Library.Types.GuardTutorial (exact Progress schema) directly -- not guessed.
--
-- Before this existed, "GuardTutorial: RequestSyncProgress" had no real handler (StubService's
-- generic fallback returns false), so _syncProgress always got nil back and the client queued a
-- retry every 0.5s FOREVER, and progress never actually persisted across sessions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Database = require(game.ServerScriptService.Library.Database)
local GuardTutorial = require(ReplicatedStorage.Library.Types.GuardTutorial)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestSyncProgressRemote = Network:WaitForChild("GuardTutorial: RequestSyncProgress")

RequestSyncProgressRemote.OnServerInvoke = function(player, progress)
	local pcallOk, validatorOk, validatorErr = pcall(GuardTutorial.SchemaValidation.Progress, progress)
	if not pcallOk then
		return false, "Invalid guard tutorial progress payload"
	end
	if not validatorOk then
		return false, "Invalid guard tutorial progress: " .. tostring(validatorErr)
	end

	local profile = Database.Get(player)
	if not profile then
		return false, "Profile not loaded"
	end

	local normalized = GuardTutorial.NormalizeProgress(progress)
	profile.GuardTutorialProgress = normalized
	Database.Set(player, { GuardTutorialProgress = normalized })

	return true, normalized
end

return {}
