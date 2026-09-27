-- StarterPlayerScripts.Game.Plots.BaseThemeVfxController (LocalScript, injected by scripts/inject/basedoors.luau)
-- Themed ambience around the themed bases (owner 2026-09-26: "add some vfx to the bases for each one, something
-- related to their theme, for example One Piece can be like gusts of wind around it"): while a plot wears a theme
-- (its BaseTheme attribute, set by PlotService), ReplicatedStorage.Library.Modules.BaseThemeVfx builds that theme's
-- emitters / beams on invisible inert anchors in Workspace.ClientBaseVfx; a theme change rebuilds it, "" removes it.
-- One loop at BaseThemeVfx.UPDATE_INTERVAL: bases farther than ACTIVE_DISTANCE (180) studs from the camera are switched
-- off (no particles, no bursts), near ones run their bursts / flicker / pulses. Touch devices get MOBILE_RATE_SCALE of
-- the particles. Client-only visuals, nothing is sent to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Modules = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules")
local BaseThemeVfx = require(Modules:WaitForChild("BaseThemeVfx"))
local BaseDoors = require(Modules:WaitForChild("BaseDoors"))

local FOLDER_NAME = "ClientBaseVfx"
local RATE_SCALE = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then BaseThemeVfx.MOBILE_RATE_SCALE else 1

local folder = Workspace:FindFirstChild(FOLDER_NAME)
if folder == nil then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace
end

local records = {} -- [plot] = { plot, key, fx, connections }

local function rebuild(record)
	local plot = record.plot
	local key = plot:GetAttribute("BaseTheme")
	key = if type(key) == "string" then key else ""
	if record.key == key and (record.fx ~= nil or BaseThemeVfx.Themes[key] == nil) then
		return
	end
	if record.fx then
		record.fx:Destroy()
		record.fx = nil
	end
	record.key = key
	if BaseThemeVfx.Themes[key] == nil then
		return
	end
	local frame = BaseThemeVfx.PenFrame(plot)
	local gate = plot:GetAttribute(BaseDoors.ATTR.Origin)
	if frame == nil or typeof(gate) ~= "Vector3" then
		return
	end
	local layout = {
		D = plot:GetAttribute(BaseDoors.ATTR.PenHalfDepth) or 26.25,
		W = plot:GetAttribute(BaseDoors.ATTR.PenHalfWidth) or 26.25,
		gx = frame:PointToObjectSpace(gate).X,
		gate = BaseDoors.ReadGeometry(plot, key),
	}
	local ok, fx = pcall(BaseThemeVfx.Build, key, frame, layout, folder, RATE_SCALE)
	if not ok then
		warn(string.format("[BaseThemeVfx] %s on plot %s failed: %s", key, plot.Name, tostring(fx)))
		return
	end
	if fx then
		fx.model.Name = "BaseVfx_" .. plot.Name
		record.fx = fx
	end
end

local untrack

local function track(plot)
	if records[plot] or not plot:IsA("Model") then
		return
	end
	local record = { plot = plot, key = nil, connections = {} }
	records[plot] = record
	table.insert(record.connections, plot:GetAttributeChangedSignal("BaseTheme"):Connect(function()
		rebuild(record)
	end))
	table.insert(record.connections, plot.AncestryChanged:Connect(function()
		if not plot:IsDescendantOf(Workspace) then
			untrack(plot)
		end
	end))
	rebuild(record)
end

function untrack(plot)
	local record = records[plot]
	if record == nil then
		return
	end
	records[plot] = nil
	for _, connection in ipairs(record.connections) do
		connection:Disconnect()
	end
	if record.fx then
		record.fx:Destroy()
		record.fx = nil
	end
end

local function tick(now, dt)
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local eye = camera.CFrame.Position
	for _, record in pairs(records) do
		local fx = record.fx
		if fx then
			local active = (fx.centre - eye).Magnitude <= BaseThemeVfx.ACTIVE_DISTANCE
			if active ~= fx.active then
				fx:SetActive(active)
			end
			if active then
				fx:Update(now, dt)
			end
		end
	end
end

local plots = Workspace:WaitForChild("Plots")
plots.ChildAdded:Connect(function(plot)
	task.defer(track, plot)
end)
plots.ChildRemoved:Connect(untrack)
for _, plot in ipairs(plots:GetChildren()) do
	track(plot)
end

task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(BaseThemeVfx.UPDATE_INTERVAL)
		local now = os.clock()
		local ok, err = pcall(tick, now, now - last)
		last = now
		if not ok then
			warn("[BaseThemeVfx] update failed: " .. tostring(err))
		end
	end
end)
