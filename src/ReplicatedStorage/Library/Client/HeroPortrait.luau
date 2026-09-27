-- ReplicatedStorage.Library.Client.HeroPortrait (ModuleScript; injected by scripts/inject/portraits.luau)
-- Live hero headshots (docs/HERO_MODELS_PLAN.md H3). No image can be uploaded, so every portrait is a ViewportFrame
-- that shows a private clone of the hero's model with the camera on its face:
--   * model: ReplicatedStorage.AssetModels.<id>, else ReplicatedStorage.Assets.Models.Heroes.<id>;
--   * the clone loses its scripts, sounds, particles, lights and billboards, every part is anchored, no WorldModel and
--     no animation: a portrait costs nothing per frame once it is mounted;
--   * framing: the rig's Head (else the top of the model) seen from its face side (face decal / FaceFrontAttachment /
--     root part), a slight 3/4 turn and a small field of view; hair, hats and helmets welded to the head (or hooked to
--     a head attachment) are kept in frame, up to a limit so capes and wings never shrink the face;
--   * silhouette mode (locked / undiscovered heroes): the whole render is multiplied to black (ImageColor3).
-- Everything a portrait owns (clone, camera) lives under its ViewportFrame: destroying the frame (or any ancestor)
-- cleans it up. Nothing is cached between portraits; every Mount clones the model afresh.
--
-- API
--   HeroPortrait.HasModel(heroId) -> boolean
--   HeroPortrait.Mount(parent, heroId, opts?) -> ViewportFrame?   (nil when the hero has no model or it cannot be framed)
--       Re-mounting the hero a parent already shows only re-applies opts (no new clone). Another hero replaces it.
--       opts: Silhouette (boolean), SilhouetteTransparency (number, default 0.35), Framing ("Face" | "Bust"),
--             Yaw / Pitch (degrees), FieldOfView (degrees), Square (boolean, default true), ZIndex (number)
--   HeroPortrait.Get(parent) -> ViewportFrame?
--   HeroPortrait.SetSilhouette(parentOrPortrait, on, transparency?)
--   HeroPortrait.Clear(parent)
--   HeroPortrait.Lazy(scroller?, { PerStep, Margin }) -> loader
--       loader:Request(parent, heroId, opts?) mounts once the parent is laid out and inside the scroller's view (+margin),
--       at most PerStep portraits per frame; opts.OnFailed() runs when the mount fails. Event driven (AbsolutePosition /
--       AbsoluteSize changes), no per-frame loop. loader:Cancel(parent), loader:Destroy().

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HeroPortrait = {}

HeroPortrait.PORTRAIT_NAME = "HeroPortrait"
HeroPortrait.SILHOUETTE_COLOR = Color3.new(0, 0, 0)
HeroPortrait.SILHOUETTE_TRANSPARENCY = 0.35
HeroPortrait.FIELD_OF_VIEW = 20 -- degrees (vertical; portraits are square)
HeroPortrait.YAW = 20 -- degrees: slight 3/4 turn
HeroPortrait.PITCH = 6 -- degrees: camera a little above the eyes
HeroPortrait.AMBIENT = Color3.fromRGB(180, 180, 190)
HeroPortrait.LIGHT_COLOR = Color3.fromRGB(210, 205, 195)

-- Frame limits in head heights around the head centre: top (hair / hats may reach this high), bottom (chin, neck and
-- the top of the shoulders), side (half width reserved for wide hair), padding (breathing room).
local FRAMINGS = {
	Face = { top = 1.6, bottom = 0.85, side = 1.15, padding = 1.04 },
	Bust = { top = 1.6, bottom = 2.4, side = 1.9, padding = 1.02 },
}

local UP = Vector3.new(0, 1, 0)

-- Instances a portrait never needs (behaviour, audio, effects that do not render in a ViewportFrame anyway).
local STRIP_CLASSES = {
	"LuaSourceContainer", "Sound", "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Light",
	"BillboardGui", "ProximityPrompt", "ClickDetector", "Highlight", "ForceField", "Explosion", "SelectionBox",
	"SelectionSphere", "Dialog",
}

-- Accessory attachments that sit on the head (hair, hats, masks, glasses).
local HEAD_ATTACHMENTS = {
	HatAttachment = true,
	HairAttachment = true,
	FaceFrontAttachment = true,
	FaceCenterAttachment = true,
}

-- Body parts of R15 / R6 rigs: never part of the "things worn on the head" set.
local BODY_PARTS = {
	HumanoidRootPart = true, Torso = true, UpperTorso = true, LowerTorso = true,
	["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
}

local NORMALS = {
	[Enum.NormalId.Front] = Vector3.new(0, 0, -1),
	[Enum.NormalId.Back] = Vector3.new(0, 0, 1),
	[Enum.NormalId.Right] = Vector3.new(1, 0, 0),
	[Enum.NormalId.Left] = Vector3.new(-1, 0, 0),
	[Enum.NormalId.Top] = Vector3.new(0, 1, 0),
	[Enum.NormalId.Bottom] = Vector3.new(0, -1, 0),
}

---------------------------------------------------------------------------------------------------
-- Model lookup and preparation
---------------------------------------------------------------------------------------------------

local function childModel(parent: Instance?, name: string): Model?
	local child = parent and parent:FindFirstChild(name)
	if child ~= nil and child:IsA("Model") then
		return child
	end
	return nil
end

local function findTemplate(heroId: any): Model?
	if type(heroId) ~= "string" or heroId == "" then
		return nil
	end
	local model = childModel(ReplicatedStorage:FindFirstChild("AssetModels"), heroId)
	if model ~= nil then
		return model
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	return childModel(models and models:FindFirstChild("Heroes"), heroId)
end

function HeroPortrait.GetTemplate(heroId: string): Model?
	return findTemplate(heroId)
end

function HeroPortrait.HasModel(heroId: string): boolean
	return findTemplate(heroId) ~= nil
end

local function cloneModel(template: Model): Model?
	local archivable = template.Archivable
	if not archivable then
		template.Archivable = true
	end
	local ok, clone = pcall(function()
		return template:Clone()
	end)
	if not archivable then
		template.Archivable = false
	end
	if ok and clone ~= nil and clone:IsA("Model") then
		return clone
	end
	return nil
end

local function isStripped(inst: Instance): boolean
	for _, className in ipairs(STRIP_CLASSES) do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

local function prepareModel(model: Model)
	local doomed = {}
	for _, d in ipairs(model:GetDescendants()) do
		if isStripped(d) then
			table.insert(doomed, d)
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.CastShadow = false
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
	end
	for _, d in ipairs(doomed) do
		pcall(function()
			d:Destroy()
		end)
	end
end

---------------------------------------------------------------------------------------------------
-- Framing
---------------------------------------------------------------------------------------------------

-- cf's rotation applied to a local vector (engine independent: only Right / Up / Look vectors).
local function toWorldVector(cf: CFrame, v: Vector3): Vector3
	return cf.RightVector * v.X + cf.UpVector * v.Y - cf.LookVector * v.Z
end

local function horizontal(v: Vector3?): Vector3?
	if v == nil then
		return nil
	end
	local flat = Vector3.new(v.X, 0, v.Z)
	if flat.Magnitude < 0.2 then
		return nil
	end
	return flat.Unit
end

local function isVisiblePart(inst: Instance): boolean
	return inst:IsA("BasePart") and inst.Transparency < 0.95
end

-- The rendered size of a part: the classic head mesh is a rounded cube of the part's smallest side, scaled.
local function visualSize(part: BasePart): Vector3
	local size = part.Size
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	if mesh ~= nil then
		local meshType = mesh.MeshType
		if meshType == Enum.MeshType.Head then
			local side = math.min(size.X, size.Y, size.Z)
			return Vector3.new(side * mesh.Scale.X, side * mesh.Scale.Y, side * mesh.Scale.Z)
		elseif meshType == Enum.MeshType.Brick or meshType == Enum.MeshType.Sphere or meshType == Enum.MeshType.Cylinder
			or meshType == Enum.MeshType.Wedge then
			return Vector3.new(size.X * mesh.Scale.X, size.Y * mesh.Scale.Y, size.Z * mesh.Scale.Z)
		end
		-- FileMesh: its natural size is unknown here; the part size is the best estimate
	end
	return size
end

local function rootPart(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root ~= nil and root:IsA("BasePart") then
		return root
	end
	local primary = model.PrimaryPart
	if primary ~= nil then
		return primary
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

-- The rig's head: a BasePart named Head outside accessories, preferring the one with a Neck joint, a face decal or
-- a Humanoid / AnimationController next to it.
local function findHead(model: Model): BasePart?
	local fallback = nil
	for _, d in ipairs(model:GetDescendants()) do
		if d.Name == "Head" and d:IsA("BasePart") and d:FindFirstAncestorWhichIsA("Accoutrement") == nil then
			local parent = d.Parent
			if d:FindFirstChild("Neck") ~= nil or d:FindFirstChildOfClass("Decal") ~= nil
				or (parent ~= nil and (parent:FindFirstChildOfClass("Humanoid") ~= nil or parent:FindFirstChildOfClass("AnimationController") ~= nil)) then
				return d
			end
			fallback = fallback or d
		end
	end
	return fallback
end

-- Where the face looks (horizontal unit vector).
local function faceDirection(model: Model, head: BasePart?): Vector3
	if head ~= nil then
		local cf = head.CFrame
		for _, c in ipairs(head:GetChildren()) do
			if c:IsA("Decal") and string.lower(c.Name) == "face" then
				local normal = NORMALS[c.Face]
				local dir = normal and horizontal(toWorldVector(cf, normal))
				if dir ~= nil then
					return dir
				end
			end
		end
		local front = head:FindFirstChild("FaceFrontAttachment")
		if front ~= nil and front:IsA("Attachment") then
			local offset = front.CFrame.Position
			local dir = if offset.Magnitude > 0.05 then horizontal(toWorldVector(cf, offset)) else nil
			if dir ~= nil then
				return dir
			end
		end
	end
	local root = rootPart(model)
	local dir = root and horizontal(root.CFrame.LookVector)
	if dir ~= nil then
		return dir
	end
	dir = head and horizontal(head.CFrame.LookVector)
	return dir or Vector3.new(0, 0, -1)
end

-- The head plus what is worn on it: parts welded (not Motor6D) to the head, up to three welds away, and accessories
-- hooked to a head attachment; all within reach of the head centre.
local function faceParts(model: Model, head: BasePart, unit: number): { BasePart }
	local headPos = head.CFrame.Position
	local reach = unit * 2.6
	local parts = { head }
	local seen = { [head] = true }
	local function accept(part: Instance): boolean
		if seen[part] or not part:IsA("BasePart") or BODY_PARTS[part.Name] then
			return false
		end
		seen[part] = true
		if (part.CFrame.Position - headPos).Magnitude > reach then
			return false
		end
		table.insert(parts, part)
		return true
	end

	local links = {}
	for _, d in ipairs(model:GetDescendants()) do
		if (d:IsA("JointInstance") and not d:IsA("Motor6D")) or d:IsA("WeldConstraint") then
			local a, b = d.Part0, d.Part1
			if a ~= nil and b ~= nil then
				links[a] = links[a] or {}
				links[b] = links[b] or {}
				table.insert(links[a], b)
				table.insert(links[b], a)
			end
		end
	end
	local frontier = { head }
	for _ = 1, 3 do
		local nextFrontier = {}
		for _, part in ipairs(frontier) do
			for _, other in ipairs(links[part] or {}) do
				if accept(other) then
					table.insert(nextFrontier, other)
				end
			end
		end
		frontier = nextFrontier
	end

	for _, accessory in ipairs(model:GetDescendants()) do
		if accessory:IsA("Accoutrement") then
			local handle = accessory:FindFirstChild("Handle")
			if handle ~= nil and handle:IsA("BasePart") then
				for _, attachment in ipairs(handle:GetChildren()) do
					if attachment:IsA("Attachment") and HEAD_ATTACHMENTS[attachment.Name] then
						accept(handle)
						break
					end
				end
			end
		end
	end

	local visible = {}
	for _, part in ipairs(parts) do
		if part == head or isVisiblePart(part) then
			table.insert(visible, part)
		end
	end
	return visible
end

-- Extents of a part's (visual) box projected on the camera plane, relative to origin.
local function growExtents(ext, part: BasePart, origin: Vector3, right: Vector3, up: Vector3)
	local cf = part.CFrame
	local half = visualSize(part) * 0.5
	local center = cf.Position - origin
	local rx, ry, rz = cf.RightVector * half.X, cf.UpVector * half.Y, cf.LookVector * half.Z
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			for sz = -1, 1, 2 do
				local p = center + rx * sx + ry * sy + rz * sz
				local x, y = p:Dot(right), p:Dot(up)
				ext.minX = math.min(ext.minX, x)
				ext.maxX = math.max(ext.maxX, x)
				ext.minY = math.min(ext.minY, y)
				ext.maxY = math.max(ext.maxY, y)
			end
		end
	end
end

-- Camera CFrame, field of view and light direction for a prepared model (nil when nothing can be framed).
function HeroPortrait.ComputeCamera(model: Model, opts: { [string]: any }?): (CFrame?, number, Vector3?)
	opts = opts or {}
	local framing = FRAMINGS[opts.Framing or "Face"] or FRAMINGS.Face
	local fov = tonumber(opts.FieldOfView) or HeroPortrait.FIELD_OF_VIEW
	local yaw = math.rad(tonumber(opts.Yaw) or HeroPortrait.YAW)
	local pitch = math.rad(tonumber(opts.Pitch) or HeroPortrait.PITCH)

	local head = findHead(model)
	local origin, unit, parts
	if head ~= nil then
		origin = head.CFrame.Position
		unit = math.max(visualSize(head).Y, 0.3)
		parts = faceParts(model, head, unit)
	else
		-- no head: the top of the model (its visible parts' box), a "head" of ~1/6 of its height
		local minY, maxY = math.huge, -math.huge
		local sum, count = Vector3.new(0, 0, 0), 0
		for _, d in ipairs(model:GetDescendants()) do
			if isVisiblePart(d) then
				local p, half = d.CFrame.Position, d.Size.Y * 0.5
				minY = math.min(minY, p.Y - half)
				maxY = math.max(maxY, p.Y + half)
				sum += p
				count += 1
			end
		end
		if count == 0 then
			return nil, fov, nil
		end
		local mid = sum / count
		unit = math.max((maxY - minY) / 6, 0.3)
		origin = Vector3.new(mid.X, maxY - unit * 0.6, mid.Z)
		parts = {}
	end

	-- camera basis: the face side, turned by yaw around the vertical, raised by pitch
	local front = faceDirection(model, head)
	local c, s = math.cos(yaw), math.sin(yaw)
	local turned = Vector3.new(front.X * c + front.Z * s, 0, -front.X * s + front.Z * c)
	local back = (turned * math.cos(pitch) + UP * math.sin(pitch)).Unit -- from the face toward the camera
	local right = UP:Cross(back).Unit
	local camUp = back:Cross(right).Unit

	local ext = { minX = -0.5 * unit, maxX = 0.5 * unit, minY = -0.5 * unit, maxY = 0.5 * unit }
	for _, part in ipairs(parts) do
		growExtents(ext, part, origin, right, camUp)
	end
	local top = math.clamp(ext.maxY, 0.5 * unit, framing.top * unit)
	local bottom = -framing.bottom * unit
	local halfWidth = math.clamp(math.max(-ext.minX, ext.maxX), 0.5 * unit, framing.side * unit)
	local halfHeight = (top - bottom) * 0.5
	local extent = math.max(halfHeight, halfWidth) * framing.padding
	local distance = extent / math.tan(math.rad(fov) * 0.5)

	local target = origin + camUp * ((top + bottom) * 0.5)
	local position = target + back * distance
	local cframe = CFrame.fromMatrix(position, right, camUp, back)
	-- key light from the camera's upper left, travelling toward the face
	local light = -(back + camUp * 0.9 - right * 0.6).Unit
	return cframe, fov, light
end

---------------------------------------------------------------------------------------------------
-- Portraits
---------------------------------------------------------------------------------------------------

local function isPortrait(inst: Instance?): boolean
	return inst ~= nil and inst:IsA("ViewportFrame") and inst:GetAttribute("HeroPortrait") == true
end

function HeroPortrait.Get(parent: Instance?): ViewportFrame?
	if parent == nil then
		return nil
	end
	for _, child in ipairs(parent:GetChildren()) do
		if isPortrait(child) then
			return child :: ViewportFrame
		end
	end
	return nil
end

function HeroPortrait.Clear(parent: Instance?)
	if parent == nil then
		return
	end
	for _, child in ipairs(parent:GetChildren()) do
		if isPortrait(child) then
			child:Destroy()
		end
	end
end

local function applyLook(viewport: ViewportFrame, opts: { [string]: any })
	local silhouette = opts.Silhouette == true
	viewport.ImageColor3 = if silhouette then HeroPortrait.SILHOUETTE_COLOR else Color3.new(1, 1, 1)
	viewport.ImageTransparency = if silhouette then (tonumber(opts.SilhouetteTransparency) or HeroPortrait.SILHOUETTE_TRANSPARENCY) else 0
	viewport:SetAttribute("Silhouette", silhouette)
end

function HeroPortrait.SetSilhouette(target: Instance, on: boolean, transparency: number?)
	local viewport = if isPortrait(target) then target else HeroPortrait.Get(target)
	if viewport ~= nil then
		applyLook(viewport :: ViewportFrame, { Silhouette = on, SilhouetteTransparency = transparency })
	end
end

local function build(parent: Instance, template: Model, heroId: string, framingName: string, opts: { [string]: any }): ViewportFrame
	local model = cloneModel(template)
	assert(model ~= nil, "model could not be cloned")
	prepareModel(model)
	local cframe, fov, light = HeroPortrait.ComputeCamera(model, opts)
	if cframe == nil then
		model:Destroy()
		error("nothing visible to frame")
	end

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = HeroPortrait.PORTRAIT_NAME
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Active = false
	viewport.Selectable = false
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.Size = UDim2.fromScale(1, 1)
	if tonumber(opts.ZIndex) ~= nil then
		viewport.ZIndex = opts.ZIndex
	elseif parent:IsA("GuiObject") then
		viewport.ZIndex = parent.ZIndex + 1
	end
	viewport.Ambient = HeroPortrait.AMBIENT
	viewport.LightColor = HeroPortrait.LIGHT_COLOR
	viewport.LightDirection = light
	viewport:SetAttribute("HeroPortrait", true)
	viewport:SetAttribute("HeroId", heroId)
	viewport:SetAttribute("Framing", framingName)
	if opts.Square ~= false then
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.Parent = viewport
	end

	local camera = Instance.new("Camera")
	camera.Name = "PortraitCamera"
	camera.FieldOfView = fov
	camera.CFrame = cframe
	camera.Parent = viewport
	-- (pcall only for offline tooling, which cannot write ViewportFrame.CurrentCamera; the engine never fails here)
	pcall(function()
		viewport.CurrentCamera = camera
	end)
	model.Parent = viewport
	applyLook(viewport, opts)
	viewport.Parent = parent
	return viewport
end

function HeroPortrait.Mount(parent: Instance, heroId: string, opts: { [string]: any }?): ViewportFrame?
	opts = opts or {}
	if typeof(parent) ~= "Instance" or type(heroId) ~= "string" then
		return nil
	end
	local framingName = if FRAMINGS[opts.Framing] ~= nil then opts.Framing else "Face"
	local existing = HeroPortrait.Get(parent)
	if existing ~= nil and existing:GetAttribute("HeroId") == heroId and existing:GetAttribute("Framing") == framingName then
		applyLook(existing, opts)
		return existing
	end
	HeroPortrait.Clear(parent)
	local template = findTemplate(heroId)
	if template == nil then
		return nil
	end
	local ok, result = pcall(build, parent, template, heroId, framingName, opts)
	if not ok then
		warn(`[HeroPortrait] { heroId }: { result }`)
		return nil
	end
	return result
end

---------------------------------------------------------------------------------------------------
-- Lazy loader: mounts portraits once their holder is laid out and scrolled into view, a few per frame
---------------------------------------------------------------------------------------------------

local Lazy = {}
Lazy.__index = Lazy

local function isShown(gui: Instance): boolean
	local node: Instance? = gui
	while node ~= nil and node:IsA("GuiObject") do
		if not node.Visible then
			return false
		end
		node = node.Parent
	end
	if node ~= nil and node:IsA("LayerCollector") then
		return node.Enabled
	end
	return node ~= nil
end

function HeroPortrait.Lazy(scroller: GuiObject?, options: { [string]: any }?)
	options = options or {}
	local self = setmetatable({
		_scroller = scroller,
		_perStep = math.max(1, tonumber(options.PerStep) or 4),
		_margin = tonumber(options.Margin) or 0.5,
		_pending = {},
		_connections = {},
		_scheduled = false,
		_alive = true,
	}, Lazy)
	if scroller ~= nil then
		for _, property in ipairs({ "AbsoluteSize", "AbsolutePosition", "CanvasPosition" }) do
			local ok, signal = pcall(function()
				return scroller:GetPropertyChangedSignal(property)
			end)
			if ok and signal ~= nil then
				table.insert(self._connections, signal:Connect(function()
					self:_schedule()
				end))
			end
		end
	end
	return self
end

function Lazy:_drop(parent: Instance)
	local request = self._pending[parent]
	if request == nil then
		return
	end
	self._pending[parent] = nil
	for _, connection in ipairs(request.connections) do
		connection:Disconnect()
	end
end

function Lazy:_inView(parent: GuiObject): boolean
	local size = parent.AbsoluteSize
	if size.X < 2 or size.Y < 2 or not isShown(parent) then
		return false
	end
	local scroller = self._scroller
	if scroller == nil then
		return true
	end
	local position = parent.AbsolutePosition
	local viewPosition, viewSize = scroller.AbsolutePosition, scroller.AbsoluteSize
	local marginY, marginX = viewSize.Y * self._margin, viewSize.X * self._margin
	return position.Y + size.Y >= viewPosition.Y - marginY and position.Y <= viewPosition.Y + viewSize.Y + marginY
		and position.X + size.X >= viewPosition.X - marginX and position.X <= viewPosition.X + viewSize.X + marginX
end

function Lazy:_schedule()
	if self._scheduled or not self._alive then
		return
	end
	self._scheduled = true
	task.defer(function()
		self:_step()
	end)
end

function Lazy:_step()
	self._scheduled = false
	if not self._alive then
		return
	end
	local ready = {}
	local more = false
	for parent, request in pairs(self._pending) do
		if parent.Parent == nil then
			table.insert(ready, { parent = parent, request = nil })
		elseif self:_inView(parent) then
			if #ready < self._perStep then
				table.insert(ready, { parent = parent, request = request })
			else
				more = true
			end
		end
	end
	for _, item in ipairs(ready) do
		self:_drop(item.parent)
		local request = item.request
		if request ~= nil then
			local viewport = HeroPortrait.Mount(item.parent, request.heroId, request.opts)
			if viewport == nil and type(request.opts.OnFailed) == "function" then
				task.spawn(request.opts.OnFailed)
			end
		end
	end
	if more and self._alive and not self._scheduled then
		-- the next few on the next frame
		self._scheduled = true
		task.delay(0, function()
			self:_step()
		end)
	end
end

function Lazy:Request(parent: GuiObject, heroId: string, opts: { [string]: any }?): ViewportFrame?
	opts = opts or {}
	if not self._alive then
		return nil
	end
	local existing = HeroPortrait.Get(parent)
	if existing ~= nil and existing:GetAttribute("HeroId") == heroId then
		-- already showing this hero: only the look (silhouette) changes
		self:_drop(parent)
		return HeroPortrait.Mount(parent, heroId, opts)
	end
	HeroPortrait.Clear(parent)
	self:_drop(parent)
	local request = { heroId = heroId, opts = opts, connections = {} }
	self._pending[parent] = request
	local function wake()
		self:_schedule()
	end
	for _, property in ipairs({ "AbsolutePosition", "AbsoluteSize" }) do
		table.insert(request.connections, parent:GetPropertyChangedSignal(property):Connect(wake))
	end
	table.insert(request.connections, parent.Destroying:Connect(function()
		self:_drop(parent)
	end))
	self:_schedule()
	return nil
end

function Lazy:Cancel(parent: Instance)
	self:_drop(parent)
end

function Lazy:Destroy()
	if not self._alive then
		return
	end
	self._alive = false
	local parents = {}
	for parent in pairs(self._pending) do
		table.insert(parents, parent)
	end
	for _, parent in ipairs(parents) do
		self:_drop(parent)
	end
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return HeroPortrait
