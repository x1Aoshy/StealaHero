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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUI = require(ReplicatedStorage.Library.Client.GUI)

require(ReplicatedStorage.Library.Types.GUI)

local Player = require(ReplicatedStorage.Library.Player)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
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

return {
	Apply = function(b1: boolean) -- line: 67
		-- upvalues: t3 (ref), t1 (copy), v10 (copy), FriendBoost (copy), Money (copy), Right (copy), Tabs (copy), TopBar (copy), TreadmillSpeedShop (copy), DoubleYourSpeed (copy), Player (copy), TabController (copy)
		if b1 then
			if t3 == nil then
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

		TopBar.Visible = v30.OfflineMoneyInPlotVisible
		v10.Enabled = v30.BackpackEnabled
		Money.Visible = v30.MoneyVisible
		FriendBoost.Visible = v30.FriendBoostVisible
		Right.Visible = v30.SideButtonsGuiRightVisible

		for k, v in pairs(v30.ToolVisibility) do
			if k.Parent ~= nil then
				k.Visible = v
			end
		end

		t3 = nil
	end
}
