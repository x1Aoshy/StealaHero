-- scripts/inject/ui_windows.luau
-- UI-WINDOWS injection manifest (see scripts/build_stealahero.luau step 13b; CONTRACTS_PHASE3 D4).
return {
	{
		-- Base-place Source (extracted from "Steal An Egg with treadmill V2.rbxl"; the old mirror differed only by CRLF
		-- line endings) + the Speedsters window animation: slide from (0.5,0,1.28,0) with (0.24, Back, Out), ModalJuice
		-- pop, SpDim 1 -> 0.55, close (0.18, Quad, In). UIScale ownership, close routing and one-tab-at-a-time kept.
		target = "ReplicatedStorage/Library/Client/TabController",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/TabController.luau",
		create = false,
	},
	{
		-- New: close-button hover/press juice (Rotation only; ButtonFX keeps the scale) and the header-icon bounce.
		target = "ReplicatedStorage/Library/Client/SpeedstersWindowJuice",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/SpeedstersWindowJuice.luau",
		create = true,
	},
}
