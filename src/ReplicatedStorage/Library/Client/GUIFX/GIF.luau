-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVEENsZWFudXBBbmltYXRpb24EdGljawRtYXRoBWZsb29yBVVEaW0yA25ldwhQb3NpdGlvbgZQYXJlbnQEU2l6ZQFYBVNjYWxlAVkPQW5jZXN0cnlDaGFuZ2VkB0Nvbm5lY3QHcmVxdWlyZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlB0xpYnJhcnkJRnVuY3Rpb25zC0dlbmVyYXRlVUlEEEJpbmRUb1JlbmRlclN0ZXABBQAFAQACAAAADPsAAAAOAAEAggABAKkAAQDeAAAA+wABAA4ABAD7AAEAnwABAcYAAADeAAEAggABAAAAIgEBGAAAAAIAAgABAAEAAiMAAAAACgAIAAAAL6QAAQAAAABAnwABAvsCAAAmAQAC+wIBAGACJwABAAAA+wICAPsDAwBgAgQAAwAAAPsCAgCVAQICZQABAIwBAQDeAQIA3gAAAPsFAgB4BAUC+wUEAOwDBAW7DAMCpAIFAAAQMICfAgIC+wMFAAkBAgP7BQIAeAQFAvsFBADPAwQF+wQFAAkCAwT7AwYApAUIAAAcYIA5BgIAjAcAADkIAQCMCQAAnwUFAvsGBwBDBAUGMAQDOwkAAACCAAEACgMCBAAAAEACAAAAAAAA8D8DAwMEBAAQMIADBQMGBAAcYIADBwAtAAEYAAAAAgAAAAABAAAAAAAAAAABAgAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAAAAAIuAAAAAAEAAwAAABD7AAAATQAAJAAAAAArAAsA+wABAA4AAQCCAAEAqQABAN4AAQD7AAIADgAEAPsAAgCfAAEBxgAAAN4AAgCCAAEAAQMIADoAARgYAAAA6AAAAgACAAEAAQATIwAAAAAWBQIAAAoHAAAFBQeCgsCCPJAFAQBSBgMAKwYDAKQGAwAACBCAnwYBApAHBABNCAAvBAAAAE0ICHkFAAAATQgIhAYAAABNCQAvBAAAAE0JCXgHAAAATQkJhAYAAAAJCwgJ7AoFC/sLAACfCwECqQwAAKQNCQAAAIBAnw0BAowOAQAJDwgJDgIBACYPDwLGEAAA2REAABIBDP8SARD/+xIBAFITCwCMFAEA2RUBABIBDf8SAAoAEgEO/xIBD/8SAAgAEgAHABIAAAASAAYAnxIEAlIQEgBNEgCLCgAAANkUAgASAAAAEgEM/xIBEP+8EhLHCwAAAJ8SAwHBDAAAghECAAwCAAAAAAAA8D8DBQMGBAAIEIADCQMKAwsDDAMCBAAAgEADDQMOAwABAgkAARgAAQAAAAABAQAAAAAAAQAAAAAAAQABAAEBAAABAQIBAwIAAAsAAAAAAAAAAAAAAAAADQAAAAAAAAAABAAQAAAAAAMAAAECAB+jAAAApAABAAAAAECkAQMAAAAgQE0BAT8EAAAATQEBagUAAABNAQFTBgAAAE0BAeAHAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgI/BAAAAE0CAmoFAAAATQICUwYAAABNAgJvCAAAAJ8BAgLAAgkAEgAAABIAAQCCAgIACgMPBAAAAEADEAQAACBAAxEDEgMTAxQDFQYDAQMBAAEYAAMAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAABAAAAAEAAAAABI3T3nR1Wtqer8vKqnrxn3n9y8kAvxe0dQ==

-- decompilation:
local GenerateUID = require(game.ReplicatedStorage.Library.Functions.GenerateUID)
local BindToRenderStep = require(game.ReplicatedStorage.Library.Functions.BindToRenderStep)

return function(p1, n1: number?, n2: number?, uDim2: UDim2?, n3: number?) -- line: 9
	-- upvalues: GenerateUID (copy), BindToRenderStep (copy)
	local v8 = n1 or 1.0
	local v9 = uDim2 or UDim2.new()
	local v10 = n3 or 1.0
	local XScale = p1.Size.X.Scale
	local YScale = p1.Size.Y.Scale
	local v13 = v8 / (XScale * YScale)
	local v14 = GenerateUID()
	local u15 = false
	local timestamp = tick()
	local n4 = 1.0
	local u18 = XScale * YScale

	if n2 then
		u18 -= n2
	end

	local u19 = nil

	local function CleanupAnimation() -- line: 34
		-- upvalues: u15 (ref), u19 (ref)
		if u15 then
			return
		end

		u15 = true

		if u19 then
			u19()
			u19 = nil
		end
	end

	u19 = BindToRenderStep(v14, 1.0, function() -- line: 45
		-- upvalues: timestamp (ref), v13 (copy), n4 (ref), u18 (ref), XScale (copy), v10 (copy), p1 (copy), v9 (copy)
		local timestamp2 = tick()

		if timestamp2 - timestamp > v13 then
			n4 = not (n4 < u18) and 1.0 or n4 + 1.0
			timestamp = timestamp2

			local v22 = math.floor((n4 - 1.0) / XScale) * v10
			local v23 = (n4 - 1.0) % XScale * v10

			p1.Position = UDim2.new(-v23, 0.0, -v22, 0.0) + v9
		end
	end)
	p1.AncestryChanged:Connect(function() -- line: 58
		-- upvalues: p1 (copy), u15 (ref), u19 (ref)
		if not p1.Parent then
			if u15 then
				return
			end

			u15 = true

			if u19 then
				u19()
				u19 = nil
			end
		end
	end)

	return CleanupAnimation
end

