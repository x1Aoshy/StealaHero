-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVCEluc3RhbmNlA25ldwpBdHRhY2htZW50BkNGcmFtZQ1Ub09iamVjdFNwYWNlBmlwYWlycw5HZXREZXNjZW5kYW50cw9QYXJ0aWNsZUVtaXR0ZXIDSXNBBlBhcmVudAdEZXN0cm95B0FkZEl0ZW0HUGxheVZGWARnYW1lBkRlYnJpcwpHZXRTZXJ2aWNlEVJlcGxpY2F0ZWRTdG9yYWdlB3JlcXVpcmUNVXNlckdlbmVyYXRlZANWRlgERW1pdAEEAAIMAwIAABYFAgMFAwdABw8PDwcSCA8IEggPAwAyMqQDAgAABACAbwQDAJ8DAgJNBACFBAAAAFIGAQC8BARGBQAAAJ8EAwIwBAOFBAAAAKQEBwAAAGBAvAUCRwgAAACfBQIAnwQABFEEBwBvCwkAvAkI/goAAACfCQMCDgkCADADCCQLAAAAbgT4/wIAAIBvBgkAvAQC/goAAACfBAMCDgQDADADAiQLAAAAZQADALwEAlAMAAAAnwQCATAAAyQLAAAA+wQAAFIGAwD7BwEAUggDAJ8HAgC8BAR4DQAAAJ8EAAGCAAEADgMBAwIEAAQAgAMDAwQDBQMGBAAAYEADBwMIAwkDCgMLAwwAGQ0BGAAAAAABAAAAAAAAAAEAAAAAAAABAAAAAAEA/gAFAAAAAAEAAAIAAAIAAQAAAAAAAAABGgAAAAAEAAABAxMAAAQPAAEZDwEHEw8CDQ0PAxYEGqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwKkAgYAAABQQE0DAeAHAAAATQMDfggAAABNAwNWCQAAAJ8CAgLAAwoAEgAAABIAAgCCAwIACwMOBAAAAEADDwMQAxEDEgQAAFBAAxMDFAMVBgABAAEAARgAEwAAAAAAAQAAAAAAAgAAAAAAAAAAAgAAEQEAAAAAATbB07ukTjkB0pc4FaHq9k5G2cTPBAW5ug==

-- decompilation:
--!native
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Emit = require(ReplicatedStorage.UserGenerated.VFX.Emit)

local function PlayVFX(p1, cFrame: CFrame, p2) -- line: 25
	-- upvalues: Debris (copy), Emit (copy)
	local Attachment = Instance.new("Attachment")

	Attachment.CFrame = p1.CFrame:ToObjectSpace(cFrame)

	for _, descendant in ipairs(p2:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Parent = Attachment
		end
	end

	if p2:IsA("ParticleEmitter") then
		p2.Parent = Attachment
	else
		p2:Destroy()
	end

	Attachment.Parent = p1
	Debris:AddItem(Attachment, Emit(Attachment))
end

return PlayVFX

