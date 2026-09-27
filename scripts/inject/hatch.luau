-- scripts/inject/hatch.luau (HATCH owner, 2026-09-23)
-- Injection manifest consumed by scripts/build_stealahero.luau step 13b.
-- EggHatchAnimation: owner "Make the egg not pop out loads of bricks when opened". t1.Play keeps the hatch flow,
-- timings and API but replaces the EggExplode brick-shard burst with a scale-pop, a flash and particles only.
-- Source = base-place Source (checked equal, CRLF-normalised) + that patch (see the note above t1.Play).
return {
	{
		target = "ReplicatedStorage/Library/Client/Eggs/EggHatchAnimation",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/Eggs/EggHatchAnimation.luau",
		create = false,
	},
}
