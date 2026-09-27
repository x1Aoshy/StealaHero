-- StarterPlayer.StarterPlayerScripts.GUI.Index.AreaIndexProgressComponent (ModuleScript, injected by
-- scripts/inject/gekko_indexbats.luau; was the base place's decompiled source, checked equal before patching).
--
-- One stage card's reward row in the Index: the progress bar while the stage is incomplete, then the stage bat's
-- EQUIP button (owner batch item 2, "Equip button in index for bats not working"). The base version turned the
-- button into a dead "Equipped" label as soon as the bat was owned and its only action was a request StubService
-- refused. Now (server: ServerScriptService.GearService answers Network["Index: RequestEquipAreaBat"]):
--   * stage complete, bat not equipped  -> "EQUIP" (the card's green), onAction(sectionId, "Equip")
--   * bat equipped (profile EquippedBat) -> "EQUIPPED" in gold; hovering it with a mouse arms it as a red "UNEQUIP"
--     until the mouse leaves, a first press / tap arms it for ARM_SECONDS, and a click / tap while armed calls
--     onAction(sectionId, "Unequip"). Hover is read from InputBegan / InputEnded MouseMovement only: on phones a tap
--     also fires MouseEnter right before Activated, which would arm and unequip in a single tap (review fix).
--   * the "!" badge shows until the bat was equipped once (profile VisitedGears)
-- The Limited Egg row (RenderGearClaim) keeps its CLAIM! / CLAIMED! behaviour: onAction(sectionId).
-- The tint is EquipBat.TextButton.BackgroundColor3 (the kit's "tint" skin lets it read through, ui_20_windows);
-- its light rim gradient (SpSkin.SpStrokeLight.UIGradient) follows the state when present.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Gears = require(ReplicatedStorage.Directory.Gears)
local Trove = require(ReplicatedStorage.Library.Modules.Packages.Trove)
local WeaponPortrait = nil
do
	local module = ReplicatedStorage.Library.Client:FindFirstChild("WeaponPortrait")
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		WeaponPortrait = if ok and type(result) == "table" then result else nil
	end
end

require(script.Types.Interface)

local AreaIndexProgressComponent = {}

AreaIndexProgressComponent.__index = AreaIndexProgressComponent
AreaIndexProgressComponent.__class = "AreaIndexProgressComponent"

local CLAIMED_COLOR = Color3.fromRGB(0, 182, 24)
local EQUIPPED_COLOR = Color3.fromRGB(255, 186, 28)
local UNEQUIP_COLOR = Color3.fromRGB(232, 58, 58)
local ARM_SECONDS = 3
local PROGRESS_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local RIM_GRADIENTS = {
	Equipped = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 246, 168)),
		ColorSequenceKeypoint.new(0.76, Color3.fromRGB(255, 196, 24)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 74, 0)),
	}),
	Unequip = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 176, 176)),
		ColorSequenceKeypoint.new(0.76, Color3.fromRGB(255, 59, 59)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 10, 10)),
	}),
}

local function rimGradientOf(button: Instance): UIGradient?
	local skin = button:FindFirstChild("SpSkin")
	local rim = skin and skin:FindFirstChild("SpStrokeLight")
	local gradient = rim and rim:FindFirstChildOfClass("UIGradient")
	return gradient
end

function AreaIndexProgressComponent.new(view, onAction: (...any) -> ...any)
	local self = setmetatable({}, AreaIndexProgressComponent)

	self._view = view
	self._onAction = onAction
	self._sectionId = nil
	self._actionEnabled = false
	self._kind = nil -- "AreaBat" | "GearClaim"
	self._equipped = false
	self._armed = false
	self._armToken = 0
	self._hovered = false -- a mouse pointer is over the button (never set by touch)
	self._equipButton = view.EquipBat.TextButton
	self._equipLabel = view.EquipBat.TextLabelFrame.TextLabel
	self._defaultEquipBatButtonColor = self._equipButton.BackgroundColor3
	self._defaultEquipBatButtonText = self._equipLabel.Text
	self._rimGradient = rimGradientOf(self._equipButton)
	self._defaultRimColor = if self._rimGradient then self._rimGradient.Color else nil
	self._progressTween = nil
	self._trove = Trove.new()
	self:_init()

	return self
end

function AreaIndexProgressComponent._setProgress(self, alpha: number)
	local progressTween = self._progressTween

	if progressTween then
		progressTween:Cancel()
		progressTween:Destroy()
	end

	local tween = TweenService:Create(self._view.ProgressBar.Progress.Fill, PROGRESS_TWEEN, {
		Size = UDim2.fromScale(alpha, 1),
	})

	self._progressTween = tween
	tween:Play()
end

-- Paints the EQUIP button: text, tint and rim for "Equip" | "Equipped" | "Unequip" | "Claim" | "Claimed".
function AreaIndexProgressComponent._paintButton(self, look: string, text: string)
	local color = self._defaultEquipBatButtonColor
	local rim = self._defaultRimColor

	if look == "Equipped" then
		color = EQUIPPED_COLOR
		rim = RIM_GRADIENTS.Equipped
	elseif look == "Unequip" then
		color = UNEQUIP_COLOR
		rim = RIM_GRADIENTS.Unequip
	elseif look == "Claimed" then
		color = CLAIMED_COLOR
	end

	self._equipButton.BackgroundColor3 = color
	self._equipLabel.Text = text

	if self._rimGradient and rim then
		self._rimGradient.Color = rim
	end
end

function AreaIndexProgressComponent._repaintAreaBat(self)
	if self._kind ~= "AreaBat" then
		return
	end

	if not self._equipped then
		self:_paintButton("Equip", self._defaultEquipBatButtonText)
	elseif self._armed then
		self:_paintButton("Unequip", "UNEQUIP")
	else
		self:_paintButton("Equipped", "EQUIPPED")
	end
end

function AreaIndexProgressComponent._setArmed(self, armed: boolean)
	armed = armed and self._kind == "AreaBat" and self._equipped

	self._armToken += 1

	if self._armed == armed then
		if armed then
			self:_scheduleDisarm()
		end
		return
	end

	self._armed = armed
	self:_repaintAreaBat()

	if armed then
		self:_scheduleDisarm()
	end
end

function AreaIndexProgressComponent._scheduleDisarm(self)
	local token = self._armToken

	task.delay(ARM_SECONDS, function()
		-- still under the mouse: stays armed until the pointer leaves (InputEnded disarms)
		if self._armToken == token and self._armed and not self._hovered then
			self._armed = false
			self:_repaintAreaBat()
		end
	end)
end

function AreaIndexProgressComponent._render(self, sectionId: string, gearId: string, discovered: number, total: number, badge: boolean, actionEnabled: boolean)
	self._sectionId = sectionId
	self._actionEnabled = actionEnabled

	local view = self._view
	local config = Gears.Directory[gearId]
	local complete = total > 0 and total <= discovered
	local alpha = if total ~= 0 then math.clamp(discovered / total, 0, 1) else 0

	view.ProgressBar.ProgressText.TextLabel.Text = `{discovered}/{total}`
	view.ProgressBar.BatImage.Image = config.Icon
	view.EquipBat.BatImage.Image = config.Icon
	-- hero weapons (owner 2026-09-27) show the weapon itself instead of the old bat image: a square studded badge
	-- inside the EQUIP button's left end and one capping the progress bar (round 9: the portraits used to sit in the
	-- old bat image, a thin box turned -61 degrees that hung off the button over the hero cards)
	if WeaponPortrait and type(WeaponPortrait.MountBadge) == "function" then
		local okEquip, equipBadge = pcall(WeaponPortrait.MountBadge, view.EquipBat, gearId,
			{ Position = UDim2.fromScale(0.11, 0.5), Height = 1.3 })
		local okBar, barBadge = pcall(WeaponPortrait.MountBadge, view.ProgressBar, gearId,
			{ Position = UDim2.fromScale(1, 0.5), Height = 2.1 })
		local onButton = okEquip and equipBadge ~= nil
		view.EquipBat.BatImage.Visible = not onButton
		view.ProgressBar.BatImage.Visible = not (okBar and barBadge ~= nil)
		view.EquipBat.TextLabelFrame.Position = if onButton then UDim2.fromScale(0.6, 0.5) else UDim2.fromScale(0.53, 0.5)
		view.EquipBat.TextLabelFrame.Size = if onButton then UDim2.fromScale(0.62, 0.6) else UDim2.fromScale(0.7, 0.6)
	end
	view.ProgressBar.Visible = not complete
	view.EquipBat.Visible = complete
	view.EquipBat.NotificationBadge.Visible = complete and badge

	self:_setProgress(alpha)
end

-- sectionId, gearId, discovered, total, visited (the bat was equipped once), owned (kept for the old signature),
-- equipped (profile EquippedBat == gearId).
function AreaIndexProgressComponent.RenderAreaBat(self, sectionId: string, gearId: string, discovered: number, total: number, visited: boolean, owned: boolean, equipped: boolean?)
	Asserts.string(sectionId)
	Asserts.string(gearId)
	Asserts.number(discovered)
	Asserts.number(total)
	Asserts.boolean(visited)
	Asserts.boolean(owned)

	local isEquipped = equipped == true

	if self._kind ~= "AreaBat" or self._sectionId ~= sectionId or self._equipped ~= isEquipped then
		self._armToken += 1
		self._armed = false
	end

	self._kind = "AreaBat"
	self._equipped = isEquipped
	self:_render(sectionId, gearId, discovered, total, not visited, true)
	self:_repaintAreaBat()
end

function AreaIndexProgressComponent.RenderGearClaim(self, sectionId: string, gearId: string, discovered: number, total: number, claimed: boolean)
	Asserts.string(sectionId)
	Asserts.string(gearId)
	Asserts.number(discovered)
	Asserts.number(total)
	Asserts.boolean(claimed)

	self._kind = "GearClaim"
	self._equipped = false
	self._armed = false
	self._armToken += 1
	self:_render(sectionId, gearId, discovered, total, not claimed, not claimed)
	self:_paintButton(if claimed then "Claimed" else "Claim", if claimed then "CLAIMED!" else "CLAIM!")
end

function AreaIndexProgressComponent.Destroy(self)
	local progressTween = self._progressTween

	if progressTween then
		progressTween:Cancel()
		progressTween:Destroy()
		self._progressTween = nil
	end

	self._armToken += 1
	self._trove:Destroy()
end

function AreaIndexProgressComponent._onPressed(self)
	local sectionId = self._sectionId

	if sectionId == nil or not self._actionEnabled then
		return
	end

	if self._kind == "GearClaim" then
		self._onAction(sectionId)
		return
	end

	if not self._equipped then
		self._onAction(sectionId, "Equip")
		return
	end

	-- equipped: the first press only arms UNEQUIP (touch); hovering already armed it on desktop
	if self._armed then
		self._armToken += 1
		self._armed = false
		self._onAction(sectionId, "Unequip")
		return
	end

	self:_setArmed(true)
end

function AreaIndexProgressComponent._init(self)
	local button = self._view.EquipBat

	self._trove:Add(ButtonFX(button, nil, function()
		self:_onPressed()
	end))
	-- Mouse hover only. MouseEnter / MouseLeave also fire for a touch (MouseEnter just before Activated, often no
	-- MouseLeave after it), so they would turn a phone's first tap on EQUIPPED into an instant UNEQUIP.
	self._trove:Connect(button.InputBegan, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			self._hovered = true
			self:_setArmed(true)
		end
	end)
	self._trove:Connect(button.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			self._hovered = false
			self:_setArmed(false)
		end
	end)
end

return AreaIndexProgressComponent
