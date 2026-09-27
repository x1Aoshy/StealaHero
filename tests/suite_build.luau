--!nocheck
-- Build integrity: every script compiles, every injected source matches its file, no Speedster Escape
-- branding leaked into Steal a Hero.

local place = H.place()

-- 1. every script in the place compiles
local scripts, broken = 0, {}
for _, d in ipairs(place:GetDescendants()) do
	if d:IsA("LuaSourceContainer") then
		scripts += 1
		local ok, err = pcall(H.luau.compile, d.Source)
		if not ok then
			table.insert(broken, d:GetFullName() .. ": " .. string.sub(tostring(err), 1, 120))
		end
	end
end
T.check(scripts > 1000, "expected > 1000 scripts in the place, found %d", scripts)
T.check(#broken == 0, "%d script(s) fail to compile: %s", #broken, table.concat(broken, " | ", 1, math.min(#broken, 5)))

-- 2. every injection manifest entry landed with the exact file content
local manifests = 0
for _, fileName in ipairs(H.fs.readDir("scripts/inject")) do
	if string.sub(fileName, -5) == ".luau" then
		local path = "scripts/inject/" .. fileName
		local okLoad, entries = pcall(function()
			return H.luau.load(H.fs.readFile(path), { debugName = path })()
		end)
		if T.check(okLoad and type(entries) == "table", "%s: manifest does not load: %s", path, tostring(entries)) then
			for _, entry in ipairs(entries) do
				manifests += 1
				local segments = string.split(entry.target, "/")
				local node = place:GetService(segments[1])
				for i = 2, #segments do
					node = node and node:FindFirstChild(segments[i])
				end
				if T.check(node ~= nil, "%s: injected target %s is missing", path, entry.target) then
					T.check(node.ClassName == entry.class, "%s: %s is a %s, expected %s", path, entry.target, node.ClassName, tostring(entry.class))
					T.check(H.normalize(node.Source) == H.normalize(H.fs.readFile(entry.source)),
						"%s: %s Source differs from %s (rebuild the place)", path, entry.target, entry.source)
				end
			end
		end
	end
end
T.check(manifests >= 10, "expected >= 10 injection manifest entries, found %d", manifests)

-- 2b. gameplay controllers that scripts/build_stealahero.luau injects itself (not through a manifest): a build that
-- predates a src/ fix (e.g. AreaEggService's one-chase-per-stage rule) must not pass for current.
local DIRECT = {
	{ "ServerScriptService/NetworkInit", "src/ServerScriptService/NetworkInit.server.luau" },
	{ "ServerScriptService/Bootstrap", "src/ServerScriptService/Bootstrap.server.luau" },
	{ "ServerScriptService/Library/Database", "src/ServerScriptService/Library/Database.luau" },
	{ "ServerScriptService/Controllers/PlotService", "src/ServerScriptService/Controllers/PlotService.luau" },
	{ "ServerScriptService/Controllers/EggService", "src/ServerScriptService/Controllers/EggService.luau" },
	{ "ServerScriptService/Controllers/AreaEggService", "src/ServerScriptService/Controllers/AreaEggService.luau" },
	{ "ServerScriptService/Controllers/AssetService", "src/ServerScriptService/Controllers/AssetService.luau" },
	{ "ServerScriptService/Controllers/OfflineAssetsService", "src/ServerScriptService/Controllers/OfflineAssetsService.luau" },
	{ "ServerScriptService/Controllers/TreadmillGrindService", "src/ServerScriptService/Controllers/TreadmillGrindService.luau" },
	{ "StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GenericGuardRuntime", "src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/GenericGuardRuntime.luau" },
	{ "StarterPlayer/StarterPlayerScripts/Game/GuardAreas/ForestGuardRuntime", "src/StarterPlayer/StarterPlayerScripts/Game/GuardAreas/ForestGuardRuntime.luau" },
}
for _, entry in ipairs(DIRECT) do
	local segments = string.split(entry[1], "/")
	local node = place:GetService(segments[1])
	for i = 2, #segments do
		node = node and node:FindFirstChild(segments[i])
	end
	if T.check(node ~= nil and node:IsA("LuaSourceContainer"), "%s missing", entry[1]) and H.fs.isFile(entry[2]) then
		T.check(H.normalize(node.Source) == H.normalize(H.fs.readFile(entry[2])), "%s Source differs from %s (rebuild the place)", entry[1], entry[2])
	end
end

-- 3. core injected controllers are present
local sss = place:GetService("ServerScriptService")
for _, name in ipairs({ "PlotService", "EggService", "AreaEggService", "GuardChaseService", "AssetService", "TreadmillGrindService", "TreadmillSpawnService" }) do
	T.check(H.path(sss, "Controllers/" .. name) ~= nil, "expected ServerScriptService.Controllers.%s", name)
end
T.check(sss:FindFirstChild("GearService") ~= nil, "expected ServerScriptService.GearService (bat and traps)")

-- 4. the Speedster Escape game logo must not appear anywhere in Steal a Hero
local SPEEDSTER_ESCAPE_LOGO = 92044769924002
local logo = {}
for _, d in ipairs(place:GetDescendants()) do
	if d:IsA("ImageLabel") or d:IsA("ImageButton") then
		if H.imageId(d) == SPEEDSTER_ESCAPE_LOGO then
			table.insert(logo, d:GetFullName())
		end
	elseif d:IsA("Decal") or d:IsA("Texture") then
		if H.assetId(H.uri(d, "TextureContent")) == SPEEDSTER_ESCAPE_LOGO then
			table.insert(logo, d:GetFullName())
		end
	end
end
T.check(#logo == 0, "Speedster Escape logo found in: %s", table.concat(logo, ", "))

-- 5. TextScaled text must also wrap: Roblox renders TextScaled + TextWrapped=false at the fixed TextSize (tiny
--    text on the HUD and the hub signs). scripts/steps/ui_99_textwrap.luau restores the pair; the base place has none.
local unwrapped = {}
for _, d in ipairs(place:GetDescendants()) do
	if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.TextScaled and not d.TextWrapped then
		table.insert(unwrapped, d:GetFullName())
	end
end
T.check(#unwrapped == 0, "%d TextScaled label(s) with TextWrapped = false render at their tiny fixed TextSize: %s", #unwrapped,
	table.concat(unwrapped, ", ", 1, math.min(#unwrapped, 5)))
