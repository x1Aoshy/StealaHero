--!nocheck
-- tests/smoke_treadmill_raise.luau (owner 2026-09-27, round 10: "the treadmills are a bit sunk into the floor, raise
-- them a bit and check they sit right"). Joins the "smoke" filter. Checks every treadmill skin built by
-- scripts/steps/treadmill.luau:
--   * the model sits on the floor (its lowest visible point at most ~0.35 under it; it used to be ~1.2 under), its belt
--     top BeltLift above the floor (the Tool attribute);
--   * the runner's invisible deck (BeltDeck: top at the belt top, over the belt) and the ramp behind it (BeltRamp)
--     are solid, invisible, out of spatial queries and flagged TreadmillDeck; both renderers keep them solid;
--   * the static plot display is raised the same way and stays visual-only.

local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts
local sss = place:GetService("ServerScriptService")

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end

local function lowestY(model)
	local low = math.huge
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 0.99 then
			for _, sx in ipairs({ -0.5, 0.5 }) do
				for _, sy in ipairs({ -0.5, 0.5 }) do
					for _, sz in ipairs({ -0.5, 0.5 }) do
						low = math.min(low, part.CFrame:PointToWorldSpace(H.roblox.Vector3.new(part.Size.X * sx, part.Size.Y * sy, part.Size.Z * sz)).Y)
					end
				end
			end
		end
	end
	return low
end

local skins = H.path(rs, "Assets/Models/Treadmills")
local checked = 0
for _, tool in ipairs(skins and skins:GetChildren() or {}) do
	local root = tool:FindFirstChild("Root")
	local decor = tool:FindFirstChild("Model")
	if tool:IsA("Tool") and root and decor and tool:GetAttribute("TreadmillModel") ~= nil then
		checked += 1
		local floorY = root.CFrame.Position.Y - 3.9 -- the template's floor frame (Root sits 3.9 above it)
		local lift = tool:GetAttribute("BeltLift")
		T.check(type(lift) == "number" and lift >= 0.05, "%s needs its BeltLift", tool.Name)
		local sink = floorY - lowestY(decor)
		T.check(sink <= 0.35, "%s still sinks %.2f studs into the floor", tool.Name, sink)
		local deck, ramp = tool:FindFirstChild("BeltDeck"), tool:FindFirstChild("BeltRamp")
		for _, part in ipairs({ deck, ramp }) do
			T.check(part ~= nil and part:IsA("BasePart") and part.CanCollide and not part.CanQuery and not part.CanTouch
				and part.Transparency >= 1 and part:GetAttribute("TreadmillDeck") == true,
				"%s: the runner's deck / ramp must be solid, invisible, unqueried and flagged TreadmillDeck", tool.Name)
		end
		if deck and type(lift) == "number" then
			local top = deck.CFrame.Position.Y + deck.Size.Y / 2
			T.check(math.abs(top - (floorY + lift)) < 0.02, "%s: the deck top %.3f must be the belt top %.3f", tool.Name, top, floorY + lift)
		end
	end
end
T.check(checked >= 10, "expected the 10 treadmill skins, checked %d", checked)

local spawnSrc = src(H.path(sss, "Controllers/TreadmillSpawnService"))
local renderSrc = src(H.path(sps, "Game/Plots/TreadmillStaticController/Render"))
T.check(H.has(spawnSrc, "desc.CanCollide = deck") and H.has(renderSrc, "descendant.CanCollide = deck"),
	"both treadmill renderers must keep the runner's deck solid")

local displays = 0
for _, plot in ipairs(place.Workspace:FindFirstChild("Plots") and place.Workspace.Plots:GetChildren() or {}) do
	local display = plot:FindFirstChild("SpeedsterTreadmillDisplay")
	local floorY = plot:GetAttribute("TreadmillFloorY")
	if display and type(floorY) == "number" then
		displays += 1
		T.check(floorY - lowestY(display) <= 0.35, "plot %s: the treadmill display still sinks into the floor", plot.Name)
		for _, part in ipairs(display:GetDescendants()) do
			if part:IsA("BasePart") then
				T.check(not part.CanCollide and not part.CanQuery, "plot %s: display part %s must stay visual-only", plot.Name, part.Name)
			end
		end
	end
end
T.check(displays >= 1, "no treadmill display on the plots")
