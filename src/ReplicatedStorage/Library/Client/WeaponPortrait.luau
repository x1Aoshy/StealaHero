--!nonstrict
-- ReplicatedStorage.Library.Client.WeaponPortrait (ModuleScript, injected by scripts/inject/hero_weapons.luau)
-- Owner 2026-09-27 (hero weapons replace the bats): the melee gear's icons (hotbar slot, the Index stage card's
-- reward) still pointed at the old bat images, and no new image can be uploaded. An icon of a hero weapon tool gets a
-- ViewportFrame of the weapon's own parts instead (ReplicatedStorage.GearTools.ShopItems.<tool>, built by
-- scripts/steps/post_hero_weapons.luau), framed from the front, tilted like an item icon; the image underneath is
-- hidden while it shows.
--   WeaponPortrait.Mount(imageLabel, toolOrName) -> ViewportFrame? (nil when it is not a hero weapon)
--   WeaponPortrait.MountBadge(host, toolOrName, { Position, Height }) -> Frame? a square studded tile holding the
--     portrait, sized Height x the host's height (owner 2026-09-27, round 9: "the Index viewports are badly placed" -
--     they sat inside the old bat image, a thin box turned -61 degrees hanging off the button)
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
WeaponPortrait.MARGIN = 1.1 -- the weapon fills the frame up to this margin (fitted on its bounding box corners)
WeaponPortrait.BADGE_NAME = "WeaponBadge"
WeaponPortrait.STUD_IMAGE = "rbxassetid://6927295847" -- the game's stud texture (every UI carries it)

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
	-- fit the camera on the bounding box's corners (a bounding sphere left long weapons tiny in the frame)
	local look = CFrame.lookAt(centre.Position + WeaponPortrait.VIEW_DIRECTION, centre.Position)
	local tangent = math.tan(math.rad(WeaponPortrait.FIELD_OF_VIEW / 2))
	local distance = 0.5
	for _, sx in ipairs({ -0.5, 0.5 }) do
		for _, sy in ipairs({ -0.5, 0.5 }) do
			for _, sz in ipairs({ -0.5, 0.5 }) do
				local corner = centre:PointToWorldSpace(Vector3.new(size.X * sx, size.Y * sy, size.Z * sz))
				-- camera space: x right, y up, -z forward; a corner toward the camera (z > 0) needs more distance
				local offset = look:VectorToObjectSpace(corner - centre.Position)
				local need = math.max(math.abs(offset.X), math.abs(offset.Y)) * WeaponPortrait.MARGIN / tangent + offset.Z
				distance = math.max(distance, need)
			end
		end
	end
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

-- A square studded tile (the game's blocky style: square corners, a glossy navy face, the stud texture, a dark rim)
-- centred at options.Position in `host`, options.Height x the host's height, holding the weapon's portrait. Reused on
-- every refresh; removed when the gear is not a hero weapon.
function WeaponPortrait.MountBadge(host, toolOrName, options)
	if not (host and host:IsA("GuiObject")) then
		return nil
	end
	options = options or {}
	local badge = host:FindFirstChild(WeaponPortrait.BADGE_NAME)
	if not templateOf(toolOrName) then
		if badge then
			badge:Destroy()
		end
		return nil
	end
	if not badge then
		badge = Instance.new("Frame")
		badge.Name = WeaponPortrait.BADGE_NAME
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		badge.BorderSizePixel = 0
		badge.ZIndex = host.ZIndex + 4
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = badge
		local face = Instance.new("UIGradient")
		face.Rotation = 90
		face.Color = ColorSequence.new(Color3.fromRGB(70, 98, 170), Color3.fromRGB(26, 34, 70))
		face.Parent = badge
		local rim = Instance.new("UIStroke")
		rim.Thickness = 2.5
		rim.Color = Color3.fromRGB(12, 16, 34)
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Parent = badge
		local studs = Instance.new("ImageLabel")
		studs.Name = "Studs"
		studs.BackgroundTransparency = 1
		studs.Size = UDim2.fromScale(1, 1)
		studs.Image = WeaponPortrait.STUD_IMAGE
		studs.ImageTransparency = 0.62
		studs.ScaleType = Enum.ScaleType.Tile
		studs.TileSize = UDim2.fromOffset(18, 18)
		studs.ZIndex = badge.ZIndex
		studs.Parent = badge
		local gloss = Instance.new("Frame")
		gloss.Name = "Gloss"
		gloss.BackgroundColor3 = Color3.new(1, 1, 1)
		gloss.BackgroundTransparency = 0.82
		gloss.BorderSizePixel = 0
		gloss.Size = UDim2.fromScale(1, 0.45)
		gloss.ZIndex = badge.ZIndex
		gloss.Parent = badge
		local holder = Instance.new("Frame")
		holder.Name = "Portrait"
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(0.9, 0.9)
		holder.ZIndex = badge.ZIndex + 1
		holder.Parent = badge
		badge.Parent = host
	end
	badge.Position = options.Position or UDim2.fromScale(0.5, 0.5)
	badge.Size = UDim2.fromScale(1, options.Height or 1.2)
	WeaponPortrait.Mount(badge:FindFirstChild("Portrait"), toolOrName)
	return badge
end

return WeaponPortrait
