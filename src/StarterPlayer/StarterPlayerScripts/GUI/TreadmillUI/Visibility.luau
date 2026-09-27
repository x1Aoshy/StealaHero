-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw
-- Decompiled StarterPlayer.StarterPlayerScripts.GUI.TreadmillUI.Visibility from the base place (the stale bytecode
-- comment was dropped when it was patched). Injected by scripts/inject/topbar.luau.
--
-- TOPBAR patch (owner report 2026-09-23: "the backpack icon and the gear icon of the topbar both disappeared"):
-- the base game's treadmill "video mode" set PlayerGui.TopbarStandard.Enabled = false for the whole treadmill
-- session. TopbarStandard is the TopbarPlus v3 container of every left-aligned icon, i.e. BOTH the InventoryIcon
-- (GUI.BackpackController.Main) and the settings gear (GUI.Settings): they vanished together every time the player
-- stood on a treadmill (sessions are live: ServerScriptService.Controllers.TreadmillGrindService fires
-- "Treadmills: ActiveTreadmillChanged"). The TikTok video UI that needed that room is gone (the SpeedPhone lives on
-- the treadmill's own screen), so the topbar now stays: this module no longer looks TopbarStandard up (that lookup
-- was also an unbounded PlayerGui WaitForChild on a ScreenGui only TopbarPlus creates at runtime) and never writes
-- its Enabled. Money, hotbar and HUD tools are hidden and restored exactly as before.
--
-- TREADMILL HUD patch (owner report 2026-09-27: "on the treadmill the effect that hides the UI goes crazy, there are
-- logic fights"): during a session this module is the ONLY owner of the Visible / Enabled values it turns off. Other
-- scripts kept writing two of them mid-session: GUI.FriendBoost shows / hides Money.Bottom.Frame.FriendBoost on every
-- PlayerAdded / PlayerRemoving and friend-cache update, and HideImportantUI:UnHide / TrappedBackpackLock re-enable
-- BackpackGui. Those popped back on screen while running, and the exit then restored a stale snapshot. Now:
--   * a write that turns one of them back on during the session is undone (guardHidden) and becomes the value the exit
--     restores, so they go away once and stay away;
--   * Apply(true) / Apply(false) are idempotent: a repeated call changes nothing, the exit restores each value once;
--   * the exit leaves BackpackGui off while HideUI is locked (egg carry, admin cutscene): HideImportantUI owns it then
--     and slides it back in when it unlocks (same rule as GUI.TrappedBackpackLock);
--   * a hide by its owner while the element is already off fires no change event, so the exit also asks GUI.FriendBoost
--     (the only other writer of FriendBoost) to re-apply its own state: GetFriendCountInServer.CacheUpdated, which only
--     that script listens to.
-- The HUD slide under menus (BranchControllers.MenuMotionController) only moves Position, never these values.

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUI = require(ReplicatedStorage.Library.Client.GUI)

require(ReplicatedStorage.Library.Types.GUI)

local Player = require(ReplicatedStorage.Library.Player)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local Variables = require(ReplicatedStorage.Library.Variables) -- TREADMILL HUD patch: Locks.HideUI
local Players = game:GetService("Players") -- TREADMILL HUD patch: the FriendBoost refresh at the exit
local v5 = GUI.Money()
local Money = v5.Bottom.Frame.Money
local FriendBoost = v5.Bottom.Frame.FriendBoost
local TopBar = GUI.OfflineMoneyInPlot().TopBar
local v10 = GUI.Backpack()
local v11 = GUI.SideButtons()
local Tools = v11.Left.Tools
local TreadmillSpeedShop = Tools.TreadmillSpeedShop
local DoubleYourSpeed = Tools.DoubleYourSpeed
local Right = v11.Right
local Tabs = v11.Tabs
local t1 = {}

for _, child in ipairs(Tools:GetChildren()) do
	if child:IsA("GuiObject") then
		t1[#t1 + 1.0] = child
	elseif child:IsA("Folder") then
		for _, child2 in ipairs(child:GetChildren()) do
			if child2:IsA("GuiObject") then
				t1[#t1 + 1.0] = child2
			end
		end
	end
end

local t3 = nil
local guards = {} -- TREADMILL HUD patch: property-changed connections, only while a session is applied

-- TREADMILL HUD patch: keeps instance[property] off while the session lasts. When another script turns it back on,
-- remember(true) records that as the value to restore at the exit and the write is undone (our own `false` fires this
-- handler again, where it is a no-op). A script hiding it meanwhile fires nothing (it is already off).
local function guardHidden(instance, property: string, remember: (boolean) -> ())
	guards[#guards + 1] = instance:GetPropertyChangedSignal(property):Connect(function()
		if t3 == nil or not instance[property] then
			return
		end
		remember(true)
		instance[property] = false
	end)
end

local function releaseGuards()
	for i = #guards, 1, -1 do
		guards[i]:Disconnect()
		guards[i] = nil
	end
end

local function isHideUILocked(): boolean
	local HideUI = Variables.Locks and Variables.Locks.HideUI
	if HideUI == nil then
		return false
	end
	local ok, locked = pcall(HideUI.IsLocked, HideUI)
	return ok and locked == true
end

-- TREADMILL HUD patch: GUI.FriendBoost recomputes Money.Bottom.Frame.FriendBoost.Visible on this signal.
local function refreshFriendBoost()
	pcall(function()
		local GetFriendCountInServer = require(ReplicatedStorage.Library.Functions.GetFriendCountInServer)

		GetFriendCountInServer.CacheUpdated:Fire(Players.LocalPlayer)
	end)
end

return {
	Apply = function(b1: boolean) -- line: 67
		-- upvalues: t3 (ref), t1 (copy), v10 (copy), FriendBoost (copy), Money (copy), Right (copy), Tabs (copy), TopBar (copy), TreadmillSpeedShop (copy), DoubleYourSpeed (copy), Player (copy), TabController (copy)
		if b1 then
			if t3 ~= nil then
				-- TREADMILL HUD patch: already applied (and guarded) for this session: a repeated call changes nothing.
				return
			end

			do
				local t2 = {}

				for _, v in ipairs(t1) do
					t2[v] = v.Visible
				end

				t3 = {
					BackpackEnabled = v10.Enabled,
					FriendBoostVisible = FriendBoost.Visible,
					MoneyVisible = Money.Visible,
					SideButtonsGuiRightVisible = Right.Visible,
					SideButtonTabsVisible = Tabs.Visible,
					ToolVisibility = t2,
					OfflineMoneyInPlotVisible = TopBar.Visible,
				}
			end

			v10.Enabled = false
			Right.Visible = false
			Money.Visible = false
			FriendBoost.Visible = false
			TopBar.Visible = false

			-- TOPBAR patch: the TopbarPlus container (PlayerGui.TopbarStandard) is left alone, see the header.

			local v27 = t3

			assert(v27 ~= nil, "Expected treadmill UI visibility state")

			for k in pairs(v27.ToolVisibility) do
				k.Visible = false
			end

			TreadmillSpeedShop.Visible = true
			DoubleYourSpeed.Visible = true

			-- TREADMILL HUD patch: from here on nobody else turns these back on until the session ends.
			local snapshot = v27

			guardHidden(v10, "Enabled", function(value)
				snapshot.BackpackEnabled = value
			end)
			guardHidden(FriendBoost, "Visible", function(value)
				snapshot.FriendBoostVisible = value
			end)
			guardHidden(Money, "Visible", function(value)
				snapshot.MoneyVisible = value
			end)
			guardHidden(Right, "Visible", function(value)
				snapshot.SideButtonsGuiRightVisible = value
			end)
			guardHidden(TopBar, "Visible", function(value)
				snapshot.OfflineMoneyInPlotVisible = value
			end)

			for k in pairs(v27.ToolVisibility) do
				if k ~= TreadmillSpeedShop and k ~= DoubleYourSpeed then
					guardHidden(k, "Visible", function(value)
						snapshot.ToolVisibility[k] = value
					end)
				end
			end

			local v29 = Player.Optional.Humanoid()

			if v29 ~= nil then
				v29:UnequipTools()
			end

			return
		end

		if TabController.IsOpen("TreadmillSpeedShop") then
			TabController.CloseTab()
		end

		local v30 = t3

		if v30 == nil then
			return
		end

		-- TREADMILL HUD patch: stop guarding before restoring, and restore once.
		releaseGuards()
		t3 = nil

		TopBar.Visible = v30.OfflineMoneyInPlotVisible
		-- TREADMILL HUD patch: while HideUI is locked HideImportantUI owns BackpackGui (it re-enables it on unlock).
		v10.Enabled = v30.BackpackEnabled and not isHideUILocked()
		Money.Visible = v30.MoneyVisible
		FriendBoost.Visible = v30.FriendBoostVisible
		Right.Visible = v30.SideButtonsGuiRightVisible

		for k, v in pairs(v30.ToolVisibility) do
			if k.Parent ~= nil then
				k.Visible = v
			end
		end

		refreshFriendBoost()
	end
}
