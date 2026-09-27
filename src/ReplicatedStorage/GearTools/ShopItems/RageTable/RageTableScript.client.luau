-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMuCUNoYXJhY3RlcghIdW1hbm9pZBVGaW5kRmlyc3RDaGlsZE9mQ2xhc3MIQW5pbWF0b3ILZ2V0QW5pbWF0b3INTG9hZEFuaW1hdGlvbgRFbnVtEUFuaW1hdGlvblByaW9yaXR5BkFjdGlvbghQcmlvcml0eQRQbGF5DXBhbHlUaHJvd0FuaW0QQ2FuQWN0aXZhdGVMb2NhbAR3YXJuD2Nhbm5vdCBhY3RpdmF0ZQpVcHBlclRvcnNvDkZpbmRGaXJzdENoaWxkBVRvcnNvBkhlYWx0aAR0aWNrFHJhZ2UgdGFibGUgYWN0aXZhdGVkCkZpcmVTZXJ2ZXIEdGFzawR3YWl0C29uQWN0aXZhdGVkBGdhbWUHUGxheWVycwpHZXRTZXJ2aWNlEVJlcGxpY2F0ZWRTdG9yYWdlB3JlcXVpcmUHTGlicmFyeQZDbGllbnQRVG9vbEdhbWVwbGF5R3VhcmQLTG9jYWxQbGF5ZXIGc2NyaXB0BlBhcmVudBNUaHJvd2luZ1RhYmxlUmVtb3RlDFdhaXRGb3JDaGlsZAlEaXJlY3RvcnkKQW5pbWF0aW9ucwhQaXBlbGluZRtyYnhhc3NldGlkOi8vOTQyMjYzMTU0MTgwNzMYR2V0QW5kU2VyaWFsaXplQW5pbWF0aW9uBGFuaW0JQWN0aXZhdGVkB0Nvbm5lY3QABAUAAQAAABH7AAAATQAAaQAAAABSAQAADgEEAG8DAQC8AQC4AgAAAJ8BAwIOAQUAbwQDALwCAbgCAAAAnwIDAisCAQDGAgAAggICAAQDAQMCAwMDBAAVBQEYAAAAAQAAAAAAAQAAAAAAAAAWAAAAAAYAAgAAAB/7AQAATQEBaQAAAABSAgEADgIEAG8EAQC8AgG4AgAAAJ8CAwIOAgYAbwUDALwDArgCAAAAnwMDAlIAAwArAAEAxgAAACsAAQCCAAEA+wMBALwBAJQEAAAAnwEDAqQCCAAHGFDAMAIBzQkAAAC8AgHuCgAAAJ8CAgGCAAEACwMBAwIDAwMEAwYDBwMIAwkEBxhQwAMKAwsAGwwBGAAAAAEAAAAAAAEAAAAAAAAABQEDAAAAAQAAAAEAAAEWAAAAAAoABwAAAGL7AAAADgABAIIAAQD7AAEATQAAPAAAAAD7AQIAnwACAisABQCkAAIAAAAQQG8BAwCfAAIBggABAPsAAwBNAABpBAAAACsAAQCCAAEAbwMFALwBALgGAAAAnwEDAm8EBwC8AgADCAAAAJ8CAwIrAgQAbwQJALwCAAMIAAAAnwIDAg4BAQArAgEAggABAE0DAVoKAAAAjAQAAH0DAgAEAAAAggABAKQDDAAAALBAnwMBAvsFBAAmBAMFjAUIAGAEAgAFAAAAggABAKkEAQDeBAAA3gMEAKQEAgAAABBAbwUNAJ8EAgH7BQMATQUFaQQAAABSBgUADgYEAG8IBQC8BgW4BgAAAJ8GAwIOBgYAbwkOALwHBrgGAAAAnwcDAlIEBwArBAEAxgQAACsEAQBlAAsA+wcFALwFBJQPAAAAnwUDAqQGEwASRADBMAYFzRQAAAC8BgXuFQAAAJ8GAgH7BAYAvAQEaxYAAACfBAIBpAQZAABgcIFvBRoAnwQCAakEAADeBAAAggABABsDDQMOBAAAEEADDwMBAwIDAwMQAxEDEgMTAxQEAACwQAMVAwQDBgMHAwgDCQQSRADBAwoDCwMWAxcDGAQAYHCBAgAAAAAAAOA/ACYZARgRAAECAAAAAAABAAAAAgMAAAEBAwAAAAEAAAAAAAAAAAIAAQIAAAAAAQMAAAEAAAAAAQMAAQEAAADQAAABAAAAAAABAAAAAAAAAAUBAwAAAAEAAAABAAAlAAAAAgAAAAEAARYAAAAAEAAAAQIARqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAWoHAAAATQMDTQgAAABNAwOCCQAAAJ8CAgJNAwAxCgAAAKQEDAAAALBATQQEJA0AAABvBw4AvAUE0w8AAACfBQMCpAYGAAAAUEBNBwGREAAAAE0HB0QRAAAATQcHORIAAACfBgICbwkTALwHBukUAAAAnwcDAk0HBy4VAAAAjAgAAKkJAADAChYAEgADAMALFwASAAMAEgAHANkMAgASAQn/EgACABIABAASAAMAEgEI/xIABwASAAUATQ0EHhgAAABSDwwAvA0NxxkAAACfDQMBwQgAAIIAAQAaAxoEAAAAQAMbAxwDHQMeBAAAUEADHwMgAyEDIgMjBAAAsEADJAMlAyYDJwMoAykDKgMrAywGAAYBAy0DLgMAAQIBAAEYAAIAAAAAAAIAAAAAAAEAAAAAAAAAAAIAAQAAAAIAAAACAAAAAAAAAAACAAAAAAACAgIABgAACwAAAAAAAAAoAAAAAAABAAEAAAAAAwZwcDJXbWh42JEMVeJpl5R2aGdGNLQaMw==

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolGameplayGuard = require(ReplicatedStorage.Library.Client.ToolGameplayGuard)
local LocalPlayer = Players.LocalPlayer
local scriptParent = script.Parent
local ThrowingTableRemote = scriptParent:WaitForChild("ThrowingTableRemote")
local anim = require(ReplicatedStorage.Directory.Animations.Pipeline):GetAndSerializeAnimation("rbxassetid://94226315418073").anim
local n1 = 0.0
local u9 = false

local function getAnimator() -- line: 21
	-- upvalues: LocalPlayer (copy)
	local Character = LocalPlayer.Character
	local v14 = Character and Character:FindFirstChildOfClass("Humanoid")

	return v14 and v14:FindFirstChildOfClass("Animator") or nil
end
local function palyThrowAnim() -- line: 27
	-- upvalues: LocalPlayer (copy), anim (copy)
	local Character = LocalPlayer.Character
	local v16 = Character and Character:FindFirstChildOfClass("Humanoid")
	local v17 = v16 and v16:FindFirstChildOfClass("Animator") or nil

	if not v17 then
		return
	end

	local track = v17:LoadAnimation(anim)

	track.Priority = Enum.AnimationPriority.Action
	track:Play()
end
local function onActivated() -- line: 38
	-- upvalues: u9 (ref), ToolGameplayGuard (copy), scriptParent (copy), LocalPlayer (copy), n1 (ref), anim (copy), ThrowingTableRemote (copy)
	if u9 then
		return
	end

	if not ToolGameplayGuard.CanActivateLocal(scriptParent) then
		warn("cannot activate")

		return
	end

	local Character = LocalPlayer.Character

	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local v21 = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")

	if not Humanoid or not v21 then
		return
	end

	if Humanoid.Health <= 0.0 then
		return
	end

	local timestamp = tick()

	if timestamp - n1 < 8.0 then
		return
	end

	u9 = true
	n1 = timestamp
	warn("rage table activated")

	local Character2 = LocalPlayer.Character
	local v24 = Character2 and Character2:FindFirstChildOfClass("Humanoid")
	local v25 = v24 and v24:FindFirstChildOfClass("Animator") or nil

	if v25 then
		local track = v25:LoadAnimation(anim)

		track.Priority = Enum.AnimationPriority.Action
		track:Play()
	end

	ThrowingTableRemote:FireServer()
	task.wait(0.5)
	u9 = false
end

scriptParent.Activated:Connect(onActivated)

