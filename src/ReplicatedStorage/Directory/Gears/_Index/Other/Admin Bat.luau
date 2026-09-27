-- Admin Bat inventory icon config (added by hand, not part of the original rip).
--
-- BUG FIX (user report: blank icon for the Admin Bat in the inventory). BackpackController.Main's
-- "Gear" icon branch resolves an icon two ways: the Tool's own TextureId first, then
-- Gears.Directory[GearName].Icon as a fallback -- and there was no Gears.Directory entry for
-- "Admin Bat" at all (only the plain "Bat" gear and the per-zone Bat reskins have one), so the
-- fallback always resolved to "". Reusing the same base "Bat" gear's real icon here since Admin
-- Bat is the same weapon (ServerStorage."Admin Bat" uses the identical GearToolServer fling
-- pattern, just with bigger GearFlingPower/GearUpBoost attributes) -- not a fabricated asset id.
require(script.Parent.Parent.Parent.Types.Interface)

local Default = require(script.Parent.Parent.Parent.BaseConfigs.Default)

return (setmetatable({
	Icon = "rbxassetid://131099804712161",
	MoneyCost = 0.0,
	ShopDropWeight = 0.0,
	MinShopStockQuantity = 1.0,
	MaxShopStockQuantity = 1.0,
	ToolController = "None",
	ToolModel = "Bat",
	Description = "Admin-only bat. Fling players and steal their eggs!",
	Rarity = "Legendary",
	Persistent = false,
	SinglePurchase = true,
	DisplayInShop = false,
	DisplayName = script.Name,
}, {
	__index = Default
}))
