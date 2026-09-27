-- ServerScriptService.NetworkInit
-- Ensures ReplicatedStorage.Network exists and populates all RemoteEvents and RemoteFunctions
-- so client and server controllers never hang on WaitForChild().

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local networkFolder = ReplicatedStorage:FindFirstChild("Network")
if not networkFolder then
	networkFolder = Instance.new("Folder")
	networkFolder.Name = "Network"
	networkFolder.Parent = ReplicatedStorage
end

local REMOTE_FUNCTIONS = {
	-- Plots
	"Plots: RequestState",
	
	-- Eggs
	"Eggs: RequestRuntimeSnapshot",
	"Eggs: RequestEggRecord",
	"Eggs: RequestEquipTool",
	"Eggs: RequestUnequipTool",
	"Eggs: RequestPlaceEgg",
	"Eggs: RequestSkipGrowth",
	"Eggs: RequestHatchEgg",
	"Eggs: RequestCompleteHatchEgg",
	"Eggs: RequestAreaEggSnapshot",
	"Eggs: RequestAreaEggRareSpawnPresentations",
	"Eggs: RequestAreaEggCarry",
	"Eggs: RequestAreaEggDrop",
	
	-- Active Assets / Heroes
	"ActiveAssets: RequestRuntimeSnapshot",
	"ActiveAssets: RequestEquip",
	"ActiveAssets: RequestUnequip",
	"ActiveAssets: RequestEquipLimit",
	"ActiveAssets: RequestSell",
	"ActiveAssets: RequestStealTarget",
	"ActiveAssets: RequestDnaStealAnimationComplete",
	"ActiveAssets: AcknowledgePenFullPetsBadge",
	"ActiveAssets: AcknowledgePenFullEquipBestBadge",
	
	-- Treadmills
	"Treadmills: RequestGetSlowToggleState",
	"Treadmills: RequestSetSlowToggleEnabled",
	"Treadmills: RequestUpgrade",
	"Treadmills: RequestEquipStatic",
	"Treadmills: RequestUnequip",
	"Treadmills: RequestActiveRenderSnapshot",
	"Treadmills: RequestCommentPage",
	"Treadmills: RequestCommentCounts",
	"Treadmills: RequestPostComment",
	"Treadmills: RequestSetCommentLike",
	"Treadmills: RequestLikeSnapshot",
	"Treadmills: RequestFriendLikeSnapshot",
	"Treadmills: RequestSetMediaLike",
	
	-- Backpack / Inventory
	"Backpack: GetAutoSellState",
	"Backpack: SetAutoSellState",
	"Backpack: EquipBest",
	"Backpack: GetEquipBestStatus",
	
	-- Stats / Offline
	"Get Stats",
	"ServerLuck:GetState",
	"OfflineAssets: GetSummary",
	"OfflineAssets: Redeem",
	"OfflineAssets: IsStatePending",
	
	-- Trails
	"Trails: RequestSelect",
	"Trails: RequestUnequip",
	"Trails: RequestActiveSnapshot",
	"Trails: RequestPurchase",
	
	-- Index / Rewards
	"Index: RequestClaim",
	"Index: RequestClaimAll",
	"Index: RequestEquipAreaBat",
	"Index: RequestClaimLimitedEggReward",
	"GroupReward: ClaimReward",
	"Settings: Request Update",
	"GuardTutorial: RequestSyncProgress",
	
	-- Products
	"Products: Request Prompt Purchase",
	"Products: Request Server Test",
	"Products: Whitelist Purchase",
	"Products: Gifting",
	"Products: Clear Gifting",
	"ClientCharacter: Sync",
	"Experiments:Get",
	"FuseMachine: InsertMob",
	"FuseMachine: RemoveMob",
	"FuseMachine: StartFuse",
	"FuseMachine: CompleteReveal",
	"FuseMachine: AcknowledgeInfo",
	"AdminAbuse_GetEventNames",
	"AdminAbuse_GetActiveEvents",
	"AdminAbuse_GetTimeUntilRecurringEvents",
	"AdminAbuse_GetScheduledEvents",
	"Analytics:RequestAfkTeleportFlush",
	"Analytics:ReportAfkTeleport",
}

local REMOTE_EVENTS = {
	-- Plots
	"Plots: StateUpdate",
	"Plots: RequestBaseUpgrade",
	"Plots: OnBaseUpgraded",
	"Plots: RequestLobbyTeleport",
	"Plots: DisableBaseHighlight",
	
	-- Eggs
	"Eggs: RuntimeOwnerUpdated",
	"Eggs: RuntimeOwnerCleared",
	"Eggs: AreaEggUpdated",
	"Eggs: AreaEggBatchUpdated",
	"Eggs: AreaEggRemoved",
	"Eggs: AreaEggCarryState",
	"Eggs: AreaEggClaimFeedback",
	"Eggs: AreaEggResetStartCountdown",
	
	-- Active Assets / Heroes
	"ActiveAssets: RuntimeOwnerUpdated",
	"ActiveAssets: RuntimeOwnerCleared",
	"ActiveAssets: MoneyCollected",
	"ActiveAssets: StealTargetEvent",
	"AssetInventory: SellAsset",
	"AssetInventory: SellAllAssets",
	"AssetInventory: SetFavorite",
	
	-- Guards / Villains
	"Guards: ForestHit",
	"Guards: ForestDeposit",
	"Guards: WakeUp",
	"Guards: SpeedHitWarning",
	"Guards: SpeedHitOffer",
	"Guards: ServerHit",

	-- Treadmills
	"Treadmills: ActiveTreadmillChanged",
	"Treadmills: ActiveRenderStateChanged",
	"Treadmills: SpeedGain",
	"Treadmills: UpdateMediaIndex",
	
	-- Trails
	"Trails: ActiveTrailChanged",
	
	-- Stats & UI
	"New Stats",
	"PlaySound",
	"Notifications_Show",
	"Setting Changed",
	"OfflineAssets: Claimed",
	"OfflineAssets: SummaryUpdated",
	"Experiments:Update",
	"GearInventory: Added",
	"GearInventory: Removed",
	"Products: Granted",
	"Products: Receipt Processed",
	"ClientCharacter: Update",
	"ClientCharacter: Ready",
	"ClientCharacter: CorrectionStarted",
	"ClientCharacter: IntegrityViolation",
	"ClientCharacter: IntegrityHeartbeat",
	"ClientCharacter: RequestCharacterReset",
	"Analytics:ReportAfkState",
	
	-- Admin
	"AdminPanel_GiveAssetToSelf",
	"AdminPanel_GiveEggToSelf",
	"AdminPanel_CheckAdminStatus",
	"AdminPanel_ResetSelfData",
	"AdminPanel_SetWalkSpeed",
	"AdminPanel_SetSpeedPower",
	"AdminPanel_AdminStatusResponse",
	
	-- Tools / Traps
	"Magnet: RequestPull",
	"BoogieBomb: RequestBoogie",
	"BodySwap: RequestSwap",
	"SubspaceMine: RequestPlace",
	"Traps:RequestPlace",
	"Megaphone: RequestActivate",
	"LaserCap: RequestFire",
	"Bat:Activate",
}

for _, name in ipairs(REMOTE_FUNCTIONS) do
	local existing = networkFolder:FindFirstChild(name)
	if not existing then
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = networkFolder
	end
end

for _, name in ipairs(REMOTE_EVENTS) do
	local existing = networkFolder:FindFirstChild(name)
	if not existing then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = networkFolder
	end
end

-- Server handlers for RemoteFunctions no controller owns. A RemoteFunction without
-- OnServerInvoke makes the client's Network.Invoke yield forever.
local SERVER_HANDLERS = {
	-- Library.Shared.Functions.PromptPurchase gifting flow: gifting is not offered in this game,
	-- so refuse cleanly (the client shows the message) instead of hanging the purchase prompt.
	["Products: Gifting"] = function(_player)
		return false, "Gifting is not available"
	end,
	["Products: Clear Gifting"] = function(_player)
		return true
	end,
}

for name, handler in pairs(SERVER_HANDLERS) do
	local remote = networkFolder:FindFirstChild(name)
	if remote and remote:IsA("RemoteFunction") then
		remote.OnServerInvoke = handler
	else
		warn("[NetworkInit] Cannot bind handler, RemoteFunction missing: " .. name)
	end
end

print(string.format("[NetworkInit] Verified %d RemoteFunctions and %d RemoteEvents in ReplicatedStorage.Network", #REMOTE_FUNCTIONS, #REMOTE_EVENTS))
