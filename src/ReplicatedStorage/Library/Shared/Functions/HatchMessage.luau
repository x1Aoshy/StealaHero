-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMHCURpcmVjdG9yeQdHZXROYW1lC0Rpc3BsYXlOYW1lCUdldFJhcml0eQdNZXNzYWdlBUNvbG9yCEFubm91bmNlAAIMAwAAAAAXvAMAkQAAAACfAwICvAQAVgEAAACfBAICTQUBVwIAAAC8BgAlAwAAAJ8GAgJNBwb4BAAAAFIIBQBSCQQAUgoDAFILAgCfBwUCTQgGpAUAAABNCQZeBgAAAIIHBAAHAwEDAgMDAwQDBQMGAwcAAQABGAAAAAEAAAEAAQAAAQAAAAAAAAAAAAAAAgAAAAABAAABAgADowAAAMAAAACCAAIAAQYAAQABAAEYAAAAAQAAAAAB

-- decompilation:
return function(p1, p2, p3) -- line: 1
	local v4 = p1:Directory()
	local Name = p1:GetName()
	local DisplayName = p2.DisplayName
	local Rarity = p1:GetRarity()

	return Rarity.Message(DisplayName, Name, v4, p3), Rarity.Color, Rarity.Announce
end

