-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMdBkNhbmNlbAtJbWFnZUNvbG9yMwVTY2FsZQ1CdXR0b25GWE93bmVkDEdldEF0dHJpYnV0ZQdEZXN0cm95B0F0VHJhY2UZQ2xlYXJlZCBpbWFnZS1jb2xvciBwdWxzZQNMb2cJR3VpQnV0dG9uBkNvbG9yMwlUd2VlbkluZm8GQ3JlYXRlCEluc3RhbmNlA25ldwdVSVNjYWxlBlBhcmVudARQbGF5GVN0YXJ0ZWQgaW1hZ2UtY29sb3IgcHVsc2UFU3RhcnQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlDFR3ZWVuU2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwdNb2R1bGVzCFBhY2thZ2VzAQsAAwMABwAAACj7AAAADgABAIIAAQCpAAEA3gAAAPsAAQC8AAChAAAAAJ8AAgH7AAIA+wEDADABAAABAAAA+wAEALwAAKEAAAAAnwACAfsABQCMAQEAMAEAhAIAAAD7AAUAbwIDALwAABIEAAAAnwADAisABAD7AAUAvAAAUAUAAACfAAIB+wAGALwAAKoGAAAAnwACAm8CBwC8AAChCAAAAJ8AAwGCAAEACQMBAwIDAwMEAwUDBgMHAwgDCQArAAEYAAABAgABAAAAAQAAAAEAAAABAAAAAQAAAAAAAQAAAAMAAAAAAAAAASwAAAAADAMDAAAIBQAABQMHQAdD+wMAAE0DA3IAAAAAUgQAAJ8DAgH7AwAATQMDmgEAAABSBAEAnwMCAfsDAABNAwNMAgAAAFIEAgCfAwIBTQMAAAMAAAD7BAEAUgYAAFIHAgDiCAQAMAEIAAMAAAC8BASWBQAAAJ8EBQKpBQAApAYIAAAcYIBvBwkAnwYCAjAABiQKAAAAbwcLADAHBoQMAAAA+wcBAFIJBgBSCgIA4gsOALwHB5YFAAAAnwcFArwIB+4PAAAAnwgCAbwIBO4PAAAAnwgCAfsIAgC8CAiqEAAAAJ8IAgJvChEAvAgIoRIAAACfCAMB2QgAABIBBf8SAAQAEgAAABIAAwASAAcAEgAGABICAgDBBQAAgggCABMDCgMLAwwDAgUBAwMNAw4DDwQAHGCAAxADEQLNzMzMzMzsPwMDAmZmZmZmZvI/CAEMDQAAAAMSAwcDEwMJAQAVFAEYAAAAAAABAAAAAAEAAAAAAgABAAAAAQD/AAADAgAAAAEAAQAAAQAAAAAAAAQAAAEAAAEAAAAAAAAAAgAAAAAAAAAAABYAAAAABwAAAQIAK6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAGoHAAAATQMDiQgAAACfAgICpAMGAAAAUEBNBABqBwAAAE0EBOgJAAAATQQE5goAAABNBAShCwAAAJ8DAgJNBAPvDAAAAJ8EAQL/BQEAAAAAAMAGDQASAAIAEgABABIABAAwBgUcDgAAAIIFAgAPAxUEAAAAQAMWAxcDGAMZBAAAUEADGgMbAxwDHQMJAw8GAQMUAQEBAAEYAAMAAAAAAAEAAAAAAAMAAAAAAAABAAAAAAAAAAAAAAMAAAMABgAAAAAAJwEAAAAAAhOxmogE4VRsEXgKRV714XJjqY38IXXwiQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local v4 = require(ReplicatedStorage.Library.Modules.Packages.Log).new()

return {
	Start = function(p1, color3: Color3, p2) -- line: 21
		-- upvalues: Asserts (copy), TweenService (copy), v4 (copy)
		Asserts.GuiButton(p1)
		Asserts.Color3(color3)
		Asserts.TweenInfo(p2)

		local p1ImageColor3 = p1.ImageColor3
		local tween = TweenService:Create(p1, p2, {
			ImageColor3 = color3
		})
		local u10 = false
		local UIScale = Instance.new("UIScale")

		UIScale.Parent = p1
		UIScale.Scale = 0.9

		local tween2 = TweenService:Create(UIScale, p2, {
			Scale = 1.15
		})

		tween2:Play()
		tween:Play()
		v4:AtTrace():Log("Started image-color pulse")

		return function() -- line: 43
			-- upvalues: u10 (ref), tween (copy), p1 (copy), p1ImageColor3 (copy), tween2 (copy), UIScale (copy), v4 (copy)
			if u10 then
				return
			end

			u10 = true
			tween:Cancel()
			p1.ImageColor3 = p1ImageColor3
			tween2:Cancel()
			UIScale.Scale = 1.0

			if not UIScale:GetAttribute("ButtonFXOwned") then
				UIScale:Destroy()
			end

			v4:AtTrace():Log("Cleared image-color pulse")
		end
	end
}

