-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWA1RvcAdNZXNzYWdlBFRpbWUFQ29sb3IKU2hvd1NoYWRvdwZDb2xvcjMDbmV3BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50B05ldHdvcmsQTm90aWZpY2F0aW9uQ21kcwdHbG9iYWxzCUNvbnN0YW50cwtORVRXT1JLX01BUA1BZG1pbk1lc3NhZ2VzBUZpcmVkDFNIT1dfTUVTU0FHRQdDb25uZWN0AAIIAgEAAAcEAAAFAgOCEvsCAABNAgKYAAAAAOIDBgAwAAP4AQAAADABA0oCAAAApAQJAAAgcICMBQEAjAYBAIwHAQCfBAQCMAQDpAMAAACfAgIBggABAAoDAQMCAwMDBAMFAQEIBAH/////Av////8D/////wQFAAAAAwYDBwQAIHCAAAkAARgAAAAAAQABAAEAAAAAAAAA/QYKAAAAAAgAAAECADOjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAk0HAAAATQICUggAAACfAQICpAIFAAAAQEBNAwBqBgAAAE0DA00HAAAATQMDbAkAAABNAwP4CgAAAJ8CAgKkAwUAAABAQE0EAGoGAAAATQQESwsAAABNBAQHDAAAAJ8DAgJNBAOzDQAAAE0EBMcOAAAATQUBSw8AAABNBgQ/EAAAAJ8FAgLABxEAEgACALwFBccSAAAAnwUDAYIAAQATAwgEAAAAQAMJAwoDCwQAAEBAAwwDDQMOAw8DAgMQAxEDEgMTAxQDFQYAAxYBAAEAARgAAAAAAAAAAgAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAACAAAAAgAAAAAAAAAAAAgBAAAAAAGPnGlvdpHYRXcjWl3XyqRO/4R+G71YA24=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Library.Client.Network)
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)
local AdminMessages = require(ReplicatedStorage.Library.Globals.Constants).NETWORK_MAP.AdminMessages

Network.Fired(AdminMessages.SHOW_MESSAGE):Connect(function(s1: string, n1: number?) -- line: 9
	-- upvalues: Message (copy)
	Message.Top({
		ShowShadow = true,
		Message = s1,
		Time = n1,
		Color = Color3.new(1.0, 1.0, 1.0)
	})
end)

