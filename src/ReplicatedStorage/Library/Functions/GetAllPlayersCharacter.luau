-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIBXBhaXJzCkdldFBsYXllcnMJQ2hhcmFjdGVyBXRhYmxlBmluc2VydARnYW1lB1BsYXllcnMKR2V0U2VydmljZQACCQABAAAAGP8AAAAAAAAApAEBAAAAAED7AgAAvAICqwIAAACfAgIAnwEABBcBCwBNBgVpAwAAAA4GCABNCAVpAwAAAJ40AAQIAAAAUgcAAKQGBgAAFECAnwYDAW4B9P8CAAAAggACAAcDAQQAAABAAwIDAwMEAwUEABRAgAAFAAEYAAACAAAAAAAAAAEAAAEAAAAAAAAA/gAGBgAAAAADAAABAgAKowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAsABBAASAAAAggECAAUDBgQAAABAAwcDCAYAAQABAAEYAAIAAAAAAAIAAAEAAAAAAawIMmB7zhL0O9OmNWgRyf3cECUUnsxYYQ==

-- decompilation:
local Players = game:GetService("Players")

return function() -- line: 5
	-- upvalues: Players (copy)
	local t1 = {}

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(t1, player.Character)
		end
	end

	return t1
end

