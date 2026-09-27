-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBnN0cmluZwhvcHRpb25hbAdib29sZWFuDkdldFBsb3RzRm9sZGVyCUdldE15U2xvdAZpcGFpcnMOR2V0RGVzY2VuZGFudHMETmFtZQZQYXJlbnQIdG9zdHJpbmcIQmFzZVBhcnQDSXNBGUxvY2FsVHJhbnNwYXJlbmN5TW9kaWZpZXIKU3VyZmFjZUd1aQdFbmFibGVkDEJpbGxib2FyZEd1aQpDYW5VcGdyYWRlB1JlZnJlc2gEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzBkNsaWVudAhQbG90Q21kcwACEgICAAAHBAAABQIDgWr7AgAATQICQQAAAABSAwAAnwICAfsCAABNAgIRAQAAAE0CAj4CAAAAUgMBAJ8CAgH7AgEATQIC7QMAAACfAgEC+wMBAE0DAwQEAAAAnwMBAkcCAgAAAACAggABAKQEBgAAAFBAvAUCRwcAAACfBQIAnwQABFEESQBNCQi6CAAAAJoJRgAAAAAATQkIJAkAAABHCUIAAAAAAKkJAABHAxEAAAAAAKkJAABNCggkCQAAAE0KCroIAAAAuz8DA1IMAwCkCwsAAACgQJ8LAgKaCgUACwAAACoBAgAAAACAqQkAAakJAQCkCgYAAABQQLwLCEcHAAAAnwsCAJ8KAARRCiUAbxEMALwPDv4NAAAAnw8DAg4PBwAOCQIAjA8AAGUAAQCMDwEAMA8OMg4AAABlABkAbxEPALwPDv4NAAAAnw8DAg4PAwAwCQ7wEAAAAGUAEQBvEREAvA8O/g0AAACfDwMCDg8MAA4JCABNDw66CAAAAPAPCAASAAAAqQ8BADAPDvAQAAAAZQADAKkPAAAwDw7wEAAAAG4K2v8CAACAbgS2/wIAAICCAAEAEwMBAwIDAwMEAwUDBgQAAFBAAwcDCAMJAwoEAACgQAMLAwwDDQMOAw8DEAMRABESARgAAAAAAAEAAAAAAAACAAAAAQAAAAEAAQMAAAAAAAABAAAAAAAAAAQAAAABAAAAAAAAAAAAAAEAAAABAAAAAAAAAQAAAAABAAAAAAAAAQAAAAABAAABAAAAAAEBAAAAAQAAAAMAAPUA+AAYEgAAAAAFAAABAgAfowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMDTQgAAABNAwOlCQAAAJ8CAgL/AwEAAAAAAMAECgASAAEAEgACADAEA/ULAAAAggMCAAwDEwQAAABAAxQDFQMWBAAAQEADFwMYAxkDGgYAAxIBAAEAARgAAwAAAAAAAwAAAAAAAAEAAAAAAAAAAAMABgAAAAAkAQAAAAABIxlF1YWtMQJIxPccOq78q1MBUqER3S/U

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local PlotCmds = require(ReplicatedStorage.Library.Client.PlotCmds)

return {
	Refresh = function(s1: string, b1: boolean?) -- line: 17
		-- upvalues: Asserts (copy), PlotCmds (copy)
		Asserts.string(s1)
		Asserts.optional.boolean(b1)

		local v6 = PlotCmds.GetPlotsFolder()
		local v7 = PlotCmds.GetMySlot()

		if v6 == nil then
			return
		end

		for _, descendant in ipairs(v6:GetDescendants()) do
			if s1 == descendant.Name and descendant.Parent ~= nil then
				local v10 = v7 ~= nil and (descendant.Parent.Name == tostring(v7) and b1 ~= false)

				for _, descendant2 in ipairs(descendant:GetDescendants()) do
					if descendant2:IsA("BasePart") then
						descendant2.LocalTransparencyModifier = not v10 and 1.0 or 0.0
					elseif descendant2:IsA("SurfaceGui") then
						descendant2.Enabled = v10
					elseif descendant2:IsA("BillboardGui") then
						if v10 then
							if descendant2.Name ~= "CanUpgrade" then
								descendant2.Enabled = true
							end
						else
							descendant2.Enabled = false
						end
					end
				end
			end
		end
	end
}

