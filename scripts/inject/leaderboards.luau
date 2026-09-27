-- scripts/inject/leaderboards.luau (LEAD, BOARDS, then HEROBOARD 2026-09-26)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- LeaderboardService (server Script): fills every page of the hub's HERO BOARD built by
-- scripts/steps/post_x_hero_board.luau (TOTAL NETWORTH, TOTAL SPEED, IN-GAME TIME, EGGS HATCHED: OrderedDataStore
-- global top + the players in the server), stands the TOTAL NETWORTH top 3's avatars on the podium and accumulates the
-- persisted TimePlayed stat server-side.
-- HeroBoard (LocalScript): the board's tab ClickDetectors switch the visible page for the local player only.
return {
	{
		target = "ServerScriptService/LeaderboardService",
		class = "Script",
		source = "src/ServerScriptService/LeaderboardService.server.luau",
		create = true,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/HeroBoard",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/HeroBoard.client.luau",
		create = true,
	},
}
