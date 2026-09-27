--!nocheck
-- scripts/steps/ui_99_textwrap.luau (owner LEAD) — runs after every other ui_* step (name order).
-- Roblox renders a TextLabel / TextButton / TextBox with TextScaled = true but TextWrapped = false at its fixed
-- TextSize instead of scaling it (the owner saw tiny text on the currency pills, the sidebar labels, the hub stall
-- signs and the Free Gift board). The base place has 2529 TextScaled labels and none with TextWrapped = false
-- (Studio turns TextWrapped on together with TextScaled); every such label came from our build steps. This pass
-- restores the pair on every text object in the place, so a step that forgets it can never ship tiny text again.
-- Idempotent. Apply(place, spPlace, ctx) prints one summary line.

local Step = {}

local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }

function Step.Apply(place)
	local fixed, byRoot = 0, {}
	for _, d in ipairs(place:GetDescendants()) do
		if TEXT_CLASSES[d.ClassName] and d.TextScaled == true and d.TextWrapped ~= true then
			d.TextWrapped = true
			fixed += 1
			local root = string.match(d:GetFullName(), "^[^%.]+%.[^%.]+") or d:GetFullName()
			byRoot[root] = (byRoot[root] or 0) + 1
		end
	end
	local parts = {}
	for root, count in pairs(byRoot) do
		table.insert(parts, string.format("%s %d", root, count))
	end
	table.sort(parts)
	print(string.format("[ui_99_textwrap] TextWrapped restored on %d TextScaled label(s)%s", fixed,
		if #parts > 0 then ": " .. table.concat(parts, ", ") else ""))
end

return Step
