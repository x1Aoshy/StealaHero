-- scripts/inject/treadmill.luau (TREADMILL owner)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- A plot's treadmill: the static, visual-only SpeedsterTreadmillDisplay baked by scripts/steps/treadmill.luau
-- (shown LOCKED until the owner buys the treadmill), then the bought render by TreadmillSpawnService (server,
-- everyone; it also drives the display's state) and by the owner's TreadmillStaticController (client), which
-- hides the server copy and the display on its own screen: exactly one treadmill per plot and viewer.
return {
	-- Also injected by the built-in controller block; listed here so the manifest fully describes
	-- the treadmill-owned sources (same file, same result). Adds the BaseUpgradeLevel purchase gate.
	{
		target = "ServerScriptService/Controllers/TreadmillGrindService",
		class = "ModuleScript",
		source = "src/ServerScriptService/Controllers/TreadmillGrindService.luau",
		create = false,
	},
	-- Base-place module (mirror == base Source modulo CRLF) + a refresh on each plot's BaseUpgradeLevel
	-- attribute, the FloorAligned grounding, the server-side rate sign text, the D6 display state
	-- (Locked / Unlocked / Hidden) of every plot's SpeedsterTreadmillDisplay, and CanQuery off on the skin's
	-- visual-only model parts (TreadmillDecor, GEKKO 2026-09-24 treadmill models).
	{
		target = "ServerScriptService/Controllers/TreadmillSpawnService",
		class = "ModuleScript",
		source = "src/ServerScriptService/Controllers/TreadmillSpawnService.luau",
		create = false,
	},
	-- Also injected by the built-in client block (same file). Hides the server copy and the static display
	-- of any plot this client renders itself, so the owner sees exactly one treadmill.
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillStaticController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillStaticController/init.client.luau",
		create = false,
	},
	-- Base-place module (mirror == base Source modulo CRLF) + the FloorAligned grounding, identical to
	-- TreadmillSpawnService's, so the owner's copy sits exactly where everyone else sees the server copy, and the
	-- same CanQuery rule for the skin's TreadmillDecor parts.
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillStaticController/Render",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillStaticController/Render.luau",
		create = false,
	},
	-- D7 lock (rule 4: base Source == the previous mirror, verified): pins the runner to the belt centre
	-- facing the console, AutoRotate off, movement input sunk, Y free (jump exits), Roblox's default run
	-- animation at Action priority; released on exit / death / reset / leaving the plot.
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillPositionLockController",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Plots/TreadmillPositionLockController.client.luau",
		create = false,
	},
	-- VISUAL_PASS_PLAN D4: the TikTok-style video player is removed. The module keeps its public API as no-ops
	-- (TreadmillUI still calls Start/Stop) and requires none of its removed children / GUIs. Also injected by
	-- scripts/inject/uiaudio.luau (same file, same result); listed so this manifest describes the treadmill sources.
	{
		target = "ReplicatedStorage/Library/Client/TreadmillVideoController",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/TreadmillVideoController/init.luau",
		create = false,
	},
	-- D4 training HUD (new): top-centre card with the gradient "+SPEED" counter, multiplier and milestone bar,
	-- driven by the ActiveTreadmillChanged session signal. Template: StarterGui.TreadmillTrainingHud
	-- (scripts/steps/ui_60_treadmill.luau).
	{
		target = "StarterPlayer/StarterPlayerScripts/GUI/TreadmillTrainingHud",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/GUI/TreadmillTrainingHud.client.luau",
		create = true,
	},
}
