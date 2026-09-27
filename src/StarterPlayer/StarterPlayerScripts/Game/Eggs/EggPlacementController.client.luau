-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw
-- Patched source (base-place bytecode blob dropped: it no longer matches this file).
--
-- BUG FIX (owner playtest: "when I grab an egg it goes into hotbar slot 3, but it does not let me
-- place it on the plot -- I have to deselect it and select it again").
-- Root cause: while a stolen area egg is carried, AreaEggs/init.client.luau holds a LOCAL-only
-- "CarriedEgg" Tool equipped on the character. At the safe zone the server claim
-- (AreaEggService.grantAreaEggClaim -> EggService.GrantEggTool) creates the real egg Tool and
-- Humanoid:EquipTool()s it server-side BEFORE it fires AreaEggRemoved / CarryState(false), so on
-- the client the real egg Tool lands in the character while CarriedEgg is still equipped there
-- (the server cannot unequip a tool it has never seen). The client then destroys CarriedEgg,
-- and the engine's single "local equipped tool" slot (ContextActionService LocalToolEquipped /
-- LocalToolUnequipped, which also routes click/R2 activation) is cleared by that unequip even
-- though the egg Tool is still held -- so Tool.Activated never fires again for it and this
-- controller, whose only placement trigger was Tool.Activated, can never place it. Deselect +
-- select (hotbar -> Eggs: RequestUnequipTool + RequestEquipTool) builds a fresh Tool with no
-- overlap, which is why that worked.
-- Fix (client side, independent of who equipped the tool or when):
--   1. When any OTHER Tool leaves the character while an egg Tool is bound, and the egg Tool is
--      now the only Tool held, re-equip it next frame (UnequipTools + EquipTool) so the engine's
--      equipped-tool/activation state points at it again.
--   2. Placement no longer depends solely on Tool.Activated: while an egg Tool is in the
--      character, an unprocessed world click (MouseButton1), gamepad R2 or TouchTapInWorld also
--      places it. Both paths share one debounce/in-flight guard, so a click never places twice.
--   3. Per-character connections are cleaned on respawn, and a removed Tool only unbinds when it
--      is the bound one (an old character's teardown can no longer unbind the new binding).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ActionPromptCmds = require(ReplicatedStorage.Library.Client.ActionPromptCmds)
local EggCmds = require(ReplicatedStorage.Library.Client.EggCmds)
local EggPlacementRaycast = require(ReplicatedStorage.Library.Client.Eggs.EggPlacementRaycast)
local EggToolDisplay = require(ReplicatedStorage.Library.Client.Eggs.EggToolDisplay)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)
local PlacedEggRenderer = require(ReplicatedStorage.Library.Client.Eggs.PlacedEggRenderer)
local PlotCmds = require(ReplicatedStorage.Library.Client.PlotCmds)
local Trove = require(ReplicatedStorage.Library.Modules.Packages.Trove)
local Variables = require(ReplicatedStorage.Library.Variables)
local ButtonR2 = Enum.KeyCode.ButtonR2
local LocalPlayer = Players.LocalPlayer
local v17 = Trove.new() -- bound egg tool
local characterTrove = Trove.new() -- current character's connections

-- Tool.Activated and the input fallback both fire for one click; keep them to one request.
local PLACE_DEBOUNCE_SECONDS = 0.3
local boundTool = nil
local placeInFlight = false
local lastPlaceAttempt = -math.huge

local function showInvalidPlacement(text: string?) -- line: 36
	-- upvalues: Message (copy)
	Message.Bottom({
		Message = text or "Cannot place egg here!",
		Time = 2.0,
		Color = Color3.fromRGB(255.0, 80.0, 80.0)
	})
end
local function placeEgg(p1) -- line: 44
	-- upvalues: EggToolDisplay (copy), PlotCmds (copy), EggPlacementRaycast (copy), LocalPlayer (copy), EggCmds (copy), PlacedEggRenderer (copy)
	local v26 = EggToolDisplay.GetToolUid(p1)

	if v26 == nil then
		showInvalidPlacement()

		return
	end

	local v27 = PlotCmds.GetPlotData()

	if v27 == nil then
		showInvalidPlacement()

		return
	end

	local PetArea = v27.PetArea
	local v29 = EggPlacementRaycast.Raycast(PetArea, LocalPlayer.UserId)

	if v29 == nil or PetArea ~= v29.Instance then
		showInvalidPlacement()

		return
	end

	local v30 = v27.CenterPoint.CFrame:ToObjectSpace(CFrame.new(v29.Position))
	local v31, v32 = EggCmds.RequestPlaceEgg(v26, v30)

	if not v31 then
		showInvalidPlacement(v32)

		return
	end

	PlacedEggRenderer.Refresh()
end
local function tryPlace(p1)
	-- upvalues: placeEgg (copy)
	if placeInFlight or p1.Parent == nil then
		return
	end

	local now = os.clock()

	if now - lastPlaceAttempt < PLACE_DEBOUNCE_SECONDS then
		return
	end

	lastPlaceAttempt = now
	placeInFlight = true

	local ok, err = pcall(placeEgg, p1)

	placeInFlight = false

	if not ok then
		warn("[EggPlacementController] place failed: " .. tostring(err))
	end
end
local function canPlaceFromHere() -- line: 78
	-- upvalues: Variables (copy), LocalPlayer (copy), PlotCmds (copy)
	if not Variables.Console then
		return false
	end

	local Character = LocalPlayer.Character
	local v34 = Character and Character:FindFirstChild("HumanoidRootPart")

	if v34 == nil or not v34:IsA("BasePart") then
		return false
	end

	return PlotCmds.IsWorldPositionWithinLocalPlotBounds(v34.Position)
end
local function refreshPlacePrompt() -- line: 92
	-- upvalues: canPlaceFromHere (copy), ActionPromptCmds (copy), ButtonR2 (copy)
	if canPlaceFromHere() then
		ActionPromptCmds.Show("EggPlacement", ButtonR2, "Place Egg")

		return
	end

	ActionPromptCmds.Hide("EggPlacement")
end
local function isHeldByLocalCharacter(p2)
	local Character = LocalPlayer.Character

	return Character ~= nil and p2.Parent == Character
end
local function unbindTool()
	-- upvalues: v17 (copy)
	boundTool = nil
	v17:Clean()
end
local function bindTool(p2) -- line: 100
	-- upvalues: v17 (copy), tryPlace (copy), RunService (copy), UserInputService (copy), refreshPlacePrompt (copy), ActionPromptCmds (copy), ButtonR2 (copy)
	v17:Clean()
	boundTool = p2
	v17:Connect(p2.Activated, function() -- line: 102
		-- upvalues: tryPlace (copy), p2 (copy)
		tryPlace(p2)
	end)
	-- Fallback for when the engine's activation state does not point at this Tool (see header).
	v17:Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or not isHeldByLocalCharacter(p2) then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == ButtonR2 then
			tryPlace(p2)
		end
	end)
	v17:Connect(UserInputService.TouchTapInWorld, function(_, processedByUI: boolean)
		if processedByUI or not isHeldByLocalCharacter(p2) then
			return
		end

		tryPlace(p2)
	end)

	local n1 = 0.0

	v17:Connect(RunService.Heartbeat, function(n2: number) -- line: 107
		-- upvalues: n1 (ref), refreshPlacePrompt (copy)
		n1 += n2

		if n1 < 0.2 then
			return
		end

		n1 = 0.0
		refreshPlacePrompt()
	end)
	v17:Add(function() -- line: 115
		-- upvalues: ActionPromptCmds (copy)
		ActionPromptCmds.Hide("EggPlacement")
	end)
	refreshPlacePrompt()
end
local function findEggTool(p3)
	-- upvalues: EggToolDisplay (copy)
	for _, child in ipairs(p3:GetChildren()) do
		if child.ClassName == "Tool" and EggToolDisplay.IsEggTool(child) then
			return child
		end
	end

	return nil
end
local function refreshCharacter(p3) -- line: 122
	-- upvalues: unbindTool (copy), findEggTool (copy), bindTool (copy)
	unbindTool()

	local tool = findEggTool(p3)

	if tool ~= nil then
		bindTool(tool)
	end
end
-- Another Tool left the character while the egg Tool stayed: once the egg Tool is the only one
-- held, re-equip it so the engine's equipped-tool/activation state is its own again.
local function reassertEggEquip(p3, p4)
	-- upvalues: LocalPlayer (copy)
	task.defer(function()
		if boundTool ~= p4 or p4.Parent ~= p3 or LocalPlayer.Character ~= p3 then
			return
		end

		for _, child in ipairs(p3:GetChildren()) do
			if child ~= p4 and child:IsA("Tool") then
				return -- still overlapping; that tool's own removal re-runs this
			end
		end

		local humanoid = p3:FindFirstChildOfClass("Humanoid")

		if humanoid == nil or humanoid.Health <= 0 or LocalPlayer:FindFirstChildOfClass("Backpack") == nil then
			return
		end

		humanoid:UnequipTools()

		if p4.Parent ~= nil then
			humanoid:EquipTool(p4)
		end
	end)
end
local function bindCharacter(p4) -- line: 132
	-- upvalues: characterTrove (copy), refreshCharacter (copy), EggToolDisplay (copy), bindTool (copy), unbindTool (copy), reassertEggEquip (copy)
	characterTrove:Clean()
	refreshCharacter(p4)
	characterTrove:Connect(p4.ChildAdded, function(child) -- line: 134
		-- upvalues: EggToolDisplay (copy), bindTool (copy)
		if child.ClassName == "Tool" and EggToolDisplay.IsEggTool(child) then
			bindTool(child)
		end
	end)
	characterTrove:Connect(p4.ChildRemoved, function(child) -- line: 139
		-- upvalues: unbindTool (copy), reassertEggEquip (copy), findEggTool (copy), bindTool (copy)
		if child.ClassName ~= "Tool" then
			return
		end

		if child == boundTool then
			unbindTool()

			-- Another egg Tool may still be in the character (e.g. a stale one): bind that instead.
			local other = findEggTool(p4)

			if other ~= nil then
				bindTool(other)
			end

			return
		end

		if boundTool ~= nil and boundTool.Parent == p4 then
			reassertEggEquip(p4, boundTool)
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(bindCharacter)
Network.Fired(Network.NET_MAP.Treadmills.ACTIVE_TREADMILL_EVENT):Connect(function(s1: string?) -- line: 151
	-- upvalues: PlacedEggRenderer (copy)
	PlacedEggRenderer.SetPromptsSuppressed(s1 ~= nil)
end)

if LocalPlayer.Character ~= nil then
	bindCharacter(LocalPlayer.Character)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() -- line: 158
	-- upvalues: LocalPlayer (copy), refreshCharacter (copy)
	local Character = LocalPlayer.Character

	if Character ~= nil then
		refreshCharacter(Character)
	end
end)
