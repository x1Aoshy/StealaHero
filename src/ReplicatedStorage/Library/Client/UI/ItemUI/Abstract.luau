-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local Client = game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client")
local FFlags = require(Client.FFlags)

return {
	BottomOverlays = function(p1, p2, p3) -- line: 11
		-- upvalues: FFlags (copy)
		local v6 = p3 or {}
		local v7 = false

		if v6.Hot then
			if not v7 then
				table.insert(p1, { "Div" })
				v7 = true
			end

			table.insert(p1, { "Hot" })
		end

		if not v6.HideExists then
			local v8 = v6.ForceExists == true or p2.Class.Name == "Skin"
			local v9 = v6.ShowExists == true or v8

			if not v8 then
				if not FFlags.Get(FFlags.Keys.ExistCount) then
					v9 = false
				end

				if not FFlags.Get(FFlags.Keys.ExistCountOverlay) then
					v9 = false
				end
			end

			if v9 then
				local ExistCount = p2:GetExistCount()

				if ExistCount > 0.0 then
					if not v7 then
						table.insert(p1, { "Div" })
						v7 = true
					end

					table.insert(p1, {
						"Exists",
						ExistCount
					})
				end
			end
		end

		if not v6.HideRAP then
			local v11 = p2:IsRAPVisible()

			if not FFlags.Get(FFlags.Keys.RAP) then
				v11 = false
			end

			if not FFlags.Get(FFlags.Keys.RAPOverlay) then
				v11 = false
			end

			if not v11 then
			end
		end

		if not true then
		end

		if v6.ShowDeal then
			if not v7 then
				table.insert(p1, { "Div" })
				v7 = true
			end

			table.insert(p1, {
				"Deal",
				v6.ShowDeal
			})
		end

		local Mailbox = v6.Mailbox

		if Mailbox then
			local v13, v14, v15 = unpack(Mailbox)

			table.insert(p1, { "Div" })
			table.insert(p1, {
				"MessageDark",
				v13
			})
			table.insert(p1, {
				"Message",
				v14
			})
			table.insert(p1, {
				"Nickname",
				v15
			})
		end

		return v7
	end
}

