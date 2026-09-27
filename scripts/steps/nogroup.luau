-- scripts/steps/nogroup.luau
-- Build step: removes the "join our group" advertising of the base place.
--
-- The spam itself is the GroupRewards LocalScript auto-nudge (GroupService:PromptJoinAsync 3 s after load, then
-- every 5 min while not a member); that script is re-injected without it via scripts/inject/nogroup.luau. This
-- step removes/neutralises the other ways the game advertised or prompted a group:
--   1. Workspace.Stands.Pads.GroupReward: the pad that opened the "Join The Community!" GroupReward window on
--      touch (UpgradesPads binds every BasePart in Stands.Pads by name). Destroyed; UpgradesPads just iterates
--      Pads:GetChildren(), nothing waits for this pad by name.
--   2. StarterGui.Hud.JoinGroup: a HUD button whose JoinGroupScript called PromptJoinAsync(774196397) on click.
--      Script destroyed, button kept (styled by ui_30_hud) but hidden and inactive.
--   3. Kept but inert (other code/tests reference them): StarterGui.GroupReward (GUI.GroupReward() WaitForChild,
--      tests/suite_ui), Workspace.__OBJECTS.GroupReward.ProximityPrompt (asserted by GroupRewards), the
--      Elements.Right.Tools.GroupReward "FREE" button, ReplicatedStorage.Network["GroupReward: ClaimReward"].
--   4. Copy that told players to join the group ("Like & join the group to use codes!", "Like/Group").
-- Idempotent.

local Step = {}

local function hideGui(gui)
	if gui and gui:IsA("GuiObject") then
		gui.Visible = false
		if gui:IsA("GuiButton") then
			gui.Active = false
			gui.Selectable = false
		end
	end
end

local function findPath(root, path)
	local node = root
	for _, name in ipairs(string.split(path, ".")) do
		node = node and node:FindFirstChild(name)
	end
	return node
end

-- Plain-text substring replace (no Lua patterns: the texts carry rich-text tags and punctuation).
local function replacePlain(text, from, to)
	local out, start = {}, 1
	while true do
		local i, j = string.find(text, from, start, true)
		if not i then
			break
		end
		table.insert(out, string.sub(text, start, i - 1))
		table.insert(out, to)
		start = j + 1
	end
	table.insert(out, string.sub(text, start))
	return table.concat(out)
end

local TEXT_REWRITES = {
	{ ' & <font color="rgb(0, 255, 0)">join the group</font>', " the game" },
	{ " & join the group", " the game" },
	{ "Like/Group", "Like" },
}

function Step.Apply(place, _spPlace, _ctx)
	local ws = place:GetService("Workspace")
	local sg = place:GetService("StarterGui")
	local rs = place:GetService("ReplicatedStorage")
	local done = {}

	-- 1. The GroupReward pad at the stands.
	local pad = findPath(ws, "Stands.Pads.GroupReward")
	if pad then
		pad:Destroy()
		table.insert(done, "Stands.Pads.GroupReward removed")
	end

	-- 2. HUD JoinGroup button.
	local join = findPath(sg, "Hud.JoinGroup")
	if join then
		for _, d in ipairs(join:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				d:Destroy()
			end
		end
		hideGui(join)
		table.insert(done, "Hud.JoinGroup hidden, script removed")
	end

	-- 3. Entry points kept for references, but closed.
	local prompt = findPath(ws, "__OBJECTS.GroupReward.ProximityPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = false
	end
	hideGui(findPath(sg, "Elements.Right.Tools.GroupReward"))
	local window = sg:FindFirstChild("GroupReward")
	if window and window:IsA("LayerCollector") then
		window.Enabled = false
	end

	-- Flag any other group-join script left in the UI or the world (none known beyond JoinGroupScript).
	for _, root in ipairs({ sg, ws, place:GetService("StarterPlayer"), rs:FindFirstChild("Assets") }) do
		for _, d in ipairs(root and root:GetDescendants() or {}) do
			if d:IsA("LuaSourceContainer") and d.Name ~= "GroupRewards" then
				local ok, src = pcall(function()
					return d.Source
				end)
				if ok and string.find(src, "PromptJoinAsync", 1, true)  then
					print("[NoGroup] WARNING: unexpected join-group prompt in " .. d:GetFullName())
				end
			end
		end
	end

	-- 4. Copy.
	local rewritten = 0
	for _, root in ipairs({ sg, rs:FindFirstChild("Assets") }) do
		for _, d in ipairs(root and root:GetDescendants() or {}) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local text = d.Text
				local new = text
				for _, r in ipairs(TEXT_REWRITES) do
					new = replacePlain(new, r[1], r[2])
				end
				if new ~= text then
					d.Text = new
					rewritten += 1
				end
			end
		end
	end
	table.insert(done, rewritten .. " group texts rewritten")

	print("[NoGroup] " .. table.concat(done, "; "))
end

return Step
