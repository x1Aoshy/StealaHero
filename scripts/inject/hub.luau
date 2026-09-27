-- Injection manifest (HUB3D, docs/VISUAL_PASS_PLAN.md D6). See scripts/build_stealahero.luau step 13b.
-- One new client script: a click on the hub's "CLICK TO CLAIM" board or gift chest (Workspace.Hub.FreeGift,
-- built by scripts/steps/post_hub_remodel.luau) opens the existing Free Gift window (StarterGui.GroupReward).
-- No base-place script is patched.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/HubFreeGift",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/HubFreeGift.client.luau",
		create = true,
	},
}
