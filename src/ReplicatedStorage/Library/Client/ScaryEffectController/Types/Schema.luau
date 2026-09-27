-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0D3N0cmljdEludGVyZmFjZQt0cmFja2VkUGFydBN0cmFja2VkUGFydFJlc29sdmVyCnRhcmdldFBhcnQSdGFyZ2V0UGFydFJlc29sdmVyFnByb3hpbWl0eVNvdW5kRGlzdGFuY2USY2hhc2VTb3VuZERpc3RhbmNlFHByb3hpbWl0eU1pbkRpc3RhbmNlD2Jhc2VGaWVsZE9mVmlldwhvcHRpb25hbAtpbnN0YW5jZUlzQQhCYXNlUGFydAhjYWxsYmFjawZudW1iZXILU3RhcnRDb25maWcAAQgAAAECAFejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgKVCQAAAJ8BAgL/AgEAAAAAAE0DAfAKAAAA4gQTAE0FAREUAAAATQYB3RUAAABvBxYAnwYCAJ8FAAIwBQRFCwAAAE0FAREUAAAATQYBphcAAACfBQICMAUErwwAAABNBQERFAAAAE0GAd0VAAAAbwcWAJ8GAgCfBQACMAUE6A0AAABNBQERFAAAAE0GAaYXAAAAnwUCAjAFBMIOAAAATQUBERQAAABNBgFgGAAAAJ8FAgIwBQSnDwAAAE0FAREUAAAATQYBYBgAAACfBQICMAUEbxAAAABNBQERFAAAAE0GAWAYAAAAnwUCAjAFBN4RAAAATQUBERQAAABNBgFgGAAAAJ8FAgIwBQSZEgAAAJ8DAgIwAwLxGQAAAIICAgAaAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwMQAxEFCAsMDQ4PEBESAxIDEwMUAxUDFgMXAAEAARgAAwAAAAAAAwAAAAAAAAAAAAADAAMAAAEAAAAAAAAAAAEAAAAAAAABAAAAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAPgAAAwBAAAAAAA6OMZlobrN8RqXtLDigbX2SiDREQj8rGQ=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	StartConfig = t.strictInterface({
		trackedPart = t.optional(t.instanceIsA("BasePart")),
		trackedPartResolver = t.optional(t.callback),
		targetPart = t.optional(t.instanceIsA("BasePart")),
		targetPartResolver = t.optional(t.callback),
		proximitySoundDistance = t.optional(t.number),
		chaseSoundDistance = t.optional(t.number),
		proximityMinDistance = t.optional(t.number),
		baseFieldOfView = t.optional(t.number)
	})
}

