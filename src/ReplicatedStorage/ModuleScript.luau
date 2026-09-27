-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMgBmlwYWlycw5HZXREZXNjZW5kYW50cwhCYXNlUGFydANJc0EETmFtZQhmaW5kUGFydARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2URQWN0aXZlQXNzZXRNb2RlbHMMV2FpdEZvckNoaWxkC0Fzc2V0TW9kZWxzC0dldENoaWxkcmVuBU1vZGVsDkZpbmRGaXJzdENoaWxkBHdhcm4dTm8gbWF0Y2hpbmcgdGFyZ2V0IG1vZGVsIGZvcjoGQ0VOVEVSCEFuaW1Sb290Jk1pc3NpbmcgcGFydHMgZm9yICVzIChDRU5URVIvQW5pbVJvb3QpBmZvcm1hdAZDRnJhbWUNVG9PYmplY3RTcGFjZQVDbG9uZQZQYXJlbnQIQW5jaG9yZWQEU2l6ZQxUcmFuc3BhcmVuY3kKQ2FuQ29sbGlkZQVwcmludBNVcGRhdGVkIENFTlRFUiBmb3I6HkRvbmUuIFVwZGF0ZWQ6ICVkLCBTa2lwcGVkOiAlZAACCgIAAAAHBAAABQIHAxWkAgEAAAAAQLwDAEcCAAAAnwMCAJ8CAARRAgoAbwkDALwHBv4EAAAAnwcDAg4HBQBNBwa6BQAAAJoHAgABAAAAggYCAG4C9f8CAACAxgIAAIICAgAGAwEEAAAAQAMCAwMDBAMFAAcGARgAAAAAAAAAAQAAAAAAAAAAAf4ABQAIAAAAABQAAAEADAAAAgMQRQIDB4UBAooBowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAm8DBAC8AQDTBQAAAJ8BAwJvBAYAvAIA0wUAAACfAgMCwAMHAIwEAACMBQAApAYJAAAAgEC8BwFoCgAAAJ8HAgCfBgAEUQZlAG8NCwC8Cwr+DAAAAJ8LAwIOC2AATQ0Kug0AAAC8CwIDDgAAAJ8LAwIOCwUAbw4LALwMC/4MAAAAnwwDAisMCACkDBAAAADwQG8NEQBNDgq6DQAAAJ8MAwGVBQUSZQBNAFIMAwBSDQoAbw4TAJ8MAwJSDQMAUg4KAG8PFACfDQMCUg4DAFIPCwBvEBQAnw4DAg4MAgAODQEAKw4LAKQPEAAAAPBAbxAVAE0SCroNAAAAvBAQjRYAAACfEAMAnw8AAZUFBRJlADMATQ8NhRcAAABNEQyFFwAAALwPD0YYAAAAnw8DAlIQAwBSEQsAbxITAJ8QAwIrEAYAvBEMOhkAAACfEQICUhARADALECQaAAAATRIOhRcAAAAJERIPMBEQhRcAAABvExsAvBEQ/gwAAACfEQMCDhEQAE0RDEUcAAAAMBEQRRwAAABNEQwvHQAAADAREC8dAAAATREM2R4AAAAwERDZHgAAAE0RDNMfAAAAMBEQ0x8AAACkESEAAAAAQm8SIgBNEwu6DQAAAJ8RAwGVBAQSbgaa/wIAAICkBiEAAAAAQm8HIwBSCQQAUgoFALwHB40WAAAAnwcEAJ8GAAGCAAEAJAMHBAAAAEADCAMJAwoDCwMMBgADAQQAAIBAAw0DDgMEAwUDDwMQBAAA8EADEQIAAAAAAADwPwMSAxMDFAMVAxYDFwMYAxkDAwMaAxsDHAMdAx4EAAAAQgMfAyABAAEAARgAAgAAAAAAAQAAAAEAAAACCQACAAAAAAAAAQAAAAAEAAAAAAEAAAAAAAEAAAAAAAEBAwAAAAEAAAABAAAAAgAAAQAAAAAAAAAAAQEEAAAAAAAAAwAAAAEBAAAAAQAEAAAAAAEAAAAAAQAAAAEAAAABAAAAAQAAAAMAAAAAAAHWAC0AAAAAAAAAAAEBAAAAAAHgIVpux5pJg+1mtIltvJCckDlNGtLlMG8=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActiveAssetModels = ReplicatedStorage:WaitForChild("ActiveAssetModels")
local AssetModels = ReplicatedStorage:WaitForChild("AssetModels")

local function findPart(p1, s1: string) -- line: 7
	for _, descendant in ipairs(p1:GetDescendants()) do
		if descendant:IsA("BasePart") and s1 == descendant.Name then
			return descendant
		end
	end

	return nil
end

local n1 = 0.0
local n2 = 0.0

for _, child in ipairs(ActiveAssetModels:GetChildren()) do
	if child:IsA("Model") then
		local childName = AssetModels:FindFirstChild(child.Name)

		if not childName or not childName:IsA("Model") then
			warn("No matching target model for:", child.Name)
			n2 += 1.0
		else
			local v10 = findPart(child, "CENTER")
			local v11 = findPart(child, "AnimRoot")
			local v12 = findPart(childName, "AnimRoot")

			if not v10 or not v11 or not v12 then
				warn(("Missing parts for %s (CENTER/AnimRoot)"):format(child.Name))
				n2 += 1.0
			else
				local v13 = v11.CFrame:ToObjectSpace(v10.CFrame)
				local v14 = findPart(childName, "CENTER")

				if not v14 then
					v14 = v10:Clone()
					v14.Parent = childName
				end

				v14.CFrame = v12.CFrame * v13

				if v14:IsA("BasePart") then
					v14.Anchored = v10.Anchored
					v14.Size = v10.Size
					v14.Transparency = v10.Transparency
					v14.CanCollide = v10.CanCollide
				end

				print("Updated CENTER for:", childName.Name)
				n1 += 1.0
			end
		end
	end
end

print(("Done. Updated: %d, Skipped: %d"):format(n1, n2))

