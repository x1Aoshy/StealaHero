-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSC0xvY2FsUGxheWVyCEdldE1vdXNlBlRhcmdldAAFTW9kZWwYRmluZEZpcnN0QW5jZXN0b3JPZkNsYXNzFkdldFBsYXllckZyb21DaGFyYWN0ZXIETmFtZQlDbGllbnRSdW4EZ2FtZQdQbGF5ZXJzCkdldFNlcnZpY2UFaG92ZXILRGVzY3JpcHRpb241UmV0dXJucyB0aGUgbmFtZSBvZiB0aGUgcGxheWVyIHlvdSBhcmUgaG92ZXJpbmcgb3Zlci4FR3JvdXALRGVmYXVsdFV0aWwEQXJncwACBwABAAAAGfsAAABNAAAxAAAAALwAACMBAAAAnwACAk0BACwCAAAAKwECAG8CAwCCAgIA+wIAAG8GBAC8BAFJBQAAAJ8EAwC8AgKJBgAAAJ8CAAIOAgMATQMCugcAAAArAwEAbwMDAIIDAgAIAwEDAgMDAwQDBQMGAwcDCAAJCQEYAAAAAAAAAQACAQADAAAAAAAAAAIAAAAAAAoAAAAAAwAAAQIAEaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLiAQwA/wIAAAAAAAAwAgHbCgAAAMACDQASAAAAMAIBMwsAAACCAQIADgMKBAAAAEADCwMMAwgDDQMOAw8DEAMRAxIDCQgFBAUAAAAGBwAAAAgJAAAACv////8L/////wYAAQABAAEYAAAAAAAAAAIEAAAAAgAAAAABAAAAAAGgdAYftCMpuXJxx0Yqmtdv0GwRa5KwbB4=

-- decompilation:
local Players = game:GetService("Players")

return {
	Name = "hover",
	Description = "Returns the name of the player you are hovering over.",
	Group = "DefaultUtil",
	Args = {},
	ClientRun = function() -- line: 9
		-- upvalues: Players (copy)
		local Target = Players.LocalPlayer:GetMouse().Target

		if not Target then
			return ""
		end

		local player = Players:GetPlayerFromCharacter(Target:FindFirstAncestorOfClass("Model"))

		return player and player.Name or ""
	end
}

