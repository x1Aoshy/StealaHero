--!nonstrict
-- ReplicatedStorage.Library.Client.WeaponPortrait (ModuleScript, injected by scripts/inject/hero_weapons.luau)
-- Owner 2026-09-27 (hero weapons replace the bats): the melee gear's icons (hotbar slot, the Index stage card's
-- reward) still pointed at the old bat images, and no new image can be uploaded. An icon of a hero weapon tool gets a
-- ViewportFrame of the weapon's own parts instead (ReplicatedStorage.GearTools.ShopItems.<tool>, built by
-- scripts/steps/post_hero_weapons.luau), framed from the front, tilted like an item icon; the image underneath is
-- hidden while it shows.
--   WeaponPortrait.Mount(imageLabel, toolOrName) -> ViewportFrame? (nil when it is not a hero weapon)
--   WeaponPortrait.Clear(imageLabel)
-- A portrait of the same tool is reused (a refresh never re-clones). The image's transparency is saved in the
-- EggPortraitImageTransparency attribute, the one the hotbar's egg / hero portraits already use and restore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponPortrait = {}

WeaponPortrait.NAME = "WeaponPortrait"
WeaponPortrait.SAVED_ATTRIBUTE = "EggPortraitImageTransparency"
WeaponPortrait.VIEW_DIRECTION = Vector3.new(0.55, 0.35, -1).Unit -- grip space: -Z is the weapon's front
WeaponPortrait.TILT = CFrame.Angles(0, 0, math.rad(-32))
WeaponPortrait.FIELD_OF_VIEW = 28

local function templateOf(toolOrName)
	local name = if typeof(toolOrName) == "Instance" then toolOrName.Name else toolOrName
	if type(name) ~= "string" then
		return nil
	end
	local gearTools = ReplicatedStorage:FindFirstChild("GearTools")
	local shopItems = gearTools and gearTools:FindFirstChild("ShopItems")
	local template = shopItems and shopItems:FindFirstChild(name)
	if template and template:IsA("Tool") and template:GetAttribute("HeroWeaponId") ~= nil then
		return template
	end
	return nil
end

function WeaponPortrait.IsWeapon(toolOrName): boolean
	return templateOf(toolOrName) ~= nil
end

function WeaponPortrait.Clear(icon)
	local existing = icon and icon:FindFirstChild(WeaponPortrait.NAME)
	if existing then
		existing:Destroy()
	end
end

function WeaponPortrait.Mount(icon, toolOrName)
	if not (icon and icon:IsA("GuiObject")) then
		return nil
	end
	local template = templateOf(toolOrName)
	local existing = icon:FindFirstChild(WeaponPortrait.NAME)
	if not template then
		if existing then
			existing:Destroy()
		end
		return nil
	end
	if existing and existing:GetAttribute("Tool") == template.Name then
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = WeaponPortrait.NAME
	viewport:SetAttribute("Tool", template.Name)
	viewport.BackgroundTransparency = 1
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.ZIndex = icon.ZIndex
	viewport.Ambient = Color3.fromRGB(170, 170, 180)
	viewport.LightColor = Color3.fromRGB(255, 250, 240)
	viewport.LightDirection = Vector3.new(-0.4, -1, 0.6)

	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local model = Instance.new("Model")
	for _, part in ipairs(template:GetChildren()) do
		if part:IsA("BasePart") then
			local copy = part:Clone()
			for _, child in ipairs(copy:GetChildren()) do
				child:Destroy()
			end
			copy.Anchored = true
			copy.Parent = model
		end
	end
	model.Parent = world
	local centre, size = model:GetBoundingBox()
	model:PivotTo(CFrame.new(centre.Position) * WeaponPortrait.TILT * CFrame.new(-centre.Position) * model:GetPivot())
	centre, size = model:GetBoundingBox()

	local camera = Instance.new("Camera")
	camera.FieldOfView = WeaponPortrait.FIELD_OF_VIEW
	local radius = math.max(size.Magnitude / 2, 0.5)
	local distance = radius / math.tan(math.rad(WeaponPortrait.FIELD_OF_VIEW / 2)) * 1.02
	local eye = centre.Position + WeaponPortrait.VIEW_DIRECTION * distance
	camera.CFrame = CFrame.lookAt(eye, centre.Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	if icon:IsA("ImageLabel") or icon:IsA("ImageButton") then
		if icon:GetAttribute(WeaponPortrait.SAVED_ATTRIBUTE) == nil then
			icon:SetAttribute(WeaponPortrait.SAVED_ATTRIBUTE, icon.ImageTransparency)
		end
		icon.ImageTransparency = 1
	end
	viewport.Parent = icon
	return viewport
end

return WeaponPortrait
