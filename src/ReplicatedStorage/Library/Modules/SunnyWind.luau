-- Small deterministic wind motions; sampled locally, no physics or animation uploads.
-- Ship coordinates: Blender (x,y,z) -> Roblox (x,z,-y), relative to SunnyOrigin.
local Wind = {}
Wind.Tag = "SunnyWindRig"
-- Keep in step with scripts/tools/blender/base_themes/themes/sunny_ship.py (MAIN_PIVOT / AFT_PIVOT / FLAG_PIVOT):
-- the main yard on the main mast, the aft yard on the aft mast, the main mast's axis for the flag.
Wind.Pivots = {
	Main = CFrame.new(-0.35, 6.5, 0),
	Aft = CFrame.new(3.95, 6.05, 0.05),
	Flag = CFrame.new(-0.35, 7.35, 0),
}
local identity = CFrame.new()

function Wind.Sample(time, phase, strength)
	local s = math.clamp(strength or 1, 0, 1)
	local t = ((time + (phase or 0)) % 12) * (2 * math.pi / 12)
	local swell = math.sin(t)
	local breeze = 0.72 * math.sin(t * 3) + 0.28 * math.sin(t * 5 + 0.8)
	local hull = CFrame.new(0, 0.025 * swell * s, 0)
		* CFrame.Angles(0, 0, math.rad(0.18) * math.sin(t * 2) * s)
	local main = CFrame.Angles(math.rad(1.8) * breeze * s, 0, 0)
	local aft = CFrame.Angles(math.rad(2.3) * math.sin(t * 4 + 1.1) * s, 0, 0)
	local flag = CFrame.Angles(0, math.rad(6) * math.sin(t * 8 + 0.5) * s, 0)
	return {
		Hull = hull,
		Main = hull * Wind.Pivots.Main * main * Wind.Pivots.Main:Inverse(),
		Aft = hull * Wind.Pivots.Aft * aft * Wind.Pivots.Aft:Inverse(),
		Flag = hull * Wind.Pivots.Flag * flag * Wind.Pivots.Flag:Inverse(),
	}
end

function Wind.Interval(distance)
	if distance > 180 then
		return nil
	end
	return if distance <= 80 then 1 / 30 else 1 / 15
end

Wind.Identity = identity
return Wind
