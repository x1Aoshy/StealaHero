-- StarterPlayer.StarterPlayerScripts.Game.SabVfxController (LocalScript)
-- Plays the ported "brainrot" VFX (ReplicatedStorage.Assets.VFX.SAB, built by scripts/steps/vfx.luau) on the
-- moments Steal a Hero already broadcasts. It only listens -- no other script is modified, no remote is
-- invoked, no server state is touched:
--
--   hero appears on a plot   workspace.ClientRenderedAssets child (ItemDisplay.CreateWanderingAssetModel)
--                            -> Burst_Hatch once (not while the folder's SuppressHatchBurst attribute is set: a Hero
--                            Size rebuild), then the rarity aura for the model's HeroId attribute, scaled to the
--                            model's rendered Scale
--   (villain chase: no aura any more; owner 2026-09-27 "remove the fire VFX" -- Aura_Villain stays stored, unused)
--   stolen egg run           nothing on the character any more (owner 2026-09-27)
--   escape / bounty paid     remote "Eggs: AreaEggClaimFeedback", which AreaEggService fires to the carrier
--                            only when the claim paid out (the carry reached the safe zone: X <= 75 or
--                            GameplayZ) -> Burst_Escape. A carry that ends any other way (villain catch in
--                            the X 75-80 strip the chase still covers, gear knock, manual drop) never plays it.
--   treadmill sprint         remote "Treadmills: ActiveTreadmillChanged" (non-nil id = running) -> Trail_Speed
--   money tick               nothing on the character any more (owner 2026-09-27: no pulsing gold sparkle)
--
-- Cost rules: every stored emitter arrives Enabled = false; auras are enabled only while their state lasts and
-- are capped (MAX_AURAS) so a full plot cannot light up the whole screen; the local player's own heroes win
-- aura slots over other players' heroes, and with the "Hide Other Pets" setting on, other players' heroes get
-- no aura and no hatch burst at all (likewise the local player's own heroes with "Hide Your Heroes" / HideMyPets
-- on); one-shots run on a temporary part that Debris removes; no Highlight and no Sound is ever created.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local LOOKUP_TIMEOUT = 20
local BURST_LIFETIME = 4 -- seconds a one-shot host part stays before Debris removes it
local MAX_AURAS = 8 -- simultaneous hero auras on this client
local AURA_TAG = "SabVfxAura"

local LocalPlayer = Players.LocalPlayer

local assets = ReplicatedStorage:WaitForChild("Assets", LOOKUP_TIMEOUT)
local vfxFolder = assets and assets:WaitForChild("VFX", LOOKUP_TIMEOUT)
local Sab = vfxFolder and vfxFolder:WaitForChild("SAB", LOOKUP_TIMEOUT)
if not Sab then
	-- The build step did not run (missing reference place): stay silent instead of erroring every join.
	return
end

local Network = ReplicatedStorage:WaitForChild("Network", LOOKUP_TIMEOUT)

-- Rarity -> effect. Common and Rare stay clean so the rarer heroes read as special.
local AURA_BY_RARITY = {
	Epic = "Aura_Epic",
	Legendary = "Aura_Legendary",
	Mythic = "Aura_Mythic",
	Secret = "Aura_Secret",
}

-- Per-hero aura colour (same effect, recoloured to fit the character). Owner 2026-09-27: Shanks' lightning red.
local AURA_TINT_BY_HERO = {
	Shanks = Color3.fromRGB(255, 38, 46),
}

local HeroCatalog do
	local directory = ReplicatedStorage:WaitForChild("Directory", LOOKUP_TIMEOUT)
	local module = directory and directory:FindFirstChild("HeroCatalog")
	if module then
		local ok, result = pcall(require, module)
		HeroCatalog = ok and result or nil
	end
end

---------------------------------------------------------------------------------------------------
-- Generic helpers
---------------------------------------------------------------------------------------------------

-- Copies an effect's children (emitters, attachments-with-emitters, beams) onto a live BasePart. The stored
-- host part itself is never parented into the world: particles emit from whatever part they sit in, so the
-- target needs no weld, no physics and no cleanup beyond destroying what we added.
local function copyEffect(effectName, targetPart, tag)
	local template = Sab:FindFirstChild(effectName)
	if not template or not targetPart then
		return {}
	end
	local copied = {}
	for _, child in ipairs(template:GetChildren()) do
		local className = child.ClassName
		if className == "ParticleEmitter" or className == "Attachment" or className == "Beam" then
			local clone = child:Clone()
			clone:SetAttribute(AURA_TAG, tag or effectName)
			clone.Parent = targetPart
			table.insert(copied, clone)
		end
	end
	return copied
end

local function setEnabled(copied, enabled)
	for _, instance in ipairs(copied) do
		if instance.Parent == nil then
			continue
		end
		if instance:IsA("ParticleEmitter") or instance:IsA("Beam") then
			instance.Enabled = enabled
		end
		for _, descendant in ipairs(instance:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
				descendant.Enabled = enabled
			end
		end
	end
end

-- HEROES (Gekko #6/#8): hero auras follow the rendered size of the hero (Hero Size setting + compressed rolls, the
-- model's Scale), so a small hero is not buried in a full-size aura and a big one is not bare. Same math as
-- ReplicatedStorage.Library.Functions.ScaleParticle (size, speed, drag, acceleration, z-offset).
local AURA_SCALE_MIN, AURA_SCALE_MAX = 0.35, 3

local function auraScaleOf(model)
	local ok, scale = pcall(function()
		return model:GetScale()
	end)
	if not ok or typeof(scale) ~= "number" or scale ~= scale or scale <= 0 then
		return 1
	end
	return math.clamp(scale, AURA_SCALE_MIN, AURA_SCALE_MAX)
end

local function scaleEmitter(emitter, factor)
	local keypoints = {}
	for _, keypoint in ipairs(emitter.Size.Keypoints) do
		table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * factor, keypoint.Envelope * factor))
	end
	emitter.Size = NumberSequence.new(keypoints)
	emitter.Drag = emitter.Drag * factor
	emitter.Speed = NumberRange.new(emitter.Speed.Min * factor, emitter.Speed.Max * factor)
	emitter.Acceleration = emitter.Acceleration * factor
	emitter.ZOffset = emitter.ZOffset * factor
end

local function scaleCopied(copied, factor)
	if math.abs(factor - 1) < 0.01 then
		return
	end
	for _, instance in ipairs(copied) do
		if instance:IsA("ParticleEmitter") then
			pcall(scaleEmitter, instance, factor)
		end
		for _, descendant in ipairs(instance:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				pcall(scaleEmitter, descendant, factor)
			end
		end
	end
end

-- Recolours copied emitters / beams to `tint`, keeping their bright cores bright: each colour keypoint becomes the tint
-- lifted toward white by how close to white it was.
local function tintSequence(sequence, tint)
	local keypoints = {}
	for _, keypoint in ipairs(sequence.Keypoints) do
		local c = keypoint.Value
		local luminance = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
		local lift = math.clamp((luminance - 0.55) / 0.45, 0, 1) * 0.55
		table.insert(keypoints, ColorSequenceKeypoint.new(keypoint.Time, tint:Lerp(Color3.new(1, 1, 1), lift)))
	end
	return ColorSequence.new(keypoints)
end

local function tintCopied(copied, tint)
	for _, instance in ipairs(copied) do
		local list = instance:GetDescendants()
		table.insert(list, instance)
		for _, d in ipairs(list) do
			if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
				pcall(function()
					d.Color = tintSequence(d.Color, tint)
				end)
			end
		end
	end
end

local function destroyCopied(copied)
	for _, instance in ipairs(copied) do
		if instance.Parent ~= nil then
			instance:Destroy()
		end
	end
end

-- One-shot: a temporary anchored host at `position` emits the effect once and is removed by Debris.
local function playBurst(effectName, position)
	local template = Sab:FindFirstChild(effectName)
	if not template or typeof(position) ~= "Vector3" then
		return
	end
	local host = Instance.new("Part")
	host.Name = "SabVfx_" .. effectName
	host.Size = Vector3.new(1, 1, 1)
	host.Transparency = 1
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.CastShadow = false
	host.Locked = true
	host.CFrame = CFrame.new(position)
	host.Parent = Workspace

	for _, child in ipairs(template:GetChildren()) do
		local className = child.ClassName
		if className == "ParticleEmitter" or className == "Attachment" then
			child:Clone().Parent = host
		end
	end
	for _, descendant in ipairs(host:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			local count = descendant:GetAttribute("SabEmit")
			descendant:Emit(typeof(count) == "number" and count or 8)
		end
	end
	Debris:AddItem(host, BURST_LIFETIME)
end

local function characterRoot()
	local character = LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart") or nil
end

---------------------------------------------------------------------------------------------------
-- 1. Heroes on the plot: hatch burst + rarity aura
---------------------------------------------------------------------------------------------------

local heroAuras = {} -- Model -> { copied = { emitters... }, connections = { RBXScriptConnection... } }
local heroAuraCount = 0
local renderedFolder = nil -- workspace.ClientRenderedAssets once found
local rescanQueued = false
local onHeroModel -- forward: releaseHeroAura -> rescan -> onHeroModel

-- "Hide Other Pets" (ActiveAssetsController turns other players' heroes transparent, the models stay). Loaded
-- in the background below: SettingsCmds pulls in the client Network/Save modules and hero auras must not
-- wait on them. Until it loads the setting reads as off, and applyHideOthers() corrects that once it does.
local SettingsCmds = nil

local function hideOthers()
	if not SettingsCmds then
		return false
	end
	local ok, enabled = pcall(SettingsCmds.IsEnabled, "HideOtherPets")
	return ok and enabled == true
end

-- "Hide Your Heroes" (HideMyPets): ActiveAssetsController hides the local player's own heroes the same way.
local function hideMine()
	if not SettingsCmds then
		return false
	end
	local ok, enabled = pcall(SettingsCmds.IsEnabled, "HideMyPets")
	return ok and enabled == true
end

-- ItemDisplay.CreateWanderingAssetModel stamps OwnerUserId before parenting the model.
local function isOwn(model)
	return model:GetAttribute("OwnerUserId") == LocalPlayer.UserId
end

-- Whether the hero model is hidden by one of the two settings (then it gets no aura and no burst).
local function isHiddenHero(model)
	if isOwn(model) then
		return hideMine()
	end
	return hideOthers()
end

local function rarityOf(heroId)
	if not HeroCatalog or type(HeroCatalog.Get) ~= "function" then
		return nil
	end
	local ok, entry = pcall(HeroCatalog.Get, heroId)
	return ok and type(entry) == "table" and entry.Rarity or nil
end

-- Gives free aura slots to heroes that were skipped at the cap: the local player's own heroes first (they may
-- evict a foreign aura), then everyone else's. onHeroModel returns early for models that already have one.
local function rescan()
	rescanQueued = false
	if not renderedFolder or renderedFolder.Parent == nil then
		return
	end
	local children = renderedFolder:GetChildren()
	for _, child in ipairs(children) do
		if isOwn(child) then
			onHeroModel(child, false)
		end
	end
	for _, child in ipairs(children) do
		if heroAuraCount >= MAX_AURAS then
			break -- only an own hero can take a slot at the cap, and the pass above already ran them all
		end
		onHeroModel(child, false)
	end
end

-- Coalesced: a plot owner leaving destroys a whole plot of heroes in one frame.
local function queueRescan()
	if rescanQueued then
		return
	end
	rescanQueued = true
	task.defer(rescan)
end

local function releaseHeroAura(model)
	local entry = heroAuras[model]
	if not entry then
		return
	end
	heroAuras[model] = nil
	heroAuraCount -= 1
	for _, connection in ipairs(entry.connections) do
		connection:Disconnect()
	end
	destroyCopied(entry.copied)
	queueRescan() -- the freed slot goes to a hero that was skipped at the cap
end

-- At the cap, an own hero takes the slot of another player's hero. Returns whether a slot was freed.
local function evictForeign()
	for model in pairs(heroAuras) do
		if not isOwn(model) then
			releaseHeroAura(model)
			return true
		end
	end
	return false
end

onHeroModel = function(model, isNew)
	if not model:IsA("Model") or heroAuras[model] or model.Parent == nil then
		return
	end
	local heroId = model:GetAttribute("HeroId")
	if type(heroId) ~= "string" then
		return -- not one of the hero rigs (plain pets keep their own look)
	end
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local own = isOwn(model)
	if isHiddenHero(model) then
		return -- the model is hidden: no burst, no aura (rescan() restores the aura when the setting goes off)
	end

	-- ActiveAssetsController sets SuppressHatchBurst while it rebuilds heroes for a Hero Size change: same heroes, no burst
	if isNew and not (renderedFolder and renderedFolder:GetAttribute("SuppressHatchBurst") == true) then
		playBurst("Burst_Hatch", root.Position)
	end

	local auraName = AURA_BY_RARITY[rarityOf(heroId) or ""]
	if not auraName or not Sab:FindFirstChild(auraName) then
		return
	end
	if heroAuraCount >= MAX_AURAS and not (own and evictForeign()) then
		return
	end
	local copied = copyEffect(auraName, root, "Hero")
	if #copied == 0 then
		return
	end
	scaleCopied(copied, auraScaleOf(model))
	local tint = AURA_TINT_BY_HERO[heroId]
	if tint then
		tintCopied(copied, tint)
	end
	setEnabled(copied, true)
	local entry = { copied = copied, connections = {} }
	heroAuras[model] = entry
	heroAuraCount += 1
	table.insert(entry.connections, model.Destroying:Connect(function()
		releaseHeroAura(model)
	end))
	table.insert(entry.connections, model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			releaseHeroAura(model)
		end
	end))
end

local function watchRenderedAssets(folder)
	renderedFolder = folder
	-- Own heroes first, so the cap never hands the whole budget to the neighbours on join.
	local children = folder:GetChildren()
	for _, child in ipairs(children) do
		if isOwn(child) then
			task.spawn(onHeroModel, child, false)
		end
	end
	for _, child in ipairs(children) do
		task.spawn(onHeroModel, child, false)
	end
	folder.ChildAdded:Connect(function(child)
		task.spawn(onHeroModel, child, true)
	end)
end

do
	local existing = Workspace:FindFirstChild("ClientRenderedAssets")
	if existing then
		watchRenderedAssets(existing)
	else
		local connection
		connection = Workspace.ChildAdded:Connect(function(child)
			if child.Name == "ClientRenderedAssets" then
				connection:Disconnect()
				watchRenderedAssets(child)
			end
		end)
	end
end

-- Setting on: drop every aura on a hidden hero (Hide Other Pets: foreign ones, whose slots go to own heroes;
-- Hide Your Heroes: own ones, whose slots go to other players' heroes). Setting off: rescan() hands the free
-- slots back.
local function applyHideOthers()
	local hidden = {}
	for model in pairs(heroAuras) do
		if isHiddenHero(model) then
			table.insert(hidden, model)
		end
	end
	for _, model in ipairs(hidden) do
		releaseHeroAura(model)
	end
	queueRescan()
end

task.spawn(function()
	local library = ReplicatedStorage:WaitForChild("Library", LOOKUP_TIMEOUT)
	local client = library and library:WaitForChild("Client", LOOKUP_TIMEOUT)
	local module = client and client:WaitForChild("SettingsCmds", LOOKUP_TIMEOUT)
	if not module then
		return
	end
	local ok, result = pcall(require, module)
	if not ok or type(result) ~= "table" or type(result.IsEnabled) ~= "function" then
		return
	end
	SettingsCmds = result
	-- Same Changed/IsEnabled API ActiveAssetsController uses for this setting; Changed also fires when the
	-- saved value arrives with the player's data.
	local changed = result.Changed
	if type(changed) == "table" then
		pcall(function()
			changed:Connect(function(key)
				if key == "HideOtherPets" or key == "HideMyPets" then
					applyHideOthers()
				end
			end)
		end)
	end
	applyHideOthers()
end)

---------------------------------------------------------------------------------------------------
-- 2. Zone villains: no chase aura (owner 2026-09-27: the fire VFX on the villains is gone)
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- 3. Local player: carry aura, escape burst, treadmill trail, cash sparkle
---------------------------------------------------------------------------------------------------

local carryAura = {}
local speedTrail = nil
local carrying = false
local treadmillActive = false

local function clearCharacterEffects()
	destroyCopied(carryAura)
	carryAura = {}
	if speedTrail then
		for _, instance in ipairs(speedTrail) do
			if instance.Parent ~= nil then
				instance:Destroy()
			end
		end
		speedTrail = nil
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	clearCharacterEffects()
	carrying = false
	treadmillActive = false
end)

local function setCarryAura(enabled)
	local root = characterRoot()
	if enabled then
		if #carryAura > 0 or not root then
			return
		end
		carryAura = copyEffect("Aura_Carry", root, "Carry")
		setEnabled(carryAura, true)
	else
		destroyCopied(carryAura)
		carryAura = {}
	end
end

-- The speed trail is the one effect that needs its own endpoints: a Trail draws between two Attachments,
-- so the stored trail is re-pointed at a fresh pair on the character's root.
local function setSpeedTrail(enabled)
	local root = characterRoot()
	if not enabled then
		if speedTrail then
			for _, instance in ipairs(speedTrail) do
				if instance.Parent ~= nil then
					instance:Destroy()
				end
			end
			speedTrail = nil
		end
		return
	end
	if speedTrail or not root then
		return
	end
	local template = Sab:FindFirstChild("Trail_Speed")
	local sourceTrail = template and template:FindFirstChildWhichIsA("Trail", true)
	if not sourceTrail then
		return
	end
	local top = Instance.new("Attachment")
	top.Name = "SabTrailTop"
	top.Position = Vector3.new(0, 1, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "SabTrailBottom"
	bottom.Position = Vector3.new(0, -1, 0)
	bottom.Parent = root
	local trail = sourceTrail:Clone()
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Enabled = true
	trail:SetAttribute(AURA_TAG, "Treadmill")
	trail.Parent = root
	speedTrail = { trail, top, bottom }
end

-- NetworkInit creates most remotes at server start, so one can replicate after this script runs: each lookup
-- waits (bounded) on its own thread instead of silently giving up.
local function connectRemote(name, handler)
	if not Network then
		return
	end
	task.spawn(function()
		local remote = Network:FindFirstChild(name) or Network:WaitForChild(name, LOOKUP_TIMEOUT)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(handler)
		end
	end)
end

-- Stolen egg: no aura on the character any more (owner 2026-09-27: "the character must not have that VFX"; the egg in
-- hand already shows the carry). A leftover aura from before is still cleared when the carry ends.
connectRemote("Eggs: AreaEggCarryState", function(payload)
	local isCarrying = type(payload) == "table" and payload.IsCarrying == true
	if isCarrying == carrying then
		return
	end
	carrying = isCarrying
	if not isCarrying then
		setCarryAura(false)
	end
end)

-- Escape / bounty paid. AreaEggService fires this to the carrier only from a successful claim (egg + cash
-- granted after the carry reached its safe zone), right after the carry-ended update above. The end of a
-- carry alone is not enough: villains chase up to X = 80 while the safe zone starts at X <= 75, so a catch in
-- that strip (and any gear knock or manual drop) also ends the carry next to the hub.
connectRemote("Eggs: AreaEggClaimFeedback", function()
	local root = characterRoot()
	if root then
		playBurst("Burst_Escape", root.Position)
	end
end)

-- Treadmill: a non-nil treadmill id means this client is running on its own belt.
connectRemote("Treadmills: ActiveTreadmillChanged", function(treadmillId)
	local active = treadmillId ~= nil
	if active == treadmillActive then
		return
	end
	treadmillActive = active
	setSpeedTrail(active)
end)

-- Hero income tick: no effect on the character (owner 2026-09-27: the gold sparkle that pulsed on the player every
-- few seconds is gone; the money counter already shows the income).
