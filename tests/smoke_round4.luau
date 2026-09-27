--!nocheck
-- tests/smoke_round4.luau (owner 2026-09-27, 4th pass). Joins the "smoke" filter. Checks:
--   1. the egg client cannot fail silently any more: a start-up watchdog names the step it waits on, the presentation
--      modules load in the background, a reconcile pass draws any egg that has no model, and it compiles with room to
--      spare under Luau's 200-local limit; EggHealthController reports from outside;
--   2. MenuMotionController: the egg / hero lists pop in, the HUD groups slide off their nearest edge under a menu
--      (sandboxed edge picks), and every group it moves exists in StarterGui;
--   3. the Egg and H tabs are further apart;
--   4. the speed shop's treadmill upgrade card draws the tiers' real models (every tier has one);
--   5. every moon / sun image carries the pixel-art layer and PixelNightIcon knows every moon art id.

local place = H.place()
local rs = place:GetService("ReplicatedStorage")
local sg = place:GetService("StarterGui")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts
local UDim2 = H.roblox.UDim2
local Vector2 = H.roblox.Vector2

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end

-- 1. egg client
local areaEggs = H.path(sps, "Game/AreaEggs")
local eggSrc = src(areaEggs)
T.check(H.has(eggSrc, "start-up still waiting after") and H.has(eggSrc, "setStartupStage(\"ready\")"),
	"AreaEggs must name the start-up step it is stuck on (watchdog)")
for _, name in ipairs({ "CarryRunBackEffects = reqDeferred(", "HoverHighlight = reqDeferred(", "RewardScreenTransition = reqDeferred(",
	"Message = reqDeferred(", "RareEggHighlight = reqDeferred(" }) do
	T.check(H.has(eggSrc, name), "AreaEggs must load %s in the background", string.match(name, "^(%w+)"))
end
for _, name in ipairs({ "EggCmds = req(", "EggRenderer = req(", "NestResolver = req(", "WorkspaceEggVisibility = req(" }) do
	T.check(H.has(eggSrc, name), "AreaEggs core module must stay a direct require: %s", name)
end
T.check(H.has(eggSrc, "local function reconcileRendered()") and H.has(eggSrc, "pcall(applyRecordNow, record)"),
	"AreaEggs must reconcile drawn eggs against EggCmds' records")
for _, level in ipairs({ 0, 1, 2 }) do
	T.check(pcall(H.luau.compile, eggSrc, { optimizationLevel = level }), "AreaEggs must compile at -O%d", level)
end
do
	local pad = {}
	for i = 1, 30 do
		table.insert(pad, "local __pad" .. i .. " = os.clock()")
	end
	T.check(pcall(H.luau.compile, table.concat(pad, "\n") .. "\n" .. eggSrc), "AreaEggs must keep headroom under the 200-local limit")
end
local health = H.path(sps, "BranchControllers/EggHealthController")
T.check(health ~= nil and H.has(src(health), "AreaEggsStage") and H.has(src(health), "AreaEggSlotsClient")
	and pcall(H.luau.compile, src(health)), "BranchControllers.EggHealthController must report the egg client's state")

-- 2. menus
local motion = H.path(sps, "BranchControllers/MenuMotionController")
if T.check(motion ~= nil, "BranchControllers.MenuMotionController missing") then
	local motionSrc = src(motion)
	T.check(pcall(H.luau.compile, motionSrc), "MenuMotionController does not compile")
	T.check(H.has(motionSrc, "GrowingEggList = \"Frame\"") and H.has(motionSrc, "PetList = \"Frame\""),
		"MenuMotionController must pop in the egg and hero lists")
	T.check(H.has(motionSrc, "AddOpenListener") and H.has(motionSrc, "AddCloseListener"), "MenuMotionController must follow TabController windows")
	local chunk, err = H.sandbox(motionSrc, {
		game = { GetService = function() return {} end },
		TweenInfo = { new = function() return {} end },
		Enum = H.roblox.Enum,
		UDim2 = UDim2,
	}, "MenuMotionController")
	if T.check(chunk ~= nil, "MenuMotionController sandbox: %s", tostring(err)) then
		local ok, controller = pcall(chunk)
		if T.check(ok and type(controller) == "table", "MenuMotionController did not load: %s", tostring(controller)) then
			local function obj(px, py, ax, ay, sx, sy)
				return { Position = UDim2.fromScale(px, py), AnchorPoint = Vector2.new(ax, ay), Size = UDim2.fromScale(sx or 0.1, sy or 0.1) }
			end
			T.check(controller._edgeOf(obj(0.01, 0.5, 0, 0.5)) == "left", "the Shop / Index column must leave by the left edge")
			T.check(controller._edgeOf(obj(0.99, 0.5, 1, 0.5)) == "right", "the Egg / H tabs must leave by the right edge")
			T.check(controller._edgeOf(obj(0.005, 1, 0, 1, 0.3, 0.12)) == "bottom", "the money / speed rows must leave by the bottom edge")
			T.check(controller._edgeOf(obj(0.5, 0.1, 0.5, 0)) == "top", "the night warning must leave by the top edge")
			for _, entry in ipairs(controller.HUD_GROUPS) do
				local gui = sg:FindFirstChild(entry[1])
				T.check(gui ~= nil and gui:FindFirstChild(entry[2]) ~= nil, "HUD group %s.%s missing", entry[1], entry[2])
			end
		end
	end
end
local branchManifest = H.fs.readFile("scripts/inject/branch.luau")
T.check(H.has(branchManifest, "MenuMotionController") and H.has(branchManifest, "EggHealthController"),
	"scripts/inject/branch.luau must inject the new controllers")

-- 3. tabs
local tabsLayout = H.path(sg, "Elements/Tabs")
tabsLayout = tabsLayout and tabsLayout:FindFirstChildOfClass("UIListLayout")
T.check(tabsLayout ~= nil and tabsLayout.Padding.Scale >= 0.12, "the Egg and H tabs must be further apart (gap %.2f)",
	tabsLayout and tabsLayout.Padding.Scale or -1)

-- 4. treadmill shop
local shop = H.path(sps, "GUI/Shop/TreadmillSpeedShop")
local shopSrc = src(shop)
T.check(H.has(shopSrc, "local function showTreadmillModel(icon, treadmillId)") and H.has(shopSrc, "Instance.new(\"ViewportFrame\")")
	and H.has(shopSrc, "pcall(showTreadmillModel, Pack.TreadmillIconCurrent, v37._id)")
	and H.has(shopSrc, "pcall(showTreadmillModel, Pack.TreadmillIconNext, v39._id)") and pcall(H.luau.compile, shopSrc),
	"the speed shop's treadmill card must show the tiers' real models")
local skins = H.path(rs, "Assets/Models/Treadmills")
local configs = H.path(rs, "Directory/Treadmills/_Index")
if T.check(skins ~= nil and configs ~= nil, "treadmill skins or configs missing") then
	for _, config in ipairs(configs:GetChildren()) do
		local skin = skins:FindFirstChild(config.Name)
		local folder = skin and skin:FindFirstChild("Model")
		T.check(folder ~= nil and folder:FindFirstChildWhichIsA("Model") ~= nil, "treadmill %s has no model for the shop viewport", config.Name)
	end
end

-- 5. moons
local template = H.path(rs, "Assets/UI/PixelIcons/SpPixelIcon")
T.check(template ~= nil and template.ClassName == "CanvasGroup" and template:FindFirstChild("Moon") ~= nil and template:FindFirstChild("Sun") ~= nil,
	"ReplicatedStorage.Assets.UI.PixelIcons.SpPixelIcon (Moon + Sun) missing")
for _, path in ipairs({ { sg, "ResetStartTimer/Frame/SleepIcon", "Moon" }, { sg, "ResetStartTimer/Frame/DayIcon", "Sun" },
	{ sg, "Elements/Tabs/GrowingEggs/NightImage", "Moon" }, { rs, "Assets/Billboards/NightEggTimeSkip/Main/Frame/ImageLabel", "Moon" } }) do
	local image = H.path(path[1], path[2])
	local layer = image and image:FindFirstChild("SpPixelIcon")
	local other = if path[3] == "Moon" then "Sun" else "Moon"
	T.check(image ~= nil and image:GetAttribute("PixelIcon") == true and layer ~= nil and layer:FindFirstChild(path[3]) ~= nil
		and layer:FindFirstChild(other) == nil, "%s must carry only the pixel %s layer", path[2], string.lower(path[3]))
end
local pixel = H.path(sps, "GUI/PixelNightIcon")
local pixelSrc = src(pixel)
for _, id in ipairs({ "131317614803230", "97443431423842", "86038047961937" }) do
	T.check(H.has(pixelSrc, id), "PixelNightIcon must know the moon / sun art %s", id)
end
T.check(H.has(pixelSrc, "GetAttribute(\"PixelIcon\")") and H.has(pixelSrc, "layer.GroupTransparency = image.ImageTransparency")
	and pcall(H.luau.compile, pixelSrc), "PixelNightIcon must drive the pixel layers and follow the scripts' fades")
