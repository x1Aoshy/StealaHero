-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMpBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0DERlZmF1bHRTdGF0cwVUeXBlcwxTY2hlbWFGaWVsZHMFdW5pb24HbGl0ZXJhbAhCcmFpbnJvdAVGdW5ueQpTYXRpc2Z5aW5nDVdlaXJkT3JIb3Jyb3IFTXVzaWMYVHJlYWRtaWxsTWVkaWFCdWNrZXRUeXBlD3N0cmljdEludGVyZmFjZQdTb3VuZElkBlZvbHVtZQZzdHJpbmcGbnVtYmVyFFZpZGVvQmFja2dyb3VuZE11c2ljBEtpbmQOUmVsZWFzZVZlcnNpb24KQnVja2V0VHlwZQVWaWRlbwpDb3ZlckltYWdlBFNpemUIb3B0aW9uYWwFVURpbTIPVmlkZW9NZWRpYUVudHJ5BUltYWdlCk11c2ljSW1hZ2UUTXVzaWNJbWFnZU1lZGlhRW50cnkTVHJlYWRtaWxsTWVkaWFFbnRyeQVhcnJheRVUcmVhZG1pbGxNZWRpYUVudHJpZXMXVHJlYWRtaWxsTWVkaWFGZWVkU3RhdGUAAQsAAAECALEBowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA+gHAAAATQMDXwoAAABNAwPvCwAAAE0DA28MAAAAnwICAv8DBAAAAAAATQQBmA0AAABNBQFzDgAAAG8GDwCfBQICTQYBcw4AAABvBxAAnwYCAk0HAXMOAAAAbwgRAJ8HAgJNCAFzDgAAAG8JEgCfCAICTQkBcw4AAABvChMAnwkCAJ8EAAIwBAMJFAAAAE0EAfAVAAAA4gUYAE0GAUEZAAAAMAYFfBYAAABNBgFgGgAAADAGBUsXAAAAnwQCAjAEA4cbAAAATQQB8BUAAADiBSIATQYBcw4AAABvBx8AnwYCAjAGBX0cAAAATQYBYBoAAAAwBgUPHQAAAE0GAwkUAAAAMAYFAh4AAABNBgFBGQAAADAGBRcfAAAATQYBESMAAABNBwFBGQAAAJ8GAgIwBgUqIAAAAE0GAREjAAAATQcDhxsAAACfBgICMAYFfRMAAABNBgERIwAAAE0HAUokAAAAnwYCAjAGBS8hAAAATQYBESMAAABNBwFgGgAAAJ8GAgIwBgVLFwAAAJ8EAgIwBAO/JQAAAE0EAfAVAAAA4gUnAE0GAXMOAAAAbwcoAJ8GAgIwBgV9HAAAAE0GAWAaAAAAMAYFDx0AAABNBgMJFAAAADAGBQIeAAAATQYBQRkAAAAwBgWpJgAAAE0GAUEZAAAAMAYFfBYAAABNBgFgGgAAADAGBUsXAAAAnwQCAjAEA3kpAAAATQQBmA0AAABNBQO/JQAAAE0GA3kpAAAAnwQDAjAEA6EqAAAATQQBHSsAAABNBQOhKgAAAJ8EAgIwBAPGLAAAAE0EAvYtAAAAMAQD9i0AAACCAwIALgMBBAAAAEADAgMDAwQEAABAQAMFAwYDBwMIAwkDCgMLAwwDDQMOAw8DEAMRAxIDEwMUAxUDFgUCFhcDFwMYAxkDGgMbAxwDHQMeAx8FCBwdHh8gEyEXAyADIQMiAyMFBhwdHiYWFwMkAyUDJgMnAygDKQABAAEYAAMAAAAAAAMAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAMAAgABAAAAAQAAAAEAAAABAAAAAQAAAPsAAAgAAAEAAAABAAAA/gAABQAAAQAAAAAAAQAAAAEAAAABAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAPgAAAsAAAEAAAAAAAEAAAABAAAAAQAAAAEAAAABAAAA+gAACQAAAAAAAAAAAQAAAAAAAAEAAAACAQAAAAAAsiCuOSBxdQTWE0Ce07NUSMI4uU2A5MQ4

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local SchemaFields = require(ReplicatedStorage.Library.Modules.DefaultStats.Types.SchemaFields)
local t1 = {
	TreadmillMediaBucketType = t.union(t.literal("Brainrot"), t.literal("Funny"), t.literal("Satisfying"), t.literal("WeirdOrHorror"), t.literal("Music")),
	VideoBackgroundMusic = t.strictInterface({
		SoundId = t.string,
		Volume = t.number
	})
}

t1.VideoMediaEntry = t.strictInterface({
	Kind = t.literal("Video"),
	ReleaseVersion = t.number,
	BucketType = t1.TreadmillMediaBucketType,
	Video = t.string,
	CoverImage = t.optional(t.string),
	Music = t.optional(t1.VideoBackgroundMusic),
	Size = t.optional(t.UDim2),
	Volume = t.optional(t.number)
})
t1.MusicImageMediaEntry = t.strictInterface({
	Kind = t.literal("MusicImage"),
	ReleaseVersion = t.number,
	BucketType = t1.TreadmillMediaBucketType,
	Image = t.string,
	SoundId = t.string,
	Volume = t.number
})
t1.TreadmillMediaEntry = t.union(t1.VideoMediaEntry, t1.MusicImageMediaEntry)
t1.TreadmillMediaEntries = t.array(t1.TreadmillMediaEntry)
t1.TreadmillMediaFeedState = SchemaFields.TreadmillMediaFeedState

return t1

