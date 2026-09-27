-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdFEFzc2V0TW9kZWxSZXBsaWNhdGVkBEZpcmUZX21hcmtBc3NldE1vZGVsUmVwbGljYXRlZAZpcGFpcnMUR2V0QXNzZXRNb2RlbHNGb2xkZXILR2V0Q2hpbGRyZW4FTW9kZWwDSXNBHEh5ZHJhdGVBc3NldENvbmZpZ01vZGVsU2NhbGUETmFtZR5faW5pdFJlcGxpY2F0ZWRBc3NldE1vZGVsU3RhdGUGc3RyaW5nGUdldEFzc2V0TW9kZWxJZlJlcGxpY2F0ZWQWSXNBc3NldE1vZGVsUmVwbGljYXRlZAVhcnJheRRGb3JjZUxvYWRBc3NldE1vZGVscxtBcmVBbGxBc3NldE1vZGVsc1JlcGxpY2F0ZWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzB01vZHVsZXMLQXNzZXRNb2RlbHMIUGFja2FnZXMGU2lnbmFsA25ldxhBbGxBc3NldE1vZGVsc1JlcGxpY2F0ZWQABgYCAgAABwQAAAUCAwcQ+wMAAIcCAwAOAgEAggABAPsCAACpAwEAagMCAPsCAQBNAgLuAAAAAFIEAABSBQEAvAIC3QEAAACfAgQBggABAAIDAQMCABgDARgAAAABAwAAAQAAAAAAAAABGQAAAAAIAAIAAAAgpAABAAAAAED7AQAATQEBFAIAAACfAQECvAEBaAMAAACfAQIAnwAABFEAEgBvBwQAvAUE/gUAAACfBQMCDgUNAPsFAABNBQVoBgAAAE0GBLoHAAAAnwUCAfsFAQBNBQUQCAAAAE0GBLoHAAAAUgcEAJ8FAwFuAO3/AgAAgIIAAQAJAwQEAAAAQAMFAwYDBwMIAwkDCgMDACELARgAAAAAAAAAAAAAAAEAAAAAAQAAAAAAAQAAAAAAAP0ABiIAAAAABAECAAAGAwAABQEDD/sBAABNAQFBAAAAAFICAACfAQIB+wIBAE0CAocBAAAAUgMAAJ8CAgJHAgIAAAAAgKkBAAGpAQEAggECAAIDDAMNAC4OARgAAAAAAAEAAAAAAAAAAAAvAAAAAAMBAQAABgMAAAUBBAn7AQAATQEBHQAAAABNAQFBAQAAAFICAACfAQIBqQEBAIIBAgACAw8DDAAzEAEYAAAAAAAAAAEANAAAAAABAAAAAAACqQABAIIAAgAAADgRARgAADkAAAAABwAAAQIAR6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA+gIAAAATQMDCAkAAACfAgICpAMFAAAAQEBNBABqBgAAAE0EBOgIAAAATQQE5goAAABNBAQfCwAAAJ8DAgL/BAAAAAAAAP8FBAAAAAAATQYD7wwAAACfBgECMAYF7g0AAABNBgPvDAAAAJ8GAQIwBgVPDgAAAMAGDwASAAQAEgAFADAGBRAQAAAAwAYRABIAAgASAAUAMAYF/xIAAADABhMAEgABABIAAgAwBgXIFAAAAMAGFQASAAEAMAYFEBYAAADABhcAMAYFVRgAAACCBQIAGQMSBAAAAEADEwMUAxUEAABAQAMWAxcDGAMZAxoDGwMcAwEDHQYAAwMGAQMLBgIDDgYDAxAGBAMRBQABAgMEAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAAADAAQAAQAAAAABAAAAAAYAAAAACQAAAAANAAAAAAUAAAAFAAAIAQAAAAAFNQEtdGD1+m9UKuoIS+bea0UZOgAHxUd1

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local AssetModels = require(ReplicatedStorage.Library.Modules.AssetModels)
local Signal = require(ReplicatedStorage.Library.Modules.Packages.Signal)
local t1 = {}
local t2 = {
	AssetModelReplicated = Signal.new(),
	AllAssetModelsReplicated = Signal.new()
}

function t2._markAssetModelReplicated(s1: string, p1) -- line: 24
	-- upvalues: t1 (copy), t2 (copy)
	if t1[s1] then
		return
	end

	t1[s1] = true
	t2.AssetModelReplicated:Fire(s1, p1)
end
function t2._initReplicatedAssetModelState() -- line: 33
	-- upvalues: AssetModels (copy), t2 (copy)
	for _, child in ipairs(AssetModels.GetAssetModelsFolder():GetChildren()) do
		if child:IsA("Model") then
			AssetModels.HydrateAssetConfigModelScale(child.Name)
			t2._markAssetModelReplicated(child.Name, child)
		end
	end
end
function t2.IsAssetModelReplicated(s2: string) -- line: 46
	-- upvalues: Asserts (copy), AssetModels (copy)
	Asserts.string(s2)

	return AssetModels.GetAssetModelIfReplicated(s2) ~= nil
end
function t2.ForceLoadAssetModels(t3: {[any]: any}) -- line: 51
	-- upvalues: Asserts (copy)
	Asserts.array.string(t3)

	return true
end
function t2.AreAllAssetModelsReplicated() -- line: 56
	return true
end

return t2

