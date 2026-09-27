-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMCUd1aU9iamVjdAdVSVNjYWxlFkZpbmRGaXJzdENoaWxkV2hpY2hJc0EISW5zdGFuY2UDbmV3BlBhcmVudARnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMAAgQBAQAABgMAAAUBBxL7AQAATQEB4wAAAABSAgAAnwECAW8DAQC8AQBUAgAAAJ8BAwIOAQEAggECAKQCBQAAEDCAbwMBAJ8CAgIwAAIkBgAAAIICAgAHAwEDAgMDAwQDBQQAEDCAAwYACgABGAAAAAAAAgAAAAEBAwAAAAEAAQsAAAAAAwAAAQIAEaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICiQcAAACfAQICwAIIABIAAQCCAgIACQMHBAAAAEADCAMJAwoEAABAQAMLAwwGAAEAAQABGAADAAAAAAADAAAAAAAAAwAAAQAAAAABR0kFjDsT95UeXFmON2rp8jdREvh1jW+N

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1) -- line: 10
	-- upvalues: Asserts (copy)
	Asserts.GuiObject(p1)

	local UIScale = p1:FindFirstChildWhichIsA("UIScale")

	if UIScale then
		return UIScale
	end

	local UIScale2 = Instance.new("UIScale")

	UIScale2.Parent = p1

	return UIScale2
end

