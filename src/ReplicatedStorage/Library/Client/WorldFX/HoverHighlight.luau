-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMoBU1vZGVsBnN0cmluZwhvcHRpb25hbAZudW1iZXIISW5zdGFuY2UDbmV3CUhpZ2hsaWdodAROYW1lB0Fkb3JuZWUERW51bRJIaWdobGlnaHREZXB0aE1vZGUIT2NjbHVkZWQJRGVwdGhNb2RlBkNvbG9yMwlGaWxsQ29sb3IQRmlsbFRyYW5zcGFyZW5jeQxPdXRsaW5lQ29sb3ITT3V0bGluZVRyYW5zcGFyZW5jeQZQYXJlbnQLRWFzaW5nU3R5bGUEUXVhZA9FYXNpbmdEaXJlY3Rpb24DT3V0BkZhZGVJbg1QbGF5YmFja1N0YXRlCUNvbXBsZXRlZAdEZXN0cm95A0lzQRJFeHBlY3RlZCBIaWdobGlnaHQGYXNzZXJ0BE9uY2UHRmFkZU91dARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMJRnVuY3Rpb25zBVR3ZWVuAAQLAwIAAAgFAAAFAwcDgkP7AwAATQMDOwAAAABSBAAAnwMCAfsDAABNAwNBAQAAAFIEAQCfAwIB+wMAAE0DAxECAAAATQMDYAMAAABSBAIAnwMCAaQDBgAAFECAbwQHAJ8DAgIwAQO6CAAAADAAAxQJAAAApAQNAAwsoMAwBAMzDgAAAKQEEAAAFPCAjAUBAIwGAQCMBwEAnwQEAjAEA4ARAAAAjAQBADAEAxYSAAAApAQQAAAU8ICMBQEAjAYBAIwHAQCfBAQCMAQD3BMAAACMBAEAMAQDohQAAAAwAAMkFQAAAPsEAQBSBQMA4gYXAP8HAAADAAAAkAgCGKQJGwAaZKDApAoeAB1woMDFBwgEAQAAAJ8EBAGCAwIAHwMBAwIDAwMEAwUDBgQAFECAAwcDCAMJAwoDCwMMBAwsoMADDQMOBAAU8IADDwMQAxEDEgMTAgAAAAAAAAAACAEUFgAAAAKamZmZmZnJPwMUAxUEGmSgwAMWAxcEHXCgwAAUGAEYAAAAAAABAAAAAAEAAAAAAAACAAAAAQABAAEAAAABAAAAAAAAAAEAAAEAAAAAAAAAAQAAAQACAQEBAAAAAAAAAAD9BhUAAAAAAwEBAAAACaQBAwACBADAmgAFAAEAAAD7AQAAvAEBUAQAAACfAQIBggABAAUDCgMZAxoEAgQAwAMbADQAARgAAAAAAQAAAAI1AAAAAAkCAgAABwQAAAUCB4ImbwUAALwDAP4BAAAAnwMDAoEBAwQCAAAAbwQCAKQCBAAAADBAnwIDAfsCAABNAgIRBQAAAE0CAmAGAAAAUgMBAJ8CAgH7AgEAUgMAAOIECQD/BQAAAwAAAJAGAQqkBw4ADTCwwKQIEQAQPLDAxQUGBAEAAACfAgQCTQICGBIAAADZBAAAEgAAALwCAj0TAAAAnwIDAYIAAQAUAwcDHAMdAx4EAAAwQAMDAwQDEgIAAAAAAADwPwgBBwgAAAACmpmZmZmZyT8DCgMUAxUEDTCwwAMWAxcEEDywwAMaAx8BASwgARgAAAAAAAAAAAAAAQAAAAAAAAIBAQEAAAAAAAAAAP0EAAAAAAAABS0AAAAABQAAAQIAJKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA1MIAAAATQMD4AkAAACfAgIC/wMCAAAAAADABAoAEgABABIAAgAwBAOeCwAAAMAEDAASAAEAEgACADAEA6ENAAAAggMCAA4DIQQAAABAAyIDIwMkBAAAQEADJQMmAycDKAYAAxgGAgMgAgACAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAABgAGAAAAABgAAAAADwEAAAAAA/Wz1vKwvB59dCg7lhiGBliFq8GGx3e88w==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local Tween = require(ReplicatedStorage.Library.Functions.Tween)

return {
	FadeIn = function(p1, s1: string, n1: number?) -- line: 20
		-- upvalues: Asserts (copy), Tween (copy)
		Asserts.Model(p1)
		Asserts.string(s1)
		Asserts.optional.number(n1)

		local Highlight = Instance.new("Highlight")

		Highlight.Name = s1
		Highlight.Adornee = p1
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = Color3.new(1.0, 1.0, 1.0)
		Highlight.FillTransparency = 1.0
		Highlight.OutlineColor = Color3.new(1.0, 1.0, 1.0)
		Highlight.OutlineTransparency = 1.0
		Highlight.Parent = p1
		Tween(Highlight, {
			OutlineTransparency = 0.0
		}, {
			n1 or 0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		})

		return Highlight
	end,
	FadeOut = function(p2, n2: number?) -- line: 44
		-- upvalues: Asserts (copy), Tween (copy)
		assert(p2:IsA("Highlight"), "Expected Highlight")
		Asserts.optional.number(n2)
		Tween(p2, {
			OutlineTransparency = 1.0
		}, {
			n2 or 0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		}).Completed:Once(function(p3) -- line: 52
			-- upvalues: p2 (copy)
			if p3 == Enum.PlaybackState.Completed then
				p2:Destroy()
			end
		end)
	end
}

