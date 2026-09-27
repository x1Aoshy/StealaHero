-- scripts/steps/gear.luau
-- Build step: the gear data the runtime (src/ServerScriptService/GearService.server.luau, injected by
-- scripts/inject/gear.luau) and the base game's gear UI rely on. No gear lies in the world (D3,
-- docs/VISUAL_PASS_PLAN.md): every player spawns with the Bat and the Trap in the Backpack + StarterGear, handed
-- out by GearService.
--
-- What this step does
--   1. Removes every gear pickup from Workspace: the base place's four podium models (`GearGiver` Taser Gun,
--      `GearGiver_Slap`, `GearGiver_BeeLauncher`, `GearGiver_SentryTurret`) and any `Workspace.GearGivers` folder an
--      older build laid out in the hub. The build keeps the podiums in Workspace for this step (see
--      scripts/build_stealahero.luau), so they are always deleted here.
--   2. Prepares the starter gear templates in ReplicatedStorage.GearTools.ShopItems the way the base game's gear UI
--      expects them: attributes `GearName` + `ItemType = "Gear"` (BackpackController locks the Bat to hotbar slot 1
--      and the Trap to slot 2 by GearName; the Trap template ships without either), CanBeDropped = false (a dropped
--      tool would lie on the floor), no Sounds (audio whitelist). Scripts inside the tools are kept: the Bat's and
--      the Trap's client controllers are live LocalScripts (the server `Controller` Script is an inert ripper stub).
--   3. Sanitises the Trap/SubspaceMine templates GearService clones (Assets.ToolEffects.PlayerTrap/SubspaceTrap):
--      no ripper stub scripts, no sounds.
--   4. Creates the server -> client events ReplicatedStorage.Network["Gear: Ragdoll"] (D2 bat ragdoll),
--      ["Gear: BatFx"] (bat swing / hit feedback) and ["ReplicateEffects: ShakeOnce"] (the base game's camera shake,
--      which Game.CameraShake only binds when it exists at client start), so the clients' targets exist in the place
--      file (GearService also creates them at runtime if missing).
--
-- Idempotent.

local roblox = require("@lune/roblox")

local Instance = roblox.Instance

local Step = {}

Step.PODIUM_NAMES = { "GearGiver", "GearGiver_Slap", "GearGiver_BeeLauncher", "GearGiver_SentryTurret" }
Step.LEGACY_FOLDER = "GearGivers"
Step.STARTER_GEAR = { "Bat", "Trap" } -- keep in sync with GearService STARTER_GEAR
Step.RAGDOLL_REMOTE = "Gear: Ragdoll"
Step.BAT_FX_REMOTE = "Gear: BatFx" -- bat swing / hit broadcast (Gekko TO DO 2, Game.Tools.BatCombatFx)
-- NETWORK_MAP.ReplicatedEffects.SHAKE_ONCE: Game.CameraShake binds it only if it exists when the client starts, so it
-- must be in the place file (GearService shakes the attacker's and the victim's camera through it).
Step.SHAKE_REMOTE = "ReplicateEffects: ShakeOnce"
Step.REMOTE_EVENTS = { Step.RAGDOLL_REMOTE, Step.BAT_FX_REMOTE, Step.SHAKE_REMOTE }

function Step.Apply(place, _spPlace, _ctx)
	local ws = place.Workspace
	local rs = place:GetService("ReplicatedStorage")

	-- 1. no gear pickups in the world
	local removed = {}
	for _, name in ipairs(Step.PODIUM_NAMES) do
		local podium = ws:FindFirstChild(name)
		while podium do
			podium:Destroy()
			table.insert(removed, name)
			podium = ws:FindFirstChild(name)
		end
	end
	local legacyFolder = ws:FindFirstChild(Step.LEGACY_FOLDER)
	if legacyFolder then
		legacyFolder:Destroy()
		table.insert(removed, Step.LEGACY_FOLDER)
	end
	-- stray Tools parented straight to Workspace would be free pickups lying on the floor
	for _, child in ipairs(ws:GetChildren()) do
		if child:IsA("Tool") then
			table.insert(removed, "Tool " .. child.Name)
			child:Destroy()
		end
	end

	-- 2. starter gear templates
	local shopItems = rs:FindFirstChild("GearTools") and rs.GearTools:FindFirstChild("ShopItems")
	local prepared = {}
	if not shopItems then
		print("[gear] !! ReplicatedStorage.GearTools.ShopItems missing - GearService cannot hand out the starter gear.")
	else
		for _, gearName in ipairs(Step.STARTER_GEAR) do
			local tool = shopItems:FindFirstChild(gearName)
			if tool and tool:IsA("Tool") and tool:FindFirstChild("Handle") then
				tool:SetAttribute("GearName", gearName)
				tool:SetAttribute("ItemType", "Gear")
				tool.CanBeDropped = false
				for _, d in ipairs(tool:GetDescendants()) do
					if d:IsA("Sound") then
						d:Destroy()
					end
				end
				table.insert(prepared, gearName)
			else
				print("[gear] !! GearTools.ShopItems." .. gearName .. " is not a Tool with a Handle - it cannot be a starter gear.")
			end
		end
	end

	-- 3. trap templates GearService clones
	local toolEffects = rs:FindFirstChild("Assets") and rs.Assets:FindFirstChild("ToolEffects")
	if toolEffects then
		for _, name in ipairs({ "PlayerTrap", "SubspaceTrap" }) do
			local template = toolEffects:FindFirstChild(name)
			if template then
				for _, d in ipairs(template:GetDescendants()) do
					if d:IsA("LuaSourceContainer") or d:IsA("Sound") then
						d:Destroy()
					end
				end
			else
				print("[gear] !! ReplicatedStorage.Assets.ToolEffects." .. name .. " missing - that trap will fall back to a plain slab.")
			end
		end
	end

	-- 4. the gear events (ragdoll, bat swing / hit feedback, camera shake)
	local network = rs:FindFirstChild("Network")
	if not network then
		network = Instance.new("Folder")
		network.Name = "Network"
		network.Parent = rs
	end
	for _, remoteName in ipairs(Step.REMOTE_EVENTS) do
		local remote = network:FindFirstChild(remoteName)
		if remote and not remote:IsA("RemoteEvent") then
			remote:Destroy()
			remote = nil
		end
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = network
		end
	end

	print(string.format(
		"[gear] Removed %d world gear pickups (%s); starter gear templates ready: %s; Network events present: %s.",
		#removed,
		#removed > 0 and table.concat(removed, ", ") or "none",
		#prepared > 0 and table.concat(prepared, ", ") or "NONE",
		table.concat(Step.REMOTE_EVENTS, ", ")
	))
end

return Step
