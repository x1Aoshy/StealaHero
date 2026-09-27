-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMgCklzQ2FycnlpbmcHRW5hYmxlZAtzZXRDYXJyeWluZxZSZXF1ZXN0RHJvcEhlbGRBcmVhRWdnB0F0RGVidWckRHJvcCBoZWxkIGFyZWEgZWdnIGRlbmllZCBmb3IgJSo6ICUqBlVzZXJJZAZmb3JtYXQDTG9nBGdhbWUHUGxheWVycwpHZXRTZXJ2aWNlEVJlcGxpY2F0ZWRTdG9yYWdlB3JlcXVpcmUHTGlicmFyeQVUeXBlcwhBcmVhRWdncwZDbGllbnQFR1VJRlgIQnV0dG9uRlgHRWdnQ21kcwNHVUkHTW9kdWxlcwhQYWNrYWdlcwtEcm9wUmVhc29ucw1QbGF5ZXJSZXF1ZXN0A25ldwtMb2NhbFBsYXllcgtEcm9wSGVsZEVnZwZCdXR0b24YQXJlYUVnZ0NhcnJ5U3RhdGVDaGFuZ2VkB0Nvbm5lY3QAAwMBAQAAAA1NAQD+AAAAAA4BBQD7AQAAqQIBADACAfABAAAAggABAPsBAACpAgAAMAIB8AEAAACCAAEAAgMBAwIAHwMBGAAAAAEAAAAAAgAAAAIgAAAAAAgABAAAABj7AAAATQAA/AAAAAD7AQEAnwACAysAEQBHARAAAAAAAPsCAgC8AgIcAQAAAJ8CAgJvBAIA+wYDAE0GBuYDAAAAUgcBALwEBI0EAAAAnwQEArwCAqEFAAAAnwIDAYIAAQAGAwQDBQMGAwcDCAMJAC0AARgAAAAAAAEAAAEAAAAAAAAAAAAAAAAAAAIuAAAAABAAAAECAGCjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAwFqBwAAAE0DA+8IAAAATQMDqgkAAACfAgICpAMGAAAAUEBNBAFqBwAAAE0EBE0KAAAATQQEgQsAAABNBASUDAAAAJ8DAgKkBAYAAABQQE0FAWoHAAAATQUFTQoAAABNBQVNDQAAAJ8EAgKkBQYAAABQQE0GAWoHAAAATQYGTQoAAABNBgY5DgAAAJ8FAgKkBgYAAABQQE0HAWoHAAAATQcH6A8AAABNBwfmEAAAAE0HB6ERAAAAnwYCAk0HAr8SAAAATQcHqxMAAABNCAbvFAAAAJ8IAQJNCQAxFQAAAE0KBd4WAAAAnwoBAsALFwASAAoAqQwAADAMCvAYAAAAUgwDAE0NCqwZAAAAxg4AAMAPGgASAAQAEgAHABIACAASAAkAnwwEAU0MBLobAAAAUg4LALwMDMccAAAAnwwDAYIAAQAdAwoEAAAAQAMLAwwDDQMOBAAAUEADDwMQAxEDEgMTAxQDFQMWAxcDGAMJAxkDGgMbAxwDHQYAAwIDHgYBAx8DIAIAAQEAARgAAwAAAAAAAQAAAAAAAwAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAgAAAADAAABAAEAAAYADAAAAgAAAAAAAAAAAAcAAAAAAAEBAAAAAAJaOczs6DPUwTPTJ6y5/txrKiHbmGj9pu0=

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AreaEggs = require(ReplicatedStorage.Library.Types.AreaEggs)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local EggCmds = require(ReplicatedStorage.Library.Client.EggCmds)
local GUI = require(ReplicatedStorage.Library.Client.GUI)
local Log = require(ReplicatedStorage.Library.Modules.Packages.Log)
local PlayerRequest = AreaEggs.DropReasons.PlayerRequest
local v9 = Log.new()
local LocalPlayer = Players.LocalPlayer
local v11 = GUI.DropHeldEgg()

local function setCarrying(p1) -- line: 31
	-- upvalues: v11 (copy)
	if p1.IsCarrying then
		v11.Enabled = true

		return
	end

	v11.Enabled = false
end

v11.Enabled = false
ButtonFX(v11.Button, nil, function() -- line: 45
	-- upvalues: EggCmds (copy), PlayerRequest (copy), v9 (copy), LocalPlayer (copy)
	local v14, v15 = EggCmds.RequestDropHeldAreaEgg(PlayerRequest)

	if not v14 and v15 ~= nil then
		v9:AtDebug():Log(`Drop held area egg denied for { LocalPlayer.UserId }: { v15 }`)
	end
end)
EggCmds.AreaEggCarryStateChanged:Connect(setCarrying)

