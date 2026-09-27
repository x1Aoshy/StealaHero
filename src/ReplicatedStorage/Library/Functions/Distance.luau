-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Library = ReplicatedStorage:WaitForChild("Library")
local Player = require(Library.Player)

return function(p1, p2) -- line: 6
	-- upvalues: Player (copy), Players (copy)
	local v7

	if p1 and (typeof(p1) ~= "Instance" or not p1:IsA("Player")) then
		v7 = if typeof(p1) ~= "CFrame" then if typeof(p1) ~= "BasePart" and (typeof(p1) ~= "MeshPart" and typeof(p1) ~= "Part") then if typeof(p1) ~= "Instance" then p1 else if p1.ClassName ~= "Model" then p1 else p1:GetPivot().Position else p1.Position else p1.Position
	else
		local v8 = if not p1 then Player.Optional.Humanoid(Players.LocalPlayer) else Player.Optional.Humanoid(p1)

		if not v8 then
			return nil
		end

		local RootPart = v8.RootPart

		if not RootPart then
			return nil
		end

		v7 = RootPart.Position
	end

	if v7 then
		if typeof(p2) == "Instance" and p2:IsA("Player") then
			local v10 = Player.Optional.Humanoid(p2)

			if not v10 then
				return nil
			end

			local RootPart = v10.RootPart

			if not RootPart then
				return nil
			end

			p2 = RootPart.Position
		elseif typeof(p2) == "CFrame" then
			p2 = p2.Position
		elseif typeof(p2) == "BasePart" or typeof(p2) == "MeshPart" or typeof(p2) == "Part" then
			p2 = p2.Position
		elseif typeof(p2) == "Instance" and p2.ClassName == "Model" then
			p2 = p2:GetPivot().Position
		end

		if p2 and typeof(v7) == "Vector3" and typeof(p2) == "Vector3" then
			return (v7 - p2).Magnitude
		end

		return nil
	end

	return nil
end

