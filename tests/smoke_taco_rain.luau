--!nocheck
-- tests/smoke_taco_rain.luau (owner 2026-09-27, admin panel round 10: "migrate the taco event to the admin panel: a rain
-- of tacos, a chance a taco falls on an egg in your base or on the stages, which multiplies that egg x3, with the taco
-- explosion VFX, the taco particle emitter and the taco music"). Joins the "smoke" filter. Checks, against the built place:
--   1. the Taco mutation: injected Library.Modules.Mutations (= its src mirror) holds Taco with ValueMulti 3, DropWeight 0
--      and its FX from ReplicatedStorage.Mutation_FX.Taco (taco emitters derived from the event's own);
--   2. the vendored event assets (vendor/taco_rain.rbxm -> ReplicatedStorage.Assets.VFX.TacoRain): the taco mesh, the
--      StruckVFX explosion and the TacoAmbient sky, every emitter disabled in storage, textures from those games;
--   3. the music: the only non-Speedsters id (142376088) is on exactly one Sound (SoundService.TacoRainMusic, looped,
--      silent, in the Music group) and in the audio step's whitelist with the owner's comment;
--   4. the wiring: TacoRainService / TacoRainController injected and compiling, the remote, the admin buttons, the
--      AreaEggService and EggRenderer hooks;
--   5. TacoRainService in a sandbox: a taco aimed at a placed egg gives it the mutation (saved + broadcast) and a Hit, a
--      stage egg goes through AreaEggService.AddRestingEggMutation, an egg is never aimed at twice, an egg that already
--      has the mutation is skipped, a missing egg makes a Miss.

local place = H.place()
local roblox = H.roblox
local rs = place:GetService("ReplicatedStorage")
local sss = place:GetService("ServerScriptService")
local sps = place:GetService("StarterPlayer").StarterPlayerScripts

local function src(inst)
	return inst and H.normalize(inst.Source) or ""
end
local function compiles(inst)
	return inst ~= nil and pcall(H.luau.compile, src(inst))
end

-- 1. the mutation ------------------------------------------------------------------------------------------------
local mutations = H.path(rs, "Library/Modules/Mutations")
local mutationSrc = src(mutations)
T.check(compiles(mutations) and mutationSrc == H.normalize(H.fs.readFile("src/ReplicatedStorage/Library/Modules/Mutations.luau")),
	"Library.Modules.Mutations must be the injected src mirror (with the Taco mutation) and compile")
local block = string.match(mutationSrc, "\n\tTaco = {(.-)\n\t}")
T.check(block ~= nil and H.has(block, 'Name = "Taco"') and string.match(block, "ValueMulti = 3%.?0?,") ~= nil
	and string.match(block, "DropWeight = 0%.?0?,") ~= nil and H.has(block, "Odds = 0") and H.has(block, 'applyVFXToFXPartWithTag(p192, "Taco", "Cleanup_TacoFX")')
	and H.has(block, 'clearFXFromTag(p193, "Cleanup_TacoFX")'), "Mutations.Taco must be x3 (ValueMulti 3), never rolled (DropWeight 0) with the taco FX")
local fx = H.path(rs, "Mutation_FX/Taco")
local fxEmitters, fxTextures = 0, {}
for _, d in ipairs(fx and fx:GetChildren() or {}) do
	if d:IsA("ParticleEmitter") and d:GetAttribute("EggVfx") == true then
		fxEmitters += 1
		fxTextures[tostring(H.assetId(H.uri(d, "TextureContent")))] = true
	end
end
T.check(fxEmitters >= 2 and fxTextures["84855954319870"] and fxTextures["13802408466"],
	"Mutation_FX.Taco must hold the taco / flake emitters (EggVfx), found %d", fxEmitters)

-- 2. the event assets --------------------------------------------------------------------------------------------
T.check(H.fs.isFile("vendor/taco_rain.rbxm"), "vendor/taco_rain.rbxm missing (lune run scripts/tools/vendor_taco_rain.luau)")
local assets = H.path(rs, "Assets/VFX/TacoRain")
local taco = assets and assets:FindFirstChild("Taco")
local struck = assets and assets:FindFirstChild("StruckVFX")
local ambient = assets and assets:FindFirstChild("TacoAmbient")
T.check(taco ~= nil and taco:IsA("MeshPart") and H.assetId(H.uri(taco, "MeshContent")) == 121725002379738,
	"Assets.VFX.TacoRain.Taco must be the event's taco mesh (121725002379738)")
local trail = taco and taco:FindFirstChildWhichIsA("Trail", true)
T.check(trail ~= nil and trail.Attachment0 ~= nil and trail.Attachment1 ~= nil, "the taco's trail must keep its attachments")
local function emitterStats(root)
	local n, enabled, untextured = 0, 0, 0
	for _, d in ipairs(root and root:GetDescendants() or {}) do
		if d:IsA("ParticleEmitter") then
			n += 1
			if d.Enabled then
				enabled += 1
			end
			if H.uri(d, "TextureContent") == nil then
				untextured += 1
			end
		end
	end
	return n, enabled, untextured
end
local sn, se, su = emitterStats(struck)
T.check(struck ~= nil and struck:IsA("BasePart") and sn >= 30 and se == 0 and su == 0,
	"StruckVFX (the taco explosion) must hold its disabled, textured emitters (%d, %d on, %d untextured)", sn, se, su)
local an, ae, au = emitterStats(ambient)
T.check(ambient ~= nil and ambient:IsA("BasePart") and ambient.Size.X > 200 and ambient.Size.Z > 300 and an == 12 and ae == 0 and au == 0,
	"TacoAmbient must be the full-size sky of 12 emitters, disabled in storage (%d, %d on)", an, ae)
local rated = 0
for _, d in ipairs(ambient and ambient:GetDescendants() or {}) do
	if d:IsA("ParticleEmitter") and type(d:GetAttribute("TacoRainRate")) == "number" and d:GetAttribute("TacoRainRate") > 0 then
		rated += 1
	end
end
T.check(rated == 12, "TacoAmbient's emitters must keep their authored rate (TacoRainRate) for the client (%d)", rated)
for _, root in ipairs({ taco, struck, ambient }) do
	T.check(root ~= nil and H.countClass(root, "Sound") == 0 and H.countClass(root, "LuaSourceContainer") == 0,
		"%s must carry no sound / script", root and root.Name or "?")
end

-- 3. the music ---------------------------------------------------------------------------------------------------
local music = H.path(place:GetService("SoundService"), "TacoRainMusic")
T.check(music ~= nil and music:IsA("Sound") and H.assetId(H.uri(music, "AudioContent")) == 142376088 and music.Looped and music.Volume == 0
	and music.SoundGroup ~= nil and music.SoundGroup.Name == "AdminAbuseMusic",
	"SoundService.TacoRainMusic must be the looped, silent taco song (142376088) in the Music group")
local copies = 0
for _, d in ipairs(place:GetDescendants()) do
	if d:IsA("Sound") and H.assetId(H.uri(d, "AudioContent")) == 142376088 then
		copies += 1
	end
end
T.check(copies == 1, "the taco song must be on exactly one Sound (found %d)", copies)
local audioStep = H.normalize(H.fs.readFile("scripts/steps/audio.luau"))
T.check(H.has(audioStep, "owner request 2026-09-27, Taco Rain music") and H.has(audioStep, "TACO_RAIN_MUSIC = { id = 142376088"),
	"scripts/steps/audio.luau must whitelist only the Taco Rain music id, with the owner's comment")

-- 4. wiring ------------------------------------------------------------------------------------------------------
local service = H.path(sss, "BranchServices/TacoRainService")
local serviceSrc = src(service)
T.check(compiles(service) and H.has(serviceSrc, 'REMOTE_NAME = "TacoRain: Event"') and H.has(serviceSrc, 'MUTATION = "Taco"')
	and H.has(serviceSrc, "AddRestingEggMutation") and H.has(serviceSrc, "BroadcastOwnerRecords") and H.has(serviceSrc, 'UNTIL_ATTRIBUTE = "TacoRainUntil"'),
	"BranchServices.TacoRainService must be injected, compile and drive the eggs / the remote")
local controllerModule = H.path(sps, "BranchControllers/TacoRainController")
local controllerSrc = src(controllerModule)
T.check(compiles(controllerModule) and H.has(controllerSrc, '"StruckVFX"') and H.has(controllerSrc, '"TacoAmbient"')
	and H.has(controllerSrc, '"TacoRainMusic"') and H.has(controllerSrc, "ApplyMutationParticles") and H.has(controllerSrc, 'HIT_LABEL = "x3 TACO!"')
	and H.has(controllerSrc, "LOW_POWER_RATE") and H.has(controllerSrc, "table.remove(s.pool)"),
	"BranchControllers.TacoRainController must draw the rain (sky, pooled tacos, StruckVFX, music, x3 label)")
local remote = H.path(rs, "Network/TacoRain: Event")
T.check(remote ~= nil and remote:IsA("RemoteEvent"), "Network['TacoRain: Event'] must be a RemoteEvent")
local areaSrc = src(H.path(sss, "Controllers/AreaEggService"))
T.check(H.has(areaSrc, "function AreaEggService.GetRestingEggs()") and H.has(areaSrc, "function AreaEggService.AddRestingEggMutation(uid, mutation)")
	and H.has(areaSrc, 'record.State ~= "Slot"'), "AreaEggService must expose its resting eggs and a nest-egg-only mutation hook")
local rendererSrc = src(H.path(rs, "Library/Client/Eggs/EggRenderer"))
T.check(H.has(rendererSrc, "function t1.ApplyMutationParticles(") and H.has(rendererSrc, "t1.ApplyMutationParticles(clone, p4.Record)"),
	"EggRenderer must put a taco'd egg's particles on every render")
local adminSrc = src(H.path(sss, "BranchServices/HeroAdminService"))
T.check(H.has(adminSrc, "COMMANDS.TacoRainStart = function") and H.has(adminSrc, "COMMANDS.TacoRainStop = function"),
	"HeroAdminService must start / stop the Taco Rain")
local world = H.path(place:GetService("ServerStorage"), "HeroAdminPanel/Window/Content/Pages/Page_World")
local buttons = {}
for _, d in ipairs(world and world:GetChildren() or {}) do
	local command = d:GetAttribute("Command")
	if command == "TacoRainStart" or command == "TacoRainStop" then
		table.insert(buttons, d.Name)
	end
end
T.check(#buttons == 3 and world:FindFirstChild("TacoStatus") ~= nil, "the World tab must offer START 60 S / 90 S, STOP and the status line")

-- 5. behaviour ---------------------------------------------------------------------------------------------------
local function inst(props)
	props.__instance = true
	props.IsA = props.IsA or function(self, class)
		return self.ClassName == class or (class == "BasePart" and self.ClassName == "Part")
	end
	props.FindFirstChild = props.FindFirstChild or function(self, name)
		return self.children and self.children[name] or nil
	end
	return props
end
local fired, sets, broadcasts, stageMutations = {}, {}, 0, {}
local attributes = {}
local playersService = inst({ ClassName = "Players" })
local player = inst({ ClassName = "Player", Name = "Owner", UserId = 42, Parent = playersService })
playersService.GetPlayers = function()
	return { player }
end
local profile = { EggInventory = {
	EggA = { AssetCategory = "Goku", Placement = { LocalCFrame = { 1, 0, 2, 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, Mutations = {} },
	EggB = { AssetCategory = "Goku", Placement = { LocalCFrame = { 3, 0, 4, 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, Mutations = { "Taco" } },
	EggC = { AssetCategory = "Goku" }, -- not placed: never a target
} }
local modulesMap = {}
local function moduleInst(name, value)
	local m = inst({ ClassName = "ModuleScript", Name = name })
	modulesMap[m] = value
	return m
end
local database = { Get = function()
	return profile
end, IsPlayerLoaded = function()
	return true
end, Set = function(_, changes)
	table.insert(sets, changes)
end }
local resting = { { Uid = "Stage1", AreaId = "Forest", AssetCategory = "Goku", Position = roblox.Vector3.new(100, 2, 0), Mutations = {} } }
local area = {
	GetRestingEggs = function()
		return resting
	end,
	AddRestingEggMutation = function(uid, mutation)
		table.insert(stageMutations, uid .. ":" .. mutation)
		return true
	end,
}
local controllers = inst({ ClassName = "Folder", children = {
	PlotService = moduleInst("PlotService", { GetPlotId = function()
		return 1
	end }),
	EggService = moduleInst("EggService", { BroadcastOwnerRecords = function()
		broadcasts += 1
	end }),
	AreaEggService = moduleInst("AreaEggService", area),
} })
local library = inst({ ClassName = "Folder", children = { Database = moduleInst("Database", database) } })
local remoteFake = inst({ ClassName = "RemoteEvent", OnServerEvent = H.mockSignal(), FireAllClients = function(_, payload)
	table.insert(fired, payload)
end })
local network = inst({ ClassName = "Folder", children = { ["TacoRain: Event"] = remoteFake } })
local directory = inst({ ClassName = "Folder", children = { Assets = moduleInst("Assets", { Directory = { Goku = { DisplayName = "Goku" } } }) } })
local center = inst({ ClassName = "Part", CFrame = roblox.CFrame.new(0, 2, 0) })
local plots = inst({ ClassName = "Folder", children = { ["1"] = inst({ ClassName = "Model", children = { CenterPoint = center } }) } })
local workspace = inst({ ClassName = "Workspace", children = { Plots = plots },
	GetServerTimeNow = function()
		return 1000
	end,
	SetAttribute = function(_, k, v)
		attributes[k] = v
	end,
	GetAttribute = function(_, k)
		return attributes[k]
	end,
})
local services = {
	Players = playersService,
	ReplicatedStorage = inst({ ClassName = "ReplicatedStorage", children = { Network = network, Directory = directory } }),
	ServerScriptService = inst({ ClassName = "ServerScriptService", children = { Controllers = controllers, Library = library } }),
	Workspace = workspace,
}
local chunk, err = H.sandbox(serviceSrc, {
	game = { GetService = function(_, name)
		return services[name]
	end },
	Color3 = roblox.Color3, CFrame = roblox.CFrame, Vector3 = roblox.Vector3,
	typeof = function(v)
		if type(v) == "table" and v.__instance then
			return "Instance"
		end
		return typeof(v)
	end,
	require = function(m)
		local value = modulesMap[m]
		if value == nil then
			error("unexpected require")
		end
		return value
	end,
	task = { delay = function(_, fn, ...)
		fn(...)
	end, spawn = function() end, wait = function() end },
	print = function() end, warn = function() end,
}, "TacoRainService")
local ok, mod = false, err
if chunk then
	ok, mod = pcall(chunk)
end
if T.check(ok and type(mod) == "table" and type(mod.DropOnEgg) == "function", "TacoRainService did not load in the sandbox: %s", tostring(mod)) then
	pcall(mod.Init, mod)
	local lowFirst = { NextNumber = function()
		return 0.1 -- < 0.5: the plot pool
	end, NextInteger = function(_, a)
		return a
	end }
	local target = mod.PickTarget(lowFirst)
	T.check(target ~= nil and target.Kind == "Plot" and target.Uid == "EggA", "the plot pool must offer the placed egg without the mutation (got %s)",
		tostring(target and target.Uid))
	T.check(mod.DropOnEgg(target) == true, "DropOnEgg must accept a target")
	local drop, hit = fired[1], fired[2]
	T.check(drop and drop.Action == "Drop" and drop.Kind == "Plot" and drop.OwnerUserId == 42 and typeof(drop.Position) == "Vector3"
		and math.abs(drop.Position.X - 1) < 1e-4 and drop.FallTime == mod.FALL_TIME, "a Drop must be broadcast at the egg's world position")
	T.check(hit and hit.Action == "Hit" and hit.Label == "x3 TACO!" and table.find(profile.EggInventory.EggA.Mutations, "Taco") ~= nil
		and #sets == 1 and sets[1].EggInventory == profile.EggInventory and broadcasts == 1,
		"the landing must give the placed egg the Taco mutation, save it, re-broadcast the owner's eggs and send a Hit")
	local again = mod.PickTarget(lowFirst)
	T.check(again == nil or again.Uid ~= "EggA", "an egg must never be aimed at twice")
	T.check(again ~= nil and again.Kind == "Stage" and again.Uid == "Stage1", "with the placed eggs done the stage egg must be offered (got %s)",
		tostring(again and again.Uid))
	mod.DropOnEgg(again)
	T.check(stageMutations[1] == "Stage1:Taco" and fired[4] and fired[4].Action == "Hit" and fired[4].Kind == "Stage",
		"a stage egg must get the mutation through AreaEggService.AddRestingEggMutation")
	T.check(mod.PickTarget(lowFirst) == nil, "no egg left: EggB already has the mutation, EggC is not placed")
	-- an egg that vanished before the taco landed (hatched / claimed): Miss, nothing saved
	profile.EggInventory.EggD = { AssetCategory = "Goku", Placement = { LocalCFrame = { 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 } }, Mutations = {} }
	local gone = mod.PickTarget(lowFirst)
	profile.EggInventory.EggD = nil
	local before = #sets
	mod.DropOnEgg(gone)
	T.check(fired[#fired].Action == "Miss" and #sets == before, "a taco landing on an egg that is gone must be a Miss")
end
