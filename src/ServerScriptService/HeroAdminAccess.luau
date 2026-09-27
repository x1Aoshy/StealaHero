-- ServerScriptService.HeroAdminAccess (ModuleScript; injected by scripts/inject/admin_panel.luau)
-- Owner 2026-09-27: "an admin panel for the devs ... only user 767108248 and the owners or people with Studio access can
-- have it in game". The ONE place the rule lives; ServerScriptService.BranchServices.HeroAdminService asks it when a
-- player joins (to hand out the panel) and again on every command. A player is a Hero admin when:
--   * the server runs in Roblox Studio (RunService:IsStudio(): whoever can open the place in Studio already has it), or
--   * their UserId is in USER_IDS (767108248), or
--   * they own the game: a user-owned game's creator (game.CreatorId), or rank 255 (the owner) in the group that owns it.
-- The group rank is a web call: it is read once per player (pcall'd; a failed read is retried on the next check, never
-- cached as "no") and kept for the session. This list is independent of every older admin system of the base place
-- (AdminStatusHandler, CmdrAdminHandler, TrollFreeAdmin, the Hud AdminPanel): none of their whitelists are read here.
--
--   HeroAdminAccess.IsAdmin(player) -> boolean, reason ("studio" | "user" | "owner" | "group owner" | nil)
--   HeroAdminAccess.ATTRIBUTE      the Player attribute the service sets for admins (the client only uses it to show the
--                                  topbar icon; every command is checked again here)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HeroAdminAccess = {}

HeroAdminAccess.ATTRIBUTE = "HeroAdmin"
HeroAdminAccess.USER_IDS = {
	[767108248] = true,
}
HeroAdminAccess.GROUP_OWNER_RANK = 255

local groupRanks = {} -- [UserId] = rank read from the owning group (successful reads only)

local function isPlayer(player)
	return typeof(player) == "Instance" and player:IsA("Player") and player.Parent == Players
end

local function groupRank(player, groupId)
	local cached = groupRanks[player.UserId]
	if cached ~= nil then
		return cached
	end
	local ok, rank = pcall(player.GetRankInGroup, player, groupId)
	if ok and type(rank) == "number" then
		groupRanks[player.UserId] = rank
		return rank
	end
	return 0
end

function HeroAdminAccess.IsAdmin(player)
	if not isPlayer(player) then
		return false, nil
	end
	if RunService:IsStudio() then
		return true, "studio"
	end
	if HeroAdminAccess.USER_IDS[player.UserId] == true then
		return true, "user"
	end
	local creatorId = game.CreatorId
	if type(creatorId) ~= "number" or creatorId <= 0 then
		return false, nil
	end
	if game.CreatorType == Enum.CreatorType.User then
		if player.UserId == creatorId then
			return true, "owner"
		end
	elseif game.CreatorType == Enum.CreatorType.Group then
		if groupRank(player, creatorId) >= HeroAdminAccess.GROUP_OWNER_RANK then
			return true, "group owner"
		end
	end
	return false, nil
end

function HeroAdminAccess.Forget(player)
	if typeof(player) == "Instance" then
		groupRanks[player.UserId] = nil
	end
end

return HeroAdminAccess
