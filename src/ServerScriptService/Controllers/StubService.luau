-- ServerScriptService.Controllers.StubService
-- Safety net for every RemoteFunction in ReplicatedStorage.Network that isn't backed by a
-- real system yet. A RemoteEvent left unconnected is harmless (FireServer is fire-and-forget),
-- but an un-set RemoteFunction.OnServerInvoke can hang or error the calling client forever --
-- so every remaining RemoteFunction gets an explicit, schema-plausible default response here.
--
-- This is intentionally shallow: it stops GUIs from spinning/hanging forever, it does NOT
-- implement Trading, FuseMachine, Guards, Trails, player-stealing (ActiveAssets), Products
-- (Robux), GroupReward, Treadmill comments/likes, or Index claiming. Those are
-- real, large systems that still need to be built system-by-system (same method as Plots/
-- Eggs: grep the ripped client for the exact contract before writing server code).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local StubService = {}

-- name -> function(player, ...) -> ...replies
local FAIL = function()
	return false, "Not available"
end
local FAIL_ONLY = function()
	return false
end
local EMPTY_TABLE = function()
	return {}
end
local NIL_VALUE = function()
	return nil
end

local HANDLERS = {
	-- ActiveAssets: equip/unequip/equip-limit/sell/runtime-snapshot are real now (AssetService).
	-- Stealing pets from other players' plots is NOT built.
	["ActiveAssets: RequestDnaStealAnimationComplete"] = FAIL_ONLY,
	["ActiveAssets: AcknowledgePenFullPetsBadge"] = FAIL_ONLY,
	["ActiveAssets: AcknowledgePenFullEquipBestBadge"] = FAIL_ONLY,
	["ActiveAssets: RequestStealTarget"] = FAIL,

	-- Backpack: EquipBest/GetEquipBestStatus/GetAutoSellState/SetAutoSellState are all real now
	-- (AssetService).

	-- OfflineAssets: GetSummary/Redeem are real now (OfflineAssetsService). IsStatePending
	-- stays here -- it's part of the Robux offline-multiplier upsell, not built (see that
	-- service's header) -- FAIL_ONLY (= false, no purchase pending) is the correct answer.
	["OfflineAssets: IsStatePending"] = FAIL_ONLY,

	-- AdminAbuse (event system query endpoints)
	["AdminAbuse_GetEventNames"] = EMPTY_TABLE,
	["AdminAbuse_GetActiveEvents"] = EMPTY_TABLE,
	["AdminAbuse_GetTimeUntilRecurringEvents"] = EMPTY_TABLE,
	["AdminAbuse_GetScheduledEvents"] = EMPTY_TABLE,

	-- Index: RequestClaim/RequestClaimAll are real now (IndexService). Area-bat trophy and the
	-- limited/seasonal egg reward are not built.
	["Index: RequestEquipAreaBat"] = FAIL,
	["Index: RequestClaimLimitedEggReward"] = FAIL,

	-- ClientCharacter (anti-cheat / character reconciliation)
	["ClientCharacter: Sync"] = EMPTY_TABLE,

	-- Analytics
	["Analytics:RequestAfkTeleportFlush"] = EMPTY_TABLE,
	["Analytics:ReportAfkTeleport"] = EMPTY_TABLE,

	-- Server luck / gamepass-style modifiers
	["ServerLuck:GetState"] = EMPTY_TABLE,

	-- Trading -- not built.
	["Server: Trading: Request"] = FAIL,
	["Server: Trading: Reject"] = FAIL_ONLY,
	["Server: Trading: Decline"] = FAIL_ONLY,
	["Server: Trading: Set Ready"] = FAIL_ONLY,
	["Server: Trading: Set Item"] = FAIL_ONLY,
	["Server: Trading: Message"] = FAIL_ONLY,
	["Server: Trading: Set Confirmed"] = FAIL_ONLY,

	-- Experiments / A-B flags
	["Experiments:Get"] = EMPTY_TABLE,

	-- FuseMachine: real now (FuseMachineService), see that module's header for the design
	-- decisions -- no authoritative fusion ruleset exists anywhere in the rip.

	-- GroupReward: ClaimReward is real now (GroupRewardService).
	-- Settings: Request Update is real now (SettingsService).
	-- Robux products -- not built.
	["Products: Request Prompt Purchase"] = FAIL,
	["Products: Request Server Test"] = FAIL,
	["Products: Whitelist Purchase"] = FAIL_ONLY,

	-- Trails -- not built.
	["Trails: RequestSelect"] = FAIL,
	["Trails: RequestUnequip"] = FAIL,
	["Trails: RequestActiveSnapshot"] = EMPTY_TABLE,
	["Trails: RequestPurchase"] = FAIL,

	-- Guard tutorial: RequestSyncProgress is real now (GuardTutorialService).

	-- Treadmill social features (comments/likes/media) -- not built. RequestCommentPage/
	-- RequestCommentCounts/RequestActiveRenderSnapshot used to reply with a bare {} -- the
	-- client validates responses against a strict schema (TreadmillMediaComments.Schema) or
	-- unpacks 2 return values (Asserts.array + Asserts.number), and {} satisfied neither,
	-- so every call logged "Rejected invalid treadmill comment counts response" or hard-
	-- asserted in TreadmillStaticController. These three now return schema-correct shapes.
	["Treadmills: RequestCommentPage"] = function()
		return { Ok = true, TotalCreatedCount = 0, Comments = {}, NextCursor = nil }
	end,
	["Treadmills: RequestCommentCounts"] = function()
		return { Ok = true, CountsByMediaKey = {}, Loaded = true, Stale = false }
	end,
	["Treadmills: RequestPostComment"] = FAIL,
	["Treadmills: RequestSetCommentLike"] = FAIL,
	-- Treadmills: RequestEquipStatic is real now (TreadmillGrindService) -- was FAILing every
	-- time a player stood near their own idle treadmill, logging "entry rejected: Not available".
	["Treadmills: RequestActiveRenderSnapshot"] = function()
		return {}, 0
	end,
	-- Treadmills: RequestUnequip is real now (TreadmillGrindService) -- jumping to get off the
	-- treadmill was calling this and getting FAIL back, so the exit never actually worked.
	["Treadmills: RequestLikeSnapshot"] = EMPTY_TABLE,
	["Treadmills: RequestFriendLikeSnapshot"] = EMPTY_TABLE,
	["Treadmills: RequestSetMediaLike"] = FAIL,
}

for name, handler in pairs(HANDLERS) do
	local remote = Network:FindFirstChild(name)
	if remote and remote:IsA("RemoteFunction") then
		remote.OnServerInvoke = function(player, ...)
			local ok, a, b, c = pcall(handler, player, ...)
			if not ok then
				warn("[StubService] Handler for '" .. name .. "' errored: " .. tostring(a))
				return false, "Server error"
			end
			return a, b, c
		end
	else
		warn("[StubService] Remote not found or not a RemoteFunction: " .. name)
	end
end

return StubService
