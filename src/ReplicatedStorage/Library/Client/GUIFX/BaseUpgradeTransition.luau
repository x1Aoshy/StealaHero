-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSDUN1cnJlbnRDYW1lcmEuQmFzZSB1cGdyYWRlIHRyYW5zaXRpb24gcmVxdWlyZXMgQ3VycmVudENhbWVyYQZhc3NlcnQFQmVnaW4EUGxheQZzY3JpcHQEdGFzawVzcGF3bghDb21wbGV0ZQRnYW1lCVdvcmtzcGFjZQpHZXRTZXJ2aWNlEVJlcGxpY2F0ZWRTdG9yYWdlB3JlcXVpcmUHTGlicmFyeQZDbGllbnQeQmFzZVVwZ3JhZGVUcmFuc2l0aW9uTGlmZWN5Y2xlBUF1ZGlvAAIIAQMAAAYDAAAFAQUo+wEAAE0BAUgAAAAARwECAAAAAICpAwABqQMBAIEBAwQBAAAAbwQBAKQCAwAAACBAnwIDAfsCAQBNAgK4BAAAAJ8CAQH7AgIATQIC7gUAAABvAwYApAQIAAAAcED/BQAAAgAAAG8GCQBvBwoAxQUGAwEAAABvBgsAnwIFAaQCDgAANMCAUgMAAJ8CAgH7AgEATQICZw8AAACfAgEBggABABADAQMCAwMEAAAgQAMEAwUCAK9Wl3tA20IDBgQAAHBAAs3MzMzMzOw/ApqZmZmZmfE/AgAAAAAAAPg/AwcDCAQANMCAAwkAXQUBGAAAAAEAAAAAAAAAAAABAAAAAgAAAAAAAAAAAAAAAAABAAAAAgAAAAFeAAAAAAYAAAECACajAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAwFqBwAAAE0DA00IAAAATQMDswkAAACfAgICpAMGAAAAUEBNBAFqBwAAAE0EBNIKAAAAnwMCAv8EAQAAAAAAwAULABIAAAASAAIAEgADADAFBO4MAAAAggQCAA0DCgQAAABAAwsDDAMNAw4EAABQQAMPAxADEQMSBgADBQEAAQABGAAGAAAAAAABAAAAAAADAAAAAAAAAAACAAAAAAAADgBCAAAAAAALAQAAAAABOh+Q5MVMKfCmU5F2L8bgrUoHh5AI2/rl

-- decompilation:
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseUpgradeTransitionLifecycle = require(ReplicatedStorage.Library.Client.BaseUpgradeTransitionLifecycle)
local Audio = require(ReplicatedStorage.Library.Audio)

return {
	Play = function(p1: ((...any) -> ...any)) -- line: 93
		-- upvalues: Workspace (copy), BaseUpgradeTransitionLifecycle (copy), Audio (copy)
		assert(Workspace.CurrentCamera ~= nil, "Base upgrade transition requires CurrentCamera")
		BaseUpgradeTransitionLifecycle.Begin()
		Audio.Play(119855061490364.0, script, {
			0.9,
			1.1
		}, 1.5)
		task.spawn(p1)
		BaseUpgradeTransitionLifecycle.Complete()
	end
}

