-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXCEdldFNjYWxlBVNjYWxlClNjYWxlUmlnaHQIU2NhbGVBbGwMVG91Y2hFbmFibGVkDFVwZGF0ZU1vYmlsZQRnYW1lB1BsYXllcnMKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZRBVc2VySW5wdXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQZDbGllbnQQU2NyZWVuUmVzb2x1dGlvbgtMb2NhbFBsYXllcglQbGF5ZXJHdWkMV2FpdEZvckNoaWxkCEVsZW1lbnRzBVJpZ2h0DER5bmFtaWNTY2FsZQdDaGFuZ2VkB0Nvbm5lY3QABAMAAgAAAAn7AAAA+wIBAE0CAuUBAAAAnwIBApUBAgAwAQCEAgAAAIIAAQADApqZmZmZmbk/AwEDAgAcAwEYAAAAAAAAAAABHQAAAAADAAIAAAAJ+wAAAPsCAQBNAgLlAQAAAJ8CAQKVAQIAMAEAhAIAAACCAAEAAwKamZmZmZm5PwMBAwIAIAQBGAAAAAAAAAAABR0AAAAAAQABAAAABvsAAABNAAB/AAAAACsAAQCCAAEAggABAAEDBQAkBgEYAAAAAAECJQAAAAAPAAABAgBFowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCAQAAAABAbwQFALwCAhYDAAAAnwIDAqQDBwAAAGBATQQBaggAAABNBARNCQAAAE0EBMYKAAAAnwMCAk0EADELAAAAbwcMALwFBNMNAAAAnwUDAm8IDgC8BgXTDQAAAJ8GAwJNBwYFDwAAAE0IB/8QAAAAwAkRABIACAASAAMAwAoSABIACAASAAMAwAsTABIAAgBNDQPlFQAAAJ8NAQKVDA0UMAwIhBYAAABNDAJ/FwAAACsMAQBlAAAATQwDhRgAAABSDgoAvAwMxxkAAACfDAMB/wwAAAAAAACCDAIAGgMHBAAAAEADCAMJAwoDCwMMBAAAYEADDQMOAw8DEAMRAxIDEwMUAxUGAAYBBgICmpmZmZmZuT8DAQMCAwUDFgMXAwABAgEAARgAAwAAAAAAAQAAAAAAAQAAAAAAAwAAAAAAAAAADAABAAAAAQAAAAEAAQADAAAEAAAEAPkAAAAAAAgAAAEIAAAAAAACAAABAAAAAAOdsIvwmG3GA5C4mK6zKAAS7aichK904fE=

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ScreenResolution = require(ReplicatedStorage.Library.Client.ScreenResolution)
local DynamicScale = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Elements").Right.DynamicScale

local function ScaleRight() -- line: 28
	-- upvalues: DynamicScale (copy), ScreenResolution (copy)
	DynamicScale.Scale = ScreenResolution.GetScale() + 0.1
end
local function ScaleAll() -- line: 32
	-- upvalues: DynamicScale (copy), ScreenResolution (copy)
	DynamicScale.Scale = ScreenResolution.GetScale() + 0.1
end
local function UpdateMobile() -- line: 36
	-- upvalues: UserInputService (copy)
	if not UserInputService.TouchEnabled then
		return
	end
end

DynamicScale.Scale = ScreenResolution.GetScale() + 0.1

if UserInputService.TouchEnabled then
end

ScreenResolution.Changed:Connect(ScaleAll)

return {}

