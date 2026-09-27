-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMgBUNsb25lBkNGcmFtZQhBbmNob3JlZApDYW5Db2xsaWRlCE1hc3NsZXNzBEVudW0ITWF0ZXJpYWwFR2xhc3MEU2l6ZQxUcmFuc3BhcmVuY3kJd29ya3NwYWNlCF9fREVCUklTBlBhcmVudAdBZGRJdGVtCVR3ZWVuSW5mbwNuZXcLRWFzaW5nU3R5bGUEU2luZQ9FYXNpbmdEaXJlY3Rpb24DT3V0BkNyZWF0ZQRQbGF5DENyZWF0ZUJ1YmJsZQRnYW1lDFR3ZWVuU2VydmljZQpHZXRTZXJ2aWNlBkRlYnJpcxFSZXBsaWNhdGVkU3RvcmFnZQZBc3NldHMGTW9kZWxzB0VmZmVjdHMGQnViYmxlAQIAAg0FAwAACgcAAAUFQAgCCAI8+wUAALwFBToAAAAAnwUCAjAABYUBAAAAqQYBADAGBUUCAAAAqQYAADAGBdMDAAAAqQYBADAGBaUEAAAApAYIAAcYUMAwBgUtBgAAADABBS8JAAAAMAIF2QoAAACkBgwAAACwQE0GBjANAAAAMAYFJA4AAAD7BgEAUggFAFIJBAC8BgZ4DwAAAJ8GBAGkBhIAAEQAgVIHBACkCBUAFExQwKQJGAAXWFDAjAoAAKkLAACMDAAAnwYHAuIHGgAwAwcvCQAAAPsIAgBSCgUAUgsGAFIMBwC8CAiWGwAAAJ8IBQK8CAjuHAAAAJ8IAgGCBQIAHQMBAwIDAwMEAwUDBgMHAwgEBxhQwAMJAwoDCwQAALBAAwwDDQMOAw8DEAQARACBAxEDEgQUTFDAAxMDFAQXWFDAAgAAAAAAAPA/CAIKGQAAAAn/////AxUDFgAKFwEYAAAAAAEAAQAAAQAAAQAAAQAAAAEAAQACAAAAAAABAAAAAAABAAAAAAAAAAAAAAECAAIAAAAAAAAAAAABEQAAAAAGAAABAgAjowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCAQAAAABAbwQFALwCAhYDAAAAnwIDAk0DAoEGAAAATQMD+AcAAABNAwOXCAAAAE0DAycJAAAA4gQLAMAFDAASAAMAEgABABIAAAAwBQT6CgAAAIIEAgANAxgEAAAAQAMZAxoDGwMcAx0DHgMfAyADFwUBCgYAAQABAAEYAAIAAAAAAAEAAAAAAAEAAAAAAAIAAAAAAAAAAgEAAAAAAAABAAAAAAFezbSqmJmP1IdLtjO8ggtkLtWj3mwJ3qs=

-- decompilation:
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Bubble = game:GetService("ReplicatedStorage").Assets.Models.Effects.Bubble

return {
	CreateBubble = function(cFrame: CFrame, vector3: Vector3, n1: number, vector3_2: Vector3, n2: number) -- line: 10
		-- upvalues: Bubble (copy), Debris (copy), TweenService (copy)
		local clone = Bubble:Clone()

		clone.CFrame = cFrame
		clone.Anchored = true
		clone.CanCollide = false
		clone.Massless = true
		clone.Material = Enum.Material.Glass
		clone.Size = vector3
		clone.Transparency = n1
		clone.Parent = workspace.__DEBRIS
		Debris:AddItem(clone, n2)

		local tweenInfo = TweenInfo.new(n2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.0, false, 0.0)
		local t1 = {
			Transparency = 1.0,
			Size = vector3_2
		}

		TweenService:Create(clone, tweenInfo, t1):Play()

		return clone
	end
}

