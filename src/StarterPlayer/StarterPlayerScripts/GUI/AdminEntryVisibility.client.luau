-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBlBhcmVudAdWaXNpYmxlBE5hbWUKQWRtaW5QYW5lbAlTY3JlZW5HdWkDSXNBKFBsYXllckd1aS5BZG1pblBhbmVsIG11c3QgYmUgYSBTY3JlZW5HdWkGYXNzZXJ0BlRvZ2dsZQpUZXh0QnV0dG9uMFBsYXllckd1aS5BZG1pblBhbmVsLlRvZ2dsZSBtdXN0IGJlIGEgVGV4dEJ1dHRvbhNJc0FkbWluUGFuZWxWaXNpYmxlB0NoYW5nZWQHQ29ubmVjdBNiaW5kQWRtaW5QYW5lbEVudHJ5BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50FEFkbWluRW50cnlWaXNpYmlsaXR5A0dVSQlQbGF5ZXJHdWkLR2V0Q2hpbGRyZW4KQ2hpbGRBZGRlZAADAgEBAAAGAwAABQEBCfsBAABNAQEkAAAAAEcBBAAAAAAA+wEAADAAAYABAAAAggABAAIDAQMCACEAARgAAAAAAAEAAAIiAAAAAAYBAQAABgMAAAUBBypNAQC6AAAAAPABAgABAAAAggABAG8EAgC8AgD+AwAAAJ8CAwKBAQIEBAAAAG8DBACkAQYAAABQQJ8BAwFNAQCsBwAAAG8FCAC8AwH+AwAAAJ8DAwKBAQMECQAAAG8ECQCkAgYAAABQQJ8CAwH7AgAATQICIgoAAACfAgECMAIBgAsAAAD7AgAATQIChQwAAADZBAAAEgABALwCAscNAAAAnwIDAYIAAQAOAwMDBAMFAwYDBwMIBAAAUEADCQMKAwsDDAMCAw0DDgEAGQ8BGAAAAAABAgAAAAAAAAAAAAEAAQAAAAAAAAAAAAEAAAAAAAEAAAAAAAAABRoAAAAADAAAAQAALqMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAGoGAAAATQICTQcAAABNAgIBCAAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMDTQcAAABNAwM5CQAAAJ8CAgJNAwKZCgAAAJ8DAQLABAsAEgABALwFA2gMAAAAnwUCBGQFAwBSCgQAUgsJAJ8KAgFuBfz/AgAAAE0FA2sNAAAAUgcEALwFBccOAAAAnwUDAYIAAQAPAxAEAAAAQAMRAxIDEwQAAEBAAxQDFQMWAxcDGAYBAxkDGgMOAQEBAAEYAAMAAAAAAAMAAAAAAAAAAAEAAAAAAAAAAAsAAAYAEwAAAAEAAP8AAwAAAAAAAQEAAAAAAoxWlTWixJYoPpRqB4ZWanv8ToJBvpL/NA==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminEntryVisibility = require(ReplicatedStorage.Library.Client.AdminEntryVisibility)
local v3 = require(ReplicatedStorage.Library.Client.GUI).PlayerGui()

local function bindAdminPanelEntry(p1) -- line: 25
	-- upvalues: AdminEntryVisibility (copy)
	if p1.Name ~= "AdminPanel" then
		return
	end

	assert(p1:IsA("ScreenGui"), "PlayerGui.AdminPanel must be a ScreenGui")

	local Toggle = p1.Toggle

	assert(Toggle:IsA("TextButton"), "PlayerGui.AdminPanel.Toggle must be a TextButton")
	Toggle.Visible = AdminEntryVisibility.IsAdminPanelVisible()
	AdminEntryVisibility.Changed:Connect(function(property: boolean) -- line: 33
		-- upvalues: Toggle (copy)
		if Toggle.Parent ~= nil then
			Toggle.Visible = property
		end
	end)
end

for _, child in v3:GetChildren() do
	bindAdminPanelEntry(child)
end

v3.ChildAdded:Connect(bindAdminPanelEntry)

