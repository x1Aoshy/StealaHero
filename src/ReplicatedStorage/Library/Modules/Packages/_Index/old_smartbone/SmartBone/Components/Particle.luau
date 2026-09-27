-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdBEJvbmUKUmVzdExlbmd0aAZXZWlnaHQLUGFyZW50SW5kZXgJVHJhbnNmb3JtDkxvY2FsVHJhbnNmb3JtDVJvb3RUcmFuc2Zvcm0GUmFkaXVzC0lzQ29sbGlkaW5nD1RyYW5zZm9ybU9mZnNldBNMYXN0VHJhbnNmb3JtT2Zmc2V0FExvY2FsVHJhbnNmb3JtT2Zmc2V0DFJlc3RQb3NpdGlvbg1Cb25lVHJhbnNmb3JtFUNhbGN1bGF0ZWRXb3JsZENGcmFtZRdDYWxjdWxhdGVkV29ybGRQb3NpdGlvbghQb3NpdGlvbgxMYXN0UG9zaXRpb24IQW5jaG9yZWQMUmVjeWNsaW5nQmluC1dvcmxkQ0ZyYW1lDVRvT2JqZWN0U3BhY2UHSW52ZXJzZQZDRnJhbWUIaWRlbnRpdHkNV29ybGRQb3NpdGlvbgxzZXRtZXRhdGFibGUDbmV3B19faW5kZXgAAgkEAQAACQYAAAUEBwcHD1biBRgAMAAFSwAAAABNBgDrGQAAAE0IAesZAAAAvAYGRhoAAACfBgMCvAYG2hsAAACfBgICMAYFIQYAAABNBgCFHAAAAE0IAYUcAAAAvAYGRhoAAACfBgMCvAYG2hsAAACfBgICMAYFTAcAAABNBgHrGQAAAE0IAoUcAAAAvAYGRhoAAACfBgMCvAYG2hsAAACfBgICMAYF/ggAAABNBgNxCQAAADAGBXEJAAAApAYeAAB0wIEwBgWmDAAAAKQGHgAAdMCBMAYFiA0AAACkBh4AAHTAgTAGBY0OAAAApAYeAAB0wIEwBgViEQAAAE0GAOsZAAAAMAYFJxIAAABNBgDgHwAAADAGBSkTAAAATQYA4B8AAAAwBgU7FAAAAE0GAOAfAAAAMAYFSRUAAAD/BgAAAAAAADAGBX0XAAAA+wYAAJ49BQMGAAAApAQhAAAAAEKfBAMCggQCACIDAQMCAgAAAAAAAAAAAwMCZmZmZmZm5j8DBAMFAwYDBwMIAwkBAAMKAwsDDAMNBwAAAAAAAAAAAAAAAAAAAAADDgMPAxADEQMSAxMDFAgUAP////8BAgAAAAMEAAAABQIAAAAG/////wf/////CP////8J/////woLAAAADP////8N/////w7/////DxAAAAAR/////xL/////E/////8U/////xX/////FgsAAAAX/////wMVAxYDFwMYAxkEAHTAgQMaAxsEAAAAQgAEHAEYAAEABAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAMAAAABAAAAAQAAAAIAAAABAAAAAQAAAAIAAAABAAAAAgAAAAEAAOkAAAAFAAAAAAIAAAECAAqjAAAA/wACAAAAAAAwAABuAAAAAMABAQASAAAAMAEA7wIAAACCAAIAAwMdBgADHAEAAQABGAAAAAEAAgAAABsBAAAAAAEOx0TSdFMjcyjsTQdub+luft9TpjwDLtM=

-- decompilation:
local t1 = {}

t1.__index = t1

function t1.new(p1, p2, p3, p4) -- line: 4
	-- upvalues: t1 (copy)
	return (setmetatable({
		RestLength = 0.0,
		Weight = 0.7,
		ParentIndex = 0.0,
		IsColliding = false,
		RestPosition = Vector3.new(0.0, 0.0, 0.0),
		Anchored = false,
		Bone = p1,
		Transform = p1.WorldCFrame:ToObjectSpace(p2.WorldCFrame):Inverse(),
		LocalTransform = p1.CFrame:ToObjectSpace(p2.CFrame):Inverse(),
		RootTransform = p2.WorldCFrame:ToObjectSpace(p3.CFrame):Inverse(),
		Radius = p4.Radius,
		TransformOffset = CFrame.identity,
		LastTransformOffset = CFrame.identity,
		LocalTransformOffset = CFrame.identity,
		BoneTransform = CFrame.identity,
		CalculatedWorldCFrame = p1.WorldCFrame,
		CalculatedWorldPosition = p1.WorldPosition,
		Position = p1.WorldPosition,
		LastPosition = p1.WorldPosition,
		RecyclingBin = {}
	}, t1))
end

return t1

