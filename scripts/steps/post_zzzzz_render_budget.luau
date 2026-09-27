--!nocheck
-- scripts/steps/post_zzzzz_render_budget.luau (owner 2026-09-27: "hyper optimised: client FPS, memory, server")
-- The stage nests are built from ~14,000 tiny wood sticks (Workspace.__OBJECTS.Areas.GuardAreas.<stage>.Nests), every
-- one of them drawn into the shadow map, and the Forest ones also in the touch / query broadphase (the other stages'
-- nests already are not). Nest sticks never collide, so none of that is visible or used:
--   CastShadow = false, CanTouch = false, CanQuery = false   on every non-colliding part of a nest.
-- The egg, the nest's own collider (a colliding part) and everything else keep their flags. Runs last among the post
-- steps. Idempotent.

local Step = {}

function Step.Apply(place, _spPlace, _ctx)
	local objects = place:GetService("Workspace"):FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	if guardAreas == nil then
		print("[post_zzzzz_render_budget] WARN Workspace.__OBJECTS.Areas.GuardAreas missing")
		return
	end
	local changed, stages = 0, 0
	for _, stage in ipairs(guardAreas:GetChildren()) do
		local nests = stage:FindFirstChild("Nests")
		if nests then
			stages += 1
			for _, d in ipairs(nests:GetDescendants()) do
				if d:IsA("BasePart") and not d.CanCollide and (d.CastShadow or d.CanTouch or d.CanQuery) then
					d.CastShadow = false
					d.CanTouch = false
					d.CanQuery = false
					changed += 1
				end
			end
		end
	end
	print(string.format("[post_zzzzz_render_budget] %d nest parts across %d stages: no shadow, no touch / query", changed, stages))
end

return Step
