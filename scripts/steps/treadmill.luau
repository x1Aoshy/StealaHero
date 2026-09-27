-- scripts/steps/treadmill.luau
-- Build step (TREADMILL owner, CONTRACTS_PHASE3 D5 + D6; GEKKO 2026-09-24: the new treadmill models).
--
-- D5. All 10 treadmill skin Tools in ReplicatedStorage.Assets.Models.Treadmills wear one of the owner's new treadmill
-- models (assets/treadmills/Treadmills.rbxl, a copy of the repo-root Treadmills.rbxl; Workspace.<Name>Treadmill),
-- table-driven by Step.TIERS, picked by name and look (owner 2026-09-24: "dependiendo de como se vean o su nombre"):
--   1 Basic, 2 Space (Sci-Fi), 3 Fire (Flame), 4 Candy tinted pink (Celebrity), 5 Jungle in solid gold (Golden),
--   6 Ice (The Freeze), 7 Lucky (Lucky Block), 8 Hacker, 9 Toxic tinted blood red (Demonic),
--   10 Rainbow in white porcelain with gold sparkles (Angelic: its rainbow arch becomes a halo).
--   Not used: TechTreadmill (same frame as Hacker) and AquaticTreadmill.
-- Each model is cloned ONCE as a whole subtree (Lune gotcha: per-child clones break internal refs); scripts (the free
-- model's showcase bob loop), sounds, joints, GUIs and value objects are stripped from the clone. Its MeshParts keep
-- their MeshContent and SurfaceAppearance maps (asset ids from the file), except where the tier's finish replaces the
-- look (a SurfaceAppearance.Color tint, or a solid colour / material without the texture). The belt's own Beam (a
-- scrolling texture: the moving belt) stays; its duplicated ParticleEmitters are merged per look and held to
-- Step.EMITTER_RATE_BUDGET particles/s (the free models ship up to 1,425/s), burst-only ones (Rate 0) dropped.
-- Every clone part is Anchored, CanCollide/CanTouch false, CanQuery false and flagged Step.DECOR_ATTRIBUTE (both
-- renderers keep CanQuery off on flagged parts). The clone lives in the skin as <skin>.Model.<ModelName>; its belt
-- MeshPart carries Step.BELT_ATTRIBUTE.
--
-- D6. Every plot also gets a static, visual-only copy of the tier-1 look named SpeedsterTreadmillDisplay (the name the
-- runtime looks up), so the treadmill is visible in the .rbxl (Studio edit mode). It is baked in the LOCKED look
-- (every visible part at 0.35 transparency + a Speedsters "UNLOCK $8" lock billboard) without effects (no belt
-- Beam, no emitters: a quiet preview). At runtime ServerScriptService.Controllers.TreadmillSpawnService hides it
-- (Transparency 1, billboard off) whenever it renders the plot's bought treadmill, and the owner's
-- TreadmillStaticController hides it locally while it shows its own render: exactly one treadmill visible per plot and
-- viewer. Every display part is Anchored, CanCollide/CanQuery/CanTouch=false (it must never intercept the client
-- raycast onto TreadmillBottom) and CastShadow=false.
--
-- Runs right after scripts/steps/plots.luau (after translatePart), so it reads final TreadmillBottom CFrames.
-- TreadmillBottom and TreadmillUpgrade are only read: TreadmillBottom stays the server detection volume
-- (TreadmillGrindService) and the client raycast target (TreadmillStaticController).
--
-- How a skin is seated. Both renderers ground a Tool with TreadmillUtil.ResolveGroundedToolRootCFrameAtLocation:
-- BoundingBoxPart centred over TreadmillBottom, its bottom `Offset` (Tool attribute) above the plate, rotation =
-- TreadmillBottom's. Tools with FloorAligned = true are then lifted by (Plots.<id>.TreadmillFloorY - TreadmillBottom.Y),
-- because the plates sit up to 0.26 studs above or below the walkable floor. This step writes TreadmillFloorY on every
-- plot and lays each skin out in that floor frame F' (TreadmillBottom X/Z and yaw, Y = floor): the model scaled so its
-- belt is as long as the plate (belt along the plate's long axis, about the size of the earlier belts), the belt top at
-- floor + GROUND_EPSILON (the runner stands on the floor; the frame's base under the belt sinks into the ground), the
-- belt centred on the plate (Root, the position-lock anchor, over the plate centre), the console on the
-- TreadmillBottom.LookVector side, and the BoundingBoxPart + Offset chosen so the game's own grounding reproduces that
-- layout on every plot (verified per tier and per plot below; a mismatch errors).
--
-- The skin's functional parts are kept with their names and sizes, because client code looks them up (Root,
-- BoundingBoxPart, the invisible hitbox Part and the SpeedPerSecond rate sign, whose BillboardGui is moved, never
-- scaled). VISUAL_PASS_PLAN D4 removed the TikTok-style video player: no skin carries a VideoFeedScreen / its frame slab /
-- swap buttons any more. In its place every skin gets ONE clean screen part, Step.PHONE_SCREEN_NAME ("PhoneScreen"):
-- the old video screen's size (3.69 x 6.56 x 0.73), centre SCREEN_CENTER_HEIGHT above the floor, mounted on the new
-- model's console: its back face just in front of the console's nearest point inside the screen's outline (read from
-- the meshes' collision hulls, scripts/lib/treadmill_models.luau), Front face toward the runner, a dark bezel slab,
-- anchored, non-colliding, CanQuery on (the SpeedPhone raycasts taps onto it). The Hero Flap phone
-- (StarterPlayerScripts.GUI.SpeedPhone) renders on it through a PlayerGui SurfaceGui for the local runner;
-- scripts/steps/ui_60_treadmill.luau adds its idle "HERO FLAP" attract SurfaceGui. verifySkin errors when any part of
-- the skin (a block's box, a mesh's hull point) stands in or up to SCREEN_SIGHT_DEPTH studs in front of the screen.
-- The rate sign floats RATE_SIGN_GAP above the screen.
--
-- Lune 0.10.5 has no PivotTo/GetPivot/ScaleTo, so everything is per-part CFrame math:
--   S = belt-top-centre frame of the source model (LookVector toward its console)
--   part.CFrame = toTemplate * CFrame.new(0, GROUND_EPSILON, 0) * CFrame.new(rel.Position * s) * rel.Rotation
--   rel = S:ToObjectSpace(source part), s = TreadmillBottom long side / belt length,
--   toTemplate = Root.CFrame * CFrame.new(0, -ROOT_HEIGHT, 0) (floor frame F' -> template space).
-- Model.WorldPivot writes are not serialized by Lune; WorldPivotData is. Yaws are built with CFrame.fromMatrix /
-- CFrame.Angles (CFrame.lookAt is mirrored in Lune 0.10.5).

local roblox = require("@lune/roblox")
local Models = require("../lib/treadmill_models")
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Instance = roblox.Instance
local UDim2 = roblox.UDim2
local Enum = roblox.Enum
local NumberSequence, NumberSequenceKeypoint, NumberRange = roblox.NumberSequence, roblox.NumberSequenceKeypoint, roblox.NumberRange
local ColorSequence, ColorSequenceKeypoint = roblox.ColorSequence, roblox.ColorSequenceKeypoint

local Step = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- The owner's treadmill models: the first file found (repo root copy as the fallback).
Step.MODEL_FILES = { "assets/treadmills/Treadmills.rbxl", "Treadmills.rbxl" }
Step.SOURCE_ASSET_PREFIX = "Treadmills.rbxl.Workspace."
Step.SKINS_PATH = { "Assets", "Models", "Treadmills" } -- under ReplicatedStorage
Step.DECOR_FOLDER_NAME = "Model" -- the skin's decor Folder (base place); holds the model clone
Step.MODEL_ATTRIBUTE = "TreadmillModel" -- on the skin Tool and on its model clone: the source model's name
Step.FINISH_ATTRIBUTE = "TreadmillFinish" -- on the skin Tool: "original" | "tint" | "solid"
Step.BELT_ATTRIBUTE = "TreadmillBelt" -- on the belt MeshPart of every clone
Step.DECOR_ATTRIBUTE = "TreadmillDecor" -- on every visual-only part of the clone: renderers keep CanQuery off

-- D5 tier table (owner-tunable). model = Workspace child of Treadmills.rbxl. finish (optional) re-dresses the frame
-- MeshParts (never the belt): { tint = Color3 } multiplies the textures (SurfaceAppearance.Color, Part.Color for the
-- maps' transparent areas); { color, material, reflectance } drops the textures for a solid finish. emitterColor
-- (optional) recolours the particle emitters, near-white sparkles excepted.
Step.TIERS = {
	{ level = 1, skin = "Treadmill", model = "BasicTreadmill" },
	{ level = 2, skin = "Sci-FiTreadmill", model = "SpaceTreadmill" },
	{ level = 3, skin = "FlameTreadmill", model = "FireTreadmill" },
	{
		level = 4,
		skin = "CelebrityTreadmill",
		model = "CandyTreadmill",
		finish = { tint = rgb(255, 128, 214) }, -- pop-star pink
		emitterColor = rgb(255, 92, 196),
	},
	{
		level = 5,
		skin = "GoldenTreadmill",
		model = "JungleTreadmill",
		finish = { color = rgb(255, 190, 38), material = Enum.Material.Metal, reflectance = 0.1 }, -- solid gold
		emitterColor = rgb(255, 215, 94),
	},
	{ level = 6, skin = "The FreezeTreadmill", model = "IceTreadmill" },
	{ level = 7, skin = "Lucky BlockTreadmill", model = "LuckyTreadmill" },
	{ level = 8, skin = "HackerTreadmill", model = "HackerTreadmill" },
	{
		level = 9,
		skin = "DemonicTreadmill",
		model = "ToxicTreadmill",
		finish = { tint = rgb(165, 26, 26) }, -- blood red / black
		emitterColor = rgb(255, 36, 24),
	},
	{
		level = 10,
		skin = "AngelicTreadmill",
		model = "RainbowTreadmill",
		finish = { color = rgb(250, 247, 238), material = Enum.Material.SmoothPlastic, reflectance = 0.12 }, -- porcelain
		emitterColor = rgb(255, 222, 120), -- gold (white sparkles stay white)
	},
}
Step.UNUSED_MODELS = { "TechTreadmill", "AquaticTreadmill" } -- reported in the build log

Step.LEGACY_MODEL_NAME = "SpeedsterTreadmillModel" -- the always-visible plot model of phase-2 builds (removed)
Step.DISPLAY_NAME = "SpeedsterTreadmillDisplay" -- D6 static display, one per plot (runtime lookup name)
Step.DISPLAY_TAG = "SpeedsterTreadmillDisplay"
Step.DISPLAY_STATE_ATTRIBUTE = "DisplayState" -- "Locked" | "Unlocked" | "Hidden" (runtime: TreadmillSpawnService)
Step.DISPLAY_LOCKED_TRANSPARENCY = 0.35 -- visible parts' transparency while locked
Step.DISPLAY_BILLBOARD_NAME = "LockBillboard"
Step.DISPLAY_ANCHOR_NAME = "LockAnchor"
Step.DISPLAY_ANCHOR_HEIGHT = 6 -- lock billboard centre above the walkable floor
Step.UNLOCK_PRICE_TEXT = "$8" -- PlotService BASE_TIERS[1].Cost (first base upgrade unlocks the treadmill); ECON 2026-09-24: was "$1,000" (money /125)
Step.FLOOR_ATTRIBUTE = "TreadmillFloorY" -- on each plot Model: walkable floor top under TreadmillBottom
Step.FLOOR_ALIGNED_ATTRIBUTE = "FloorAligned" -- on the skin Tool: renderers apply the floor correction
Step.MAX_FLOOR_CORRECTION = 2 -- renderers ignore larger corrections (same constant at runtime)
Step.GROUND_EPSILON = 0.05 -- belt top sits this far above the walkable floor (no z-fighting)
Step.ROOT_HEIGHT = 3.9 -- Root above the floor (the original skin's Root sat 3.9 above TreadmillBottom)
-- D4: the video set every skin loses (looked up recursively; the runtime video player is gone).
Step.VIDEO_PART_NAMES = { "VideoFeedScreen", "VideoDecorationPart", "SwapLeft", "SwapRight" }
-- The Hero Flap phone screen that replaces the video screen (runtime: GUI.SpeedPhone, 100 px/stud).
Step.PHONE_SCREEN_NAME = "PhoneScreen"
Step.PHONE_SCREEN_ATTRIBUTE = "SpeedPhoneScreen"
Step.PHONE_SCREEN_COLOR = rgb(7, 10, 22) -- dark bezel
Step.PHONE_SCREEN_SIZE = Vector3.new(3.6876724, 6.556, 0.726) -- the base skins' VideoFeedScreen (read when present)
Step.SCREEN_CENTER_HEIGHT = 5.1 -- phone screen centre above the floor (the old video screen's eye height)
Step.SCREEN_SIDE_MARGIN = 0.15 -- console search window: the screen's outline widened by this (studs, each side)
Step.SCREEN_HEIGHT_MARGIN = 0.1 -- and heightened by this
Step.RUNNER_CLEARANCE = 1 -- console search ignores points closer than this ahead of the runner (the runner's spot)
Step.CONSOLE_CLEARANCE = 0.05 -- gap between the screen's back face and the console's nearest point
Step.SCREEN_MIN_AHEAD = 2.5 -- the screen centre stands at least this far ahead of the runner (else: layout error)
Step.SCREEN_MAX_AHEAD = 6.5 -- and at most this far (a console farther away than that is not waited for)
-- Studs in front of the PhoneScreen face (toward the runner, whose Root is ~4 away) that no visible skin part may
-- enter: the phone on the screen must never be hidden by the skin itself (verifySkin).
Step.SCREEN_SIGHT_DEPTH = 3
Step.RATE_SIGN_GAP = 0.8 -- SpeedPerSecond centre above the screen's top edge
-- Plot parts (upgrade signs, fences) may not be touched by a model above the floor: each tier is shrunk from the
-- plate-length scale in FIT_STEP steps (not below MIN_FIT of it) until its hull points clear every plot part grown by
-- FURNITURE_MARGIN, or by UPGRADE_SIGN_MARGIN for an upgrade sign's Sign / Support: scripts/steps/post_hub_remodel.luau
-- (a later step) frames each Sign with 0.44-stud bars and sets its Support on a plinth 0.45 studs wider.
Step.FURNITURE_MARGIN = 0.1
Step.UPGRADE_SIGN_MARGIN = 0.45
Step.UPGRADE_SIGN_MODELS = { PlotUpgrade = true, TreadmillUpgrade = true }
Step.MIN_FIT = 0.85
Step.FIT_STEP = 0.01
-- Particle budget per skin (sum of emitter Rates, particles/s) and per merged emitter.
Step.EMITTER_RATE_BUDGET = 150
Step.EMITTER_MAX_RATE = 40
Step.EMITTER_MIN_RATE = 0.5

-- Speedsters UI materials for the lock billboard (uiport/materials.md): the authored exemplars are cloned
-- from the Speedsters place when present, with these values as the fallback.
Step.LOCK_ICON = "rbxassetid://121834855888887" -- Treadmill lock icon
Step.ACTION_PILL = "rbxassetid://135496826236732" -- main action pill (cyan "treadmill lock" family)
Step.PRICE_PILL = "rbxassetid://118171558421884" -- price pill (green family)
Step.EXEMPLAR_UNLOCK = { "Treadmill", "TimeGift", "Reddem" } -- StarterGui: the Treadmill-lock window's cyan button
Step.EXEMPLAR_PRICE = { "Backpack", "MainFrame", "Trail#ScrollingFrame", "Frame", "Frame", "WinsPurchase" } -- green price pill
local INK = rgb(11, 27, 61) -- #0b1b3d authored ink

local LOG_PREFIX = "[StealaHero Build][treadmill]"

-- Stripped from the model clones only (never from the skin's own SpeedPerSecond billboard).
local STRIP_CLASSES = {
	"LuaSourceContainer", "Sound", "JointInstance", "WeldConstraint", "NoCollisionConstraint", "Constraint",
	"Highlight", "ValueBase", "SurfaceGui", "BillboardGui", "ClickDetector", "ProximityPrompt", "Dialog", "Tool",
}
-- Never allowed anywhere in a converted skin.
local FORBIDDEN_IN_SKIN = { "LuaSourceContainer", "Sound", "Highlight", "JointInstance", "WeldConstraint", "NoCollisionConstraint" }
local JOINT_CLASSES = { "JointInstance", "WeldConstraint", "NoCollisionConstraint", "Constraint" }
local EFFECT_CLASSES = { "ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles", "Light" }

local function findPath(root, path)
	local current = root
	for _, segment in ipairs(path) do
		if current == nil then
			return nil
		end
		-- "Name#ClassName" disambiguates same-named siblings (materials.json notation)
		local name, className = string.match(segment, "^(.-)#(.+)$")
		if name then
			local found = nil
			for _, child in ipairs(current:GetChildren()) do
				if child.Name == name and child.ClassName == className then
					found = child
					break
				end
			end
			current = found
		else
			current = current:FindFirstChild(segment)
		end
	end
	return current
end

local function findDescendant(root, name)
	for _, d in ipairs(root:GetDescendants()) do
		if d.Name == name then
			return d
		end
	end
	return nil
end

local function countDescendants(root, name)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d.Name == name then
			n += 1
		end
	end
	return n
end

local function isA(inst, classNames)
	for _, className in ipairs(classNames) do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

local function contentUri(inst, prop)
	local ok, content = pcall(function()
		return (inst :: any)[prop]
	end)
	if ok and content ~= nil then
		local okUri, uri = pcall(function()
			return content.Uri
		end)
		if okUri and type(uri) == "string" then
			return uri
		end
	end
	return ""
end

-- D4: destroys a skin's video set (every descendant named in Step.VIDEO_PART_NAMES, with its SurfaceGuis), then
-- any Folder/Model that held it and is left without a BasePart. Never touches the Tool itself. Returns the count.
function Step.RemoveVideoSet(tool)
	local names = {}
	for _, name in ipairs(Step.VIDEO_PART_NAMES) do
		names[name] = true
	end
	local holders, removed = {}, 0
	for _, d in ipairs(tool:GetDescendants()) do
		if d.Parent ~= nil and names[d.Name] then
			local holder = d.Parent
			if holder ~= tool and (holder:IsA("Folder") or holder:IsA("Model")) then
				holders[holder] = true
			end
			d:Destroy()
			removed += 1
		end
	end
	for holder in pairs(holders) do
		if holder.Parent ~= nil and holder:FindFirstChildWhichIsA("BasePart", true) == nil then
			holder:Destroy()
		end
	end
	return removed
end

-- The Hero Flap phone screen (one per skin, a direct child of the Tool): a dark bezel slab on the console.
-- Anchored, non-colliding, no touch, no shadow; CanQuery stays on (the SpeedPhone raycasts taps / clicks onto it).
-- Replaces an earlier one.
function Step.AddPhoneScreen(tool, cframe, size)
	for _, child in ipairs(tool:GetChildren()) do
		if child.Name == Step.PHONE_SCREEN_NAME then
			child:Destroy()
		end
	end
	local part = Instance.new("Part")
	part.Name = Step.PHONE_SCREEN_NAME
	part.Size = size
	part.CFrame = cframe
	part.Color = Step.PHONE_SCREEN_COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.CastShadow = false
	part:SetAttribute(Step.PHONE_SCREEN_ATTRIBUTE, true)
	part.Parent = tool
	return part
end

local function forEachCorner(cf, size, fn)
	local h = size / 2
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				fn(cf * Vector3.new(sx * h.X, sy * h.Y, sz * h.Z))
			end
		end
	end
end

-- Oriented-box overlap (separating axis test): true when the boxes are closer than `margin` on every axis.
function Step.BoxesOverlap(cf1, size1, cf2, size2, margin)
	margin = margin or 0
	local axes1 = { cf1.RightVector, cf1.UpVector, cf1.LookVector }
	local axes2 = { cf2.RightVector, cf2.UpVector, cf2.LookVector }
	local axes = { axes1[1], axes1[2], axes1[3], axes2[1], axes2[2], axes2[3] }
	for _, a in ipairs(axes1) do
		for _, b in ipairs(axes2) do
			local c = a:Cross(b)
			if c.Magnitude > 1e-4 then
				table.insert(axes, c.Unit)
			end
		end
	end
	local h1, h2 = size1 / 2, size2 / 2
	for _, axis in ipairs(axes) do
		local r1 = math.abs(axes1[1]:Dot(axis)) * h1.X + math.abs(axes1[2]:Dot(axis)) * h1.Y + math.abs(axes1[3]:Dot(axis)) * h1.Z
		local r2 = math.abs(axes2[1]:Dot(axis)) * h2.X + math.abs(axes2[2]:Dot(axis)) * h2.Y + math.abs(axes2[3]:Dot(axis)) * h2.Z
		local distance = math.abs((cf2.Position - cf1.Position):Dot(axis))
		if distance >= r1 + r2 + margin then
			return false
		end
	end
	return true
end

local function colorKey(c)
	return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

-- Walkable floor top used for every plot: the Baseplate (ctx.groundY). scripts/steps/ground.luau keeps the
-- Baseplate as the one solid floor under the plots, so this stays true after the ground restyle.
local function resolveGroundY(place, ctx)
	if type(ctx.groundY) == "number" then
		return ctx.groundY
	end
	local baseplate = ctx.baseplate or place.Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		return baseplate.CFrame.Position.Y + baseplate.Size.Y / 2
	end
	return nil
end

-- The grounding both renderers perform (TreadmillUtil.ResolveGroundedToolRootCFrameAtLocation + the
-- FloorAligned correction of TreadmillSpawnService / TreadmillStaticController.Render), for verification.
function Step.GroundedRootCFrame(tool, tb, floorY)
	local root, bbp = tool.Root, tool.BoundingBoxPart
	local bbpInRoot = root.CFrame:PointToObjectSpace(bbp.CFrame.Position)
	local offset = tool:GetAttribute("Offset") or 0
	local tbPos = tb.CFrame.Position
	local target = CFrame.new(tbPos + Vector3.new(0, bbp.Size.Y * 0.5 + offset, 0)) * tb.CFrame.Rotation * CFrame.new(-bbpInRoot)
	if tool:GetAttribute(Step.FLOOR_ALIGNED_ATTRIBUTE) == true and type(floorY) == "number" then
		local correction = floorY - tbPos.Y
		if math.abs(correction) <= Step.MAX_FLOOR_CORRECTION then
			target = target + Vector3.new(0, correction, 0)
		end
	end
	return target
end

-- The functional parts every skin must have; returns the phone screen size (the video screen's, when still there).
local function validateSkin(tool, skinName)
	if not tool then
		return nil, "skin " .. skinName .. " not found"
	end
	if not tool:IsA("Tool") then
		return nil, "skin " .. skinName .. " is a " .. tool.ClassName .. ", expected a Tool"
	end
	for _, name in ipairs({ "Root", "BoundingBoxPart", "SpeedPerSecond" }) do
		local part = tool:FindFirstChild(name)
		if not (part and part:IsA("BasePart")) then
			return nil, "skin " .. skinName .. " has no BasePart " .. name
		end
	end
	local screen = findDescendant(tool, "VideoFeedScreen")
	if screen and screen:IsA("BasePart") then
		return screen.Size
	end
	return Step.PHONE_SCREEN_SIZE
end

-- Scales the non-part effects of a clone by s (attachments are offsets inside their part, emitter / beam / light
-- sizes are in studs, FileMesh SpecialMeshes ignore Part.Size).
local function scaleEffect(inst, s)
	if inst:IsA("Attachment") then
		local cf = inst.CFrame
		inst.CFrame = CFrame.new(cf.Position * s) * cf.Rotation
	elseif inst:IsA("ParticleEmitter") then
		local kps = {}
		for _, k in ipairs(inst.Size.Keypoints) do
			table.insert(kps, NumberSequenceKeypoint.new(k.Time, k.Value * s, k.Envelope * s))
		end
		inst.Size = NumberSequence.new(kps)
		inst.Speed = NumberRange.new(inst.Speed.Min * s, inst.Speed.Max * s)
		inst.Acceleration = inst.Acceleration * s
	elseif inst:IsA("Beam") then
		inst.Width0 = inst.Width0 * s
		inst.Width1 = inst.Width1 * s
		inst.TextureLength = inst.TextureLength * s
		inst.CurveSize0 = inst.CurveSize0 * s
		inst.CurveSize1 = inst.CurveSize1 * s
	elseif inst:IsA("Light") then
		pcall(function()
			inst.Range = inst.Range * s
		end)
	elseif inst:IsA("SpecialMesh") then
		if inst.MeshType == Enum.MeshType.FileMesh then
			inst.Scale = inst.Scale * s
		end
		inst.Offset = inst.Offset * s
	elseif inst:IsA("Texture") then
		inst.StudsPerTileU = inst.StudsPerTileU * s
		inst.StudsPerTileV = inst.StudsPerTileV * s
	end
end

-- Re-dresses the frame MeshParts (never the belt) with the tier's finish. Returns the finish kind.
local function applyFinish(frames, finish)
	if finish == nil then
		return "original"
	end
	for _, part in ipairs(frames) do
		if finish.tint then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("SurfaceAppearance") then
					child.Color = finish.tint
				end
			end
			part.Color = finish.tint -- what the maps' transparent areas (AlphaMode Overlay) show
		else
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
			part.Color = finish.color
			part.Material = finish.material or Enum.Material.SmoothPlastic
			part.Reflectance = finish.reflectance or 0
		end
	end
	return if finish.tint then "tint" else "solid"
end

-- Recolours every particle emitter but the near-white sparkles.
local function recolorEmitters(root, color)
	local n = 0
	for _, e in ipairs(root:GetDescendants()) do
		if e:IsA("ParticleEmitter") then
			local c = e.Color.Keypoints[1].Value
			if math.min(c.R, c.G, c.B) < 0.9 then
				e.Color = ColorSequence.new(color)
				n += 1
			end
		end
	end
	return n
end

-- The free models stack identical emitters to thicken an effect (up to 12 copies, 1,425 particles/s in all): merge
-- each look (host, name, texture, colour, size, lifetime) into one emitter carrying the summed rate, drop burst-only
-- emitters (Rate 0: nothing calls Emit on a skin), then hold the skin to EMITTER_RATE_BUDGET. Returns emitters kept,
-- the rate before and after.
local function consolidateEmitters(root)
	local groups, order, before = {}, {}, 0
	for _, e in ipairs(root:GetDescendants()) do
		if e:IsA("ParticleEmitter") and e.Parent ~= nil then
			if e.Rate <= 0 or not e.Enabled then
				e:Destroy()
			else
				before += e.Rate
				local key = table.concat({
					e.Parent.Name, e.Name, contentUri(e, "TextureContent"), colorKey(e.Color.Keypoints[1].Value),
					string.format("%.2f|%.2f", e.Size.Keypoints[1].Value, e.Lifetime.Max),
				}, "|")
				local group = groups[key]
				if group then
					group.rate += e.Rate
					e:Destroy()
				else
					groups[key] = { emitter = e, rate = e.Rate }
					table.insert(order, key)
				end
			end
		end
	end
	local total = 0
	for _, key in ipairs(order) do
		total += math.min(groups[key].rate, Step.EMITTER_MAX_RATE)
	end
	local factor = if total > Step.EMITTER_RATE_BUDGET then Step.EMITTER_RATE_BUDGET / total else 1
	local after = 0
	for _, key in ipairs(order) do
		local group = groups[key]
		local rate = math.max(Step.EMITTER_MIN_RATE, math.floor(math.min(group.rate, Step.EMITTER_MAX_RATE) * factor * 10) / 10)
		group.emitter.Rate = rate
		after += rate
	end
	return #order, before, after
end

-- Outline points ({ x, y, z } in the floor frame F': x lateral, y above the floor, -z ahead of the runner) of parts.
local function floorPoints(parts, toTemplate)
	local points, exact = {}, true
	for _, part in ipairs(parts) do
		local world, isExact = Models.PartPoints(roblox, part)
		exact = exact and isExact
		for _, w in ipairs(world) do
			local p = toTemplate:PointToObjectSpace(w)
			table.insert(points, { p.X, p.Y, p.Z })
		end
	end
	return points, exact
end

-- Where the phone screen goes on this console: centre SCREEN_CENTER_HEIGHT above the floor on the belt's centre line,
-- its back face CONSOLE_CLEARANCE in front of the nearest console point inside the screen's (widened) outline.
function Step.PlacePhoneScreen(points, screenSize)
	local halfW = screenSize.X / 2 + Step.SCREEN_SIDE_MARGIN
	local y = Step.SCREEN_CENTER_HEIGHT
	local bottom = y - screenSize.Y / 2 - Step.SCREEN_HEIGHT_MARGIN
	local top = y + screenSize.Y / 2 + Step.SCREEN_HEIGHT_MARGIN
	local consoleAhead = math.huge
	for _, p in ipairs(points) do
		local ahead = -p[3]
		if math.abs(p[1]) <= halfW and p[2] >= bottom and p[2] <= top and ahead >= Step.RUNNER_CLEARANCE then
			consoleAhead = math.min(consoleAhead, ahead)
		end
	end
	local back = math.min(consoleAhead - Step.CONSOLE_CLEARANCE, Step.SCREEN_MAX_AHEAD + screenSize.Z / 2)
	return { y = y, ahead = back - screenSize.Z / 2, consoleAhead = consoleAhead }
end

-- Names of the furniture boxes (floor frame, grown by FURNITURE_MARGIN) holding one of the points.
local function furnitureClashes(points, furniture)
	local hits, seen = {}, {}
	for _, box in ipairs(furniture) do
		local lo, hi = box.lo, box.hi
		for _, p in ipairs(points) do
			if p[1] > lo.X and p[1] < hi.X and p[2] > lo.Y and p[2] < hi.Y and p[3] > lo.Z and p[3] < hi.Z then
				local l = box.cf:PointToObjectSpace(Vector3.new(p[1], p[2], p[3]))
				local h = box.size / 2
				if math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z then
					if not seen[box.name] then
						seen[box.name] = true
						table.insert(hits, box.name)
					end
					break
				end
			end
		end
	end
	return hits
end

-- Converts one skin in place (tier row of Step.TIERS, analysed source model). Returns a summary table.
-- furniture = every plot's own visible parts in the floor frame F' (the skin lands in F' on every plot).
local function convertSkin(tool, screenSize, tier, info, tbLength, furniture)
	local root, bbp = tool.Root, tool.BoundingBoxPart
	local ratePart = tool.SpeedPerSecond
	local hitbox = tool:FindFirstChild("Part")
	if hitbox and not (hitbox:IsA("BasePart") and hitbox.Transparency >= 1) then
		hitbox = nil
	end
	local decorFolder = tool:FindFirstChild(Step.DECOR_FOLDER_NAME)
	if not (decorFolder and (decorFolder:IsA("Folder") or decorFolder:IsA("Model"))) then
		decorFolder = Instance.new("Folder")
		decorFolder.Name = Step.DECOR_FOLDER_NAME
		decorFolder.Parent = tool
	end

	local F = root.CFrame
	local toTemplate = F * CFrame.new(0, -Step.ROOT_HEIGHT, 0) -- floor frame F' -> template space
	local rateRotation = F:ToObjectSpace(ratePart.CFrame).Rotation
	local videoRemoved = 0
	for _, name in ipairs(Step.VIDEO_PART_NAMES) do
		videoRemoved += countDescendants(tool, name)
	end

	-- 1. Drop every old part but the functional ones (the old decor meshes, light beams and the whole video set,
	--    whatever its parts are named), then every joint, any effect left without a rendering host, anything
	--    forbidden in a skin, and the holders left empty.
	local keep = { [root] = true, [bbp] = true, [ratePart] = true }
	if hitbox then
		keep[hitbox] = true
	end
	local removed = 0
	for _, d in ipairs(tool:GetDescendants()) do
		if d.Parent ~= nil and d:IsA("BasePart") and not keep[d] then
			d:Destroy()
			removed += 1
		end
	end
	for _, d in ipairs(tool:GetDescendants()) do
		if d.Parent ~= nil then
			if isA(d, JOINT_CLASSES) or isA(d, FORBIDDEN_IN_SKIN) then
				d:Destroy()
			elseif d:IsA("Beam") then
				local a0, a1 = d.Attachment0, d.Attachment1
				if not (a0 and a1 and a0:IsDescendantOf(tool) and a1:IsDescendantOf(tool)) then
					d:Destroy()
				end
			elseif isA(d, EFFECT_CLASSES) and not (d.Parent:IsA("BasePart") or d.Parent:IsA("Attachment")) then
				d:Destroy()
			end
		end
	end
	videoRemoved += Step.RemoveVideoSet(tool)
	for _, d in ipairs(decorFolder:GetChildren()) do
		if (d:IsA("Folder") or d:IsA("Model")) and d:FindFirstChildWhichIsA("BasePart", true) == nil then
			d:Destroy()
		end
	end

	-- 2. The model: clone the whole subtree once, strip what has no place in a static skin, then seat every part in
	--    the floor frame, scaled so the belt is as long as the plate, or a little shorter where the model would touch
	--    a plot part above the floor (the hidden part under the floor never counts).
	local baseScale = tbLength / info.beltLength
	local sourcePoints = {}
	for _, w in ipairs(info.framePoints) do
		local p = info.S:PointToObjectSpace(w) * baseScale
		if p.Y + Step.GROUND_EPSILON >= 0 then
			table.insert(sourcePoints, { p.X, p.Y, p.Z })
		end
	end
	local function pointsAt(f)
		local out = table.create(#sourcePoints)
		for i, p in ipairs(sourcePoints) do
			out[i] = { p[1] * f, p[2] * f + Step.GROUND_EPSILON, p[3] * f }
		end
		return out
	end
	local fit = 1
	while fit > Step.MIN_FIT + 1e-6 and #furnitureClashes(pointsAt(fit), furniture) > 0 do
		fit -= Step.FIT_STEP
	end
	fit = math.max(fit, Step.MIN_FIT)
	local scale = baseScale * fit
	local clone = info.model:Clone()
	for _, d in ipairs(clone:GetDescendants()) do
		if d.Parent ~= nil and isA(d, STRIP_CLASSES) then
			d:Destroy()
		end
	end
	local parts, frames, localPoses, belt = {}, {}, {}, nil
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			if d:IsA("MeshPart") and d.Name == info.belt.Name then
				belt = d
			elseif d.Transparency < 0.99 then
				table.insert(frames, d)
			end
		elseif not (d:IsA("Model") or d:IsA("Folder")) then
			scaleEffect(d, scale)
		end
	end
	assert(belt, tier.model .. ": the clone lost its belt " .. info.belt.Name)
	for _, d in ipairs(parts) do
		local rel = info.S:ToObjectSpace(d.CFrame)
		local L = CFrame.new(0, Step.GROUND_EPSILON, 0) * CFrame.new(rel.Position * scale) * rel.Rotation
		d.Size = d.Size * scale
		d.CFrame = toTemplate * L
		d.Anchored = true
		d.CanCollide = false
		d.CanTouch = false
		d.CanQuery = false
		d.CastShadow = d ~= belt and d.Transparency < 0.99
		d:SetAttribute(Step.DECOR_ATTRIBUTE, true)
		localPoses[d] = L
	end
	belt:SetAttribute(Step.BELT_ATTRIBUTE, true)

	-- 3. The tier's finish and particles.
	local finishKind = applyFinish(frames, tier.finish)
	local recolored = if tier.emitterColor then recolorEmitters(clone, tier.emitterColor) else 0
	local emitters, rateBefore, rateAfter = consolidateEmitters(clone)

	-- 4. The phone screen on the console, the rate sign above it.
	local points, exact = floorPoints(frames, toTemplate)
	local placement = Step.PlacePhoneScreen(points, screenSize)
	assert(placement.ahead >= Step.SCREEN_MIN_AHEAD, string.format("%s <- %s: the console leaves the phone screen only %.2f studs ahead of the runner (min %.2f)",
		tier.skin, tier.model, placement.ahead, Step.SCREEN_MIN_AHEAD))
	local screenLocal = CFrame.new(0, placement.y, -placement.ahead) * CFrame.Angles(0, math.pi, 0) -- Front face -> runner
	Step.AddPhoneScreen(tool, toTemplate * screenLocal, screenSize)
	local rateLocal = CFrame.new(0, placement.y + screenSize.Y / 2 + Step.RATE_SIGN_GAP, -placement.ahead) * rateRotation
	ratePart.CFrame = toTemplate * rateLocal
	ratePart.Anchored = true

	-- 5. Plot parts the model still touches at the smallest fit (reported; the plots are not identical).
	local clashes = furnitureClashes(pointsAt(fit), furniture)
	if #clashes > 0 then
		print(string.format("%s WARNING: %s <- %s touches plot parts: %s", LOG_PREFIX, tier.skin, tier.model, table.concat(clashes, ", ", 1, math.min(#clashes, 6))))
	end

	local pivot = toTemplate * CFrame.new(0, Step.GROUND_EPSILON, 0)
	for _, m in ipairs(clone:GetDescendants()) do
		if m:IsA("Model") then
			pcall(function()
				(m :: any).WorldPivotData = pivot
			end)
		end
	end
	pcall(function()
		(clone :: any).WorldPivotData = pivot
	end)
	clone.Name = info.model.Name
	clone:SetAttribute("SourceAsset", Step.SOURCE_ASSET_PREFIX .. info.model.Name)
	clone:SetAttribute(Step.MODEL_ATTRIBUTE, info.model.Name)
	clone.Parent = decorFolder

	-- 6. Root stays the template frame F (= floor frame at ROOT_HEIGHT over the plate centre).
	root.CFrame = toTemplate * CFrame.new(0, Step.ROOT_HEIGHT, 0)
	root.Anchored = true

	-- 7. BoundingBoxPart: centred on the plate (the grounding centres it there), enclosing the visible skin.
	local minV, maxV
	local function addBox(L, size)
		forEachCorner(L, size, function(w)
			minV = minV and minV:Min(w) or w
			maxV = maxV and maxV:Max(w) or w
		end)
	end
	for _, d in ipairs(parts) do
		if d.Transparency < 0.99 then
			addBox(localPoses[d], d.Size)
		end
	end
	addBox(screenLocal, screenSize)
	local halfX = math.max(math.abs(minV.X), math.abs(maxV.X))
	local halfZ = math.max(math.abs(minV.Z), math.abs(maxV.Z))
	local boxSize = Vector3.new(2 * halfX, maxV.Y - minV.Y, 2 * halfZ)
	local boxCFrame = toTemplate * CFrame.new(0, (minV.Y + maxV.Y) / 2, 0)
	bbp.Size = boxSize
	bbp.CFrame = boxCFrame
	bbp.Anchored = true
	if hitbox then
		hitbox.Size = boxSize
		hitbox.CFrame = boxCFrame
		hitbox.Anchored = true
	end
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end

	-- Grounding puts the box bottom `Offset` above the plate; the floor correction then makes it the floor.
	tool:SetAttribute("Offset", minV.Y)
	tool:SetAttribute(Step.FLOOR_ALIGNED_ATTRIBUTE, true)
	tool:SetAttribute("SourceAsset", Step.SOURCE_ASSET_PREFIX .. info.model.Name)
	tool:SetAttribute(Step.MODEL_ATTRIBUTE, info.model.Name)
	tool:SetAttribute(Step.FINISH_ATTRIBUTE, finishKind)
	tool:SetAttribute("Scale", scale)
	pcall(function()
		(tool :: any).WorldPivotData = F
	end)

	return {
		scale = scale,
		fit = fit,
		parts = #parts,
		meshes = #frames + 1,
		emitters = emitters,
		rateBefore = rateBefore,
		rateAfter = rateAfter,
		recolored = recolored,
		finish = finishKind,
		removed = removed,
		videoRemoved = videoRemoved,
		offset = minV.Y,
		box = boxSize,
		belt = Vector3.new(belt.Size.X, belt.Size.Y, belt.Size.Z),
		screen = screenLocal.Position,
		consoleAhead = placement.consoleAhead,
		rateCenter = rateLocal.Position,
		exact = exact,
		clashes = #clashes,
	}
end

-- Checks a converted skin on every plot with the renderers' own grounding. Errors on a layout bug.
local function verifySkin(tool, tier, plotInfos)
	local F = tool.Root.CFrame
	local belts, meshes, meshesOk, maps, mapsOk = {}, 0, 0, 0, 0
	for _, d in ipairs(tool:GetDescendants()) do
		if isA(d, FORBIDDEN_IN_SKIN) then
			error(string.format("%s: %s %s left in the skin", tier.skin, d.ClassName, d:GetFullName()))
		end
		if d:IsA("BasePart") then
			if not d.Anchored then
				error(tier.skin .. ": unanchored part " .. d:GetFullName())
			end
			if d:GetAttribute(Step.BELT_ATTRIBUTE) == true then
				table.insert(belts, d)
			end
			if d:IsA("MeshPart") then
				meshes += 1
				if contentUri(d, "MeshContent") ~= "" then
					meshesOk += 1
				end
			end
		elseif d:IsA("SurfaceAppearance") then
			maps += 1
			if contentUri(d, "ColorMapContent") ~= "" then
				mapsOk += 1
			end
		end
	end
	assert(#belts == 1 and belts[1]:IsA("MeshPart"), string.format("%s: expected one %s MeshPart, found %d", tier.skin, Step.BELT_ATTRIBUTE, #belts))
	assert(meshes > 1 and meshesOk == meshes, string.format("%s: %d of %d MeshParts lost their MeshContent", tier.skin, meshes - meshesOk, meshes))
	assert(mapsOk == maps, string.format("%s: %d of %d SurfaceAppearances lost their ColorMap", tier.skin, maps - mapsOk, maps))
	for _, name in ipairs(Step.VIDEO_PART_NAMES) do
		local n = countDescendants(tool, name)
		assert(n == 0, string.format("%s: %d descendant(s) named %s left (D4: the video set is removed)", tier.skin, n, name))
	end
	-- The Hero Flap phone screen: one, on the console, Front face toward the runner, visual only.
	local phoneScreen = tool:FindFirstChild(Step.PHONE_SCREEN_NAME)
	assert(phoneScreen ~= nil and phoneScreen:IsA("BasePart") and countDescendants(tool, Step.PHONE_SCREEN_NAME) == 1,
		tier.skin .. ": expected exactly one " .. Step.PHONE_SCREEN_NAME .. " part (direct child of the Tool)")
	local screenRel = F:ToObjectSpace(phoneScreen.CFrame)
	assert(phoneScreen.CFrame.LookVector:Dot(F.LookVector) <= -0.99,
		tier.skin .. ": " .. Step.PHONE_SCREEN_NAME .. " Front face must face the runner (against Root.LookVector)")
	assert(-screenRel.Position.Z >= Step.SCREEN_MIN_AHEAD - 0.01 and math.abs(screenRel.Position.X) <= 0.05
		and math.abs(screenRel.Position.Y - (Step.SCREEN_CENTER_HEIGHT - Step.ROOT_HEIGHT)) <= 0.05,
		string.format("%s: %s at %s from Root, expected ahead of the runner at eye height", tier.skin, Step.PHONE_SCREEN_NAME, tostring(screenRel.Position)))
	assert(phoneScreen.Anchored and not phoneScreen.CanCollide and not phoneScreen.CanTouch and phoneScreen.CanQuery,
		tier.skin .. ": " .. Step.PHONE_SCREEN_NAME .. " must be anchored, non-colliding, no touch, queryable")
	-- Nothing visible of the skin may stand in the screen or in front of it: no block part's box and no mesh hull point
	-- in the box the screen occupies plus SCREEN_SIGHT_DEPTH studs toward the runner. A MeshPart without readable hull
	-- data can only be box-tested (its mesh rarely fills its box), so it is reported instead.
	local size = phoneScreen.Size
	local sightCF = phoneScreen.CFrame * CFrame.new(0, 0, -Step.SCREEN_SIGHT_DEPTH / 2)
	local sightSize = Vector3.new(size.X, size.Y, size.Z + Step.SCREEN_SIGHT_DEPTH)
	local unchecked, crossings = 0, 0
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") and d ~= phoneScreen
			and (d.Transparency < 0.99 or d:FindFirstChildWhichIsA("Decal") or d:FindFirstChildWhichIsA("SurfaceGui")) then
			local points = if d:IsA("MeshPart") then Models.MeshPoints(roblox, d) else nil
			if points then
				local seq = {}
				for _, w in ipairs(points) do
					local l = sightCF:PointToObjectSpace(w)
					local inDepth = math.abs(l.Z) < sightSize.Z / 2 and math.abs(l.Y) < sightSize.Y / 2 - 0.02
					if inDepth and math.abs(l.X) < sightSize.X / 2 - 0.02 then
						error(string.format("%s: %s (hull point %.2f, %.2f, %.2f in the screen's frame) stands in or in front of the %s and hides the phone",
							tier.skin, d:GetFullName(), l.X, l.Y, l.Z + Step.SCREEN_SIGHT_DEPTH / 2, Step.PHONE_SCREEN_NAME))
					end
					table.insert(seq, if not inDepth then "." elseif l.X < 0 then "L" else "R")
				end
				-- Hull vertices are stored hull after hull: a run in front of the screen that keeps alternating
				-- between both sides would be a bar across it (its corners all outside the outline).
				local runs = string.gsub(table.concat(seq), "%.+", "|")
				for a, b in string.gmatch(runs, "([LR])([LR])") do
					if a ~= b then
						crossings += 1
					end
				end
			elseif Step.BoxesOverlap(d.CFrame, d.Size, sightCF, sightSize, -0.01) then
				assert(d:IsA("MeshPart"), string.format("%s: %s (%s) stands in front of the %s and hides the phone",
					tier.skin, d:GetFullName(), d.ClassName, Step.PHONE_SCREEN_NAME))
				unchecked += 1
			end
		end
	end
	if unchecked > 0 or crossings > 1 then
		print(string.format("%s tier %2d %-21s note: %d mesh box(es) without hull data and %d side-to-side hull run(s) in front of the %s (check in Studio).",
			LOG_PREFIX, tier.level, tier.skin, unchecked, crossings, Step.PHONE_SCREEN_NAME))
	end
	local belt = belts[1]
	for _, info in ipairs(plotInfos) do
		local tb, floorY = info.tb, info.floorY
		local rootWorld = Step.GroundedRootCFrame(tool, tb, floorY)
		local toWorld = rootWorld * F:Inverse()
		local beltWorld = toWorld * belt.CFrame
		local beltTop = (beltWorld * Vector3.new(0, belt.Size.Y / 2, 0)).Y
		local beltLocal = tb.CFrame:PointToObjectSpace(beltWorld.Position)
		local rootLocal = tb.CFrame:PointToObjectSpace(rootWorld.Position)
		local expected = floorY + Step.GROUND_EPSILON
		assert(math.abs(beltTop - expected) <= 0.01,
			string.format("%s plot %s: belt top %.3f, expected %.3f", tier.skin, info.plot.Name, beltTop, expected))
		assert(math.abs(beltLocal.X) <= 0.05 and math.abs(beltLocal.Z) <= 0.05,
			string.format("%s plot %s: belt off the plate centre (%.3f, %.3f)", tier.skin, info.plot.Name, beltLocal.X, beltLocal.Z))
		local beltAxis = if belt.Size.Z >= belt.Size.X then beltWorld.LookVector else beltWorld.RightVector
		assert(math.abs(beltAxis:Dot(tb.CFrame.LookVector)) >= 0.999,
			string.format("%s plot %s: the belt does not run along the plate's long axis", tier.skin, info.plot.Name))
		assert(math.abs(rootLocal.X) <= 0.01 and math.abs(rootLocal.Z) <= 0.01,
			string.format("%s plot %s: Root off the plate centre (%.3f, %.3f)", tier.skin, info.plot.Name, rootLocal.X, rootLocal.Z))
		assert(rootWorld.LookVector:Dot(tb.CFrame.LookVector) >= 0.999,
			string.format("%s plot %s: Root.LookVector not along TreadmillBottom.LookVector", tier.skin, info.plot.Name))
	end
	return meshes, maps
end

---------------------------------------------------------------------------------------------------
-- D6 display
---------------------------------------------------------------------------------------------------
local function setModernStrokeProps(stroke, thickness, offset)
	pcall(function()
		(stroke :: any).StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	end)
	stroke.Thickness = thickness
	if offset then
		pcall(function()
			(stroke :: any).BorderOffset = roblox.UDim.new(offset, 0)
		end)
	end
end

local function gradient(stops, rotation)
	local g = Instance.new("UIGradient")
	local kps = {}
	for _, stop in ipairs(stops) do
		table.insert(kps, ColorSequenceKeypoint.new(stop[1], stop[2]))
	end
	g.Color = ColorSequence.new(kps)
	g.Rotation = rotation or 90
	return g
end

local function textLabel(name, text, fontFace, strokeColor, strokeThickness)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.AnchorPoint = roblox.Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.84, 0.62)
	label.FontFace = fontFace
	label.Text = text
	label.TextColor3 = rgb(255, 255, 255)
	label.TextScaled = true
	label.TextWrapped = true
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = strokeColor
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	setModernStrokeProps(stroke, strokeThickness, nil)
	stroke.Parent = label
	return label
end

local function aspect(parent, ratio)
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = ratio
	ar.Parent = parent
	return ar
end

-- An ImageLabel dressed like a Speedsters button: the authored exemplar's look (image, gradient, strokes,
-- corner, aspect, label) when the exemplar exists, else the documented fallback values.
local function pillFromExemplar(name, exemplar, fallbackImage, build)
	local pill = Instance.new("ImageLabel")
	pill.Name = name
	pill.AnchorPoint = roblox.Vector2.new(0.5, 0.5)
	pill.BackgroundColor3 = rgb(255, 255, 255)
	pill.BackgroundTransparency = 1
	pill.ImageContent = roblox.Content.fromUri(fallbackImage)
	pill.ScaleType = Enum.ScaleType.Stretch
	local fromExemplar = false
	if exemplar and (exemplar:IsA("ImageLabel") or exemplar:IsA("ImageButton")) then
		fromExemplar = true
		for _, prop in ipairs({ "BackgroundColor3", "BackgroundTransparency", "ImageColor3", "ImageTransparency", "ImageContent" }) do
			pcall(function()
				pill[prop] = exemplar[prop]
			end)
		end
		for _, child in ipairs(exemplar:GetChildren()) do
			if child:IsA("UIComponent") or child:IsA("UIStroke") or child:IsA("UIGradient") or child:IsA("UICorner")
				or child:IsA("UIAspectRatioConstraint") or child:IsA("TextLabel") then
				child:Clone().Parent = pill -- each is a self-contained leaf subtree (no instance refs)
			end
		end
	end
	build(pill, fromExemplar)
	return pill
end

local function buildLockBillboard(spPlace)
	local starterGui = spPlace and spPlace:FindFirstChild("StarterGui")
	local unlockExemplar = starterGui and findPath(starterGui, Step.EXEMPLAR_UNLOCK)
	local priceExemplar = starterGui and findPath(starterGui, Step.EXEMPLAR_PRICE)
	local gotham = roblox.Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	local fredoka = roblox.Font.fromEnum(Enum.Font.FredokaOne)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = Step.DISPLAY_BILLBOARD_NAME
	billboard.Size = UDim2.fromScale(6.4, 5.4) -- studs
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.MaxDistance = 110
	billboard.ClipsDescendants = false
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Active = false
	billboard.Enabled = true
	billboard:SetAttribute("TreadmillLockBillboard", true)

	local icon = Instance.new("ImageLabel")
	icon.Name = "LockIcon"
	icon.AnchorPoint = roblox.Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.26)
	icon.Size = UDim2.fromScale(0.44, 0.48)
	icon.BackgroundTransparency = 1
	icon.ImageContent = roblox.Content.fromUri(Step.LOCK_ICON)
	icon.ScaleType = Enum.ScaleType.Stretch
	aspect(icon, 1)
	icon.Parent = billboard

	local unlock = pillFromExemplar("UnlockButton", unlockExemplar, Step.ACTION_PILL, function(pill, fromExemplar)
		if not fromExemplar then
			pill.BackgroundTransparency = 0
			local corner = Instance.new("UICorner")
			corner.CornerRadius = roblox.UDim.new(0.25, 0)
			corner.Parent = pill
			gradient({ { 0, rgb(8, 255, 247) }, { 0.4577, rgb(11, 228, 248) }, { 1, rgb(18, 155, 167) } }).Parent = pill
			local white = Instance.new("UIStroke")
			white.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			white.Color = rgb(255, 255, 255)
			setModernStrokeProps(white, 0.06, -0.1)
			gradient({ { 0, rgb(147, 244, 255) }, { 0.6356, rgb(7, 244, 248) }, { 1, rgb(9, 89, 86) } }).Parent = white
			white.Parent = pill
			local dark = Instance.new("UIStroke")
			dark.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			dark.Color = rgb(0, 53, 53)
			setModernStrokeProps(dark, 0.05, -0.05)
			dark.Parent = pill
			aspect(pill, 2.6)
		end
		local label = pill:FindFirstChild("Name")
		if not (label and label:IsA("TextLabel")) then
			label = textLabel("Name", "UNLOCK", gotham, rgb(61, 6, 46), 0.08)
			label.Parent = pill
		end
		label.Text = "UNLOCK"
		label.FontFace = gotham
		label.TextScaled = true
	end)
	unlock.Position = UDim2.fromScale(0.5, 0.64)
	unlock.Size = UDim2.fromScale(0.78, 0.26)
	unlock.Parent = billboard

	local price = pillFromExemplar("PricePill", priceExemplar, Step.PRICE_PILL, function(pill, fromExemplar)
		if not fromExemplar then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = roblox.UDim.new(0.25, 0)
			corner.Parent = pill
			gradient({ { 0, rgb(132, 255, 0) }, { 0.7799, rgb(30, 210, 45) }, { 1, rgb(56, 165, 93) } }).Parent = pill
			local white = Instance.new("UIStroke")
			white.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			white.Color = rgb(255, 255, 255)
			setModernStrokeProps(white, 0.13, -0.12)
			gradient({ { 0, rgb(125, 255, 55) }, { 0.5088, rgb(123, 255, 75) }, { 1, rgb(0, 255, 17) } }).Parent = white
			white.Parent = pill
			local dark = Instance.new("UIStroke")
			dark.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			dark.Color = rgb(0, 0, 0)
			setModernStrokeProps(dark, 0.07, -0.04)
			dark.Parent = pill
			aspect(pill, 3.0152)
		end
		local label = pill:FindFirstChild("Name")
		if not (label and label:IsA("TextLabel")) then
			label = textLabel("Name", Step.UNLOCK_PRICE_TEXT, fredoka, INK, 0.06)
			label.Parent = pill
		end
		-- the Wins pill's label sits right of its currency icon: centre it and let it fill the pill
		label.Name = "Price"
		label.Text = Step.UNLOCK_PRICE_TEXT
		label.FontFace = fredoka
		label.TextScaled = true
		label.AnchorPoint = roblox.Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(0.82, 0.72)
		for _, c in ipairs(label:GetChildren()) do
			if c:IsA("UIAspectRatioConstraint") then
				c:Destroy()
			end
		end
	end)
	price.Position = UDim2.fromScale(0.5, 0.9)
	price.Size = UDim2.fromScale(0.62, 0.2)
	price.Parent = billboard

	return billboard, unlockExemplar ~= nil, priceExemplar ~= nil
end

local function setVisualOnly(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

-- Places the static display on one plot: the tier-1 skin's model clone, cloned once and moved to exactly where the
-- renderers would ground the tier-1 skin on this plot, without its effects (a quiet preview).
local function buildDisplay(plotInfo, tier1, billboardTemplate)
	local tool = tier1.tool
	local decorFolder = tool:FindFirstChild(Step.DECOR_FOLDER_NAME)
	local container = decorFolder and decorFolder:FindFirstChild(tier1.tier.model)
	assert(container, "tier-1 skin has no " .. Step.DECOR_FOLDER_NAME .. "." .. tier1.tier.model)
	local rootWorld = Step.GroundedRootCFrame(tool, plotInfo.tb, plotInfo.floorY)
	local toWorld = rootWorld * tool.Root.CFrame:Inverse()
	local floorFrame = rootWorld * CFrame.new(0, -Step.ROOT_HEIGHT, 0)

	local display = container:Clone()
	display.Name = Step.DISPLAY_NAME
	for _, d in ipairs(display:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = toWorld * d.CFrame
			setVisualOnly(d)
			local orig = d.Transparency
			d:SetAttribute("OrigTransparency", orig)
			if orig < 0.99 then
				d.Transparency = math.max(orig, Step.DISPLAY_LOCKED_TRANSPARENCY)
			end
		elseif d:IsA("Model") then
			pcall(function()
				(d :: any).WorldPivotData = floorFrame
			end)
		elseif isA(d, EFFECT_CLASSES) or isA(d, STRIP_CLASSES) then
			d:Destroy()
		end
	end
	pcall(function()
		(display :: any).WorldPivotData = floorFrame
	end)

	local anchor = Instance.new("Part")
	anchor.Name = Step.DISPLAY_ANCHOR_NAME
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.CFrame = floorFrame * CFrame.new(0, Step.DISPLAY_ANCHOR_HEIGHT, 0)
	setVisualOnly(anchor)
	anchor:SetAttribute("OrigTransparency", 1)
	anchor.Parent = display
	local billboard = billboardTemplate:Clone()
	billboard.Parent = anchor

	display:SetAttribute("SourceAsset", Step.SOURCE_ASSET_PREFIX .. tier1.tier.model)
	display:SetAttribute("PlotId", tonumber(plotInfo.plot.Name) or plotInfo.plot.Name)
	display:SetAttribute("VisualOnly", true)
	display:SetAttribute(Step.DISPLAY_STATE_ATTRIBUTE, "Locked")
	display:SetAttribute("LockedTransparency", Step.DISPLAY_LOCKED_TRANSPARENCY)
	pcall(function()
		display:AddTag(Step.DISPLAY_TAG)
	end)
	display.Parent = plotInfo.plot
	return display
end

-- Checks a display with the same formulas as the skins. Errors on a layout/flag bug.
local function verifyDisplay(display, plotInfo)
	local tb, floorY = plotInfo.tb, plotInfo.floorY
	local belts, parts = {}, 0
	for _, d in ipairs(display:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
			if not (d.Anchored and not d.CanCollide and not d.CanQuery and not d.CanTouch) then
				error(string.format("plot %s: display part %s is not visual-only", plotInfo.plot.Name, d.Name))
			end
			if d:GetAttribute(Step.BELT_ATTRIBUTE) == true then
				table.insert(belts, d)
			end
		elseif isA(d, EFFECT_CLASSES) or isA(d, FORBIDDEN_IN_SKIN) then
			error(string.format("plot %s: display keeps a %s (%s)", plotInfo.plot.Name, d.ClassName, d:GetFullName()))
		end
	end
	assert(#belts == 1, string.format("plot %s: display has %d belts, expected 1", plotInfo.plot.Name, #belts))
	local belt = belts[1]
	local beltTop = (belt.CFrame * Vector3.new(0, belt.Size.Y / 2, 0)).Y
	assert(math.abs(beltTop - (floorY + Step.GROUND_EPSILON)) <= 0.01,
		string.format("plot %s: display belt top %.3f, expected %.3f", plotInfo.plot.Name, beltTop, floorY + Step.GROUND_EPSILON))
	local centre = tb.CFrame:PointToObjectSpace(belt.CFrame.Position)
	assert(math.abs(centre.X) <= 0.05 and math.abs(centre.Z) <= 0.05,
		string.format("plot %s: display belt off the plate centre (%.3f, %.3f)", plotInfo.plot.Name, centre.X, centre.Z))
	local anchor = display:FindFirstChild(Step.DISPLAY_ANCHOR_NAME)
	local billboard = anchor and anchor:FindFirstChild(Step.DISPLAY_BILLBOARD_NAME)
	assert(billboard and billboard:IsA("BillboardGui") and billboard.Enabled, "plot " .. plotInfo.plot.Name .. ": display has no enabled lock billboard")
	return parts
end

-- The treadmill models place (first readable Step.MODEL_FILES entry), or nil.
local function loadModelPlace(ctx)
	local fs = ctx.fs or require("@lune/fs")
	for _, path in ipairs(Step.MODEL_FILES) do
		if fs.isFile(path) then
			local ok, result = pcall(function()
				return roblox.deserializePlace(fs.readFile(path))
			end)
			if ok then
				return result, path
			end
			print(string.format("%s WARNING: could not read %s: %s", LOG_PREFIX, path, tostring(result)))
		end
	end
	return nil, nil
end

-- ctx = { roblox, fs, baseplate, groundY, shiftOffset } (see scripts/build_stealahero.luau)
function Step.Apply(place, spPlace, ctx)
	ctx = ctx or {}
	local groundY = resolveGroundY(place, ctx)

	-- 1. Plots: drop earlier static models, record the walkable floor under each plate.
	local plotInfos = {}
	local plots = place.Workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in ipairs(plots:GetChildren()) do
			for _, child in ipairs(plot:GetChildren()) do
				if child.Name == Step.LEGACY_MODEL_NAME or child.Name == Step.DISPLAY_NAME then
					child:Destroy()
				end
			end
			local tb = plot:FindFirstChild("TreadmillBottom")
			if tb and tb:IsA("BasePart") then
				local floorY = groundY or (tb.CFrame.Position.Y + tb.Size.Y / 2)
				plot:SetAttribute(Step.FLOOR_ATTRIBUTE, floorY)
				table.insert(plotInfos, { plot = plot, tb = tb, floorY = floorY })
			elseif plot:IsA("Model") then
				print(LOG_PREFIX .. " WARNING: plot " .. plot.Name .. " has no TreadmillBottom part.")
			end
		end
	else
		print(LOG_PREFIX .. " WARNING: Workspace.Plots not found.")
	end
	table.sort(plotInfos, function(a, b)
		return (tonumber(a.plot.Name) or 0) < (tonumber(b.plot.Name) or 0)
	end)
	print(string.format("%s %d plots, %s set to %s.", LOG_PREFIX, #plotInfos, Step.FLOOR_ATTRIBUTE,
		groundY and string.format("%.3f", groundY) or "the plate top"))
	if #plotInfos == 0 then
		print(LOG_PREFIX .. " WARNING: no TreadmillBottom to size the belts against; skins keep their original look, no displays.")
		return 0
	end

	-- Every plate is 8.548 x 13.422; the belt length matches the long side of the first one.
	local tbLength = math.max(plotInfos[1].tb.Size.X, plotInfos[1].tb.Size.Z)
	for _, info in ipairs(plotInfos) do
		local len = math.max(info.tb.Size.X, info.tb.Size.Z)
		if math.abs(len - tbLength) > 0.01 then
			print(string.format("%s WARNING: plot %s TreadmillBottom is %.3f long (plot %s: %.3f); belts sized for %.3f.",
				LOG_PREFIX, info.plot.Name, len, plotInfos[1].plot.Name, tbLength, tbLength))
		end
	end

	-- 2. The models (each read once).
	local source, sourcePath = loadModelPlace(ctx)
	if not source then
		print(string.format("%s WARNING: !! no treadmill model file (%s): NO treadmill skin converted, NO plot display.",
			LOG_PREFIX, table.concat(Step.MODEL_FILES, ", ")))
	end
	local analyses = {}
	local function getModel(name)
		if analyses[name] ~= nil then
			return analyses[name] or nil
		end
		local model = source and source.Workspace:FindFirstChild(name)
		if not (model and model:IsA("Model")) then
			print(string.format("%s WARNING: !! model Workspace.%s not found in %s.", LOG_PREFIX, name, tostring(sourcePath)))
			analyses[name] = false
			return nil
		end
		local info, err = Models.Analyze(roblox, model)
		if not info then
			print(string.format("%s WARNING: !! model %s: %s.", LOG_PREFIX, name, tostring(err)))
			analyses[name] = false
			return nil
		end
		analyses[name] = info
		return info
	end

	-- Every plot's own visible parts near its plate, in its floor frame F' (TreadmillBottom X/Z and rotation,
	-- Y = floor): a skin sits in F' on every plot, so it is checked against all of them at once.
	local furniture = {}
	for _, info in ipairs(plotInfos) do
		local tbPos = info.tb.CFrame.Position
		local toFloor = (CFrame.new(tbPos.X, info.floorY, tbPos.Z) * info.tb.CFrame.Rotation):Inverse()
		for _, d in ipairs(info.plot:GetDescendants()) do
			if d:IsA("BasePart") and d ~= info.tb and d.Transparency < 1 then
				local cf = toFloor * d.CFrame
				local lo, hi
				forEachCorner(cf, d.Size, function(w)
					lo = lo and lo:Min(w) or w
					hi = hi and hi:Max(w) or w
				end)
				if hi.X > -16 and lo.X < 16 and hi.Z > -16 and lo.Z < 16 and lo.Y < 16 then
					local grow = if (d.Name == "Sign" or d.Name == "Support") and d.Parent and Step.UPGRADE_SIGN_MODELS[d.Parent.Name]
						then Step.UPGRADE_SIGN_MARGIN
						else Step.FURNITURE_MARGIN
					local margin = Vector3.new(grow, grow, grow)
					table.insert(furniture, {
						cf = cf,
						size = d.Size + margin * 2,
						name = info.plot.Name .. "." .. d.Name,
						lo = lo - margin,
						hi = hi + margin,
					})
				end
			end
		end
	end

	-- 3. Convert + verify every tier.
	local skinsFolder = findPath(place.ReplicatedStorage, Step.SKINS_PATH)
	local converted, skipped, tier1 = 0, {}, nil
	for _, tier in ipairs(Step.TIERS) do
		local tool = skinsFolder and skinsFolder:FindFirstChild(tier.skin)
		local alreadyConverted = tool ~= nil and tool:GetAttribute("SourceAsset") == Step.SOURCE_ASSET_PREFIX .. tier.model
			and tool:GetAttribute(Step.MODEL_ATTRIBUTE) == tier.model
		local screenSize, skinErr = nil, nil
		if not alreadyConverted then
			screenSize, skinErr = validateSkin(tool, tier.skin)
		end
		local info = screenSize and source and getModel(tier.model)
		if alreadyConverted then
			Step.RemoveVideoSet(tool)
			print(string.format("%s tier %d %s already wears %s; conversion skipped.", LOG_PREFIX, tier.level, tier.skin, tier.model))
		elseif not screenSize then
			print(LOG_PREFIX .. " WARNING: !! " .. tostring(skinErr) .. "; tier " .. tier.level .. " left unchanged.")
			table.insert(skipped, tier.skin)
		elseif not info then
			table.insert(skipped, tier.skin)
		else
			local r = convertSkin(tool, screenSize, tier, info, tbLength, furniture)
			converted += 1
			print(string.format("%s tier %2d %-21s <- %-16s finish %-8s scale %.4f (fit %.2f)  %2d parts (%d meshes), belt %.2f x %.2f, %d emitters (%.0f -> %.0f particles/s, %d recoloured)  box %.2f x %.2f x %.2f  Offset %.3f  (%d old parts dropped, %d video-set instances removed)",
				LOG_PREFIX, tier.level, tier.skin, tier.model, r.finish, r.scale, r.fit, r.parts, r.meshes, r.belt.X, r.belt.Z, r.emitters,
				r.rateBefore, r.rateAfter, r.recolored, r.box.X, r.box.Y, r.box.Z, r.offset, r.removed, r.videoRemoved))
			print(string.format("%s tier %2d %-21s %s centre (%.2f, %.2f, %.2f) in the floor frame (%.2f ahead of the runner, console at %.2f), rate sign (%.2f, %.2f, %.2f)%s",
				LOG_PREFIX, tier.level, tier.skin, Step.PHONE_SCREEN_NAME, r.screen.X, r.screen.Y, r.screen.Z, -r.screen.Z, r.consoleAhead,
				r.rateCenter.X, r.rateCenter.Y, r.rateCenter.Z, if r.exact then "" else " (WARNING: some meshes without hull data, placed by their boxes)"))
		end
		if tool and tool:GetAttribute("SourceAsset") == Step.SOURCE_ASSET_PREFIX .. tier.model then
			local meshes, maps = verifySkin(tool, tier, plotInfos)
			print(string.format("%s tier %2d %-21s verified on %d plots: belt flush at floor+%.2f along the plate, Root over the plate facing TreadmillBottom.LookVector, no video set, one clear PhoneScreen facing the runner, %d meshes / %d texture sets kept.",
				LOG_PREFIX, tier.level, tier.skin, #plotInfos, Step.GROUND_EPSILON, meshes, maps))
			if tier.level == 1 then
				tier1 = { tool = tool, tier = tier }
			end
		end
	end
	-- D4: no skin keeps a video set, converted or not (the runtime video player is gone).
	local leftoverVideo = 0
	for _, tool in ipairs(skinsFolder and skinsFolder:GetChildren() or {}) do
		leftoverVideo += Step.RemoveVideoSet(tool)
	end
	if leftoverVideo > 0 then
		print(string.format("%s removed %d leftover video-set instance(s) from unconverted skins.", LOG_PREFIX, leftoverVideo))
	end
	if #skipped > 0 then
		print(string.format("%s WARNING: !! %d of %d treadmill tiers NOT converted (keep their Steal-an-Egg skins): %s",
			LOG_PREFIX, #skipped, #Step.TIERS, table.concat(skipped, ", ")))
	end

	-- 4. D6: the static locked display on every plot.
	local displays = 0
	if tier1 then
		local billboard, fromUnlock, fromPrice = buildLockBillboard(spPlace)
		for _, info in ipairs(plotInfos) do
			local display = buildDisplay(info, tier1, billboard)
			verifyDisplay(display, info)
			displays += 1
		end
		billboard:Destroy()
		print(string.format("%s %d plots carry a locked %s (tier-1 %s look, visual-only, no effects; lock billboard %s): shown locked until the owner buys the treadmill, hidden at runtime while the real render exists.",
			LOG_PREFIX, displays, Step.DISPLAY_NAME, tier1.tier.model,
			(fromUnlock and fromPrice) and "cloned from the Speedsters exemplars" or "built from the documented Speedsters values"))
	else
		print(LOG_PREFIX .. " WARNING: !! the tier-1 skin wears no treadmill model; no " .. Step.DISPLAY_NAME .. " placed.")
	end

	print(string.format("[StealaHero Build] Treadmills: %d/%d skins wear the new treadmill models from %s (%d converted now; unused: %s), %d plots with a locked static display.",
		#Step.TIERS - #skipped, #Step.TIERS, tostring(sourcePath), converted, table.concat(Step.UNUSED_MODELS, ", "), displays))
	return displays
end

return Step
