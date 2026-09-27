--!nocheck
-- Quick smoke test (~50 checks): the contracts that break a play session. Owner 2026-09-23: run this, then compile;
-- the full suites (lune run tests/run_all_tests.luau) only for big structural passes or to diagnose a failure.
--   STEALAHERO_PLACE=<build> lune run tests/run_all_tests.luau smoke

local PLAN = H.PLAN
local Enum = H.roblox.Enum
local place = H.place()
local ws = place:GetService("Workspace")
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local sg = place:GetService("StarterGui")
local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

local function missing(root, names)
	local out = {}
	for _, name in ipairs(names) do
		if root == nil or root:FindFirstChild(name) == nil then
			table.insert(out, name)
		end
	end
	return out
end

local function list(t)
	return table.concat(t, ", ", 1, math.min(#t, 6))
end

-- 1. injected scripts landed and compile (every manifest entry)
local broken, injected = {}, 0
for _, fileName in ipairs(H.fs.readDir("scripts/inject")) do
	if string.sub(fileName, -5) == ".luau" then
		local ok, entries = pcall(function()
			return H.luau.load(H.fs.readFile("scripts/inject/" .. fileName))()
		end)
		for _, entry in ipairs(ok and entries or {}) do
			injected += 1
			local node = place:GetService(string.split(entry.target, "/")[1])
			for i, seg in ipairs(string.split(entry.target, "/")) do
				if i > 1 then
					node = node and node:FindFirstChild(seg)
				end
			end
			local okCompile = node ~= nil and pcall(H.luau.compile, node.Source)
			if not okCompile then
				table.insert(broken, entry.target)
			end
		end
	end
end
T.check(injected >= 20, "expected >= 20 injected scripts, found %d", injected)
T.check(#broken == 0, "injected scripts missing or not compiling: %s", list(broken))

-- 2. core server services
local services = missing(sss, { "GearService", "LeaderboardService" })
for _, name in ipairs(missing(sss:FindFirstChild("Controllers"), { "AreaEggService", "GuardChaseService", "EggService", "AssetService" })) do
	table.insert(services, "Controllers." .. name)
end
T.check(#services == 0, "missing server services: %s", list(services))
T.check(H.path(sss, "Library/Database") ~= nil and H.path(sss, "Library/Tools") ~= nil, "ServerScriptService.Library.Database / Tools missing")

-- 3. heroes: every roster hero has a model, a config and an egg
local assetModels = rs:FindFirstChild("AssetModels")
local configs = H.path(rs, "Directory/Assets/_Index")
local eggs = H.path(rs, "Assets/Models/Eggs")
local noModel, noConfig, noEgg, notR15, noHead = {}, {}, {}, {}, {}
for _, hero in ipairs(PLAN.HEROES) do
	local id = hero[1]
	local model = assetModels and assetModels:FindFirstChild(id)
	if model == nil then
		table.insert(noModel, id)
	else
		-- AssetModels animate through an AnimationController; a Humanoid exists only to render classic clothing
		local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
		if (humanoid ~= nil and humanoid.RigType ~= Enum.HumanoidRigType.R15) or model:FindFirstChild("UpperTorso", true) == nil
			or model:FindFirstChild("LeftFoot", true) == nil or model:FindFirstChild("Torso", true) ~= nil then
			table.insert(notR15, id)
		end
		if model:FindFirstChild("Head", true) == nil or model:FindFirstChild("HumanoidRootPart", true) == nil then
			table.insert(noHead, id)
		end
	end
	if configs == nil or configs:FindFirstChild(id) == nil then
		table.insert(noConfig, id)
	end
	if eggs == nil or eggs:FindFirstChild(id) == nil then
		table.insert(noEgg, id)
	end
end
T.check(#PLAN.HEROES == 38, "plan roster must list 38 heroes, found %d", #PLAN.HEROES)
T.check(#noModel == 0, "heroes without ReplicatedStorage.AssetModels model: %s", list(noModel))
T.check(#notR15 == 0, "hero models that are not R15: %s", list(notR15))
T.check(#noHead == 0, "hero models without Head / HumanoidRootPart: %s", list(noHead))
T.check(#noConfig == 0, "heroes without Directory.Assets._Index config: %s", list(noConfig))
T.check(#noEgg == 0, "heroes without Assets.Models.Eggs egg: %s", list(noEgg))
T.check(rs:FindFirstChild("HeroCatalog", true) ~= nil, "HeroCatalog module missing")

-- 4. stages: villains, egg spots, gates, lighting presets
local guardAreas = H.path(ws, "__OBJECTS/Areas/GuardAreas")
local stageProblems = {}
for _, stage in ipairs(PLAN.STAGES) do
	local zone = guardAreas and guardAreas:FindFirstChild(stage.key)
	local guard = zone and zone:FindFirstChild("Guard")
	if guard == nil or guard:FindFirstChildWhichIsA("Humanoid", true) == nil then
		table.insert(stageProblems, stage.key .. ": no villain rig")
	end
	local env = H.path(ws, "StageEnvironments/" .. stage.key)
	local spots = env and env:FindFirstChild("EggSpots")
	if spots == nil or #spots:GetChildren() ~= stage.spots then
		table.insert(stageProblems, stage.key .. ": EggSpots")
	end
	if env == nil or env:FindFirstChild("VillainPost") == nil then
		table.insert(stageProblems, stage.key .. ": VillainPost")
	end
	if H.path(ws, "Hub/StageGates/StageGate_" .. stage.number) == nil then
		table.insert(stageProblems, "StageGate_" .. stage.number)
	end
end
T.check(#stageProblems == 0, "stage problems: %s", list(stageProblems))
T.check(guardAreas ~= nil and guardAreas:FindFirstChild("Abyss Ocean") == nil, "retired zones must stay removed")
T.check(H.path(ws, "Hub/ProgressionBoard") == nil, "the STAGES progression board must stay removed")
local signed = {}
for _, gate in ipairs(H.path(ws, "Hub/StageGates") and H.path(ws, "Hub/StageGates"):GetChildren() or {}) do
	if gate:FindFirstChildWhichIsA("SurfaceGui", true) then
		table.insert(signed, gate.Name)
	end
end
T.check(#signed == 0, "stage gates must carry no signs: %s", list(signed))
T.check(rs:FindFirstChild("Archived_ProceduralEnvironments") ~= nil, "scratch-layout archive missing")

-- 5. hub
T.check(H.path(ws, "Hub/FreeGift/ClaimSign") ~= nil and H.path(ws, "Hub/FreeGift/GiftChest") ~= nil, "Free Gift board / chest missing")
-- HEROBOARD 2026-09-26: one wall-mounted HERO BOARD with a page per stat (details: tests/smoke_heroboard.luau)
local heroPages = H.path(ws, "Hub/HeroBoard/Screen/BoardGui/Board/List/Pages")
local mislabelled = {}
for _, stat in ipairs({ "Networth", "SpeedPower", "TimePlayed", "EggsHatched" }) do
	local page = heroPages and heroPages:FindFirstChild("Page_" .. stat)
	if not (page and page:GetAttribute("LeaderboardStat") == stat) then
		table.insert(mislabelled, "Page_" .. stat)
	end
end
T.check(heroPages ~= nil and #mislabelled == 0 and H.path(ws, "__OBJECTS/Leaderboards") == nil,
	"hub HERO BOARD pages (NETWORTH / SPEED / IN-GAME TIME / EGGS HATCHED) missing, or the old boards are back: %s", list(mislabelled))
T.check(H.path(ws, "Stands/Models/Sell Stands") ~= nil and H.path(ws, "Stands/Models/GearShopStand") ~= nil, "Sell / Trails stalls missing")
T.check(ws:FindFirstChild("GearGivers") == nil, "no gear lying on the lobby floor (GearGivers must stay removed)")
T.check(#(ws:FindFirstChild("Plots") and ws.Plots:GetChildren() or {}) == 6, "expected 6 plots")
T.check(ws:FindFirstChild("SpawnLocation", true) ~= nil, "SpawnLocation missing")

-- 6. gear
local shop = H.path(rs, "GearTools/ShopItems")
T.check(#missing(shop, PLAN.STARTER_GEAR) == 0, "starter gear tools missing: %s", list(missing(shop, PLAN.STARTER_GEAR)))

-- 7. UI
local guis = missing(sg, { "Elements", "Money", "GroupReward", "AutoSell", "Index", "SpeedPhone", "TreadmillTrainingHud", "BackpackGui" })
T.check(#guis == 0, "StarterGui windows missing: %s", list(guis))
T.check(H.path(sg, "Elements/Left/Tools/Shop") ~= nil and H.path(sg, "Elements/Left/Tools/Index") ~= nil, "Shop / Index sidebar buttons missing")
T.check(H.path(sg, "Elements/Tabs/GrowingEggs") ~= nil and H.path(sg, "Elements/Tabs/Pets") ~= nil, "EGGS / HERO INDEX tabs missing")
T.check(H.path(sg, "Money/Bottom/Frame/Money") ~= nil and H.path(sg, "Money/Bottom/Frame/SpeedValue") ~= nil, "currency rows missing")
T.check(sg:FindFirstChild("TreadmillVideoSurfaceGui") == nil, "the TikTok video player must stay removed")
local unwrapped = 0
for _, d in ipairs(place:GetDescendants()) do
	if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.TextScaled and not d.TextWrapped then
		unwrapped += 1
	end
end
T.check(unwrapped == 0, "%d TextScaled labels without TextWrapped (render tiny in Roblox)", unwrapped)

-- 8. client scripts
local clients = missing(sps and sps:FindFirstChild("Game"), { "VillainChaseFx", "StageAmbience", "HubFreeGift" })
T.check(#clients == 0, "client scripts missing: %s", list(clients))
T.check(H.path(sps, "GUI/SpeedPhone") ~= nil and H.path(sps, "GUI/SellHeroes") ~= nil, "SpeedPhone / SellHeroes client scripts missing")
local fx = H.path(sps, "Game/VillainChaseFx")
T.check(fx ~= nil and not H.has(fx.Source, "IS CHASING YOU"), "the chase banner / safe-zone meter must stay removed")

-- 9. audio whitelist + branding
local WHITELIST = { ["77120543307812"] = true, ["72264591133889"] = true, ["127039883737564"] = true, ["136993031050456"] = true, ["80736831159506"] = true }
local badSounds = {}
for _, d in ipairs(place:GetDescendants()) do
	if d:IsA("Sound") then
		local id = H.assetId(H.uri(d, "AudioContent"))
		if id and not WHITELIST[tostring(id)] then
			table.insert(badSounds, d:GetFullName())
		end
	elseif (d:IsA("ImageLabel") or d:IsA("ImageButton")) and H.imageId(d) == 92044769924002 then
		table.insert(badSounds, "Speedster Escape logo at " .. d:GetFullName())
	end
end
T.check(#badSounds == 0, "non-whitelisted sounds / banned logo: %s", list(badSounds))

-- 10. SpeedPhone on the treadmill screen (PHONE 2026-09-23): one PhoneScreen per skin where the video screen was,
-- Front face toward the runner, with the idle HERO FLAP SurfaceGui; the phone script adorns it
local badScreens = {}
for _, tool in ipairs(H.path(rs, "Assets/Models/Treadmills") and H.path(rs, "Assets/Models/Treadmills"):GetChildren() or {}) do
	local screen, root = tool:FindFirstChild("PhoneScreen"), tool:FindFirstChild("Root")
	local idle = screen and screen:FindFirstChild("IdleScreen")
	if not (screen and screen:IsA("BasePart") and root and screen.Anchored and not screen.CanCollide and screen.CanQuery
		and screen.CFrame.LookVector:Dot(root.CFrame.LookVector) < -0.99) then
		table.insert(badScreens, tool.Name)
	elseif not (idle and idle:IsA("SurfaceGui") and idle.Face == Enum.NormalId.Front) then
		table.insert(badScreens, tool.Name .. " (IdleScreen)")
	end
end
T.check(#badScreens == 0, "treadmill skins without a proper PhoneScreen: %s", list(badScreens))
local phoneSrc = H.path(sps, "GUI/SpeedPhone") and H.path(sps, "GUI/SpeedPhone").Source or ""
T.check(H.has(phoneSrc, "\"PhoneScreen\"") and H.has(phoneSrc, "SurfaceGui") and H.has(phoneSrc, ".Adornee = part") and H.has(phoneSrc, "hitsPhoneScreen"),
	"SpeedPhone must render on the treadmill's PhoneScreen (PlayerGui SurfaceGui + Adornee + raycast taps)")
T.check(H.has(phoneSrc, "BindActionAtPriority") and H.has(phoneSrc, "Enum.KeyCode.ButtonY") and H.has(phoneSrc, "slideIn2D"),
	"SpeedPhone must keep Space / ButtonA / ButtonY controls and the 2D fallback")

-- 11. topbar icons (TOPBAR, owner report 2026-09-23: the backpack InventoryIcon and the settings gear vanished)
local settingsLs, backpackLs = H.path(sps, "GUI/Settings"), H.path(sps, "GUI/BackpackController")
local backpackMain = backpackLs and backpackLs:FindFirstChild("Main")
local function liveLocalScript(ls)
	local ok, disabled = pcall(function()
		return ls.Disabled
	end)
	return ls ~= nil and ls:IsA("LocalScript") and not (ok and disabled)
end
T.check(liveLocalScript(settingsLs) and liveLocalScript(backpackLs) and backpackMain ~= nil
	and H.path(rs, "Library/Modules/Packages/_Index/1foreverhd_topbarplus@3.2.5/topbarplus") ~= nil
	and H.has(settingsLs.Source, "TopBarPlus.new()") and H.has(backpackMain.Source, "setName(\"InventoryIcon\")"),
	"topbar icon owners (GUI.Settings gear, BackpackController InventoryIcon) or the TopbarPlus package missing / disabled")
local topbarHiders = {}
for fullName, src in pairs(H.allSources()) do
	if not H.has(fullName, "1foreverhd_topbarplus")
		and (H.has(src, "GUI.TopBarStandard()") or H.has(src, "setTopbarEnabled(") or H.has(src, "\"TopbarEnabled\", false")) then
		table.insert(topbarHiders, fullName)
	end
end
T.check(#topbarHiders == 0, "scripts hiding the TopbarPlus container (takes both topbar icons with it): %s", list(topbarHiders))
local juiceLs = H.path(sps, "GUI/SpeedstersJuice")
T.check(juiceLs ~= nil and H.has(juiceLs.Source, "Icon.setDisplayOrder(") and H.has(juiceLs.Source, "topbar icons not all shown"),
	"SpeedstersJuice must lift the TopbarPlus containers above the HUD (DisplayOrder 0 in 3.2.5) and audit the two icons")

-- 12. nothing of the skin in front of the PhoneScreen (SCREEN 2026-09-23, owner: "una part que tapa todo": the old
-- video set's frame slab, a plain "Part" in 9 skins, stood 1.29 studs in front of the screen). Visible block parts
-- whose corners fall in the box the screen face sweeps 3 studs toward the runner (MeshParts: see the build log).
local blockers = {}
for _, tool in ipairs(H.path(rs, "Assets/Models/Treadmills") and H.path(rs, "Assets/Models/Treadmills"):GetChildren() or {}) do
	local screen = tool:FindFirstChild("PhoneScreen")
	if screen and screen:IsA("BasePart") then
		local S, half = screen.CFrame, screen.Size / 2
		for _, d in ipairs(tool:GetDescendants()) do
			if d:IsA("BasePart") and d ~= screen and not d:IsA("MeshPart") and d.Transparency < 0.99 then
				local lo, hi = nil, nil
				for _, c in ipairs({ -1, 1 }) do
					for _, e in ipairs({ -1, 1 }) do
						for _, f in ipairs({ -1, 1 }) do
							local p = S:PointToObjectSpace(d.CFrame * H.roblox.Vector3.new(c * d.Size.X / 2, e * d.Size.Y / 2, f * d.Size.Z / 2))
							lo, hi = lo and lo:Min(p) or p, hi and hi:Max(p) or p
						end
					end
				end
				if hi.X > -half.X + 0.05 and lo.X < half.X - 0.05 and hi.Y > -half.Y + 0.05 and lo.Y < half.Y - 0.05
					and lo.Z < -half.Z - 0.01 and hi.Z > -half.Z - 3 then
					table.insert(blockers, tool.Name .. "." .. d:GetFullName():sub(#tool:GetFullName() + 2))
				end
			end
		end
	end
end
T.check(#blockers == 0, "visible parts in front of a treadmill PhoneScreen (hide the phone): %s", list(blockers))

-- 13. villain cold start (CHASE 2026-09-23, "the first chase is dumb"): clients preload the chase animations the server
-- plays (same ids), and the server warms every stage's navmesh and re-primes the tracks at startup
local preloader, chaseSvc = H.path(sps, "Game/AssetPreloader"), H.path(sss, "Controllers/GuardChaseService")
local chaseIds = {}
for id in string.gmatch(chaseSvc and string.match(chaseSvc.Source, "local ANIMATION_IDS = (%b{})") or "", "rbxassetid://(%d+)") do
	table.insert(chaseIds, id)
end
local unloaded = {}
for _, id in ipairs(chaseIds) do
	if not (preloader and H.has(preloader.Source, "rbxassetid://" .. id)) then
		table.insert(unloaded, id)
	end
end
T.check(preloader ~= nil and preloader:IsA("LocalScript") and H.has(preloader.Source, "PreloadAsync") and #chaseIds == 3 and #unloaded == 0,
	"Game.AssetPreloader must PreloadAsync every GuardChaseService chase animation (missing: %s)", list(unloaded))
T.check(chaseSvc ~= nil and H.has(chaseSvc.Source, "task.spawn(warmUpPaths") and H.has(chaseSvc.Source, "pcall(primeTracks")
	and H.has(chaseSvc.Source, "resumeWaypointIndex(g, waypoints)"), "GuardChaseService must warm the navmesh and prime its tracks at startup")

-- 14. Hide Your Heroes (HIDE 2026-09-23, owner: "Add a Hide Your Pets menu to settings"): new setting key HideMyPets
-- (row cloned by GUI.Settings), the old Disable Videos row renamed without changing its key (SpeedPhone reads it),
-- and the own-hero hide path wired through ActiveAssetsController, AssetComponent (faces/effects) and SabVfx auras.
local sharedVars, settingsGui = H.path(rs, "Library/Shared/Variables"), H.path(sps, "GUI/Settings")
T.check(sharedVars ~= nil and H.has(sharedVars.Source, "HideMyPets = {") and H.has(sharedVars.Source, "\"Hide Your Heroes\"")
	and H.has(sharedVars.Source, "DisableVideos = {") and H.has(sharedVars.Source, "\"Hide Treadmill Phone\"")
	and settingsGui ~= nil and H.has(settingsGui.Source, "registerSettingRow(\"HideMyPets\")") and H.has(settingsGui.Source, "\"Hide Treadmill Phone\""),
	"Settings must list Hide Your Heroes (HideMyPets) and rename the DisableVideos row to Hide Treadmill Phone (key kept)")
local aacSrc = H.path(sps, "Game/Plots/ActiveAssetsController")
local compSrc = H.path(sps, "Game/Plots/ActiveAssetsController/AssetComponent")
local sabSrc = H.path(sps, "Game/SabVfxController")
T.check(aacSrc ~= nil and H.has(aacSrc.Source, "property == \"HideMyPets\"") and H.has(aacSrc.Source, "shouldHideComponent(p3)")
	and compSrc ~= nil and H.has(compSrc.Source, "p0:IsA(\"Decal\")") and sabSrc ~= nil and H.has(sabSrc.Source, "\"HideMyPets\""),
	"Hide Your Heroes must hide own heroes (ActiveAssetsController), their faces/effects (AssetComponent) and auras (SabVfxController)")

-- 15. Trails shop (TRAILS 2026-09-23, owner: "Trails unpurchasable, needs fixing"): a server Script answers the four
-- Trails remotes after StubService's "Not available" placeholders, and every trail config has the BasePart asset
-- (weld + Trail) that Game.TrailController clones onto the HumanoidRootPart
local trailSvc = H.path(sss, "TrailService")
T.check(trailSvc ~= nil and trailSvc:IsA("Script") and H.has(trailSvc.Source, "\"Trails: RequestPurchase\"")
	and H.has(trailSvc.Source, "\"Trails: RequestSelect\"") and H.has(trailSvc.Source, "\"Trails: RequestUnequip\"")
	and H.has(trailSvc.Source, "\"Trails: RequestActiveSnapshot\"") and H.has(trailSvc.Source, "pcall(require, stub)")
	and H.has(trailSvc.Source, "FireAllClients(player, active)") and H.has(H.path(sps, "Game/TrailController") and H.path(sps, "Game/TrailController").Source, "tonumber(k)"),
	"ServerScriptService.TrailService must bind the Trails remotes after StubService and broadcast ActiveTrailChanged (TrailController: tonumber keys)")
local trailIndex, trailAssets, badTrails = H.path(rs, "Directory/Trails/_Index"), H.path(rs, "Assets/Trails"), {}
for _, cfg in ipairs(trailIndex and trailIndex:GetChildren() or {}) do
	local asset = trailAssets and trailAssets:FindFirstChild(cfg.Name)
	if not (asset and asset:IsA("BasePart") and asset:FindFirstChild("MainPartTrailWeldConstraint") and asset:FindFirstChildWhichIsA("Trail", true)) then
		table.insert(badTrails, cfg.Name)
	end
end
T.check(trailIndex ~= nil and #trailIndex:GetChildren() >= 10 and #badTrails == 0,
	"trail configs without a BasePart asset + MainPartTrailWeldConstraint + Trail in ReplicatedStorage.Assets.Trails: %s", list(badTrails))

-- 16. selling (SELL 2026-09-23, owner: "Implement Selling"): heroes AND eggs sell through one validated, rate-limited,
-- atomic server path (AssetService.applySale: keeps placed / favorited / fusing heroes and growing eggs), and the Sell
-- Heroes window + the sell stall both use it
local assetSvcSrc = H.path(sss, "Controllers/AssetService") and H.path(sss, "Controllers/AssetService").Source or ""
T.check(H.has(assetSvcSrc, "local function applySale(") and H.has(assetSvcSrc, "listHas(profile.FusionSlots, uid)")
	and H.has(assetSvcSrc, "profile.EggInventory[uid] = nil") and H.has(assetSvcSrc, "SELL_COOLDOWN") and H.has(assetSvcSrc, "\"HeroSellMultiplier\""),
	"AssetService must sell heroes and eggs through applySale (exclusions, rate limit, published sell multipliers)")
local sellUiLs, sellerLs = H.path(sps, "GUI/SellHeroes"), H.path(sps, "Game/Npcs/AssetSellerNpc")
T.check(sellUiLs ~= nil and sellerLs ~= nil and H.has(sellUiLs.Source, "{ Eggs = chunk }") and H.has(sellUiLs.Source, "local function eggIconFor(")
	and H.has(sellerLs.Source, "{ Eggs = { t1.uid } }") and not H.has(sellerLs.Source, "Eggs can't be sold"),
	"Sell Heroes window / sell stall must sell heroes and eggs through ActiveAssets: RequestSell")

-- NIGHT (2026-09-23, owner: "Make Night tp you back to spawn"): the night reset ends the carries of the players still
-- out in the stages (before the nests are reshuffled), locks new steals, moves them home and cues their client
local aesNightSrc = H.path(sss, "Controllers/AreaEggService") and H.path(sss, "Controllers/AreaEggService").Source or ""
local prepAt, resetAt, runAt = string.find(aesNightSrc, "pcall(prepareNightTeleports)", 1, true), string.find(aesNightSrc, "pcall(resetAllNests)", 1, true),
	string.find(aesNightSrc, "pcall(runNightTeleports, homeBound)", 1, true)
T.check(prepAt ~= nil and resetAt ~= nil and runAt ~= nil and prepAt < resetAt and resetAt < runAt
	and H.has(aesNightSrc, "\"Eggs: NightTeleport\"") and H.has(aesNightSrc, "endCarryAndReturn(player, \"NightReset\")")
	and H.has(aesNightSrc, "(nightTeleportUntil[player] or 0) > os.clock()") and H.has(aesNightSrc, "character:PivotTo(target)"),
	"AreaEggService night reset must end carries, then reshuffle, then send the players out in the stages home")
local nightCueLs = H.path(sps, "GUI/NightTeleportCue")
T.check(nightCueLs ~= nil and nightCueLs:IsA("LocalScript") and H.has(nightCueLs.Source, "\"Eggs: NightTeleport\"")
	and H.has(nightCueLs.Source, "ON_CLIENT_TELEPORT_COMPLETED") and not H.has(nightCueLs.Source, "Instance.new(\"Sound\")"),
	"GUI.NightTeleportCue must handle Eggs: NightTeleport (fade, toast, wall collision hand-off) without sounds")

-- 14. hatch + egg icons (HATCH 2026-09-23): the egg hatch no longer flings the EggExplode brick shards (particles on
-- built-in rbxasset textures only), and Directory.EggIcons lists every roster hero (0 = generic egg image) for the
-- backpack / hotbar egg slots, which resolve their icon through it
local hatchAnim = H.path(rs, "Library/Client/Eggs/EggHatchAnimation")
T.check(hatchAnim ~= nil and H.has(hatchAnim.Source, "hatchSparkleBurst") and not H.has(hatchAnim.Source, "ApplyImpulse")
	and not H.has(hatchAnim.Source, "EggExplode:Clone()") and H.has(hatchAnim.Source, "rbxasset://textures/particles/"),
	"EggHatchAnimation must hatch without the EggExplode brick-shard burst (particles only)")
local eggIconsModule, backpackMain, noEggIcon = H.path(rs, "Directory/EggIcons"), H.path(sps, "GUI/BackpackController/Main"), {}
local okEggIcons, eggIcons = pcall(function()
	return H.luau.load(eggIconsModule.Source)()
end)
for _, hero in ipairs(PLAN.HEROES) do
	if not (okEggIcons and type(eggIcons) == "table" and type(eggIcons.Ids) == "table" and eggIcons.Ids[hero[1]] ~= nil) then
		table.insert(noEggIcon, hero[1])
	end
end
T.check(okEggIcons and #noEggIcon == 0 and backpackMain ~= nil and H.has(backpackMain.Source, "resolveEggIcon(p59.AssetCategory")
	and H.has(backpackMain.Source, "resolveEggIcon(v1091.AssetCategory"),
	"Directory.EggIcons must list every roster hero and BackpackController.Main must resolve egg icons through it (missing: %s)", list(noEggIcon))

-- 18. Hero Flap FULL SCREEN + TOP PLAYERS (FLAPPY 2026-09-23): the template nodes SpeedPhone drives, and the server's
-- validated leaderboard (OrderedDataStore FlappyBest_v1, score-rate ceiling, rate limit)
do
	local flapGui, flapMissing = H.path(sg, "SpeedPhone"), {}
	for _, p in ipairs({ "FullscreenBackdrop", "FullscreenExit", "FullscreenButton", "Phone/Bezel/Screen/FullscreenToggle",
		"Phone/Bezel/Screen/Game/LeaderboardScreen/List/Row10/Score", "Phone/Bezel/Screen/Game/LeaderboardScreen/BackButton",
		"Phone/Bezel/Screen/Game/StartScreen/TopButton", "Phone/Bezel/Screen/Game/GameOverScreen/TopButton",
		"Phone/Bezel/Screen/Game/GameOverScreen/Rank" }) do
		if H.path(flapGui, p) == nil then
			table.insert(flapMissing, p)
		end
	end
	local flapSrc = H.path(sps, "GUI/SpeedPhone") and H.path(sps, "GUI/SpeedPhone").Source or ""
	T.check(#flapMissing == 0 and H.has(flapSrc, "function setFullscreen(") and H.has(flapSrc, "Enum.KeyCode.ButtonX")
		and H.has(flapSrc, "\"Flappy: SubmitScore\"") and H.has(flapSrc, "surfacePointAt("),
		"SpeedPhone full screen / TOP PLAYERS missing (template nodes: %s)", list(flapMissing))
	local flappySvc = H.path(sss, "FlappyService")
	T.check(flappySvc ~= nil and flappySvc:IsA("Script") and H.has(flappySvc.Source, "\"FlappyBest_v1\"")
		and H.has(flappySvc.Source, "GetOrderedDataStore") and H.has(flappySvc.Source, "MAX_POINTS_PER_SECOND")
		and H.has(flappySvc.Source, "MIN_SUBMIT_INTERVAL") and H.has(flappySvc.Source, "OnServerInvoke"),
		"ServerScriptService.FlappyService must keep the validated Hero Flap leaderboard (FlappyBest_v1, score-rate ceiling, rate limit)")
end

-- 20. Balancing (owner approved 2026-09-23): treadmill prices strictly rise with the level, only the first is free;
--     the free gift gives 1K Speed; base upgrade costs match between the client directory and PlotService.
do
	local treadmills = H.path(rs, "Directory/Treadmills/_Index")
	local prices = {}
	for _, m in ipairs(treadmills and treadmills:GetChildren() or {}) do
		if m:IsA("ModuleScript") then
			local price = tonumber(string.match(m.Source, "\n%s*Price = ([%d%.e]+)"))
			table.insert(prices, { m.Name, price or -1 })
		end
	end
	table.sort(prices, function(a, b) return a[2] < b[2] end)
	local zero = 0
	for _, p in ipairs(prices) do if p[2] == 0 then zero += 1 end end
	T.check(#prices == 10 and zero == 1 and prices[1][1] == "Treadmill" and prices[#prices][1] == "AngelicTreadmill",
		"treadmill price ladder broken (%d tiers, %d free, first %s, last %s)", #prices, zero, prices[1] and prices[1][1] or "?", prices[#prices] and prices[#prices][1] or "?")
	local reward = H.path(rs, "Library/Types/GroupReward")
	local plot = H.path(sss, "Controllers/PlotService")
	local bases = H.path(rs, "Directory/Bases")
	T.check(reward ~= nil and H.has(reward.Source, "return 1000.0") and plot ~= nil and H.has(plot.Source, "[2] = { Cost = 400000,")
		and bases ~= nil and string.find(bases.Source, "\n%s*400000%.0,") ~= nil,
		"balance: free gift 1K / base level-2 cost 400K (50M /125, ECON 2026-09-24) not applied on both sides")
end

-- 21. Balancing, chase (owner approved 2026-09-23): stage 4-6 villain speeds and the far-side spawn rule (#7) on the
--     server and in the RequiredSpeedSign scenario.
do
	local guardIndex = H.path(rs, "Directory/Guards/_Index")
	local speeds = {}
	for key, expected in pairs({ Jungle = 88, Snow = 102, Volcano = 122 }) do
		local m = guardIndex and guardIndex:FindFirstChild(key)
		local speed = m and tonumber(string.match(m.Source, "\n%s*WalkSpeed = ([%d%.]+)"))
		if speed ~= expected then
			table.insert(speeds, key .. "=" .. tostring(speed))
		end
	end
	T.check(#speeds == 0, "villain WalkSpeed balance not applied: %s", list(speeds))
	local chase = H.path(sss, "Controllers/GuardChaseService")
	local sign = H.path(sps, "Game/GuardAreas/GuardEscapeSignController")
	T.check(chase ~= nil and H.has(chase.Source, "and current.X >= carrier.X then") and sign ~= nil and H.has(sign.Source, "postOnFarSide"),
		"far-side egg spawn rule (#7) missing from GuardChaseService / GuardEscapeSignController")
end

-- 22. UI revamp (Gekko pass 2026-09-24): UI revamp (Gekko 2026-09-24, owner UI): every window shares the Free Gift / Sell Heroes look (scripts/lib/ui_kit.luau, scripts/steps/ui_50_revamp.luau): a glossy SpHeaderBand + dark studded body, every round X Close stay
do
	local noLook, badClose, twoIcons = {}, {}, {}
	for _, path in ipairs({ "GroupReward/FrameReward", "AutoSell/Frame", "Index/Index", "Shop/Frame", "TreadmillSpeedShop/Frame",
		"TrailShop/Main", "TreadmillShop/Main", "GearShop/Main", "Settings/Frame", "Codes/Frame", "FuseMachine/Main/FuseMachine",
		"TradeWindow/Frame", "TradePlayerList/Frame", "PetList/Frame", "GrowingEggList/Frame", "Odds_UI/Frame", "Rebirth/Rebirth",
		"Message/Frame", "StealDnaMessage/Frame", "OfflineCashOnly/Frame", "LimitedStarterPackOffer/Frame", "FreeGifts/Frame" }) do
		local root = H.path(sg, path)
		local band = root and root:FindFirstChild("SpHeaderBand")
		if band == nil or band:FindFirstChild("SpBandGradient") == nil or root:FindFirstChild("SpStuds", true) == nil then
			table.insert(noLook, path)
		end
		-- (the PetList / GrowingEggList drawers close with their ">" tab: a TextButton + TextLabel)
		local drawer = path == "PetList/Frame" or path == "GrowingEggList/Frame"
		local close = root and not drawer and root:FindFirstChild("Close")
		if close and not (close:IsA("GuiButton") and close:FindFirstChild("TextButton") ~= nil and close.TextButton:IsA("ImageLabel")) then
			table.insert(badClose, path)
		end
		local tagged = 0
		for _, d in ipairs(root and root:GetDescendants() or {}) do
			if d:GetAttribute("SpHeaderIcon") == true then
				tagged += 1
			end
		end
		if tagged > 1 then
			table.insert(twoIcons, path)
		end
	end
	T.check(H.fs.isFile("scripts/lib/ui_kit.luau") and #noLook == 0, "windows without the studded glossy look (SpHeaderBand + studs): %s", list(noLook))
	T.check(#badClose == 0, "window Close buttons broke the TabController / ConsoleCmds contract: %s", list(badClose))
	T.check(#twoIcons == 0, "windows with more than one SpHeaderIcon bounce target (a hidden one may bounce): %s", list(twoIcons))
	local clipped = {}
	for _, name in ipairs({ "TrailShop", "TreadmillShop" }) do
		local listFrame = H.path(sg, name .. "/Main/ShopContent/List")
		local grid = listFrame and H.path(listFrame, "ScrollingFrame/UIGridLayout")
		-- base layout: cells 0.31 wide in a 0.875 tall list just fit; the ratio may not grow
		if grid == nil or grid.CellSize.X.Scale / math.max(listFrame.Size.Y.Scale, 0.01) > 0.355 then
			table.insert(clipped, name)
		end
	end
	T.check(#clipped == 0, "stall shop cards taller than their list (bottom clipped): %s", list(clipped))
	local index = H.path(sg, "Index/Index")
	local sell = H.path(sg, "AutoSell/Frame")
	T.check(index ~= nil and H.path(index, "Content/IndexPage/IndexListFrame/IndexEntries/Template/Frame/SpStageFallback") ~= nil
		and H.path(index, "Title/TextLabel") ~= nil and index.Title.TextLabel.Text == "Hero Index"
		and sell ~= nil and sell:GetAttribute("SellHeroesWindow") == true,
		"Index (stage cards, band title) / Sell Heroes window contract broken by the UI revamp")
end

-- 23. Bat + egg carrier (Gekko pass 2026-09-24): COMBAT (Gekko TO DO 2 + 3, 2026-09-24): bat swing with a contact-moment hit + feedback, smoother ragdoll, carrier rules (no tools / no treadmill while carrying, a bat hit drops the egg + 3 s ragdoll, 3 s re-pick lock for
do
	local gearSrc = H.path(sss, "GearService") and H.path(sss, "GearService").Source or ""
	T.check(H.has(gearSrc, "task.delay(SWING_WINDUP") and H.has(gearSrc, "local function resolveSwingContact(")
		and H.has(gearSrc, "\"Gear: BatFx\"") and H.has(gearSrc, "\"ReplicateEffects: ShakeOnce\"")
		and H.has(gearSrc, "local CARRIER_RAGDOLL_DURATION = 3") and H.has(gearSrc, "IgnoreImmunity = dropped")
		and H.has(gearSrc, "isHittable(other, otherCharacter, otherRoot)")
		and H.has(gearSrc, "\"GearReleaseRequest\"") and H.has(gearSrc, "local function stowIfCarrying(")
		and H.has(gearSrc, "NoCollisionConstraint") and H.has(gearSrc, "SetNetworkOwner") and not H.has(gearSrc, "HitAnim"),
		"GearService must resolve bat hits at the swing's contact moment on a hittable player (Gear: BatFx, camera shake), knock carriers down 3 s, stow tools while carrying and expose GearReleaseRequest")
	local dropAt = string.find(gearSrc, "dropped = dropCarriedEggOf(victim, attacker", 1, true)
	local ragdollAt = string.find(gearSrc, "local ragdolled = ragdollVictim(victim, direction", 1, true)
	T.check(dropAt ~= nil and ragdollAt ~= nil and dropAt < ragdollAt, "a bat hit on a carrier must drop the egg before the knockback moves them")
	local net = rs:FindFirstChild("Network")
	local noRemote = {}
	for _, name in ipairs({ "Gear: Ragdoll", "Gear: BatFx", "ReplicateEffects: ShakeOnce" }) do
		local remote = net and net:FindFirstChild(name)
		if not (remote and remote:IsA("RemoteEvent")) then
			table.insert(noRemote, name)
		end
	end
	T.check(#noRemote == 0, "gear RemoteEvents missing from ReplicatedStorage.Network: %s", list(noRemote))
	local fxLs = H.path(sps, "Game/Tools/BatCombatFx")
	local fxSrc = fxLs and fxLs.Source or ""
	T.check(fxLs ~= nil and fxLs:IsA("LocalScript") and H.has(fxSrc, "RunService.PreSimulation") and H.has(fxSrc, "motor.Transform = out")
		and H.has(fxSrc, "\"SlapVFX\"") and H.has(fxSrc, "rbxassetid://72264591133889") and H.has(fxSrc, "Instance.new(\"Highlight\")")
		and not H.has(fxSrc, "Instance.new(\"Sound\")") and not H.has(fxSrc, ":LoadAnimation("),
		"Game.Tools.BatCombatFx must animate the swing procedurally (Motor6D.Transform) and play the hit burst / flash / pop")
	local slap = H.path(rs, "Assets/Particles/SlapVFX")
	T.check(slap ~= nil and slap:FindFirstChildWhichIsA("ParticleEmitter") ~= nil, "ReplicatedStorage.Assets.Particles.SlapVFX (bat hit burst) missing")
	local ragSrc = H.path(sps, "Game/Tools/GearRagdollController") and H.path(sps, "Game/Tools/GearRagdollController").Source or ""
	T.check(H.has(ragSrc, "local function uprightCFrame(") and H.has(ragSrc, "part.AssemblyLinearVelocity = velocity"),
		"GearRagdollController must fling the whole body and ease it upright when getting up")
	local aesSrc = H.path(sss, "Controllers/AreaEggService") and H.path(sss, "Controllers/AreaEggService").Source or ""
	local _, directWrites = string.gsub(aesSrc, "carryByPlayer%[[%w%.]+%] = ", "")
	T.check(directWrites == 1 and H.has(aesSrc, "player:SetAttribute(CARRY_ATTRIBUTE, uid ~= nil)")
		and H.has(aesSrc, "local REPICK_LOCK_SECONDS = 3") and H.has(aesSrc, "lockRepick(player, eggUid)")
		and H.has(aesSrc, "locks[player.UserId] = now + REPICK_LOCK_SECONDS") and H.has(aesSrc, "if isRepickLocked(player, uid) then"),
		"AreaEggService must mirror every carry on the CarryingEgg attribute (setCarry) and lock the dropper (per player + egg) off that egg for 3 s")
	local grindSrc = H.path(sss, "Controllers/TreadmillGrindService") and H.path(sss, "Controllers/TreadmillGrindService").Source or ""
	local eggSrc = H.path(sss, "Controllers/EggService") and H.path(sss, "Controllers/EggService").Source or ""
	local backpackMainSrc = H.path(sps, "GUI/BackpackController/Main") and H.path(sps, "GUI/BackpackController/Main").Source or ""
	T.check(H.has(grindSrc, "player:GetAttribute(CARRY_ATTRIBUTE) == true") and H.has(grindSrc, "Drop the egg to train!")
		and H.has(eggSrc, "GetAttribute(\"CarryingEgg\") == true") and H.has(backpackMainSrc, "if isCarryEquipBlocked() then"),
		"carriers must be refused by the treadmill grind, the egg tool equip and the backpack (CarryingEgg)")
end

-- 24. New treadmill models (Gekko pass 2026-09-24): New treadmill models (TREADMILL 2026-09-24, owner: "meteras los nuevos treadmills"): every tier wears its Treadmills.rbxl model (textured meshes, one belt whose scrolling Beam keeps both attachments, merged particles, vi
do
	local MODELS = {
		Treadmill = "BasicTreadmill", ["Sci-FiTreadmill"] = "SpaceTreadmill", FlameTreadmill = "FireTreadmill",
		CelebrityTreadmill = "CandyTreadmill", GoldenTreadmill = "JungleTreadmill", ["The FreezeTreadmill"] = "IceTreadmill",
		["Lucky BlockTreadmill"] = "LuckyTreadmill", HackerTreadmill = "HackerTreadmill", DemonicTreadmill = "ToxicTreadmill",
		AngelicTreadmill = "RainbowTreadmill",
	}
	local badSkins, badScreens = {}, {}
	for skinName, modelName in pairs(MODELS) do
		local tool = H.path(rs, "Assets/Models/Treadmills/" .. skinName)
		local model = tool and H.path(tool, "Model/" .. modelName)
		local meshes, blank, belts, beams, loose, rate = 0, 0, {}, 0, 0, 0
		for _, d in ipairs(model and model:GetDescendants() or {}) do
			if d:IsA("BasePart") then
				if d:GetAttribute("TreadmillDecor") ~= true or d.CanCollide or d.CanQuery or d.CanTouch or not d.Anchored then
					loose += 1
				end
				if d:IsA("MeshPart") then
					meshes += 1
					if H.uri(d, "MeshContent") == nil then
						blank += 1
					end
					if d:GetAttribute("TreadmillBelt") == true then
						table.insert(belts, d)
						-- the belt Beam must keep both Attachment refs inside the belt (Lune drops refs across DOMs)
						local beam = d:FindFirstChildWhichIsA("Beam")
						if beam and beam.Attachment0 and beam.Attachment1 and beam.Attachment0:IsDescendantOf(d)
							and beam.Attachment1:IsDescendantOf(d) and beam.Attachment0 ~= beam.Attachment1 then
							beams += 1
						end
					end
				end
			elseif d:IsA("ParticleEmitter") then
				rate += d.Rate
			elseif d:IsA("LuaSourceContainer") or d:IsA("Sound") then
				loose += 1
			end
		end
		if not (tool and model and tool:GetAttribute("TreadmillModel") == modelName and meshes >= 2 and blank == 0 and #belts == 1
			and beams == 1 and loose == 0 and rate <= 150.01) then
			table.insert(badSkins, string.format("%s (%s: %d meshes, %d blank, %d belts, %d beams, %d loose, %.0f p/s)", skinName, modelName, meshes, blank, #belts, beams, loose, rate))
		else
			-- Root sits 3.9 above the floor on the belt line; the screen centre 5.1 above the floor (raised with the belt:
			-- BeltLift - 0.05, round 10), 2.5-6.5 studs ahead, over the belt
			local root, screen, belt = tool:FindFirstChild("Root"), tool:FindFirstChild("PhoneScreen"), belts[1]
			local rel = screen and root and root.CFrame:PointToObjectSpace(screen.CFrame.Position)
			local beltEnd = root and root.CFrame:PointToObjectSpace(belt.CFrame.Position).Z - math.max(belt.Size.X, belt.Size.Z) / 2
			local raised = (tonumber(tool:GetAttribute("BeltLift")) or 0.05) - 0.05
			if not (rel and math.abs(rel.X) < 0.05 and -rel.Z >= 2.5 and -rel.Z <= 6.5 and math.abs(rel.Y - 1.2 - raised) < 0.05 and rel.Z > beltEnd) then
				table.insert(badScreens, skinName)
			end
		end
	end
	T.check(#badSkins == 0, "treadmill skins not wearing their Treadmills.rbxl model properly: %s", list(badSkins))
	T.check(#badScreens == 0, "treadmill PhoneScreen not over the console end ahead of the runner at eye height: %s", list(badScreens))
	local badDisplays = {}
	for _, plot in ipairs(ws:FindFirstChild("Plots") and ws.Plots:GetChildren() or {}) do
		local display = plot:FindFirstChild("SpeedsterTreadmillDisplay")
		local belts, solid, effects = 0, 0, 0
		for _, d in ipairs(display and display:GetDescendants() or {}) do
			if d:IsA("BasePart") then
				if d.CanCollide or d.CanQuery or d.CanTouch then
					solid += 1
				end
				if d:IsA("MeshPart") and d:GetAttribute("TreadmillBelt") == true then
					belts += 1
				end
			elseif d:IsA("ParticleEmitter") or d:IsA("Beam") then
				effects += 1
			end
		end
		if not (display and display:GetAttribute("SourceAsset") == "Treadmills.rbxl.Workspace.BasicTreadmill" and belts == 1 and solid == 0
			and effects == 0 and H.path(display, "LockAnchor/LockBillboard") ~= nil) then
			table.insert(badDisplays, plot.Name)
		end
	end
	T.check(#badDisplays == 0, "plots whose locked SpeedsterTreadmillDisplay is not the visual-only tier-1 model: %s", list(badDisplays))
end

-- 25. Steal an Egg walls and floor (Gekko pass 2026-09-24): Steal an Egg walls + floor (WORLD 2026-09-24, owner: "mete los muros y el piso del steal an egg original pero basados en nuestros stages"): Workspace.WorldWalls holds the SAE walls (36.935 tall, SmoothPlastic, the SAE Te
do
	local walls, badWalls, zones = {}, {}, {}
	for _, d in ipairs(ws:FindFirstChild("WorldWalls") and ws.WorldWalls:GetDescendants() or {}) do
		if d:IsA("BasePart") then
			local mn, mx = H.aabb(d)
			table.insert(walls, { name = d.Name, mn = mn, mx = mx })
			zones[tostring(d:GetAttribute("Zone"))] = true
			local tex = d:FindFirstChildWhichIsA("Texture")
			if not (d.Anchored and d.CanCollide and d.Transparency == 0 and math.abs(d.Size.Y - 36.935) < 0.01
				and tex ~= nil and H.assetId(H.uri(tex, "TextureContent")) == 6905003203) then
				table.insert(badWalls, d.Name)
			end
		end
	end
	local noWall = {}
	for _, stage in ipairs(PLAN.STAGES) do
		if not zones[stage.key] then
			table.insert(noWall, stage.key)
		end
	end
	T.check(#walls >= 17 and zones.Hub and #noWall == 0 and #badWalls == 0,
		"Workspace.WorldWalls must hold the SAE walls of the hub and every stage (%d walls; stages without: %s; wrong profile / texture: %s)",
		#walls, list(noWall), list(badWalls))

	local V3 = H.roblox.Vector3
	local bp = ws:FindFirstChild("Baseplate")
	local groundY = bp and bp.CFrame.Position.Y + bp.Size.Y / 2 or 2.05
	local blocked = {}
	local function clear(label, mn, mx, pad)
		for _, w in ipairs(walls) do
			if w.mn.X - pad < mx.X and w.mx.X + pad > mn.X and w.mn.Y - pad < mx.Y and w.mx.Y + pad > mn.Y
				and w.mn.Z - pad < mx.Z and w.mx.Z + pad > mn.Z then
				table.insert(blocked, label .. " x " .. w.name)
			end
		end
	end
	-- anything the owner placed by hand in Studio (post_zzz_owner_layout marks it OwnerLayout) stands where they put it
	local function ownerPlaced(inst)
		local node = inst
		while node ~= nil and node ~= ws do
			if node:GetAttribute("OwnerLayout") == true then
				return true
			end
			node = node.Parent
		end
		return false
	end
	local function clearParts(root)
		local parts = root and (root:IsA("BasePart") and { root } or root:GetDescendants()) or {}
		for _, d in ipairs(parts) do
			if d:IsA("BasePart") and not ownerPlaced(d) then
				local mn, mx = H.aabb(d)
				if mx.Y > groundY - 1 then
					clear(d.Name, mn, mx, 1)
				end
			end
		end
	end
	local spawn = ws:FindFirstChild("SpawnLocation")
	local lastX = PLAN.STAGES[#PLAN.STAGES].xMax
	clear("main street", V3.new(spawn and H.aabb(spawn).X or PLAN.HUB_MAX_X - 40, groundY, -15), V3.new(lastX, groundY + 12, 15), 1)
	clear("lane", V3.new(PLAN.STAGES[1].xMin, groundY, PLAN.WALL_SOUTH_Z + 1.01), V3.new(lastX, groundY + 40, PLAN.WALL_NORTH_Z - 1.01), 0)
	-- (the HERO BOARD hangs flush ON HubWall_EastSouth by design; its podium must still keep clear of every wall)
	for _, root in ipairs({ ws:FindFirstChild("Plots"), ws:FindFirstChild("Stands"), spawn, H.path(ws, "Hub/HeroBoard/Podium"), H.path(ws, "Hub/FreeGift") }) do
		clearParts(root)
	end
	for _, stage in ipairs(PLAN.STAGES) do
		local env = H.path(ws, "StageEnvironments/" .. stage.key)
		clearParts(env and env:FindFirstChild("EggSpots"))
		clearParts(env and env:FindFirstChild("EggCover"))
		local post = env and env:FindFirstChild("VillainPost")
		if post then
			local p = post.CFrame.Position
			clear(stage.key .. " villain pad", V3.new(p.X - 10, groundY, p.Z - 10), V3.new(p.X + 10, groundY + 14, p.Z + 10), 1)
		end
	end
	T.check(#blocked == 0, "SAE walls block the street / lane / hub or stage content: %s", list(blocked))

	local plainFloors = {}
	for _, stage in ipairs(PLAN.STAGES) do
		local floor = H.path(ws, "Ground/ZoneFloor_" .. stage.key)
		local grid = floor and floor:FindFirstChild("GridTexture")
		if not (grid and H.assetId(H.uri(grid, "TextureContent")) == 6372755229 and floor.MaterialVariant == "Studs") then
			table.insert(plainFloors, stage.key)
		end
	end
	T.check(#plainFloors == 0, "zone floors without the SAE grid look (Studs + GridTexture 6372755229): %s", list(plainFloors))
end

-- 26. Themed trails (Gekko pass 2026-09-24): Themed trails (TRAILS 2026-09-24, Gekko TO DO #4): every Legendary+ trail has its superpower FX template (Assets.TrailFx.<id>: Attachments only, one core Trail, <= 2 capped emitters, a PointLight) that ServerScriptServic
do
	local rarityNumber = {}
	local rarityIndex = H.path(rs, "Directory/Rarity/_Index")
	for _, m in ipairs(rarityIndex and rarityIndex:GetChildren() or {}) do
		rarityNumber[m.Name] = tonumber(string.match(m.Source, "RarityNumber = ([%d%.]+)"))
	end
	local function capOk(trail)
		return trail.MaxLength == 0 or trail.MaxLength >= trail.Lifetime * 200
	end
	local fx, ribbons, trailConfigs = H.path(rs, "Assets/TrailFx"), H.path(rs, "Assets/Trails"), H.path(rs, "Directory/Trails/_Index")
	local wrong, badFx, badRibbon, themed = {}, {}, {}, 0
	for _, cfg in ipairs(trailConfigs and trailConfigs:GetChildren() or {}) do
		local n = rarityNumber[string.match(cfg.Source, "Rarity%.Rarities%.(%w+)") or ""]
		local legendary = n ~= nil and n >= 5
		local template = fx and fx:FindFirstChild(cfg.Name)
		if (template ~= nil) ~= legendary or (legendary and not H.has(cfg.Source, "Effect = \"")) then
			table.insert(wrong, cfg.Name)
		end
		if template then
			themed += 1
			local emitters, trails, lights, ok = 0, 0, 0, true
			for _, c in ipairs(template:GetChildren()) do
				ok = ok and c:IsA("Attachment")
			end
			for _, d in ipairs(template:GetDescendants()) do
				if d:IsA("ParticleEmitter") then
					emitters += 1
					ok = ok and d.Rate <= 30 and H.uri(d, "TextureContent") ~= nil
				elseif d:IsA("Trail") or d:IsA("Beam") then
					trails += if d:IsA("Trail") then 1 else 0
					ok = ok and d.Attachment0 ~= nil and d.Attachment0.Parent == template and d.Attachment1 ~= nil
						and d.Attachment1.Parent == template and (not d:IsA("Trail") or capOk(d))
				elseif d:IsA("PointLight") then
					lights += 1
				end
			end
			if not (ok and emitters >= 1 and emitters <= 2 and trails == 1 and lights == 1) then
				table.insert(badFx, cfg.Name)
			end
		end
		local part = ribbons and ribbons:FindFirstChild(cfg.Name)
		local trail = part and part:FindFirstChildWhichIsA("Trail", true)
		if not (trail and trail.MaxLength > 0 and capOk(trail) and trail.Attachment0 and trail.Attachment0.Parent == part
			and trail.Attachment1 and trail.Attachment1.Parent == part) then
			table.insert(badRibbon, cfg.Name)
		end
	end
	T.check(themed == 6 and #wrong == 0 and #badFx == 0, "themed trail FX: %d templates (want 6); wrong rarity / missing Effect: %s; bad template: %s",
		themed, list(wrong), list(badFx))
	T.check(#badRibbon == 0, "Assets.Trails ribbons need a Trail between attachments on the part, capped at >= Lifetime x 200 studs: %s",
		list(badRibbon))
	local trailFxSvc = H.path(sss, "TrailService")
	local trailFxSrc = trailFxSvc and trailFxSvc.Source or ""
	T.check(H.has(trailFxSrc, "WaitForChild(\"TrailFx\"") and H.has(trailFxSrc, "local function mountFx(")
		and H.has(trailFxSrc, "humanoid.Died:Connect(") and H.has(trailFxSrc, "player.CharacterRemoving:Connect(")
		and H.has(trailFxSrc, "safeRefreshFx(player)") and H.has(trailFxSrc, "characterConnections[player] = nil"),
		"TrailService must mount Assets.TrailFx on the character and clear it on unequip / death / respawn / leave")
end

-- 27. Hero size + motion (Gekko pass 2026-09-24): HEROES (Gekko 2026-09-24 #6/#7/#8): Settings > Hero Size (Small / Normal / Big, a viewer preference saved as profile.Settings.HeroSize) draws pen heroes at a compressed visual scale while income keeps the real Scale, eve
do
	local vars, settingsSvc, settingsLs = H.path(rs, "Library/Shared/Variables"), H.path(sss, "Controllers/SettingsService"), H.path(sps, "GUI/Settings")
	T.check(vars ~= nil and H.has(vars.Source, "HeroSizeInfo = {") and H.has(vars.Source, "key = \"HeroSize\"")
		and not H.has(string.match(vars.Source, "SettingsInfo = (%b{})") or "HeroSize", "HeroSize")
		and settingsSvc ~= nil and H.has(settingsSvc.Source, "return updateHeroSize(player, value)") and H.has(settingsSvc.Source, "HeroSizeInfo.options[value] == nil")
		and settingsLs ~= nil and H.has(settingsLs.Source, "ensureClonedRow(\"HeroSize\"") and H.has(settingsLs.Source, "Network.NET_MAP.Settings.REQUEST_UPDATE"),
		"Hero Size: Variables.HeroSizeInfo (outside the boolean SettingsInfo), SettingsService validation and the Settings row")
	local sizeModule = H.path(rs, "Library/Modules/AssetHeroSizePresentation")
	local stub = { FindFirstChild = function() return nil end, IsClient = function() return false end }
	local chunk = sizeModule and H.sandbox(sizeModule.Source, { game = { GetService = function() return stub end } }, "AssetHeroSizePresentation")
	local okSize, size = false, nil
	if chunk then
		okSize, size = pcall(chunk)
	end
	local curveOk = okSize and type(size) == "table"
	local last = 0
	for _, scale in ipairs({ 0.1, 0.25, 0.5, 1, 1.5, 2, 3, 6, 10, 17, 35 }) do
		local visual = curveOk and size.GetVisualScale(scale, "Normal") or 0
		curveOk = curveOk and visual > last
		last = visual
	end
	T.check(curveOk and math.abs(size.GetVisualScale(1, "Normal") - 1) < 1e-6 and size.GetVisualScale(35, "Normal") < 3
		and size.GetVisualScale(1, "Small") < 1 and size.GetVisualScale(1, "Big") > 1 and size.NextPreference("Big") == "Small",
		"AssetHeroSizePresentation must keep the size order, draw Scale 1 at 1x and cap the 35x giants under 3x")
	local income = H.path(rs, "Library/Util/AssetGenerationUtil")
	T.check(income ~= nil and H.has(income.Source, "p1Scale ^ 1.85"), "income must keep using the real Scale (AssetGenerationUtil Scale ^ 1.85)")
	local motionModule = H.path(rs, "Directory/HeroMotion")
	local motionChunk = motionModule and H.sandbox(motionModule.Source, { Color3 = H.roblox.Color3 }, "HeroMotion")
	local okMotion, motion = false, nil
	if motionChunk then
		okMotion, motion = pcall(motionChunk)
	end
	local unstyled, styles = {}, {}
	for _, hero in ipairs(PLAN.HEROES) do
		local entry = okMotion and type(motion) == "table" and motion.Heroes[hero[1]]
		if entry and motion.Styles[entry.Style] then
			styles[entry.Style] = true
		else
			table.insert(unstyled, hero[1])
		end
	end
	T.check(okMotion and #unstyled == 0 and styles.walk and styles.float and styles.dash and styles.stomp,
		"Directory.HeroMotion must give every roster hero a movement style (missing: %s)", list(unstyled))
	local aac = H.path(sps, "Game/Plots/ActiveAssetsController")
	local comp, sab = aac and aac:FindFirstChild("AssetComponent"), H.path(sps, "Game/SabVfxController")
	T.check(aac ~= nil and aac:FindFirstChild("AssetHeroMotion") ~= nil and comp ~= nil and sab ~= nil
		and H.has(comp.Source, "CreateWanderingAssetModel(p1.OwnerUserId, p1.UID, displayItemData, p4)")
		and H.has(comp.Source, "AssetWanderSimulator.new(p1.Seed, p2, p3, p1.ItemData,") and H.has(comp.Source, "p28:_stepMotion(")
		and H.has(aac.Source, "ConnectPreferenceChanged(setHeroSizePreference)") and H.has(aac.Source, "SuppressHatchBurst")
		and H.has(aac.Source, "if rebuilt % HERO_SIZE_REBUILDS_PER_FRAME ~= 0 then") -- deferred ChildAdded: yield before clearing
		and H.has(sab.Source, "GetAttribute(\"SuppressHatchBurst\")") and H.has(sab.Source, "scaleCopied(copied, auraScaleOf(model))"),
		"pen heroes must render at the Hero Size visual scale (records keep the real Scale), run the motion layer and size their auras")
	local doubled = {}
	for _, hero in ipairs(PLAN.HEROES) do
		local model = H.path(rs, "AssetModels/" .. hero[1])
		local head = model and H.path(model, "Model/Head")
		for _, d in ipairs(head and model:GetDescendants() or {}) do
			if d ~= head and d:IsA("BasePart") and d.Transparency < 1 and d.ClassName == head.ClassName
				and (d.CFrame.Position - head.CFrame.Position).Magnitude < 0.02 and (d.Size - head.Size).Magnitude < 0.02 then
				table.insert(doubled, hero[1] .. "." .. d.Name)
			end
		end
	end
	T.check(#doubled == 0, "hero models with a doubled visible head (z-fighting face): %s", list(doubled))
end

-- 28. Index base themes (Gekko pass 2026-09-24): Index completion rewards (Gekko 2026-09-24, owner BASES): completing a stage's Hero Index unlocks that stage's themed base. Directory.BaseThemes (6 themes), Database defaults, IndexService (unlock live + on join, validat
do
	local order = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }
	local directory = H.path(rs, "Directory/BaseThemes")
	local db = H.path(sss, "Library/Database")
	local indexService = H.path(sss, "Controllers/IndexService")
	local plotService = H.path(sss, "Controllers/PlotService")
	local remote = H.path(rs, "Network/BaseThemes: RequestEquip")
	T.check(directory ~= nil and H.has(directory.Source, "BaseThemes.Order = { \"Forest\", \"Lake\", \"Desert\", \"Jungle\", \"Snow\", \"Volcano\" }")
		and db ~= nil and H.has(db.Source, "UnlockedBaseThemes = {},") and H.has(db.Source, "EquippedBaseTheme = \"\",")
		and remote ~= nil and remote:IsA("RemoteFunction"),
		"base themes: Directory.BaseThemes / Database defaults (UnlockedBaseThemes, EquippedBaseTheme) / equip remote missing")
	T.check(indexService ~= nil and H.has(indexService.Source, "EquipBaseThemeRemote.OnServerInvoke") and H.has(indexService.Source, "Database.OnFieldChanged(\"Index\"")
		and H.has(indexService.Source, "Database.OnLoaded(") and H.has(indexService.Source, "profile.UnlockedBaseThemes[key] ~= true")
		and plotService ~= nil and H.has(plotService.Source, "THEME_PROPS_NAME = \"ThemeProps\"") and H.has(plotService.Source, "restorePen(plotId)")
		and H.has(plotService.Source, "Database.OnFieldChanged(\"EquippedBaseTheme\""),
		"base themes: IndexService unlock / validated equip or PlotService apply / revert missing")

	-- the props: every theme on every plot, with its floor, gate and sides and NO backdrop (owner 2026-09-24); inert parts only
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes")
	local noModel, noGroups, notInert, intrusions = {}, {}, {}, {}
	for _, plot in ipairs(ws:FindFirstChild("Plots") and ws.Plots:GetChildren() or {}) do
		local petArea = H.path(plot, "ToUpdate/PetArea")
		local heroMin, heroMax = nil, nil
		if petArea then
			heroMin, heroMax = H.aabb(petArea)
		end
		local functional = {}
		for _, name in ipairs({ "PlotUpgrade", "TreadmillUpgrade", "SpeedsterTreadmillDisplay", "TreadmillBottom", "SpawnPoint", "Multiplier" }) do
			local node = plot:FindFirstChild(name)
			for _, d in ipairs(node and { node, table.unpack(node:GetDescendants()) } or {}) do
				if d:IsA("BasePart") then
					local a, b = H.aabb(d)
					table.insert(functional, { a, b })
				end
			end
		end
		for _, key in ipairs(order) do
			local tag = key .. "/" .. plot.Name
			local model = store and H.path(store, tag)
			if model == nil then
				table.insert(noModel, tag)
				continue
			end
			local backdrop = false
			for _, group in ipairs(model:GetChildren()) do
				backdrop = backdrop or string.sub(group.Name, 1, 13) == "ThemeBackdrop"
			end
			-- a Blender-modelled pen (HidesPenFence, section 29) replaces the floor / gate / sides groups
			local imported = model:GetAttribute("HidesPenFence") == true and model:FindFirstChild("ThemeImportedPen") ~= nil
			if not ((imported or (model:FindFirstChild("ThemeFloor") and model:FindFirstChild("ThemeGate") and model:FindFirstChild("ThemeSides"))) and not backdrop) then
				table.insert(noGroups, tag)
			end
			local inertOk = true
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					if inertOk and (d.CanCollide or d.CanQuery or d.CanTouch or not d.Anchored) then
						table.insert(notInert, tag .. "." .. d.Name)
						inertOk = false
					end
					local a, b = H.aabb(d)
					-- merged meshes of an imported pen span the whole pen: the build checks their pieces one by one
					local floor = string.sub(d.Name, 1, 10) == "ThemeFloor" or d:FindFirstAncestor("ThemeImportedPen") ~= nil
					local hit = not floor and heroMin ~= nil and a.X < heroMax.X and b.X > heroMin.X and a.Z < heroMax.Z and b.Z > heroMin.Z
						and b.Y > heroMin.Y + 0.3
					for _, box in ipairs(if d:FindFirstAncestor("ThemeImportedPen") then {} else functional) do
						hit = hit or (a.X < box[2].X and b.X > box[1].X and a.Y < box[2].Y and b.Y > box[1].Y and a.Z < box[2].Z and b.Z > box[1].Z)
					end
					if hit then
						table.insert(intrusions, tag .. "." .. d.Name)
						break
					end
				end
			end
		end
	end
	T.check(store ~= nil and #noModel == 0, "themed props missing (ServerStorage.BaseThemes.<Key>.<plot>): %s", list(noModel))
	T.check(#noGroups == 0, "themed props without their floor / gate / sides, or with a backdrop: %s", list(noGroups))
	T.check(#notInert == 0, "themed props must be anchored and never collide / query / touch: %s", list(notInert))
	T.check(#intrusions == 0, "themed props inside a hero area or touching a plot's upgrade signs / treadmill / spawn: %s", list(intrusions))

	-- the Index page, its client and the 3D previews
	local index = H.path(sg, "Index/Index")
	local page = index and H.path(index, "Content/SpBaseThemesPage")
	local button = index and index:FindFirstChild("SpBasesButton")
	local rows, previews = {}, {}
	for _, key in ipairs(order) do
		local row = page and H.path(page, "List/Row_" .. key)
		if row == nil or not row:IsA("GuiButton") then
			table.insert(rows, key)
		end
		if H.path(rs, "Assets/BaseThemes/" .. key) == nil then
			table.insert(previews, key)
		end
	end
	local client = H.path(sps, "GUI/BaseThemes")
	T.check(button ~= nil and button:IsA("GuiButton") and page ~= nil and page.Visible == false and page.Active == true and #rows == 0
		and H.path(page, "Detail/Preview") ~= nil and page.Detail.Preview:IsA("ViewportFrame") and H.path(page, "Detail/EquipButton") ~= nil
		and page.Detail.EquipButton:IsA("GuiButton") and H.path(index, "Content/IndexPage") ~= nil,
		"Index STAGE BASES page broken (band button, hidden page, rows: %s)", list(rows))
	T.check(#previews == 0 and client ~= nil and client:IsA("LocalScript") and H.has(client.Source, "\"BaseThemes: RequestEquip\""),
		"STAGE BASES client (GUI.BaseThemes) or previews (ReplicatedStorage.Assets.BaseThemes) missing: %s", list(previews))
end

-- 29. Blender base themes, API v3 (scripts/tools/blender/base_themes, owner art direction 2026-09-24): every v3 theme
--     layout on disk (assets/models/bases/<Key>/<Name>.json, format stealahero-base-theme/3) has its FBX + .blend, stays
--     within 6000..9000 evaluated tris per complete variant, passed its self-checks, has no backdrop role and is in the
--     Studio helper (older v2 layouts may stay on disk: the build ignores them); the loader and PlotService's fence
--     hiding are wired; every per-plot model using an imported pen is complete and inert, with no backdrop.
do
	local order = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }
	local helperPath = "assets/models/bases/BaseThemesImport.lua"
	local helper = H.fs.isFile(helperPath) and H.fs.readFile(helperPath) or ""
	local layouts, bad = 0, {}
	for _, key in ipairs(order) do
		local dir = "assets/models/bases/" .. key
		for _, name in ipairs(H.fs.isDir(dir) and H.fs.readDir(dir) or {}) do
			local text = if string.sub(name, -5) == ".json" then H.fs.readFile(dir .. "/" .. name) else ""
			if H.has(text, "\"format\": \"stealahero-base-theme/3\"") then
				layouts += 1
				local stem = string.sub(name, 1, -6)
				local ok = H.fs.isFile(dir .. "/" .. stem .. ".fbx") and H.fs.isFile(dir .. "/" .. stem .. ".blend")
					and H.has(helper, "key = \"" .. key .. "\", name = \"" .. stem .. "\", title = ") and not H.has(text, "\"Backdrop_")
				local variants = 0
				for tris in string.gmatch(text, "\"total_tris\": (%d+)") do
					variants += 1
					ok = ok and tonumber(tris) >= 6000 and tonumber(tris) <= 9000
				end
				local _, clean = string.gsub(text, "\"problems\": %[%]", "")
				if not (ok and variants == 2 and clean == 2) then
					table.insert(bad, key .. "/" .. stem)
				end
			end
		end
	end
	T.check(layouts >= 1 and H.fs.isFile("assets/models/bases/Forest/StarkLab.json") and #bad == 0,
		"Blender base themes (v3): a layout without its FBX / .blend / helper entry, out of the 6000..9000 tri budget, with a backdrop or with self-check problems: %s",
		list(bad))
	local plotService = H.path(sss, "Controllers/PlotService")
	local step = H.fs.readFile("scripts/steps/post_zz_base_themes.luau")
	T.check(plotService ~= nil and H.has(plotService.Source, "HidesPenFence") and H.has(plotService.Source, "local function hidePenFence(")
		and H.has(step, "Step.IMPORTED_PENS") and H.has(step, "Step.IMPORT_FORMAT = \"stealahero-base-theme/3\"")
		and H.has(step, "function Step.applyImportedTheme("),
		"imported base themes not wired (post_zz_base_themes IMPORTED_PENS / v3 IMPORT_FORMAT / applyImportedTheme, PlotService hidePenFence)")
	-- per-plot models (and the Index previews) that use an imported pen
	local function inert(group)
		local n, ok = 0, true
		for _, part in ipairs(group and group:GetChildren() or {}) do
			if part:IsA("BasePart") then
				n += 1
				ok = ok and part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch
			end
		end
		return n, ok
	end
	local incomplete, used = {}, 0
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes")
	local previews = H.path(rs, "Assets/BaseThemes")
	for _, key in ipairs(order) do
		local models = {}
		for _, model in ipairs(store and store:FindFirstChild(key) and store[key]:GetChildren() or {}) do
			table.insert(models, model)
		end
		if previews and previews:FindFirstChild(key) then
			table.insert(models, previews[key])
		end
		for _, model in ipairs(models) do
			local tag = key .. "/" .. model.Name
			local pen = model:FindFirstChild("ThemeImportedPen")
			if pen or model:GetAttribute("HidesPenFence") == true then
				used += 1
				local n, ok = inert(pen)
				if not (pen and model:GetAttribute("HidesPenFence") == true and n >= 3 and ok and pen:FindFirstChild("ThemeFloor_Base")
					and pen:FindFirstChild("ThemeNeon_Emissive_Screen") and model:FindFirstChild("ThemeBackdropImported") == nil) then
					table.insert(incomplete, tag)
				end
			end
		end
	end
	T.check(#incomplete == 0, "base themes with an incomplete / collidable imported pen (or a backdrop): %s (%d using imports)",
		list(incomplete), used)
end

-- 30. Hero animations (ANIMCORE 2026-09-24): clips authored in Blender (scripts/tools/blender/hero_anim) are published as
--     ReplicatedStorage.Directory.HeroAnimations.<HeroId> and played by HeroClipPlayer (Motor6D.Transform writer) through
--     AssetComponent; every module must load, pass HeroClipMath.PrepareModule and name a real hero model, and (INTEGRATE)
--     every roster hero is animated: Idle + Move loops and a one-shot Special.
do
	local folder = H.path(rs, "Directory/HeroAnimations")
	local clipMath = H.path(rs, "Library/Modules/HeroClipMath")
	local aac = H.path(sps, "Game/Plots/ActiveAssetsController")
	local player = aac and aac:FindFirstChild("HeroClipPlayer")
	local comp = aac and aac:FindFirstChild("AssetComponent")
	local motion = aac and aac:FindFirstChild("AssetHeroMotion")
	local mathChunk = clipMath and H.sandbox(clipMath.Source, { CFrame = H.roblox.CFrame }, "HeroClipMath")
	local okMath, clipMathApi = false, nil
	if mathChunk then
		okMath, clipMathApi = pcall(mathChunk)
	end
	local bad, heroes, prepared = {}, {}, {}
	for _, module in ipairs(folder and folder:GetChildren() or {}) do
		local chunk = module:IsA("ModuleScript") and H.sandbox(module.Source, {}, module.Name)
		local okLoad, data = false, nil
		if chunk then
			okLoad, data = pcall(chunk)
		end
		local okPrepare, clips = false, nil
		if okLoad and okMath then
			okPrepare, clips = pcall(clipMathApi.PrepareModule, data)
		end
		if not okPrepare or data.HeroId ~= module.Name or H.path(rs, "AssetModels/" .. module.Name) == nil then
			table.insert(bad, module.Name)
			continue
		end
		table.insert(heroes, module.Name)
		prepared[module.Name] = data
		local sample = {}
		clipMathApi.SampleClip(clips.Move, 0.37, sample)
		for joint, s in pairs(sample) do
			if math.abs(s[1] * s[1] + s[2] * s[2] + s[3] * s[3] + s[4] * s[4] - 1) > 1e-4 then
				table.insert(bad, module.Name .. "." .. joint)
			end
		end
	end
	T.check(okMath and folder ~= nil and #bad == 0 and table.find(heroes, "Vegeta") ~= nil and table.find(heroes, "PeterParker") ~= nil,
		"Directory.HeroAnimations: every module must load and pass HeroClipMath (Vegeta + PeterParker at least); bad: %s", list(bad))
	T.check(player ~= nil and comp ~= nil and motion ~= nil and H.has(player.Source, "motor.Transform = HeroClipMath.ToCFrame(")
		and H.has(comp.Source, "p28:_stepClips(") and H.has(comp.Source, "v40.Parent = nil")
		and H.has(motion.Source, "function AssetHeroMotion.SetClipModifiers("),
		"HeroClipPlayer must be injected and driven by AssetComponent (clips own the joints, AssetHeroMotion keeps the root)")
	local unanimated = {}
	for _, hero in ipairs(PLAN.HEROES) do
		local data = prepared[hero[1]]
		local c = data and data.Clips
		if not (c and c.Idle and c.Idle.Loop == true and c.Move and c.Move.Loop == true and c.Special and c.Special.Loop == false) then
			table.insert(unanimated, hero[1])
		end
	end
	T.check(#heroes >= #PLAN.HEROES and #unanimated == 0,
		"every roster hero needs its Blender clips (Idle + Move loops, one-shot Special): %d modules, missing / incomplete: %s",
		#heroes, list(unanimated))
end

-- 31. Dragon Ball + My Hero Academia clips (ANIM_DBZ_MHA 2026-09-24): every hero of the two franchises ships an Idle +
--     Move loop and a one-shot Special with an effect, and the flyers never play footsteps while flying.
do
	local folder = H.path(rs, "Directory/HeroAnimations")
	local heroes = { "Goku", "Gohan", "Piccolo", "Trunks", "Krillin", "Uraraka", "Hawks", "Deku", "Bakugo", "Todoroki", "AllMight" }
	local flyers = { Goku = true, Gohan = true, Piccolo = true, Krillin = true, Uraraka = true, Hawks = true, Bakugo = true }
	local bad = {}
	for _, heroId in ipairs(heroes) do
		local module = folder and folder:FindFirstChild(heroId)
		local chunk = module and module:IsA("ModuleScript") and H.sandbox(module.Source, {}, heroId)
		local okLoad, data = false, nil
		if chunk then
			okLoad, data = pcall(chunk)
		end
		local clips = okLoad and type(data) == "table" and data.HeroId == heroId and data.Clips or nil
		local function joints(clip)
			local n = 0
			for _ in pairs(clip and clip.Tracks or {}) do
				n += 1
			end
			return n
		end
		if clips == nil or H.path(rs, "AssetModels/" .. heroId) == nil then
			table.insert(bad, heroId)
		elseif not (clips.Idle and clips.Idle.Loop == true and joints(clips.Idle) >= 8
			and clips.Move and clips.Move.Loop == true and joints(clips.Move) >= 8
			and clips.Special and clips.Special.Loop == false and joints(clips.Special) >= 8 and #(clips.Special.Effects or {}) > 0) then
			table.insert(bad, heroId .. ".clips")
		elseif flyers[heroId] and clips.Move.Footsteps ~= false then
			table.insert(bad, heroId .. ".Footsteps")
		end
	end
	T.check(#bad == 0, "Dragon Ball / My Hero Academia hero clips missing or malformed (Idle+Move loops, Special one-shot with effects, flyers silent): %s", list(bad))
end

-- 32. Spider-Verse + Avengers clips (ANIM_SPIDER 2026-09-24): SpiderGwen / MilesMorales / SpiderMan2099 web-swing (a Web
--     beam per swing, the clip owns the height: Motion.Lift 0, no footsteps) and web-shoot in their Special; AgentVenom /
--     Venom / BlackWidow / Hawkeye have their own Idle + Move + Special, Venom's stomp keeps half the HeroMotion dip and
--     Hawkeye's nocked arrow is a RightHand Web on the drawn string (the loosed arrow a LeftHand Web streak).
do
	local folder = H.path(rs, "Directory/HeroAnimations")
	local bad = {}
	local function clipsOf(id)
		local module = folder and folder:FindFirstChild(id)
		local chunk = module and module:IsA("ModuleScript") and H.sandbox(module.Source, {}, id)
		local ok, data = false, nil
		if chunk then
			ok, data = pcall(chunk)
		end
		if not ok or type(data) ~= "table" or data.HeroId ~= id or type(data.Clips) ~= "table" then
			table.insert(bad, id)
			return nil
		end
		local c = data.Clips
		if not (c.Idle and c.Idle.Loop == true and c.Move and c.Move.Loop == true and c.Special and c.Special.Loop == false) then
			table.insert(bad, id .. ".Clips")
			return nil
		end
		return c
	end
	local function hasWeb(clip, hand)
		for _, e in ipairs(clip.Effects or {}) do
			if e.Type == "Web" and (hand == nil or e.Hand == hand) then
				return true
			end
		end
		return false
	end
	for _, id in ipairs({ "SpiderGwen", "MilesMorales", "SpiderMan2099" }) do
		local c = clipsOf(id)
		if c and not (hasWeb(c.Move) and c.Move.Motion.Lift == 0 and c.Move.Footsteps == false and hasWeb(c.Special)) then
			table.insert(bad, id .. ".swing")
		end
	end
	clipsOf("AgentVenom")
	clipsOf("BlackWidow")
	local venom = clipsOf("Venom")
	if venom and not (venom.Move.Motion.Lift < 1 and venom.Move.Footsteps == true) then
		table.insert(bad, "Venom.stomp")
	end
	local hawkeye = clipsOf("Hawkeye")
	if hawkeye and not (hasWeb(hawkeye.Idle, "RightHand") and hasWeb(hawkeye.Special, "RightHand") and hasWeb(hawkeye.Special, "LeftHand")) then
		table.insert(bad, "Hawkeye.arrows")
	end
	T.check(#bad == 0, "Spider-Verse + Avengers hero clips (7 heroes: Idle/Move/Special, swingers web + own the height, Hawkeye's arrows); bad: %s",
		list(bad))
end

-- 33. Avengers / Justice League clips (ANIM_AVJL 2026-09-24): the 10 heroes each carry a looping Idle + Move and a
--     one-shot Special with its effects (shield throw, smash, lightning, unibeam, tidal strike, construct, Speed Force,
--     lasso, grapple, chain break); the airborne Moves (flight / swim glide) never play footsteps, the walkers do.
do
	local folder = H.path(rs, "Directory/HeroAnimations")
	local NO_STEPS = { Thor = true, IronMan = true, GreenLantern = true, Superman = true, Aquaman = true }
	local bad = {}
	for _, id in ipairs({ "CaptainAmerica", "Hulk", "Thor", "IronMan", "Aquaman", "GreenLantern", "Flash", "WonderWoman", "Batman", "Superman" }) do
		local module = folder and folder:FindFirstChild(id)
		local chunk = module and module:IsA("ModuleScript") and H.sandbox(module.Source, {}, id)
		local okLoad, data = false, nil
		if chunk then
			okLoad, data = pcall(chunk)
		end
		local clips = okLoad and type(data) == "table" and data.HeroId == id and data.Clips
		local idle, move, special = clips and clips.Idle, clips and clips.Move, clips and clips.Special
		if not (idle and move and special and idle.Loop == true and move.Loop == true and special.Loop == false
			and move.Tracks and move.Tracks.Root and #(special.Effects or {}) > 0 and move.Footsteps == (NO_STEPS[id] == nil)) then
			table.insert(bad, id)
		end
	end
	T.check(#bad == 0, "Avengers / Justice League hero clips missing or wrong (Idle + Move + Special with effects, footsteps): %s", list(bad))
end

-- 34. One Piece clips (ANIM_OP 2026-09-24): Usopp, Nami, Brook, Sanji, Zoro, Shanks, Luffy and Joy Boy each publish
--     Idle + Move loops and a one-shot Special with at least one effect (burst / charge / accent), for a real model.
do
	local folder = H.path(rs, "Directory/HeroAnimations")
	local bad = {}
	for _, id in ipairs({ "Usopp", "Nami", "Brook", "Sanji", "Zoro", "Shanks", "Luffy", "JoyBoy" }) do
		local module = folder and folder:FindFirstChild(id)
		local chunk = module and module:IsA("ModuleScript") and H.sandbox(module.Source, {}, id)
		local okLoad, data = false, nil
		if chunk then
			okLoad, data = pcall(chunk)
		end
		local clips = okLoad and type(data) == "table" and data.Clips or nil
		local special = clips and clips.Special
		if not (clips and clips.Idle and clips.Idle.Loop and clips.Move and clips.Move.Loop and special and not special.Loop
			and #(special.Effects or {}) > 0 and H.path(rs, "AssetModels/" .. id) ~= nil) then
			table.insert(bad, id)
		end
	end
	T.check(#bad == 0, "One Piece heroes need Idle + Move loops and an effect Special in Directory.HeroAnimations: %s", list(bad))
end

-- 35. Lake "Hall of Justice" Blender base, API v3 (base_themes/themes/lake.py, owner art direction 2026-09-24): the
--     Justice League layout on disk (stealahero-base-theme/3, material-family roles: marble, League blue, gold, the
--     sapphire neon, the grey chess slabs and the 3D gold / blue shield core; both variants 6000..9000 tris with no
--     problems, every real plot fits: Std on 1/4/5, Deep on 2/3/6), its FBX + .blend + hero / gate / detail renders, its
--     own perimeter (the balustrade: plinth, balusters, cornice; the portico gate; no backdrop), and any Lake plot model
--     that uses the import picked a variant its layout says fits that plot.
do
	local dir = "assets/models/bases/Lake/"
	local text = H.fs.isFile(dir .. "HallOfJustice.json") and H.fs.readFile(dir .. "HallOfJustice.json") or ""
	local srcPath = "scripts/tools/blender/base_themes/themes/lake.py"
	local src = H.fs.isFile(srcPath) and H.fs.readFile(srcPath) or ""
	local bad = {}
	if not (H.has(text, "\"format\": \"stealahero-base-theme/3\"") and H.has(text, "\"key\": \"Lake\"")) then
		table.insert(bad, "format / key")
	end
	for _, role in ipairs({ "Floor_Base", "Neon_Emissive_Screen", "Floor_Grey", "Structure_Marble", "Structure_Blue",
		"Structure_Gold", "Core_3D_Gold", "Core_3D_Blue", "Neon_Emissive_Sapphire" }) do
		if not H.has(text, "\"" .. role .. "\": {") then
			table.insert(bad, "role " .. role)
		end
	end
	if H.has(text, "Backdrop") or H.has(src, "Backdrop") then
		table.insert(bad, "a backdrop")
	end
	for _, file in ipairs({ "HallOfJustice.fbx", "HallOfJustice.blend", "preview/HallOfJustice_hero.png",
		"preview/HallOfJustice_gate.png", "preview/HallOfJustice_detail.png" }) do
		if not H.fs.isFile(dir .. file) then
			table.insert(bad, file)
		end
	end
	for _, needle in ipairs({ "def rail_run(", "def baluster(", "def span(", "def post(", "def corner(", "def gate_pylon(",
		"def gate_lintel(", "def emblem(", "def terminal(", "def shield(" }) do
		if not H.has(src, needle) then
			table.insert(bad, "lake.py " .. needle)
		end
	end
	local variants = 0
	for tris in string.gmatch(text, "\"total_tris\": (%d+)") do
		variants += 1
		if tonumber(tris) < 6000 or tonumber(tris) > 9000 then
			table.insert(bad, "tris " .. tris)
		end
	end
	local _, clean = string.gsub(text, "\"problems\": %[%]", "")
	local _, plotClean = string.gsub(text, "\"plot_problems\": %[%]", "")
	local fits = 0
	for _ in string.gmatch(text, "\"%d\": \"fits\"") do
		fits += 1
	end
	T.check(variants == 2 and clean == 2 and plotClean == 2 and fits == 6 and #bad == 0,
		"Lake Hall of Justice v3 layout: %d variant(s), %d/2 clean, %d/2 plot-clean, %d/6 plots fit, problems: %s",
		variants, clean, plotClean, fits, list(bad))
	local deepAt = string.find(text, "\"Deep\": {", 1, true) or #text
	local parts = { Std = string.sub(text, 1, deepAt), Deep = string.sub(text, deepAt) }
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes/Lake")
	local wrong = {}
	for _, model in ipairs(store and store:GetChildren() or {}) do
		local variant = model:GetAttribute("ImportedVariant")
		if variant ~= nil and not (parts[variant] and H.has(parts[variant], "\"" .. model.Name .. "\": \"fits\"")) then
			table.insert(wrong, model.Name .. "=" .. tostring(variant))
		end
	end
	T.check(store ~= nil and #store:GetChildren() >= 6 and #wrong == 0,
		"Lake plot models missing, or an imported Hall of Justice on a variant that does not fit the plot: %s", list(wrong))
end

-- 36. Desert "Brooklyn Rooftop" (base_themes/themes/desert.py, API v3, owner art direction 2026-09-24; replaces the v2
--     "Spider Hideout"): the Spider-Verse rooftop layout on disk (format /3, FBX + .blend + hero / gate / detail renders,
--     in the Studio helper), both variants within 6000..9000 evaluated tris with no self-check problems, Std fitting plots
--     1/4/5 and Deep 2/3/6, the Brooklyn roles (brick, limestone, wrought iron, water-tower wood, the red / black spider
--     core, magenta + cyan neon), its own perimeter in the theme source (brick parapet, fire-escape railing, chimney
--     vents, water-tower pylons, the stepped spider) and no v2 leftovers; a plot using the import picks its depth's variant.
do
	local dir = "assets/models/bases/Desert/"
	local text = H.fs.isFile(dir .. "BrooklynRooftop.json") and H.fs.readFile(dir .. "BrooklynRooftop.json") or ""
	local helperPath = "assets/models/bases/BaseThemesImport.lua"
	local helper = H.fs.isFile(helperPath) and H.fs.readFile(helperPath) or ""
	local srcPath = "scripts/tools/blender/base_themes/themes/desert.py"
	local src = H.fs.isFile(srcPath) and H.fs.readFile(srcPath) or ""
	local bad = {}
	if not H.has(text, "\"format\": \"stealahero-base-theme/3\"") or not H.has(text, "\"name\": \"BrooklynRooftop\"") then
		table.insert(bad, "layout / format")
	end
	for _, file in ipairs({ "BrooklynRooftop.fbx", "BrooklynRooftop.blend", "preview/BrooklynRooftop_hero.png",
		"preview/BrooklynRooftop_gate.png", "preview/BrooklynRooftop_detail.png" }) do
		if not H.fs.isFile(dir .. file) then
			table.insert(bad, file)
		end
	end
	for _, role in ipairs({ "Floor_Base", "Neon_Emissive_Screen", "Structure_Brick", "Structure_Concrete", "Structure_Iron",
		"Structure_Wood", "Core_3D_Red", "Core_3D_Black", "Neon_Emissive_Magenta", "Neon_Emissive_Cyan" }) do
		if not H.has(text, "\"" .. role .. "\": {") then
			table.insert(bad, "role " .. role)
		end
	end
	local deepAt = string.find(text, "\"Deep\": {", 1, true) or #text
	local parts = { Std = string.sub(text, 1, deepAt), Deep = string.sub(text, deepAt) }
	for variant, plots in pairs({ Std = { "1", "4", "5" }, Deep = { "2", "3", "6" } }) do
		local body = parts[variant]
		local tris = tonumber(string.match(body, "\"total_tris\": (%d+)"))
		if not (tris and tris >= 6000 and tris <= 9000 and H.has(body, "\"problems\": []")
			and H.has(body, "\"plot_problems\": []")) then
			table.insert(bad, variant .. " budget / self-check (" .. tostring(tris) .. " tris)")
		end
		for _, plot in ipairs(plots) do
			if not H.has(body, "\"" .. plot .. "\": \"fits\"") then
				table.insert(bad, variant .. " plot " .. plot)
			end
		end
	end
	local leftovers = {}
	for _, sub in ipairs({ "", "preview/" }) do
		for _, name in ipairs(H.fs.isDir(dir .. sub) and H.fs.readDir(dir .. sub) or {}) do
			if string.find(name, "SpiderHideout", 1, true) then
				table.insert(leftovers, sub .. name)
			end
		end
	end
	T.check(#bad == 0 and #leftovers == 0 and H.has(helper, "key = \"Desert\", name = \"BrooklynRooftop\", title = \"Brooklyn Rooftop\""),
		"Desert Brooklyn Rooftop v3 layout / FBX / .blend / renders / helper entry incomplete, over budget or not fitting a plot: %s; v2 leftovers: %s",
		list(bad), list(leftovers))
	T.check(H.has(src, "\"Desert\", \"BrooklynRooftop\", \"Brooklyn Rooftop\", \"Spider-Verse\"") and H.has(src, "def rail_run(")
		and H.has(src, "def pillow_brick(") and H.has(src, "def ladder(") and H.has(src, "def water_tower(")
		and H.has(src, "def spider_polys(") and H.has(src, "def gate_lintel(") and H.has(src, "def corner(")
		and not H.has(src, "Backdrop_"),
		"Desert Brooklyn Rooftop lost its own perimeter (brick parapet, fire-escape railing and ladders, chimney vents, water towers, the stepped spider)")
	local wrong = {}
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes/Desert")
	for _, model in ipairs(store and store:GetChildren() or {}) do
		local imported = model:GetAttribute("ImportedPen")
		if imported ~= nil then
			local depth = model:GetAttribute("PenDepth") or 0
			if imported ~= "BrooklynRooftop" or model:GetAttribute("ImportedVariant") ~= (if depth > 57.75 then "Deep" else "Std") then
				table.insert(wrong, model.Name .. "=" .. tostring(imported) .. "/" .. tostring(model:GetAttribute("ImportedVariant")))
			end
		end
	end
	T.check(store ~= nil and #store:GetChildren() >= 1 and #wrong == 0,
		"Desert per-plot base models missing, or an imported Brooklyn Rooftop on the wrong variant: %s", list(wrong))
end

-- 37. Jungle "U.A. Hero Arena" (base_themes/themes/jungle.py, API v3, owner art direction 2026-09-24): exactly one v3
--     layout in assets/models/bases/Jungle (the v2 U.A. Academy is gone) with its FBX, .blend and hero / gate / detail
--     renders; the stadium roles in both variants (white / navy / red barriers, the stadium-green pitch and turf stripes,
--     the gold + white "U.A." core, One For All green neon, floodlight lamps, the green screen bezel); 6000..9000 tris per
--     variant, no backdrop, no self-check or plot problems, Std + Deep together fit all six plots; the theme keeps its own
--     silhouette (fins leaning out, floodlight masts, the 3D "U.A."); any Jungle plot model (or the Index preview) using
--     the imported pen carries the arena parts, inert, with no backdrop.
do
	local dir = "assets/models/bases/Jungle"
	local text = H.fs.isFile(dir .. "/UAHeroArena.json") and H.fs.readFile(dir .. "/UAHeroArena.json") or ""
	local layouts, legacy = 0, 0
	for _, name in ipairs(H.fs.isDir(dir) and H.fs.readDir(dir) or {}) do
		if string.sub(name, -5) == ".json" then
			local body = H.fs.readFile(dir .. "/" .. name)
			if H.has(body, "\"format\": \"stealahero-base-theme/3\"") then
				layouts += 1
			elseif H.has(body, "\"format\": \"stealahero-base-theme/2\"") then
				legacy += 1
			end
		end
	end
	local absent = {}
	for _, role in ipairs({ "Floor_Base", "Floor_Turf", "Floor_White", "Structure_White", "Structure_Navy", "Structure_Red",
		"Core_3D_Gold", "Core_3D_White", "Core_3D_Navy", "Neon_Emissive_Green", "Neon_Emissive_Lamp", "Neon_Emissive_Screen" }) do
		if not H.has(text, "\"" .. role .. "\": {") then
			table.insert(absent, role)
		end
	end
	for _, file in ipairs({ "UAHeroArena.fbx", "UAHeroArena.blend", "preview/UAHeroArena_hero.png", "preview/UAHeroArena_gate.png",
		"preview/UAHeroArena_detail.png" }) do
		if not H.fs.isFile(dir .. "/" .. file) then
			table.insert(absent, file)
		end
	end
	if H.has(text, "Backdrop") then
		table.insert(absent, "(no backdrop role allowed)")
	end
	local variants, budget = 0, true
	for tris in string.gmatch(text, "\"total_tris\": (%d+)") do
		variants += 1
		budget = budget and tonumber(tris) >= 6000 and tonumber(tris) <= 9000
	end
	local fits, covered = {}, 0
	for plot in string.gmatch(text, "\"(%d+)\": \"fits\"") do
		fits[plot] = true
	end
	for i = 1, 6 do
		covered += if fits[tostring(i)] then 1 else 0
	end
	local _, clean = string.gsub(text, "\"problems\": %[%]", "")
	local _, plotClean = string.gsub(text, "\"plot_problems\": %[%]", "")
	T.check(layouts == 1 and legacy == 0 and #absent == 0 and variants == 2 and budget and covered == 6 and clean == 2
		and plotClean == 2,
		"Jungle U.A. Hero Arena layout: %d v3 / %d v2 layout(s), missing %s, %d variant(s) (6000..9000 tris: %s), %d/6 plots fit, %d/2 clean, %d/2 plot-clean",
		layouts, legacy, list(absent), variants, tostring(budget), covered, clean, plotClean)
	local srcPath = "scripts/tools/blender/base_themes/themes/jungle.py"
	local src = H.fs.isFile(srcPath) and H.fs.readFile(srcPath) or ""
	T.check(H.has(src, "\"Jungle\", \"UAHeroArena\", \"U.A. Hero Arena\"") and H.has(src, "FIN_EDGE") and H.has(src, "def post(")
		and H.has(src, "def corner(") and H.has(src, "MAST_RIB") and H.has(src, "glyphs_ua(") and not H.has(src, "def backdrop("),
		"themes/jungle.py lost the U.A. Hero Arena silhouette (outward fins, floodlight masts, the 3D U.A. relief) or grew a backdrop")
	local models = {}
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes/Jungle")
	for _, model in ipairs(store and store:GetChildren() or {}) do
		table.insert(models, model)
	end
	local preview = H.path(rs, "Assets/BaseThemes/Jungle")
	if preview then
		table.insert(models, preview)
	end
	local bad, imported = {}, 0
	for _, model in ipairs(models) do
		local pen = model:FindFirstChild("ThemeImportedPen")
		if pen then
			imported += 1
			local variant = model:GetAttribute("ImportedVariant")
			local inert = true
			for _, part in ipairs(pen:GetChildren()) do
				if part:IsA("BasePart") then
					inert = inert and part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch
				end
			end
			if not (model:GetAttribute("ImportedPen") == "UAHeroArena" and (variant == "Std" or variant == "Deep") and inert
				and pen:FindFirstChild("ThemeFloor_Base") and pen:FindFirstChild("ThemeStructure_White")
				and pen:FindFirstChild("ThemeCore_3D_Gold") and pen:FindFirstChild("ThemeNeon_Emissive_Green")
				and pen:FindFirstChild("ThemeNeon_Emissive_Screen") and model:FindFirstChild("ThemeBackdropImported") == nil) then
				table.insert(bad, model.Name)
			end
		end
	end
	T.check(#bad == 0, "Jungle models with an incomplete / collidable U.A. Hero Arena imported pen (or a backdrop): %s (%d using the import)",
		list(bad), imported)
end

-- 38. Snow "Capsule Corp Arena" (base_themes/themes/snow.py, THEME3_Snow 2026-09-25, API v3): the CapsuleCorp v3 layout
--     (Dragon Ball material-family roles, no backdrop, both variants 6000..9000 evaluated tris with no self-check or plot
--     problems, every real plot fits: Std 1/4/5, Deep 2/3/6) with its FBX, .blend, hero / gate / detail renders and its
--     Studio helper entry; the theme models its own perimeter (Capsule Corp domes, Bulma capsule studs), the 7 Dragon
--     Balls core and the Dragon Radar terminal.
do
	local dir = "assets/models/bases/Snow/"
	local text = H.fs.isFile(dir .. "CapsuleCorp.json") and H.fs.readFile(dir .. "CapsuleCorp.json") or ""
	local helperPath = "assets/models/bases/BaseThemesImport.lua"
	local helper = H.fs.isFile(helperPath) and H.fs.readFile(helperPath) or ""
	local srcPath = "scripts/tools/blender/base_themes/themes/snow.py"
	local src = H.fs.isFile(srcPath) and H.fs.readFile(srcPath) or ""
	local bad = {}
	if not (H.has(text, "\"format\": \"stealahero-base-theme/3\"") and H.has(text, "\"name\": \"CapsuleCorp\"")
		and H.has(text, "\"title\": \"Capsule Corp Arena\"")) then
		table.insert(bad, "v3 layout")
	end
	for _, file in ipairs({ "CapsuleCorp.fbx", "CapsuleCorp.blend", "preview/CapsuleCorp_hero.png", "preview/CapsuleCorp_gate.png",
		"preview/CapsuleCorp_detail.png" }) do
		if not H.fs.isFile(dir .. file) then
			table.insert(bad, file)
		end
	end
	for _, role in ipairs({ "Floor_Base", "Floor_Tile", "Neon_Emissive_Screen", "Structure_Pearl", "Structure_Orange", "Structure_Teal",
		"Structure_Radar", "Core_3D_Amber", "Core_3D_Red" }) do
		if not H.has(text, "\"" .. role .. "\": {") then
			table.insert(bad, "role " .. role)
		end
	end
	if H.has(text, "Backdrop") then
		table.insert(bad, "a backdrop role")
	end
	local variants = 0
	for tris in string.gmatch(text, "\"total_tris\": (%d+)") do
		variants += 1
		if tonumber(tris) < 6000 or tonumber(tris) > 9000 then
			table.insert(bad, "tris " .. tris)
		end
	end
	local _, clean = string.gsub(text, "\"problems\": %[%]", "")
	local _, plotClean = string.gsub(text, "\"plot_problems\": %[%]", "")
	local fits = 0
	for _ in string.gmatch(text, "\"%d\": \"fits\"") do
		fits += 1
	end
	if not H.has(helper, "key = \"Snow\", name = \"CapsuleCorp\", title = \"Capsule Corp Arena\", legacy = false") then
		table.insert(bad, "Studio helper entry")
	end
	for _, needle in ipairs({ "def span(", "def post(", "def corner(", "def gate_pylon(", "def gate_lintel(", "def emblem(",
		"def podium_ball(", "def dragon_ball(", "Dragon Radar", "def bm_ring_arc(" }) do
		if not H.has(src, needle) then
			table.insert(bad, "snow.py " .. needle)
		end
	end
	T.check(variants == 2 and clean == 2 and plotClean == 2 and fits == 6 and #bad == 0,
		"Snow Capsule Corp Arena v3 layout: %d variant(s), %d clean, %d plot-clean, %d/6 plots fit, problems: %s", variants,
		clean, plotClean, fits, list(bad))
end

-- 39. Volcano "Sunny Pirate Wharf" (base_themes/themes/volcano.py + sunny_ship.py, 2026-09-25): the v3 layout and FBX
--     exist (the old v2 ThousandSunny layout is gone), both variants hold 6000..9000 tris with no self-check or plot
--     problems, every real plot fits (Std 1/4/5, Deep 2/3/6), the Thousand Sunny keeps its four wind groups (Hull / Main /
--     Aft / Flag roles) and the lion's mane, the previews and the Studio helper entry exist, and the SunnyWind module (the
--     pivots of sunny_ship.py) and its client controller are in the place.
do
	local dir = "assets/models/bases/Volcano/"
	local text = H.fs.isFile(dir .. "SunnyPirateWharf.json") and H.fs.readFile(dir .. "SunnyPirateWharf.json") or ""
	local helperPath = "assets/models/bases/BaseThemesImport.lua"
	local helper = H.fs.isFile(helperPath) and H.fs.readFile(helperPath) or ""
	local bad = {}
	if not (H.has(text, "\"format\": \"stealahero-base-theme/3\"") and H.has(text, "\"name\": \"SunnyPirateWharf\"")
		and H.fs.isFile(dir .. "SunnyPirateWharf.fbx")) then
		table.insert(bad, "layout / FBX")
	end
	if H.fs.isFile(dir .. "ThousandSunny.json") then
		table.insert(bad, "old ThousandSunny.json still on disk")
	end
	local variants = 0
	for tris in string.gmatch(text, "\"total_tris\": (%d+)") do
		variants += 1
		if tonumber(tris) > 9000 or tonumber(tris) < 6000 then
			table.insert(bad, tris .. " tris")
		end
	end
	local _, clean = string.gsub(text, "\"problems\": %[%]", "")
	local _, plotClean = string.gsub(text, "\"plot_problems\": %[%]", "")
	local fits = {}
	for plot in string.gmatch(text, "\"(%d)\": \"fits\"") do
		fits[plot] = true
	end
	for plot = 1, 6 do
		if not fits[tostring(plot)] then
			table.insert(bad, "plot " .. plot .. " not fitting")
		end
	end
	for _, role in ipairs({ "Floor_Base", "Neon_Emissive_Screen", "Structure_SunnyHull_Plank", "Core_3D_SunnyHull_Orange",
		"Core_3D_SunnyMain_Sail", "Structure_SunnyAft_Red", "Core_3D_SunnyFlag_Wood" }) do
		if not H.has(text, "\"" .. role .. "\": {") then
			table.insert(bad, "role " .. role)
		end
	end
	for _, shot in ipairs({ "hero", "gate", "detail", "top", "sunny" }) do
		if not H.fs.isFile(dir .. "preview/SunnyPirateWharf_" .. shot .. ".png") then
			table.insert(bad, "preview " .. shot)
		end
	end
	local wind = H.path(rs, "Library/Modules/SunnyWind")
	local controller = H.path(sps, "Game/Plots/SunnyWindController")
	if not (wind and wind:IsA("ModuleScript") and H.has(wind.Source, "Main = CFrame.new(-0.35, 6.5, 0)")
		and controller and controller:IsA("LocalScript") and H.has(controller.Source, "SunnyOrigin")) then
		table.insert(bad, "SunnyWind module / controller")
	end
	T.check(variants == 2 and clean == 2 and plotClean == 2 and #bad == 0
		and H.has(helper, "key = \"Volcano\", name = \"SunnyPirateWharf\""),
		"Volcano Sunny Pirate Wharf layout: %d variant(s), %d/%d clean, problems: %s", variants, clean, plotClean, list(bad))
end

-- 40. Clips x HeroMotion coherence (INTEGRATE 2026-09-24): a clip that pumps the hero's accent (Accent effect) needs a
--     HeroMotion Accent to pump, a flying Move (no footsteps, clip-owned or hovering height) never belongs to a stomp hero
--     (its dust puffs fire per footfall), and all 6 themes have a Blender layout the Studio helper can file.
do
	local folder = H.path(rs, "Directory/HeroAnimations")
	local motionModule = H.path(rs, "Directory/HeroMotion")
	local motionChunk = motionModule and H.sandbox(motionModule.Source, { Color3 = H.roblox.Color3 }, "HeroMotion")
	local okMotion, motion = false, nil
	if motionChunk then
		okMotion, motion = pcall(motionChunk)
	end
	local bad = {}
	for _, hero in ipairs(PLAN.HEROES) do
		local id = hero[1]
		local module = folder and folder:FindFirstChild(id)
		local chunk = module and module:IsA("ModuleScript") and H.sandbox(module.Source, {}, id)
		local okLoad, data = false, nil
		if chunk then
			okLoad, data = pcall(chunk)
		end
		local entry = okMotion and motion.Heroes[id]
		if not (okLoad and type(data) == "table" and type(data.Clips) == "table" and entry) then
			table.insert(bad, id)
			continue
		end
		for clipName, clip in pairs(data.Clips) do
			for _, e in ipairs(clip.Effects or {}) do
				if e.Type == "Accent" and entry.Accent == nil then
					table.insert(bad, id .. "." .. clipName .. " pumps no Accent")
				end
			end
		end
		if entry.Style == "stomp" and data.Clips.Move and data.Clips.Move.Footsteps == false then
			table.insert(bad, id .. " stomps without footsteps")
		end
	end
	local helper = H.fs.isFile("assets/models/bases/BaseThemesImport.lua") and H.fs.readFile("assets/models/bases/BaseThemesImport.lua") or ""
	local themes = 0
	for _, key in ipairs({ "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }) do
		themes += if H.has(helper, "key = \"" .. key .. "\", name = \"") then 1 else 0
	end
	T.check(okMotion and #bad == 0 and themes == 6,
		"hero clips and HeroMotion disagree (%s) or the Studio helper lists %d/6 themes", list(bad), themes)
end

-- 41. UIFIX (2026-09-24, owner batch 1 / 3 / 9): (1) the Free Gift chest's opener sits ON the chest: the GroupReward
--     prompt host just over the lid (no line of sight, clickable, 8..20 studs, instant) and a TAP TO OPEN pill
--     (GiftChest.Lid.OpenHint + Button) that Game.HubFreeGift moves into PlayerGui; (3) every Sell Heroes money value
--     shows the HUD cash icon (SpFooter.CashIcon + SpCardTemplate.CashIcon), never the speed shoe; (9) the Index STAGE
--     BASES previews are the current plot (PlotPreview clone of Plots.1 + its themed props + PreviewDiorama), inert,
--     with no scripts / GUIs / prompts / sounds / CollectionService tags.
do
	local chest = H.path(ws, "Hub/FreeGift/GiftChest")
	local lid = chest and chest:FindFirstChild("Lid")
	local hint = lid and lid:FindFirstChild("OpenHint")
	local giftPart = H.path(ws, "__OBJECTS/GroupReward")
	local prompt = giftPart and giftPart:FindFirstChildOfClass("ProximityPrompt")
	local onLid = false
	if prompt and lid and giftPart:IsA("BasePart") then
		local g, l = giftPart.CFrame.Position, lid.CFrame.Position
		local flat = math.sqrt((g.X - l.X) ^ 2 + (g.Z - l.Z) ^ 2)
		onLid = flat <= 1.5 and g.Y > l.Y and g.Y - l.Y <= 3 and prompt.Enabled and not prompt.RequiresLineOfSight
			and prompt.ClickablePrompt and prompt.HoldDuration == 0 and prompt.MaxActivationDistance >= 8 and prompt.MaxActivationDistance <= 20
	end
	local giftClient = H.path(sps, "Game/HubFreeGift")
	T.check(onLid and hint ~= nil and hint:IsA("BillboardGui") and hint:FindFirstChild("Button") ~= nil and hint.StudsOffsetWorldSpace.Y > 1
		and giftClient ~= nil and H.has(giftClient.Source, "\"OpenHint\"") and H.has(giftClient.Source, "PromptShown"),
		"Free Gift: the tap-to-open prompt and the TAP TO OPEN pill must sit on the chest lid (GroupReward prompt, Lid.OpenHint, HubFreeGift)")

	local sell = H.path(sg, "AutoSell/Frame")
	local hudCash = H.imageId(H.path(sg, "Money/Bottom/Frame/Money/CurrencyIcon"))
	local footerIcon = sell and H.path(sell, "SpFooter/CashIcon")
	local cardIcon = sell and H.path(sell, "SpCardTemplate/CashIcon")
	local sellClient = H.path(sps, "GUI/SellHeroes")
	T.check(hudCash ~= nil and hudCash ~= 99458650446228 and footerIcon ~= nil and H.imageId(footerIcon) == hudCash
		and cardIcon ~= nil and H.imageId(cardIcon) == hudCash and sellClient ~= nil and H.has(sellClient.Source, "bindPriceRow(card)"),
		"Sell Heroes money icons must be the HUD cash icon %s (Total Value %s, card price %s)", tostring(hudCash),
		tostring(footerIcon and H.imageId(footerIcon)), tostring(cardIcon and H.imageId(cardIcon)))

	local previews = H.path(rs, "Assets/BaseThemes")
	local badPreviews = {}
	for _, key in ipairs({ "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }) do
		local model = previews and previews:FindFirstChild(key)
		local plotClone = model and model:FindFirstChild("PlotPreview")
		local ok = plotClone ~= nil and model:FindFirstChild("PreviewDiorama") ~= nil and H.path(plotClone, "ToUpdate/StarterPen") ~= nil
		for _, d in ipairs(if ok then model:GetDescendants() else {}) do
			if d:IsA("LuaSourceContainer") or d:IsA("LayerCollector") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector")
				or d:IsA("Sound") or #d:GetTags() > 0 or (d:IsA("BasePart") and (not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch)) then
				ok = false
				break
			end
		end
		if not ok then
			table.insert(badPreviews, key)
		end
	end
	T.check(previews ~= nil and #badPreviews == 0,
		"Index STAGE BASES previews must show the current plot (PlotPreview + PreviewDiorama, inert, no scripts / GUIs / tags): %s", list(badPreviews))
end

-- 42. Index stage bats (INDEXBATS, owner batch item 2 "Equip button in index for bats not working"): GearService answers
-- Network["Index: RequestEquipAreaBat"](sectionId, "Equip" | "Unequip") (StubService required first, so its "Not available"
-- placeholder can never win), the equipped stage bat replaces the Bat in the kit, and the stage card reads EQUIP / EQUIPPED / UNEQUIP.
do
	local gearSrc = H.path(sss, "GearService") and H.path(sss, "GearService").Source or ""
	local remote = H.path(rs, "Network/Index: RequestEquipAreaBat")
	local stubAt = string.find(gearSrc, "WaitForChild(\"StubService\"", 1, true)
	local bindAt = string.find(gearSrc, "remote.OnServerInvoke = function(player, sectionId, action)", 1, true)
	T.check(remote ~= nil and remote:IsA("RemoteFunction") and stubAt ~= nil and bindAt ~= nil and stubAt < bindAt
		and H.has(gearSrc, "\"Stage Index not complete\"") and H.has(gearSrc, "\"Profile not loaded\"")
		and H.has(gearSrc, "local EQUIPPED_BAT_FIELD = \"EquippedBat\"") and H.has(gearSrc, "ensureStarterGear(player, kitFor(player), MELEE_GEAR)"),
		"GearService must answer Index: RequestEquipAreaBat (after requiring StubService), validate the stage Index and deal profile.EquippedBat")
	local comp = H.path(sps, "GUI/Index/AreaIndexProgressComponent")
	local index = H.path(sps, "GUI/Index")
	local compSrc = comp and comp.Source or ""
	local indexSrc = index and index.Source or ""
	T.check(H.has(compSrc, "\"UNEQUIP\"") and H.has(compSrc, "\"EQUIPPED\"") and H.has(compSrc, "self._onAction(sectionId, \"Unequip\")")
		and H.has(indexSrc, "p35:_equipAreaBat(s2, action or \"Equip\")") and H.has(indexSrc, "v158.EquippedBat == v152.RewardGearId")
		and H.has(indexSrc, "\"EquippedBat\"") and H.has(indexSrc, "clone.Frame.ZIndex = math.max(clone.Frame.ZIndex, 2)"),
		"Index stage cards must equip / unequip the stage bat (EQUIP / EQUIPPED / UNEQUIP), keep EQUIP above the hero slots and re-render on EquippedBat")
	-- every stage's reward bat is a server-dealt melee tool with a gear config
	local shop = H.path(rs, "GearTools/ShopItems")
	local badBats = {}
	for _, area in ipairs(H.path(rs, "Directory/Areas/_Index") and H.path(rs, "Directory/Areas/_Index"):GetChildren() or {}) do
		local bat = string.match(area.Source, "IndexBatGearId%s*=%s*\"([^\"]+)\"")
		local tool = bat and shop and shop:FindFirstChild(bat)
		if tool == nil or not tool:IsA("Tool") or H.path(rs, "Directory/Gears/_Index/Other/" .. bat) == nil
			or not H.has(gearSrc, "[\"" .. bat .. "\"] = true") then
			table.insert(badBats, area.Name .. ":" .. tostring(bat))
		end
	end
	T.check(#badBats == 0, "stage bats without a ShopItems tool / gear config / GearService melee entry: %s", list(badBats))
	-- behaviour: dealing the kit with a stage bat swaps the Bat out of Backpack + StarterGear (and back), never doubles it
	local ensure = nil
	local pieces = { string.match(gearSrc, "local STARTER_GEAR%s*=%s*%b{}") or "" }
	for _, name in ipairs({ "prepareGearTool", "gearToolsIn", "ensureStarterGear" }) do
		table.insert(pieces, H.extractFunction(gearSrc, name) or ("error('" .. name .. " not found')"))
	end
	table.insert(pieces, "return ensureStarterGear")
	local chunk = H.sandbox(table.concat(pieces, "\n"), { shopItems = shop, hookTool = function() end, log = function() end }, "INDEXBATS kit")
	if chunk then
		local okLoad, loaded = pcall(chunk)
		ensure = if okLoad and type(loaded) == "function" then loaded else nil
	end
	local swapped = false
	if ensure and shop and shop:FindFirstChild("Forest Bat") then
		local backpack, starterGear, character = H.roblox.Instance.new("Folder"), H.roblox.Instance.new("Folder"), H.roblox.Instance.new("Folder")
		local player = { Name = "Tester", Parent = true, Character = character, FindFirstChildOfClass = function(_, className)
			return if className == "Backpack" then backpack elseif className == "StarterGear" then starterGear else nil
		end }
		local function names(container)
			local out = {}
			for _, c in ipairs(container:GetChildren()) do
				table.insert(out, c.Name)
			end
			table.sort(out)
			return table.concat(out, ",")
		end
		local melee = { ["Bat"] = true, ["Forest Bat"] = true }
		local okRun = pcall(ensure, player)
		okRun = okRun and pcall(ensure, player, { "Forest Bat", "Trap" }, melee)
		local stage = names(backpack) .. "|" .. names(starterGear)
		local fb = backpack:FindFirstChild("Forest Bat")
		local fbGear = fb and fb:GetAttribute("GearName")
		okRun = okRun and pcall(ensure, player, { "Bat", "Trap" }, melee)
		swapped = okRun and stage == "Forest Bat,Trap|Forest Bat,Trap" and fbGear == "Forest Bat"
			and names(backpack) == "Bat,Trap" and names(starterGear) == "Bat,Trap"
	end
	T.check(swapped, "GearService ensureStarterGear must swap the Bat for the equipped stage bat (Backpack + StarterGear) and back")
	-- (REVIEW_INDEXBATS) the stage card's UNEQUIP hover-arming reads mouse-only input: a phone tap fires MouseEnter right
	-- before Activated, so MouseEnter-based arming turned the first tap on EQUIPPED into an instant unequip.
	T.check(H.has(compSrc, "button.InputBegan") and H.has(compSrc, "Enum.UserInputType.MouseMovement")
		and not H.has(compSrc, "button.MouseEnter") and not H.has(compSrc, "button.MouseLeave"),
		"Index stage card: UNEQUIP hover-arming must use InputBegan / InputEnded MouseMovement, never MouseEnter / MouseLeave (touch)")
	-- a retired zone (Prehistoric / Cosmic / Abyss Ocean) keeps its Directory.Areas entry and a stronger bat, but the Index
	-- (Directory.StageArt) never shows it: a crafted request must not unlock it
	local gear24b = H.path(sss, "GearService")
	local gear24bSrc = gear24b and gear24b.Source or ""
	T.check(H.has(gear24bSrc, "action == \"Equip\" and not isIndexStage(sectionId)") and H.has(gear24bSrc, "FindFirstChild(\"StageArt\")"),
		"GearService must refuse to equip the bat of a zone the Index does not list (Directory.StageArt)")
end

-- 43. Money economy /125 (ECON 2026-09-24, owner: "lower the entire money system, Black Widow as a basis should be
--     giving like 4/s max"): the real GetRate (sandboxed) pays a normal-size Black Widow $1/s at 10 SpeedPower and ~$4/s
--     at the stage-1 cap (2,885 SP, x3.46); every money ladder / reward is on the same 1/125 scale, the base costs match
--     on both sides, old saves are converted once, and the plot lock price / Shop cash pack titles follow. Every
--     treadmill / trail rung is pinned; the offline claim pays (and shows) whole dollars and keeps the cents (REVIEW_ECON).
do
	local agu = H.path(rs, "Library/Util/AssetGenerationUtil")
	local bw = H.path(rs, "Directory/Assets/_Index/BlackWidow")
	local bwRate = bw and tonumber(string.match(bw.Source, "EarningRate%s*=%s*([%d%.]+)"))
	local stub = {
		Library = {
			Util = { MonetizationGamepassUtil = { GetAssetMoneyAdditiveRebirthBonus = function() return 0 end } },
			Types = { Monetization = {}, AssetItem = { AssetItemData = function() return true end } },
			Asserts = { finite = function() end, number = function() end },
			Modules = { Mutations = { GetTotalMutationsEarningMulti = function() return 1 end } },
			Signal = { Invoked = function() return {} end, MAP = { Shared = { AssetGenerationUtil = {} } } },
		},
		Directory = { Assets = { Directory = { BlackWidow = { EarningRate = bwRate } } } },
	}
	local chunk = agu and bwRate and H.sandbox(agu.Source, {
		game = { GetService = function() return stub end },
		require = function(m) return m end,
		script = { Parent = { RebirthUtil = { RebirthToMultiplier = function() return 1 end } } },
	}, "AssetGenerationUtil")
	local okLoad, util = false, nil
	if chunk then
		okLoad, util = pcall(chunk)
	end
	-- AssetService.earningRateFor / PlayerMoneyPerSecondUtil.ApplySpeedPower: round(GetRate x SpeedPower factor), >= 1
	local function paid(scale, speedPower)
		local rate = util.GetRate({ Category = "BlackWidow", Scale = scale, Mutations = {} }, 0)
		return math.max(math.round(rate * (1 + math.log10(math.max(speedPower, 10) / 10))), 1)
	end
	local okPay, fresh, capped = false, nil, nil
	if okLoad and type(util) == "table" then
		okPay, fresh, capped = pcall(function()
			return paid(1, 10), paid(1.05, 2885)
		end)
	end
	T.check(okPay and fresh == 1 and capped ~= nil and capped >= 3 and capped <= 5
		and math.abs((util.MONEY_SCALE or 0) - 1 / 125) < 1e-9 and H.has(agu.Source, "p1Scale ^ 1.85"),
		"money /125: a normal Black Widow must pay $1/s at 10 SP and ~$4/s at the stage-1 cap (got %s / %s)",
		tostring(fresh), tostring(capped))

	local LADDER = {
		["Directory/Treadmills/_Index"] = { Treadmill = 0, ["Sci-FiTreadmill"] = 1.6e6, FlameTreadmill = 12e6, CelebrityTreadmill = 60e6,
			GoldenTreadmill = 200e6, ["The FreezeTreadmill"] = 1e9, ["Lucky BlockTreadmill"] = 8e9, HackerTreadmill = 80e9,
			DemonicTreadmill = 800e9, AngelicTreadmill = 8e12 },
		["Directory/Trails/_Index"] = { GreyTrail = 200e3, GreenTrail = 2e6, BlueTrail = 20e6, PurpleTrail = 120e6, GoldenTrail = 600e6,
			RedTrail = 3.2e9, GalaxyTrail = 16e9, SecretTrail = 160e9, EternalTrail = 1.6e12, DivineTrail = 16e12 },
	}
	local worst = 0
	local offLadder = {}
	for folder, want in pairs(LADDER) do
		for name, price in pairs(want) do
			local m = H.path(rs, folder .. "/" .. name)
			local got = m and tonumber(string.match(m.Source, "\n%s*Price = ([%d%.e]+)"))
			worst = math.max(worst, got or 0)
			if got ~= price then
				table.insert(offLadder, name .. "=" .. tostring(got))
			end
		end
	end
	local plot = H.path(sss, "Controllers/PlotService")
	local bases = H.path(rs, "Directory/Bases")
	local costs, tiers = {}, {}
	local block = bases and string.match(bases.Source, "local t2 = (%b{})") or ""
	for n in string.gmatch(block, "\n%s*(%d[%d%.e]*)") do
		table.insert(costs, tonumber(n))
	end
	for lvl, cost in string.gmatch(plot and plot.Source or "", "%[(%d+)%] = { Cost = (%d+),") do
		tiers[tonumber(lvl)] = tonumber(cost)
	end
	local mismatch = {}
	for lvl = 1, 11 do
		if tiers[lvl] == nil or costs[lvl] ~= tiers[lvl] then
			table.insert(mismatch, tostring(lvl))
		end
	end
	T.check(#offLadder == 0 and worst == 16e12 and tiers[1] == 8 and tiers[2] == 400000 and #mismatch == 0,
		"money /125: treadmill / trail / base ladders not on the new scale (off: %s; base levels differing: %s)",
		list(offLadder), list(mismatch))

	local area = H.path(sss, "Controllers/AreaEggService")
	local db = H.path(sss, "Library/Database")
	local grind = H.path(sss, "Controllers/TreadmillGrindService")
	local packs = H.path(sss, "Controllers/ConsumableGamepassService")
	local offline = H.path(sss, "Controllers/OfflineAssetsService")
	T.check(area ~= nil and H.has(area.Source, "Common = 1,") and not H.has(area.Source, "Common = 150,")
		and db ~= nil and string.match(db.Source, "local defaults = {%s*Money = 2,") ~= nil
		and grind ~= nil and H.has(grind.Source, "TREADMILL_COINS_PER_SECOND = 0.08")
		and packs ~= nil and H.has(packs.Source, "Kind = \"Money\", Amount = 200 }") and not H.has(packs.Source, "Amount = 24000")
		and offline ~= nil and H.has(offline.Source, "MoneyScaleVersion") and H.has(offline.Source, "migrateMoneyScale(player, profile)")
		and H.has(offline.Source, "local claimable = claimableWholeDollars(profile)") and H.has(offline.Source, "local amount = claimableWholeDollars(profile)")
		and H.has(offline.Source, "OfflineClaimableAmount = remainder,"),
		"money /125: steal bounties / starting cash / treadmill coins / cash packs / old-save conversion / whole-dollar offline claim not on the new scale")

	local shopRoot = H.path(sg, "Shop/Frame/Main/ScrollingFrame")
	local wrongText = {}
	for path, want in pairs({ ["MoneyTop/1/Title"] = "$200", ["MoneyTop/2/Title"] = "$1,600", ["MoneyTop/3/Title"] = "$6,400",
		["MoneyBottom/1/Title"] = "$32,000", ["MoneyBottom/2/Title"] = "$64,000" }) do
		local label = shopRoot and H.path(shopRoot, path)
		if not (label and label.Text == want) then
			table.insert(wrongText, "Shop " .. path)
		end
	end
	for _, p in ipairs(H.path(ws, "Plots") and ws.Plots:GetChildren() or {}) do
		local price = H.path(p, "SpeedsterTreadmillDisplay/LockAnchor/LockBillboard/PricePill/Price")
		if price and price.Text ~= "$" .. tostring(tiers[1]) then
			table.insert(wrongText, "plot " .. p.Name .. " lock " .. price.Text)
		end
	end
	T.check(#wrongText == 0, "money /125: baked money texts not updated: %s", list(wrongText))
end

-- 44. Hub leaderboards (owner batch 2026-09-24 #6; HEROBOARD 2026-09-26: ONE wall-mounted HERO BOARD with a tab per stat
-- TOTAL NETWORTH / TOTAL SPEED / IN-GAME TIME / EGGS HATCHED + a top-3 podium, scripts/steps/post_x_hero_board.luau +
-- LeaderboardService; wall / tab / podium details in tests/smoke_heroboard.luau): the board and its podium stay inside
-- the hub, off the main street and the lane mouth, clear of the plots, stalls, Free Gift and spawn; stats persisted
do
	local heroBoard = H.path(ws, "Hub/HeroBoard")
	local spawn = ws:FindFirstChild("SpawnLocation")
	local obstacles = {}
	for _, root in ipairs({ ws:FindFirstChild("Plots"), ws:FindFirstChild("Stands"), H.path(ws, "Hub/FreeGift"), spawn,
		H.path(ws, "__OBJECTS/GroupReward") }) do
		local parts = root and (root:IsA("BasePart") and { root } or root:GetDescendants()) or {}
		for _, d in ipairs(parts) do
			if d:IsA("BasePart") and (d.Transparency < 1 or d.CanCollide) then
				local mn, mx = H.aabb(d)
				if mx.Y > 2.35 and (mx.X - mn.X) < 400 then
					table.insert(obstacles, { d, mn, mx })
				end
			end
		end
	end
	local bad = {}
	if heroBoard == nil or H.path(heroBoard, "Screen/BoardGui/Board/List/Pages") == nil or heroBoard:FindFirstChild("Podium") == nil then
		table.insert(bad, "Workspace.Hub.HeroBoard (screen pages + podium) missing")
	else
		local mn, mx = H.groupAabb(heroBoard)
		if heroBoard:GetAttribute("OwnerLayout") == true then
			-- the owner hung the board where they wanted it in Studio (post_zzz_owner_layout): no region rules
		elseif mx.X > 71.25 or mn.X < -99.6 or mn.Z < -211.03 or mx.Z > 215.97 then
			table.insert(bad, string.format("outside the hub (X %.1f..%.1f Z %.1f..%.1f)", mn.X, mx.X, mn.Z, mx.Z))
		end
		if mx.Z > -89 and mn.Z < 87 then
			table.insert(bad, string.format("on the main street / lane mouth (Z %.1f..%.1f)", mn.Z, mx.Z))
		end
		for _, o in ipairs(obstacles) do
			if mn.X < o[3].X + 1 and mx.X > o[2].X - 1 and mn.Z < o[3].Z + 1 and mx.Z > o[2].Z - 1 then
				table.insert(bad, "touches " .. o[1]:GetFullName())
				break
			end
		end
	end
	T.check(#bad == 0, "hub HERO BOARD: %s", list(bad))

	local service = sss:FindFirstChild("LeaderboardService")
	local src = service and H.normalize(service.Source) or ""
	T.check(H.has(src, "Networth = {") and H.has(src, "HeroSellPrice") and H.has(src, "EggSellPrice") and H.has(src, "profile.TimePlayed =")
		and H.has(src, "TimePlayed = { format = duration }") and H.has(src, "EggsHatched = { format = compact }"),
		"LeaderboardService must compute Networth (Money + hero / egg sell values), accrue TimePlayed and show EggsHatched")
	local db = H.path(sss, "Library/Database")
	local dbSrc = db and H.normalize(db.Source) or ""
	local _, timeDefaults = string.gsub(dbSrc, "\n%s*TimePlayed = 0,", "")
	local _, eggDefaults = string.gsub(dbSrc, "\n%s*EggsHatched = 0,", "")
	T.check(timeDefaults == 2 and eggDefaults == 2, "Database: TimePlayed / EggsHatched must be in defaults and NUMERIC_DEFAULTS (%d / %d)",
		timeDefaults, eggDefaults)
	local eggService = H.path(sss, "Controllers/EggService")
	local eggSrc = eggService and H.normalize(eggService.Source) or ""
	local hatch = string.match(eggSrc, "RequestCompleteHatchEggRemote%.OnServerInvoke = function.-\nend\n") or ""
	T.check(H.has(hatch, "profile.EggsHatched = math.floor(hatched) + 1") and H.has(hatch, "EggsHatched = profile.EggsHatched"),
		"EggService must count EggsHatched when a hatch completes (server-side)")

	-- owner batch #5: eggs growing on a plot are pass-through (no part of a placed egg collides with characters)
	local renderer = H.path(rs, "Library/Client/Eggs/EggRenderer")
	local rSrc = renderer and H.normalize(renderer.Source) or ""
	local policy = string.match(rSrc, "function t1%.ApplyPlacedCollisionPolicy%(p3%).-\nend\n") or ""
	T.check(policy ~= "" and H.has(policy, "descendant.CanCollide = false") and not H.has(policy, "CanCollide = not")
		and not H.has(policy, "CanCollide = true"), "EggRenderer.ApplyPlacedCollisionPolicy must make every placed-egg part CanCollide = false")
end

-- 45. Pen hero animation polish (ANIMPOLISH 2026-09-24): every stepping Move is foot-locked (a ground Speed + dense leg
--     tracks from scripts/tools/blender/hero_anim/footlock.py), HeroClipPlayer plays it at the ground speed, looks at
--     the viewer, tucks in jumps and throttles by distance / screen; the wander simulation keeps heroes apart, off the
--     fence and out of the pen's terminal / eggs (AssetPenSpace) and inside the speed band their clip plays
--     (HeroMotion Pace / CadenceRange); floaters hover at their own height.
do
	local folder = H.path(rs, "Directory/HeroAnimations")
	local aac = H.path(sps, "Game/Plots/ActiveAssetsController")
	local unlocked, stepping = {}, 0
	for _, module in ipairs(folder and folder:GetChildren() or {}) do
		local chunk = module:IsA("ModuleScript") and H.sandbox(module.Source, {}, module.Name)
		local okLoad, data = false, nil
		if chunk then
			okLoad, data = pcall(chunk)
		end
		local move = okLoad and type(data) == "table" and type(data.Clips) == "table" and data.Clips.Move or nil
		if move and move.Footsteps ~= false then
			stepping += 1
			local hip = move.Tracks and move.Tracks.LeftHip
			if type(move.Speed) ~= "number" or move.Speed <= 0.5 or type(hip) ~= "table" or #hip < 16 then
				table.insert(unlocked, module.Name)
			end
		end
	end
	T.check(stepping >= 20 and #unlocked == 0,
		"stepping Move clips must be foot-locked (speed=\"auto\": a Speed + dense leg keys), %d stepping, unlocked: %s",
		stepping, list(unlocked))
	local player = aac and aac:FindFirstChild("HeroClipPlayer")
	local comp = aac and aac:FindFirstChild("AssetComponent")
	local sim = aac and aac:FindFirstChild("AssetWanderSimulator")
	local wander = aac and aac:FindFirstChild("AssetWanderMotion")
	local space = aac and aac:FindFirstChild("AssetPenSpace")
	local motion = aac and aac:FindFirstChild("AssetHeroMotion")
	T.check(player ~= nil and comp ~= nil and sim ~= nil and wander ~= nil and space ~= nil and motion ~= nil
		and H.has(player.Source, "self._speed / (move.Speed * self._scale)") and H.has(player.Source, "function HeroClipPlayer.GetGait(")
		and H.has(player.Source, "function HeroClipPlayer.SetLookTarget(") and H.has(player.Source, "self._poseInterval")
		and H.has(comp.Source, "SetSpeedProfile(t1._paceProfile(") and H.has(comp.Source, "p28:_stepClips(n6, v124, v126, b6, v125)")
		and H.has(comp.Source, "clips:SetLookTarget(") and H.has(comp.Source, "_wanderSimulator:ExtendIdle(")
		and H.has(sim.Source, "local AssetPenSpace = require(script.Parent.AssetPenSpace)") and H.has(sim.Source, "function t1.SetFootprint(")
		and H.has(sim.Source, "AssetWanderArea.ClampKeepHeight(") and H.has(wander.Source, "local TURN_RATE_MAX")
		and H.has(space.Source, "function AssetPenSpace.Steer(") and H.has(space.Source, "PlacedEggRenders")
		and H.has(motion.Source, "function AssetHeroMotion.SetGaitPhase("),
		"pen hero polish must be wired: clip cadence / look / LOD, pace profile, pen space (spacing, eggs, terminal), smooth turns")
	local motionModule = H.path(rs, "Directory/HeroMotion")
	local motionChunk = motionModule and H.sandbox(motionModule.Source, { Color3 = H.roblox.Color3 }, "HeroMotion")
	local okMotion, heroMotion = false, nil
	if motionChunk then
		okMotion, heroMotion = pcall(motionChunk)
	end
	local noHover = {}
	if okMotion and type(heroMotion) == "table" and type(heroMotion.Heroes) == "table" then
		for id, entry in pairs(heroMotion.Heroes) do
			if entry.Style == "float" and type(entry.Hover) ~= "number" then
				table.insert(noHover, id)
			end
		end
	end
	local styles = okMotion and type(heroMotion) == "table" and heroMotion.Styles or {}
	T.check(okMotion and type(heroMotion.Pace) == "table" and #noHover == 0 and styles.walk and styles.walk.CadenceRange ~= nil
		and styles.stomp and styles.stomp.CadenceRange ~= nil and styles.stomp.CadenceRange[2] <= 1.6,
		"Directory.HeroMotion needs Pace, a CadenceRange per stepping style (stomp stays heavy) and a Hover per floater (missing: %s)",
		list(noHover))
end

-- 46. Bases v3 framework (BASECORE3 2026-09-24 + Astra 2026-09-25, owner art direction: no backdrops, one silhouette per
--     base, 3D reliefs, bevelled toy plastic): every stage has exactly one v3 layout on disk and a non-legacy Studio
--     helper entry, the six-base coherence sheet exists, the v3 framework (own perimeter per theme, studs / reliefs,
--     Bevel ANGLE + Weighted Normal stack, coherence sheet, no backdrop API) is intact, and no backdrop is left in any
--     built theme model or Index preview. (The Forest layout itself: section 47.)
do
	local helperPath = "assets/models/bases/BaseThemesImport.lua"
	local helper = H.fs.isFile(helperPath) and H.fs.readFile(helperPath) or ""
	local bad = {}
	for _, key in ipairs({ "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }) do
		local dir = "assets/models/bases/" .. key
		local v3 = {}
		for _, name in ipairs(H.fs.isDir(dir) and H.fs.readDir(dir) or {}) do
			if string.sub(name, -5) == ".json" and H.has(H.fs.readFile(dir .. "/" .. name), "\"format\": \"stealahero-base-theme/3\"") then
				table.insert(v3, string.sub(name, 1, -6))
			end
		end
		if #v3 ~= 1 then
			table.insert(bad, key .. " has " .. #v3 .. " v3 layouts")
		elseif not H.has(helper, "key = \"" .. key .. "\", name = \"" .. v3[1] .. "\", title = ")
			or not string.find(helper, "key = \"" .. key .. "\", name = \"" .. v3[1] .. "\", title = \"[^\"]+\", legacy = false", 1) then
			table.insert(bad, key .. " helper entry")
		end
	end
	if not H.fs.isFile("assets/models/bases/preview/_coherence.png") then
		table.insert(bad, "preview/_coherence.png")
	end
	T.check(#bad == 0, "base themes v3: one layout per stage, a non-legacy helper entry each and the coherence sheet: %s", list(bad))
	local common = H.fs.isFile("scripts/tools/blender/base_themes/common.py") and H.fs.readFile("scripts/tools/blender/base_themes/common.py") or ""
	local pipeline = H.fs.isFile("scripts/tools/blender/base_themes/pipeline.py") and H.fs.readFile("scripts/tools/blender/base_themes/pipeline.py") or ""
	T.check(H.has(common, "FORMAT = \"stealahero-base-theme/3\"") and H.has(common, "OWN_MODULES = (") and not H.has(common, "def backdrop_frame(")
		and H.has(common, "def stud(") and H.has(common, "def relief(") and H.has(pipeline, "bv.limit_method = \"ANGLE\"")
		and H.has(pipeline, "\"WEIGHTED_NORMAL\"") and H.has(pipeline, "def coherence_sheet("),
		"base theme framework v3 incomplete (own-perimeter rule, studs / reliefs, Bevel ANGLE + Weighted Normal stack, coherence sheet)")
	-- no backdrop anywhere: the loader source, every built per-plot model, every Index preview
	local step = H.fs.readFile("scripts/steps/post_zz_base_themes.luau")
	local left = {}
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes")
	local roots = {}
	for _, folder in ipairs(store and store:GetChildren() or {}) do
		for _, model in ipairs(folder:GetChildren()) do
			table.insert(roots, { folder.Name .. "/" .. model.Name, model })
		end
	end
	for _, model in ipairs(H.path(rs, "Assets/BaseThemes") and rs.Assets.BaseThemes:GetChildren() or {}) do
		table.insert(roots, { "preview/" .. model.Name, model })
	end
	for _, entry in ipairs(roots) do
		for _, d in ipairs(entry[2]:GetDescendants()) do
			if string.sub(d.Name, 1, 13) == "ThemeBackdrop" then
				table.insert(left, entry[1] .. "." .. d.Name)
				break
			end
		end
	end
	T.check(not H.has(step, "B.group(\"Backdrop") and H.has(step, "Step.BACK_MAX = 2.0") and #roots >= 36 and #left == 0,
		"base themes still carry a backdrop (owner: plots stay open): %s (%d models checked)", list(left), #roots)
end

-- 47. Forest "Stark Lab" polish (THEME3_Forest_Polish 2026-09-25, Astra's approved graphite / steel / glass tower
--     design kept): the v3 layout is clean in both variants (6000..9000 tris, no contract or plot problems, all six
--     plots fit), keeps the Stark Lab palette with no backdrop, its FBX / .blend / previews (incl. the player-height
--     shots) are on disk, and scripts/tools/blender/base_themes/verify_forest.py passed: no floating piece and no
--     coplanar (z-fighting) faces in either variant, validated against the real plots' obstacles.
do
	local dir = "assets/models/bases/Forest/"
	local text = H.fs.isFile(dir .. "StarkLab.json") and H.fs.readFile(dir .. "StarkLab.json") or ""
	local bad = {}
	if not H.has(text, "\"format\": \"stealahero-base-theme/3\"") then
		table.insert(bad, "format")
	end
	for _, role in ipairs({ "Floor_Base", "Neon_Emissive_Screen", "Structure_Graphite", "Structure_Steel", "Structure_Glazing",
		"Core_3D_Silver" }) do
		if not H.has(text, "\"" .. role .. "\": {") then
			table.insert(bad, "role " .. role)
		end
	end
	if H.has(text, "Backdrop") then
		table.insert(bad, "a backdrop role")
	end
	for _, file in ipairs({ "StarkLab.fbx", "StarkLab.blend", "preview/StarkLab_hero.png", "preview/StarkLab_gate.png",
		"preview/StarkLab_detail.png", "preview/StarkLab_top.png", "preview/StarkLab_gate_joint.png",
		"preview/StarkLab_player_out.png", "preview/StarkLab_player_in.png", "reference/validation.json" }) do
		if not H.fs.isFile(dir .. file) then
			table.insert(bad, file)
		end
	end
	local variants = 0
	for tris in string.gmatch(text, "\"total_tris\": (%d+)") do
		variants += 1
		if tonumber(tris) < 6000 or tonumber(tris) > 9000 then
			table.insert(bad, "tris " .. tris)
		end
	end
	local _, clean = string.gsub(text, "\"problems\": %[%]", "")
	local _, plotClean = string.gsub(text, "\"plot_problems\": %[%]", "")
	local fits = 0
	for _ in string.gmatch(text, "\"%d\": \"fits\"") do
		fits += 1
	end
	T.check(variants == 2 and clean == 2 and plotClean == 2 and fits == 6 and #bad == 0,
		"Forest Stark Lab layout: %d variant(s), %d / %d clean, %d/6 plots fit, problems: %s", variants, clean, plotClean, fits, list(bad))
	local report = H.fs.isFile(dir .. "reference/validation.json") and H.fs.readFile(dir .. "reference/validation.json") or ""
	local _, noFloat = string.gsub(report, "\"floating_pieces\": 0", "")
	local _, noFight = string.gsub(report, "\"coplanar_faces\": 0", "")
	T.check(H.has(report, "\"ok\": true") and noFloat == 2 and noFight == 2 and H.has(report, "plot_obstacles.json"),
		"Forest Stark Lab not verified (run verify_forest.py): ok / floating / coplanar per variant = %s / %d / %d",
		tostring(H.has(report, "\"ok\": true")), noFloat, noFight)
end

-- 48. No Neon anywhere in the bases, and no stale import placed (owner 2026-09-25: "remove ALL the neon from the bases,
--     it is very disruptive for the players"; INTEGRATE_BASES_V4): every stage's layout JSON declares policy neon /
--     lights false, has no Neon palette or window material, no base light in either variant and a geometry fingerprint;
--     common.py bans Neon, the six theme sources never ask for it and the build keeps its guards (post_zz
--     Step.assertNoNeon, ui_80's preview guard); no BasePart under ServerStorage.BaseThemes, the Index previews or a
--     plot's ThemeProps is Neon and no Light is left there (window panes included); and a stage uses its Studio import
--     (assets/models/bases/<Key>/<Name>.rbxm, or STEALAHERO_BASE_IMPORTS like the build) only when the import is the
--     layout's CURRENT geometry (its GeometryFingerprint stamp, or Step.PRESTAMP_IMPORTS for the owner's unstamped
--     imports): then every plot the layout fits (and the Index preview) carries it, restyled from the neon-free palette;
--     a stale import (a redesign not re-imported yet) is never placed and the stage keeps its procedural theme.
do
	local okSerde, serde = pcall(function()
		return require("@lune/serde")
	end)
	local okProcess, process = pcall(function()
		return require("@lune/process")
	end)
	local importsRoot = (okProcess and process.env.STEALAHERO_BASE_IMPORTS) or "assets/models/bases"
	local step = H.fs.isFile("scripts/steps/post_zz_base_themes.luau") and H.fs.readFile("scripts/steps/post_zz_base_themes.luau") or ""
	local prestamp = {}
	for name, fp in string.gmatch(string.match(step, "Step%.PRESTAMP_IMPORTS = (%b{})") or "", "(%w+) = \"(g1:%x+)\"") do
		prestamp[name] = fp
	end
	local layouts, bad = {}, {}
	for _, key in ipairs({ "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano" }) do
		local dir = "assets/models/bases/" .. key
		for _, file in ipairs(H.fs.isDir(dir) and H.fs.readDir(dir) or {}) do
			local text = string.sub(file, -5) == ".json" and H.fs.readFile(dir .. "/" .. file) or ""
			if H.has(text, "\"format\": \"stealahero-base-theme/3\"") then
				local ok, layout = pcall(function()
					return serde.decode("json", text)
				end)
				if not (okSerde and ok and type(layout) == "table") then
					table.insert(bad, key .. " unreadable " .. file)
					continue
				end
				layouts[key] = layout
				local policy = layout.policy or {}
				if policy.neon ~= false or policy.lights ~= false then
					table.insert(bad, key .. " policy neon / lights not false")
				end
				for role, look in pairs(layout.palette or {}) do
					if look.material == "Neon" then
						table.insert(bad, key .. " palette " .. role .. " is Neon")
					end
				end
				for vname, variant in pairs(layout.variants or {}) do
					if #(variant.lights or {}) > 0 then
						table.insert(bad, string.format("%s %s has %d light(s)", key, vname, #variant.lights))
					end
				end
				if layout.window_lights and layout.window_lights.material == "Neon" then
					table.insert(bad, key .. " window_lights material Neon")
				end
				if type(layout.geometry_fingerprint) ~= "string" or not string.match(layout.geometry_fingerprint, "^g1:%x+$") then
					table.insert(bad, key .. " geometry_fingerprint")
				end
			end
		end
		if layouts[key] == nil then
			table.insert(bad, key .. " has no readable v3 layout")
		end
	end
	T.check(#bad == 0 and next(prestamp) ~= nil, "base layouts not neon-free (policy / palette / lights / fingerprint): %s%s", list(bad),
		if next(prestamp) == nil then " (Step.PRESTAMP_IMPORTS not found)" else "")

	-- the framework, the six theme sources and the build guards
	local common = H.fs.isFile("scripts/tools/blender/base_themes/common.py") and H.fs.readFile("scripts/tools/blender/base_themes/common.py") or ""
	local ui80 = H.fs.isFile("scripts/steps/ui_80_plot_viewports.luau") and H.fs.readFile("scripts/steps/ui_80_plot_viewports.luau") or ""
	local sources = {}
	for _, file in ipairs({ "forest", "lake", "desert", "jungle", "snow", "volcano", "sunny_ship" }) do
		local path = "scripts/tools/blender/base_themes/themes/" .. file .. ".py"
		local src = H.fs.isFile(path) and H.fs.readFile(path) or nil
		if src == nil or H.has(src, "\"Neon\"") or H.has(src, "'Neon'") then
			table.insert(sources, file .. ".py")
		end
	end
	T.check(H.has(common, "BANNED_MATERIALS = {\"Neon\":") and H.has(common, "MAX_LIGHTS = 0") and #sources == 0
		and H.has(step, "Step.BANNED_MATERIALS = { Neon = \"SmoothPlastic\" }") and H.has(step, "function Step.assertNoNeon(")
		and H.has(step, "Step.assertNoNeon({ { serverFolder,") and H.has(ui80, "assertNoNeon(previews)"),
		"no-neon guards missing (common.py ban / MAX_LIGHTS, post_zz assertNoNeon, ui_80 guard) or a theme asks for Neon: %s", list(sources))

	-- the built place: per-plot models, Index previews, any plot's ThemeProps
	local roots = {}
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes")
	for _, folder in ipairs(store and store:GetChildren() or {}) do
		for _, model in ipairs(folder:GetChildren()) do
			table.insert(roots, { folder.Name .. "/" .. model.Name, model })
		end
	end
	for _, model in ipairs(H.path(rs, "Assets/BaseThemes") and rs.Assets.BaseThemes:GetChildren() or {}) do
		table.insert(roots, { "preview/" .. model.Name, model })
	end
	for _, plot in ipairs(H.path(ws, "Plots") and ws.Plots:GetChildren() or {}) do
		for _, child in ipairs(plot:GetChildren()) do
			if child.Name == "ThemeProps" then
				table.insert(roots, { "Plots." .. plot.Name .. ".ThemeProps", child })
			end
		end
	end
	local neon, lights, parts, panes = {}, {}, 0, 0
	for _, entry in ipairs(roots) do
		for _, d in ipairs(entry[2]:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
				if d.Name == "ThemeWindowPane" then
					panes += 1
				end
				if d.Material == Enum.Material.Neon then
					table.insert(neon, entry[1] .. "." .. d.Name)
				end
			elseif d:IsA("Light") then
				table.insert(lights, entry[1] .. "." .. d.Name)
			end
		end
	end
	T.check(#roots >= 42 and parts > 0 and #neon == 0 and #lights == 0,
		"Neon / lights left in the bases (%d models, %d parts, %d window panes): %d Neon (%s), %d light(s) (%s)",
		#roots, parts, panes, #neon, list(neon), #lights, list(lights))

	-- imports: placed only when current, and then on every plot the layout fits, restyled from the palette
	local stale, wrong = {}, {}
	for key, layout in pairs(layouts) do
		local path = string.format("%s/%s/%s", importsRoot, key, tostring(layout.import or (tostring(layout.name) .. ".rbxm")))
		local current, stamp = false, nil
		if H.fs.isFile(path) then
			local ok, importRoots = pcall(H.roblox.deserializeModel, H.fs.readFile(path))
			for _, root in ipairs(ok and importRoots or {}) do
				local value = root:GetAttribute("GeometryFingerprint")
				if type(value) == "string" and value ~= "" then
					stamp = value
					break
				end
			end
			current = ok and (stamp or prestamp[layout.name]) == layout.geometry_fingerprint
		end
		local fits = 0
		for _, variant in pairs(layout.variants or {}) do
			for _, verdict in pairs(variant.plots or {}) do
				if verdict == "fits" then
					fits += 1
				end
			end
		end
		local folder = store and store:FindFirstChild(key)
		local placed = 0
		for _, model in ipairs(folder and folder:GetChildren() or {}) do
			local pen = model:FindFirstChild("ThemeImportedPen")
			if pen ~= nil or model:GetAttribute("ImportedPen") ~= nil then
				placed += 1
				if model:GetAttribute("ImportedPen") ~= layout.name then
					table.insert(wrong, key .. "/" .. model.Name .. " ImportedPen " .. tostring(model:GetAttribute("ImportedPen")))
				end
				for _, part in ipairs(pen and pen:GetDescendants() or {}) do
					local role = part:IsA("BasePart") and string.sub(part.Name, 1, 5) == "Theme" and string.sub(part.Name, 6)
					local look = role and layout.palette[role]
					if look then
						local material = if look.material == "Neon" then "SmoothPlastic" else look.material
						local rgb = look.rgb or { -1, -1, -1 }
						local c = part.Color
						if part.Material.Name ~= material or math.abs(c.R * 255 - rgb[1]) > 1.5 or math.abs(c.G * 255 - rgb[2]) > 1.5
							or math.abs(c.B * 255 - rgb[3]) > 1.5 then
							table.insert(wrong, string.format("%s/%s %s %s", key, model.Name, part.Name, part.Material.Name))
							break
						end
					end
				end
			end
		end
		local preview = H.path(rs, "Assets/BaseThemes/" .. key)
		local previewImported = preview ~= nil and preview:FindFirstChild("ThemeImportedPen") ~= nil
		if current and (placed ~= fits or not previewImported) then
			table.insert(wrong, string.format("%s current import placed on %d/%d plots (preview %s)", key, placed, fits, tostring(previewImported)))
		elseif not current and (placed > 0 or previewImported) then
			table.insert(wrong, string.format("%s STALE import (%s) placed on %d plots (preview %s)", key, tostring(stamp or prestamp[layout.name]),
				placed, tostring(previewImported)))
		end
		if not current then
			table.insert(stale, key)
		end
	end
	table.sort(stale)
	T.check(#wrong == 0, "base imports: a stale import placed, a current one missing or not restyled from the palette (stale: %s): %s",
		list(stale), list(wrong))
end

-- 49. Base window lights (post_zz_base_themes section 8, owner 2026-09-25, SPIDER2): the flicker client is injected and compiles
--     (StarterPlayerScripts.Game.Plots.BaseWindowLights: tag BaseWindowLights, no RunService, tweens only); wherever an
--     imported pen whose layout lists window slots is placed, its ThemeWindows group sits NEXT TO ThemeImportedPen, is
--     tagged, holds exactly one inert SmoothPlastic ThemeWindowPane per slot (no shadow, never Neon, no lights); the
--     Index preview keeps them static (untagged).
do
	local serde = require("@lune/serde")
	local script = sps and H.path(sps, "Game/Plots/BaseWindowLights")
	local src = script and script.Source or ""
	T.check(script ~= nil and script:IsA("LocalScript") and H.has(src, "\"BaseWindowLights\"") and H.has(src, "TweenService")
		and not H.has(src, "RunService") and pcall(H.luau.compile, src),
		"StarterPlayerScripts.Game.Plots.BaseWindowLights (window flicker client) missing, not compiling or per-frame")
	local store = H.path(place:GetService("ServerStorage"), "BaseThemes")
	local bad, panesSeen = {}, 0
	for _, folder in ipairs(store and store:GetChildren() or {}) do
		for _, model in ipairs(folder:GetChildren()) do
			local pen = model:FindFirstChild("ThemeImportedPen")
			local group = model:FindFirstChild("ThemeWindows")
			local layoutName = pen and pen:GetAttribute("ImportedPen")
			local path = layoutName and string.format("assets/models/bases/%s/%s.json", folder.Name, layoutName)
			local layout = path and H.fs.isFile(path) and serde.decode("json", H.fs.readFile(path))
			local variant = layout and layout.variants[pen:GetAttribute("ImportedVariant")]
			local want = variant and variant.windows and #variant.windows or 0
			local tag = folder.Name .. "/" .. model.Name
			if (pen == nil and group ~= nil) or (pen ~= nil and want > 0 and group == nil) then
				table.insert(bad, tag .. " panes without their pen / missing")
			elseif group then
				local n = 0
				for _, part in ipairs(group:GetChildren()) do
					n += 1
					if not (part.ClassName == "Part" and part.Name == "ThemeWindowPane" and part.Anchored and not part.CanCollide
						and not part.CanQuery and not part.CanTouch and not part.CastShadow
						and part.Material == Enum.Material.SmoothPlastic and #part:GetChildren() == 0) then
						table.insert(bad, tag .. "." .. part.Name)
						break
					end
				end
				panesSeen += n
				if n ~= want or not group:HasTag("BaseWindowLights") or group:FindFirstAncestor("ThemeImportedPen") then
					table.insert(bad, string.format("%s %d/%d panes, tagged %s", tag, n, want, tostring(group:HasTag("BaseWindowLights"))))
				end
			end
		end
	end
	for _, preview in ipairs(H.path(rs, "Assets/BaseThemes") and rs.Assets.BaseThemes:GetChildren() or {}) do
		local group = preview:FindFirstChild("ThemeWindows")
		for _, d in ipairs(group and { group, table.unpack(group:GetDescendants()) } or {}) do
			if #d:GetTags() > 0 then
				table.insert(bad, "preview " .. preview.Name .. " keeps the BaseWindowLights tag")
				break
			end
		end
	end
	T.check(#bad == 0, "base window panes wrong (%d panes checked): %s", panesSeen, list(bad))
end

-- 50. No neon in the base theme directory (owner 2026-09-25: "remove ALL the neon from the bases"): the procedural
--     fallback recolours the fence gems from Directory.BaseThemes FenceMaterials, so no theme may ask for Neon.
do
	local directory = H.path(rs, "Directory/BaseThemes")
	T.check(directory ~= nil and not H.has(directory.Source, '"Neon"'), "Directory.BaseThemes still asks for Neon (fence gems)")
end
