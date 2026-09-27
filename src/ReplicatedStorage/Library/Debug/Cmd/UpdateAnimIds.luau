-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUBGdhbWUJU2VsZWN0aW9uCkdldFNlcnZpY2UDR2V0CXdvcmtzcGFjZQtOZXdCcmFpbnJvdARBbmltBmlwYWlycwZzdHJpbmcFc3BsaXQETmFtZQMgOiAOR2V0RGVzY2VuZGFudHMJQW5pbWF0aW9uA0lzQQtBbmltYXRpb25JZAVtYXRjaA1yYnhhc3NldGlkOi8vBHdhcm4EZG9uZQABEgAAAQAAPqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwK8AAB/BAAAAJ8AAgKkAQYAAABQQE0BAVoHAAAATQEBDggAAACkAgoAAACQQFIDAACfAgIEUQImAKQHDQAAMLCATQgGug4AAABvCQ8AnwcDAhMIBwATCQcBpAoKAAAAkEC8CwFHEAAAAJ8LAgCfCgAEUQoVAG8REQC8Dw7+EgAAAJ8PAwIODxAATQ8OthMAAABSEQgAvA8P5xQAAACfDwMCDg8JAG8QFQBSEQkAcw8QETAPDrYTAAAApA8XAAAAYEFvEBgAnw8CAW4K6v8CAACAbgLZ/wIAAICCAAEAGQMBBAAAAEADAgMDAwQDBQQAAFBAAwYDBwMIBAAAkEADCQMKBAAwsIADCwMMAw0DDgMPAxADEQMSAxMEAABgQQMUAAEAARgAAgAAAAAAAAAAAQAAAAAAAgAAAAABAAAAAAABAQEAAAAAAAABAAAAAAAAAAAAAAABAAAAAAEAAAD9APwACwEAAAAAAPsErF0D6lkvUOKjb4opaSKLHLspycDGXA==

-- decompilation:
local v1 = game:GetService("Selection"):Get()
local Anim = workspace.NewBrainrot.Anim

for _, v in ipairs(v1) do
	local parts = string.split(v.Name, " : ")
	local v6 = parts[1.0]
	local v7 = parts[2.0]

	for _, descendant in ipairs(Anim:GetDescendants()) do
		if descendant:IsA("Animation") and descendant.AnimationId:match(v6) then
			descendant.AnimationId = "rbxassetid://" .. v7
			warn("done")
		end
	end
end

