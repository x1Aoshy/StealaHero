-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBnN0cmluZwlUZXh0TGFiZWwIb3B0aW9uYWwGQ29sb3IzBFRleHQGU2hhZG93DkZpbmRGaXJzdENoaWxkClRleHRDb2xvcjMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzAQQAAgcEAQAACQYAAAUEBwPAgyb7BAAATQQEQQAAAABSBQEAnwQCAfsEAABNBASaAQAAAFIFAACfBAIB+wQAAE0EBBECAAAATQQEmgMAAABSBQIAnwQCAfsEAABNBAQRAgAAAE0EBEEAAAAAUgUDAJ8EAgHKBAMBMAQA9QQAAABvBgUAvAQAAwYAAACfBAMCDgQFADABBPUEAAAADgICADACBHMHAAAAggABAAgDAQMCAwMDBAMFAwYDBwMIAAoAARgAAAAAAAEAAAAAAQAAAAAAAAEAAAAAAAACAAACAAAAAQEAAQEAAwsAAAAAAwAAAQIAEaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICwAIIABIAAQCCAgIACQMJBAAAAEADCgMLAwwEAABAQAMNAw4GAAEAAQABGAADAAAAAAADAAAAAAAAAwAAAQAAAAABonf8BwjaNoSkNZhshjgcOdJv63OQs5YG

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1, s1: string, color3: Color3?, s2: string?) -- line: 10
	-- upvalues: Asserts (copy)
	Asserts.string(s1)
	Asserts.TextLabel(p1)
	Asserts.optional.Color3(color3)
	Asserts.optional.string(s2)
	p1.Text = s2 or s1

	local Shadow = p1:FindFirstChild("Shadow")

	if Shadow then
		Shadow.Text = s1

		if color3 then
			Shadow.TextColor3 = color3
		end
	end
end

