-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMgDVJheWNhc3RQYXJhbXMDbmV3BkNGcmFtZQhQb3NpdGlvbgFYAVoJd29ya3NwYWNlB1BldEFyZWEIUEVUX1VVSUQMR2V0QXR0cmlidXRlCEVxdWlwUGV0BkJvdHRvbQdNZXNzYWdlH1lvdSBjYW5ub3QgcGxhY2UgeW91ciBwZXQgaGVyZSEEVGltZQRnYW1lEVJlcGxpY2F0ZWRTdG9yYWdlCkdldFNlcnZpY2UGc2NyaXB0BlBhcmVudAdyZXF1aXJlB0xpYnJhcnkJRnVuY3Rpb25zD0dldE1vdXNlVG9Xb3JsZAtNYW5oYXR0YW4yRAdNb2R1bGVzC1BldFNlcnZpY2VzC1BldHNTZXJ2aWNlBkNsaWVudBBOb3RpZmljYXRpb25DbWRzCUFjdGl2YXRlZAdDb25uZWN0AAIHAAUAAAAt+wAAAKQBAgAABACAnwEBAowCZACfAAMCDgAlAKQBBAAABDCATQIAOwUAAABNAgJ5BgAAAIwDAABNBAA7BQAAAE0EBHsHAAAAnwEEAvsCAQBNAwE7BQAAAKQECQAAAIBATQQEAgoAAACfAgMCDgILAPsCAgD7BAMAbwYLALwEBBIMAAAAnwQDAlIFAQC8AgIYDQAAAJ8CBAGCAAEA+wIEAE0CAhMOAAAA4gMTAJ8CAgGCAAEAFAMBAwIEAAQAgAMDBAAEMIADBAMFAwYDBwQAAIBAAwgDCQMKAwsDDAMNAw4DDwIAAAAAAADgPwgCDxAAAAAREgAAAAAIAAEYAAAAAAAAAQEAAAAAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAABAgAAAAAFCgAAAAAJAAABAgA/owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQEBJAYAAACkAggAAABwQE0DAGoJAAAATQMDUwoAAABNAwMzCwAAAJ8CAgKkAwgAAABwQE0EAGoJAAAATQQEUwoAAABNBASoDAAAAJ8DAgKkBAgAAABwQE0FAGoJAAAATQUF6A0AAABNBQVUDgAAAE0FBfgPAAAAnwQCAqQFCAAAAHBATQYAagkAAABNBgZNEAAAAE0GBmwRAAAATQYG+BIAAACfBQICTQYBHhMAAADACBQAEgACABIAAwASAAQAEgABABIABQC8BgbHFQAAAJ8GAwGCAAEAFgMQBAAAAEADEQMSAxMEAABAQAMUAxUEAABwQAMWAxcDGAMZAxoDGwMcAx0DHgMNAx8GAAMgAQABAAEYAAEAAAAAAAEAAAABAAAAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAPAQAAAAABrx7GY2uUnznxJrDRrq4vUd8G0Red2qxi

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local scriptParent = script.Parent
local GetMouseToWorld = require(ReplicatedStorage.Library.Functions.GetMouseToWorld)
local Manhattan2D = require(ReplicatedStorage.Library.Functions.Manhattan2D)
local PetsService = require(ReplicatedStorage.Library.Modules.PetServices.PetsService)
local Message = require(ReplicatedStorage.Library.Client.NotificationCmds.Message)

scriptParent.Activated:Connect(function() -- line: 8
	-- upvalues: GetMouseToWorld (copy), Manhattan2D (copy), PetsService (copy), scriptParent (copy), Message (copy)
	local v7 = GetMouseToWorld(RaycastParams.new(), 100.0)

	if v7 then
		local cFrame = CFrame.new(v7.Position.X, 0.0, v7.Position.Z)

		if Manhattan2D(cFrame.Position, workspace.PetArea) then
			PetsService:EquipPet(scriptParent:GetAttribute("PET_UUID"), cFrame)

			return
		end

		Message.Bottom({
			Message = "You cannot place your hero here!",
			Time = 0.5
		})
	end
end)

