-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcCEV4ZWN1dG9yCEdldE1vdXNlCUNoYXJhY3RlchBIdW1hbm9pZFJvb3RQYXJ0DkZpbmRGaXJzdENoaWxkG1lvdSBkb24ndCBoYXZlIGEgY2hhcmFjdGVyLghQb3NpdGlvbgNIaXQBcAR1bml0Bk1vdmVUbwhCbGlua2VkIQlDbGllbnRSdW4ETmFtZQR0aHJ1B0FsaWFzZXMLRGVzY3JpcHRpb25kVGVsZXBvcnRzIHlvdSB0aHJvdWdoIHdoYXRldmVyIHlvdXIgbW91c2UgaXMgaG92ZXJpbmcgb3ZlciwgcGxhY2luZyB5b3UgZXF1aWRpc3RhbnRseSBmcm9tIHRoZSB3YWxsLgVHcm91cAxEZWZhdWx0RGVidWcEQXJncwF0B3Rocm91Z2gEVHlwZQZudW1iZXIORXh0cmEgZGlzdGFuY2UqR28gdGhyb3VnaCB0aGUgd2FsbCBhbiBhZGRpdGlvbmFsIFggc3R1ZHMuB0RlZmF1bHQAAg0CAAAAACVNAgD/AAAAALwCAiMBAAAAnwICAk0DAP8AAAAATQMDaQIAAAAOAwUAbwYDALwEAwMEAAAAnwQDAisEAgBvBAUAggQCAE0EA2YDAAAATQQEOwYAAABNBgL7BwAAAE0GBpEIAAAAJgUGBFsKBQlNDAUnCgAAAAkLDAFDCQoLQwgJBLwGA3cLAAAAnwYDAW8GDACCBgIADQMBAwIDAwMEAwUDBgMHAwgDCQIAAAAAAAAAQAMKAwsDDAAPDQEYAAAAAAABAAAAAgAAAAAAAQADAAAAAQAAAAACAAAAAAAAAAACABMAAAAABAAAAQIAFaMAAADiAAkA/wEAAAIAAABvAgoAbwMLAMUBAgMBAAAAMAEAJwIAAAD/AQAAAQAAAOICEgDFAQICAQAAADABANsHAAAAwAETADABADMIAAAAggACABQDDgMPAxADEQMSAxMDFAMVAw0IBgABAAAAAv////8DBAAAAAUGAAAAB/////8I/////wMWAxcDGAMZAxoDGwMcAgAAAAAAAAAACAQMDQAAAAAOAAAAAw8AAAAQEQAAAAYAAQABAAEYAAACAAAAAAAAAAMAAQAA/wAJAAAAAQAAAAABi0AoqKb22OFJ3uro1YCBVftYP9y5hEKp

-- decompilation:
return {
	Name = "thru",
	Description = "Teleports you through whatever your mouse is hovering over, placing you equidistantly from the wall.",
	Group = "DefaultDebug",
	Aliases = {
		"t",
		"through"
	},
	Args = {{
		Type = "number",
		Name = "Extra distance",
		Description = "Go through the wall an additional X studs.",
		Default = 0.0
	}},
	ClientRun = function(p1, p2) -- line: 15
		local Mouse = p1.Executor:GetMouse()
		local Character = p1.Executor.Character

		if not Character or not Character:FindFirstChild("HumanoidRootPart") then
			return "You don't have a character."
		end

		local HumanoidRootPartPosition = Character.HumanoidRootPart.Position
		local v6 = Mouse.Hit.p - HumanoidRootPartPosition

		Character:MoveTo(v6 * 2.0 + v6.unit * p2 + HumanoidRootPartPosition)

		return "Blinked!"
	end
}

