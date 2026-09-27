-- scripts/steps/audio.luau
-- Build step: Speedsters audio identity. Runs LAST (after the build's final Content.none sanitize pass).
--   1. SoundService slots that code plays directly get whitelisted Speedsters sounds (SOUNDSERVICE_MAP).
--   2. SoundService.SpeedstersSfx holds one Sound per whitelisted id, in the Default SoundGroup.
--   3. Enforcement: any other Sound in the place whose AudioContent is not engine-local or whitelisted is
--      reset to Content.none, so the place file never references a non-whitelisted (403) asset.
-- Lune: write AudioContent via Content.fromAssetId. The file stores AudioContent; legacy SoundId is not the
-- stored property, so reading it back on a loaded Sound fails — always read and write AudioContent here.

local AudioStep = {}

-- Must match Library.Audio (src/ReplicatedStorage/Library/Audio/init.luau) SPEEDSTERS_AUDIO.
AudioStep.SPEEDSTERS_AUDIO = {
	UI_CLICK = 77120543307812, -- Speedsters Workspace.ui-bubble-click
	UI_POP = 72264591133889, -- Speedsters Workspace.ui-pop-sound-316482
	WINNER = 127039883737564, -- Speedsters Workspace.winner!
	SUCCESS = 136993031050456, -- Speedsters Workspace.Decal.SuccessSfx
	UPGRADE = 80736831159506, -- Speedsters Workspace.winner!.UpgradeBought.mp3
}
AudioStep.SFX_ORDER = { "UI_CLICK", "UI_POP", "WINNER", "SUCCESS", "UPGRADE" }

-- SoundService children played directly by scripts (MoneyUpdate, PlayHoverSound, NPC Option_UI) or used as
-- clone sources. Everything else in SoundService stays silent.
-- `subgroup` routes a sound through a SoundGroup nested in Default (effective volume = Volume x subgroup x
-- Default, so the SFX setting still mutes it, like Music.GameMusic). Used where a script overwrites Volume.
AudioStep.SOUNDSERVICE_MAP = {
	{ name = "Click", key = "UI_CLICK", volume = 0.5 },
	-- Library.Functions.PlayHoverSound sets Hover.Volume = 1 on every play; the subgroup keeps it at 0.5.
	{ name = "Hover", key = "UI_POP", volume = 1.0, subgroup = { name = "UIHover", volume = 0.5 } },
	{ name = "CashCollect", key = "UI_POP", volume = 0.35 }, -- MoneyUpdate pitch-shifts it per gain
	{ name = "Cash Register", key = "SUCCESS", volume = 0.5 },
	{ name = "Collect", key = "SUCCESS", volume = 0.5 },
}

-- Where each id lives in the Speedsters place (World1Update3New.rbxl); used only to cross-check the ids.
local SPEEDSTERS_SOURCES = {
	UI_CLICK = { "Workspace", "ui-bubble-click" },
	UI_POP = { "Workspace", "ui-pop-sound-316482" },
	WINNER = { "Workspace", "winner!" },
	SUCCESS = { "Workspace", "Decal", "SuccessSfx" },
	UPGRADE = { "Workspace", "winner!", "UpgradeBought.mp3" },
}

local SFX_VOLUME = 0.5

local function audioUri(sound): string?
	local ok, content = pcall(function()
		return sound.AudioContent
	end)
	if ok and content then
		return content.Uri
	end
	return nil
end

local function assetIdOf(uri: string?): string?
	return uri and string.match(uri, "^rbxassetid://(%d+)$") or nil
end

-- Sound at an exact full path (Speedsters' Workspace has several children named "Decal").
local function findSoundByPath(root, path)
	local fullName = table.concat(path, ".")
	for _, inst in ipairs(root:GetService(path[1]):GetDescendants()) do
		if inst.Name == path[#path] and inst:IsA("Sound") and inst:GetFullName() == fullName then
			return inst
		end
	end
	return nil
end

function AudioStep.Apply(place, spPlace, ctx)
	local roblox = (ctx and ctx.roblox) or require("@lune/roblox")
	local Instance = roblox.Instance
	local Content = roblox.Content

	local ids = AudioStep.SPEEDSTERS_AUDIO
	local whitelist = {}
	for _, id in pairs(ids) do
		whitelist[tostring(id)] = true
	end

	-- Cross-check the ids against the Speedsters place when it is available.
	if spPlace then
		for _, key in ipairs(AudioStep.SFX_ORDER) do
			local source = findSoundByPath(spPlace, SPEEDSTERS_SOURCES[key])
			local sourceId = source and assetIdOf(audioUri(source))
			if sourceId ~= tostring(ids[key]) then
				print(string.format("[Audio] WARNING: Speedsters %s is %s in World1Update3New.rbxl, expected %d",
					table.concat(SPEEDSTERS_SOURCES[key], "."), tostring(sourceId), ids[key]))
			end
		end
	else
		print("[Audio] Speedsters place not loaded; using the built-in Speedsters audio ids without cross-check.")
	end

	local soundService = place:GetService("SoundService")
	local defaultGroup = soundService:FindFirstChild("Default")
	if defaultGroup and not defaultGroup:IsA("SoundGroup") then
		defaultGroup = nil
	end
	if not defaultGroup then
		print("[Audio] WARNING: SoundService.Default SoundGroup missing; Speedsters sounds get no SoundGroup.")
	end

	-- A SoundGroup nested in Default (or in SoundService when Default is missing), created once per name.
	local function ensureSubgroup(spec)
		local parent = defaultGroup or soundService
		local group = parent:FindFirstChild(spec.name)
		if group and not group:IsA("SoundGroup") then
			group:Destroy()
			group = nil
		end
		if not group then
			group = Instance.new("SoundGroup")
			group.Name = spec.name
			group.Parent = parent
		end
		group.Volume = spec.volume
		return group
	end

	-- 1. SoundService slots
	local mapped = 0
	for _, entry in ipairs(AudioStep.SOUNDSERVICE_MAP) do
		local sound = soundService:FindFirstChild(entry.name)
		if sound and sound:IsA("Sound") then
			sound.AudioContent = Content.fromAssetId(ids[entry.key])
			sound.Volume = entry.volume
			sound.PlaybackSpeed = 1
			sound.Looped = false
			local group = if entry.subgroup then ensureSubgroup(entry.subgroup) else defaultGroup
			if group then
				sound.SoundGroup = group
			end
			mapped += 1
		else
			print(string.format("[Audio] SoundService.%s not found; skipped.", entry.name))
		end
	end

	-- 2. SoundService.SpeedstersSfx
	local sfx = soundService:FindFirstChild("SpeedstersSfx")
	if sfx and not sfx:IsA("Folder") then
		sfx:Destroy()
		sfx = nil
	end
	if not sfx then
		sfx = Instance.new("Folder")
		sfx.Name = "SpeedstersSfx"
		sfx.Parent = soundService
	end
	for _, key in ipairs(AudioStep.SFX_ORDER) do
		local sound = sfx:FindFirstChild(key)
		if sound and not sound:IsA("Sound") then
			sound:Destroy()
			sound = nil
		end
		if not sound then
			sound = Instance.new("Sound")
			sound.Name = key
			sound.Parent = sfx
		end
		sound.AudioContent = Content.fromAssetId(ids[key])
		sound.Volume = SFX_VOLUME
		sound.PlaybackSpeed = 1
		sound.Looped = false
		if defaultGroup then
			sound.SoundGroup = defaultGroup
		end
	end

	-- 3. Enforce the whitelist across the whole place.
	local total, audible, silenced = 0, 0, 0
	local audibleIds = {}
	for _, inst in ipairs(place:GetDescendants()) do
		if inst:IsA("Sound") then
			total += 1
			local uri = audioUri(inst)
			if uri and uri ~= "" and not string.find(uri, "^rbxasset://") then
				local id = assetIdOf(uri)
				if id and whitelist[id] then
					audible += 1
					audibleIds[id] = (audibleIds[id] or 0) + 1
				else
					inst.AudioContent = Content.none
					silenced += 1
				end
			end
		end
	end

	local summary = {}
	for _, key in ipairs(AudioStep.SFX_ORDER) do
		local id = tostring(ids[key])
		table.insert(summary, string.format("%s=%s x%d", key, id, audibleIds[id] or 0))
	end
	print(string.format("[Audio] Speedsters audio applied: %d SoundService slots mapped, SpeedstersSfx has %d sounds.",
		mapped, #sfx:GetChildren()))
	print(string.format("[Audio] %d Sounds in place, %d audible (whitelisted), %d non-whitelisted reset to Content.none. %s",
		total, audible, silenced, table.concat(summary, ", ")))
end

return AudioStep
