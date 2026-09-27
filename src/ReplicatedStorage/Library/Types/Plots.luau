-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0EFNjaGVtYVZhbGlkYXRpb24PUGxvdFN0YXRlVXBkYXRlEVBsb3RTdGF0ZVNuYXBzaG90CWludGVyZmFjZQhSZXZpc2lvbgRTbG90BlVzZXJJZAZudW1iZXIIb3B0aW9uYWwMT3duZXJzQnlTbG90A21hcAZzdHJpbmcAAQkAAAECAD+jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgKVCQAAAJ8BAgLiAgsA4gMOAE0EAS8PAAAA4gUTAE0GAWAUAAAAMAYFsRAAAABNBgFgFAAAADAGBZMRAAAATQYBERUAAABNBwFgFAAAAJ8GAgIwBgXmEgAAAJ8EAgIwBAMWDAAAAE0EAS8PAAAA4gUXAE0GAWAUAAAAMAYFsRAAAABNBgGQGAAAAE0HAUEZAAAATQgBYBQAAACfBgMCMAYF6RYAAACfBAICMAQDmg0AAAAwAwLfCgAAAIICAgAaAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQUBCgMKAwsFAgwNAwwDDQMOAw8FAxAREgMQAxEDEgUCEBYDEwMUAAEAARgAAgAAAAAAAgAAAAAAAAAAAAAbAQEAAAEAAAABAAAAAQAAAAAAAP0AAAUAAAEAAAABAAAAAAAAAAD+AAD6AA0BAAAAAAC5rumeAwE+BKuOfsQv7gA1ybb+6otqg58=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	SchemaValidation = {
		PlotStateUpdate = t.interface({
			Revision = t.number,
			Slot = t.number,
			UserId = t.optional(t.number)
		}),
		PlotStateSnapshot = t.interface({
			Revision = t.number,
			OwnersBySlot = t.map(t.string, t.number)
		})
	}
}

