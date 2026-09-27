-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcDkhhc0VxdWlwcGVkRWdnC0lzU2F0aXNmaWVkFEJpbmRPbkFkYXB0ZXJDaGFuZ2VkBEJpbmQIQ2xlYXJBbGwWRm9yY2VCZXN0RWdnSW50b0hvdGJhchJHZXRFZ2dIb3RiYXJUYXJnZXQNU2hvd0hpZ2hsaWdodA5DbGVhckhpZ2hsaWdodBNyZWZyZXNoUHJlc2VudGF0aW9uCkRpc2Nvbm5lY3QHQ2hhbmdlZAdDb25uZWN0B1ByZXNlbnQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQZDbGllbnQiR3VhcmRUdXRvcmlhbFByZXNlbnRhdGlvbkNvbXBvbmVudAZzY3JpcHQGUGFyZW50CVN0ZXBVdGlscwVUeXBlcwlJbnRlcmZhY2UGU3RlcElkCEVxdWlwRWdnAAYDAQAAAAAEvAEACQAAAACfAQIAggEAAAEDAQAVAgEYAAAAABYAAAAABgICAAAHBAAABQIPBQr7AgAATQICRwAAAABSAwAA+wQBAE0EBAcBAAAAUgUBAJ8CBACCAgAAAgMDAwIAGQQBGAAAAAAAAAAAAAAaAAAAAAQAAwAAACH7AAAATQAABwAAAAD7AQEAnwACAg4ABQD7AAIAvAAASwEAAACfAAIBggABAPsAAQC8AADAAgAAAJ8AAgIrAAQA+wABALwAACcDAAAAnwACAkcABwAAAAAA+wECAFIDAAC8AQGCBAAAAJ8BAwGCAAEA+wECALwBAbAFAAAAnwECAYIAAQAGAwIDBQMGAwcDCAMJACEKARgAAAAAAAABAAAAAQMAAAAAAAAAAAEAAQAAAAAAAgAAAAIiAAAAAAIAAgAAAAn7AAAAvAAAGgAAAACfAAIB+wABALwAAEsBAAAAnwACAYIAAQACAwsDBQAyAAEYAAAAAAEAAAABMwAAAAAGAgEAAAAQ2QIAABICAAASAAEAEgAAAE0DAYUAAAAAUgUCALwDA8cBAAAAnwMDAlIEAgCfBAEB2QQBABIAAwASAAAAggQCAAIDDAMNAgIDHQ4BGAAAAAAOAAAAAAABAAIAAAAhAAAAAAYAAAECADSjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAk0HAAAATQIC5QgAAACfAQICpAIFAAAAQECkAwoAAACQQE0DAyQLAAAATQMDJAsAAABNAwPODAAAAJ8CAgKkAwUAAABAQKQECgAAAJBATQQEJAsAAABNBATvDQAAAE0EBA8OAAAAnwMCAuIEEQDABRIAMAUEBxMAAADABRQAEgACABIABAAwBQSKFQAAAMAFFgASAAQAMAUEAhcAAACCBAIAGAMPBAAAAEADEAMRAxIEAABAQAMTAxQDFQMWBAAAkEADFwMYAxkDGgMbAxwIAQ8QAAAABgADAgYBAwQGBAMOAwABBAEAARgAAwAAAAAAAwAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAgEAAAEAAAAAAQAAAAbAQAAAAAFotqtZYZEEdr/OrY39/UaeNLCuhGQHsdk

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Client.GuardTutorialPresentationComponent)

local StepUtils = require(script.Parent.Parent.StepUtils)

require(script.Parent.Types.Interface)

local t1 = {
	StepId = "EquipEgg",
	IsSatisfied = function(p1) -- line: 21
		return p1:HasEquippedEgg()
	end
}

function t1.Bind(p2, p3: ((...any) -> ...any)) -- line: 25
	-- upvalues: StepUtils (copy), t1 (copy)
	return StepUtils.BindOnAdapterChanged(p2, t1.IsSatisfied, p3)
end
function t1.Present(p4, p5) -- line: 29
	-- upvalues: t1 (copy)
	local function refreshPresentation() -- line: 33
		-- upvalues: t1 (copy), p5 (copy), p4 (copy)
		if t1.IsSatisfied(p5) then
			p4:ClearAll()

			return
		end

		local v11 = p5:ForceBestEggIntoHotbar() or p5:GetEggHotbarTarget()

		if v11 ~= nil then
			p4:ShowHighlight(v11)

			return
		end

		p4:ClearHighlight()
	end

	local connection = p5.Changed:Connect(refreshPresentation)

	refreshPresentation()

	return function() -- line: 50
		-- upvalues: connection (copy), p4 (copy)
		connection:Disconnect()
		p4:ClearAll()
	end
end

return t1

