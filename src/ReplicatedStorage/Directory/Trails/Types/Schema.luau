-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBWVycm9yDXVuaW1wbGVtZW50ZWQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdNb2R1bGVzCFBhY2thZ2VzAXQJRGlyZWN0b3J5BlJhcml0eQ9UcmFpbE5hbWVFeGlzdHMJaW50ZXJmYWNlA19pZAVQcmljZQlQcm9kdWN0SWQESWNvbg9TcGVlZE11bHRpcGxpZXINRGlzcGxheUluU2hvcAtEaXNwbGF5TmFtZQZzdHJpbmcGbnVtYmVyCG9wdGlvbmFsBVR5cGVzDURlZmF1bHRDb25maWcHYm9vbGVhbgACAwEAAAAGAwAABQEDBaQBAQAAAABAbwICAJ8BAgGCAAEAAwMBBAAAAEADAgANAAEYAAAAAAEOAAAAAAgAAAECAE2jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgKVCQAAAJ8BAgKkAgUAAABAQE0DAJEKAAAATQMD8gsAAACfAgIC/wMCAAAAAADABAwAMAQDLQ0AAABNBAEvDgAAAOIFFgBNBgFBFwAAADAGBdMPAAAATQYBYBgAAAAwBgUkEAAAAE0GAREZAAAATQcBYBgAAACfBgICMAYFCxEAAABNBgFBFwAAADAGBa4SAAAATQYC7xoAAABNBgYMGwAAADAGBfILAAAATQYBYBgAAAAwBgWgEwAAAE0GAREZAAAATQcBPhwAAACfBgICMAYFZhQAAABNBgFBFwAAADAGBVcVAAAAnwQCAjAEAwwbAAAAggMCAB0DAwQAAABAAwQDBQMGBAAAQEADBwMIAwkDCgMLAwwGAAMNAw4DDwMQAxEDEgMTAxQDFQUIDxAREgsTFBUDFgMXAxgDGQMaAxsBAAEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAAAwACAAAEAAABAAAAAQAAAAEAAAAAAAABAAAAAQAAAAAAAQAAAAEAAAAAAAABAAAA+AAACwEAAAAAAd08ojq6XQDJnLaoMBW2KuatJLVO7/jIOw==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local Rarity = require(ReplicatedStorage.Directory.Rarity)

return {
	TrailNameExists = function(_: string) -- line: 13
		error("unimplemented")
	end,
	DefaultConfig = t.interface({
		_id = t.string,
		Price = t.number,
		ProductId = t.optional(t.number),
		Icon = t.string,
		Rarity = Rarity.Types.DefaultConfig,
		SpeedMultiplier = t.number,
		DisplayInShop = t.optional(t.boolean),
		DisplayName = t.string
	})
}

