-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJCkdldFBsYXllcnMEdGFzawVzcGF3bgtQbGF5ZXJBZGRlZAdDb25uZWN0D3NhZmVQbGF5ZXJBZGRlZARnYW1lB1BsYXllcnMKR2V0U2VydmljZQACCQEBAAAGAwAABQEFFPsBAAC8AQGrAAAAAJ8BAgRkAQUApAYDAAAIEIBSBwAAUggFAJ8GAwFuAfr/AgAAAPsBAABNAQEoBAAAAFIDAAC8AQHHBQAAAJ8BAwCCAQAABgMBAwIDAwQACBCAAwQDBQALBgEYAAAAAAABAAAAAP8ABAAAAAAAAAAMAAAAAAMAAAECAAqjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCwAEEABIAAACCAQIABQMHBAAAAEADCAMJBgABAAEAARgACAAAAAAAAgAIAQAAAAABeRjidcqIqyVXR52iCUdcqgkA9QFL3Ih0

-- decompilation:
local Players = game:GetService("Players")

local function safePlayerAdded(p1: ((...any) -> ...any)) -- line: 11
	-- upvalues: Players (copy)
	for _, player in Players:GetPlayers() do
		task.spawn(p1, player)
	end

	return Players.PlayerAdded:Connect(p1)
end

return safePlayerAdded

