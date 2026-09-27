-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIBHRhc2sFZGVmZXIERmlyZQ5HZXRQYXJ0c0luUGFydAZzY3JpcHQGUGFyZW50BlJlc3VsdBVCaW5kVG9NZXNzYWdlUGFyYWxsZWwAAgoDAQAACAUAAAUDDwcHDaQDAgAABACA+wQAAE0EBN0DAAAA+wUAAFIIAgBSCQEAvAYAtQQAAACfBgQAnwMAAYIAAQAFAwEDAgQABACAAwMDBAAHAAEYAAAAAAAAAAAAAAAAAQgAAAAABgAAAQIADqMAAACkAAEAAAAAQE0AACQCAAAATQEADgMAAABvBAQAwAUFABIAAQC8AgBaBgAAAJ8CBAGCAAEABwMFBAAAAEADBgMHAwQGAAMIAQABAAEYAAEAAAABAAQAAAAAAAMBAAAAAAHjLY9z12tzKuwaWy7pFnwvkzWYB9Hp5XI=

-- decompilation:
local scriptParent = script.Parent
local Result = scriptParent.Result

scriptParent:BindToMessageParallel("GetPartsInPart", function(p1, p2, p3) -- line: 7
	-- upvalues: Result (copy)
	task.defer(Result.Fire, Result, p1:GetPartsInPart(p3, p2))
end)

