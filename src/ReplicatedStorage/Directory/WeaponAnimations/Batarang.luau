-- ReplicatedStorage.Directory.WeaponAnimations.Batarang (GENERATED - do not edit by hand)
-- Authored in scripts/tools/hero_weapons/author_weapon_clips.py (Batarang_Flick), hero clip Format 1
-- (ReplicatedStorage.Library.Modules.HeroClipMath). Played on the attacker by
-- StarterPlayerScripts.BranchControllers.HeroWeaponController; the server (GearService) resolves the hit at
-- Impact seconds. Keys: { time, easing, qx, qy, qz, qw [, px, py, pz] }.

return {
	Format = 1,
	WeaponId = "Batarang",
	Clip = "Batarang_Flick",
	Length = 0.62,
	Impact = 0.22,
	Release = 0.22,
	Loop = false,
	Tracks = {
		Root = { { 0, "sine_inout", 0, 0, 0, 1, 0, 0, 0 }, { 0.12, "quad_in", -0.03414, -0.20779, 0.00726, 0.97755, 0, -0.25, 0 }, { 0.22, "quad_out", -0.08651, 0.12141, -0.01062, 0.98877, 0, -0.3, -0.2 }, { 0.34, "sine_inout", -0.0687, 0.17323, -0.01211, 0.98241, 0, -0.25, -0.2 }, { 0.62, "linear", 0, 0, 0, 1, 0, 0, 0 } },
		Waist = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", -0.03386, -0.24177, 0.00844, 0.9697 }, { 0.22, "quad_out", -0.08555, 0.19008, -0.01663, 0.97789 }, { 0.34, "sine_inout", -0.06738, 0.25819, -0.01805, 0.96357 }, { 0.62, "linear", 0, 0, 0, 1 } },
		Neck = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", 0, 0.34202, 0, 0.93969 }, { 0.22, "quad_out", 0, -0.15643, 0, 0.98769 }, { 0.34, "sine_inout", 0, -0.15643, 0, 0.98769 }, { 0.62, "linear", 0, 0, 0, 1 } },
		LeftShoulder = { { 0, "sine_inout", 0, 0, -0.05234, 0.99863 }, { 0.12, "quad_in", 0.38072, 0.0879, -0.20707, 0.89691 }, { 0.22, "quad_out", 0.13078, 0.0476, -0.33869, 0.93055 }, { 0.34, "sine_inout", 0.13078, 0.0476, -0.33869, 0.93055 }, { 0.62, "linear", 0, 0, -0.05234, 0.99863 } },
		LeftElbow = { { 0, "sine_inout", 0.06976, 0, 0, 0.99756 }, { 0.12, "quad_in", 0.34202, 0, 0, 0.93969 }, { 0.22, "quad_out", 0.25882, 0, 0, 0.96593 }, { 0.34, "sine_inout", 0.25882, 0, 0, 0.96593 }, { 0.62, "linear", 0.06976, 0, 0, 0.99756 } },
		RightShoulder = { { 0, "sine_inout", 0.57218, -0.04001, 0.05714, 0.81716 }, { 0.12, "quad_in", 0.21949, -0.13715, 0.51186, 0.81915 }, { 0.22, "quad_out", 0.68611, 0.10867, -0.11253, 0.71048 }, { 0.34, "sine_inout", 0.53181, 0.21487, -0.30686, 0.7595 }, { 0.62, "linear", 0.57218, -0.04001, 0.05714, 0.81716 } },
		RightElbow = { { 0, "sine_inout", 0.19081, 0, 0, 0.98163 }, { 0.12, "quad_in", 0.57358, 0, 0, 0.81915 }, { 0.22, "quad_out", 0.05234, 0, 0, 0.99863 }, { 0.34, "sine_inout", 0.22495, 0, 0, 0.97437 }, { 0.62, "linear", 0.19081, 0, 0, 0.98163 } },
		RightWrist = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", 0, 0, 0.17365, 0.98481 }, { 0.22, "quad_out", 0, 0, -0.20791, 0.97815 }, { 0.34, "sine_inout", 0, 0, -0.20791, 0.97815 }, { 0.62, "linear", 0, 0, 0, 1 } },
		LeftHip = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", -0.06971, -0.00243, -0.03481, 0.99696 }, { 0.22, "quad_out", -0.13909, -0.00486, -0.03456, 0.98966 }, { 0.34, "sine_inout", -0.13909, -0.00486, -0.03456, 0.98966 }, { 0.62, "linear", 0, 0, 0, 1 } },
		LeftKnee = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", -0.17365, 0, 0, 0.98481 }, { 0.22, "quad_out", -0.15643, 0, 0, 0.98769 }, { 0.34, "sine_inout", -0.15643, 0, 0, 0.98769 }, { 0.62, "linear", 0, 0, 0, 1 } },
		LeftAnkle = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", 0.0349, 0, 0, 0.99939 }, { 0.22, "quad_out", 0.0349, 0, 0, 0.99939 }, { 0.34, "sine_inout", 0.0349, 0, 0, 0.99939 }, { 0.62, "linear", 0, 0, 0, 1 } },
		RightHip = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", 0.17354, -0.00606, 0.03437, 0.98421 }, { 0.22, "quad_out", 0.25866, -0.00903, 0.03371, 0.96534 }, { 0.34, "sine_inout", 0.25866, -0.00903, 0.03371, 0.96534 }, { 0.62, "linear", 0, 0, 0, 1 } },
		RightKnee = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", -0.24192, 0, 0, 0.9703 }, { 0.22, "quad_out", -0.27564, 0, 0, 0.96126 }, { 0.34, "sine_inout", -0.27564, 0, 0, 0.96126 }, { 0.62, "linear", 0, 0, 0, 1 } },
		RightAnkle = { { 0, "sine_inout", 0, 0, 0, 1 }, { 0.12, "quad_in", 0.08716, 0, 0, 0.99619 }, { 0.22, "quad_out", 0.08716, 0, 0, 0.99619 }, { 0.34, "sine_inout", 0.08716, 0, 0, 0.99619 }, { 0.62, "linear", 0, 0, 0, 1 } },
	},
}
