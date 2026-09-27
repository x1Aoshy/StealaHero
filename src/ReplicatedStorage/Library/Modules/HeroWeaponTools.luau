-- ReplicatedStorage.Library.Modules.HeroWeaponTools (ModuleScript, injected by scripts/inject/hero_weapons.luau)
-- The owner's hero weapon kit (assets/hero_weapons/HeroWeaponTools.luau, 2026-09-27), kept API-compatible:
--   Kit.Prepare(model, weaponId) -> Tool   turns an imported weapon model into a Tool (the future FBX path)
--   Kit.Attach(tool, character)             grips the weapon in the R15 right hand
--   Kit.SetGomuTime(tool, elapsed)          stretches the Gum-Gum fist along Gomu_Pistol (client visual)
-- plus Kit.SetStretch(tool, stretch) / Kit.SetPoleTime(tool, elapsed) (the Power Pole extends on Pole_Strike) and
-- Kit.Sections(tool) (parts by HeroSection).
--
-- The build does Prepare's work offline (scripts/steps/post_hero_weapons.luau; Lune has no GetPivot): the same
-- attributes (HeroWeaponId, GripFromHand, HeroSection), materials by palette, collisions off, Massless and one
-- "HeroWeaponWeld" per part with C0 = Handle.CFrame:ToObjectSpace(part.CFrame). It also writes Tool.Grip (and the
-- HeroGrip attribute) from the model's grip-space layout, so the engine's own RightGrip already holds the weapon
-- right; Attach only re-asserts it. Changes to the owner's version:
--   * Attach accepts the RightGrip whatever its class (the engine makes a Weld, the original asserted Motor6D) and
--     never throws;
--   * the stretch works on any part shape and Handle orientation: it runs from the Handle to the first Rubber / Extend
--     part (the Handle's +Y for the owner's fist), the part axis along it is the one scaled (a Roblox cylinder runs
--     along its X), and a Fist / Tip rides the stretch by its StretchLength attribute (default 1.35, the original
--     constant);
--   * grips for the two weapons the original kit did not list (Batarang, BakugoGauntlet).

local Kit = {}

Kit.WELD_NAME = "HeroWeaponWeld"
Kit.DEFAULT_STRETCH_LENGTH = 1.35

local materialByPalette = {
	mjolnir_metal = Enum.Material.Metal, steel_dark = Enum.Material.Metal,
	silver = Enum.Material.Metal, gold = Enum.Material.Metal, cartridge_brass = Enum.Material.Metal,
	lightning = Enum.Material.Neon, web_neon = Enum.Material.Neon, gold_energy = Enum.Material.Neon,
	hammer_forged = Enum.Material.Metal, hammer_edge = Enum.Material.Metal, hammer_inlay = Enum.Material.Metal,
}
Kit.MaterialByPalette = materialByPalette

local gripRotations = {
	Mjolnir = CFrame.Angles(math.rad(-90), 0, 0),
	PowerPole = CFrame.Angles(math.rad(-90), 0, 0),
	PowerPole_GoldToy = CFrame.Angles(math.rad(-90), 0, 0),
	CapShield = CFrame.Angles(math.rad(-90), 0, 0),
	WebShooter = CFrame.identity,
	GomuFist = CFrame.Angles(math.pi, 0, 0),
	Batarang = CFrame.Angles(math.rad(-90), 0, 0),
	BakugoGauntlet = CFrame.Angles(math.rad(-90), 0, 0),
}
Kit.GripRotations = gripRotations

local paletteForHandle = {
	Mjolnir = "leather", PowerPole = "hero_red", PowerPole_GoldToy = "hero_red",
	CapShield = "leather", WebShooter = "web_red_cloth", GomuFist = "rubber_skin",
	Batarang = "steel_dark", BakugoGauntlet = "steel_dark",
}

function Kit.Prepare(importedModel: Model, weaponId: string): Tool
	assert(gripRotations[weaponId], "Unknown weaponId")
	local source = importedModel:Clone()
	local handle = source:FindFirstChild("Handle", true)
	assert(handle and handle:IsA("BasePart"), "Import must contain a BasePart named Handle")
	local tool = Instance.new("Tool")
	tool.Name = weaponId
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("HeroWeaponId", weaponId)
	-- Preserve any import pivot offset before flattening the assembly into the Tool.
	local importOrigin = source:GetPivot()
	local originToHandle = importOrigin:ToObjectSpace(handle.CFrame)
	tool:SetAttribute("GripFromHand", gripRotations[weaponId] * originToHandle)
	for _, part in source:GetDescendants() do
		if part:IsA("BasePart") then
			local section = part:GetAttribute("Section") or part.Name:match("__([^_]+)__") or "Handle"
			local palette = part:GetAttribute("Palette") or part.Name:match("__[^_]+__(.+)$") or paletteForHandle[weaponId]
			part:SetAttribute("HeroSection", section)
			part.Material = materialByPalette[palette] or Enum.Material.SmoothPlastic
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			part.Parent = tool
			if part ~= handle then
				local weld = Instance.new("Weld")
				weld.Name = Kit.WELD_NAME
				weld.Part0 = handle
				weld.Part1 = part
				weld.C0 = handle.CFrame:ToObjectSpace(part.CFrame)
				weld.Parent = part
			end
		end
	end
	handle.Name = "Handle"
	source:Destroy()
	return tool
end

-- Run on the server when a Tool is equipped. A built weapon (HeroGrip attribute) is already held by Tool.Grip: the
-- engine's RightGrip gets it again. An imported one (Prepare) is gripped the original way (C0 identity, C1 the
-- inverse of GripFromHand). Returns true when a grip was set; never throws (no R15 hand / no grip yet -> false).
function Kit.Attach(tool: Tool, character: Model): boolean
	local hand = character and character:FindFirstChild("RightHand")
	if not (hand and hand:IsA("BasePart")) then
		return false
	end
	local grip = hand:FindFirstChild("RightGrip") or hand:WaitForChild("RightGrip", 3)
	if not (grip and grip:IsA("JointInstance")) then
		return false
	end
	local built = tool:GetAttribute("HeroGrip")
	if typeof(built) == "CFrame" then
		if tool.Grip ~= built then
			tool.Grip = built
		end
		grip.C1 = built
		return true
	end
	local desired = tool:GetAttribute("GripFromHand")
	if typeof(desired) ~= "CFrame" then
		return false
	end
	grip.C0 = CFrame.identity
	grip.C1 = desired:Inverse()
	return true
end

-- Parts by section: { [section] = { BasePart } } (the Handle under "Handle").
function Kit.Sections(tool: Tool): { [string]: { BasePart } }
	local sections = {}
	for _, part in tool:GetChildren() do
		if part:IsA("BasePart") then
			local section = part:GetAttribute("HeroSection")
			section = if type(section) == "string" then section else "Handle"
			sections[section] = sections[section] or {}
			table.insert(sections[section], part)
		end
	end
	return sections
end

-- The part axis ("X" / "Y" / "Z") that runs along `dir` (Handle space), from a weld C0 (part in Handle space).
local function axisAlong(c0: CFrame, dir: Vector3): string
	local v = c0:VectorToObjectSpace(dir)
	local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
	if ax >= ay and ax >= az then
		return "X"
	elseif ay >= az then
		return "Y"
	end
	return "Z"
end

local function isStretchSection(section)
	return section == "Rubber" or section == "Extend" or section == "Fist" or section == "Tip"
end

-- The stretch direction (Handle space) runs from the Handle to the first Rubber / Extend part: the Handle's +Y for
-- the owner's Gum-Gum fist, the pole's axis for the Power Pole (a cylinder Handle runs along its own X).
local caches = setmetatable({}, { __mode = "k" })
local function stretchCache(tool: Tool)
	local cache = caches[tool]
	if cache then
		return cache
	end
	cache = {}
	local dir = nil
	for _, part in tool:GetChildren() do
		local section = part:IsA("BasePart") and part:GetAttribute("HeroSection")
		if section == "Rubber" or section == "Extend" then
			local weld = part:FindFirstChild(Kit.WELD_NAME)
			if weld and weld:IsA("Weld") and weld.C0.Position.Magnitude > 1e-3 then
				dir = weld.C0.Position.Unit
				break
			end
		end
	end
	dir = dir or Vector3.yAxis
	for _, part in tool:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "Handle" then
			local weld = part:FindFirstChild(Kit.WELD_NAME)
			local section = part:GetAttribute("HeroSection")
			if weld and weld:IsA("Weld") and isStretchSection(section) then
				local length = part:GetAttribute("StretchLength")
				table.insert(cache, {
					part = part,
					weld = weld,
					size = part.Size,
					c0 = weld.C0,
					section = section,
					dir = dir,
					axis = axisAlong(weld.C0, dir),
					length = if type(length) == "number" then length else Kit.DEFAULT_STRETCH_LENGTH,
				})
			end
		end
	end
	caches[tool] = cache
	return cache
end

-- Client visual: stretch 1 = rest. Rubber / Extend parts grow along the stretch direction from their base; Fist / Tip
-- parts move with the end of the stretched section (by StretchLength per unit of stretch).
function Kit.SetStretch(tool: Tool, stretch: number)
	for _, state in stretchCache(tool) do
		if not state.part.Parent then
			continue
		end
		local dir = state.dir
		if state.section == "Rubber" or state.section == "Extend" then
			local s = state.size
			state.part.Size = Vector3.new(
				if state.axis == "X" then s.X * stretch else s.X,
				if state.axis == "Y" then s.Y * stretch else s.Y,
				if state.axis == "Z" then s.Z * stretch else s.Z
			)
			local p = state.c0.Position
			state.weld.C0 = CFrame.new(p + dir * (p:Dot(dir) * (stretch - 1))) * state.c0.Rotation
		else
			state.weld.C0 = CFrame.new(dir * ((stretch - 1) * state.length)) * state.c0
		end
	end
end

local function keyedStretch(keys, elapsed: number): number
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if elapsed >= a[1] and elapsed <= b[1] then
			local f = (elapsed - a[1]) / (b[1] - a[1])
			f = f * f * (3 - 2 * f)
			return a[2] + (b[2] - a[2]) * f
		end
	end
	return 1
end

-- Client visual only. Call at the same elapsed time as Gomu_Pistol, then at t=0 to reset.
Kit.GOMU_STRETCH_KEYS = { { 0, 1 }, { 0.17, 1.4 }, { 0.30, 2.25 }, { 0.36, 1.65 }, { 0.60, 1 } }
function Kit.SetGomuTime(tool: Tool, elapsed: number)
	Kit.SetStretch(tool, keyedStretch(Kit.GOMU_STRETCH_KEYS, elapsed))
end

-- The Power Pole shoots out at Pole_Strike's Impact (0.2 s) and slides back in.
Kit.POLE_STRETCH_KEYS = { { 0, 1 }, { 0.12, 1.05 }, { 0.2, 2.3 }, { 0.34, 2.3 }, { 0.58, 1 }, { 0.7, 1 } }
function Kit.SetPoleTime(tool: Tool, elapsed: number)
	Kit.SetStretch(tool, keyedStretch(Kit.POLE_STRETCH_KEYS, elapsed))
end

return Kit
