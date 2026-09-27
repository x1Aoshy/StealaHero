-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0BXR1cGxlBXRhYmxlBXVuaW9uBnN0cmluZx9jb25maWd1cmVBbmltYXRpb25TZXRQYXJhbWV0ZXJzCG9wdGlvbmFsBm51bWJlchNwbGF5QW5pbWF0aW9uQ29uZmlnAAEMAAABAgBDowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQIC/wICAAAAAABNAwF4CgAAAE0EAUsLAAAATQUBmAwAAABNBgFBDQAAAE0HAUsLAAAAnwUDAJ8DAAIwAwJvDgAAAE0DAXgKAAAATQQBQQ0AAABNBQERDwAAAE0GAWAQAAAAnwUCAk0GAREPAAAATQcBYBAAAACfBgICTQcBEQ8AAABNCAFgEAAAAJ8HAgJNCAERDwAAAE0JAZgMAAAATQoBSwsAAABNCwFBDQAAAJ8JAwCfCAAAnwMAAjADAnQRAAAAggICABIDAQQAAABAAwIDAwMEBAAAQEADBQMGAwcDCAMJAwoDCwMMAw0DDgMPAxAAAQABGAABAAAAAAADAAAAAAAAAAAAAAMAAwAAAAAAAAAAAAAA/wADAAEAAQAAAAABAAAAAAEAAAAAAQAAAAAAAAAAAPsAAAgBAAAAAACLvhAmDlY1LywpphI0oYI/+6YHUrl6eic=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	configureAnimationSetParameters = t.tuple(t.table, t.union(t.string, t.table)),
	playAnimationConfig = t.tuple(t.string, t.optional(t.number), t.optional(t.number), t.optional(t.number), t.optional(t.union(t.table, t.string)))
}

