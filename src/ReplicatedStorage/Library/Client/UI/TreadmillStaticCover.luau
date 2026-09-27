-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMfBUNsb25lBE5hbWUHQWRvcm5lZQdFbmFibGVkBlBhcmVudAZDcmVhdGUKU2V0RW5hYmxlZApWaWRlb0ZyYW1lBUltYWdlEVJlc29sdmVDb3ZlckltYWdlCFN0b3BQbGF5E0dldFN0b3BwZWRJY29uSW1hZ2UHVmlzaWJsZQpBcHBseU1lZGlhFEdldEN1cnJlbnRNZWRpYUVudHJ5CUFwcGx5RmVlZARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5BkNsaWVudANHVUkYVHJlYWRtaWxsVmlkZW9Db250cm9sbGVyBVR5cGVzCUludGVyZmFjZR5TdGF0aWNUcmVhZG1pbGxJbWFnZVN1cmZhY2VHdWkKU3VyZmFjZUd1aQNJc0EvU3RhdGljIHRyZWFkbWlsbCBpbWFnZSBHVUkgbXVzdCBiZSBhIFN1cmZhY2VHdWkGYXNzZXJ0AAUEAgEAAAcEAAAFAgMHEfsCAAC8AgI6AAAAAJ8CAgIwAAK6AQAAADABAhQCAAAAqQMBADADAvADAAAA+wMAAE0DAyQEAAAAMAMCJAQAAACCAgIABQMBAwIDAwMEAwUAFwYBGAAAAAABAAEAAQAAAQAAAAABGAAAAAACAgAAAAcEAAAFAg8BAzABAPAAAAAAggABAAEDBAAgBwEYAAABIQAAAAAFAgEAAAAdTQIAxwAAAABNAgKpAQAAAPsDAABNAwMZAgAAAFIEAQCfAwICMAMCqQEAAABNAgDHAAAAAE0CApIDAAAA+wMAAE0DAzYEAAAAnwMBAjADAqkBAAAATQIAxwAAAABNAgKSAwAAAKkDAQAwAwKABQAAAIIAAQAGAwgDCQMKAwsDDAMNACQOARgAAAAAAAAAAAAAAAEAAAAAAAAAAAABAAAAAAAAASgAAAAABgICAAAAC/sCAABNAgLwAAAAAFIDAAD7BAEATQQE8gEAAABSBQEAnwQCAJ8CAAGCAAEAAgMOAw8ALRABGAAAAAAAAAAAAAABMQAAAAAJAAABAgBGowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgJNBwAAAE0CAjkIAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwNNBwAAAE0DA6kJAAAAnwICAqQDBQAAAEBATQQAagYAAABNBARNBwAAAE0EBKkJAAAATQQE7woAAABNBAQPCwAAAJ8DAgJNBAGBDAAAAJ8EAQJvCA0AvAYE/g4AAACfBgMCgQEGBA8AAABvBw8ApAURAAAAAEGfBQMB/wUDAAAAAADABhIAEgAEADAGBZYTAAAAwAYUADAGBZ4VAAAAwAYWABIAAgAwBgXwFwAAAMAGGAASAAUAEgACADAGBbwZAAAAggUCABoDEQQAAABAAxIDEwMUBAAAQEADFQMWAxcDGAMZAxoDGwMcAx0DHgMfBAAAAEEGAAMGBgEDBwYCAw4GAwMQBAABAgMBAAEYAAMAAAAAAAMAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAEAAABAAAAAAAAAAAAAwAGAAAACQAABAAAAAkAAAAABwEAAAAABG3gwNRe7qcHJtWfsKBjVEkd+NegXySq1Q==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GUI = require(ReplicatedStorage.Library.Client.GUI)
local TreadmillVideoController = require(ReplicatedStorage.Library.Client.TreadmillVideoController)

require(ReplicatedStorage.Library.Client.TreadmillVideoController.Types.Interface)

local v4 = GUI.StaticTreadmillImageSurfaceGui()

assert(v4:IsA("SurfaceGui"), "Static treadmill image GUI must be a SurfaceGui")

local t1 = {
	Create = function(s1: string, p1) -- line: 23
		-- upvalues: v4 (copy)
		local clone = v4:Clone()

		clone.Name = s1
		clone.Adornee = p1
		clone.Enabled = true
		clone.Parent = v4.Parent

		return clone
	end,
	SetEnabled = function(p2, b1: boolean) -- line: 32
		p2.Enabled = b1
	end,
	ApplyMedia = function(p3, p4) -- line: 36
		-- upvalues: TreadmillVideoController (copy)
		p3.VideoFrame.Image.Image = TreadmillVideoController.ResolveCoverImage(p4)
		p3.VideoFrame.StopPlay.Image = TreadmillVideoController.GetStoppedIconImage()
		p3.VideoFrame.StopPlay.Visible = true
	end
}

function t1.ApplyFeed(p5, p6) -- line: 45
	-- upvalues: t1 (copy), TreadmillVideoController (copy)
	t1.ApplyMedia(p5, TreadmillVideoController.GetCurrentMediaEntry(p6))
end

return t1

