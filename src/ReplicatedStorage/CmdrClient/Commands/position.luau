-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbCUNoYXJhY3RlchBIdW1hbm9pZFJvb3RQYXJ0DkZpbmRGaXJzdENoaWxkAAhQb3NpdGlvbgh0b3N0cmluZwIlcwRnc3ViCUNsaWVudFJ1bgRnYW1lB1BsYXllcnMKR2V0U2VydmljZQROYW1lCHBvc2l0aW9uB0FsaWFzZXMLRGVzY3JpcHRpb25eUmV0dXJucyBWZWN0b3IzIHBvc2l0aW9uIG9mIHlvdSBvciBvdGhlciBwbGF5ZXJzLiBFbXB0eSBzdHJpbmcgaXMgdGhlIHBsYXllciBoYXMgbm8gY2hhcmFjdGVyLgVHcm91cAxEZWZhdWx0RGVidWcEQXJncwNwb3MEVHlwZQZwbGF5ZXIGUGxheWVyQVRoZSBwbGF5ZXIgdG8gcmVwb3J0IHRoZSBwb3NpdGlvbiBvZi4gT21pdCBmb3IgeW91ciBvd24gcG9zaXRpb24uB0RlZmF1bHQLTG9jYWxQbGF5ZXIAAgcCAAAABwAAAQMDFAIYTQIBaQAAAAAOAgUAbwUBALwDAgMCAAAAnwMDAisDAgBvAwMAggMCAE0EAmYBAAAATQQEOwQAAAC7PwQCpAMGAAAAUECfAwICbwUHAG8GAwC8AwPMCAAAAJ8DBACCAwAACQMBAwIDAwMEAwUDBgQAAFBAAwcDCAARCQEYAAACAAAAAAABAAMAAAAAAAAAAAAAAAAAEgAAAAAFAAABAgAeowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAuIBDQD/AgAAAQAAAG8DDgDFAgMCAQAAADACAScGAAAA/wIAAAEAAADiAxQATQQAMRUAAAAwBAM6EwAAAMUCAwIBAAAAMAIB2wsAAADAAhYAMAIBMwwAAACCAQIAFwMKBAAAAEADCwMMAw0DDgMPAxADEQMSAxMDFAMJCAYEBQAAAAb/////BwgAAAAJCgAAAAv/////DP////8DFQMWAxcDGAMZAxoIBA8QAAAABBEAAAAHEgAAABP/////AxsGAAEAAQABGAAAAAAAAAACAgAAAAAAAAMAAQQAAAAAAPsACQAAAAEAAAAAAZXdW63ld7XkYwuTApy9ojXlxUzZpxkxrA==

-- decompilation:
local Players = game:GetService("Players")

return {
	Name = "position",
	Description = "Returns Vector3 position of you or other players. Empty string is the player has no character.",
	Group = "DefaultDebug",
	Aliases = { "pos" },
	Args = {{
		Type = "player",
		Name = "Player",
		Description = "The player to report the position of. Omit for your own position.",
		Default = Players.LocalPlayer
	}},
	ClientRun = function(_, p2) -- line: 17
		local Character = p2.Character

		if not Character or not Character:FindFirstChild("HumanoidRootPart") then
			return ""
		end

		return tostring(Character.HumanoidRootPart.Position):gsub("%s", "")
	end
}

