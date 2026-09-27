-- scripts/steps/post_areas_retire.luau
-- Visual pass D5 (owner INDEX): formally retire the 3 legacy zones from the directories.
-- Build hook: scripts/build_stealahero.luau step 12b runs every scripts/steps/post_*.luau in name order after the hero
-- builder and the stages step, before controller/manifest injection: Apply(place, spPlace, ctx).
--
-- Before this pass the retired zones (Abyss Ocean, Prehistoric, Cosmic) were only emptied (STAGES_PLAN A1: their
-- GuardAreas models / floors are destroyed by scripts/steps/stages.luau, their Areas configs got DropTable = {} from the
-- hero builder). This step removes the per-zone modules themselves:
--   ReplicatedStorage.Directory.Areas._Index.<zone>   (area config; `require`s Guards.Directory.<zone>)
--   ReplicatedStorage.Directory.Guards._Index.<zone>  (guard config, only indexed by the area config above and by the
--                                                      client guard runtime for zones that still exist in Workspace)
-- ONLY after verifying that nothing needs them by name:
--   1. no Workspace.__OBJECTS.Areas.GuardAreas.<zone> model is left (the client guard runtime asserts a Guards config
--      for every zone model, AreaNotificationTracker indexes Areas.Directory[zone]);
--   2. no script can index them by name: every LuaSourceContainer in the place (the retired modules themselves
--      excluded) AND every src/**/*.luau file (build step 13 / 13b inject those AFTER this step) is scanned for
--      name-based lookups - `Directory.<zone>`, `Directory["<zone>"]`, `_Index.<zone>`, `_Index["<zone>"]`,
--      `FindFirstChild("<zone>")`, `WaitForChild("<zone>")`, `...NameExists("<zone>")` (comments stripped; a line that
--      is about the Cosmic *rarity* - it mentions "Rarit" - is not a zone lookup). Harmless mentions (skip sets such as
--      `["Abyss Ocean"] = true`, per-zone number tables, the "<zone> Bat" gear ids) do not block.
-- A zone with any hit is kept and reported. Both directories iterate their _Index generically (ModuleLoader), so a
-- removed module simply disappears from Areas.Directory / Guards.Directory.
--
-- It also verifies (and repairs if a stale config slipped through) that the 6 kept zones' area configs carry the stage
-- names and numbers the players see (docs/STAGES_PLAN.md §1, Directory.StageArt).
--
-- NOT removed (reported): the retired zones' area-bat gear ("Abyss Ocean Bat", "Prehistoric Bat", "Cosmic Bat" in
-- Directory.Gears / ReplicatedStorage.GearTools) - gear ids live in player saves (GearInventory) and GearService's
-- melee table, owned by the gear/cleanup pass.

local fs = require("@lune/fs")

local Step = {}

local RETIRED = { "Abyss Ocean", "Prehistoric", "Cosmic" }
local ZONE_DIRECTORIES = { "Areas", "Guards" }

local STAGES = {
	{ key = "Forest", number = 1, name = "The Avengers" },
	{ key = "Lake", number = 2, name = "Justice League" },
	{ key = "Desert", number = 3, name = "Spider-Verse" },
	{ key = "Jungle", number = 4, name = "My Hero Academia" },
	{ key = "Snow", number = 5, name = "Dragon Ball" },
	{ key = "Volcano", number = 6, name = "One Piece" },
}

local function log(fmt, ...)
	print(string.format("[post_areas_retire] " .. fmt, ...))
end

local function child(parent, name)
	if parent == nil then
		return nil
	end
	for _, c in ipairs(parent:GetChildren()) do
		if c.Name == name then
			return c
		end
	end
	return nil
end

local function escapePattern(s)
	return (string.gsub(s, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- Name-based lookup patterns for one zone key: `generic` apply to every script, `index` (`_Index.<zone>`,
-- `_Index["<zone>"]`) only to scripts outside other directories - inside e.g. Directory.Rarity, `_Index.Cosmic` is
-- that directory's own Cosmic *rarity* module, not the zone.
local function hazardPatterns(key)
	local k = escapePattern(key)
	local q = "[\"']" .. k .. "[\"']"
	local generic = {
		"Directory%s*%[%s*" .. q .. "%s*%]",
		"FindFirstChild%s*%(%s*" .. q,
		"WaitForChild%s*%(%s*" .. q,
		"FindFirstChildWhichIsA%s*%(%s*" .. q,
		"NameExists%s*%(%s*" .. q,
	}
	local index = { "_Index%s*%[%s*" .. q .. "%s*%]" }
	if string.match(key, "^[%a_][%w_]*$") then
		table.insert(generic, "Directory%." .. k .. "%f[^%w_]")
		table.insert(index, "_Index%." .. k .. "%f[^%w_]")
	end
	return { generic = generic, index = index }
end

-- The directory a script belongs to when it lives inside ReplicatedStorage.Directory.<Name> other than the zone
-- directories (its `_Index.<x>` lookups then address its own _Index), else nil.
local function foreignDirectoryOf(label)
	local name = string.match(label, "^ReplicatedStorage%.Directory%.([^%.]+)")
		or string.match(label, "^src/ReplicatedStorage/Directory/([^/]+)/")
	if name == nil then
		return nil
	end
	name = string.gsub(name, "%.luau?$", "")
	for _, dirName in ipairs(ZONE_DIRECTORIES) do
		if name == dirName then
			return nil
		end
	end
	return name
end

-- Code of one line without its `--` comment (naive: good enough for these lookups).
local function codeOf(line)
	local cut = string.find(line, "--", 1, true)
	if cut then
		return string.sub(line, 1, cut - 1)
	end
	return line
end

-- Every hazard hit in `source` -> list of "line N: text". `patternLists` = arrays of patterns to try.
local function scanSource(source, patternLists)
	local hits = {}
	local lineNo = 0
	for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
		lineNo += 1
		local code = codeOf(line)
		if code ~= "" and not string.find(code, "Rarit", 1, true) then
			local found = false
			for _, patterns in ipairs(patternLists) do
				for _, pattern in ipairs(patterns) do
					if string.find(code, pattern) then
						found = true
						break
					end
				end
				if found then
					break
				end
			end
			if found then
				table.insert(hits, string.format("line %d: %s", lineNo, (string.gsub(code, "^%s+", ""))))
			end
		end
	end
	return hits
end

local function listLuauFiles(dir, out)
	for _, name in ipairs(fs.readDir(dir)) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			listLuauFiles(path, out)
		elseif string.sub(name, -5) == ".luau" or string.sub(name, -4) == ".lua" then
			table.insert(out, path)
		end
	end
	return out
end

-- The src mirrors of the modules being retired (never injected; they only mention themselves).
local function isRetiredMirror(path, key)
	for _, dirName in ipairs(ZONE_DIRECTORIES) do
		local base = "src/ReplicatedStorage/Directory/" .. dirName .. "/_Index/" .. key
		if path == base .. ".luau" or path == base .. ".lua" then
			return true
		end
	end
	return false
end

local function readSource(inst)
	local ok, source = pcall(function()
		return inst.Source
	end)
	return if ok and type(source) == "string" then source else ""
end

-- All reasons that block retiring `key` (empty = safe). `sources` = { { label, text, path? } } collected once.
local function findBlockers(place, key, sources)
	local blockers = {}
	local guardAreas = child(child(child(place:GetService("Workspace"), "__OBJECTS"), "Areas"), "GuardAreas")
	if child(guardAreas, key) ~= nil then
		table.insert(blockers, "Workspace.__OBJECTS.Areas.GuardAreas." .. key .. " still exists")
	end
	local patterns = hazardPatterns(key)
	local everywhere = { patterns.generic, patterns.index }
	local foreign = { patterns.generic }
	for _, entry in ipairs(sources) do
		if not (entry.path and isRetiredMirror(entry.path, key)) then
			local lists = if foreignDirectoryOf(entry.label) then foreign else everywhere
			for _, hit in ipairs(scanSource(entry.text, lists)) do
				table.insert(blockers, entry.label .. " " .. hit)
			end
		end
	end
	return blockers
end

local function quoteForSource(s)
	return string.format("%q", s)
end

-- Checks (and repairs a stale) DisplayName / StageNumber of the 6 kept area configs.
local function verifyStageNames(areasIndex)
	local ok, fixed, problems = 0, 0, {}
	for _, stage in ipairs(STAGES) do
		local module = child(areasIndex, stage.key)
		if module == nil or not module:IsA("ModuleScript") then
			table.insert(problems, stage.key .. ": area config missing")
			continue
		end
		local source = readSource(module)
		local expectedName = "DisplayName = " .. quoteForSource(stage.name) .. ","
		local nameOk = string.find(source, expectedName, 1, true) ~= nil
		local numberOk = string.find(source, "StageNumber%s*=%s*" .. stage.number .. "%s*,") ~= nil
		if nameOk and numberOk then
			ok += 1
			continue
		end
		local patched = source
		if not nameOk then
			local n
			patched, n = string.gsub(patched, "DisplayName%s*=%s*[^\n]-,", expectedName, 1)
			if n == 0 then
				table.insert(problems, stage.key .. ": no DisplayName field to repair")
			end
		end
		if not numberOk then
			local n
			patched, n = string.gsub(patched, "StageNumber%s*=%s*[^\n]-,", "StageNumber = " .. stage.number .. ",", 1)
			if n == 0 then
				patched, n = string.gsub(patched, "(DisplayName%s*=%s*[^\n]-,)", "%1\n\tStageNumber = " .. stage.number .. ",", 1)
			end
			if n == 0 then
				table.insert(problems, stage.key .. ": no StageNumber field to repair")
			end
		end
		if patched ~= source then
			module.Source = patched
			fixed += 1
			log("repaired %s area config -> DisplayName %q, StageNumber %d", stage.key, stage.name, stage.number)
		end
	end
	return ok, fixed, problems
end

function Step.Apply(place, _spPlace, _ctx)
	local rs = place:GetService("ReplicatedStorage")
	local directory = child(rs, "Directory")
	assert(directory ~= nil, "ReplicatedStorage.Directory missing")

	local indexes = {}
	for _, dirName in ipairs(ZONE_DIRECTORIES) do
		local index = child(child(directory, dirName), "_Index")
		assert(index ~= nil, "ReplicatedStorage.Directory." .. dirName .. "._Index missing")
		indexes[dirName] = index
	end

	-- the modules this step may remove (excluded from the scan: they only reference each other)
	local retiredModules = {}
	for _, key in ipairs(RETIRED) do
		for _, dirName in ipairs(ZONE_DIRECTORIES) do
			local module = child(indexes[dirName], key)
			if module ~= nil then
				retiredModules[module] = true
			end
		end
	end

	-- every script source that could index a retired module by name: the place's scripts (the candidates excluded)
	-- plus every src file (build step 13 / 13b inject src files after this step)
	local sources = {}
	local scriptCount = 0
	for _, inst in ipairs(place:GetDescendants()) do
		if inst:IsA("LuaSourceContainer") and not retiredModules[inst] then
			scriptCount += 1
			table.insert(sources, { label = inst:GetFullName(), text = readSource(inst) })
		end
	end
	local srcFiles = if fs.isDir("src") then listLuauFiles("src", {}) else {}
	for _, path in ipairs(srcFiles) do
		table.insert(sources, { label = path, text = fs.readFile(path), path = path })
	end
	local removed, kept, absent = {}, {}, {}
	for _, key in ipairs(RETIRED) do
		local modules = {}
		for _, dirName in ipairs(ZONE_DIRECTORIES) do
			local module = child(indexes[dirName], key)
			if module ~= nil then
				table.insert(modules, { dir = dirName, inst = module })
			end
		end
		if #modules == 0 then
			table.insert(absent, key)
			continue
		end
		local blockers = findBlockers(place, key, sources)
		if #blockers > 0 then
			table.insert(kept, key)
			log("KEEPING %s: %d name-based reference(s) still need it:", key, #blockers)
			for i, blocker in ipairs(blockers) do
				if i > 12 then
					log("   ... %d more", #blockers - 12)
					break
				end
				log("   %s", blocker)
			end
		else
			local names = {}
			for _, entry in ipairs(modules) do
				entry.inst:Destroy()
				table.insert(names, "Directory." .. entry.dir .. "._Index." .. key)
			end
			table.insert(removed, key)
			log("removed %s (0 name-based references in %d place scripts + %d src files)", table.concat(names, ", "),
				scriptCount, #srcFiles)
		end
	end

	-- nothing retired may be left behind as a kept zone's dependency either
	for _, key in ipairs(removed) do
		for _, dirName in ipairs(ZONE_DIRECTORIES) do
			assert(child(indexes[dirName], key) == nil, "Directory." .. dirName .. "._Index." .. key .. " survived its removal")
		end
	end

	local okCount, fixedCount, problems = verifyStageNames(indexes.Areas)
	for _, problem in ipairs(problems) do
		log("WARNING stage config: %s", problem)
	end
	local remaining = {}
	for _, module in ipairs(indexes.Areas:GetChildren()) do
		table.insert(remaining, module.Name)
	end
	table.sort(remaining)
	log("retired zones removed: %s | kept (referenced): %s | already absent: %s", #removed > 0 and table.concat(removed, ", ") or "-",
		#kept > 0 and table.concat(kept, ", ") or "-", #absent > 0 and table.concat(absent, ", ") or "-")
	log("Areas._Index now: %s | stage names: %d ok, %d repaired, %d problems", table.concat(remaining, ", "), okCount, fixedCount, #problems)
	log("kept on purpose: the retired zones' area-bat gear (Abyss Ocean Bat / Prehistoric Bat / Cosmic Bat) - save-data ids")
end

return Step
