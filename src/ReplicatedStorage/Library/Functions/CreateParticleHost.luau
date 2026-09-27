-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMiBmFzc2VydAhvcHRpb25hbAhCYXNlUGFydAhJbnN0YW5jZQNuZXcKQXR0YWNobWVudAZQYXJlbnQGdHlwZW9mBkNGcmFtZQRQYXJ0CEFuY2hvcmVkCkNhbkNvbGxpZGUIQ2FuUXVlcnkIQ2FuVG91Y2gMVHJhbnNwYXJlbmN5CkNhc3RTaGFkb3cEU2l6ZQRob3N0BE5hbWUJd29ya3NwYWNlCF9fREVCUklTDFdhaXRGb3JDaGlsZBJDcmVhdGVQYXJ0aWNsZUhvc3QEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzB01vZHVsZXMIUGFja2FnZXMBdAV1bmlvbgdWZWN0b3IzAQkAAgcCAgAABwQAAAUCD4dN+wMAAFIEAACfAwIATAEAAqQCAQAAAABAnwIAAfsCAQBNAgIRAgAAAE0CAmMDAAAAUgMBAJ8CAgGkAgYAABRAgG8DBwCfAgICDgEDADABAiQIAAAAggEDALssAANSBAAApAMKAAAAkECfAwIC8AMGAAsAAACkAwwAABSwgFIEAACfAwICUgADAKQDBgAAFECAbwQNAJ8DAgKpBAEAMAQDRQ4AAACpBAAAMAQD0w8AAACpBAAAMAQDYhAAAACpBAAAMAQD9hEAAACMBAEAMAQD2RIAAACpBAAAMAQDPhMAAABvBBQAMAQDLxUAAAAwAAOFCwAAAG8EFgAwBAO6FwAAADADAiQIAAAApAQZAAAAgEFvBhoAvAQE0xsAAACfBAMCMAQDJAgAAABSBAMAUgUCAIIEAwAcAwEEAAAAQAMCAwMDBAMFBAAUQIADBgMHAwgEAACQQAMJBAAUsIADCgMLAwwDDQMOAw8DEAcAAAAAAAAAAAAAAAAAAAAAAxEDEgMTAxQEAACAQQMVAxYACBcBGAAAAAAAAAABAAAAAAAAAgAAAAEBAAEDAAAAAAAAAQAAAAADAAAAAQAAAQAAAQAAAQAAAQAAAQAAAQAAAQABAAACAAEAAAAAAAAAAgAACQAAAAAHAAABAgAnowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD6AgAAABNAwPmCQAAAE0DA5UKAAAAnwICAk0DAhELAAAATQQCmAwAAABNBQKFDQAAAE0GAk8OAAAAnwQDAJ8DAALABA8AEgADABIAAQCCBAIAEAMYBAAAAEADGQMaAxsEAABAQAMcAx0DHgMfAyADAgMhAwkDIgYAAQABAAEYAAAAAAAAAAIAAAAAAAABAAAAAAAAAAAAAAIAAAAAAAAAAAACAAAfAQAAAAABHxGIE9FqA5hgcjSRn7yOEm8Jn2ct1eIS

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local v4 = t.optional(t.union(t.CFrame, t.Vector3))

local function CreateParticleHost(p1, p2) -- line: 8
	-- upvalues: v4 (copy), Asserts (copy)
	assert(v4(p1))
	Asserts.optional.BasePart(p2)

	local Attachment = Instance.new("Attachment")

	if p2 then
		Attachment.Parent = p2

		return p2, Attachment
	end

	if typeof(p1) ~= "CFrame" then
		p1 = CFrame.new(p1)
	end

	local Part = Instance.new("Part")

	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false
	Part.Transparency = 1.0
	Part.CastShadow = false
	Part.Size = Vector3.new(0.0, 0.0, 0.0)
	Part.CFrame = p1
	Part.Name = "host"
	Attachment.Parent = Part
	Part.Parent = workspace:WaitForChild("__DEBRIS")

	return Part, Attachment
end

return CreateParticleHost

