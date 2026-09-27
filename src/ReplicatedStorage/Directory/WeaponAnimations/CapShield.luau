-- ReplicatedStorage.Directory.WeaponAnimations.CapShield (GENERATED - do not edit by hand)
-- Authored in scripts/tools/hero_weapons/author_weapon_clips.py (Shield_Throw), hero clip Format 1
-- (ReplicatedStorage.Library.Modules.HeroClipMath). Played on the attacker by
-- StarterPlayerScripts.BranchControllers.HeroWeaponController; the server (GearService) resolves the hit at
-- Impact seconds. Keys: { time, easing, qx, qy, qz, qw [, px, py, pz] }.

return {
	Format = 1,
	WeaponId = "CapShield",
	Clip = "Shield_Throw",
	Length = 0.72,
	Impact = 0.26,
	Release = 0.26,
	Loop = false,
	Tracks = {
		Root = { { 0, "sine_inout", 0, 0, 0, 1, 0, 0, 0 }, { 0.15, "quad_in", -0.03426, 0.19069, -0.00666, 0.98103, 0, -0.2, 0 }, { 0.26, "quad_out", -0.06924, -0.12157, 0.0085, 0.99013, 0, -0.25, -0.2 }, { 0.4, "sine_inout", -0.05137, -0.19055, 0.00999, 0.98028, 0, -0.2, -0.2 }, { 0.72, "linear", 0, 0, 0, 1, 0, 0, 0 } },
		Waist = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", -0.05005, 0.29197, -0.0153, 0.95499 }, { 0.26, "quad_out", -0.06823, -0.20741, 0.0145, 0.97576 }, { 0.4, "sine_inout", -0.05031, -0.27526, 0.01443, 0.95994 }, { 0.72, "linear", 0, 0, 0, 1 } },
		Neck = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", 0, -0.37461, 0, 0.92718 }, { 0.26, "quad_out", 0, 0.25882, 0, 0.96593 }, { 0.4, "sine_inout", 0, 0.30902, 0, 0.95106 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftShoulder = { { 0, "sine_inout", 0, 0, -0.05234, 0.99863 }, { 0.15, "quad_in", 0.24751, 0.07567, -0.28241, 0.92372 }, { 0.26, "quad_out", 0.15738, 0.07339, -0.4162, 0.89254 }, { 0.4, "sine_inout", 0.15738, 0.07339, -0.4162, 0.89254 }, { 0.72, "linear", 0, 0, -0.05234, 0.99863 } },
		LeftElbow = { { 0, "sine_inout", 0.06976, 0, 0, 0.99756 }, { 0.15, "quad_in", 0.34202, 0, 0, 0.93969 }, { 0.26, "quad_out", 0.25882, 0, 0, 0.96593 }, { 0.4, "sine_inout", 0.25882, 0, 0, 0.96593 }, { 0.72, "linear", 0.06976, 0, 0, 0.99756 } },
		RightShoulder = { { 0, "sine_inout", 0.58635, -0.041, 0.05643, 0.80705 }, { 0.15, "quad_in", 0.58523, 0.3244, -0.36028, 0.64997 }, { 0.26, "quad_out", 0.69797, -0.17402, 0.16805, 0.67402 }, { 0.4, "sine_inout", 0.56235, -0.3379, 0.3887, 0.64691 }, { 0.72, "linear", 0.58635, -0.041, 0.05643, 0.80705 } },
		RightElbow = { { 0, "sine_inout", 0.17365, 0, 0, 0.98481 }, { 0.15, "quad_in", 0.82904, 0, 0, 0.55919 }, { 0.26, "quad_out", 0.05234, 0, 0, 0.99863 }, { 0.4, "sine_inout", 0.12187, 0, 0, 0.99255 }, { 0.72, "linear", 0.17365, 0, 0, 0.98481 } },
		RightWrist = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", 0, 0, 0, 1 }, { 0.26, "quad_out", 0, 0, 0, 1 }, { 0.4, "sine_inout", 0, 0, 0, 1 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftHip = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", 0.22481, 0.00785, -0.03401, 0.97378 }, { 0.26, "quad_out", 0.27547, 0.00962, -0.03355, 0.96068 }, { 0.4, "sine_inout", 0.27547, 0.00962, -0.03355, 0.96068 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftKnee = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", -0.22495, 0, 0, 0.97437 }, { 0.26, "quad_out", -0.25882, 0, 0, 0.96593 }, { 0.4, "sine_inout", -0.25882, 0, 0, 0.96593 }, { 0.72, "linear", 0, 0, 0, 1 } },
		LeftAnkle = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", 0.06976, 0, 0, 0.99756 }, { 0.26, "quad_out", 0.08716, 0, 0, 0.99619 }, { 0.4, "sine_inout", 0.08716, 0, 0, 0.99619 }, { 0.72, "linear", 0, 0, 0, 1 } },
		RightHip = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", -0.0871, 0.00304, 0.03477, 0.99559 }, { 0.26, "quad_out", -0.13909, 0.00486, 0.03456, 0.98966 }, { 0.4, "sine_inout", -0.13909, 0.00486, 0.03456, 0.98966 }, { 0.72, "linear", 0, 0, 0, 1 } },
		RightKnee = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", -0.19081, 0, 0, 0.98163 }, { 0.26, "quad_out", -0.12187, 0, 0, 0.99255 }, { 0.4, "sine_inout", -0.12187, 0, 0, 0.99255 }, { 0.72, "linear", 0, 0, 0, 1 } },
		RightAnkle = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.15, "quad_in", 0.05234, 0, 0, 0.99863 }, { 0.26, "quad_out", 0.0349, 0, 0, 0.99939 }, { 0.4, "sine_inout", 0.0349, 0, 0, 0.99939 }, { 0.72, "linear", 0, 0, 0, 1 } },
	},
}
