-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMfB0Rlc3Ryb3kGUmVtb3ZlC1ByaW1hcnlQYXJ0CEJhc2VQYXJ0CEFuY2hvcmVkA25ldwhSZWdpc3RlcgNBZGQFUGFydHMKQ29tcG9uZW50cwVUcm92ZQpEZXN0cm95aW5nB0Nvbm5lY3QNbmV3TW9kZWxTdGF0ZQVNb2RlbAxmaW5pdGVDRnJhbWUIR2V0UGl2b3QGQ0ZyYW1lDVRvT2JqZWN0U3BhY2UJU2V0Q0ZyYW1lCFNldFBpdm90BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwZDbGllbnQSQnVsa01vdmVDb250cm9sbGVyB01vZHVsZXMIUGFja2FnZXMBEgAGBwABAAAACvsAAADGAQAAxgIAAGQAAwC8BQRQAAAAAJ8FAgFuAPz/AgAAAIIAAQABAwEAKAABGAAAAAABAAD/AAMpAAAAAAIAAgAAAAb7AAAATQAAaQAAAAD7AQEAnwACAYIAAQABAwIANAABGAAAAAAAATUAAAAACwEFAAAGAwAABQEHPE0BAJsAAAAA+wIAAE0CAmMBAAAAUgMBAJ8CAgGpAgEAMAIBRQIAAAD7AgEATQIC7wMAAACfAgEC/wMAAAAAAAD/BAAAAQAAAFIHAQDFBAcCAQAAAMYFAADGBgAAZAQGAPsJAgBNCQmDBAAAAFIKCACfCQICagkDB24E+f8CAAAA2QYAABIAAwC8BAJfBQAAAJ8EAwHiBAkA/wUAAAEAAABSBgEAxQUGAgEAAAAwBQQvBgAAADADBB4HAAAAMAIEmwgAAAD7BQMAagQFAE0HAGIKAAAA2QgBABICBAASAAAAvAUCxwsAAACfBQQBggQCAAwDAwMEAwUDBgMHAwgDCQMKAwsFAwYHCAMMAw0CAAEcDgEYAAABAAAAAAIAAAIAAAABAAEAAAAAAAAAAQAAAAAB/gAEAAAAAAYBAAAAAAAAAQABAAIAAQAAAAAAAAAEHQAAAAANAgMAAAcEAAAFAgdAJ/sCAABNAgI7AAAAAFIDAACfAgIB+wIAAE0CAkMBAAAAUgMBAJ8CAgH7AwEAhwIDACsCAwD7AgIAUgMAAJ8CAgK8AwBSAgAAAJ8DAgJNBAIvAwAAAMYFAADGBgAAZAQMAE0LCIUEAAAAvAkDRgUAAACfCQMCTQsCHgYAAACHCgsHCQwBCbwKCtoHAAAAnwoDAW4E8/8CAAAAggABAAgDDwMQAxEDCQMSAxMDCgMUAD8VARgAAAAAAAEAAAAAAgAAAAAAAQAAAQAAAAABAAAAAAEAAAAAAAD+AARAAAAAAAQBAgAACgMAAQUBBw8CDwIT+wEAAE0BATsAAAAAUgIAAJ8BAgH7AgEAhwECAEcBAgAAAACAggABAPsCAQDGAwAAagMCAE0CAZsBAAAAvAICUAIAAACfAgIBggABAAMDDwMLAwEASwIBGAAAAAAAAgABAAEDAAABAAAAAAFMAAAAAAgAAAECADijAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwNNCAAAAE0DA3kJAAAAnwICAqQDBQAAAEBATQQAagYAAABNBAToCgAAAE0EBOYLAAAATQQEmwwAAACfAwIC/wQAAAAAAAD/BQIAAAAAAMAGDQASAAEAEgADABIAAgASAAQAEgAFAMAHDgASAAEAEgAEABIABgAwBwVeDwAAAMAHEAASAAEAEgAEADAHBWkRAAAAggUCABIDFgQAAABAAxcDGAMZBAAAQEADGgMbAxwDHQMeAx8DCwYCBgMDFQYEAwIDAgMEAQABGAADAAAAAAADAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAAADAAMADQAAAAAAIwAAAAAADAAAAAAMAQAAAAAF8YZQu6RB1xQfwNW1jfD0jIGeR8/DQjq6

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local BulkMoveController = require(ReplicatedStorage.Library.Client.BulkMoveController)
local Trove = require(ReplicatedStorage.Library.Modules.Packages.Trove)
local t1 = {}
local t2 = {}

local function newModelState(p1) -- line: 28
	-- upvalues: Asserts (copy), Trove (copy), BulkMoveController (copy), t1 (copy), t2 (copy)
	local PrimaryPart = p1.PrimaryPart

	Asserts.BasePart(PrimaryPart)
	PrimaryPart.Anchored = true

	local v10 = Trove.new()
	local t3 = {}

	for v12, v13 in { PrimaryPart } do
		t3[v12] = BulkMoveController.Register(v13)
	end

	v10:Add(function() -- line: 40
		-- upvalues: t3 (copy)
		for _, v25 in t3 do
			v25:Destroy()
		end
	end)

	local t4 = {
		Parts = { PrimaryPart },
		Components = t3,
		Trove = v10
	}

	t1[p1] = t4
	v10:Connect(p1.Destroying, function() -- line: 52
		-- upvalues: t2 (copy), p1 (copy)
		t2.Remove(p1)
	end)

	return t4
end

function t2.SetPivot(p2, cFrame: CFrame) -- line: 63
	-- upvalues: Asserts (copy), t1 (copy), newModelState (copy)
	Asserts.Model(p2)
	Asserts.finiteCFrame(cFrame)

	local v17 = t1[p2] or newModelState(p2)
	local Pivot = p2:GetPivot()

	for v19, v20 in v17.Parts do
		local v21 = Pivot:ToObjectSpace(v20.CFrame)

		v17.Components[v19]:SetCFrame(cFrame * v21)
	end
end
function t2.Remove(p3) -- line: 75
	-- upvalues: Asserts (copy), t1 (copy)
	Asserts.Model(p3)

	local v23 = t1[p3]

	if v23 == nil then
		return
	end

	t1[p3] = nil
	v23.Trove:Destroy()
end

return t2

