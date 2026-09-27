-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSDUN1cnJlbnRDYW1lcmEMVmlld3BvcnRTaXplC0ZpZWxkT2ZWaWV3BG1hdGgDcmFkA3RhbgFYAVkSVmlld3BvcnRQb2ludFRvUmF5BkNGcmFtZQZsb29rQXQJRGlyZWN0aW9uBk9yaWdpbgdWZWN0b3IzA25ldwRnYW1lCVdvcmtzcGFjZQpHZXRTZXJ2aWNlAAIOAgEAAAcEAAAFAgICN/sCAABNAgJIAAAAAE0DArABAAAATQcCYQMAAAC7FgcCpAYGAAAUQICfBgICWwUGArsbBQKkBAgAABxAgJ8EAgJNBwN5CQAAAAkGBAdNBwN4CgAAAOwFBgdbBwALCQYHBVsIAAsJBwgETQsDeQkAAABbCgsCTQwDeAoAAABbCwwCWw0BAiYMAA28CAJGDAAAAJ8IBQKkCg8AADjQgG8LEABNDAhhEQAAAJ8KAwJNCwhDEgAAAEMJCgs0NgYGBwEAAFILBgBSDAcAUg0BAKQKFQAAUDCBnwoEAoIJAwAWAwEDAgIAAAAAAADgPwMDAwQDBQQAFECAAwYEABxAgAMHAwgCAAAAAAAAAEADCQMKAwsEADjQgAcAAAAAAAAAAAAAAAAAAAAAAwwDDQMOAw8EAFAwgQADAAEYAAAAAQABAAAAAAAAAAAAAAEAAAAAAAEAAQABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAwAAAQIACqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLAAQQAEgAAAIIBAgAFAxAEAAAAQAMRAxIGAAEAAQABGAAAAAAAAAACAAABAAAAAAEwHeGpn4zCELCLzUMT3DfFQAX23QLZi6g=

-- decompilation:
local Workspace = game:GetService("Workspace")

return function(n1: number, n2: number) -- line: 3
	-- upvalues: Workspace (copy)
	local CurrentCamera = Workspace.CurrentCamera
	local ViewportSize = CurrentCamera.ViewportSize
	local v6 = math.tan(math.rad(CurrentCamera.FieldOfView) * 0.5)
	local v7 = v6 * ViewportSize.X / ViewportSize.Y
	local v8 = n1 * 2.0 * v7
	local v9 = n1 * 2.0 * v6
	local v10 = CurrentCamera:ViewportPointToRay(ViewportSize.X * 0.5, ViewportSize.Y * 0.5, n1 - n2 * 0.5)

	return CFrame.lookAt(Vector3.new(0.0, 0.0, 0.0), v10.Direction) + v10.Origin, (Vector3.new(v8, v9, n2))
end

