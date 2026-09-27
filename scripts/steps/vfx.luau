-- scripts/steps/vfx.luau
-- Build step: ports a small, hand-picked set of "brainrot" VFX from the V40 Steal a Brainrot place
-- (`Update2/Outdated/V40 SAB by FaypleStudios.rbxl`, read-only reference) into
-- `ReplicatedStorage.Assets.VFX.SAB`, where the client script
-- `StarterPlayer.StarterPlayerScripts.Game.SabVfxController` (scripts/inject/vfx.luau) clones them onto the
-- moments Steal a Hero already has: a hero hatching onto the plot, its rarity aura, the villain chase, the
-- stolen-egg run, the treadmill sprint, a money tick and the safe-zone escape.
--
-- Why these sources: they are self-contained instances (one Part with ParticleEmitters/Attachments, or a
-- Trail with its two attachments), so they clone-and-parent with no script of their own -- exactly what the
-- runtime needs. `ReplicatedStorage.Vfx.Traits.<Name>.VfxInstance` is SAB's mutation-aura set, and
-- `Shared.VFX.Library.Misc.LuckyBlockUnbox` / `Assets.Tools.Flash Teleport.lightningappear` are its
-- authored one-shot bursts (already `Enabled = false`, designed for `:Emit()`).
--
-- Rules honoured here:
--   * NO Sound is ever copied (the game has a strict audio whitelist; every Sound in a clone is destroyed).
--   * no Script/LocalScript/ModuleScript, Highlight (Roblox caps ~31 per client), Light, Explosion, Fire,
--     Smoke, joint or Bone is copied either -- particles, beams, trails and attachments only.
--   * Content properties (ParticleEmitter texture, MeshPart mesh) are never re-written, only carried along by
--     a whole-subtree `:Clone()`, so the Lune 0.10.5 Content gotchas cannot bite (CONTRACTS §0.5).
--   * every emitter/beam/trail is stored `Enabled = false` and rate-capped; the client enables auras and
--     `:Emit()`s the one-shots, so nothing in ReplicatedStorage ever emits on its own.
--   * duplicate sibling emitters (same name/texture/colour/rate) are collapsed and each effect is capped, so
--     a 105-emitter teleport burst ships as a dozen.
--
-- Idempotent: the SAB folder is destroyed and rebuilt from the reference place on every build. If the
-- reference place is missing (another machine), the step prints and skips -- the rest of the build is
-- unaffected and the client script no-ops when the folder is absent.

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local Instance = roblox.Instance

local Step = {}

-- The read-only reference place (override with STEALAHERO_SAB_PLACE).
-- vendor/sab_vfx.rbxl holds only the Step.EFFECTS subtrees (scripts/tools/vendor_sab_vfx.luau), so the repo does not
-- carry the full third-party reference place; the owner's local copy is the fallback.
Step.SAB_PLACE_PATH = if fs.isFile("vendor/sab_vfx.rbxl") then "vendor/sab_vfx.rbxl"
	else "C:/Users/Aoshy´/Desktop/Update2/Outdated/V40 SAB by FaypleStudios.rbxl"
Step.PARENT_PATH = { "Assets", "VFX" } -- inside ReplicatedStorage; both already exist in the base place
Step.FOLDER_NAME = "SAB"

Step.MAX_AURA_RATE = 12 -- particles/second per emitter for a looping aura
Step.MAX_BURST_RATE = 30 -- one-shots are :Emit()ed, the rate only bounds an accidental Enabled = true
Step.MAX_AURA_EMITTERS = 14
Step.MAX_BURST_EMITTERS = 20

-- Classes that may live inside a ported effect. Everything else is dropped (see header).
Step.KEEP_CLASSES = {
	Part = true,
	MeshPart = true,
	Attachment = true,
	ParticleEmitter = true,
	Beam = true,
	Trail = true,
}

-- name = what the client looks up | source = path inside the reference place's ReplicatedStorage
-- kind  = "Aura" (looping, attached while a state lasts) or "Burst" (one-shot :Emit) or "Trail"
-- purpose = the Steal a Hero moment it plays on (also written as an attribute, for probes and Studio)
Step.EFFECTS = {
	{
		name = "Aura_Epic",
		source = "Vfx/Traits/Lucky/VfxInstance",
		kind = "Aura",
		purpose = "Epic hero on the plot: gold sparkle halo",
	},
	{
		name = "Aura_Legendary",
		source = "Vfx/Traits/Lightning/VfxInstance",
		kind = "Aura",
		purpose = "Legendary hero on the plot: blue lightning arcs",
	},
	{
		name = "Aura_Mythic",
		source = "Vfx/Traits/Galactic/VfxInstance",
		kind = "Aura",
		purpose = "Mythic hero on the plot: purple galaxy swirl",
	},
	{
		name = "Aura_Secret",
		source = "Vfx/Traits/Glitched/VfxInstance",
		kind = "Aura",
		purpose = "Secret hero on the plot: RGB glitch shards",
	},
	{
		name = "Aura_Villain",
		source = "Vfx/Traits/Fire/VfxInstance",
		kind = "Aura",
		purpose = "Zone villain while GuardState = Chasing: orange fire aura",
	},
	{
		name = "Aura_Carry",
		source = "Vfx/Traits/Cometstruck/VfxInstance",
		kind = "Aura",
		purpose = "Local player while carrying a stolen area egg: blue comet stars",
	},
	{
		name = "Burst_Hatch",
		source = "Shared/VFX/Library/Misc/LuckyBlockUnbox",
		kind = "Burst",
		purpose = "A hatched hero appears on the plot: unbox burst",
	},
	{
		name = "Burst_Escape",
		source = "Assets/Tools/Flash Teleport/lightningappear",
		kind = "Burst",
		purpose = "Stolen egg claimed in the safe zone (bounty paid, Eggs: AreaEggClaimFeedback): white lightning burst",
	},
	{
		name = "Sparkle_Cash",
		source = "Controllers/EventController/Events/Eggrot Hunt/CoinVisuals/Drop",
		kind = "Burst",
		purpose = "Hero income tick: gold coin sparkle (throttled client-side)",
	},
	{
		name = "Trail_Speed",
		source = "Vfx/Traits/Nyan/VfxInstance",
		kind = "Trail",
		purpose = "Local player while running on the treadmill: speed trail",
	},
}

local function findByPath(root, path)
	local node = root
	for segment in string.gmatch(path, "[^/]+") do
		if not node then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local function get(inst, prop)
	local ok, value = pcall(function()
		return (inst :: any)[prop]
	end)
	if ok then
		return value
	end
	return nil
end

-- Identity of an emitter for duplicate collapsing: SAB layers the same emitter several times under one
-- parent; one copy reads the same and costs a fraction.
local function emitterKey(inst)
	return table.concat({
		inst.ClassName,
		inst.Name,
		tostring(get(inst, "TextureContent")),
		tostring(get(inst, "Color")),
		tostring(get(inst, "Rate")),
		tostring(get(inst, "Size")),
		tostring(get(inst, "Lifetime")),
	}, "|")
end

-- Strips everything that is not a particle/beam/trail/attachment/part, collapses duplicate emitters,
-- disables and rate-caps what is left, and makes every part a weightless, invisible, non-colliding host.
-- Returns emitters kept, instances dropped.
local function sanitize(root, effect)
	local isBurst = effect.kind ~= "Aura"
	local maxRate = isBurst and Step.MAX_BURST_RATE or Step.MAX_AURA_RATE
	local maxEmitters = isBurst and Step.MAX_BURST_EMITTERS or Step.MAX_AURA_EMITTERS
	local dropped = 0

	-- 1. class filter (a dropped container takes its subtree with it, which is what we want)
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil and not Step.KEEP_CLASSES[d.ClassName] then
			d:Destroy()
			dropped += 1
		end
	end
	-- Trails carry Attachment0/Attachment1 references; only the effect that is a trail keeps its own.
	if effect.kind ~= "Trail" then
		for _, d in ipairs(root:GetDescendants()) do
			if d.Parent ~= nil and d.ClassName == "Trail" then
				d:Destroy()
				dropped += 1
			end
		end
	end

	-- 2. collapse duplicate sibling emitters
	local seenBySibling = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil and d.ClassName == "ParticleEmitter" then
			local bucket = seenBySibling[d.Parent]
			if not bucket then
				bucket = {}
				seenBySibling[d.Parent] = bucket
			end
			local key = emitterKey(d)
			if bucket[key] then
				d:Destroy()
				dropped += 1
			else
				bucket[key] = true
			end
		end
	end

	-- 3. cap the emitter count (SAB's teleport burst ships 105 of them)
	local kept = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil and d.ClassName == "ParticleEmitter" then
			if kept >= maxEmitters then
				d:Destroy()
				dropped += 1
			else
				kept += 1
			end
		end
	end

	-- 4. disable + rate-cap what survives, and remember how much to :Emit() for one-shots
	for _, d in ipairs(root:GetDescendants()) do
		if d.ClassName == "ParticleEmitter" then
			local emitter = d :: any
			local rate = get(d, "Rate") or 0
			emitter.Enabled = false
			emitter.Rate = math.min(rate, maxRate)
			if isBurst then
				d:SetAttribute("SabEmit", math.clamp(math.round(rate * 0.4), 3, 20))
			end
		elseif d.ClassName == "Beam" or d.ClassName == "Trail" then
			local effectInstance = d :: any
			effectInstance.Enabled = false
		end
	end

	-- 5. hosts are invisible, weightless, non-colliding anchors -- they only carry the effect children
	local parts = { root }
	for _, d in ipairs(root:GetDescendants()) do
		table.insert(parts, d)
	end
	for _, d in ipairs(parts) do
		if d.ClassName == "Part" or d.ClassName == "MeshPart" then
			local p = d :: any
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Massless = true
			p.Transparency = 1
			p.Locked = true
		end
	end

	-- 6. empty attachments left behind by the pruning -- except the ones a surviving Trail/Beam uses as its
	-- endpoints (those are childless by design and destroying them would nil out the trail).
	local endpoints = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d.ClassName == "Trail" or d.ClassName == "Beam" then
			for _, prop in ipairs({ "Attachment0", "Attachment1" }) do
				local attachment = get(d, prop)
				if attachment ~= nil then
					endpoints[attachment] = true
				end
			end
		end
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d.Parent ~= nil and d.ClassName == "Attachment" and #d:GetChildren() == 0 and not endpoints[d] then
			d:Destroy()
			dropped += 1
		end
	end

	return kept, dropped
end

function Step.Apply(place, _spPlace, ctx)
	local roblox_ = (ctx and ctx.roblox) or roblox
	local fs_ = (ctx and ctx.fs) or fs

	local sabPath = process.env.STEALAHERO_SAB_PLACE
	if sabPath == nil or sabPath == "" then
		sabPath = Step.SAB_PLACE_PATH
	end
	if not fs_.isFile(sabPath) then
		print(
			string.format(
				"[VFX] Reference place not found at %s -- skipping the SAB VFX port (set STEALAHERO_SAB_PLACE to override).",
				sabPath
			)
		)
		return
	end

	local sabPlace = roblox_.deserializePlace(fs_.readFile(sabPath))
	local sabRs = sabPlace:GetService("ReplicatedStorage")

	local rs = place:GetService("ReplicatedStorage")
	local parent = rs
	for _, name in ipairs(Step.PARENT_PATH) do
		local child = parent:FindFirstChild(name)
		if not child then
			child = Instance.new("Folder")
			child.Name = name
			child.Parent = parent
		end
		parent = child
	end

	local existing = parent:FindFirstChild(Step.FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = Step.FOLDER_NAME
	folder.Parent = parent

	local ported, totalEmitters, missing = 0, 0, {}
	for _, effect in ipairs(Step.EFFECTS) do
		local source = findByPath(sabRs, effect.source)
		if not source then
			table.insert(missing, effect.name .. " (" .. effect.source .. ")")
			continue
		end
		-- whole-subtree clone in one call (CONTRACTS §0.5: per-child cloning loses references)
		local clone = source:Clone()
		clone.Name = effect.name
		local kept, dropped = sanitize(clone, effect)
		clone:SetAttribute("SabKind", effect.kind)
		clone:SetAttribute("SabPurpose", effect.purpose)
		clone:SetAttribute("SabSource", "ReplicatedStorage/" .. effect.source)
		clone:SetAttribute("SabEmitters", kept)
		clone.Parent = folder
		ported += 1
		totalEmitters += kept
		print(
			string.format(
				"[VFX]   %-16s %-2d emitters (dropped %d) <- %s -- %s",
				effect.name,
				kept,
				dropped,
				effect.source,
				effect.purpose
			)
		)
	end

	-- Safety net: nothing audible, nothing scripted, nothing enabled may reach the built place.
	local sounds, scripts, enabled = 0, 0, 0
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("Sound") then
			d:Destroy()
			sounds += 1
		elseif d:IsA("LuaSourceContainer") then
			d:Destroy()
			scripts += 1
		elseif d.ClassName == "ParticleEmitter" or d.ClassName == "Beam" or d.ClassName == "Trail" then
			if get(d, "Enabled") == true then
				local effectInstance = d :: any
				effectInstance.Enabled = false
				enabled += 1
			end
		end
	end

	if #missing > 0 then
		print(string.format("[VFX] !! %d effect(s) not found in the reference place: %s", #missing, table.concat(missing, ", ")))
	end
	print(
		string.format(
			"[VFX] Ported %d SAB effects (%d emitters, all Enabled = false) into ReplicatedStorage.%s.%s; removed %d Sounds, %d scripts, disabled %d strays.",
			ported,
			totalEmitters,
			table.concat(Step.PARENT_PATH, "."),
			Step.FOLDER_NAME,
			sounds,
			scripts,
			enabled
		)
	)
end

return Step
