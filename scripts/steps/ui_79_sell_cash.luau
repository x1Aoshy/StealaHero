--!nocheck
-- scripts/steps/ui_79_sell_cash.luau (owner UIFIX, 2026-09-24)
-- Owner report: "Total value icon in sell heroes is a speed icon, should be cash". ui_20_windows gave the Sell Heroes
-- footer (StarterGui.AutoSell.Frame.SpFooter.CashIcon) rbxassetid://99458650446228, which is the blue running shoe
-- (the Speed icon: Rebirth / SpeedPower / SpeedGainAnimation use it), not money. Every money value of the window now
-- shows the icon the HUD money row draws (StarterGui.Money.Bottom.Frame.Money.CurrencyIcon, set by ui_30_hud from the
-- Shop's banknotes art; read here, never invented):
--   SpFooter.CashIcon          the Total Value icon (image swapped, same box);
--   SpCardTemplate.CashIcon    NEW: a small cash icon on every card's price row ("Value"); the Value label is narrowed so
--                              icon + price fit, and StarterPlayerScripts.GUI.SellHeroes centres icon + text together
--                              from the label's TextBounds at runtime;
--   root attribute SpCashIcon  the icon's uri (the client's fallback when the HUD icon is not there yet).
-- Also scans the whole window for any other speed-shoe image next to money and reports it. Runs after ui_20_windows /
-- ui_30_hud / ui_50_revamp, before ui_99_textwrap.

local roblox = require("@lune/roblox")
local UiKit = require("../lib/ui_kit")
local Kit = UiKit.Kit

local UDim2 = roblox.UDim2
local Vector2 = roblox.Vector2
local Enum = roblox.Enum
local Color3 = roblox.Color3

local Step = {}

Step.HUD_CASH_PATH = "Money.Bottom.Frame.Money.CurrencyIcon"
Step.SHOP_CASH_PATH = "Shop.Frame.Main.ScrollingFrame.MoneyTop.1.Icon"
Step.FALLBACK_CASH = 130591156585519 -- ui_30_hud RIBBON.cashIcon (the Shop's banknotes), only if both paths are gone
-- speed art that must never stand for money in this window (running shoes of the base game / Speedsters)
Step.SPEED_ICONS = {
	["99458650446228"] = true, ["88890095051151"] = true, ["71111471194517"] = true, ["94170745615043"] = true,
	["89229856722745"] = true, ["100644629385368"] = true,
}
Step.CARD_VALUE_Y = 0.905
Step.CARD_ICON = 0.13 -- card price icon, fraction of the card HEIGHT (square)
Step.CARD_VALUE_WIDTH = 0.72

local function log(fmt, ...)
	print(string.format("[ui_79_sell_cash] " .. fmt, ...))
end

local function isImage(inst)
	return inst ~= nil and (inst:IsA("ImageLabel") or inst:IsA("ImageButton"))
end

-- The cash icon id the HUD money row draws.
function Step.cashIconId(sg)
	for _, path in ipairs({ Step.HUD_CASH_PATH, Step.SHOP_CASH_PATH }) do
		local node = Kit.findPath(sg, path)
		local id = isImage(node) and Kit.imageId(node)
		if id and not Step.SPEED_ICONS[tostring(id)] then
			return tostring(id), "StarterGui." .. path
		end
	end
	return tostring(Step.FALLBACK_CASH), "fallback"
end

function Step.Apply(place, _spPlace, _ctx)
	local sg = place:GetService("StarterGui")
	local gui = sg:FindFirstChild("AutoSell")
	local root = gui and gui:FindFirstChild("Frame")
	if not (root and root:GetAttribute("SellHeroesWindow") == true) then
		log("skipped: StarterGui.AutoSell.Frame is not the Sell Heroes window (ui_20_windows did not convert it)")
		return
	end
	local id, source = Step.cashIconId(sg)
	local uri = "rbxassetid://" .. id
	local done = {}

	-- Total Value icon
	local footer = root:FindFirstChild("SpFooter")
	local footerIcon = footer and footer:FindFirstChild("CashIcon")
	if isImage(footerIcon) then
		local old = Kit.imageId(footerIcon)
		Kit.setImage(footerIcon, id)
		footerIcon.ImageTransparency = 0
		footerIcon.ImageColor3 = Color3.new(1, 1, 1)
		footerIcon.ScaleType = Enum.ScaleType.Fit
		table.insert(done, string.format("SpFooter.CashIcon %s -> %s", tostring(old), id))
	else
		log("WARNING: SpFooter.CashIcon missing")
	end

	-- price row of every card: cash icon + value
	local card = root:FindFirstChild("SpCardTemplate")
	local value = card and card:FindFirstChild("Value")
	if card and value and value:IsA("TextLabel") then
		local icon = UiKit.layer(card, "ImageLabel", "CashIcon", value.ZIndex)
		Kit.setImage(icon, id)
		icon.BackgroundTransparency = 1
		icon.ImageTransparency = 0
		icon.ImageColor3 = Color3.new(1, 1, 1)
		icon.ScaleType = Enum.ScaleType.Fit
		icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
		-- static layout (the client re-centres icon + text from TextBounds): icon left of a narrowed, centred price
		UiKit.setBox(icon, Vector2.new(0, 0.5), UDim2.fromScale(0.1, Step.CARD_VALUE_Y), UDim2.fromScale(Step.CARD_ICON, Step.CARD_ICON))
		value.AnchorPoint = Vector2.new(0.5, 0.5)
		value.Position = UDim2.fromScale(0.56, Step.CARD_VALUE_Y)
		value.Size = UDim2.fromScale(Step.CARD_VALUE_WIDTH, value.Size.Y.Scale)
		value.TextXAlignment = Enum.TextXAlignment.Center
		table.insert(done, "SpCardTemplate.CashIcon (price row)")
	else
		log("WARNING: SpCardTemplate.Value missing, cards keep a text-only price")
	end

	-- any other speed art left in the window
	local strays = {}
	for _, d in ipairs(root:GetDescendants()) do
		if isImage(d) then
			local digits = Kit.imageId(d)
			if digits and Step.SPEED_ICONS[tostring(digits)] then
				Kit.setImage(d, id)
				table.insert(strays, d:GetFullName())
			end
		end
	end
	if #strays > 0 then
		table.insert(done, "speed art replaced on " .. table.concat(strays, ", "))
	end
	root:SetAttribute("SpCashIcon", uri)
	log("Sell Heroes money icons = the HUD cash icon %s (from %s): %s", id, source, table.concat(done, "; "))
end

return Step
