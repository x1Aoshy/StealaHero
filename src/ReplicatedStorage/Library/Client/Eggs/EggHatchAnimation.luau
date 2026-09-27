-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw
-- Patched source (base-place bytecode blob dropped: it no longer matches this file). Injected by
-- scripts/inject/hatch.luau. HATCH 2026-09-23: t1.Play no longer bursts the egg into brick shards; see the note
-- above t1.Play. Everything else is the base-place decompilation.

-- decompilation:
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Assets = require(ReplicatedStorage.Directory.Assets)
local Audio = require(ReplicatedStorage.Library.Audio)
local BBFromModelVisibleOnly = require(ReplicatedStorage.Library.Functions.BBFromModelVisibleOnly)
local Bezier = require(ReplicatedStorage.Library.Functions.Bezier)
local Easing = require(ReplicatedStorage.Library.Functions.Easing)
local EggActionMovement = require(script.Parent.EggActionMovement)
local EggRenderer = require(script.Parent.EggRenderer)
local Eggs = require(ReplicatedStorage.Library.Types.Eggs)
local EmitDescendants = require(ReplicatedStorage.Library.Functions.EmitDescendants)

require(ReplicatedStorage.Library.Types.AssetItem)

local ItemDisplay = require(ReplicatedStorage.Library.Modules.ItemDisplay)
local AssetHeroSizePresentation = require(ReplicatedStorage.Library.Modules.AssetHeroSizePresentation)
local Player = require(ReplicatedStorage.Library.Player)
local RenderStepped = require(ReplicatedStorage.Library.Functions.RenderStepped)
local Transparency = require(ReplicatedStorage.Library.Functions.Transparency)
local CollisionGroups = require(ReplicatedStorage.Library.Types.CollisionGroups)
local color3 = Color3.fromRGB(248.0, 248.0, 248.0)
local Assets2 = ReplicatedStorage.Assets
local __DEBRIS = Workspace.__DEBRIS
local PlacedEggOpen = Assets2.Particles["Egg Open"].PlacedEggOpen
local EggExplode = PlacedEggOpen.EggExplode
local Trail = PlacedEggOpen.Trail
local EggPoof = Assets2.EggPoof

assert(__DEBRIS:IsA("Folder"), "Workspace.__DEBRIS must be a Folder")
assert(EggExplode:IsA("Model"), "PlacedEggOpen.EggExplode must be a Model")
assert(Trail:IsA("Trail"), "PlacedEggOpen.Trail must be a Trail")
assert(EggPoof:IsA("BasePart"), "Assets.EggPoof must be a BasePart")

for _, descendant in EggExplode:GetDescendants() do
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = CollisionGroups.PLAYER_COLLISION_GROUP
	end
end

local t1 = {}

local function buildAssetItemData(p1, n1: number?) -- line: 88
	return {
		HasBeenFirstPlaced = false,
		Category = p1.AssetCategory,
		Scale = n1 or p1.AssetScale,
		EyeColor = p1.AssetEyeColor,
		ColorSeed = p1.AssetColorSeed,
		ColorIndex = p1.AssetColorIndex,
		Mutations = p1.Mutations or {},
		BaseMutation = p1.BaseMutation
	}
end
local function playPoofSound() -- line: 101
	-- upvalues: Audio (copy)
	Audio.Play("rbxassetid://102267539121951", script, nil, 1.0)
end
local function playAssetRevealSound(p2, cFrame: CFrame) -- line: 105
	-- upvalues: Assets (copy), Audio (copy)
	local RandomIdleSound = Assets.Directory[p2.AssetCategory].RandomIdleSound

	if RandomIdleSound == nil then
		return nil
	end

	return Audio.PlayFromSoundFile(RandomIdleSound, cFrame)
end
local function autoControlPoint(vector3: Vector3, vector3_2: Vector3) -- line: 114
	local v53 = (vector3 + vector3_2) / 2.0
	local Magnitude = ((vector3 - vector3_2) * Vector3.new(1.0, 0.0, 1.0)).Magnitude
	local v55 = math.max(vector3.Y, vector3_2.Y) + Magnitude * 0.5

	return (Vector3.new(v53.X, v55, v53.Z))
end
local function getPlayerBodyPosition(p3, vector3: Vector3) -- line: 122
	-- upvalues: Player (copy)
	local v58 = Player.Optional.PrimaryPart(p3)

	if v58 then
		return v58:GetPivot().Position
	end

	return vector3
end
local function getBottomCFrameFacingPlayer(n2: number, vector3: Vector3, cFrame: CFrame) -- line: 127
	-- upvalues: Players (copy), Player (copy)
	local PlayerByUserId = Players:GetPlayerByUserId(n2)

	if PlayerByUserId == nil then
		return CFrame.new(vector3) * cFrame
	end

	local v63 = Player.Optional.PrimaryPart(PlayerByUserId)
	local v64 = if not v63 then vector3 else v63:GetPivot().Position
	local vector3_3 = Vector3.new(v64.X, vector3.Y, v64.Z)

	if (vector3 - vector3_3).Magnitude < 0.001 then
		return CFrame.new(vector3) * cFrame
	end

	return CFrame.lookAt(vector3, vector3_3)
end
local function shakeEggPass(p4, cFrame: CFrame, n3: number) -- line: 146
	-- upvalues: RunService (copy), EggActionMovement (copy)
	local n4 = 0.0

	while n4 < 0.5 do
		n4 += RunService.Heartbeat:Wait()

		local v70 = (1.0 - n4 / 0.5) * math.sin(tick() * 90.0) * n3

		EggActionMovement.SetPivot(p4, cFrame * CFrame.Angles(0.0, 0.0, (math.rad(v70))))
	end
end
local function shakeEgg(p5, cFrame: CFrame) -- line: 155
	-- upvalues: shakeEggPass (copy)
	shakeEggPass(p5, cFrame, 7.0)
	task.wait(0.3)
	shakeEggPass(p5, cFrame, 9.0)
	task.wait(0.3)
	shakeEggPass(p5, cFrame, 13.0)
end
local function pivotAssetToEggBottom(p6, cFrame: CFrame) -- line: 163
	-- upvalues: BBFromModelVisibleOnly (copy)
	local Pivot = p6:GetPivot()
	local v76, v77 = BBFromModelVisibleOnly(p6)
	local v78 = v76.Position - Vector3.new(0.0, 1.0, 0.0) * (v77.Y * 0.5) - Pivot.Position
	local v79 = cFrame.Position - v78
	local v80 = cFrame - cFrame.Position

	p6:PivotTo(CFrame.new(v79) * v80)
end
local function growAsset(p7, cFrame: CFrame, n5: number) -- line: 174
	-- upvalues: RenderStepped (copy), Easing (copy), pivotAssetToEggBottom (copy)
	local v84 = n5 * 0.5

	RenderStepped(function(_, p9) -- line: 176
		-- upvalues: p7 (copy), Easing (copy), v84 (copy), n5 (copy), pivotAssetToEggBottom (copy), cFrame (copy)
		if p7.Parent == nil then
			return true
		end

		local v175 = Easing(p9, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)

		p7:ScaleTo(v84 + (n5 - v84) * v175)
		pivotAssetToEggBottom(p7, cFrame)
	end, 1.3, true):Wait()

	if p7.Parent ~= nil then
		p7:ScaleTo(n5)
		pivotAssetToEggBottom(p7, cFrame)
	end
end
local function lookAtPlayer(p10, p11) -- line: 194
	-- upvalues: RenderStepped (copy), Player (copy), Easing (copy)
	local Pivot = p10:GetPivot()

	RenderStepped(function(_, p13) -- line: 196
		-- upvalues: p10 (copy), Pivot (copy), p11 (copy), Player (copy), Easing (copy)
		if p10.Parent == nil then
			return true
		end

		local v178 = Pivot + Vector3.new(0.0, math.sin(6.283185307179586 * p13 * 0.5) * 1.0, 0.0)
		local v179 = p11
		local PivotPosition = Pivot.Position
		local v181 = Player.Optional.PrimaryPart(v179)
		local v182 = if not v181 then PivotPosition else v181:GetPivot().Position
		local vector3 = Vector3.new(v182.X, v178.Y, v182.Z)
		local v184 = if not ((v178.Position - vector3).Magnitude < 0.001) then CFrame.lookAt(v178.Position, vector3) else v178
		local v185 = Easing(p13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		p10:PivotTo(v178:Lerp(v184, v185))
	end, 3.0, true):Wait()
end
local function flyAssetIntoPlayer(p14, p15) -- line: 215
	-- upvalues: Transparency (copy), RenderStepped (copy), Player (copy), Bezier (copy), Easing (copy)
	local Scale = p14:GetScale()
	local Pivot = p14:GetPivot()
	local v92 = Transparency()

	task.spawn(function() -- line: 221
		-- upvalues: RenderStepped (copy), p14 (copy), p15 (copy), Pivot (copy), Player (copy), Bezier (copy), Easing (copy), v92 (copy), Scale (copy)
		RenderStepped(function(_, p17) -- line: 222
			-- upvalues: p14 (copy), p15 (copy), Pivot (copy), Player (copy), Bezier (copy), Easing (copy), v92 (copy), Scale (copy)
			if p14.Parent == nil then
				return true
			end

			local v213 = p15
			local PivotPosition = Pivot.Position
			local v215 = Player.Optional.PrimaryPart(v213)
			local v216 = if not v215 then PivotPosition else v215:GetPivot().Position
			local v217 = Bezier
			local PivotPosition2 = Pivot.Position
			local PivotPosition3 = Pivot.Position
			local v220 = (PivotPosition3 + v216) / 2.0
			local Magnitude = ((PivotPosition3 - v216) * Vector3.new(1.0, 0.0, 1.0)).Magnitude
			local v222 = math.max(PivotPosition3.Y, v216.Y) + Magnitude * 0.5
			local v223 = v217(PivotPosition2, Vector3.new(v220.X, v222, v220.Z), v216)
			local v224 = CFrame.new(v223(p17)) * Pivot.Rotation
			local vector3 = Vector3.new(v216.X, v224.Y, v216.Z)
			local v226 = if not ((v224.Position - vector3).Magnitude < 0.001) then CFrame.lookAt(v224.Position, vector3) else v224
			local v227 = math.clamp((p17 - 0.6) / 0.4, 0.0, 1.0)
			local v228 = Easing(v227, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

			v92(p14, 1.0, v228)
			p14:ScaleTo((math.max(0.001, Scale * (1.0 - v228))))
			p14:PivotTo(v226)
		end, 0.7, true):Wait()

		if p14.Parent ~= nil then
			v92(p14, 1.0, 1.0)
			p14:ScaleTo(0.001)
			p14:Destroy()
		end
	end)
	task.wait(0.3)
end
local function playAssetClaimSequence(n6: number, p18) -- line: 253
	-- upvalues: Players (copy), RenderStepped (copy), Player (copy), Easing (copy), flyAssetIntoPlayer (copy)
	local PlayerByUserId = Players:GetPlayerByUserId(n6)

	if PlayerByUserId == nil then
		p18:Destroy()

		return
	end

	local Pivot = p18:GetPivot()

	RenderStepped(function(_, p20) -- line: 196
		-- upvalues: p18 (copy), Pivot (copy), PlayerByUserId (copy), Player (copy), Easing (copy)
		if p18.Parent == nil then
			return true
		end

		local v188 = Pivot + Vector3.new(0.0, math.sin(6.283185307179586 * p20 * 0.5) * 1.0, 0.0)
		local v189 = PlayerByUserId
		local PivotPosition = Pivot.Position
		local v191 = Player.Optional.PrimaryPart(v189)
		local v192 = if not v191 then PivotPosition else v191:GetPivot().Position
		local vector3 = Vector3.new(v192.X, v188.Y, v192.Z)
		local v194 = if not ((v188.Position - vector3).Magnitude < 0.001) then CFrame.lookAt(v188.Position, vector3) else v188
		local v195 = Easing(p20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		p18:PivotTo(v188:Lerp(v194, v195))
	end, 3.0, true):Wait()
	flyAssetIntoPlayer(p18, PlayerByUserId)
end
local function revealAsset(n7: number, s1: string, p21, cFrame: CFrame) -- line: 264
	-- upvalues: ItemDisplay (copy), buildAssetItemData (copy), __DEBRIS (copy), Asserts (copy), BBFromModelVisibleOnly (copy), pivotAssetToEggBottom (copy), growAsset (copy), TweenService (copy)
	local v101 = ItemDisplay.CreateActiveModel(s1, buildAssetItemData(p21, 1.0), true, true)

	v101.Name = `{ n7 }_{ s1 }`
	v101.Parent = __DEBRIS

	local PrimaryPart = v101.PrimaryPart

	Asserts.BasePart(PrimaryPart)
	PrimaryPart.Anchored = true

	local Highlight = Instance.new("Highlight")

	Highlight.FillColor = Color3.new(1.0, 1.0, 1.0)
	Highlight.FillTransparency = 0.0
	Highlight.OutlineTransparency = 1.0
	Highlight.Adornee = v101
	Highlight.Parent = v101
	-- Gekko #6 (Hero Size): the reveal grows to the compressed visual scale, like the pen and the held Tool
	local revealScale = AssetHeroSizePresentation.CompressScale(p21.AssetScale)
	v101:ScaleTo(revealScale * 0.5)

	local v104, v105 = BBFromModelVisibleOnly(v101)
	local v106 = v104.Position.Y - v105.Y * 0.5
	local PositionY = PrimaryPart.CFrame.Position.Y

	PrimaryPart.PivotOffset = CFrame.new(0.0, v106 - PositionY, 0.0)
	pivotAssetToEggBottom(v101, cFrame)
	task.spawn(function() -- line: 285
		-- upvalues: growAsset (copy), v101 (copy), cFrame (copy), revealScale (copy)
		growAsset(v101, cFrame, revealScale)
	end)

	for _, descendant in ipairs(v101:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanQuery = false
		end
	end

	TweenService:Create(Highlight, TweenInfo.new(0.5), {
		FillTransparency = 1.0
	}):Play()

	return v101
end

-- HATCH 2026-09-23 (owner: "Make the egg not pop out loads of bricks when opened"). The hatch no longer clones the
-- EggExplode shard rig (6 brick models that were unanchored, flung across the pen with trails and left lying there
-- for 4 s). After the same shake the egg now does a short scale-pop with a white flash and is gone: only particles
-- and one short-lived anchored, non-colliding flash ball follow (the original EggExplode.Core emitters tinted with
-- the egg colour, the EggPoof smoke, and confetti / sparkles / a ground ring on Roblox's built-in rbxasset
-- particle textures). No part is unanchored or moved by physics. Hatch flow and timings are unchanged: 0.4 s lead-in,
-- 3 shakes, reveal (hero grows out of the egg spot), 3 s look-at, fly into the owner; Play still returns the reveal
-- sound for FadeSoundWhenGrantedToolUnequips, and PlacedEggRenderer calls RequestCompleteHatchEgg after it.
local HATCH_CONFETTI_TEXTURE = "rbxasset://textures/particles/SquareParticle.png"
local HATCH_SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local HATCH_RING_TEXTURE = "rbxasset://textures/particles/explosion01_shockwave_main.dds"
local HATCH_POP_TIME = 0.14 -- egg swells for this long before it vanishes
local HATCH_POP_SCALE = 1.22 -- egg scale multiplier at the end of the pop
local HATCH_FLASH_TIME = 0.35 -- neon flash ball expand + fade
local HATCH_FX_LIFETIME = 4.0 -- particle host part lifetime (Debris)
local HATCH_CONFETTI_PER_COLOR = 12
local HATCH_SPARKLE_COUNT = 22
local HATCH_GOLD = Color3.fromRGB(255, 214, 72)
local HATCH_WHITE = Color3.new(1.0, 1.0, 1.0)

-- Assigns each property on its own pcall so one unsupported property never cancels the effect.
local function hatchSetProps(instance: Instance, props: { [string]: any })
	for key, value in pairs(props) do
		pcall(function()
			(instance :: any)[key] = value
		end)
	end
end

-- Average colour of the egg's visible parts (as before) plus its dominant colours by volume (shell, band, spots:
-- scripts/steps/post_egg_colors.luau paints every hero egg), used to tint the burst.
local function hatchEggColors(model: Model): (Color3, { Color3 })
	local r, g, b, count = 0.0, 0.0, 0.0, 0
	local byKey = {}
	local entries = {}

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Transparency < 1.0 then
			local color = descendant.Color
			local size = descendant.Size
			local key = string.format("%d_%d_%d", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
			local entry = byKey[key]

			r += color.R
			g += color.G
			b += color.B
			count += 1

			if entry == nil then
				entry = { Color = color, Volume = 0.0 }
				byKey[key] = entry
				table.insert(entries, entry)
			end

			entry.Volume += size.X * size.Y * size.Z
		end
	end

	local average = if count > 0 then Color3.new(r / count, g / count, b / count) else color3

	table.sort(entries, function(a, b2)
		return a.Volume > b2.Volume
	end)

	local palette = {}

	for i = 1, math.min(#entries, 3) do
		table.insert(palette, entries[i].Color)
	end

	if #palette == 0 then
		table.insert(palette, average)
	end

	return average, palette
end

-- Short swell with a white fill flash; yields about HATCH_POP_TIME. Never errors (the egg may already be gone).
local function hatchPopEgg(model: Model)
	local okScale, baseScale = pcall(function()
		return model:GetScale()
	end)
	local highlight = Instance.new("Highlight")

	hatchSetProps(highlight, {
		FillColor = HATCH_WHITE,
		FillTransparency = 1.0,
		OutlineTransparency = 1.0,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Adornee = model,
	})
	highlight.Parent = model
	TweenService:Create(highlight, TweenInfo.new(HATCH_POP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 0.05,
	}):Play()

	if okScale and type(baseScale) == "number" and baseScale > 0.001 then
		RenderStepped(function(_, alpha)
			if model.Parent == nil then
				return true
			end

			local eased = Easing(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local ok = pcall(function()
				model:ScaleTo(math.max(0.001, baseScale * (1.0 + (HATCH_POP_SCALE - 1.0) * eased)))
			end)

			if not ok then
				return true
			end
		end, HATCH_POP_TIME, true):Wait()
	else
		task.wait(HATCH_POP_TIME)
	end
end

-- The original particle core of the explosion rig (ColorMe / Gradient / Rare emitters), without its brick shards.
local function hatchCoreBurst(eggScale: number, cFrame: CFrame, color: Color3)
	local coreTemplate = EggExplode:FindFirstChild("Core")

	if coreTemplate == nil or not coreTemplate:IsA("BasePart") then
		return
	end

	local holder = Instance.new("Model")
	local core = coreTemplate:Clone()

	core.Parent = holder
	holder.PrimaryPart = core

	if eggScale > 0.001 then
		pcall(function()
			holder:ScaleTo(eggScale / 3.0)
		end)
	end

	hatchSetProps(core, {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1.0,
	})
	core.CFrame = cFrame
	core.Parent = __DEBRIS
	holder:Destroy()
	Debris:AddItem(core, HATCH_FX_LIFETIME + 2.0)

	local attachment = core:FindFirstChild("Attachment")

	if attachment and attachment:IsA("Attachment") then
		for _, descendant in ipairs(attachment:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") and descendant.Name == "ColorMe" then
				descendant.Color = ColorSequence.new(color)
			end
		end

		EmitDescendants(attachment)
	end

	local rare = core:FindFirstChild("Rare")

	if rare and rare:IsA("Attachment") then
		for _, descendant in ipairs(rare:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant.Color = ColorSequence.new(color)
			end
		end

		EmitDescendants(rare)
	end
end

-- Confetti, sparkles, a ground ring and a neon flash ball at the egg: particles only, nothing physical.
local function hatchSparkleBurst(center: Vector3, height: number, average: Color3, palette: { Color3 })
	local k = math.clamp(height / 3.0, 0.6, 2.5)
	local host = Instance.new("Part")

	host.Name = "EggHatchFx"
	hatchSetProps(host, {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Massless = true,
		Transparency = 1.0,
		Size = Vector3.new(0.2, 0.2, 0.2),
	})
	host.CFrame = CFrame.new(center)

	local burstAttachment = Instance.new("Attachment")

	burstAttachment.Name = "Burst"
	burstAttachment.Parent = host

	local groundAttachment = Instance.new("Attachment")

	groundAttachment.Name = "Ground"
	groundAttachment.Position = Vector3.new(0.0, -height * 0.5 + 0.15, 0.0)
	groundAttachment.Parent = host
	host.Parent = __DEBRIS
	Debris:AddItem(host, HATCH_FX_LIFETIME)

	local function emitter(parent: Instance, name: string, props: { [string]: any }, count: number)
		local particles = Instance.new("ParticleEmitter")

		particles.Name = name
		particles.Enabled = false
		particles.Rate = 0.0
		hatchSetProps(particles, props)
		particles.Parent = parent
		particles:Emit(count)
	end

	local confettiColors = table.clone(palette)

	table.insert(confettiColors, HATCH_GOLD)

	for index, color in ipairs(confettiColors) do
		emitter(burstAttachment, "Confetti" .. index, {
			Texture = HATCH_CONFETTI_TEXTURE,
			Color = ColorSequence.new(color),
			LightEmission = 0.15,
			LightInfluence = 0.3,
			Size = NumberSequence.new(0.28 * k),
			Squash = NumberSequence.new(0.55),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0.0, 0.0),
				NumberSequenceKeypoint.new(0.75, 0.0),
				NumberSequenceKeypoint.new(1.0, 1.0),
			}),
			Lifetime = NumberRange.new(1.3, 2.0),
			Speed = NumberRange.new(9.0 * k, 15.0 * k),
			SpreadAngle = Vector2.new(40.0, 40.0),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0.0, -22.0, 0.0),
			Drag = 1.6,
			Rotation = NumberRange.new(0.0, 360.0),
			RotSpeed = NumberRange.new(-320.0, 320.0),
		}, HATCH_CONFETTI_PER_COLOR)
	end

	emitter(burstAttachment, "Sparkles", {
		Texture = HATCH_SPARKLE_TEXTURE,
		Color = ColorSequence.new(HATCH_WHITE, average:Lerp(HATCH_WHITE, 0.35)),
		LightEmission = 1.0,
		LightInfluence = 0.0,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 0.9 * k),
			NumberSequenceKeypoint.new(1.0, 0.0),
		}),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(6.0 * k, 12.0 * k),
		SpreadAngle = Vector2.new(180.0, 180.0),
		Drag = 3.0,
		Rotation = NumberRange.new(0.0, 360.0),
		ZOffset = 0.5,
	}, HATCH_SPARKLE_COUNT)

	emitter(groundAttachment, "Ring", {
		Texture = HATCH_RING_TEXTURE,
		Color = ColorSequence.new(average:Lerp(HATCH_WHITE, 0.5)),
		LightEmission = 0.7,
		LightInfluence = 0.0,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top,
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 0.6 * k),
			NumberSequenceKeypoint.new(1.0, 6.5 * k),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 0.1),
			NumberSequenceKeypoint.new(1.0, 1.0),
		}),
		Lifetime = NumberRange.new(0.45, 0.45),
		Speed = NumberRange.new(0.01, 0.01),
		SpreadAngle = Vector2.new(0.0, 0.0),
	}, 1)

	local flash = Instance.new("Part")

	flash.Name = "EggHatchFlash"
	hatchSetProps(flash, {
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = average:Lerp(HATCH_WHITE, 0.65),
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Massless = true,
		Transparency = 0.2,
		Size = Vector3.one * math.max(0.5, height * 0.9),
	})
	flash.CFrame = CFrame.new(center)

	local light = Instance.new("PointLight")

	hatchSetProps(light, {
		Color = average:Lerp(HATCH_WHITE, 0.5),
		Brightness = 3.0,
		Range = 14.0 * k,
		Shadows = false,
	})
	light.Parent = flash
	flash.Parent = __DEBRIS
	Debris:AddItem(flash, HATCH_FLASH_TIME + 0.5)

	local flashInfo = TweenInfo.new(HATCH_FLASH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(flash, flashInfo, {
		Size = Vector3.one * math.max(1.0, height * 2.1),
		Transparency = 1.0,
	}):Play()
	TweenService:Create(light, flashInfo, {
		Brightness = 0.0,
	}):Play()
end

function t1.Play(n8: number, s2: string, p22, p23) -- line: 307
	Asserts.number(n8)
	Asserts.string(s2)
	assert(Eggs.SchemaValidation.SavedEgg(p22), "Invalid saved egg record")
	Asserts.Model(p23)
	EggRenderer.DisableCollisions(p23)
	task.wait(0.4)

	local Pivot = p23:GetPivot()
	local v117, v118 = BBFromModelVisibleOnly(p23)
	local v119 = v117.Position - Vector3.new(0.0, 1.0, 0.0) * (v118.Y * 0.5) + Vector3.new(0.0, 0.20000000298023224, 0.0)
	local v120 = getBottomCFrameFacingPlayer(n8, v119, Pivot - Pivot.Position)

	shakeEgg(p23, Pivot)

	local okScale, eggScale = pcall(function()
		return p23:GetScale()
	end)

	eggScale = if okScale and type(eggScale) == "number" then eggScale else 3.0

	local v129, palette = hatchEggColors(p23)

	pcall(hatchPopEgg, p23)
	p23:Destroy()

	local v134 = revealAsset(n8, s2, p22, v120)
	local RandomIdleSound = Assets.Directory[p22.AssetCategory].RandomIdleSound
	local v136 = if RandomIdleSound ~= nil then Audio.PlayFromSoundFile(RandomIdleSound, v120) else nil

	Audio.Play("rbxassetid://102267539121951", script, nil, 1.0)

	local okCore, coreErr = pcall(hatchCoreBurst, eggScale, CFrame.new(v117.Position) * (Pivot - Pivot.Position), v129)

	if not okCore then
		warn("[EggHatchAnimation] core burst failed: " .. tostring(coreErr))
	end

	local okBurst, burstErr = pcall(hatchSparkleBurst, v117.Position, v118.Y, v129, palette)

	if not okBurst then
		warn("[EggHatchAnimation] sparkle burst failed: " .. tostring(burstErr))
	end

	pcall(function()
		local clone3 = EggPoof:Clone()

		clone3.CFrame = Pivot
		clone3.Parent = __DEBRIS
		EmitDescendants(clone3)
		Debris:AddItem(clone3, 6.0)
	end)

	local PlayerByUserId = Players:GetPlayerByUserId(n8)

	if PlayerByUserId == nil then
		v134:Destroy()

		return v136
	end

	local Pivot2 = v134:GetPivot()

	RenderStepped(function(_, p25) -- line: 196
		-- upvalues: v134 (copy), Pivot2 (copy), PlayerByUserId (copy), Player (copy), Easing (copy)
		if v134.Parent == nil then
			return true
		end

		local v202 = Pivot2 + Vector3.new(0.0, math.sin(6.283185307179586 * p25 * 0.5) * 1.0, 0.0)
		local v203 = PlayerByUserId
		local Pivot2Position = Pivot2.Position
		local v205 = Player.Optional.PrimaryPart(v203)
		local v206 = if not v205 then Pivot2Position else v205:GetPivot().Position
		local vector3 = Vector3.new(v206.X, v202.Y, v206.Z)
		local v208 = if not ((v202.Position - vector3).Magnitude < 0.001) then CFrame.lookAt(v202.Position, vector3) else v202
		local v209 = Easing(p25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		v134:PivotTo(v202:Lerp(v208, v209))
	end, 3.0, true):Wait()
	flyAssetIntoPlayer(v134, PlayerByUserId)

	return v136
end
function t1.FadeSoundWhenGrantedToolUnequips(p26, s3: string) -- line: 468
	-- upvalues: Asserts (copy), Players (copy), Audio (copy)
	Asserts.Sound(p26)
	Asserts.string(s3)

	if not p26:IsDescendantOf(game) then
		return
	end

	local LocalPlayer = Players.LocalPlayer
	local u163 = nil
	local u164 = nil
	local u165 = nil
	local u166 = nil
	local u167 = false

	local function disconnectLifecycle() -- line: 482
		-- upvalues: u163 (ref), u164 (ref), u165 (ref), u166 (ref)
		if u163 ~= nil then
			u163:Disconnect()
			u163 = nil
		end

		if u164 ~= nil then
			u164:Disconnect()
			u164 = nil
		end

		if u165 ~= nil then
			u165:Disconnect()
			u165 = nil
		end

		if u166 ~= nil then
			u166:Disconnect()
			u166 = nil
		end
	end
	local function fadeAndStop() -- line: 501
		-- upvalues: disconnectLifecycle (copy), p26 (copy), Audio (copy)
		disconnectLifecycle()

		if not p26:IsDescendantOf(game) then
			return
		end

		Audio.Fade(p26, 0.0, 0.35).Completed:Once(function() -- line: 508
			-- upvalues: p26 (copy)
			if p26:IsDescendantOf(game) then
				p26:Stop()
			end
		end)
	end
	local function tryBindTool(p27) -- line: 515
		-- upvalues: u167 (ref), s3 (copy), u163 (ref), u166 (ref), fadeAndStop (copy)
		if u167 or (not p27:IsA("Tool") or p27:GetAttribute("UID") ~= s3) then
			return
		end

		u167 = true

		if u163 ~= nil then
			u163:Disconnect()
			u163 = nil
		end

		u166 = p27.Unequipped:Once(fadeAndStop)
	end

	u164 = p26.Ended:Once(disconnectLifecycle)
	u165 = p26.Stopped:Once(disconnectLifecycle)
	u163 = LocalPlayer.DescendantAdded:Connect(tryBindTool)

	for _, descendant in LocalPlayer:GetDescendants() do
		tryBindTool(descendant)

		if u167 then
			break
		end
	end
end

return t1

