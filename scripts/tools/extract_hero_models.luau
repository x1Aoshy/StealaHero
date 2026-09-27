-- scripts/tools/extract_hero_models.luau
-- Re-runnable extraction of the owner's hero / villain models (docs/HERO_MODELS_PLAN.md "Source of the models", H1).
--
--   lune run scripts/tools/extract_hero_models.luau            (from the project root)
--
-- Reads the read-only snapshot assets/user_models/StealaHero_user_models_0747.rbxl, resolves every row of MAPPING
-- below (the source of truth for "which model is which hero") and writes:
--   assets/hero_models/Heroes.rbxm       one Model per roster hero, named by hero id (38)
--   assets/hero_models/Villains.rbxm     one Model per stage villain, named by villain id (6)
--   assets/hero_models/Extras.rbxm       models kept for later (not in the roster this pass; Sonic family excluded)
--   assets/hero_models/R15Template.rbxm  "R15BlockTemplate": the default block R15 body (Rig Builder meshes) the most
--                                        of the owner's R15 rigs share; R6 heroes are converted onto it
-- The models are stored as authored (whole-subtree clones, world position kept) minus code, audio, animation data
-- and avatar-description objects; the build (scripts/hero_system_builder.luau + scripts/lib/rig_convert.luau)
-- converts / normalises them. Each stored model carries attributes SourcePath, SourceName, SourceRig, SourceFile.
-- The build never reads the generated StealaHero.rbxl (it is overwritten by every build).

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")
local RigConvert = require("../lib/rig_convert")

local SNAPSHOT = "assets/user_models/StealaHero_user_models_0747.rbxl"
local OUT_DIR = "assets/hero_models"

--------------------------------------------------------------------------------------------------
-- MAPPING (source of truth). Path = Workspace-relative names (exact, spaces matter: "Replacement  Guards" has TWO);
-- Rig = expected source rig; Near = position hint when a path matches several models; Evidence = check that the
-- resolved model really is that character (the "?" rows of the contract were decided with it); Note = report text.
--------------------------------------------------------------------------------------------------

local function hasDescendantNamed(name)
	return function(m)
		return m:FindFirstChild(name, true) ~= nil, "contains " .. name
	end
end
local function wearsShirt(id, what)
	return function(m)
		local s = m:FindFirstChildOfClass("Shirt")
		local ok = s ~= nil and string.find(tostring(s.ShirtTemplate), tostring(id), 1, true) ~= nil
		return ok, string.format("Shirt %d = %s", id, what)
	end
end
local function greenHead(m)
	local bc = m:FindFirstChildOfClass("BodyColors")
	local c = bc and bc.HeadColor3 or (m:FindFirstChild("Head") and m.Head.Color)
	local ok = c ~= nil and c.G > c.R * 1.5 and c.G > c.B * 1.5
	return ok, "green head (BodyColors.HeadColor3)"
end

local MAPPING = {
	Heroes = {
		-- STAGE 1 The Avengers (Forest)
		{ Id = "Hawkeye", Path = { "Model", "Model", "Hawkeye" }, Rig = "R6" },
		{ Id = "BlackWidow", Path = { "Jean Grey (X-Men)" }, Rig = "R6", Evidence = wearsShirt(7273688193, "\"X-Men Uniform (Film)\""),
			Note = "contract '?' row: the first choice \"StarterCharacter\" is the Iron Man armour (Iron Man Helmet, arc reactor), so the "
				.. "alt is used: black X-Men film uniform + PopularGirlGingerHair (red hair)" },
		{ Id = "CaptainAmerica", Path = { "Captain America", "" }, Rig = "R15" },
		{ Id = "Hulk", Path = { "Hulk" }, Rig = "R15" },
		{ Id = "Thor", Path = { "Thor" }, Rig = "R15" },
		{ Id = "IronMan", Path = { "StarterCharacter" }, Rig = "R15", Evidence = hasDescendantNamed("Iron Man Helmet"),
			Note = "contract '?' row: the unnamed R15 at ~(111,5,-21) wears \"Flash Season 5\" clothing (Shirt 2639063722), "
				.. "while \"StarterCharacter\" is a full Iron Man armour (76 MeshParts: Iron Man Helmet, arc reactor, titanium/gold plates)" },
		-- STAGE 2 Justice League (Lake)
		{ Id = "Aquaman", Path = { "Aquaman" }, Rig = "R6" },
		{ Id = "GreenLantern", Path = { "Green Lantern" }, Rig = "R15" },
		{ Id = "Flash", Path = { "Downloaded_Heroes_R15", "Flash" }, Rig = "R15" },
		{ Id = "WonderWoman", Path = { "Wonder Woman", " " }, Rig = "R15" },
		{ Id = "Batman", Path = { "Downloaded_Heroes_R15", "Batman" }, Rig = "R15" },
		{ Id = "Superman", Path = { "Downloaded_Heroes_R15", "Superman", "     " }, Rig = "R15" },
		-- STAGE 3 Spider-Verse (Desert)
		{ Id = "PeterParker", Path = { "Spiderman" }, Rig = "R6" },
		{ Id = "SpiderGwen", Path = { "Gwen" }, Rig = "R6" },
		{ Id = "MilesMorales", Path = { "MilesMoralesK" }, Rig = "R6" },
		{ Id = "SpiderMan2099", Path = { "Spiderman 2099" }, Rig = "R6" },
		{ Id = "AgentVenom", Path = { "Venom" }, Rig = "R6", Note = "owner: \"two venoms: agent venom and ultimate venom\"; "
			.. "CharacterMesh monster package (cannot carry over to R15)" },
		{ Id = "Venom", Path = { "Ultimate Venom" }, Rig = "R6" },
		-- STAGE 4 My Hero Academia (Jungle)
		{ Id = "Uraraka", Path = { "Uraraka" }, Rig = "R6" },
		{ Id = "Bakugo", Path = { "Bakugo" }, Rig = "R6" },
		{ Id = "Todoroki", Path = { "Shoto Todoroki" }, Rig = "R15" },
		{ Id = "Hawks", Path = { "Hawks" }, Rig = "R6" },
		{ Id = "Deku", Path = { "Deku" }, Rig = "R6" },
		{ Id = "AllMight", Path = { "All Might" }, Rig = "R6" },
		-- STAGE 5 Dragon Ball (Snow)
		{ Id = "Krillin", Path = { "Krillin" }, Rig = "R6" },
		{ Id = "Trunks", Path = { "Trunks" }, Rig = "R6" },
		{ Id = "Piccolo", Path = { "Model", "Model", "" }, Rig = "R6", Near = { 560, 4, -86 }, Evidence = greenHead },
		{ Id = "Gohan", Path = { "Gohan" }, Rig = "R6" },
		{ Id = "Vegeta", Path = { " " }, Rig = "R6", Near = { 594, 44, -85 },
			Evidence = wearsShirt(5584916611, "\"Prince Vegeta Saiyan Battle Armor (Top)\""),
			Note = "contract '?' row: the unnamed R6 at ~(594,44,-85) wears the Vegeta Saiyan armour; the unnamed R15 at "
				.. "~(526,8,-85) wears the Usopp outfit (Shirt 7437390598 \"Ussop Shirt\") and goes to Extras" },
		{ Id = "Goku", Path = { "Goku" }, Rig = "R6" },
		-- STAGE 6 One Piece (Volcano)
		{ Id = "Usopp", Path = { "Usopp" }, Rig = "R6" },
		{ Id = "Nami", Path = { "Nami Onigashima" }, Rig = "R6" },
		{ Id = "Brook", Path = { "Brook" }, Rig = "R6" },
		{ Id = "Sanji", Path = { "Sanji" }, Rig = "R6" },
		{ Id = "Zoro", Path = { "Zoro" }, Rig = "R6" },
		{ Id = "Shanks", Path = { "Shanks" }, Rig = "R15" },
		{ Id = "Luffy", Path = { "--" }, Rig = "R15", Evidence = hasDescendantNamed("Luffy Hair") },
		{ Id = "JoyBoy", Path = { "Luffy - Gear 5" }, Rig = "R15", Note = "owner: \"el luffy es gear5 el joyboy\"" },
	},
	Villains = {
		{ Id = "Thanos", Path = { "Replacement  Guards", "THANOS" }, Rig = "R6" },
		{ Id = "Darkseid", Path = { "Replacement  Guards", "Darkseid" }, Rig = "R15" },
		{ Id = "Carnage", Path = { "Replacement  Guards", "Venom", "Zombie" }, Rig = "R15" },
		{ Id = "Shigaraki", Path = { "Replacement  Guards", "Shoto" }, Rig = "R6", Evidence = hasDescendantNamed("Accessory (Shigaraki)") },
		{ Id = "Frieza", Path = { "Replacement  Guards", "Freeza" }, Rig = "R15" },
		{ Id = "Kaido", Path = { "Replacement  Guards", "Kaidos", "Kaido" }, Rig = "R15" },
	},
	-- not in the roster this pass (the owner will confirm category / rarity); the Sonic family is excluded entirely
	Extras = {
		{ Id = "NicoRobin", Path = { "Nico Robin" }, Rig = "R6" },
		{ Id = "Franky", Path = { "Franky" }, Rig = "R6" },
		{ Id = "Chopper", Path = { "Chopper" }, Rig = "R6" },
		{ Id = "LJTheSecond", Path = { "LJTheSecond" }, Rig = "R6" },
		{ Id = "FlashSeason5", Path = { "" }, Rig = "R15", Near = { 111, 5, -21 }, Evidence = wearsShirt(2639063722, "\"Flash Season 5\""),
			Note = "the unnamed R15 the contract proposed for Iron Man" },
		{ Id = "UnnamedUsoppR15", Path = { " " }, Rig = "R15", Near = { 526, 8, -85 }, Evidence = wearsShirt(7437390598, "\"Ussop Shirt\""),
			Note = "the unused unnamed rig (an R15 Usopp outfit)" },
		{ Id = "SilverSurfer", Path = { "Downloaded_Heroes_R15", "SilverSurfer" }, Rig = "R15" },
		{ Id = "ReverseFlash", Path = { "Downloaded_Heroes_R15", "ReverseFlash" }, Rig = "R15" },
		{ Id = "KidFlash", Path = { "Downloaded_Heroes_R15", "KidFlash" }, Rig = "R15" },
		{ Id = "BlackFlash", Path = { "Downloaded_Heroes_R15", "BlackFlash" }, Rig = "R15" },
		{ Id = "WallyWest", Path = { "Downloaded_Heroes_R15", "WallyWest" }, Rig = "R15" },
		{ Id = "MobiusWallyWest", Path = { "Downloaded_Heroes_R15", "MobiusWallyWest" }, Rig = "R15" },
		{ Id = "WhiteSpeedster", Path = { "Downloaded_Heroes_R15", "WhiteSpeedster" }, Rig = "R15" },
		{ Id = "Savitar", Path = { "Downloaded_Heroes_R15", "Savitar" }, Rig = "R15" },
		{ Id = "Zoom", Path = { "Downloaded_Heroes_R15", "Zoom" }, Rig = "R15" },
	},
	-- the block R15 template: the most common full default body among the owner's R15 rigs (checked below)
	Template = { Id = "R15BlockTemplate", Path = { "Shoto Todoroki" }, Rig = "R15" },
}

-- Removed at extraction: code (free models ship viruses, e.g. Hawkeye's "zacksisk" scripts), audio, animation data,
-- avatar-description objects, cameras and dialogs. Everything visual stays; the build strips the rest.
local EXTRACT_STRIP = {
	Script = true, LocalScript = true, ModuleScript = true, Sound = true, SoundGroup = true, Animation = true,
	KeyframeSequence = true, Keyframe = true, Pose = true, Camera = true, Dialog = true, DialogChoice = true,
	BindableEvent = true, BindableFunction = true, RemoteEvent = true, RemoteFunction = true, Backpack = true, Tool = true,
	HumanoidDescription = true, AccessoryDescription = true, BodyPartDescription = true,
}

--------------------------------------------------------------------------------------------------
-- resolution
--------------------------------------------------------------------------------------------------

local function referencePosition(m)
	local p = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso")
	return p and p.CFrame.Position
end

local function pathString(path)
	local parts = {}
	for _, n in ipairs(path) do
		table.insert(parts, string.format("%q", n))
	end
	return "Workspace/" .. table.concat(parts, "/")
end

local function resolve(ws, row)
	local found = {}
	local function walk(node, i)
		if i > #row.Path then
			table.insert(found, node)
			return
		end
		for _, c in ipairs(node:GetChildren()) do
			if c.Name == row.Path[i] then
				walk(c, i + 1)
			end
		end
	end
	walk(ws, 1)
	local candidates = {}
	for _, m in ipairs(found) do
		if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and RigConvert.RigType(m) == row.Rig then
			table.insert(candidates, m)
		end
	end
	if #candidates > 1 and row.Near then
		local near = roblox.Vector3.new(row.Near[1], row.Near[2], row.Near[3])
		table.sort(candidates, function(a, b)
			return (referencePosition(a) - near).Magnitude < (referencePosition(b) - near).Magnitude
		end)
		candidates = { candidates[1] }
	end
	assert(#candidates == 1, string.format("[extract] %s: %s (%s) matched %d models", row.Id, pathString(row.Path), row.Rig, #candidates))
	local model = candidates[1]
	local evidence = nil
	if row.Evidence then
		local ok, what = row.Evidence(model)
		assert(ok, string.format("[extract] %s: %s fails its evidence check (%s)", row.Id, pathString(row.Path), what))
		evidence = what
	end
	return model, evidence
end

local function extract(model, row, category)
	local copy = model:Clone()
	copy.Name = row.Id
	local removed = 0
	for _, d in ipairs(copy:GetDescendants()) do
		if d.Parent ~= nil and (EXTRACT_STRIP[d.ClassName] or d:IsA("LuaSourceContainer")) then
			d:Destroy()
			removed += 1
		end
	end
	copy:SetAttribute("SourcePath", pathString(row.Path))
	copy:SetAttribute("SourceName", model.Name)
	copy:SetAttribute("SourceRig", row.Rig)
	copy:SetAttribute("SourceFile", SNAPSHOT)
	copy:SetAttribute("Category", category)
	if row.Note then
		copy:SetAttribute("MappingNote", row.Note)
	end
	return copy, removed
end

-- per-part signature of an R15 body (mesh id, size, attachments) rounded to 2 decimals
local function r15Signature(m)
	local function r(x)
		if math.abs(x) < 0.005 then
			x = 0
		end
		return string.format("%.2f", x)
	end
	local function v(p)
		return r(p.X) .. "," .. r(p.Y) .. "," .. r(p.Z)
	end
	local parts = {}
	for _, n in ipairs({ "HumanoidRootPart", table.unpack(RigConvert.R15_PARTS) }) do
		local p = m:FindFirstChild(n)
		if not p then
			return nil
		end
		local mesh = "Part"
		if p:IsA("MeshPart") then
			mesh = string.match(p.MeshContent.Uri or "", "(%d+)$") or "?"
		end
		local atts = {}
		for _, a in ipairs(p:GetChildren()) do
			if a:IsA("Attachment") then
				table.insert(atts, a.Name .. "@" .. v(a.CFrame.Position))
			end
		end
		table.sort(atts)
		table.insert(parts, n .. ":" .. mesh .. ":" .. v(p.Size) .. ":" .. table.concat(atts, ";"))
	end
	return table.concat(parts, "|")
end

--------------------------------------------------------------------------------------------------
-- run
--------------------------------------------------------------------------------------------------

local function main()
	print("[extract] reading " .. SNAPSHOT)
	local place = roblox.deserializePlace(fs.readFile(SNAPSHOT))
	local ws = place.Workspace
	if not fs.isDir(OUT_DIR) then
		fs.writeDir(OUT_DIR)
	end

	local lines = {}
	local function out(s)
		print(s)
		table.insert(lines, s)
	end

	-- template: verify it carries the most common PLAIN default block body (classic Part head with its SpecialMesh;
	-- the Downloaded_Heroes_R15 speedsters share a textured dynamic-head body and are not "plain")
	local sigs, owners = {}, {}
	for _, m in ipairs(ws:GetDescendants()) do
		local head = m:IsA("Model") and m:FindFirstChild("Head")
		local plain = head and head.ClassName == "Part" and head:FindFirstChildOfClass("SpecialMesh") ~= nil
		if plain and m:FindFirstChildOfClass("Humanoid") and RigConvert.RigType(m) == "R15" and not m:FindFirstAncestor("__OBJECTS") then
			local sig = r15Signature(m)
			if sig then
				sigs[sig] = (sigs[sig] or 0) + 1
				owners[sig] = owners[sig] or {}
				table.insert(owners[sig], m:GetFullName())
			end
		end
	end
	local bestSig, bestN = nil, 0
	for sig, n in pairs(sigs) do
		if n > bestN then
			bestSig, bestN = sig, n
		end
	end
	local templateSrc = resolve(ws, MAPPING.Template)
	assert(r15Signature(templateSrc) == bestSig, "[extract] the template rig is not the most common default block R15 body")
	out(string.format("[extract] R15 template: %s (default block body shared by %d rigs: %s)", pathString(MAPPING.Template.Path), bestN,
		table.concat(owners[bestSig], ", ")))
	local template = templateSrc:Clone()
	template.Name = MAPPING.Template.Id
	local keep = { HumanoidRootPart = true }
	for _, n in ipairs(RigConvert.R15_PARTS) do
		keep[n] = true
	end
	for _, c in ipairs(template:GetChildren()) do
		if not (c:IsA("BasePart") and keep[c.Name]) then
			c:Destroy()
		end
	end
	for _, d in ipairs(template:GetDescendants()) do
		if d.Parent ~= nil and not (d:IsA("BasePart") or d:IsA("Attachment") or d:IsA("Motor6D") or d:IsA("SpecialMesh")) then
			d:Destroy()
		elseif d.Parent ~= nil and d:IsA("BasePart") and not (keep[d.Name] and d.Parent == template) then
			d:Destroy()
		end
	end
	for _, d in ipairs(template:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Color = roblox.Color3.fromRGB(163, 162, 165)
		end
	end
	template:SetAttribute("SourcePath", pathString(MAPPING.Template.Path))
	template:SetAttribute("SourceFile", SNAPSHOT)
	fs.writeFile(OUT_DIR .. "/R15Template.rbxm", roblox.serializeModel({ template }))

	local preparedTemplate = RigConvert.PrepareTemplate(template)

	for _, category in ipairs({ "Heroes", "Villains", "Extras" }) do
		local models = {}
		out(string.format("[extract] %s:", category))
		for _, row in ipairs(MAPPING[category]) do
			local model, evidence = resolve(ws, row)
			local copy, removed = extract(model, row, string.sub(category, 1, -2))
			table.insert(models, copy)
			local summary = ""
			if category ~= "Extras" then
				-- dry conversion: what the build will do with it
				local body, notes, info = RigConvert.ToR15(copy, preparedTemplate, {
					HipHeight = if category == "Villains" then 2 else nil,
					Label = row.Id,
				})
				summary = string.format(" -> R15 (%d accessories: %d at attachments, %d at authored offsets; %d extras welded; scale %.3f; hip %.2f)%s",
					info.Accessories, info.AttachmentPlaced, info.OffsetPlaced, info.Extras, info.Scale, info.HipHeight,
					if #info.Lost > 0 then " LOST: " .. table.concat(info.Lost, ", ") else "")
				for _, n in ipairs(notes) do
					if string.find(n, "missing", 1, true) or string.find(n, "no rig attachment", 1, true) then
						summary ..= " [" .. n .. "]"
					end
				end
				body:Destroy()
			end
			out(string.format("  %-16s <- %s (%s)%s%s%s", row.Id, pathString(row.Path), row.Rig,
				if evidence then " evidence: " .. evidence else "", summary, if removed > 0 then string.format(" [%d code/audio/anim objects stripped]", removed) else ""))
			if row.Note then
				out("                      note: " .. row.Note)
			end
		end
		fs.writeFile(OUT_DIR .. "/" .. category .. ".rbxm", roblox.serializeModel(models))
		out(string.format("[extract] wrote %s/%s.rbxm (%d models)", OUT_DIR, category, #models))
	end
	return lines
end

main()
process.exit(0)
