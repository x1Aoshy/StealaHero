-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMKAlVJDFdhaXRGb3JDaGlsZAZSYXJpdHkIR3JhZGllbnQFQ2xvbmUGUGFyZW50BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQZBc3NldHMAAgUCAQAAABf7AgAAbwQAALwCAtMBAAAAnwIDAm8EAgC8AgLTAQAAAJ8CAwJSBAEAvAIC0wEAAACfAgMCbwQDALwCAtMBAAAAnwIDArwCAjoEAAAAnwICAjAAAiQFAAAAggABAAYDAQMCAwMDBAMFAwYABAABGAAAAAAAAAAAAAAAAAAAAAAAAAAAAQABBgAAAAAEAAABAgAOowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAm8DBAC8AQDTBQAAAJ8BAwLAAgYAEgABAIICAgAHAwcEAAAAQAMIAwkDCgMCBgABAAEAARgAAAAAAAAAAQAAAAIAAAEAAAAAAZLS8ZgbcvtJ4FFzq7Ml7g7iyubsoBabmQ==

-- decompilation:
local Assets = game:GetService("ReplicatedStorage"):WaitForChild("Assets")

return function(p1, p2) -- line: 4
	-- upvalues: Assets (copy)
	Assets:WaitForChild("UI"):WaitForChild("Rarity"):WaitForChild(p2):WaitForChild("Gradient"):Clone().Parent = p1
end

