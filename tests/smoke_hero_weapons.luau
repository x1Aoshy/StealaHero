--!nocheck
-- tests/smoke_hero_weapons.luau (owner 2026-09-27, 6th pass: "MISSION: replace the bat system with Hero Gadgets", plus
-- the bug reports that came with it). Joins the "smoke" filter. Checks:
--   1. every mapped melee tool is a hero weapon built like HeroWeaponTools.Prepare: HeroWeaponId, a Handle, Tool.Grip
--      from the grip-space model, per-part HeroSection, the palette materials, no collision / touch / query, Massless,
--      one HeroWeaponWeld per part (C0 = Handle:ToObjectSpace(part)), no scripts / sounds / lights left from the bat;
--      the unmapped classic bats keep their bat;
--   2. the owner's 7 attack clips are published (hero clip Format 1, Impact inside the clip, the right arm animated);
--   3. the shared weapon table follows the owner's mapping and effects (2.5 s, the Dazed 2.0 - 2.5 s), the kit keeps
--      the owner's API, and the Gum-Gum stretch really stretches the built fist (sandboxed kit on the built tool);
--   4. GearService resolves hero weapon hits at the clip's Impact and applies the debuff states instead of the ragdoll;
--      the client controller, the hotbar / Index portraits and the classic bat FX split are wired;
--   5. the owner's reports: the trap's Hitbox moves with the placed trap, the ragdoll ignores aura / trail parts, the
--      Money Popups row paints its real value and the descriptions end before the button.

local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts
local sss = place:GetService("ServerScriptService")
local roblox = H.roblox

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end

local OWNER_MAPPING = {
	["Bat"] = "CapShield",
	["Forest Bat"] = "PowerPole",
	["Desert Bat"] = "WebShooter",
	["Lake Bat"] = "Batarang",
	["Jungle Bat"] = "BakugoGauntlet",
	["Snow Bat"] = "Mjolnir",
	["Cosmic Bat"] = "Mjolnir",
	["Volcano Bat"] = "GomuFist",
}
local OWNER_EFFECTS = {
	WebShooter = "Webbed", Mjolnir = "Electrocuted", GomuFist = "CleanKnockback", CapShield = "Dazed",
	Batarang = "SmokeStun", BakugoGauntlet = "ExplosionBlast", PowerPole = "SpinTornado",
}
local ENERGY = { lightning = true, web_neon = true, gold_energy = true }

-- 1. tools
local shopItems = H.path(rs, "GearTools/ShopItems")
T.check(shopItems ~= nil, "ReplicatedStorage.GearTools.ShopItems missing")
for toolName, weaponId in pairs(OWNER_MAPPING) do
	local tool = shopItems and shopItems:FindFirstChild(toolName)
	if not T.check(tool ~= nil and tool:IsA("Tool"), "GearTools.ShopItems.%s missing", toolName) then
		continue
	end
	T.check(tool:GetAttribute("HeroWeaponId") == weaponId, "%s must be the %s (HeroWeaponId %s)", toolName, weaponId,
		tostring(tool:GetAttribute("HeroWeaponId")))
	T.check(type(tool:GetAttribute("GearName")) == "string" and tool:GetAttribute("ItemType") == "Gear",
		"%s must keep GearName / ItemType (hotbar slot lock, gear UI)", toolName)
	local handle = tool:FindFirstChild("Handle")
	T.check(handle ~= nil and handle:IsA("BasePart") and tool.RequiresHandle, "%s needs a BasePart Handle", toolName)
	T.check(typeof(tool:GetAttribute("GripFromHand")) == "CFrame", "%s: GripFromHand (Kit.Prepare contract) missing", toolName)
	local heroGrip = tool:GetAttribute("HeroGrip")
	T.check(typeof(heroGrip) == "CFrame" and (heroGrip.Position - tool.Grip.Position).Magnitude < 1e-3,
		"%s: Tool.Grip must be the model's grip (HeroGrip)", toolName)
	local imported = tool:GetAttribute("HeroWeaponModel") == "Import"
	T.check(imported or tool:GetAttribute("HeroWeaponModel") == "Parts", "%s: HeroWeaponModel must say Import or Parts", toolName)
	if imported and typeof(tool:GetAttribute("GripFromHand")) == "CFrame" then
		-- the engine's RightGrip (Handle = RightHand * RightGripAttachment * Grip^-1) must hold the Handle where the owner's
		-- kit puts it (Handle = RightHand * GripFromHand)
		local attachment = roblox.CFrame.new(0, -0.15, 0) * roblox.CFrame.Angles(math.rad(-90), 0, 0)
		local held = attachment * tool.Grip:Inverse()
		local want = tool:GetAttribute("GripFromHand")
		T.check((held.Position - want.Position).Magnitude < 1e-3 and (held.LookVector - want.LookVector).Magnitude < 1e-3,
			"%s: the imported model must be held exactly where the kit's GripFromHand puts it", toolName)
	end
	T.check(#H.badJoints(tool) == 0, "%s has joints pointing outside the tool: %s", toolName, table.concat(H.badJoints(tool), ", "))
	local parts = 0
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("Light") or d:IsA("Animation") or d:IsA("ParticleEmitter") then
			T.check(false, "%s still carries a %s (%s) from the old bat", toolName, d.ClassName, d.Name)
		end
		if d:IsA("BasePart") then
			parts += 1
			T.check(not d.CanCollide and not d.CanTouch and not d.CanQuery and d.Massless and not d.Anchored,
				"%s.%s must not collide / touch / query, and be massless and unanchored", toolName, d.Name)
			T.check(type(d:GetAttribute("HeroSection")) == "string", "%s.%s has no HeroSection", toolName, d.Name)
			local palette = d:GetAttribute("HeroPalette")
			T.check(d.Material ~= roblox.Enum.Material.Neon or ENERGY[palette], "%s.%s: Neon only for energy palettes", toolName, d.Name)
			if d ~= handle then
				local weld = d:FindFirstChild("HeroWeaponWeld")
				if T.check(weld ~= nil and weld:IsA("Weld") and weld.Part0 == handle and weld.Part1 == d,
					"%s.%s needs a HeroWeaponWeld to the Handle", toolName, d.Name) then
					local expected = handle.CFrame:ToObjectSpace(d.CFrame)
					T.check((expected.Position - weld.C0.Position).Magnitude < 1e-3, "%s.%s: weld C0 must hold the authored layout", toolName, d.Name)
				end
			end
		end
	end
	if imported then
		T.check(parts >= 2 and parts <= 40, "%s: %d imported meshes", toolName, parts)
	else
		T.check(parts >= 6 and parts <= 40, "%s: %d parts (a readable toy weapon, cheap per player)", toolName, parts)
	end
end
for _, classic in ipairs({ "Prehistoric Bat", "Abyss Ocean Bat" }) do
	local tool = shopItems and shopItems:FindFirstChild(classic)
	if tool then
		T.check(tool:GetAttribute("HeroWeaponId") == nil and tool:FindFirstChild("Handle") ~= nil,
			"%s is not mapped: it stays a classic bat", classic)
	end
end

-- 2. clips
local clipFolder = H.path(rs, "Directory/WeaponAnimations")
local clipMath = H.sandbox(src(H.path(rs, "Library/Modules/HeroClipMath")), { CFrame = roblox.CFrame })()
for _, weaponId in pairs(OWNER_MAPPING) do
	local module = clipFolder and clipFolder:FindFirstChild(weaponId)
	if T.check(module ~= nil and module:IsA("ModuleScript"), "Directory.WeaponAnimations.%s missing", weaponId) then
		local data = H.sandbox(src(module), {})()
		T.check(data.WeaponId == weaponId and data.Format == 1 and not data.Loop, "WeaponAnimations.%s: bad header", weaponId)
		T.check(data.Impact > 0 and data.Impact < data.Length and data.Length <= 1, "WeaponAnimations.%s: Impact outside the clip", weaponId)
		T.check(pcall(clipMath.PrepareClip, weaponId, data), "WeaponAnimations.%s does not validate with HeroClipMath", weaponId)
		T.check(data.Tracks.RightShoulder ~= nil and data.Tracks.RightElbow ~= nil and data.Tracks.Waist ~= nil,
			"WeaponAnimations.%s must animate the right arm and the waist", weaponId)
	end
end

-- 3. shared table + kit
local configModule = H.path(rs, "Library/Modules/HeroWeapons")
local config = configModule and H.sandbox(src(configModule), { Color3 = roblox.Color3 })()
if T.check(type(config) == "table", "Library.Modules.HeroWeapons missing or broken") then
	for toolName, weaponId in pairs(OWNER_MAPPING) do
		T.check(config.BY_TOOL[toolName] == weaponId, "HeroWeapons.BY_TOOL[%s] must be %s (owner's mapping)", toolName, weaponId)
	end
	for weaponId, effect in pairs(OWNER_EFFECTS) do
		local weapon = config.WEAPONS[weaponId]
		if T.check(weapon ~= nil, "HeroWeapons.WEAPONS.%s missing", weaponId) then
			T.check(weapon.Effect == effect, "%s must apply %s", weaponId, effect)
			local spec = config.EFFECTS[effect]
			local duration = spec and spec.Duration
			T.check(type(duration) == "number" and (if effect == "Dazed" then duration >= 2 and duration <= 2.5 else duration == 2.5),
				"%s must last 2.5 s (Dazed 2.0 - 2.5 s), got %s", effect, tostring(duration))
			T.check(type(weapon.Cooldown) == "number" and weapon.Cooldown >= 0.7 and type(weapon.Range) == "number",
				"%s needs a cooldown and a range", weaponId)
		end
	end
	T.check((config.WEAPONS.GomuFist.Push or 0) >= 40, "the Gum-Gum pistol pushes ~45 studs")
end
local kitSrc = src(H.path(rs, "Library/Modules/HeroWeaponTools"))
for _, api in ipairs({ "function Kit.Prepare(", "function Kit.Attach(", "function Kit.SetGomuTime(", "function Kit.SetStretch(" }) do
	T.check(H.has(kitSrc, api), "HeroWeaponTools must keep %s", api)
end
do
	local chunk = H.sandbox(kitSrc, { Enum = roblox.Enum, CFrame = roblox.CFrame, Vector3 = roblox.Vector3 })
	local Kit = chunk and chunk()
	-- parts by HeroSection (the part stand-ins and the owner's imports name them differently)
	local function sectionPart(tool, section)
		for _, part in ipairs(tool:GetChildren()) do
			if part:IsA("BasePart") and part:GetAttribute("HeroSection") == section then
				return part
			end
		end
		return nil
	end
	-- a part's length along the stretch direction (the Kit scales the part axis most aligned with it)
	local function lengthAlong(part, dir)
		local weld = part:FindFirstChild("HeroWeaponWeld")
		local v = weld.C0:VectorToObjectSpace(dir)
		local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
		return if ax >= ay and ax >= az then part.Size.X elseif ay >= az then part.Size.Y else part.Size.Z
	end
	local fist = shopItems and shopItems:FindFirstChild("Volcano Bat")
	if T.check(type(Kit) == "table" and fist ~= nil, "HeroWeaponTools must load") then
		fist = fist:Clone()
		local rubber, fistPart = sectionPart(fist, "Rubber"), sectionPart(fist, "Fist")
		if T.check(rubber ~= nil and fistPart ~= nil, "the Gum-Gum fist needs a Rubber and a Fist section") then
			local rubberWeld, fistWeld = rubber:FindFirstChild("HeroWeaponWeld"), fistPart:FindFirstChild("HeroWeaponWeld")
			local dir = rubberWeld.C0.Position.Unit
			local restLength, restFist = lengthAlong(rubber, dir), fistWeld.C0.Position
			Kit.SetGomuTime(fist, 0.30) -- the peak of Gomu_Pistol: stretch 2.25
			T.check(math.abs(lengthAlong(rubber, dir) - restLength * 2.25) < 1e-3, "SetGomuTime must stretch the rubber arm x2.25 at the punch")
			T.check((fistWeld.C0.Position - restFist).Magnitude > 1.6, "SetGomuTime must throw the fist forward")
			Kit.SetGomuTime(fist, 0)
			T.check(math.abs(lengthAlong(rubber, dir) - restLength) < 1e-3 and (fistWeld.C0.Position - restFist).Magnitude < 1e-3,
				"SetGomuTime(tool, 0) must reset the fist")
		end
	end
	-- the Power Pole's Handle is a cylinder (it runs along its own X): the stretch must follow the pole, not the
	-- Handle's Y (review: the shaft got fat and the tip flew up the forearm). The owner's imported pole has no Extend
	-- section (it does not extend), so this only runs on the part stand-in.
	local pole = shopItems and shopItems:FindFirstChild("Forest Bat")
	if type(Kit) == "table" and pole ~= nil and sectionPart(pole, "Extend") then
		pole = pole:Clone()
		local shaft, tip = sectionPart(pole, "Extend"), sectionPart(pole, "Tip")
		local shaftWeld, tipWeld = shaft:FindFirstChild("HeroWeaponWeld"), tip:FindFirstChild("HeroWeaponWeld")
		local restSize, restShaft, restTip = shaft.Size, shaftWeld.C0.Position, tipWeld.C0.Position
		local dir = restShaft.Unit
		Kit.SetPoleTime(pole, 0.25) -- fully out: stretch 2.3
		local length = tip:GetAttribute("StretchLength")
		T.check(math.abs(shaft.Size.X - restSize.X * 2.3) < 1e-3 and math.abs(shaft.Size.Y - restSize.Y) < 1e-3,
			"SetPoleTime must lengthen the shaft, not fatten it")
		T.check(((tipWeld.C0.Position - restTip) - dir * (1.3 * length)).Magnitude < 1e-3,
			"SetPoleTime must carry the tip out along the pole, to the shaft's new end")
		Kit.SetPoleTime(pole, 0)
		T.check((tipWeld.C0.Position - restTip).Magnitude < 1e-3 and math.abs(shaft.Size.X - restSize.X) < 1e-3,
			"SetPoleTime(tool, 0) must pull the pole back in")
	end
end

-- 4. server + client wiring
local gearSrc = src(H.path(sss, "GearService"))
for _, needle in ipairs({ "local function onHeroWeaponActivated(", "local function applyDebuff(", "HeroWeapons.Timing(weapon.Id)",
	"Action = \"Debuff\"", "Action = \"Launch\"", "character:SetAttribute(DEBUFF_ATTRIBUTE, effectName)",
	"pcall(WeaponKit.Attach, tool, character)", "pcall(endDebuff, player, character, nil)" }) do
	T.check(H.has(gearSrc, needle), "GearService must contain %s", needle)
end
T.check(pcall(H.luau.compile, gearSrc), "GearService does not compile")
local controller = H.path(sps, "BranchControllers/HeroWeaponController")
local controllerSrc = src(controller)
T.check(controller ~= nil and pcall(H.luau.compile, controllerSrc), "BranchControllers.HeroWeaponController missing or broken")
for _, effect in pairs(OWNER_EFFECTS) do
	T.check(H.has(controllerSrc, "effect == \"" .. effect .. "\""), "HeroWeaponController must draw %s", effect)
end
T.check(H.has(controllerSrc, "Kit.SetGomuTime") and H.has(controllerSrc, "Kit.SetPoleTime"), "the fist and the pole must stretch on their clips")
local batFxSrc = src(H.path(sps, "Game/Tools/BatCombatFx"))
T.check(H.has(batFxSrc, "payload.Weapon ~= nil") and H.has(batFxSrc, "GetAttribute(\"HeroWeaponId\") == nil"),
	"BatCombatFx must leave hero weapons to HeroWeaponController")
T.check(H.path(rs, "Library/Client/WeaponPortrait") ~= nil, "Library.Client.WeaponPortrait missing")
T.check(H.has(src(H.path(sps, "GUI/BackpackController/Main")), "mountWeaponPortrait(Icon, p135)"), "hotbar gear slots must show the weapon")
T.check(H.has(src(H.path(sps, "GUI/Index/AreaIndexProgressComponent")), "WeaponPortrait.Mount, image, gearId"),
	"the Index stage card must show the weapon")
T.check(H.has(src(H.path(sss, "StageHazardService")), "GetAttribute(\"HeroDebuff\") ~= nil"),
	"StageHazardService must leave a debuffed player's WalkSpeed to GearService")

-- 5b. the owner's FBX models: Studio import helper, extraction, build path, effect meshes
local importHelper = H.fs.isFile("assets/hero_weapons/HeroWeaponsImport.lua") and H.fs.readFile("assets/hero_weapons/HeroWeaponsImport.lua") or ""
T.check(pcall(H.luau.compile, importHelper) and H.has(importHelper, "pcall(Kit.Prepare, model, spec.id)")
	and H.has(importHelper, "HeroWeaponImports"), "assets/hero_weapons/HeroWeaponsImport.lua must prepare the imports with the owner's kit")
for _, name in ipairs({ "CapShield", "PowerPole", "WebShooter", "Batarang", "Bakugo_Gauntlet", "Mjolnir", "GomuFist",
	"Web_Blob", "Web_Net", "Web_Cocoon", "Mjolnir_Lightning", "Dazed_Stars", "Comic_Explosion", "Bat_Smoke_Cloud" }) do
	T.check(H.has(importHelper, "[\"" .. name .. "\"]"), "the import helper must know %s.fbx", name)
end
local buildSrc = H.fs.readFile("scripts/build_stealahero.luau")
T.check(H.has(buildSrc, "require(\"./lib/hero_weapon_imports\").fromPlaceFile(OUT_PATH)"),
	"the build must extract ServerStorage.HeroWeaponImports from a Studio save before overwriting it")
local stepSrc = H.fs.readFile("scripts/steps/post_hero_weapons.luau")
T.check(H.has(stepSrc, "function Step.BuildWeaponFromImport(") and H.has(stepSrc, "local grip = gripFromHand:Inverse() * Step.GRIP_ATTACHMENT"),
	"post_hero_weapons must build the tools from the owner's imported models")
local vfxFolder = rs:FindFirstChild("HeroWeaponVfx")
T.check(vfxFolder ~= nil, "ReplicatedStorage.HeroWeaponVfx missing (empty until the effects are imported)")
for _, model in ipairs(vfxFolder and vfxFolder:GetChildren() or {}) do
	T.check(model.PrimaryPart == nil and model.WorldPivotData ~= nil and model.WorldPivotData.Position.Magnitude < 1e-3,
		"HeroWeaponVfx.%s must pivot on its FBX origin (no PrimaryPart)", model.Name)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			T.check(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,
				"HeroWeaponVfx.%s.%s must be anchored and never collide", model.Name, part.Name)
		end
	end
end
for _, name in ipairs({ "Web_Cocoon", "Dazed_Stars", "Mjolnir_Lightning", "Comic_Explosion", "Bat_Smoke_Cloud", "Web_Blob", "Web_Net" }) do
	T.check(H.has(controllerSrc, "\"" .. name .. "\""), "HeroWeaponController must use the owner's %s when imported", name)
end

-- 5d. owner 2026-09-27: "no VFX made of meshes anywhere, apart from the ones I sent" - the controller builds no parts
-- (particles, Beams, Trails and the owner's 7 effect models only)
for _, needle in ipairs({ "Instance.new(\"Part\")", "Instance.new(\"WedgePart\")", "Instance.new(\"MeshPart\")",
	"Enum.PartType.Ball", "Enum.PartType.Cylinder", "Instance.new(\"SpecialMesh\")" }) do
	T.check(not H.has(controllerSrc, needle), "HeroWeaponController must not build part / mesh VFX (%s)", needle)
end
-- the owner's imported models are in the build (assets/hero_weapons/imports, from their Studio rbxm)
if H.fs.isDir("assets/hero_weapons/imports/weapons") then
	for toolName, weaponId in pairs(OWNER_MAPPING) do
		local tool = shopItems and shopItems:FindFirstChild(toolName)
		if tool and H.fs.isFile("assets/hero_weapons/imports/weapons/" .. weaponId .. ".rbxm") then
			T.check(tool:GetAttribute("HeroWeaponModel") == "Import", "%s must use the owner's imported %s model", toolName, weaponId)
			local meshes = 0
			for _, part in ipairs(tool:GetChildren()) do
				if part:IsA("MeshPart") then
					meshes += 1
				end
			end
			T.check(meshes >= 2, "%s: the owner's MeshParts must be in the tool (%d)", toolName, meshes)
		end
	end
	for _, name in ipairs({ "Web_Blob", "Web_Net", "Web_Cocoon", "Mjolnir_Lightning", "Dazed_Stars", "Comic_Explosion", "Bat_Smoke_Cloud" }) do
		if H.fs.isFile("assets/hero_weapons/imports/vfx/" .. name .. ".rbxm") then
			local model = vfxFolder and vfxFolder:FindFirstChild(name)
			T.check(model ~= nil and model:FindFirstChildWhichIsA("BasePart", true) ~= nil, "HeroWeaponVfx.%s (the owner's effect) missing", name)
		end
	end
end

-- 5c. "the ragdoll does not get back up, and the weapons can be used while down" (owner 2026-09-27)
local ragdollSrc0 = src(H.path(sps, "Game/Tools/GearRagdollController"))
for call in string.gmatch(ragdollSrc0, "bodyParts%(([^)]*)%)") do
	T.check(call == "character, humanoid", "GearRagdollController must pass the Humanoid to bodyParts (got bodyParts(%s)): the get-up loop errored every frame", call)
end
T.check(H.has(ragdollSrc0, "pcall(humanoid.UnequipTools, humanoid)"), "a ragdolled player must put the weapon away")
T.check(H.has(gearSrc, "and not isDown(character)"), "GearService must refuse attacks from a body that is down")
T.check(H.has(controllerSrc, "HeroWeaponController.DOWN_STATES[current]") and H.has(controllerSrc, "local function standBackUp(state)")
	and H.has(controllerSrc, "holdUpright(state, humanoid)"), "weapon victims must stay upright and get back up")

-- 5. owner's reports
T.check(H.has(gearSrc, "local debuff = debuffs[character]") and H.has(gearSrc, "if debuffs[character] ~= state or state.restored or"),
	"a trap freezing a debuffed player must take the movement over from the state")
T.check(H.has(gearSrc, "offsets[descendant] = pivot:ToObjectSpace(descendant.CFrame)") and H.has(gearSrc, "part.CFrame = trap.CFrame * offset"),
	"a placed trap must move its Hitbox with it (it stayed in the lobby: traps never caught anyone)")
local trapTemplate = H.path(rs, "Assets/ToolEffects/PlayerTrap")
local hitbox = trapTemplate and trapTemplate:FindFirstChild("Hitbox")
T.check(hitbox ~= nil and (hitbox.CFrame.Position - trapTemplate.CFrame.Position).Magnitude < 3, "the PlayerTrap template's Hitbox must sit on the trap")
local ragdollSrc = src(H.path(sps, "Game/Tools/GearRagdollController"))
T.check(H.has(ragdollSrc, "local function isBodyPart(") and H.has(ragdollSrc, "for _, part in ipairs(character:GetChildren()) do")
	and H.has(gearSrc, "isBodyPart(character, humanoid, part0) and isBodyPart(character, humanoid, part1)"),
	"the ragdoll must only joint / collide the real body parts (aura / trail parts made it stiff)")
local settingsSrc = src(H.path(sps, "GUI/Settings"))
T.check(H.has(settingsSrc, "pcall(SettingsCmds.IsEnabled, \"ShowMoneyPopups\")") and H.has(settingsSrc, "ShowMoneyPopups.Status.Text"),
	"the Money Popups row must paint its real value (it showed the template's On)")
T.check(H.has(settingsSrc, "DESCRIPTION_RIGHT") and pcall(H.luau.compile, settingsSrc), "settings descriptions must end before the button")
