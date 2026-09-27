-- scripts/steps/post_heroes_polish.luau (HEROES, Gekko TO DO #8 "much better hero models": the procedural part)
-- Build hook: scripts/build_stealahero.luau step 12b runs every scripts/steps/post_*.luau in name order after the hero
-- builder: Apply(place, spPlace, ctx). No mesh can be uploaded, so this only cleans up what the owner's converted rigs
-- carry (scripts/hero_system_builder.luau + scripts/lib/rig_convert.luau) on every hero model the game renders:
-- ReplicatedStorage.AssetModels.<id> (pen heroes, portraits, tools) and Assets.Models.Heroes.<id> (template rigs).
--   * consistent body material: the 16 R15 body parts (Head + 15 limbs) of a hero are SmoothPlastic. The R6-converted
--     heroes already were, the R15 ones mixed in grainy Plastic; accessories / armour / glow parts keep theirs.
--   * duplicate heads: an R6 "FakeHead" welded exactly on the Head (same size, place and head mesh) doubled the head and
--     its face decal (z-fighting shimmer). The copy is made invisible (instance kept, so joints and checks are intact).
--   * stacked face decals: two identical decals on the same face -> the copy is hidden; different decals sharing one
--     face and one ZIndex get distinct ZIndex values in child order (a fixed draw order instead of flicker).
--   * the visible body parts cast shadows (grounds the heroes in the pen).
-- Villain guards (scripts/r15_rig_factory.luau ApplyGuard) are never touched. Idempotent.

local roblox = require("@lune/roblox")

local Enum = roblox.Enum

local Step = {}

Step.BODY_PARTS = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local EPSILON = 0.02

local function log(fmt, ...)
	print(string.format("[post_heroes_polish] " .. fmt, ...))
end

local function textureUri(decal)
	local ok, content = pcall(function()
		return (decal :: any).TextureContent
	end)
	if ok and content ~= nil then
		local okUri, uri = pcall(function()
			return content.Uri
		end)
		if okUri and uri ~= nil then
			return tostring(uri)
		end
	end
	return ""
end

local function headMeshType(part)
	local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
	return mesh and tostring(mesh.MeshType) or part.ClassName
end

local function samePlace(a, b)
	return (a.CFrame.Position - b.CFrame.Position).Magnitude <= EPSILON and (a.Size - b.Size).Magnitude <= EPSILON
end

-- Returns the counts of what was changed on one hero model.
function Step.PolishModel(model)
	local stats = { material = 0, duplicateHeads = 0, duplicateDecals = 0, decalOrder = 0, shadows = 0 }
	local inner = model:FindFirstChild("Model")
	local body = if inner and inner:IsA("Model") then inner else model

	-- 1. body material + shadows
	for _, name in ipairs(Step.BODY_PARTS) do
		local part = body:FindFirstChild(name)
		if part and part:IsA("BasePart") and part.Transparency < 1 then
			if part.Material == Enum.Material.Plastic then
				part.Material = Enum.Material.SmoothPlastic
				stats.material += 1
			end
			if not part.CastShadow then
				part.CastShadow = true
				stats.shadows += 1
			end
		end
	end

	-- 2. duplicate heads
	local head = body:FindFirstChild("Head")
	if head and head:IsA("BasePart") and head.Transparency < 1 then
		for _, d in ipairs(model:GetDescendants()) do
			if d ~= head and d:IsA("BasePart") and d.Name ~= "Head" and d.Transparency < 1 and d.ClassName == head.ClassName
				and headMeshType(d) == headMeshType(head) and samePlace(d, head) then
				d.Transparency = 1
				d.CastShadow = false
				d.CanQuery = false
				for _, decal in ipairs(d:GetChildren()) do
					if decal:IsA("Decal") then
						decal.Transparency = 1
					end
				end
				d:SetAttribute("PolishHidden", "DuplicateHead")
				stats.duplicateHeads += 1
			end
		end
	end

	-- 3. stacked decals (per part and face; Texture instances tile on purpose and are left alone)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local byFace = {}
			for _, decal in ipairs(part:GetChildren()) do
				if decal.ClassName == "Decal" and decal.Transparency < 1 then
					local face = tostring(decal.Face)
					byFace[face] = byFace[face] or {}
					table.insert(byFace[face], decal)
				end
			end
			for _, decals in pairs(byFace) do
				if #decals >= 2 then
					local seen, kept = {}, {}
					for _, decal in ipairs(decals) do
						local uri = textureUri(decal)
						if uri ~= "" and seen[uri] then
							decal.Transparency = 1
							stats.duplicateDecals += 1
						else
							seen[uri] = true
							table.insert(kept, decal)
						end
					end
					local sameZ = #kept >= 2
					for i = 2, #kept do
						if kept[i].ZIndex ~= kept[1].ZIndex then
							sameZ = false
						end
					end
					if sameZ then
						local base = kept[1].ZIndex
						for i, decal in ipairs(kept) do
							decal.ZIndex = base + i - 1
						end
						stats.decalOrder += 1
					end
				end
			end
		end
	end

	return stats
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local folders = {}
	local assetModels = rs:FindFirstChild("AssetModels")
	if assetModels then
		table.insert(folders, { assetModels, true })
	end
	local assets = rs:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	local heroes = models and models:FindFirstChild("Heroes")
	if heroes then
		table.insert(folders, { heroes, false })
	end

	local totals = { models = 0, material = 0, duplicateHeads = 0, duplicateDecals = 0, decalOrder = 0, shadows = 0 }
	for _, entry in ipairs(folders) do
		local folder, needsHeroId = entry[1], entry[2]
		for _, model in ipairs(folder:GetChildren()) do
			if model:IsA("Model") and (not needsHeroId or type(model:GetAttribute("HeroId")) == "string") then
				local stats = Step.PolishModel(model)
				totals.models += 1
				for key, value in pairs(stats) do
					totals[key] += value
				end
			end
		end
	end
	log("%d hero models: %d body parts -> SmoothPlastic, %d duplicate heads hidden, %d duplicate decals hidden, %d decal stacks ordered, %d shadows on",
		totals.models, totals.material, totals.duplicateHeads, totals.duplicateDecals, totals.decalOrder, totals.shadows)
	return totals
end

return Step
