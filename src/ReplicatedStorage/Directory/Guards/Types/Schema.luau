-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMzBWVycm9yDXVuaW1wbGVtZW50ZWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdNb2R1bGVzCFBhY2thZ2VzAXQJRGlyZWN0b3J5CkFuaW1hdGlvbnMIUGlwZWxpbmUHUHJpdmF0ZQVUeXBlcwZSYXJpdHkPR3VhcmROYW1lRXhpc3RzCWludGVyZmFjZQdTb3VuZElkCFNvdW5kSWRzBlZvbHVtZQtNYXhEaXN0YW5jZQ1QbGF5YmFja1NwZWVkBkxvb3BlZAZzdHJpbmcIb3B0aW9uYWwFYXJyYXkGbnVtYmVyB2Jvb2xlYW4LU291bmRDb25maWcFdW5pb24UQWZ0ZXJXYWtlU291bmRDb25maWcDX2lkCkZsYXRSYWRpdXMJV2Fsa1NwZWVkC0hpdERpc3RhbmNlEUVnZ1BpY2t1cERpc3RhbmNlFkFuaW1hdGlvbkJhc2VXYWxrU3BlZWQaSG9tZUltcHVsc2VCb29zdERpc3RhbmNlWFoNSWRsZUFuaW1hdGlvbg5TbGVlcEFuaW1hdGlvbg1XYWxrQW5pbWF0aW9uD0F0dGFja0FuaW1hdGlvbgpTbGVlcFNvdW5kCVdha2VTb3VuZA5BZnRlcldha2VTb3VuZAtBdHRhY2tTb3VuZA1Gb290c3RlcFNvdW5kDURlZmF1bHRDb25maWcObnVtYmVyUG9zaXRpdmUTU2VyaWFsaXplZEFuaW1hdGlvbgACAwEAAAAGAwAABQEDBaQBAQAAAABAbwICAJ8BAgGCAAEAAwMBBAAAAEADAgAOAAEYAAAAAAEPAAAAAAoAAAECAL0BowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQICpAIFAAAAQEBNAwCRCgAAAE0DA0QLAAAATQMDOQwAAABNAwMMDQAAAE0DA+8OAAAAnwICAqQDBQAAAEBATQQAkQoAAABNBATyDwAAAJ8DAgL/BAMAAAAAAMAFEAAwBQStEQAAAE0FAS8SAAAA4gYZAE0HAUEaAAAAMAcGfBMAAABNBwERGwAAAE0IAR0cAAAATQkBQRoAAACfCAIAnwcAAjAHBvMUAAAATQcBYB0AAAAwBwZLFQAAAE0HAWAdAAAAMAcGmRYAAABNBwERGwAAAE0IAWAdAAAAnwcCAjAHBigXAAAATQcBERsAAABNCAE+HgAAAJ8HAgIwBwa1GAAAAJ8FAgIwBQSOHwAAAE0FAZggAAAATQYEjh8AAABNBwEdHAAAAE0IBI4fAAAAnwcCAJ8FAAIwBQTzIQAAAE0FAS8SAAAA4gYyAE0HAUEaAAAAMAcG0yIAAABNBwPvDgAAAE0HBwwzAAAAMAcG8g8AAABNBwFgHQAAADAHBt8jAAAATQcBYB0AAAAwBwaOJAAAAE0HAREbAAAATQgBxDQAAACfBwICMAcGICUAAABNBwERGwAAAE0IAcQ0AAAAnwcCAjAHBvcmAAAATQcBERsAAABNCAFgHQAAAJ8HAgIwBwZJJwAAAE0HAcQ0AAAAMAcGxSgAAABNBwLwNQAAADAHBvopAAAATQcC8DUAAAAwBwbTKgAAAE0HAvA1AAAAMAcGwCsAAABNBwLwNQAAADAHBrIsAAAATQcEjh8AAAAwBwbCLQAAAE0HBI4fAAAAMAcG+y4AAABNBwERGwAAAE0IBPMhAAAAnwcCAjAHBjEvAAAATQcEjh8AAAAwBwaIMAAAAE0HAREbAAAATQgEjh8AAACfBwICMAcGhDEAAACfBQICMAUEDDMAAACCBAIANgMDBAAAAEADBAMFAwYEAABAQAMHAwgDCQMKAwsDDAMNAw4DDwMQBgADEQMSAxMDFAMVAxYDFwMYBQYTFBUWFxgDGQMaAxsDHAMdAx4DHwMgAyEDIgMjAyQDJQMmAycDKAMpAyoDKwMsAy0DLgMvAzAFESIPIyQlJicoKSorLC0uLzAxAzEDMgMzAQABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAEAAAAAAAADAAIAAAQAAAEAAAABAAAAAAAAAAAAAQAAAAEAAAABAAAAAAAAAQAAAAAAAPoAAAkAAAAAAAAAAAAAAAIAAAEAAAACAAAAAAABAAAAAQAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAACAAAAAQAAAAEAAAABAAAAAgAAAAEAAAABAAAAAAAAAQAAAAEAAAAAAADsAAAXAQAAAAABNMJ3e7wecrLNtTrYrrUfIkTaYA8GBh16

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local Types = require(ReplicatedStorage.Directory.Animations.Pipeline.Private.Types)
local Rarity = require(ReplicatedStorage.Directory.Rarity)
local t1 = {
	GuardNameExists = function(_: string) -- line: 14
		error("unimplemented")
	end,
	SoundConfig = t.interface({
		SoundId = t.string,
		SoundIds = t.optional(t.array(t.string)),
		Volume = t.number,
		MaxDistance = t.number,
		PlaybackSpeed = t.optional(t.number),
		Looped = t.optional(t.boolean)
	})
}

t1.AfterWakeSoundConfig = t.union(t1.SoundConfig, t.array(t1.SoundConfig))
t1.DefaultConfig = t.interface({
	_id = t.string,
	Rarity = Rarity.Types.DefaultConfig,
	FlatRadius = t.number,
	WalkSpeed = t.number,
	HitDistance = t.optional(t.numberPositive),
	EggPickupDistance = t.optional(t.numberPositive),
	AnimationBaseWalkSpeed = t.optional(t.number),
	HomeImpulseBoostDistanceXZ = t.numberPositive,
	IdleAnimation = Types.SerializedAnimation,
	SleepAnimation = Types.SerializedAnimation,
	WalkAnimation = Types.SerializedAnimation,
	AttackAnimation = Types.SerializedAnimation,
	SleepSound = t1.SoundConfig,
	WakeSound = t1.SoundConfig,
	AfterWakeSound = t.optional(t1.AfterWakeSoundConfig),
	AttackSound = t1.SoundConfig,
	FootstepSound = t.optional(t1.SoundConfig)
})

return t1

