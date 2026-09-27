-- Injection manifest (HUB LAYOUT pass 2026-09-26). See scripts/build_stealahero.luau step 13b.
-- One new client script: the Hero Park's prompts (Workspace.Hub.HeroPark, built by scripts/steps/post_hub_zlayout.luau):
-- the fountain's coin toss, the statues' Hall of Heroes card (StarterGui.HeroParkCard, scripts/steps/ui_85_hero_park.luau)
-- and the trophy cheer. Cosmetic only; no base-place script is patched.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/HeroPark",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/HeroPark.client.luau",
		create = true,
	},
}
