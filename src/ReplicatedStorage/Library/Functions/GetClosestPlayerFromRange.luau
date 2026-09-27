-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaCGRpc3RhbmNlBlBsYXllcgZudW1iZXIJQ2hhcmFjdGVyEEh1bWFub2lkUm9vdFBhcnQORmluZEZpcnN0Q2hpbGQGaXBhaXJzCkdldFBsYXllcnMIUG9zaXRpb24JTWFnbml0dWRlBnBsYXllcgVkZWx0YQV0YWJsZQZpbnNlcnQEc29ydARtYXRoBWZsb29yA21heANtaW4EZ2FtZQdQbGF5ZXJzCkdldFNlcnZpY2URUmVwbGljYXRlZFN0b3JhZ2UHcmVxdWlyZQdMaWJyYXJ5B0Fzc2VydHMAAwUCAAAABwQAAAUCBAQJTQMAdQAAAABNBAF1AAAAALcDAgAEAAAAqQIAAakCAQCCAgIAAQMBAC4AARgAAAAAAAAAAAAvAAAAABQDAgAACAUAAAUDBwKCefsDAABNAwP5AAAAAFIEAACfAwIB+wMAAE0DA2ABAAAAUgQBAJ8DAgFNAwBpAgAAAFIEAwAOBAQAbwYDALwEAwMEAAAAnwQDAisEAwDGBQAAbwYFAIIFAwD/BQAAAAAAAKQGBwAAAGBA+wcBALwHB6sIAAAAnwcCAJ8GAARRBiYA8QolAAAAAABNCwppAgAAAFIMCwAODAQAbw4DALwMCwMEAAAAnwwDAg4MGwBNDgw7CQAAAE0PBDsJAAAAJg0OD00NDaoKAAAAfQ0TAAEAAADiEA4AMAoQGQsAAABNEgw7CQAAAE0TBDsJAAAAJhESEzARENYMAAAAMA0QdQ0AAACeNAUEEAAAAFIPBQCkDhEAAEDwgJ8OAwFuBtn/AgAAgKQGEwAASPCAUgcFAMAIFACfBgMBDgIMAIwHAAC7DAIDUgkCAKQIFwAAWFCBnwgCAp4SBwMIAAAApAYZAABgUIGfBgMCZQABAIwGAQCMBwEAfQYLAAcAAAATBwUAKwcDAMYIAABvCQUAgggDAE0IBxkLAAAATQkH1gwAAACCCAMA/wcAAAAAAAAcCgUAnhMGBAoAAABSCQYApAgbAABoUIGfCAMCjAsBAFIJCACMCgEAqAkDAIcMBQtqDAcLiwn9/4IHAgAcAwIDAwMEAwUDBgcAAIA/AAAAAAAAAAAAAAAAAwcEAABgQAMIAwkDCgMLAwwDAQUDCwwNAw0DDgQAQPCAAw8EAEjwgAYAAxADEQQAWFCBAxIEAGBQgQMTBABoUIEBABEAARgAAAAAAAEAAAAAAgABAAAAAAABAQAAAwABAAAAAAAAAAEAAwABAAAAAAABAQAAAAAAAAEAAQEAAQAAAAAAAAEAAAAA/QAA9wASAAAAAAQAAAAAAAAAAAAAAAAAAQAAAQEBAAACAAAAAAMAAQAAAAAAAAEAAAABAP8EEgAAAAAEAAABAgAYowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAqQCBgAAAFBATQMBagcAAABNAwOJCAAAAJ8CAgLAAwkAEgACABIAAACCAwIACgMUBAAAAEADFQMWAxcDGAQAAFBAAxkDGgYBAQEBAAEYAAMAAAAAAAEAAAAAAAMAAAAAAAAJAAAAAQAAAAACDxg9kA2kXANISHiotp++EH8AKuQ93FeR

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1, n1: number, n2: number?) -- line: 17
	-- upvalues: Asserts (copy), Players (copy)
	Asserts.Player(p1)
	Asserts.number(n1)

	local Character = p1.Character
	local v8 = Character and Character:FindFirstChild("HumanoidRootPart")

	if not v8 then
		return nil, (Vector3.new(1.0, 0.0, 0.0))
	end

	local t1 = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= p1 then
			local Character2 = player.Character
			local v13 = Character2 and Character2:FindFirstChild("HumanoidRootPart")

			if v13 then
				local Magnitude = (v13.Position - v8.Position).Magnitude

				if Magnitude <= n1 then
					table.insert(t1, {
						player = player,
						delta = v13.Position - v8.Position,
						distance = Magnitude
					})
				end
			end
		end
	end

	table.sort(t1, function(t2: {[any]: any}, t3: {[any]: any}) -- line: 46
		return t2.distance < t3.distance
	end)

	local v15 = not n2 and 1.0 or math.max(0.0, (math.floor(n2)))

	if v15 <= 1.0 then
		local v16 = t1[1.0]

		if not v16 then
			return nil, (Vector3.new(1.0, 0.0, 0.0))
		end

		return v16.player, v16.delta
	end

	local t4 = {}

	for i = 1.0, math.min(v15, #t1) do
		t4[i] = t1[i]
	end

	return t4
end

