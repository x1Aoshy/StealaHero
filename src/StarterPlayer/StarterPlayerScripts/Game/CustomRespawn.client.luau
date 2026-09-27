-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVBEZpcmUHTkVUX01BUA9DbGllbnRDaGFyYWN0ZXIXUkVRVUVTVF9DSEFSQUNURVJfUkVTRVQVcmVxdWVzdENoYXJhY3RlclJlc2V0CEh1bWFub2lkDFdhaXRGb3JDaGlsZAREaWVkB0Nvbm5lY3QNYmluZENoYXJhY3RlcgRnYW1lB1BsYXllcnMKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50B05ldHdvcmsLTG9jYWxQbGF5ZXIOQ2hhcmFjdGVyQWRkZWQJQ2hhcmFjdGVyAAQEAQEAAAYDAAAFAQcN+wEAAE0BAd0AAAAA+wIAAE0CAtABAAAATQICRAIAAABNAgIcAwAAAFIDAACfAQMBggABAAQDAQMCAwMDBAARBQEYAAAAAAAAAAAAAAAAARIAAAAABAACAAAADvsAAAD7AQEATQEB3QAAAAD7AgEATQIC0AEAAABNAgJEAgAAAE0CAhwDAAAAUgMAAJ8BAwGCAAEABAMBAwIDAwMEABgAARgH+QAAAAAAAAAAAAAACBIAAAAABQEBAAAGAwAABQEHDW8DAAC8AQDTAQAAAJ8BAwJNAgHHAgAAANkEAAASAAAAEgIAALwCAscDAAAAnwIDAYIAAQAEAwYDBwMIAwkBARUKARgAAAAAAgAAAAAAAAADFgAAAAALAAABAgA0owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCBgAAAFBATQMBagcAAABNAwNNCAAAAE0DA1IJAAAAnwICAk0DADEKAAAAwAQLABIAAgDABQwAEgACAE0GA5cNAAAAUggFALwGBscOAAAAnwYDAU0GA2kPAAAADgYOAE0GA2kPAAAAbwkQALwHBtMRAAAAnwcDAk0IB8cSAAAA2QoCABIABgASAAIAvAgIxw4AAACfCAMBggABABMDCwQAAABAAwwDDQMOAw8EAABQQAMQAxEDEgMTBgAGAgMUAwkDFQMGAwcDCAMAAgEBAAEYAAMAAAAAAAEAAAAAAAMAAAAAAAAAAAMABgAEAAwAAAAAAAEAAAEA8wAAAAIAAAAAAAAADQEAAAAAA4f2Y+PjfedDylNfbK5CkDH37nSXtTIJ4g==

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Library.Client.Network)
local LocalPlayer = Players.LocalPlayer

local function requestCharacterReset(p1) -- line: 17
	-- upvalues: Network (copy)
	Network.Fire(Network.NET_MAP.ClientCharacter.REQUEST_CHARACTER_RESET, p1)
end
local function bindCharacter(p2) -- line: 21
	-- upvalues: Network (copy)
	p2:WaitForChild("Humanoid").Died:Connect(function() -- line: 24
		-- upvalues: p2 (copy), Network (copy)
		local v11 = p2

		Network.Fire(Network.NET_MAP.ClientCharacter.REQUEST_CHARACTER_RESET, v11)
	end)
end

LocalPlayer.CharacterAdded:Connect(bindCharacter)

if LocalPlayer.Character then
	local Character = LocalPlayer.Character

	Character:WaitForChild("Humanoid").Died:Connect(function() -- line: 24
		-- upvalues: Character (copy), Network (copy)
		local v10 = Character

		Network.Fire(Network.NET_MAP.ClientCharacter.REQUEST_CHARACTER_RESET, v10)
	end)
end

