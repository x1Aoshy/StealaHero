-- ReplicatedStorage.Directory.WeaponAnimations.GomuFist (GENERATED - do not edit by hand)
-- Authored in scripts/tools/hero_weapons/author_weapon_clips.py (Gomu_Pistol_Long), hero clip Format 1
-- (ReplicatedStorage.Library.Modules.HeroClipMath). Played on the attacker by
-- StarterPlayerScripts.BranchControllers.HeroWeaponController; the server (GearService) resolves the hit at
-- Impact seconds. Keys: { time, easing, qx, qy, qz, qw [, px, py, pz] }.

return {
	Format = 1,
	WeaponId = "GomuFist",
	Clip = "Gomu_Pistol_Long",
	Length = 0.72,
	Impact = 0.28,
	Release = 0.28,
	Loop = false,
	Stretch = { { 0, 1 }, { 0.2, 1 }, { 0.28, 7.5 }, { 0.42, 7.5 }, { 0.54, 2 }, { 0.64, 1 }, { 0.72, 1 } },
	Tracks = {
		Root = { { 0, "sine_inout", 0, 0, 0, 1, 0, 0, 0 }, { 0.16, "quad_in", -0.03447, -0.15634, 0.00546, 0.98709, 0, -0.3, 0.2 }, { 0.24, "quad_out", -0.05221, 0.06966, -0.00365, 0.9962, 0, -0.3, -0.3 }, { 0.44, "sine_inout", -0.04351, 0.06969, -0.00304, 0.99661, 0, -0.28, -0.25 }, { 0.72, "linear", 0, 0, 0, 1, 0, 0, 0 } },
		Waist = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", -0.03401, -0.22481, 0.00785, 0.97378 }, { 0.24, "quad_out", -0.03437, 0.17354, -0.00606, 0.98421 }, { 0.44, "sine_inout", -0.03437, 0.17354, -0.00606, 0.98421 }, { 0.72, "linear", 0, 0, 0, 1 } },
		Neck = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", 0, 0.25882, 0, 0.96593 }, { 0.24, "quad_out", 0, -0.15643, 0, 0.98769 }, { 0.44, "sine_inout", 0, -0.15643, 0, 0.98769 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftShoulder = { { 0, "sine_inout", 0, 0, -0.05234, 0.99863 }, { 0.16, "quad_in", 0.57139, 0.04999, -0.07139, 0.81603 }, { 0.24, "quad_out", 0.16318, 0.05939, -0.33682, 0.92542 }, { 0.44, "sine_inout", 0.16318, 0.05939, -0.33682, 0.92542 }, { 0.72, "linear", 0, 0, -0.05234, 0.99863 } },
		LeftElbow = { { 0, "sine_inout", 0.06976, 0, 0, 0.99756 }, { 0.16, "quad_in", 0.17365, 0, 0, 0.98481 }, { 0.24, "quad_out", 0.5, 0, 0, 0.86603 }, { 0.44, "sine_inout", 0.5, 0, 0, 0.86603 }, { 0.72, "linear", 0.06976, 0, 0, 0.99756 } },
		RightShoulder = { { 0, "sine_inout", 0.57218, -0.04001, 0.05714, 0.81716 }, { 0.16, "quad_in", 0.24321, -0.08852, 0.33037, 0.90767 }, { 0.24, "quad_out", 0.70442, -0.06163, 0.29884, 0.64086 }, { 0.44, "sine_inout", 0.70442, -0.06163, 0.29884, 0.64086 }, { 0.72, "linear", 0.57218, -0.04001, 0.05714, 0.81716 } },
		RightElbow = { { 0, "sine_inout", 0.19081, 0, 0, 0.98163 }, { 0.16, "quad_in", 0.81915, 0, 0, 0.57358 }, { 0.24, "quad_out", 0, 0, 0, 1 }, { 0.44, "sine_inout", 0, 0, 0, 1 }, { 0.72, "linear", 0.19081, 0, 0, 0.98163 } },
		RightWrist = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", 0, 0, 0, 1 }, { 0.24, "quad_out", 0, 0, 0, 1 }, { 0.44, "sine_inout", 0, 0, 0, 1 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftHip = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", 0.25846, 0.01355, -0.05055, 0.9646 }, { 0.24, "quad_out", 0.34155, 0.0179, -0.04918, 0.9384 }, { 0.44, "sine_inout", 0.34155, 0.0179, -0.04918, 0.9384 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftKnee = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", -0.25882, 0, 0, 0.96593 }, { 0.24, "quad_out", -0.34202, 0, 0, 0.93969 }, { 0.44, "sine_inout", -0.34202, 0, 0, 0.93969 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftAnkle = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", 0.08716, 0, 0, 0.99619 }, { 0.24, "quad_out", 0.12187, 0, 0, 0.99255 }, { 0.44, "sine_inout", 0.12187, 0, 0, 0.99255 }, { 0.72, "linear", 0, 0, 0, 1 } },
		RightHip = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", -0.10439, 0.00547, 0.05205, 0.99316 }, { 0.24, "quad_out", -0.17341, 0.00909, 0.05154, 0.98346 }, { 0.44, "sine_inout", -0.17341, 0.00909, 0.05154, 0.98346 }, { 0.72, "linear", 0, 0, 0, 1 } },
		RightKnee = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", -0.22495, 0, 0, 0.97437 }, { 0.24, "quad_out", -0.13917, 0, 0, 0.99027 }, { 0.44, "sine_inout", -0.13917, 0, 0, 0.99027 }, { 0.72, "linear", 0, 0, 0, 1 } },
		RightAnkle = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.16, "quad_in", 0.06976, 0, 0, 0.99756 }, { 0.24, "quad_out", 0.05234, 0, 0, 0.99863 }, { 0.44, "sine_inout", 0.05234, 0, 0, 0.99863 }, { 0.72, "linear", 0, 0, 0, 1 } },
	},
}
