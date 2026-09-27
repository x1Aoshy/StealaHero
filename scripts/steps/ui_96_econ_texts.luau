--!nocheck
-- scripts/steps/ui_96_econ_texts.luau (owner ECON) — runs after the ui_2x..ui_7x restyles, before ui_99_textwrap.
-- ECON 2026-09-24 (owner: "lower the entire money system, Black Widow as a basis should be giving like 4/s max"): the
-- whole money economy is divided by 125 (ReplicatedStorage.Library.Util.AssetGenerationUtil MONEY_SCALE). The Shop's
-- five cash packs are Game Passes granted by ServerScriptService.Controllers.ConsumableGamepassService, whose amounts
-- moved to 200 / 1,600 / 6,400 / 32,000 / 64,000; their titles are static base-place text (no script writes them),
-- so this step rewrites each one. A label whose text is no longer the old base value is left alone (someone restyled
-- it on purpose) and reported. Idempotent; never throws on a missing piece. Apply(place) prints one summary line.
-- Every other money number the player sees is written at runtime from the configs (treadmill / trail / base prices,
-- hero $/s, sell values, index rewards); the plot treadmill's "UNLOCK $8" lock price lives in scripts/steps/treadmill.luau.

local Step = {}

local SHOP_ROOT = { "Shop", "Frame", "Main", "ScrollingFrame" }

-- { path under SHOP_ROOT, base-place text, new text } (ConsumableGamepassService.GAMEPASS_GRANTS Money amounts)
Step.PACK_TITLES = {
	{ { "MoneyTop", "1", "Title" }, "$24,000", "$200" },
	{ { "MoneyTop", "2", "Title" }, "$200,000", "$1,600" },
	{ { "MoneyTop", "3", "Title" }, "$800,000", "$6,400" },
	{ { "MoneyBottom", "1", "Title" }, "$4,000,000", "$32,000" },
	{ { "MoneyBottom", "2", "Title" }, "$8,000,000", "$64,000" },
}

local function findPath(root, segments)
	local node = root
	for _, name in ipairs(segments) do
		node = node and node:FindFirstChild(name)
	end
	return node
end

function Step.Apply(place)
	local starterGui = place:GetService("StarterGui")
	local shop = starterGui and findPath(starterGui, SHOP_ROOT)
	if not shop then
		print("[ui_96_econ_texts] StarterGui.Shop.Frame.Main.ScrollingFrame missing; cash pack titles not rewritten")
		return
	end
	local done, already, skipped = 0, 0, {}
	for _, entry in ipairs(Step.PACK_TITLES) do
		local label = findPath(shop, entry[1])
		local name = table.concat(entry[1], ".")
		if not (label and (label:IsA("TextLabel") or label:IsA("TextButton"))) then
			table.insert(skipped, name .. " (missing)")
		elseif label.Text == entry[3] then
			already += 1
		elseif label.Text == entry[2] then
			label.Text = entry[3]
			done += 1
		else
			table.insert(skipped, string.format("%s (text %q)", name, label.Text))
		end
	end
	print(string.format("[ui_96_econ_texts] Shop cash pack titles: %d rewritten, %d already new%s", done, already,
		if #skipped > 0 then "; left alone: " .. table.concat(skipped, ", ") else ""))
end

return Step
