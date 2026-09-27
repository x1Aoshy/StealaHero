-- ReplicatedStorage.Library.Client.EggPortrait (ModuleScript; injected by scripts/inject/portraits.luau)
-- Owner 2026-09-27: "when you hold the egg in your hand or see it in a list it must show a view of the egg itself, not
-- a common image". No image can be uploaded, so an egg icon is a ViewportFrame showing a private clone of the hero's
-- own voxel egg (ReplicatedStorage.Assets.Models.Eggs.<HeroId>, else Assets.Models.BossEggs.<HeroId>), framed whole
-- with a slight 3/4 turn. Like HeroPortrait: scripts, sounds, particles, lights and GUIs are stripped, every part is
-- anchored, nothing runs per frame; everything the portrait owns lives under its ViewportFrame.
--
-- API
--   EggPortrait.HasModel(heroId) -> boolean
--   EggPortrait.Mount(parent, heroId, opts?) -> ViewportFrame?   (nil when the egg has no model)
--       Re-mounting the egg a parent already shows does nothing; another egg replaces it.
--       opts: Yaw / Pitch (degrees), FieldOfView (degrees), Padding (number, default 1.08), ZIndex (number)
--   EggPortrait.Get(parent) -> ViewportFrame?
--   EggPortrait.Clear(parent)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggPortrait = {}

EggPortrait.PORTRAIT_NAME = "EggPortrait"
EggPortrait.FIELD_OF_VIEW = 24
EggPortrait.YAW = 24
EggPortrait.PITCH = 12
EggPortrait.PADDING = 1.08
EggPortrait.AMBIENT = Color3.fromRGB(190, 190, 200)
EggPortrait.LIGHT_COLOR = Color3.fromRGB(230, 225, 215)

local STRIP_CLASSES = {
	"LuaSourceContainer", "Sound", "ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Light",
	"BillboardGui", "SurfaceGui", "ProximityPrompt", "ClickDetector", "Highlight", "Attachment",
}

local function findTemplate(heroId: any): Model?
	if type(heroId) ~= "string" or heroId == "" then
		return nil
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	for _, folderName in ipairs({ "Eggs", "BossEggs" }) do
		local folder = models and models:FindFirstChild(folderName)
		local model = folder and folder:FindFirstChild(heroId)
		if model and model:IsA("Model") then
			return model
		end
	end
	return nil
end

function EggPortrait.HasModel(heroId: string): boolean
	return findTemplate(heroId) ~= nil
end

function EggPortrait.Get(parent: Instance?): ViewportFrame?
	if parent == nil then
		return nil
	end
	local found = parent:FindFirstChild(EggPortrait.PORTRAIT_NAME)
	return if found and found:IsA("ViewportFrame") then found else nil
end

function EggPortrait.Clear(parent: Instance?)
	local existing = EggPortrait.Get(parent)
	if existing then
		existing:Destroy()
	end
end

local function isStripped(inst: Instance): boolean
	for _, className in ipairs(STRIP_CLASSES) do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

-- The visible bounds of the clone (the invisible Hitbox and any fully transparent part are ignored).
local function visibleBounds(model: Model): (Vector3?, Vector3?)
	local minV, maxV
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local cf, half = part.CFrame, part.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local p = cf:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
						minV = if minV then minV:Min(p) else p
						maxV = if maxV then maxV:Max(p) else p
					end
				end
			end
		end
	end
	return minV, maxV
end

function EggPortrait.Mount(parent: Instance, heroId: string, opts: { [string]: any }?): ViewportFrame?
	opts = opts or {}
	local existing = EggPortrait.Get(parent)
	if existing and existing:GetAttribute("HeroId") == heroId then
		return existing
	end
	local template = findTemplate(heroId)
	if template == nil then
		EggPortrait.Clear(parent)
		return nil
	end
	local ok, model = pcall(function()
		return template:Clone()
	end)
	if not ok or model == nil then
		return nil
	end
	for _, d in ipairs(model:GetDescendants()) do
		if isStripped(d) then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local minV, maxV = visibleBounds(model)
	if minV == nil then
		model:Destroy()
		return nil
	end
	EggPortrait.Clear(parent)

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = EggPortrait.PORTRAIT_NAME
	viewport:SetAttribute("HeroId", heroId)
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.SizeConstraint = Enum.SizeConstraint.RelativeYY
	viewport.Ambient = EggPortrait.AMBIENT
	viewport.LightColor = EggPortrait.LIGHT_COLOR
	viewport.LightDirection = Vector3.new(-1, -1.4, -0.6)
	if type(opts.ZIndex) == "number" then
		viewport.ZIndex = opts.ZIndex
	elseif parent:IsA("GuiObject") then
		viewport.ZIndex = parent.ZIndex + 1
	end
	model.Parent = viewport

	-- camera on the egg's centre, from its front (-Z) turned YAW and raised PITCH, far enough for the whole egg
	local centre = (minV + maxV) / 2
	local radius = (maxV - minV).Magnitude / 2
	local fov = tonumber(opts.FieldOfView) or EggPortrait.FIELD_OF_VIEW
	local distance = radius * (tonumber(opts.Padding) or EggPortrait.PADDING) / math.sin(math.rad(fov / 2))
	local yaw = math.rad(tonumber(opts.Yaw) or EggPortrait.YAW)
	local pitch = math.rad(tonumber(opts.Pitch) or EggPortrait.PITCH)
	local direction = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch))
	local camera = Instance.new("Camera")
	camera.FieldOfView = fov
	camera.CFrame = CFrame.lookAt(centre + direction * distance, centre)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.Parent = parent
	return viewport
end

return EggPortrait
