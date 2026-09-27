-- Injection manifest (NOGROUP): the base place's GroupRewards LocalScript with the join-group prompt spam removed
-- (no 3 s / every-5-min GroupService:PromptJoinAsync auto-nudge, no prompt from the Claim button). The World/HUD
-- entry points of the group ad are neutralised by scripts/steps/nogroup.luau.
return {
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/GroupRewards",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/GroupRewards.client.luau",
		create = false,
	},
}
