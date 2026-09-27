-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLCkZpcmVTZXJ2ZXIEZ2FtZQpHdWlTZXJ2aWNlCkdldFNlcnZpY2UGc2NyaXB0BlBhcmVudAlNZW51U3RhdGUMV2FpdEZvckNoaWxkCk1lbnVPcGVuZWQHQ29ubmVjdApNZW51Q2xvc2VkAAMDAAEAAAQAAQAPBvsAAACpAgEAvAAAawAAAACfAAMBggABAAEDAQAYAAEYAAAAAAABGQAAAAADAAEAAAQAAQAPBvsAAACpAgAAvAAAawAAAACfAAMBggABAAEDAQAbAAEYAAAAAAABHAAAAAAFAAABAwsAAAIPAAEdDwEHFx6jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAQEkBgAAAG8DBwC8AQHTCAAAAJ8BAwJNAgCWCQAAAMAECgASAAEAvAICxwsAAACfAgMBTQIATgwAAADABA0AEgABALwCAscLAAAAnwIDAYIAAQAOAwIEAAAAQAMDAwQDBQQAAEBAAwYDBwMIAwkGAAMKAwsGAQIAAQEAARgAEwAAAAAAAgAAAAAAAAACAAAAAAAAAwAAAAAAAAMBAAAAAAJ1oLok6DGnmreivAH5eQXFBbitUEdk0CU=

-- decompilation:
--!native
local GuiService = game:GetService("GuiService")
local MenuState = script.Parent:WaitForChild("MenuState")

GuiService.MenuOpened:Connect(function() -- line: 24
	-- upvalues: MenuState (copy)
	MenuState:FireServer(true)
end)
GuiService.MenuClosed:Connect(function() -- line: 27
	-- upvalues: MenuState (copy)
	MenuState:FireServer(false)
end)

