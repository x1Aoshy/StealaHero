

local v1 = game:GetService("ReplicatedStorage")
game:GetService("Lighting")
local v2 = v1:WaitForChild("Modules")
local u3 = require(v2:WaitForChild("TweenFOV"))
local u4 = require(v2:WaitForChild("TweenUIStrokes"))
local u5 = require(v2:WaitForChild("Notification"))
local v6 = v1:WaitForChild("RemoteGUI"):WaitForChild("UNotifyEvent")
local _ = game.Players.LocalPlayer
local u7 = game.SoundService.Game.SFX
local u8 = game:GetService("TweenService")
local u9 = {}
local u10 = {
	["buttonInfo"] = {
		["offset"] = 0.15,
		["info"] = TweenInfo.new(0.1, Enum.EasingStyle.Sine)
	},
	["frameInfo"] = {
		["blur"] = 15,
		["fov"] = 60,
		["baseFOV"] = 70,
		["DesiredScale"] = 1,
		["info"] = TweenInfo.new(0.25, Enum.EasingStyle.Back),
		["dof_blur"] = {
			["FarIntensity"] = 1,
			["FocusDistance"] = 1,
			["InFocusRadius"] = 2,
			["NearIntensity"] = 1
		},
		["dof_blurOut"] = {
			["FarIntensity"] = 0.095,
			["FocusDistance"] = 0,
			["InFocusRadius"] = 100,
			["NearIntensity"] = 0.75
		},
		["DesiredPos"] = UDim2.new(0.5, 0, 0.5, 0)
	}
}
local u11 = nil
function u9.CreateButton(u12) 
	
	if u12 then
		if not u12:getAttribute("IsNotAnim") then
			local u13 = u12:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", u12)
			-- NoScaleAnim: el boton NO crece/encoge en hover/click, pero SIGUE
			-- sonando (Tap/Click) y rotando el Icon si lo tiene.
			local skipScale = u12:GetAttribute("NoScaleAnim")
			u12.MouseEnter:Connect(function()
				
				u7.Tap:Play()
				if not skipScale then
					u8:Create(u13, u10.buttonInfo.info, {
						["Scale"] = 1.05
					}):Play()
				end
				if u12:FindFirstChild("Icon") then
					u8:Create(u12:FindFirstChild("Icon"), u10.buttonInfo.info, {
						["Rotation"] = 14
					}):Play()
				end
			end)
			u12.MouseLeave:Connect(function()
				
				if not skipScale then
					u8:Create(u13, u10.buttonInfo.info, {
						["Scale"] = 1
					}):Play()
				end
				if u12:FindFirstChild("Icon") then
					u8:Create(u12:FindFirstChild("Icon"), u10.buttonInfo.info, {
						["Rotation"] = 0
					}):Play()
				end
			end)
			u12.MouseButton1Down:Connect(function()
				
				u7.Click:Play()
				if not skipScale then
					u8:Create(u13, u10.buttonInfo.info, {
						["Scale"] = 1 - u10.buttonInfo.offset
					}):Play()
				end
			end)
			u12.MouseButton1Up:Connect(function()
				
				u7.Tap:Play()
				if not skipScale then
					u8:Create(u13, u10.buttonInfo.info, {
						["Scale"] = 1
					}):Play()
				end
			end)
		end
	else
		warn("Button not provided.")
		return
	end
end
function u9.ScaleUIStrokes(p14) 
	
	if p14 then
		u4(p14)
	end
end
function u9.True(p15) 
	
	if p15 then
		local v16 = p15:FindFirstChildOfClass("Frame")
		if v16 then
			if u11 then
				u9.False(u11)
			end
			local v17 = v16:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", v16)
			v16.Position = UDim2.new(0.5, 0, 0.65, 0)
			v17.Scale = 0.75
			v16.Visible = true
			p15.Enabled = true
			u8:Create(v17, u10.frameInfo.info, {
				["Scale"] = u10.frameInfo.DesiredScale
			}):Play()
			u8:Create(v16, u10.frameInfo.info, {
				["Position"] = u10.frameInfo.DesiredPos
			}):Play()
			u3(u10.frameInfo.fov, 0.1)
			u11 = p15
		end
	else
		warn("Frame not provided on toggle (true).")
		return
	end
end
function u9.False(p18) 
	
	if p18 then
		local v19 = p18:FindFirstChildOfClass("Frame")
		if v19 then
			u8:Create(v19:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", v19), u10.frameInfo.info, {
				["Scale"] = 0.4
			}):Play()
			u3(u10.frameInfo.baseFOV, 0.2)
			p18.Enabled = false
			v19.Visible = false
			v19.Position = UDim2.new(0.5, 0, 0.65, 0)
		end
	else
		warn("Frame not provided on toggle (false).")
		return
	end
end
function u9.ToggleFrame(p20) 
	
	if p20 then
		if u10.frameInfo.currentframe then
			if u10.frameInfo.currentframe == p20 then
				u10.frameInfo.currentframe = nil
				u9.False(p20)
			else
				u10.frameInfo.currentframe = p20
				u9.True(p20)
			end
		else
			u10.frameInfo.currentframe = p20
			u9.True(p20)
			return
		end
	else
		warn("Frame not provided.")
		return
	end
end
function u9.ClearFrame() 
	
	if u10.frameInfo.currentframe then
		u9.False(u10.frameInfo.currentframe)
		u10.frameInfo.currentframe = nil
	end
end
v6.OnClientEvent:Connect(function(p21, p22, p23)
	
	u5:New(p21, p22, p23)
end)
return u9