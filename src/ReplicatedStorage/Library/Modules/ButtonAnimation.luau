-- ReplicatedStorage.Library.Modules.ButtonAnimation
-- Small hover-grow helper for GuiButtons. Never existed in the rip; TrollOpenClient required
-- it via a wrong path ("ReplicatedStorage.Modules", which also never existed) and hung
-- forever. Minimal but real: scales the button up slightly on hover/press.

local TweenService = game:GetService("TweenService")

local ButtonAnimation = {}

local HOVER_SCALE = 1.08
local TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function ButtonAnimation.CreateButton(button)
	if button:GetAttribute("_ButtonAnimationBound") then
		return
	end
	button:SetAttribute("_ButtonAnimationBound", true)

	local baseSize = button.Size
	local hoverSize = UDim2.new(
		baseSize.X.Scale * HOVER_SCALE, baseSize.X.Offset * HOVER_SCALE,
		baseSize.Y.Scale * HOVER_SCALE, baseSize.Y.Offset * HOVER_SCALE
	)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TWEEN_INFO, { Size = hoverSize }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TWEEN_INFO, { Size = baseSize }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TWEEN_INFO, { Size = baseSize }):Play()
	end)
end

return ButtonAnimation
