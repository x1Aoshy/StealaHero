-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTFkNvcmVTY3JpcHRMb2NhbGl6YXRpb24OUm9ibG94TG9jYWxlSWQNR2V0VHJhbnNsYXRvcg1nZXRUcmFuc2xhdG9yFmdldFRyYW5zbGF0b3JGb3JMb2NhbGULRm9ybWF0QnlLZXkFcGNhbGwXZm9ybWF0QnlLZXlXaXRoRmFsbGJhY2sURm9ybWF0QnlLZXlGb3JMb2NhbGUEZ2FtZRNMb2NhbGl6YXRpb25TZXJ2aWNlCkdldFNlcnZpY2UHUGxheWVycwtMb2NhbFBsYXllcglQbGF5ZXJHdWkLQmFja3BhY2tHdWkMV2FpdEZvckNoaWxkGEdldFByb3BlcnR5Q2hhbmdlZFNpZ25hbARXYWl0AAcDAAMAAAAP+wAAAEcACwAAAACA+wABAE0AAKoAAAAA+wICAE0CAosBAAAAvAAAGQIAAACfAAMC3gAAAPsAAACCAAIAAwMBAwIDAwASBAEYAAAAAQAAAAAAAAAAAAIAEwAAAAAFAQIAAAAP+wIAAIcBAgAOAQEAggECAPsCAQBNAgKqAAAAAFIEAAC8AgIZAQAAAJ8CAwJSAQIA+wIAAGoBAgCCAQIAAgMBAwMAGwUBGAAAAQEDAAAAAAAAAAEAAhwAAAAABAADAAAAB/sAAAD7AgEA+wMCALwAAJsAAAAAnwAEAIIAAAABAwYAKAABGAAAAAAAAAApAAAAAAkDAQAAABCkAwEAAAAAQNkEAAASAAIAEgAAABIAAQCfAwIDDgMBAIIEAgD7BQAAUgcAAFIIAQC8BQWbAgAAAJ8FBACCBQAAAwMHBAAAAEADBgECJwgBGAAAAAAAAAAEAQIAAAAAAAAoAAAAAAcDAwAAABT7BAAARwQLAAAAAID7BAEATQQEqgAAAAD7BgIATQYGiwEAAAC8BAQZAgAAAJ8EAwLeBAAA+wMAAFIFAQBSBgIAvAMDmwMAAACfAwQAggMAAAQDAQMCAwMDBgA1BgEYAAAAAQAAAAAAAAAAAAIjAAAAAAATAAAAAAkEAgAAABb7BgAAhwUGAg4FAgBSBAUAZQALAPsGAQBNBgaqAAAAAFIIAgC8BgYZAQAAAJ8GAwJSBQYA+wYAAGoFBgJSBAUAUgYBAFIHAwC8BASbAgAAAJ8EBACCBAAAAwMBAwMDBgA9CQEYAAABAQADAAAAAAAAAAEAAh0AAAAAABwAAAAADAAAAQIAQKMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQE0BAVAEAAAATQEBMQUAAABNAQGZBgAAAG8EBwC8AgHTCAAAAJ8CAwKkAwEAAAAAQG8FBAC8AwMWAwAAAJ8DAwLGBAAATQUDMQUAAABHBQgAAAAAgG8HBQC8BQOUCQAAAJ8FAwK8BQX3CgAAAJ8FAgHGBQAA2QYAABIBBf8SAAEAEgAAAP8HAAAAAAAAwAgLABIABwASAAEA2QkCABIBBP//CgIAAAAAANkLAwASAQX/EgABABIAAAAwCwqbDAAAAMALDQASAAcAEgABADALCq4OAAAAwQQAAIIKAgAPAwoEAAAAQAMLAwwDDQMOAw8DEAMRAxIDEwYBAwYGBQMJBQABAwQFAQABGAAAAAAAAAABAAAAAAAAAAEAAAABAAAAAAADBgAAAAEAAAAAAAADAQAAAAcAAgAADAAMAAIAAAAAAAgAAAAACAABAAAAAAZ2Wp0mbUVzzb0MkMChnsxsBkKKUkSe9yc=

-- decompilation:
local LocalizationService = game:GetService("LocalizationService")
local PlayerGui = game.Players.LocalPlayer.PlayerGui

PlayerGui:WaitForChild("BackpackGui")

local Players = game:GetService("Players")
local u4 = nil

if Players.LocalPlayer == nil then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local Translator = nil

local function getTranslator() -- line: 18
	-- upvalues: Translator (ref), PlayerGui (copy), LocalizationService (copy)
	if Translator == nil then
		Translator = PlayerGui.CoreScriptLocalization:GetTranslator(LocalizationService.RobloxLocaleId)
	end

	return Translator
end

local t1 = {}

local function getTranslatorForLocale(p1) -- line: 27
	-- upvalues: t1 (copy), PlayerGui (copy)
	local v11 = t1[p1]

	if v11 then
		return v11
	end

	local Translator2 = PlayerGui.CoreScriptLocalization:GetTranslator(p1)

	t1[p1] = Translator2

	return Translator2
end
local function formatByKeyWithFallback(p2, p3, p4) -- line: 39
	-- upvalues: u4 (ref)
	local ok, result = pcall(function() -- line: 40
		-- upvalues: p4 (copy), p2 (copy), p3 (copy)
		return p4:FormatByKey(p2, p3)
	end)

	if ok then
		return result
	end

	return u4:FormatByKey(p2, p3)
end

return {
	FormatByKey = function(_, p6, p7) -- line: 53
		-- upvalues: Translator (ref), PlayerGui (copy), LocalizationService (copy)
		if Translator == nil then
			Translator = PlayerGui.CoreScriptLocalization:GetTranslator(LocalizationService.RobloxLocaleId)
		end

		return Translator:FormatByKey(p6, p7)
	end,
	FormatByKeyForLocale = function(_, p9, p10, p11) -- line: 61
		-- upvalues: t1 (copy), PlayerGui (copy)
		local v25 = t1[p10]

		if v25 then
		else
			v25 = PlayerGui.CoreScriptLocalization:GetTranslator(p10)
			t1[p10] = v25
		end

		return v25:FormatByKey(p9, p11)
	end
}

