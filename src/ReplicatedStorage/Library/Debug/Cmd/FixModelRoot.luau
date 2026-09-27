-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBGdhbWUJU2VsZWN0aW9uCkdldFNlcnZpY2UUQ2hhbmdlSGlzdG9yeVNlcnZpY2UGaXBhaXJzA0dldAVNb2RlbANJc0EQSHVtYW5vaWRSb290UGFydA5GaW5kRmlyc3RDaGlsZAhIdW1hbm9pZBZGaW5kRmlyc3RDaGlsZFdoaWNoSXNBBlBhcmVudAhSb290UGFydAROYW1lDkdldEJvdW5kaW5nQm94CFBvc2l0aW9uAVkHVmVjdG9yMwNuZXcAARAAAAEABwAAAQgMNwE9owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCBgAAAFBAvAMAfwcAAACfAwIAnwIABFECJgBvCQgAvAcG/gkAAACfBwMCDgchAG8JCgC8BwYDCwAAAJ8HAwIOBxwAbwoMALwIBlQNAAAAnwgDAg4IAwDGCQAAMAkIJA4AAABvCQ8AMAkHuhAAAAC8CQaVEQAAAJ8JAgNNCwc7EgAAAIwNAABNDwp4FAAAAD4ODxOMDwAATDYAAqQMFwAAWFCBnwwEAiYLCwwwCwc7EgAAAG4C2f8CAACAggABABgDAQQAAABAAwIDAwMEAwUEAABQQAMGAwcDCAMJAwoDCwMMAw0DDgMPAxADEQIAAAAAAAAAQAMSAxMDFAQAWFCBAAEAARgAAAAAAAAAAQAAAAAAAgAAAAAAAAEAAAAAAwAAAAEEAAAAAQEAAAMAAAIAAAIAAAAAAAAAAAAAAAAA7gAUAQAAAAAAJLJb6jNNB7joodMsQtjWi1SqTJ4WdjHr

-- decompilation:
local Selection = game:GetService("Selection")

game:GetService("ChangeHistoryService")

for _, v in ipairs(Selection:Get()) do
	if v:IsA("Model") then
		local HumanoidRootPart = v:FindFirstChild("HumanoidRootPart")

		if HumanoidRootPart then
			local Humanoid = v:FindFirstChildWhichIsA("Humanoid")

			if Humanoid then
				Humanoid.Parent = nil
			end

			HumanoidRootPart.Name = "RootPart"

			local _, v7 = v:GetBoundingBox()

			HumanoidRootPart.Position = HumanoidRootPart.Position - Vector3.new(0.0, v7.Y / 2.0, 0.0)
		end
	end
end

