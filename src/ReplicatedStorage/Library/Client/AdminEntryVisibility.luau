-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWCUlzVmlzaWJsZQRnYW1lBkdhbWVJZBNJc0FkbWluUGFuZWxWaXNpYmxlB0tleUNvZGUERW51bQJGOAdDaGFuZ2VkBEZpcmURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZRBVc2VySW5wdXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdNb2R1bGVzCFBhY2thZ2VzBlNpZ25hbA9LZXlib2FyZEVuYWJsZWQMVG91Y2hFbmFibGVkA25ldwpJbnB1dEJlZ2FuB0Nvbm5lY3QABAEAAgAAAAT7AAAADgABAPsAAQCCAAIAAAAaAQEYAAAAABsAAAAAAgACAAAADqkAAQCkAQEAAAAAQE0BAbsCAAAADQEHAAMAAAD7AAAAKwAEAPsAAQBNAAAxBAAAAJ8AAQKCAAIABQMCBAAAAEADAwIAAHh5atYDQgMBAB4EARgAAAAAAAAAAAAAAAAAAB8AAAAABQIDAAAHBAAABQIHARX7AgAADgIHACsBBgBNAgCzAAAAAKQDAwACABDA8QICAAMAAACCAAEA+wMBAFYCAwDeAgEA+wICAE0CAoUEAAAA+wQBALwCAt0FAAAAnwIDAYIAAQAGAwUDBgMHBAIAEMADCAMJACYAARgAAAAAAAAAAAABAwAAAQAAAAAAAAEnAAAAAAoAAAECAEGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAwBqBwAAAE0DA+gIAAAATQMD5gkAAABNAwMfCgAAAJ8CAgJNAwEtCwAAAA4DAwBNBAF/DAAAAFYDBABNBAF/DAAAAA4EAwBNBQEtCwAAAFYEBQCpBQAA/wYDAAAAAABNBwLvDQAAAJ8HAQIwBwaFDgAAANkHAAASAAMAEgEF/zAHBjEPAAAAwAcQABIABAASAAYAMAcGIhEAAABNBwGCEgAAANkJAgASAAMAEgEF/xIABgC8BwfHEwAAAJ8HAwHBBQAAggYCABQDAgQAAABAAwoDCwMMAw0EAABQQAMOAw8DEAMRAxIDEwMUAwgDAQYBAwQDFQMWAwABAgEAARgAAwAAAAAAAQAAAAAAAwAAAAAAAAAAAAADAAAAAAABAAAAAAAEAwABAAAAAAYAAAAABAAAAAAIAAAAAAAAAAAJAAEAAAAAAwVgAXsOMfs2nTzetlHpwsB1eBYPN6Rreg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Signal = require(ReplicatedStorage.Library.Modules.Packages.Signal)
local v4 = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
local v5 = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local u6 = false
local t1 = {
	Changed = Signal.new(),
	IsVisible = function() -- line: 26
		-- upvalues: v4 (copy), u6 (ref)
		return v4 and u6
	end
}

function t1.IsAdminPanelVisible() -- line: 30
	-- upvalues: v5 (copy), t1 (copy)
	return game.GameId == 10650210095.0 or (v5 or t1.IsVisible())
end

UserInputService.InputBegan:Connect(function(input, gameProcessed: boolean) -- line: 38
	-- upvalues: v4 (copy), u6 (ref), t1 (copy)
	if not v4 or (gameProcessed or input.KeyCode ~= Enum.KeyCode.F8) then
		return
	end

	u6 = not u6
	t1.Changed:Fire(u6)
end)

return t1

