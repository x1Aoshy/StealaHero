-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJCXdvcmtzcGFjZQ1DdXJyZW50Q2FtZXJhEldvcmxkVG9TY3JlZW5Qb2ludAVVRGltMgpmcm9tT2Zmc2V0AVgBWRhHZXRQcm9wZXJ0eUNoYW5nZWRTaWduYWwHQ29ubmVjdAADAQABAAAABqQAAQAAAABATQAASAIAAADeAAAAggABAAMDAQQAAABAAwIAAgABGAAAAAAAAQMAAAAABgEBAAAAECsAAQCCAAEA+wEAAFIDAAC8AQGxAAAAAJ8BAwOkAwMAAAgQgE0EAXkEAAAATQUBeAUAAACfAwMCUgQCAIIDAwAGAwMDBAMFBAAIEIADBgMHAAYAARgAAQIAAAAAAQAAAAAAAAAABwAAAAAEAAABAgAUowAAAKQAAQAAAABATQAASAIAAACkAQEAAAAAQG8DAgC8AQGUAwAAAJ8BAwLZAwAAEgEA/7wBAccEAAAAnwEDAdkBAQASAQD/wQAAAIIBAgAFAwEEAAAAQAMCAwgDCQIAAQEAARgAAAAAAAEAAAAAAAAAAAAABAAAAAEAAAAAAusW5UAcwRsqC3DBQQGmOzabDvI02dKPQQ==

-- decompilation:
local CurrentCamera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() -- line: 2
	-- upvalues: CurrentCamera (ref)
	CurrentCamera = workspace.CurrentCamera
end)

return function(p1) -- line: 6
	-- upvalues: CurrentCamera (ref)
	if not p1 then
		return
	end

	local v3, v4 = CurrentCamera:WorldToScreenPoint(p1)

	return UDim2.fromOffset(v3.X, v3.Y), v4
end

