-- scripts/inject/hud_polish.luau (owner 2026-09-27, 5th pass)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b. The base-place script, patched (its src mirror
-- was checked equal to the base Source before the change):
--   GUI/MoneyUpdate   the floating "+$" amounts only show with the ShowMoneyPopups setting on (off by default;
--                     Shared.Variables.SettingsInfo, row in GUI/Settings).
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/MoneyUpdate",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/MoneyUpdate.client.luau",
		create = false,
	},
}
