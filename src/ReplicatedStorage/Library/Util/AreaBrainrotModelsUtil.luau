-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRCXdvcmtzcGFjZQ5Xb3JsZEFzc2V0TW9icw5GaW5kRmlyc3RDaGlsZAZpcGFpcnMLR2V0Q2hpbGRyZW4FTW9kZWwDSXNBB1NwYXduSWQMR2V0QXR0cmlidXRlEEdldEJyYWlucm90TW9kZWwIR2V0UGl2b3QOR2V0RXh0ZW50c1NpemUIUG9zaXRpb24BWQdWZWN0b3IzA25ldw5HZXRUb3BQb3NpdGlvbgADCgEAAAAGAwAABQEDIKQBAQAAAABAbwMCALwBAQMDAAAAnwEDAisBAgDGAgAAggICAKQCBQAAAEBAvAMBaAYAAACfAwIAnwIABFECDABvCQcAvAcG/ggAAACfBwMCDgcHAG8JCQC8BwYSCgAAAJ8HAwKaBwIAAAAAAIIGAgBuAvP/AgAAgMYCAACCAgIACwMBBAAAAEADAgMDAwQEAABAQAMFAwYDBwMIAwkABQoBGAAAAAAAAAEBAAMAAAAAAAABAAAAAAEAAAABAAH8AAgABgAAAAAJAQAAAAoDAAEFAQcIBREBE7wBAFIAAAAAnwECArwCAKUBAAAAnwICAk0EATsCAAAAjAYAAE0IAngEAAAAWwcIA4wIAABMNgACpAUHAAAYUICfBQQCQwMEBYIDAgAIAwsDDAMNAgAAAAAAAOA/Aw4DDwMQBAAYUIAAFhEBGAAAAAEAAAEAAAAAAAAAAAAAAAAXAAAAAAIAAAECAAqjAAAA/wACAAAAAADAAQAAMAEAdAEAAADAAQIAMAEAYQMAAACCAAIABAYAAwoGAQMRAgABAQABGAACAAIAABEAAAYBAAAAAALRvzchR47g7Zf51ofnl4wBoacgVeN7XSA=

-- decompilation:
return {
	GetBrainrotModel = function(s1: string) -- line: 5
		local WorldAssetMobs = workspace:FindFirstChild("WorldAssetMobs")

		if not WorldAssetMobs then
			return nil
		end

		for _, child in ipairs(WorldAssetMobs:GetChildren()) do
			if child:IsA("Model") and s1 == child:GetAttribute("SpawnId") then
				return child
			end
		end

		return nil
	end,
	GetTopPosition = function(p1) -- line: 22
		local Pivot = p1:GetPivot()
		local ExtentsSize = p1:GetExtentsSize()

		return Pivot.Position + Vector3.new(0.0, ExtentsSize.Y * 0.5, 0.0)
	end
}

