-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdD19wcm9maWxlTWFuYWdlcgJpcwNHZXQGUGxheWVyBlVzZXJJZBFHZXRQbGF5ZXJJbnN0YW5jZQxTdHJpbmdVc2VySWQIdG9zdHJpbmcGdHlwZW9mBm51bWJlcgZzdHJpbmcOR2V0SW5kZXhNZXRob2QUQXV0b0Rlc3Ryb3lJZk5vSW5kZXgHRGVzdHJveRBQcm9maWxlQ29udGFpbmVyBXRhYmxlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdMaWJyYXJ5B3JlcXVpcmUHTW9kdWxlcwhQYWNrYWdlcwF0CUZ1bmN0aW9ucw1JbnN0YW5jZUNoZWNrEkNvcmVQcm9maWxlTWFuYWdlcgV0dXBsZQhvcHRpb25hbAAECAQCAAAJBgAABQQPDw8EOU0EABoAAAAADgQLAPsFAABNBQUEAQAAAFIGBACfBQICDgUFAFIHAgC8BQR/AgAAAJ8FAwCCBQAA+wUBAFIGAgBvBwMAnwUDAg4FFQBNBQLmBAAAAE0HA30FAAAADgcCAFIGAgArBgoATQcD+AYAAAAOBwYAuz8FA1IHBQCkBggAAABwQJ8GAgIrBgEAUgYFAFIHBgAOBwEAhwcBBoIHAgC7LAIDUgYCAKQFCgAAAJBAnwUCAvAFCAALAAAAuywCA1IGAgCkBQoAAACQQJ8FAgLwBQMADAAAgIcFAQKCBQIAggABAA0DAQMCAwMDBAMFAwYDBwMIBAAAcEADCQQAAJBAAwoDCwAdDAEYAAABAAAAAAAAAQAAAAADAAAAAAEAAgAAAAABAAAAAAAAAAABAgAAAAEAAAAAAAAAAAAAAAAAAQACHgAAAAAHAgMBAAcEAAAFAg8DJ6MCAAD7AwAATQMDJwAAAAAOAwMAKwECAG8CAQBlAAEAUgIBAFIBAgC7LAEDUgMBAKQCAwAAACBAnwICAvACAgAEAAAAggABAPsCAQD7AwIA+wQAAE0EBIsFAAAAUgUAAPsGAACfAgUCuywCA1IEAgCkAwMAAAAgQJ8DAgLwAwIABgAAAIIAAQCHAwIBUgQCAN0FAACfAwAAggMAAAcDDQMOAwkEAAAgQAMLAw8DEAA1AAEYAAEAAAAAAAAAAAEAAAAAAAABAwAAAAAAAAACAAAAAAAAAQIAAAAANQAAAAAFAgIAAAcEAAAFAg8EC/sCAABSAwAAUgQBAJ8CAwIrAgEAggABANkCAAASAAEAEgIBABIAAACCAgIAAAEBMAABGAAAAAAAAQMAAAAAMQAAAAAIAAABAgAxowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAk0AAGoEAAAApAEGAAAAUEBNAgDoBwAAAE0CAuYIAAAATQIClQkAAACfAQICpAIGAAAAUEBNAwBTCgAAAE0DA38LAAAAnwICAqQDBgAAAFBATQQA6AcAAABNBAS6DAAAAJ8DAgJNBAF4DQAAAE0FAUsOAAAATQYBEQ8AAABNBwFLDgAAAJ8GAgCfBAACwAUQABIAAwASAAIAwAYRABIABAASAAUAggYCABIDEQQAAABAAxIDEwMUAxUEAABQQAMWAxcDGAMZAxoDGwMcAxADHQYABgICAAIBAAEYAAEAAAAAAAAAAwAAAAAAAAAAAQAAAAAAAAEAAAAAAAADAAAAAAAAAAAAEwAAEwAAAAEAAAAAA5g7QWk5fFB1RTtwznimWtfoI1Ydqv8raA==

-- decompilation:
local Library = game:GetService("ReplicatedStorage").Library
local t = require(Library.Modules.Packages.t)
local InstanceCheck = require(Library.Functions.InstanceCheck)
local CoreProfileManager = require(Library.Modules.CoreProfileManager)
local v5 = t.tuple(t.table, t.optional(t.table))

local function GetIndexMethod(p1, p2, p3, t1: {[any]: any}) -- line: 29
	-- upvalues: CoreProfileManager (copy), InstanceCheck (copy)
	local _profileManager = p1._profileManager

	if _profileManager and CoreProfileManager.is(_profileManager) then
		return _profileManager:Get(p3)
	end

	if InstanceCheck(p3, "Player") then
		local UserId = p3.UserId
		local v13 = t1.GetPlayerInstance and p3 or (t1.StringUserId and tostring(UserId) or UserId)

		return v13 and p2[v13]
	end

	if typeof(p3) == "number" or typeof(p3) == "string" then
		return p2[p3]
	end
end

return function(p4, t2: {[any]: any}) -- line: 48
	-- upvalues: v5 (copy), GetIndexMethod (copy)
	if not v5(p4, t2) then
		return
	end

	return function(p5, s1: string, ...) -- line: 53
		-- upvalues: t2 (copy), GetIndexMethod (copy), p4 (copy)
		local v18 = if not t2.AutoDestroyIfNoIndex then s1 else s1 or "Destroy"

		if typeof(v18) ~= "string" then
			return
		end

		local v19 = GetIndexMethod(p4, t2.ProfileContainer, p5, t2)

		if typeof(v19) ~= "table" then
			return
		end

		return v19[v18](v19, ...)
	end
end

