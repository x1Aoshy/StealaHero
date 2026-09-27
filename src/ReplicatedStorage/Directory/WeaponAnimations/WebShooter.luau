-- ReplicatedStorage.Directory.WeaponAnimations.WebShooter (GENERATED - do not edit by hand)
-- Authored in scripts/tools/hero_weapons/author_weapon_clips.py (Web_Thwip), hero clip Format 1
-- (ReplicatedStorage.Library.Modules.HeroClipMath). Played on the attacker by
-- StarterPlayerScripts.BranchControllers.HeroWeaponController; the server (GearService) resolves the hit at
-- Impact seconds. Keys: { time, easing, qx, qy, qz, qw [, px, py, pz] }.

return {
	Format = 1,
	WeaponId = "WebShooter",
	Clip = "Web_Thwip",
	Length = 0.55,
	Impact = 0.16,
	Release = 0.16,
	Loop = false,
	Tracks = {
		Root = { { 0, "quad_out", 0, 0, 0, 1, 0, 0, 0 }, { 0.1, "quad_out", -0.03481, 0.06971, -0.00243, 0.99696, 0, -0.18, 0 }, { 0.16, "quad_out", -0.03481, 0.06971, -0.00243, 0.99696, 0, -0.18, 0 }, { 0.26, "sine_inout", 0.01741, 0.06975, 0.00122, 0.99741, 0, -0.14, 0.12 }, { 0.55, "linear", 0, 0, 0, 1, 0, 0, 0 } },
		Waist = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", -0.01739, 0.08714, -0.00152, 0.99604 }, { 0.16, "quad_out", -0.01739, 0.08714, -0.00152, 0.99604 }, { 0.26, "sine_inout", -0.01739, 0.08714, -0.00152, 0.99604 }, { 0.55, "linear", 0, 0, 0, 1 } },
		Neck = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", 0, -0.10453, 0, 0.99452 }, { 0.16, "quad_out", 0, -0.10453, 0, 0.99452 }, { 0.26, "sine_inout", 0, -0.10453, 0, 0.99452 }, { 0.55, "linear", 0, 0, 0, 1 } },
		LeftShoulder = { { 0, "quad_out", 0, 0, -0.05234, 0.99863 }, { 0.1, "quad_out", 0.25489, 0.04494, -0.16773, 0.95125 }, { 0.16, "quad_out", 0.25489, 0.04494, -0.16773, 0.95125 }, { 0.26, "sine_inout", 0.25489, 0.04494, -0.16773, 0.95125 }, { 0.55, "linear", 0, 0, -0.05234, 0.99863 } },
		LeftElbow = { { 0, "quad_out", 0.06976, 0, 0, 0.99756 }, { 0.1, "quad_out", 0.5, 0, 0, 0.86603 }, { 0.16, "quad_out", 0.5, 0, 0, 0.86603 }, { 0.26, "sine_inout", 0.5, 0, 0, 0.86603 }, { 0.55, "linear", 0.06976, 0, 0, 0.99756 } },
		RightShoulder = { { 0, "quad_out", 0.57218, -0.04001, 0.05714, 0.81716 }, { 0.1, "quad_out", 0.73124, -0.01276, 0.0119, 0.68189 }, { 0.16, "quad_out", 0.75459, -0.01317, 0.01145, 0.65596 }, { 0.26, "sine_inout", 0.78789, -0.01375, 0.01074, 0.61557 }, { 0.55, "linear", 0.57218, -0.04001, 0.05714, 0.81716 } },
		RightElbow = { { 0, "quad_out", 0.19081, 0, 0, 0.98163 }, { 0.1, "quad_out", 0.01745, 0, 0, 0.99985 }, { 0.16, "quad_out", 0, 0, 0, 1 }, { 0.26, "sine_inout", 0.12187, 0, 0, 0.99255 }, { 0.55, "linear", 0.19081, 0, 0, 0.98163 } },
		RightWrist = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", -0.08716, 0, 0, 0.99619 }, { 0.16, "quad_out", 0.43837, 0, 0, 0.89879 }, { 0.26, "sine_inout", 0.25882, 0, 0, 0.96593 }, { 0.55, "linear", 0, 0, 0, 1 } },
		LeftHip = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", -0.06971, -0.00243, -0.03481, 0.99696 }, { 0.16, "quad_out", -0.06971, -0.00243, -0.03481, 0.99696 }, { 0.26, "sine_inout", -0.06971, -0.00243, -0.03481, 0.99696 }, { 0.55, "linear", 0, 0, 0, 1 } },
		LeftKnee = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", -0.12187, 0, 0, 0.99255 }, { 0.16, "quad_out", -0.12187, 0, 0, 0.99255 }, { 0.26, "sine_inout", -0.12187, 0, 0, 0.99255 }, { 0.55, "linear", 0, 0, 0, 1 } },
		LeftAnkle = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", 0.0349, 0, 0, 0.99939 }, { 0.16, "quad_out", 0.0349, 0, 0, 0.99939 }, { 0.26, "sine_inout", 0.0349, 0, 0, 0.99939 }, { 0.55, "linear", 0, 0, 0, 1 } },
		RightHip = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", 0.10446, -0.00365, 0.03471, 0.99392 }, { 0.16, "quad_out", 0.10446, -0.00365, 0.03471, 0.99392 }, { 0.26, "sine_inout", 0.10446, -0.00365, 0.03471, 0.99392 }, { 0.55, "linear", 0, 0, 0, 1 } },
		RightKnee = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", -0.17365, 0, 0, 0.98481 }, { 0.16, "quad_out", -0.17365, 0, 0, 0.98481 }, { 0.26, "sine_inout", -0.17365, 0, 0, 0.98481 }, { 0.55, "linear", 0, 0, 0, 1 } },
		RightAnkle = { { 0, "quad_out", 0, 0, 0, 1 }, { 0.1, "quad_out", 0.05234, 0, 0, 0.99863 }, { 0.16, "quad_out", 0.05234, 0, 0, 0.99863 }, { 0.26, "sine_inout", 0.05234, 0, 0, 0.99863 }, { 0.55, "linear", 0, 0, 0, 1 } },
	},
}
