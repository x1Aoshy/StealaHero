-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhB1ZlY3RvcjIDbmV3Bk9mZnNldAVUd2VlbgRRdWFkBUluT3V0C3BsYXlTaGltbWVyBlBhcmVudAdFbmFibGVkBHRhc2sEd2FpdAdEZXN0cm95CVNjcmVlbkd1aRhGaW5kRmlyc3RBbmNlc3Rvck9mQ2xhc3MMQmlsbGJvYXJkR3VpClN1cmZhY2VHdWkGYXNzZXJ0AlVJCUZSQU1FV09SSwVHVUlGWAdTaGltbWVyBUNsb25lClVJR3JhZGllbnQORmluZEZpcnN0Q2hpbGQFc3Bhd24EZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB0xpYnJhcnkMV2FpdEZvckNoaWxkBkFzc2V0cwdyZXF1aXJlCUZ1bmN0aW9ucwAGAAAAAAAAAYIAAQAAAA0AARgADQAAAAAHAAMAAAAd+wAAAKQBAgAABACAjAL//4wDAACfAQMCMAEAcAMAAAD7AAEATQAA4AQAAAD7AQAA4gIFAKQDAgAABACAjAQBAIwFAACfAwMCMAMCcAMAAAD/AwAAAwAAAPsEAgBvBQYAbwYHAMUDBAQBAAAAnwAEAYIAAQAIAwEDAgQABACAAwMDBAUBAwMFAwYAEwcBGAAAAAAAAAAAAQAAAAABAAAAAAAAAQAAAAAAAP4DFAAAAAACAAYAAAAZ+wAAAA4AAwD7AAEAnwABAYIAAQD7AAIAKwARAPsAAwAOAA8A+wADAE0AACQAAAAADgALAPsABABNAADwAQAAAA4AAgD7AAEAnwABAaQABAAADCCA+wEFAJ8AAgFIAO3/ggABAAUDCAMJAwoDCwQADCCAABoAARgAAAEAAAIAAAAAAAAAAQAAAAEAAgAAAPwHGwAAAAACAAIAAAAJ+wAAAA4ABAD7AAAAvAAAUAAAAACfAAIBqQABAN4AAQCCAAEAAQMMACYAARgAAAEAAAACAAEnAAAAAA0EAgAAAD6QBAEAkAUCAW8IAgC8BgBJAwAAAJ8GAwIrBgkAbwgEALwGAEkDAAAAnwYDAisGBABvCAUAvAYASQMAAACfBgMCKwYCAMAHBgCCBwIAuwEGA1IIBgCkBwgAAABwQJ8HAgH7BwAATQcHXAkAAABNBwfPCgAAAE0HB4ELAAAATQcH+wwAAAC8Bwc6DQAAAJ8HAgJvCg4AvAgHAw8AAACfCAMCMAAHJBAAAADZCQEAEgAIABICAQASAAUAqQoAAKQLEwAASBCB2QwCABIAAwASAAkAEgEK/xIAAAASAAYAEgAEAJ8LAgHZCwMAEgAHABIBCv/BCgAAggsCABQCAAAAAAAA/D8CAAAAAAAA8D8DDQMOAw8DEAYAAxEEAABwQAMSAxMDFAMVAxYDFwMYAwgDCgMZBABIEIEEAAECAwYAARgAAQEAAAAAAQAAAAABAAAAAQEAAgAAAAABAAAAAAAAAAAAAAABAAAAAQABAAAABgEAAAAAAAAAAAAMAAAAAAcAAAAABQAAAQIAGKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwJvAwQAvAEA0wUAAACfAQMCbwQGALwCANMFAAAAnwIDAqQDCAAAAHBATQQBUwkAAACfAwICwAQKABIAAgASAAMAggQCAAsDGgQAAABAAxsDHAMdAx4DHwMgBAAAcEADIQYEAQQBAAEYAAAAAAAAAAEAAAABAAAAAQAAAAACAAAAAQAAAAAFnJ4Ml10V5npVEUFFTKjDWOyGG+OuWmaW

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Functions = require(Library.Functions)

return function(p1, p2, p3, p4) -- line: 6
	-- upvalues: Assets (copy), Functions (copy)
	local v9 = p2 or 1.75
	local v10 = p3 or 1.0
	local v11 = p1:FindFirstAncestorOfClass("ScreenGui") or (p1:FindFirstAncestorOfClass("BillboardGui") or p1:FindFirstAncestorOfClass("SurfaceGui"))

	if not v11 then
		return function() -- line: 13
		end
	end

	assert(v11)

	local clone = Assets.UI.FRAMEWORK.GUIFX.Shimmer:Clone()
	local UIGradient = clone:FindFirstChild("UIGradient")

	clone.Parent = p1

	local function playShimmer() -- line: 19
		-- upvalues: UIGradient (copy), Functions (copy), v10 (copy)
		UIGradient.Offset = Vector2.new(-1.0, 0.0)
		Functions.Tween(UIGradient, {
			Offset = Vector2.new(1.0, 0.0)
		}, {
			v10,
			"Quad",
			"InOut"
		})
	end

	local u15 = false

	task.spawn(function() -- line: 26
		-- upvalues: p4 (copy), playShimmer (copy), u15 (ref), p1 (copy), v11 (copy), v9 (copy)
		if p4 then
			playShimmer()

			return
		end

		while not u15 and p1 and p1.Parent do
			if v11.Enabled then
				playShimmer()
			end

			task.wait(v9)
		end
	end)

	return function() -- line: 38
		-- upvalues: clone (copy), u15 (ref)
		if clone then
			clone:Destroy()
		end

		u15 = true
	end
end

