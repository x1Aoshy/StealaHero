-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMjB0Rlc3Ryb3kGdHlwZW9mCEluc3RhbmNlBVNvdW5kA0lzQQR3YXJuFlNvdW5kIG5vdCBmb3VuZCBmb3IgJSoGZm9ybWF0DlBsYXlMb2NhbFNvdW5kA25ldwRQYXJ0CkNhbkNvbGxpZGUIQ2FuUXVlcnkIQ2FuVG91Y2gITWFzc2xlc3MIQW5jaG9yZWQJd29ya3NwYWNlBlBhcmVudAxUcmFuc3BhcmVuY3kIUG9zaXRpb24FQ2xvbmUCb3MFY2xvY2sISXNMb2FkZWQEdGFzawR3YWl0BFBsYXkFRW5kZWQET25jZQlQbGF5U291bmQJVXBkYXRlT1NUBVN0YXJ0BGdhbWUMU291bmRTZXJ2aWNlCkdldFNlcnZpY2UABQIAAQAAAAX7AAAAvAAAUAAAAACfAAIBggABAAEDAQAzAAEYAAAAAAE0AAAAAAoDAQAADAUAAQUDDweIAwUTAmPGAwAAuywBA1IFAQCkBAEAAAAAQJ8EAgLwBAcAAgAAgG8GAwC8BAH+BAAAAJ8EAwIOBAEAUgMBACsDCQCkBAYAAABQQG8FBwBSBwEAvAUFjQgAAACfBQMCnwQCAIIEAAArAgYA+wQAAFIGAwC8BAQsCQAAAJ8EAwGCAwIApAQLAAAoIIBvBQwAnwQCAqkFAAAwBQTTDQAAAKkFAAAwBQRiDgAAAKkFAAAwBQT2DwAAAKkFAQAwBQSlEAAAAKkFAQAwBQRFEQAAAKQFEwAAACBBMAUEJBQAAACMBQEAMAUE2RUAAAAwAgQ7FgAAALwFAzoXAAAAnwUCAjAEBSQUAAAApAYaAABkgIGfBgECTQcFVRsAAAArBwsApAgaAABkgIGfCAECJgcIBowIAgBgBwUACAAAAKQHHgAAdMCBnwcBAUgA8v9NBwVVGwAAAA4HBAC8BwXuHwAAAJ8HAgFlAAMAvAcEUCAAAACfBwIBTQcFNyEAAADZCQAAEgAEALwHBz0iAAAAnwcDAYIDAgAjAwIEAAAAQAMDAwQDBQMGBAAAUEADBwMIAwkDCgQAKCCAAwsDDAMNAw4DDwMQAxEEAAAgQQMSAxMDFAMVAxYDFwQAZICBAxgDGQMaBAB0wIEDGwMBAxwDHQEADB4BGAABAAAAAAAAAAAAAAABCgEAAAAAAAAAAAEBAAAAAAECAAAAAQAAAQAAAQAAAQAAAQAAAQAAAAEAAAEAAQAAAQABAAABAAAAAAAAAAAAAQAA/wMAAAEAAAACAAACAAAAAAAAAw0AAAAAAQEAAAAAAYIAAQAAADofARgAOgAAAAAAAAAAAAABggABAAAAOyABGAA7AAAAAAMAAAECABejAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMC/wEDAAAAAADAAgQAEgAAADACAfcFAAAAwAIGADACAZYHAAAAwAIIADACARwJAAAATQIBHAkAAACfAgEBggECAAoDIQQAAABAAyIDIwYBAx4GAgMfBgMDIAMBAgMBAAEYAAAAAAAAAAkAAgAAAC4AAAEAAAIAAAIBAAAAAAQB3iTftWPul2hj82RgVVA4ccYzqzMaTt4=

-- decompilation:
local SoundService = game:GetService("SoundService")
local t1 = {
	PlaySound = function(_, p2, vector3: Vector3?) -- line: 12
		-- upvalues: SoundService (copy)
		local v6 = nil

		if typeof(p2) == "Instance" and p2:IsA("Sound") then
			v6 = p2
		end

		if not v6 then
			return warn(`Sound not found for { p2 }`)
		end

		if not vector3 then
			SoundService:PlayLocalSound(v6)

			return v6
		end

		local Part = Instance.new("Part")

		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.Massless = true
		Part.Anchored = true
		Part.Parent = workspace
		Part.Transparency = 1.0
		Part.Position = vector3

		local clone = v6:Clone()

		clone.Parent = Part

		local elapsed = os.clock()

		while not clone.IsLoaded and os.clock() - elapsed < 2.0 do
			task.wait()
		end

		if clone.IsLoaded then
			clone:Play()
		else
			Part:Destroy()
		end

		clone.Ended:Once(function() -- line: 51
			-- upvalues: Part (copy)
			Part:Destroy()
		end)

		return v6
	end,
	UpdateOST = function(_) -- line: 58
	end,
	Start = function() -- line: 59
	end
}

t1.Start()

return t1

