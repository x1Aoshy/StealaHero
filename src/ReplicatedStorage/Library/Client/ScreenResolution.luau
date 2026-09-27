-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaD0dldFZpZXdwb3J0U2l6ZQhHZXRTY2FsZQxWaWV3cG9ydFNpemUHQ2hhbmdlZAlGaXJlQXN5bmMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB0xpYnJhcnkMV2FpdEZvckNoaWxkB01vZHVsZXMJRnVuY3Rpb25zB3JlcXVpcmUFRXZlbnQPUmVzb2x1dGlvblNjYWxlEEJpbmRUb1JlbmRlclN0ZXAJd29ya3NwYWNlDUN1cnJlbnRDYW1lcmEDbmV3GEdldFByb3BlcnR5Q2hhbmdlZFNpZ25hbAdDb25uZWN0EFNjcmVlblJlc29sdXRpb24ERW51bQ5SZW5kZXJQcmlvcml0eQVGaXJzdAVWYWx1ZQAFAQABAAAAAvsAAACCAAIAAAAUAQEYAAAWAAAAAAEAAQAAAAL7AAAAggACAAAAGQIBGAAAGwAAAAACAAUAAAAL+wABAE0AALAAAAAA3gAAAPsAAwD7AQAAnwACAt4AAgBvAAEA3gAEAIIAAQACAwMCMzMzMzMzwz8AHgABGAAAAAABAAAAAQABHwAAAAAGAQYAAAAX+wEAAPsCAQDxAhMAAQAAAPsCAgCMAwAAfQIMAAMAAADeAQEA+wIEAN4CAwD7AgUATQIChQAAAABSBAEA+wUEALwCAt0BAAAAnwIEAfsDAgAmAgMA3gICAIIAAQACAwQDBQAkAAEYAAEAAAEAAAABAQABAAAAAAAAAAIAAAIlAAAAABIAAAECAF6jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCbwMEALwBANMFAAAAnwEDAm8EBgC8AgHTBQAAAJ8CAwJvBQcAvAMB0wUAAACfAwMCpAQJAAAAgEBNBQI2CgAAAJ8EAgKkBQkAAACAQE0GA50LAAAAnwUCAqQGCQAAAIBATQcAagQAAABNBwdTBwAAAE0HB28MAAAAnwYCAqQHDgAAANBATQcHSA8AAABNCAewEAAAAFIJBQBSCggAnwkCAlIKCABSCwkAjAwAAP8NAwAAAAAATQ4E7xEAAACfDgECMA4NhRIAAADZDgAAEgEK/zAODWMTAAAA2Q4BABIBC/8wDg3lFAAAAG8QEAC8DgeUFQAAAJ8OAwLZEAIAEgEI/xIABwASAQn/EgAFABIBDP+8Dg7HFgAAAJ8OAwFSDgYAbw8XAKQQGwAaZIDBTRAQ7BwAAADZEQMAEgEI/xIBCv8SAQz/EgEL/xIBCf8SAA0Anw4EAcEIAACCDQIAHQMGBAAAAEADBwMIAwkDCgMLAwwDDQQAAIBAAw4DDwMQAxEEAADQQAMSAwMDEwMEAwEDAgMUAxUDFgMXAxgDGQQaZIDBAxoEAAECAwEAARgAAAAAAAAAAQAAAAEAAAABAAAAAgAAAAABAAAAAAEAAAAAAAAAAAIAAAABAAEAAAEBAQIAAQAAAAACAAAABQAAAAUAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAwAAQAAAAAE3FvZ8SAJD7YEGRxO9LzgQ6xDzoXun7Pw

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local Modules = Library:WaitForChild("Modules")
local Functions = Library:WaitForChild("Functions")
local Event = require(Modules.Event)
local ResolutionScale = require(Functions.ResolutionScale)
local BindToRenderStep = require(ReplicatedStorage.Library.Functions.BindToRenderStep)
local CurrentCamera = workspace.CurrentCamera
local ViewportSize = CurrentCamera.ViewportSize
local u10 = ResolutionScale(ViewportSize)
local u11 = ViewportSize
local u12 = u10
local n1 = 0.0
local t1 = {
	Changed = Event.new(),
	GetViewportSize = function() -- line: 20
		-- upvalues: u11 (ref)
		return u11
	end,
	GetScale = function() -- line: 25
		-- upvalues: u12 (ref)
		return u12
	end
}

CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() -- line: 30
	-- upvalues: ViewportSize (ref), CurrentCamera (copy), u10 (ref), ResolutionScale (copy), n1 (ref)
	ViewportSize = CurrentCamera.ViewportSize
	u10 = ResolutionScale(ViewportSize)
	n1 = 0.15
end)
BindToRenderStep("ScreenResolution", Enum.RenderPriority.First.Value, function(p1) -- line: 36
	-- upvalues: ViewportSize (ref), u11 (ref), n1 (ref), u12 (ref), u10 (ref), t1 (copy)
	local v16 = ViewportSize

	if v16 ~= u11 then
		if n1 <= 0.0 then
			u11 = v16
			u12 = u10
			t1.Changed:FireAsync(v16, u10)
		end

		n1 -= p1
	end
end)

return t1

