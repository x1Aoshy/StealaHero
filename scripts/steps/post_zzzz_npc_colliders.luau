-- scripts/steps/post_zzzz_npc_colliders.luau (NPC pass 2026-09-26)
-- Owner: "invisible places that block you from walking ... go over all bases and areas for anything that is not
-- supposed to be there". The static Workspace audit (scripts/tools/audit_invisible_colliders.luau) finds no stray
-- invisible collider in the plots, bases or hub; the ones that reached the world at runtime came from templates:
--   1. ReplicatedStorage.GearTools tools: a held tool is part of the character, and the slap family ships a CanCollide
--      Handle plus an invisible 1 x 4.5 x 2.5 CanCollide block (InvisibilityCap: its Handle) that snagged doorways and
--      pushed other players. Every tool part is made non-colliding here (GearService.prepareGearTool does the same on
--      every copy it hands out). Melee hits are distance checks, traps are placed as their own non-colliding clone.
--   2. Invisible CanCollide effect templates that scripts clone into Workspace: ToolEffects.beamTrail (LaserCap parents
--      a clone to Workspace as is; Magnet references it) and the unused trail / smoke / footstep / ban-hammer templates
--      next to it, so a future use cannot drop an invisible block in the world either.
--   3. The six stage villains (__OBJECTS.Areas.GuardAreas.<stage>.Guard): every part is filed in the "Guards" collision
--      group (the base place had it on a few parts only, Forest on none). GuardChaseService re-assigns it when the chase
--      starts; filed in the place, a sleeping villain passes through players even before / without that (Bootstrap
--      registers the group first thing; Guards never collide with Players / NPCs / Guards).
-- Runs last among the post_ steps (after the gear step, the hero builder's villains and every template tweak). Idempotent.

local Step = {}

local INVISIBLE_TEMPLATES = {
	"Assets/ToolEffects/beamTrail",
	"Assets/beamTrail",
	"Assets/SpeedBoostTrail",
	"Assets/DashAbilityTrail",
	"Assets/SpeedTrail",
	"Assets/Extra/FootStepDecal",
	"Assets/VFX/SmokeBomb",
	"Assets/Models/Abilities/SmokeBomb",
	"Particles/BanHammerParticle",
}

local function findPath(root, path)
	local node = root
	for segment in string.gmatch(path, "[^/]+") do
		node = node and node:FindFirstChild(segment)
	end
	return node
end

local function insideTool(part, stop)
	local node = part.Parent
	while node and node ~= stop do
		if node:IsA("Tool") then
			return true
		end
		node = node.Parent
	end
	return false
end

function Step.Apply(place)
	local rs = place:GetService("ReplicatedStorage")
	local gearParts, templateParts = 0, 0

	local gear = rs:FindFirstChild("GearTools")
	for _, d in ipairs(gear and gear:GetDescendants() or {}) do
		if d:IsA("BasePart") and d.CanCollide and insideTool(d, gear) then
			d.CanCollide = false
			gearParts += 1
		end
	end

	for _, path in ipairs(INVISIBLE_TEMPLATES) do
		local template = findPath(rs, path)
		if template then
			local list = { template }
			for _, d in ipairs(template:GetDescendants()) do
				table.insert(list, d)
			end
			for _, d in ipairs(list) do
				if d:IsA("BasePart") and d.CanCollide and d.Transparency >= 0.95 then
					d.CanCollide = false
					templateParts += 1
				end
			end
		end
	end

	local villainParts, villains = 0, 0
	local guardAreas = findPath(place:GetService("Workspace"), "__OBJECTS/Areas/GuardAreas")
	for _, zone in ipairs(guardAreas and guardAreas:GetChildren() or {}) do
		local guard = zone:FindFirstChild("Guard")
		if guard and guard:IsA("Model") then
			villains += 1
			for _, d in ipairs(guard:GetDescendants()) do
				if d:IsA("BasePart") and d.CollisionGroup ~= "Guards" then
					d.CollisionGroup = "Guards"
					villainParts += 1
				end
			end
		end
	end

	print(string.format("[post_zzzz_npc_colliders] gear tool parts made non-colliding: %d, invisible effect template parts: %d, "
		.. "villain parts filed in Guards: %d (%d villains)", gearParts, templateParts, villainParts, villains))
end

return Step
