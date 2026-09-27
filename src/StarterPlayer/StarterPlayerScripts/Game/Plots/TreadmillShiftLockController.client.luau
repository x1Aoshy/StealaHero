-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdCG9wdGlvbmFsBnN0cmluZwVMb2NrcxBEaXNhYmxlU2hpZnRMb2NrCk9idGFpbkxvY2sHQXREZWJ1ZzREaXNhYmxlZCBzaGlmdCBsb2NrIGZvciB0aGUgYWN0aXZlIHRyZWFkbWlsbCBzZXNzaW9uA0xvZylSZWxlYXNlZCB0cmVhZG1pbGwgc2hpZnQtbG9jayBzdXBwcmVzc2lvbhZ1cGRhdGVUcmVhZG1pbGxTZXNzaW9uBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwdHbG9iYWxzCUNvbnN0YW50cwdNb2R1bGVzCFBhY2thZ2VzBkNsaWVudAdOZXR3b3JrCVZhcmlhYmxlcwtORVRXT1JLX01BUApUcmVhZG1pbGxzA25ldwVGaXJlZBZBQ1RJVkVfVFJFQURNSUxMX0VWRU5UB0Nvbm5lY3QAAgQBBAAABgMAAAUBgzD7AQAATQEBEQAAAABNAQFBAQAAAFICAACfAQIBRwAWAAAAAAD7AQEARwETAAAAAID7AQIATQEBgQIAAABNAQFxAwAAALwBAS8EAAAAnwECAt4BAQD7AQMAvAEBHAUAAACfAQICbwMGALwBAaEHAAAAnwEDAYIAAQBHABAAAAAAgPsBAQBHAQ0AAAAAAPsBAQCfAQEBxgEAAN4BAQD7AQMAvAEBHAUAAACfAQICbwMIALwBAaEHAAAAnwEDAYIAAQAJAwEDAgMDAwQDBQMGAwcDCAMJABsKARgAAAAAAAAAAgAAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAEAAQABAAAAAAAAAAIcAAAAAA0AAAECAEqjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwNLCAAAAE0DAwcJAAAAnwICAqQDBQAAAEBATQQAagYAAABNBAToCgAAAE0EBOYLAAAATQQEoQwAAACfAwICpAQFAAAAQEBNBQBqBgAAAE0FBU0NAAAATQUFUg4AAACfBAICpAUFAAAAQEBNBgBqBgAAAE0GBmwPAAAAnwUCAk0GArMQAAAATQYG5xEAAABNBwPvEgAAAJ8HAQLGCAAA2QkAABIAAQASAQj/EgAFABIABwBNCgRLEwAAAE0LBroUAAAAnwoCAlIMCQC8CgrHFQAAAJ8KAwHBCAAAggABABYDCwQAAABAAwwDDQMOBAAAQEADDwMQAxEDEgMTAxQDCAMVAxYDFwMYAxkDGgMbAxwDHQEAAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAwAAAAYAAAEGAAAAABEAAAAAAAAAAAEAAQAAAAABcP4k9u7VWZ8Sz9OEEqvjWwDmM4JCOk73

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Constants = require(ReplicatedStorage.Library.Globals.Constants)
local Log = require(ReplicatedStorage.Library.Modules.Packages.Log)
local Network = require(ReplicatedStorage.Library.Client.Network)
local Variables = require(ReplicatedStorage.Library.Variables)
local Treadmills = Constants.NETWORK_MAP.Treadmills
local v8 = Log.new()
local u9 = nil

local function updateTreadmillSession(s1: string?) -- line: 27
	-- upvalues: Asserts (copy), u9 (ref), Variables (copy), v8 (copy)
	Asserts.optional.string(s1)

	if s1 ~= nil and u9 == nil then
		u9 = Variables.Locks.DisableShiftLock:ObtainLock()
		v8:AtDebug():Log("Disabled shift lock for the active treadmill session")

		return
	end

	if s1 == nil and u9 ~= nil then
		u9()
		u9 = nil
		v8:AtDebug():Log("Released treadmill shift-lock suppression")
	end
end

Network.Fired(Treadmills.ACTIVE_TREADMILL_EVENT):Connect(updateTreadmillSession)

