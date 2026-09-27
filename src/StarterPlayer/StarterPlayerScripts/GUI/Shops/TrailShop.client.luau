-- StarterPlayer.StarterPlayerScripts.GUI.Shops.TrailShop (LocalScript)
-- Decompiled from the base place (UniversalSynSaveInstance rip), patched:
--   * nil-safe TrailInventory (earlier patch);
--   * TRAILS 2026-09-23: the server side now exists (ServerScriptService.TrailService, Money purchases). Every
--     request is pcall'ed and debounced per entry, a purchase confirms with a message, and the Robux button stays
--     hidden: the configs' ProductIds are the ripped game's developer products (not sellable in this experience)
--     and no ProcessReceipt branch grants trails. Set ROBUX_PURCHASES_ENABLED only after both exist.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Simple = require(ReplicatedStorage.Library.Modules.FormatNumber.Simple)
local GUI = require(ReplicatedStorage.Library.Client.GUI)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)
local MonetizationGamepassUtil = require(ReplicatedStorage.Library.Util.MonetizationGamepassUtil)
local Products = require(ReplicatedStorage.Directory.Products)
local PromptPurchase = require(ReplicatedStorage.Library.Shared.Functions.PromptPurchase)
local Save = require(ReplicatedStorage.Library.Client.Save)
local Trails = require(ReplicatedStorage.Directory.Trails)
local TreadmillUtil = require(ReplicatedStorage.Library.Util.TreadmillUtil)
local GradientSwap = require(ReplicatedStorage.Library.Functions.GradientSwap)

local ROBUX_PURCHASES_ENABLED = false

local Trails2 = Constants.NETWORK_MAP.Trails
local SPEED_COLOR = Color3.fromRGB(9, 255, 0)
local FAIL_COLOR = Color3.fromRGB(255, 64, 64)
local SUCCESS_COLOR = Color3.fromRGB(90, 255, 120)
local ScrollingFrame = GUI.TrailShop().Main.ShopContent.List.ScrollingFrame
local Template = ScrollingFrame.Template
local entries = {}
local priceRequested = {}
local busy = {}

local function robuxAvailable(config)
	return ROBUX_PURCHASES_ENABLED and config.ProductId ~= nil and Products.DataByProductId[config.ProductId] ~= nil
end

local function showMessage(text: string, color: Color3)
	Message.Bottom({
		Time = 3,
		Message = text,
		Color = color,
	})
end

local function refreshEntry(frame, trailId: string)
	local save = Save.Get()
	if save == nil then
		return
	end

	local config = Trails.Directory[trailId]
	local inventory = save.TrailInventory or {}
	local owned = inventory[trailId] == true
	local label = frame.Buttons.CashBuy.Label

	if owned then
		label.Text = if save.EquippedTrail == trailId then "Unequip" else "Equip"
	else
		label.Text = `${ Simple.FormatCompact(config.Price, ".#") }`
	end

	frame.Buttons.RobuxBuy.Visible = robuxAvailable(config) and not owned
end

local function bindShopEntry(trailId: string, order: number)
	local config = Trails.Directory[trailId]
	local clone = Template:Clone()

	clone.Name = trailId
	clone.LayoutOrder = order
	clone.Visible = true
	clone.Parent = ScrollingFrame
	clone.Title.Text = config.DisplayName
	clone.Rarity.Text = config.Rarity.DisplayName
	config.Rarity.Gradient:Clone().Parent = clone.Rarity
	GradientSwap(clone.Background, config.Rarity.Gradient)
	clone.Icon.Image = config.Icon
	clone.Data.Boosts.RichText = true
	clone.Data.Boosts.Text = `<font color="#{ SPEED_COLOR:ToHex() }">{ TreadmillUtil.FormatSpeedMultiplierValue(config.SpeedMultiplier) }</font> Speed`

	local CashBuy = clone.Buttons.CashBuy
	local RobuxBuy = clone.Buttons.RobuxBuy

	entries[trailId] = {
		RobuxPrice = nil,
		Frame = clone,
	}

	ButtonFX(CashBuy, 1.05, function()
		if busy[trailId] then
			return
		end
		local save = Save.Get()
		if save == nil then
			return
		end

		local inventory = save.TrailInventory or {}
		local buying = inventory[trailId] ~= true
		busy[trailId] = true

		local okCall, ok, err
		if not buying then
			if save.EquippedTrail == trailId then
				okCall, ok, err = pcall(Network.Invoke, Trails2.REQUEST_UNEQUIP)
			else
				okCall, ok, err = pcall(Network.Invoke, Trails2.REQUEST_SELECT, trailId)
			end
		else
			okCall, ok, err = pcall(Network.Invoke, Trails2.REQUEST_PURCHASE, trailId)
		end

		busy[trailId] = nil

		if okCall and ok then
			if buying then
				showMessage(`You bought the { config.DisplayName }!`, SUCCESS_COLOR)
			end
		else
			showMessage(if okCall and type(err) == "string" and err ~= "" then err else "Trail request failed", FAIL_COLOR)
		end

		refreshEntry(clone, trailId)
	end)

	ButtonFX(RobuxBuy, 1.05, function()
		if not robuxAvailable(config) then
			showMessage("Robux purchases for trails are not available yet", FAIL_COLOR)
			return
		end

		PromptPurchase.Prompt(config.ProductId, true)
	end)

	if robuxAvailable(config) then
		RobuxBuy.Label.Text = Constants.ROBUX_ICON_STR

		if not priceRequested[config.ProductId] then
			priceRequested[config.ProductId] = true
			task.spawn(function()
				local okPrice, robuxPrice = pcall(MonetizationGamepassUtil.GetProductPriceInRobux, config.ProductId)
				local entry = entries[trailId]

				if okPrice and entry ~= nil and type(robuxPrice) == "number" and robuxPrice > 0 then
					entry.RobuxPrice = robuxPrice
					RobuxBuy.Label.Text = `{ Constants.ROBUX_ICON_STR } { Simple.FormatCompact(robuxPrice, ".#") }`
				end
			end)
		end
	end

	refreshEntry(clone, trailId)
end

Template.Visible = false
Template.Parent = script

if not Save.IsLocalDataLoaded() then
	Save.LoadedStats:Wait()
end

local shopIds = {}

for trailId, config in pairs(Trails.Directory) do
	if config.DisplayInShop then
		shopIds[#shopIds + 1] = trailId
	end
end

table.sort(shopIds, function(a: string, b: string)
	return Trails.Directory[a].Price < Trails.Directory[b].Price
end)

for index, trailId in ipairs(shopIds) do
	bindShopEntry(trailId, index)
end

Save.ConnectForDataChanged({
	"TrailInventory",
	"EquippedTrail",
}, function()
	for _, trailId in ipairs(shopIds) do
		local frame = ScrollingFrame:FindFirstChild(trailId)
		if frame and frame:IsA("Frame") then
			refreshEntry(frame, trailId)
		end
	end
end)

return {}
