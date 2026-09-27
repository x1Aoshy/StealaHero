-- ServerScriptService.Controllers.PlotService
-- Assigns Workspace.Plots.<id> (every numeric Model child, 1..6 in the built place) to players,
-- keeps ReplicatedStorage.Network's "Plots: *" remotes in sync (contract confirmed by reading
-- Library.Types.Plots + Library.Client.PlotCmds directly), and handles base upgrades.
--
-- Base themes (Gekko TO DO #5, Index completion rewards): the owner's profile.EquippedBaseTheme
-- (a Directory.BaseThemes key, only if in profile.UnlockedBaseThemes) is shown on their plot: the
-- themed props built for that plot (ServerStorage.BaseThemes.<Key>.<plotId>, built by
-- scripts/steps/post_zz_base_themes.luau, all anchored, non-collidable, non-queryable, outside the
-- hero area) are cloned into the plot as "ThemeProps", and the StarterPen fence is recoloured by
-- role. Applied on assignment, on equip and after base upgrades; reverted (props removed, every
-- fence part's original Color / Material / MaterialVariant restored) on unequip and when the plot
-- is freed. Plot.BaseTheme (attribute) = the key shown.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Database = require(game.ServerScriptService.Library.Database)

local Network = ReplicatedStorage:WaitForChild("Network")
local RequestStateRemote = Network:WaitForChild("Plots: RequestState")
local StateUpdateRemote = Network:WaitForChild("Plots: StateUpdate")
local RequestBaseUpgradeRemote = Network:WaitForChild("Plots: RequestBaseUpgrade")
local OnBaseUpgradedRemote = Network:WaitForChild("Plots: OnBaseUpgraded")
local RequestLobbyTeleportRemote = Network:WaitForChild("Plots: RequestLobbyTeleport")

local PlotsFolder = Workspace:WaitForChild("Plots")

-- Plot ids come from the place itself (the build keeps plots 1..6 and deletes the base place's
-- plot 7), so a server never hands out a plot that does not exist.
local PLOT_IDS = {}
for _, child in ipairs(PlotsFolder:GetChildren()) do
	local id = tonumber(child.Name)
	if id and child:IsA("Model") and not table.find(PLOT_IDS, id) then
		table.insert(PLOT_IDS, id)
	end
end
table.sort(PLOT_IDS)
if #PLOT_IDS == 0 then
	warn("[PlotService] Workspace.Plots has no numeric plot Models; no plots can be assigned")
end

-- Roblox thumbnail content URL: no-yield, resolves on the client (valid sizes 48/60/150/352/420).
local HEADSHOT_FORMAT = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"

-- Cost/MaxAssets per base level, copied literally from ReplicatedStorage.Directory.Bases
-- (that module errors on require() -- it looks for ServerStorage.Assets.Models.Bases.Main,
-- which doesn't exist in this rip; see memory).
-- BALANCE 2026-09-23 (owner approved): levels 2-8 repriced; must equal Directory.Bases COSTS.
-- ECON 2026-09-24: every cost /125 with the whole money economy (was 1000 / 50M / 2B / 12B / 50B / 250B / 1T / 5T /
-- 25T / 100T / 500T; level 4 rounded 96M -> 100M).
local BASE_TIERS = {
	[0] = { Cost = 0, MaxAssets = 7 },
	[1] = { Cost = 8, MaxAssets = 7 },
	[2] = { Cost = 400000, MaxAssets = 9 },
	[3] = { Cost = 16000000, MaxAssets = 10 },
	[4] = { Cost = 100000000, MaxAssets = 11 },
	[5] = { Cost = 400000000, MaxAssets = 12 },
	[6] = { Cost = 2000000000, MaxAssets = 13 },
	[7] = { Cost = 8000000000, MaxAssets = 14 },
	[8] = { Cost = 40000000000, MaxAssets = 15 },
	[9] = { Cost = 200000000000, MaxAssets = 16 },
	[10] = { Cost = 800000000000, MaxAssets = 17 },
	[11] = { Cost = 4000000000000, MaxAssets = 18 },
}
local MAX_BASE_LEVEL = 11

local PlotService = {}

local ownerOf = {} -- [plotId] = player
local plotOf = {} -- [player] = plotId
local characterConnections = {} -- [player] = RBXScriptConnection
local warnedNoPlot = {} -- [player] = true once the "server full" warning was logged
local leavingPlayers = {} -- [player] = true from PlayerRemoving until the Player is out of Players
local revision = 0

-- PlayerRemoving fires while the Player is still a child of Players, and Database keeps
-- reporting it loaded while its leave-save yields, so Parent alone cannot stop a leaving owner
-- from re-taking the plot that was just freed (it would then never be freed again).
local function canOwnPlot(player)
	return player.Parent == Players and not leavingPlayers[player]
end

local function plotModel(plotId)
	local plot = PlotsFolder:FindFirstChild(tostring(plotId))
	if plot then
		return plot
	end
	for _, candidate in ipairs(PlotsFolder:GetChildren()) do
		if candidate:IsA("Model") and tonumber(candidate.Name) == plotId then
			return candidate
		end
	end
	return nil
end

local function snapshot()
	local owners = {}
	for plotId, player in pairs(ownerOf) do
		owners[tostring(plotId)] = player.UserId
	end
	return owners
end

local function broadcastSlot(plotId, userIdOrNil)
	revision += 1
	StateUpdateRemote:FireAllClients({
		Revision = revision,
		Slot = plotId,
		UserId = userIdOrNil,
	})
end

local function setPlotBaseUpgradeLevel(plotId, level)
	local plot = plotModel(plotId)
	if plot then
		plot:SetAttribute("BaseUpgradeLevel", math.max(0, math.floor(tonumber(level) or 0)))
	end
end

local function getPlayerPlotSign(plotId)
	local plot = plotModel(plotId)
	local sign = plot and plot:FindFirstChild("PlotSign")
	return sign and sign:FindFirstChild("PlayerPlotSign")
end

local function setPlotSignOwner(plotId, player)
	local playerSign = getPlayerPlotSign(plotId)
	if not playerSign then
		return
	end
	local frame = playerSign:FindFirstChild("Frame")
	if frame then
		local nameLabel = frame:FindFirstChild("PlayerName")
		local icon = frame:FindFirstChild("PlayerIcon")
		if nameLabel then
			nameLabel.Text = player.DisplayName
		end
		if icon then
			icon.Image = string.format(HEADSHOT_FORMAT, player.UserId)
		end
	end
	playerSign.Enabled = true
end

local function clearPlotSignOwner(plotId)
	local playerSign = getPlayerPlotSign(plotId)
	if not playerSign then
		return
	end
	local frame = playerSign:FindFirstChild("Frame")
	if frame then
		local nameLabel = frame:FindFirstChild("PlayerName")
		local icon = frame:FindFirstChild("PlayerIcon")
		if nameLabel then
			nameLabel.Text = ""
		end
		if icon then
			icon.Image = ""
		end
	end
	playerSign.Enabled = false
end

local function teleportToSpawn(player, plotId)
	local plot = plotModel(plotId)
	local spawnPoint = plot and plot:FindFirstChild("SpawnPoint")
	if not spawnPoint then
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
	end
end

---------------------------------------------------------------------------------------------------
-- Base themes
---------------------------------------------------------------------------------------------------

-- Optional: without the directory (or the built props) plots simply keep the plain look.
local BaseThemes = nil
do
	local directory = ReplicatedStorage:FindFirstChild("Directory")
	local module = directory and directory:FindFirstChild("BaseThemes")
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			BaseThemes = result
		else
			warn("[PlotService] Directory.BaseThemes failed to load (base themes disabled): " .. tostring(result))
		end
	end
end

local THEME_PROPS_NAME = "ThemeProps"
local THEME_ATTRIBUTE = "BaseTheme"
local appliedTheme = {} -- [plotId] = theme key currently shown
local penOriginals = {} -- [plotId] = { [BasePart] = { Color, Material, MaterialVariant, Transparency? } } of themed fence parts

local function materialNamed(name)
	if type(name) ~= "string" then
		return nil
	end
	local ok, material = pcall(function()
		return Enum.Material[name]
	end)
	return ok and material or nil
end

-- Fence role of a visible StarterPen part (see Directory.BaseThemes), from its name / shape only, so
-- a later restyle of the fence colours does not break it. nil = leave the part alone.
local function fenceRole(part, groundY)
	local parentName = part.Parent and part.Parent.Name or ""
	if parentName == "GateLeft" or parentName == "GateRight" then
		return if part.Name == "Hinge" then "Hinge" else "Gate"
	end
	if part.Name == "HubFenceCap" then
		return "Cap"
	elseif part.Name == "HubFenceGem" then
		return "Gem"
	elseif part.Name == "HubFenceBrace" then
		return "Brace"
	end
	local size = part.Size
	if size.Y >= 3 and size.X <= 2 and size.Z <= 2 then
		return "Post"
	end
	if math.max(size.X, size.Z) >= 4 then
		local level = part.CFrame.Position.Y - groundY
		if level < 1.4 then
			return "RailLow"
		elseif level > 3 then
			return "RailTop"
		end
		return "Brace"
	end
	return nil
end

local function starterPen(plot)
	local toUpdate = plot:FindFirstChild("ToUpdate")
	return toUpdate and toUpdate:FindFirstChild("StarterPen")
end

local function restorePen(plotId)
	local originals = penOriginals[plotId]
	penOriginals[plotId] = nil
	for part, look in pairs(originals or {}) do
		if part.Parent then
			part.Color = look[1]
			part.Material = look[2]
			part.MaterialVariant = look[3]
			if look[4] ~= nil then
				part.Transparency = look[4]
			end
		end
	end
end

local function recolourPen(plotId, plot, theme)
	local pen = starterPen(plot)
	if not pen or type(theme.Fence) ~= "table" then
		return
	end
	local visible = {}
	local groundY = tonumber(plot:GetAttribute("TreadmillFloorY"))
	for _, part in ipairs(pen:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			table.insert(visible, part)
			if not groundY or part.CFrame.Position.Y - part.Size.Y / 2 < groundY then
				groundY = part.CFrame.Position.Y - part.Size.Y / 2
			end
		end
	end
	local originals = penOriginals[plotId] or {}
	penOriginals[plotId] = originals
	local materials = type(theme.FenceMaterials) == "table" and theme.FenceMaterials or {}
	for _, part in ipairs(visible) do
		local role = fenceRole(part, groundY or 0)
		local color = role and theme.Fence[role]
		if typeof(color) == "Color3" then
			local look = originals[part]
			if not look then
				look = { part.Color, part.Material, part.MaterialVariant }
				originals[part] = look
			end
			part.Color = color
			local material = materialNamed(materials[role])
			if material then
				part.Material = material
				part.MaterialVariant = ""
			else
				part.Material = look[2]
				part.MaterialVariant = look[3]
			end
		end
	end
end

-- A theme whose props bring their own modelled pen (ServerStorage.BaseThemes model attribute HidesPenFence, see
-- post_zz_base_themes IMPORTED_PENS) hides the StarterPen fence under it. The gate leaves (GateLeft / GateRight) stay:
-- they are the base lock. The fence parts are CanCollide false already, so only the look changes.
local function hidePenFence(plotId, plot)
	local pen = starterPen(plot)
	if not pen then
		return
	end
	local originals = penOriginals[plotId] or {}
	penOriginals[plotId] = originals
	for _, part in ipairs(pen:GetDescendants()) do
		local parentName = part.Parent and part.Parent.Name or ""
		if part:IsA("BasePart") and part.Transparency < 1 and parentName ~= "GateLeft" and parentName ~= "GateRight" then
			local look = originals[part]
			if not look then
				look = { part.Color, part.Material, part.MaterialVariant }
				originals[part] = look
			end
			if look[4] == nil then
				look[4] = part.Transparency
			end
			part.Transparency = 1
		end
	end
end

local function clearPlotTheme(plotId)
	local plot = plotModel(plotId)
	if plot then
		for _, child in ipairs(plot:GetChildren()) do
			if child.Name == THEME_PROPS_NAME then
				child:Destroy()
			end
		end
		plot:SetAttribute(THEME_ATTRIBUTE, nil)
	end
	restorePen(plotId)
	appliedTheme[plotId] = nil
end

local function themePropsSource(key, plotId)
	local folder = ServerStorage:FindFirstChild("BaseThemes")
	local themeFolder = folder and folder:FindFirstChild(key)
	return themeFolder and themeFolder:FindFirstChild(tostring(plotId))
end

-- Shows theme `key` ("" = none) on the plot. Idempotent: the same key only re-runs the fence
-- recolour (a rebuilt fence part picks the theme up) and restores missing props.
local function applyPlotTheme(plotId, key)
	local theme = BaseThemes and BaseThemes.Get(key)
	if theme == nil then
		if appliedTheme[plotId] ~= nil then
			clearPlotTheme(plotId)
		end
		return
	end
	local plot = plotModel(plotId)
	if not plot then
		return
	end
	if appliedTheme[plotId] ~= key then
		clearPlotTheme(plotId)
	end
	if plot:FindFirstChild(THEME_PROPS_NAME) == nil then
		local source = themePropsSource(key, plotId)
		if source then
			local props = source:Clone()
			props.Name = THEME_PROPS_NAME
			props.Parent = plot
		else
			warn(string.format("[PlotService] No themed props for base theme %s on plot %s", key, tostring(plotId)))
		end
	end
	recolourPen(plotId, plot, theme)
	local props = plot:FindFirstChild(THEME_PROPS_NAME)
	if props and props:GetAttribute("HidesPenFence") == true then
		hidePenFence(plotId, plot)
	end
	plot:SetAttribute(THEME_ATTRIBUTE, key)
	appliedTheme[plotId] = key
end

-- The theme the player's profile asks for: an unlocked, known key, else "".
local function equippedThemeOf(player)
	local profile = Database.Get(player)
	local key = profile and profile.EquippedBaseTheme
	local unlocked = profile and profile.UnlockedBaseThemes
	if type(key) ~= "string" or key == "" or type(unlocked) ~= "table" or unlocked[key] ~= true then
		return ""
	end
	return key
end

local function refreshPlayerTheme(player)
	local plotId = plotOf[player]
	if not plotId or ownerOf[plotId] ~= player then
		return
	end
	local ok, err = pcall(applyPlotTheme, plotId, equippedThemeOf(player))
	if not ok then
		warn("[PlotService] Base theme failed for " .. player.Name .. ": " .. tostring(err))
	end
end

function PlotService.RefreshBaseTheme(player)
	refreshPlayerTheme(player)
end

function PlotService.GetPlotId(player)
	return plotOf[player]
end

function PlotService.GetPlotIds()
	return table.clone(PLOT_IDS)
end

-- teleportNow: move the current character to the plot right away (true on join). A late
-- assignment (a plot freed for a player who was waiting in the hub) passes false: that player
-- may be mid-run or carrying an egg, so only their next spawn (or the base button) takes them.
local function assignPlot(player, teleportNow)
	if plotOf[player] or not canOwnPlot(player) then
		return
	end
	local freeId = nil
	for _, plotId in ipairs(PLOT_IDS) do
		if not ownerOf[plotId] and plotModel(plotId) then
			freeId = plotId
			break
		end
	end
	if not freeId then
		-- Server full: the player keeps playing from the hub spawn without a base.
		if not warnedNoPlot[player] then
			warnedNoPlot[player] = true
			warn("[PlotService] No free plot for " .. player.Name .. " (server full)")
		end
		return
	end
	ownerOf[freeId] = player
	plotOf[player] = freeId
	local profile = Database.Get(player)
	setPlotBaseUpgradeLevel(freeId, profile and profile.BaseUpgradeLevel or 0)
	setPlotSignOwner(freeId, player)
	broadcastSlot(freeId, player.UserId)
	refreshPlayerTheme(player)

	local function onCharacterAdded(character)
		character:WaitForChild("Humanoid", 5)
		character:WaitForChild("HumanoidRootPart", 5)
		if plotOf[player] == freeId then
			teleportToSpawn(player, freeId)
		end
	end
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end
	characterConnections[player] = player.CharacterAdded:Connect(onCharacterAdded)
	if teleportNow and player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

local function freePlot(player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end
	warnedNoPlot[player] = nil
	local plotId = plotOf[player]
	if not plotId then
		return
	end
	ownerOf[plotId] = nil
	plotOf[player] = nil
	local okTheme, themeErr = pcall(clearPlotTheme, plotId)
	if not okTheme then
		warn("[PlotService] Failed to clear the base theme of plot " .. tostring(plotId) .. ": " .. tostring(themeErr))
	end
	clearPlotSignOwner(plotId)
	setPlotBaseUpgradeLevel(plotId, 0)
	broadcastSlot(plotId, nil)
end

Database.OnLoaded(function(player)
	local ok, err = pcall(assignPlot, player, true)
	if not ok then
		warn("[PlotService] Failed to assign plot to " .. player.Name .. ": " .. tostring(err))
	end
end)

-- Keep the plot's BaseUpgradeLevel attribute in step with the owner's profile (and re-assert the
-- owner's base theme after the upgrade).
Database.OnFieldChanged("BaseUpgradeLevel", function(player, level)
	local plotId = plotOf[player]
	if plotId then
		setPlotBaseUpgradeLevel(plotId, level)
		refreshPlayerTheme(player)
	end
end)

-- Equip / unequip (IndexService's "BaseThemes: RequestEquip") and new unlocks.
Database.OnFieldChanged("EquippedBaseTheme", function(player)
	refreshPlayerTheme(player)
end)
Database.OnFieldChanged("UnlockedBaseThemes", function(player)
	refreshPlayerTheme(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if Database.IsPlayerLoaded(player) then
		task.defer(assignPlot, player, true)
	end
end

-- A plot freed by a leaving player goes to someone who joined a full server (waiting in the hub).
local function assignWaitingPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if not plotOf[player] and canOwnPlot(player) and Database.IsPlayerLoaded(player) then
			local ok, err = pcall(assignPlot, player, false)
			if not ok then
				warn("[PlotService] Failed to assign plot to " .. player.Name .. ": " .. tostring(err))
			end
		end
	end
end

-- Drop the leaving mark once the Player has left Players (checked every 5 s for up to a minute;
-- a Player still parented after that keeps its mark, so it can never be handed a plot).
local function forgetLeavingPlayer(player, checks)
	if player.Parent ~= Players then
		leavingPlayers[player] = nil
	elseif checks < 12 then
		task.delay(5, forgetLeavingPlayer, player, checks + 1)
	end
end

Players.PlayerRemoving:Connect(function(player)
	leavingPlayers[player] = true
	local hadPlot = plotOf[player] ~= nil
	freePlot(player)
	if hadPlot then
		task.defer(assignWaitingPlayers)
	end
	task.delay(5, forgetLeavingPlayer, player, 1)
end)

RequestStateRemote.OnServerInvoke = function(_player)
	return {
		Revision = revision,
		OwnersBySlot = snapshot(),
	}
end

RequestBaseUpgradeRemote.OnServerEvent:Connect(function(player)
	local profile = Database.Get(player)
	if not profile then
		return
	end
	local nextLevel = (profile.BaseUpgradeLevel or 0) + 1
	if nextLevel > MAX_BASE_LEVEL then
		return
	end
	local tier = BASE_TIERS[nextLevel]
	if not tier then
		return
	end
	if (profile.Money or 0) < tier.Cost then
		return
	end
	Database.SetAndBroadcast(player, {
		Money = profile.Money - tier.Cost,
		BaseUpgradeLevel = nextLevel,
	})
	OnBaseUpgradedRemote:FireClient(player)
end)

RequestLobbyTeleportRemote.OnServerEvent:Connect(function(player)
	local plotId = plotOf[player]
	if plotId then
		teleportToSpawn(player, plotId)
	end
end)

return PlotService
