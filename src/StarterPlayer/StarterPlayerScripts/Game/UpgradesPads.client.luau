-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbB09wZW5UYWIDR2V0CENsb3NlVGFiA25ldwNBZGQQQWRkRW50ZXJMaXN0ZW5lchBBZGRMZWF2ZUxpc3RlbmVyB2JpbmRQYWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlCVdvcmtzcGFjZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50B1dvcmxkRlgEUGFkcw1UYWJDb250cm9sbGVyB01vZHVsZXMIUGFja2FnZXMFVHJvdmUGU3RhbmRzDFdhaXRGb3JDaGlsZAtHZXRDaGlsZHJlbghCYXNlUGFydANJc0EETmFtZQAEAgACAAAABvsAAABNAAD0AAAAAPsBAQCfAAIBggABAAEDAQATAAEYAAAAAAABFAAAAAACAAIAAAAN+wAAAE0AAH8AAAAAnwABAvsBAQCaAAYAAQAAAPsAAABNAAAdAQAAAKkBAQCfAAIBggABAAIDAgMDABYAARgAAAAAAAAAAQAAAAACFwAAAAAJAwIAAAgFAAAFAw8HAxz7AwAATQMD7wAAAABSBAEAnwMCAlIGAwC8BABfAQAAAJ8EAwHZCAAAEgIBABIAAgC8BgM4AgAAAJ8GAwC8BABfAQAAAJ8EAAHZCAEAEgIBABIAAgC8BgOMAwAAAJ8GAwC8BABfAQAAAJ8EAAGCAAEABAMEAwUDBgMHAgABEAgBGAAAAAAAAQAAAAEAAAAAAAAAAAMAAAAAAAAAAAURAAAAABAAAAEAAEujAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMCpAIGAAAAUEBNAwBqBwAAAE0DA00IAAAATQMDZwkAAABNAwN8CgAAAJ8CAgKkAwYAAABQQE0EAGoHAAAATQQETQgAAABNBARDCwAAAJ8DAgKkBAYAAABQQE0FAGoHAAAATQUF6AwAAABNBQXmDQAAAE0FBZsOAAAAnwQCAm8HDwC8BQHTEAAAAJ8FAwJvBwoAvAUF0xAAAACfBQMCwAYRABIAAgASAAMAvAcFaBIAAACfBwIEZAcNAG8OEwC8DAv+FAAAAJ8MAwIODAgAUgwGAE0NBO8VAAAAnw0BAlIOCwBNDwu6FgAAAJ8MBAFuB/L/AgAAAIIAAQAXAwkEAAAAQAMKAwsDDAMNBAAAUEADDgMPAxADEQMSAxMDFAMVAxYDFwYCAxgDGQMaAwQDGwECAQABGAADAAAAAAABAAAAAAADAAAAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAwAAAAAAAAADAAANAAAAAQAAAAABAAAAAAAAAP4ABAEAAAAAA1+arLgrzbQT3PgTHuEktFovgrvMbV7GuQ==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Pads = require(ReplicatedStorage.Library.Client.WorldFX.Pads)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local Trove = require(ReplicatedStorage.Library.Modules.Packages.Trove)

local function bindPad(p1, p2, s1: string) -- line: 16
	-- upvalues: Pads (copy), TabController (copy)
	local v12 = Pads.new(p2)

	p1:Add(v12)
	p1:Add(v12:AddEnterListener(function() -- line: 19
		-- upvalues: TabController (copy), s1 (copy)
		TabController.OpenTab(s1)
	end))
	p1:Add(v12:AddLeaveListener(function() -- line: 22
		-- upvalues: TabController (copy), s1 (copy)
		if TabController.Get() == s1 then
			TabController.CloseTab(true)
		end
	end))
end

for _, child in Workspace:WaitForChild("Stands"):WaitForChild("Pads"):GetChildren() do
	if child:IsA("BasePart") then
		bindPad(Trove.new(), child, child.Name)
	end
end

