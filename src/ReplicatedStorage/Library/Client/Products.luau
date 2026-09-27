-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPC0xvY2FsUGxheWVyA0dldAhQcm9kdWN0cwh0b3N0cmluZwRPd25zBkdldEFsbARnYW1lB1BsYXllcnMKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdMaWJyYXJ5DFdhaXRGb3JDaGlsZAZDbGllbnQHcmVxdWlyZQRTYXZlAAMIAgIAAAsEAAEFAgKHAwYSARZSAgEAKwIDAPsCAABNAgIxAAAAAPsDAQBNAwN/AQAAAFIEAgCfAwICDgMJAE0FA0ECAAAAuz8AA1IHAACkBgQAAAAwQJ8GAgKHBAUGggQCAKkEAACCBAIABQMBAwIDAwMEBAAAMEAACQUBGAAAAAAAAQAAAAABAQAAAAAAAAAAAgAKAAAAAAQBAgAABgMAAAUBhxFSAQAAKwEDAPsBAABNAQExAAAAAPsCAQBNAgJ/AQAAAFIDAQCfAgICDgIDAE0DAkECAAAAKwMCAP8DAAAAAAAAggMCAAMDAQMCAwMAEwYBGAAAAAAAAQAAAAABAAAAAAAAFAAAAAAFAAABAgAnowAAAP8AAgAAAAAApAEBAAAAAEBvAwIAvAEBFgMAAACfAQMCpAIBAAAAAEBvBAQAvAICFgMAAACfAgMCbwQFALwCAtMGAAAAnwIDAm8EBwC8AgLTBgAAAJ8CAwKkAwkAAACAQE0EAmUKAAAAnwMCAsAECwASAAEAEgADADAEAGMMAAAAwAQNABIAAQASAAMAMAQA0A4AAACCAAIADwMHBAAAAEADCAMJAwoDCwMMAw0DDgQAAIBAAw8GAAMFBgEDBgIAAQEAARgAAgACAAAAAAABAAAAAAAAAAAAAAAAAAEAAAAAAgAAAAAKAAAAAAYBAAAAAAJX7EICNnLU5Vc4VH/gUT+JJ/RVdmUoKAM=

-- decompilation:
local t1 = {}
local Players = game:GetService("Players")
local Client = game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client")
local Save = require(Client.Save)

function t1.Owns(n1: number, p1) -- line: 9
	-- upvalues: Players (copy), Save (copy)
	local v7 = p1 or Players.LocalPlayer
	local v8 = Save.Get(v7)

	if v8 then
		return v8.Products[tostring(n1)]
	end

	return false
end
function t1.GetAll(p2) -- line: 19
	-- upvalues: Players (copy), Save (copy)
	local v10 = p2 or Players.LocalPlayer
	local v11 = Save.Get(v10)

	return v11 and v11.Products or {}
end

return t1

