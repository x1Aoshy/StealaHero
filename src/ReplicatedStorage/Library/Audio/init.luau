-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw
-- Decompiled Library.Audio from the base place (the stale bytecode comment was dropped when it was patched).
--
-- Speedsters audio patch:
--   * Only the whitelisted Speedsters asset ids are ever loaded. Legacy ids with a Speedsters equivalent are
--     remapped (SOUND_REMAP); every other id is silenced. See Audio.ResolveSoundId / Audio.ResolveSoundUri.
--   * A rejected or failed sound never errors: callers get an unparented, silent Sound.
--   * Loads are bounded (LOAD_TIMEOUT) instead of an unbounded Loaded:Wait(), so a 403 cannot leak threads.
--   * The server path fires ReplicatedStorage.Network.PlaySound (ServerScriptService.Library.Network does not exist).

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Library = ReplicatedStorage:WaitForChild("Library")
local AddDebris = require(Library.Functions.AddDebris)
local ParseAssetId = require(Library.Functions.ParseAssetId)
local Tween = require(Library.Functions.Tween)
local __DEBRIS = workspace:WaitForChild("__DEBRIS")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local InstanceCheck = require(ReplicatedStorage.Library.Functions.InstanceCheck)
local Interface = require(script.Types.Interface)
local FFlags = nil
local SettingsCmds = nil

if RunService:IsClient() then
	local Client = Library:WaitForChild("Client")

	FFlags = require(Client.FFlags)
	SettingsCmds = require(Client.SettingsCmds)
end

local Music = script:WaitForChild("Music")
local v16 = RunService:IsClient()
local random = Random.new()
local t1 = {}

-- Speedsters sound whitelist (the only asset ids this game may load).
local SPEEDSTERS_AUDIO = {
	UI_CLICK = 77120543307812, -- Speedsters Workspace.ui-bubble-click
	UI_POP = 72264591133889, -- Speedsters Workspace.ui-pop-sound-316482
	WINNER = 127039883737564, -- Speedsters Workspace.winner!
	SUCCESS = 136993031050456, -- Speedsters Workspace.Decal.SuccessSfx
	UPGRADE = 80736831159506, -- Speedsters Workspace.winner!.UpgradeBought.mp3
}
local ALLOWED_SOUND_IDS = {}

for _, id in pairs(SPEEDSTERS_AUDIO) do
	ALLOWED_SOUND_IDS[id] = true
end

-- Legacy (unauthorized) ids that have a Speedsters equivalent. Anything not listed here or whitelisted is silent.
local SOUND_REMAP = {
	[100671636189844] = SPEEDSTERS_AUDIO.UI_CLICK, -- base BUTTON_FX mouse-down
	[115437212690964] = SPEEDSTERS_AUDIO.UI_CLICK, -- SoundService.Click
	[131342831254185] = SPEEDSTERS_AUDIO.UI_CLICK, -- PlayError / PlayStatement / PlayQuestion / PlayLocked / Huh
	[17208372272] = SPEEDSTERS_AUDIO.UI_CLICK, -- red notification (NotificationCmds.Message)
	[126006309206939] = SPEEDSTERS_AUDIO.UI_POP, -- SoundService.Hover
	[133581886462636] = SPEEDSTERS_AUDIO.UI_POP, -- CashCollect / Cash Register / AddCurrencyScreen spawn
	[96726510123679] = SPEEDSTERS_AUDIO.UI_POP, -- NotificationCmds.Progress
	[89944486811970] = SPEEDSTERS_AUDIO.UI_POP, -- InfoOverlay / ItemUI hover
	[73352992887992] = SPEEDSTERS_AUDIO.UI_POP, -- NotificationCmds.Item
	[74146265484496] = SPEEDSTERS_AUDIO.UI_POP, -- egg placed on a plot (Eggs.EggPlaceAnimation.PlaySfx)
	[102267539121951] = SPEEDSTERS_AUDIO.WINNER, -- egg hatch poof
	[112792997660073] = SPEEDSTERS_AUDIO.WINNER, -- reward screen transition
	[129627240635324] = SPEEDSTERS_AUDIO.SUCCESS, -- purchase success (PromptPurchase)
	[98002834893313] = SPEEDSTERS_AUDIO.SUCCESS, -- gamepass bought (PurchaseNotifications)
	[103957546380416] = SPEEDSTERS_AUDIO.SUCCESS, -- new item notification (NotificationCmds.Item)
	[119855061490364] = SPEEDSTERS_AUDIO.UPGRADE, -- base upgrade transition
	[91650233387983] = SPEEDSTERS_AUDIO.UPGRADE, -- speed purchase (RewardScreenTransition, DoubleYourSpeed)
	[130233661094961] = SPEEDSTERS_AUDIO.UPGRADE, -- treadmill upgrade (TreadmillStaticController)
}

-- Volume multiplier keyed by the id the caller asked for: ButtonFX/InteractSound play the click at 3.6.
local VOLUME_SCALE = {
	[SPEEDSTERS_AUDIO.UI_CLICK] = 0.15,
	[100671636189844] = 0.15,
}

-- Volume ceiling keyed by the resolved id: legacy call sites were tuned for other (often quieter) assets.
local VOLUME_MAX = {
	[SPEEDSTERS_AUDIO.UI_CLICK] = 0.6,
	[SPEEDSTERS_AUDIO.UI_POP] = 0.6,
	[SPEEDSTERS_AUDIO.WINNER] = 1.0,
	[SPEEDSTERS_AUDIO.SUCCESS] = 1.0,
	[SPEEDSTERS_AUDIO.UPGRADE] = 1.0,
}

local LOAD_TIMEOUT = 5.0
local SILENT_SOUND_LIFETIME = 3.0

-- number | "rbxassetid://123" | "http://www.roblox.com/asset/?id=123" -> whitelisted id or nil
local function resolveSoundId(soundId): number?
	local id = nil

	if type(soundId) == "number" then
		id = soundId
	elseif type(soundId) == "string" then
		id = tonumber(string.match(soundId, "%d+"))
	end

	if not id or id <= 0.0 then
		return nil
	end

	id = SOUND_REMAP[id] or id

	return if ALLOWED_SOUND_IDS[id] then id else nil
end

-- Returns the SoundId string to use, or nil when the sound must stay silent.
local function resolveSoundUri(soundId): string?
	if type(soundId) == "string" and string.find(soundId, "^rbxasset://") then
		return soundId -- engine-bundled content never needs asset permission
	end

	local id = resolveSoundId(soundId)

	return if id then ("rbxassetid://%d"):format(id) else nil
end

local function normalizeVolume(requestedId: number?, resolvedId: number?, volume: number): number
	if requestedId then
		volume *= VOLUME_SCALE[requestedId] or 1.0
	end

	if resolvedId then
		volume = math.min(volume, VOLUME_MAX[resolvedId] or 1.0)
	end

	return volume
end

-- A fresh unparented, silent Sound per rejected request, so callers that Destroy() or re-parent the
-- returned Sound never affect each other. One-shot requests are cleaned up like a sound that finished.
local function silentSound(keepAlive: boolean?)
	local sound = Instance.new("Sound")

	sound.Name = "SilentSound"

	if not keepAlive then
		task.delay(SILENT_SOUND_LIFETIME, function()
			sound:Destroy()
		end)
	end

	return sound
end

-- Waits for the sound to load, at most `timeout` seconds. A 403 / failed load never fires Loaded.
local function waitForLoad(sound, timeout: number): boolean
	if sound.IsLoaded then
		return true
	end

	if sound.SoundId == "" then
		return false
	end

	local thread = coroutine.running()
	local finished = false
	local connection = nil

	local function finish(loaded: boolean)
		if finished then
			return
		end

		finished = true

		if connection then
			connection:Disconnect()
		end

		task.spawn(thread, loaded)
	end

	connection = sound.Loaded:Connect(function()
		finish(true)
	end)

	if sound.IsLoaded then
		finished = true
		connection:Disconnect()

		return true
	end

	task.delay(timeout, function()
		finish(sound.IsLoaded)
	end)

	return coroutine.yield()
end

local function getPlaySoundRemote()
	local network = ReplicatedStorage:FindFirstChild("Network")
	local remote = network and network:FindFirstChild("PlaySound")

	return if remote and remote:IsA("RemoteEvent") then remote else nil
end

local function isInsideBox(vector3: Vector3, vector3_2: Vector3) -- line: 42
	return vector3.X >= -vector3_2.X and (vector3.X <= vector3_2.X and (vector3.Y >= -vector3_2.Y and (vector3.Y <= vector3_2.Y and (vector3.Z >= -vector3_2.Z and vector3.Z <= vector3_2.Z))))
end
local function addToGarbageCollection(p1, b1: boolean?) -- line: 51
	-- upvalues: t1 (copy)
	table.insert(t1, {
		p1,
		b1
	})
end
local function scanGarbageCollection() -- line: 58
	-- upvalues: t1 (copy), RunService (copy), AddDebris (copy)
	for i = #t1, 1.0, -1.0 do
		if i % 25.0 == 0.0 then
			RunService.Heartbeat:Wait()
		end

		local v35 = t1[i]
		local v36 = v35[1.0]
		local v37 = v35[2.0]

		if not v36 or not v36.Parent or not v36.Playing or v36.SoundId == "" then
			if v37 and v36 and v36.Parent then
				AddDebris(v36.Parent, 0.0)
			elseif v36 then
				AddDebris(v36, 0.0)
			end

			table.remove(t1, i)
		end
	end
end

local t2 = {
	__types = Interface,
	ScheduleAndPlay = function(p2, p3: ((...any) -> ...any), p4) -- line: 87
		-- upvalues: Asserts (copy)
		Asserts.Sound(p2)
		Asserts.optional.func(p3)
		Asserts.optional.Instance(p4)

		-- Caller-supplied Sounds (AnimatedText / TutorialMessageAnimator clones) are gated here, before
		-- parenting, so a non-whitelisted id is never requested; legacy ids with an equivalent are remapped.
		if p2.SoundId ~= "" then
			local soundUri = resolveSoundUri(p2.SoundId)

			if not soundUri then
				p2.SoundId = ""
			elseif soundUri ~= p2.SoundId then
				p2.SoundId = soundUri
			end
		end

		if p4 then
			p2.Parent = p4
		end

		task.spawn(function() -- line: 96
			-- upvalues: p2 (copy), p3 (copy)
			local function cleanup()
				if p3 then
					local ok, handled = pcall(p3, p2)

					if ok and handled then
						return
					end
				end

				p2:Destroy()
			end

			if not waitForLoad(p2, LOAD_TIMEOUT) then
				-- Silent, unauthorized or failed sound: clean up without playing.
				cleanup()

				return
			end

			local u119 = nil
			local u120 = nil

			local function stoppedOrEnded() -- line: 104
				-- upvalues: u119 (ref), u120 (ref), p3 (copy), p2 (copy)
				if u119 then
					u119:Disconnect()
					u119 = nil
				end

				if u120 then
					u120:Disconnect()
					u120 = nil
				end

				cleanup()
			end

			u119 = p2.Ended:Once(stoppedOrEnded)
			u120 = p2.Stopped:Once(stoppedOrEnded)
			pcall(function()
				p2:Play()
			end)
		end)

		return p2
	end
}

t2.SPEEDSTERS_AUDIO = SPEEDSTERS_AUDIO
t2.ResolveSoundId = resolveSoundId
t2.ResolveSoundUri = resolveSoundUri

function t2.PlayFromSoundFile(t3: {[any]: any}, p5, t4: {[any]: any}?) -- line: 128
	-- upvalues: t2 (copy)
	return t2.PlayFromFormattedParams(t3.SoundId, p5, t3.Data, t4)
end
function t2.PlayFromFormattedParams(p6, p7, p8, t5: {[any]: any}?) -- line: 132
	-- upvalues: Interface (copy), t2 (copy)
	assert(Interface.PlayFormattedParamsInterface(p8))

	return t2.Play(p6, p7, p8.Speed, p8.Volume, p8.MaxDistance, p8.SoundGroup, p8.Looped, p8.TimePos, p8.Player, p8.SkipPlay, t5)
end
function t2.PrepareSoundFromSoundFile(p9, t6: {[any]: any}) -- line: 155
	-- upvalues: Asserts (copy), Interface (copy), InstanceCheck (copy), ParseAssetId (copy), random (copy)
	Asserts.Sound(p9)
	assert(Interface.SoundFile(t6))

	local SoundId = t6.SoundId
	local Data = t6.Data
	local v52 = Data and Data.Speed
	local v53 = Data and Data.Volume
	local v54 = Data and Data.MaxDistance
	local v55 = Data and Data.SoundGroup
	local v56 = Data and Data.Looped
	local v57 = Data and Data.TimePos

	if InstanceCheck(SoundId, "Sound") then
		SoundId = SoundId.SoundId
	elseif type(SoundId) == "table" then
		SoundId = if #SoundId > 0 then SoundId[math.random(1.0, #SoundId)] else nil
	end

	local requestedId = if type(SoundId) == "number" then SoundId else nil
	local soundUri = resolveSoundUri(SoundId)

	if v52 == nil then
		v52 = 1.0
	end

	if type(v52) == "table" then
		v52 = random:NextNumber(unpack(v52))
	end

	assert(type(v52) == "number", "speed must be a number")

	if v53 == nil then
		v53 = 1.0
	end

	if type(v53) == "table" then
		v53 = random:NextNumber(unpack(v53))
	end

	assert(type(v53) == "number", "volume must be a number")

	if v54 == nil then
		v54 = 200.0
	end

	assert(type(v54) == "number", "maxDistance must be a number")

	if typeof(v55) == "Instance" then
		assert(v55:IsA("SoundGroup"), "soundGroup must be a SoundGroup instance")

		local _ = v55.Name
	end

	if v56 == nil then
		v56 = false
	end

	assert(type(v56) == "boolean", "looped must be a boolean")

	if v57 == nil then
		v57 = 0.0
	end

	assert(type(v57) == "number", "timePos must be a number")
	-- Rejected ids leave the caller's Sound silent (SoundId "") instead of asserting.
	p9.SoundId = soundUri or ""
	p9.PlaybackSpeed = v52
	p9.Volume = normalizeVolume(requestedId, resolveSoundId(SoundId), v53)
	p9.Looped = v56
	p9.TimePosition = v57
	p9.RollOffMode = Enum.RollOffMode.LinearSquare
	p9.RollOffMinDistance = 0.001
	p9.RollOffMaxDistance = v54

	return p9
end
function t2.Play(p10, p11, p12, p13, n1: number?, p14, b2: boolean?, n2: number?, p15, b3: boolean?, t7: {[any]: any}?) -- line: 224
	-- upvalues: InstanceCheck (copy), ParseAssetId (copy), random (copy), Asserts (copy), v16 (copy), FFlags (ref), SettingsCmds (ref), SoundService (copy), __DEBRIS (copy), t2 (copy)
	if not p10 or p10 == "" or p10 == 0 then
		return silentSound(b2 == true)
	end

	local v71 = InstanceCheck(p10, "Sound")
	local requestedId = nil
	local instanceSoundUri = nil

	if v71 then
		-- Sound instances are cloned below; gate them on their own SoundId.
		instanceSoundUri = resolveSoundUri(p10.SoundId)

		if not instanceSoundUri then
			return silentSound(b2 == true)
		end
	else
		if type(p10) == "table" then
			if #p10 == 0 then
				return silentSound(b2 == true)
			end

			p10 = p10[math.random(1.0, #p10)]
		end

		if type(p10) == "string" then
			local ok, parsed = pcall(ParseAssetId, p10)
			p10 = ok and parsed or nil
		end

		if type(p10) ~= "number" or p10 <= 0.0 then
			return silentSound(b2 == true)
		end

		if not resolveSoundId(p10) then
			return silentSound(b2 == true)
		end

		requestedId = p10
	end

	if typeof(p11) == "Vector3" then
		p11 = CFrame.new(p11)
	end

	assert(typeof(p11) == "CFrame" or typeof(p11) == "Instance", "target must be either a CFrame or an Instance")

	if p12 == nil then
		p12 = 1.0
	end

	if type(p12) == "table" then
		p12 = random:NextNumber(unpack(p12))
	end

	assert(type(p12) == "number", "speed must be a number")

	if p13 == nil then
		p13 = 1.0
	end

	if type(p13) == "table" then
		p13 = random:NextNumber(unpack(p13))
	end

	assert(type(p13) == "number", "volume must be a number")

	if n1 == nil then
		n1 = 200.0
	end

	assert(type(n1) == "number", "maxDistance must be a number")

	if typeof(p14) == "Instance" then
		assert(p14:IsA("SoundGroup"), "soundGroup must be a SoundGroup instance")
		p14 = p14.Name
	end

	assert(p14 == nil or type(p14) == "string", "soundGroup must be nil or a string when not an Instance")

	if b2 == nil then
		b2 = false
	end

	assert(type(b2) == "boolean", "looped must be a boolean")

	if n2 == nil then
		n2 = 0.0
	end

	assert(type(n2) == "number", "timePos must be a number")
	Asserts.optional.table(t7)

	if not v16 then
		-- Server: forward the caller's id and volume unchanged; every client resolves and scales it again.
		local remote = getPlaySoundRemote()

		if remote then
			pcall(function()
				if p15 then
					remote:FireClient(p15, p10, p11, p12, p13, n1, p14, b2, n2, nil, b3, t7)
				else
					remote:FireAllClients(p10, p11, p12, p13, n1, p14, b2, n2, nil, b3, t7)
				end
			end)
		end

		return nil
	end

	if not FFlags.Get(FFlags.Keys.SFX) then
		return silentSound(b2)
	end

	if SettingsCmds and not SettingsCmds.IsEnabled("SFX") then
		return silentSound(b2)
	end

	local resolvedId = if requestedId then resolveSoundId(requestedId) else nil

	if requestedId then
		p13 = normalizeVolume(requestedId, resolvedId, p13)
	end

	local v73 = nil
	local vector3 = Vector3.new(0.0, 0.0, 0.0)
	local v75 = true

	if typeof(p11) == "CFrame" then
		v73 = p11
	elseif typeof(p11) == "Instance" then
		if p11:IsA("Model") then
			local PrimaryPart = p11.PrimaryPart

			if not PrimaryPart then
				warn("Tried to play Audio on a Model with no PrimaryPart:", p11, p10, debug.traceback())

				return silentSound(b2)
			end

			v73 = PrimaryPart.CFrame
			vector3 = PrimaryPart.Size
		elseif p11:IsA("BasePart") then
			v73 = p11.CFrame
			vector3 = p11.Size
		elseif p11:IsA("PVInstance") then
			v73 = p11:GetPivot()
		elseif p11:IsA("Attachment") then
			v73 = p11.WorldCFrame
		end
	end

	local CurrentCameraCFrame = workspace.CurrentCamera.CFrame

	if not v73 then
		v73 = CurrentCameraCFrame
		v75 = false
	end

	if not b2 and v75 then
		local v78 = n1 * 2.0
		local v79 = vector3 * 0.5 + Vector3.new(v78, v78, v78)
		local v80 = v73:ToObjectSpace(CurrentCameraCFrame)

		if not (v80.X >= -v79.X) or (not (v80.X <= v79.X) or (not (v80.Y >= -v79.Y) or (not (v80.Y <= v79.Y) or (not (v80.Z >= -v79.Z) or not (v80.Z <= v79.Z))))) then
			return silentSound(b2)
		end
	end

	local v81 = SoundService:FindFirstChild(p14 or "Default")

	if v81 and v81.Name == "Music" and v81:FindFirstChild("GameMusic") then
		v81 = v81:FindFirstChild("GameMusic")
	end

	if not (v81 and v81:IsA("SoundGroup")) then
		v81 = SoundService:FindFirstChild("Default")

		if not (v81 and v81:IsA("SoundGroup")) then
			v81 = nil
		end
	end

	local u82 = false

	if typeof(p11) == "CFrame" then
		local Part = Instance.new("Part")

		Part.CFrame = p11
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.Size = Vector3.new(0.0, 0.0, 0.0)
		Part.Transparency = 1.0
		Part.Parent = __DEBRIS
		p11 = Part
		u82 = true
	elseif p11:IsA("Model") then
		local PrimaryPart = p11.PrimaryPart

		if not PrimaryPart then
			warn("Tried to play Audio on a Model with no PrimaryPart:", p11, p10, debug.traceback())

			return silentSound(b2)
		end

		p11 = PrimaryPart
	end

	assert(typeof(p11) == "Instance", "target must be an Instance")

	local v85 = v71 and p10:Clone() or Instance.new("Sound")

	if v71 then
		if v85.SoundId ~= instanceSoundUri then
			v85.SoundId = instanceSoundUri
		end
	else
		v85.SoundId = ("rbxassetid://%d"):format(resolvedId)
		v85.PlaybackSpeed = p12
		v85.Volume = p13
		v85.Looped = b2
		v85.TimePosition = n2
		v85.RollOffMode = Enum.RollOffMode.LinearSquare
		v85.RollOffMinDistance = 0.001
		v85.RollOffMaxDistance = n1
		v85.SoundGroup = v81

		if t7 then
			for _, v in ipairs(t7) do
				Asserts.Instance(v)
				v.Parent = v85
			end
		end
	end

	if p11:IsA("Model") then
		local PrimaryPart = p11.PrimaryPart

		if PrimaryPart then
			p11 = PrimaryPart
		end
	end

	v85.Parent = p11

	if not b3 then
		t2.ScheduleAndPlay(v85, function() -- line: 448
			-- upvalues: u82 (ref), p11 (ref)
			if not u82 then
				return
			end

			p11:Destroy()

			return true
		end)
	end

	return v85
end
function t2.PlayError(p16) -- line: 460
	-- upvalues: t2 (copy)
	t2.Play("rbxassetid://131342831254185", script, 1.0, 1.0 * (p16 or 1.0))
end
function t2.PlayStatement(p17) -- line: 464
	-- upvalues: t2 (copy)
	t2.Play("rbxassetid://131342831254185", script, 1.0, 0.5 * (p17 or 1.0))
end
function t2.PlayQuestion(p18) -- line: 468
	-- upvalues: t2 (copy)
	t2.Play("rbxassetid://131342831254185", script, 1.0, 0.8 * (p18 or 1.0))
end
function t2.PlayLocked(p19) -- line: 472
	-- upvalues: t2 (copy)
	t2.Play("rbxassetid://131342831254185", script, 1.0, 1.0 * (p19 or 1.0))
end
function t2.Huh(p20, p21) -- line: 476
	-- upvalues: t2 (copy)
	t2.Play("rbxassetid://131342831254185", script, 1.0, 1.0 * (p21 or 1.0), nil, nil, nil, nil, p20)
end
function t2.Fade(p22, n3: number, n4: number, p23, p24) -- line: 479
	-- upvalues: Interface (copy), Tween (copy)
	assert(Interface.FadeParams(p22, n3, n4, p23, p24))

	return Tween(p22, {
		Volume = n3
	}, {
		n4,
		p23,
		p24
	})
end
function t2.PlayMusic(p25, p26, p27, p28, p29, p30) -- line: 497
	-- upvalues: v16 (copy), SettingsCmds (ref), ParseAssetId (copy), random (copy), SoundService (copy), Music (copy), t2 (copy), t1 (copy)
	if v16 and (SettingsCmds and not SettingsCmds.IsEnabled("Music")) then
		return silentSound(true)
	end

	if type(p25) == "table" then
		p25 = if #p25 > 0 then p25[math.random(1.0, #p25)] else nil
	end

	if type(p25) == "string" then
		local ok, parsed = pcall(ParseAssetId, p25)
		p25 = ok and parsed or nil
	end

	-- Music ids go through the same whitelist; a rejected id returns a silent Sound instead of asserting.
	local resolvedId = if type(p25) == "number" then resolveSoundId(p25) else nil

	if not resolvedId then
		return silentSound(true)
	end

	if p26 == nil then
		p26 = 1.0
	end

	if type(p26) == "table" then
		p26 = random:NextNumber(unpack(p26))
	end

	assert(type(p26) == "number", "volume must be a number")

	if p27 == nil then
		p27 = 1.0
	end

	assert(type(p27) == "number", "fadeTime must be a number")

	if typeof(p28) == "Instance" then
		assert(p28:IsA("SoundGroup"), "group must be a SoundGroup instance")
		p28 = p28.Name
	end

	assert(p28 == nil or type(p28) == "string", "group must be nil or a string when not an Instance")

	if p29 == nil then
		p29 = true
	end

	assert(type(p29) == "boolean", "loop must be a boolean")

	if p30 == nil then
		p30 = 0.0
	end

	assert(type(p30) == "number", "timePos must be a number")

	local v106 = SoundService:FindFirstChild(p28 or "Music")

	if v106 and v106.Name == "Music" and v106:FindFirstChild("GameMusic") then
		v106 = v106:FindFirstChild("GameMusic")
	end

	if not (v106 and v106:IsA("SoundGroup")) then
		v106 = nil
	end

	local Sound2 = Instance.new("Sound")

	Sound2.SoundId = ("rbxassetid://%d"):format(resolvedId)
	Sound2.Volume = 0.0
	Sound2.Looped = p29
	Sound2.SoundGroup = v106
	Sound2.Parent = Music
	Sound2:Play()

	for _, child in ipairs(Music:GetChildren()) do
		if child:IsA("Sound") then
			t2.Fade(child, 0.0, p27)
		end
	end

	t2.Fade(Sound2, p26, p27)
	table.insert(t1, {
		Sound2,
		nil
	})

	return Sound2
end
function t2.StopMusic(p31) -- line: 567
	-- upvalues: Music (copy), t2 (copy)
	if p31 == nil then
		p31 = 1.0
	end

	assert(type(p31) == "number", "fadeTime must be a number")

	for _, child in ipairs(Music:GetChildren()) do
		if child:IsA("Sound") then
			t2.Fade(child, 0.0, p31)
		end
	end
end

if v16 then
	local DefaultReverb = SoundService:FindFirstChild("DefaultReverb")

	if DefaultReverb then
		local ReverbSoundEffect = DefaultReverb:FindFirstChild("ReverbSoundEffect")

		if ReverbSoundEffect then
			ReverbSoundEffect.DryLevel = -1.3389357926122634
			ReverbSoundEffect.WetLevel = -16.90196080028514
		end
	end

	local function computeVolume(p32) -- line: 592
		return (math.clamp(p32, 0.0, 1.0) * 2.0) ^ 2.0
	end

	local Client = Library:WaitForChild("Client")
	local Network = require(Client.Network)
	local Signal = require(Library.Signal)

	Network.Fired("PlaySound"):Connect(function(...) -- line: 601
		-- upvalues: t2 (copy)
		local ok, err = pcall(t2.Play, ...)

		if not ok then
			warn("[Audio] PlaySound relay failed:", err)
		end
	end)
	Signal.Fired("Setting Slider Update"):Connect(function(p33, p34) -- line: 605
		-- upvalues: SoundService (copy)
		if p33 == "Music" then
			SoundService:WaitForChild("Music").Volume = (math.clamp(p34, 0.0, 1.0) * 2.0) ^ 2.0

			return
		end

		if p33 == "SFX" then
			local Default = SoundService:WaitForChild("Default")
			local DefaultReverb2 = SoundService:WaitForChild("DefaultReverb")
			local v118 = (math.clamp(p34, 0.0, 1.0) * 2.0) ^ 2.0

			Default.Volume = v118
			DefaultReverb2.Volume = v118
		end
	end)
end

_G.Huh = t2.Huh
task.spawn(function() -- line: 662
	-- upvalues: v16 (copy), scanGarbageCollection (copy)
	if v16 then
		while true do
			task.wait(1.0)
			scanGarbageCollection()
		end
	end
end)

return t2
