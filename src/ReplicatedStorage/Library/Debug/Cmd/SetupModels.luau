-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMkBGdhbWUJU2VsZWN0aW9uCkdldFNlcnZpY2UUQ2hhbmdlSGlzdG9yeVNlcnZpY2UGaXBhaXJzA0dldAVNb2RlbANJc0EISHVtYW5vaWQVRmluZEZpcnN0Q2hpbGRPZkNsYXNzEEh1bWFub2lkUm9vdFBhcnQORmluZEZpcnN0Q2hpbGQOR2V0Qm91bmRpbmdCb3gISW5zdGFuY2UDbmV3BlBhcmVudAtHZXRDaGlsZHJlbgdEZXN0cm95BUNsb25lCEFuY2hvcmVkDldlbGRDb25zdHJhaW50BVBhcnQwBVBhcnQxE0FuaW1hdGlvbkNvbnRyb2xsZXIIQW5pbWF0b3IETmFtZQtQcmltYXJ5UGFydARQYXJ0BkNFTlRFUgRTaXplDFRyYW5zcGFyZW5jeQpDYW5Db2xsaWRlCENhblRvdWNoCENhblF1ZXJ5BkNGcmFtZQFZAAEXAAABAACoAaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQLwDAH8HAAAAnwMCAJ8CAARRApEAbwkIALwHBv4JAAAAnwcDAg4HjABvCQoAvAcGuAsAAACfBwMCbwoMALwIBgMNAAAAnwgDAg4HgwAOCIIAvAkGlQ4AAACfCQIDpAsRAABA8IBvDAgAnwsCAk0MBiQSAAAAMAwLJBIAAAAwCwYkEgAAAKQMBgAAAFBAvA0HaBMAAACfDQIAnwwABFEMAwC8ERBQFAAAAJ8RAgFuDPz/AgAAgDALByQSAAAAvAwIOhUAAACfDAICpA0GAAAAUEC8DgxoEwAAAJ8OAgCfDQAEUQ0DALwSEVAUAAAAnxICAW4N/P8CAACAqQ0AADANCEUWAAAAqQ0AADANDEUWAAAAMAsMJBIAAACkDREAAEDwgG8OFwCfDQICMAgNPBgAAAAwDA2xGQAAADAIDSQSAAAApA4RAABA8IBvDxoAnw4CAqQPEQAAQPCAbxAbAJ8PAgIwDg8kEgAAADAGDiQSAAAATRAGuhwAAAAwEAu6HAAAAG8QCAAwEAa6HAAAADAMC5sdAAAApBARAABA8IBvER4AnxACAm8RHwAwERC6HAAAAG8RIAAwERAvIQAAAIwRAQAwERDZIgAAAKkRAAAwERBFFgAAAKkRAAAwERDTIwAAAKkRAAAwERD2JAAAAKkRAAAwERBiJQAAADALECQSAAAApBInAABAYIKMEwAATRYKeCoAAAA+FRYplRQVKIwVAACfEgQCCREJEjAREIUmAAAApBERAABA8IBvEhcAnxECAjAQETwYAAAAMAwRsRkAAAAwEBEkEgAAAG4Cbv8CAACAggABACsDAQQAAABAAwIDAwMEAwUEAABQQAMGAwcDCAMJAwoDCwMMAw0DDgMPBABA8IADEAMRAxIDEwMUAxUDFgMXAxgDGQMaAxsDHAMdB2q8VD8tsj0/bxIDOwAAAAADHgMfAyADIQMiAyMEAEBgggIAAAAAAAAIQAIAAAAAAAAAQAMkAAEAARgAAAAAAAAAAQAAAAAAAgAAAAAAAAEAAAAAAwAAAAEAAAABAAQAAAIAAAABAAAAAwADAAAAAAAAAQAA/wADAAMAAAEAAAAAAAABAAD/AAMAAAEAAAEAAgAAAAEAAQABAAMAAAABAAAAAQABAAMAAAABAAADAAMAAAABAAABAAABAAABAAABAAABAAABAAABAAIAAAAAAAAAAAAAAAIAAAABAAEAAQC9AEUBAAAAAABLdTE5jMasTiub9/k7qLHQO20mTXmxWzg=

-- decompilation:
local Selection = game:GetService("Selection")

game:GetService("ChangeHistoryService")

for _, v in ipairs(Selection:Get()) do
	if v:IsA("Model") then
		local Humanoid = v:FindFirstChildOfClass("Humanoid")
		local HumanoidRootPart = v:FindFirstChild("HumanoidRootPart")

		if Humanoid and HumanoidRootPart then
			local v6, v7 = v:GetBoundingBox()
			local Model = Instance.new("Model")

			Model.Parent = v.Parent
			v.Parent = Model

			for _, child in ipairs(Humanoid:GetChildren()) do
				child:Destroy()
			end

			Humanoid.Parent = Model

			local clone = HumanoidRootPart:Clone()

			for _, child in ipairs(clone:GetChildren()) do
				child:Destroy()
			end

			HumanoidRootPart.Anchored = false
			clone.Anchored = false
			clone.Parent = Model

			local WeldConstraint = Instance.new("WeldConstraint")

			WeldConstraint.Part0 = HumanoidRootPart
			WeldConstraint.Part1 = clone
			WeldConstraint.Parent = HumanoidRootPart

			local AnimationController = Instance.new("AnimationController")

			Instance.new("Animator").Parent = AnimationController
			AnimationController.Parent = v
			Model.Name = v.Name
			v.Name = "Model"
			Model.PrimaryPart = clone

			local Part = Instance.new("Part")

			Part.Name = "CENTER"
			Part.Size = Vector3.new(0.8309999704360962, 0.7409999966621399, 0.0020000000949949026)
			Part.Transparency = 1.0
			Part.Anchored = false
			Part.CanCollide = false
			Part.CanTouch = false
			Part.CanQuery = false
			Part.Parent = Model
			Part.CFrame = v6 * CFrame.new(0.0, v7.Y / 2.0 + 3.0, 0.0)

			local WeldConstraint2 = Instance.new("WeldConstraint")

			WeldConstraint2.Part0 = Part
			WeldConstraint2.Part1 = clone
			WeldConstraint2.Parent = Part
		end
	end
end

