-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiCXdvcmtzcGFjZQ1DdXJyZW50Q2FtZXJhAVgBWRJWaWV3cG9ydFBvaW50VG9SYXkGT3JpZ2luCURpcmVjdGlvbgdSYXljYXN0CEluc3RhbmNlDWdldFJheWNhc3RIaXQFdGFibGUHVmVjdG9yMgZudW1iZXIibWF4RGlzdGFuY2UgbXVzdCBiZSBncmVhdGVyIHRoYW4gMAZhc3NlcnQFcGFpcnMGc3RyaW5nBU1vZGVsBlBhcmVudA5Jc0Rlc2NlbmRhbnRPZg1HZXRIb3ZlcmVkS2V5BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwVUeXBlcw9Db2xsaXNpb25Hcm91cHMNUmF5Y2FzdFBhcmFtcwNuZXcLSWdub3JlV2F0ZXIWUExBWUVSX0NPTExJU0lPTl9HUk9VUA5Db2xsaXNpb25Hcm91cAEMAAMJAgEAAAcEAAAFAkACIaQCAQAAAABATQICSAIAAABHAgMAAAAAgMYDAACCAwIATQUAeQMAAABNBgB4BAAAALwDAkYFAAAAnwMEAqQEAQAAAABATQYDQwYAAABNCANhBwAAAAkHCAH7CAAAvAQEwggAAACfBAUCRwQDAAAAAIDGBQAAggUCAE0FBPQJAAAAggUCAAoDAQQAAABAAwIDAwMEAwUDBgMHAwgDCQAWCgEYAAAAAAEAAQADAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAFwAAAAAMAwIAAAgFAAAFAwRAAlv7AwAATQMDSwAAAABSBAAAnwMCAfsDAABNAwO7AQAAAFIEAQCfAwIB+wMAAE0DA2ACAAAAUgQCAJ8DAgGMBQAAtwUCAAIAAACpBAABqQQBAIEBBAQDAAAAbwUDAKQDBQAAAEBAnwMDAaQEBwAAAGBATQQESAgAAABHBAMAAAAAgMYDAABlABgATQcBeQkAAABNCAF4CgAAALwFBEYLAAAAnwUEAqQGBwAAAGBATQgFQwwAAABNCgVhDQAAAAkJCgL7CgEAvAYGwg4AAACfBgUCRwYDAAAAAIDGAwAAZQACAE0DBvQPAAAARwMDAAAAAIDGBAAAggQCAKQEEQAAAABBUgUAAJ8EAgQXBBQA+wkAAE0JCUESAAAAUgoHAJ8JAgH7CQAATQkJOxMAAABSCggAnwkCAU0JCCQUAAAARwkHAAAAAABSCwgAvAkDrRUAAACfCQMCDgkBAIIHAgBuBOv/AgAAAMYEAACCBAIAFgMLAwwDDQMOAw8EAABAQAMBBAAAYEADAgMDAwQDBQMGAwcDCAMJAxAEAAAAQQMRAxIDEwMUACUVARgTAAAAAAEAAAAAAQAAAAABAAAAAAAAAAAAAOoAAAABAAEAAwAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAEgABAAMAAAAAAQAAAAABAAAAAAEAAAAEAAAAAAH4AAwAFwAAAAAHAAABAgArowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD7wgAAABNAwOECQAAAJ8CAgKkAwwAACyggJ8DAQKpBAEAMAQDYw0AAABNBAJaDgAAADAEAxQPAAAA/wQBAAAAAADABRAAEgADAMAGEQASAAEAEgADADAGBBkSAAAAggQCABMDFgQAAABAAxcDGAMZBAAAQEADGgMbAxwDHQMeAx8EACyggAMgAyEDIgYABgEDFQIAAQEAARgAAwAAAAAAAwAAAAAAAAEAAAAAAAAAAAMAAAEAAAEAAAADAAYADwAAAAAeAQAAAAACdKuHziVawzcxXRnB3X6IggSzkLpGb+3P

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local CollisionGroups = require(ReplicatedStorage.Library.Types.CollisionGroups)
local raycastParams = RaycastParams.new()

-- NPC pass 2026-09-26: pen heroes are in the "NPCs" collision group, which never collides with "Players", so a ray cast
-- as PLAYER_COLLISION_GROUP (the base game's choice: it passes through the stage guards) no longer sees them. The hover
-- ray is cast as "HoverProbe" (Bootstrap: collides with Default / Players / NPCs, not with Guards); until that group
-- has replicated it falls back to Default.
local HOVER_COLLISION_GROUP = "HoverProbe"

raycastParams.IgnoreWater = true
raycastParams.CollisionGroup = "Default"

local hoverGroupReady = false
local function refreshCollisionGroup()
	if hoverGroupReady then
		return
	end
	local ok, registered = pcall(function()
		return PhysicsService:IsCollisionGroupRegistered(HOVER_COLLISION_GROUP)
	end)
	if ok and registered then
		hoverGroupReady = true
		raycastParams.CollisionGroup = HOVER_COLLISION_GROUP
	end
end
refreshCollisionGroup()

local t1 = {}

local function getRaycastHit(vector2: Vector2, n1: number) -- line: 22
	-- upvalues: raycastParams (copy)
	local CurrentCamera = workspace.CurrentCamera

	if CurrentCamera == nil then
		return nil
	end

	refreshCollisionGroup()

	local v10 = CurrentCamera:ViewportPointToRay(vector2.X, vector2.Y)
	local raycastResult = workspace:Raycast(v10.Origin, v10.Direction * n1, raycastParams)

	if raycastResult == nil then
		return nil
	end

	return raycastResult.Instance
end

function t1.GetHoveredKey(t2: {[any]: any}, vector2: Vector2, n2: number) -- line: 37
	-- upvalues: Asserts (copy), raycastParams (copy)
	Asserts.table(t2)
	Asserts.Vector2(vector2)
	Asserts.number(n2)
	assert(n2 > 0.0, "maxDistance must be greater than 0")

	local CurrentCamera = workspace.CurrentCamera
	local v16

	refreshCollisionGroup()

	if CurrentCamera == nil then
		v16 = nil
	else
		local v17 = CurrentCamera:ViewportPointToRay(vector2.X, vector2.Y)
		local raycastResult = workspace:Raycast(v17.Origin, v17.Direction * n2, raycastParams)

		v16 = if raycastResult ~= nil then raycastResult.Instance else nil
	end

	if v16 == nil then
		return nil
	end

	for k, v in pairs(t2) do
		Asserts.string(k)
		Asserts.Model(v)

		if v.Parent ~= nil and v16:IsDescendantOf(v) then
			return k
		end
	end

	return nil
end

return t1

