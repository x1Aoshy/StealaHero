-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMfDEhhc1BsYWNlZFBldAtJc1NhdGlzZmllZBRCaW5kT25BZGFwdGVyQ2hhbmdlZARCaW5kEUhhc1BldEluSW52ZW50b3J5CENsZWFyQWxsD1BsYWNlIHlvdXIgUGV0IRNTaG93QW5pbWF0ZWRNZXNzYWdlEkhhc1BldFRvb2xFcXVpcHBlZBVTZXRTY3JlZW5DbGlja1Zpc2libGUTcmVmcmVzaFByZXNlbnRhdGlvbgpEaXNjb25uZWN0B0NoYW5nZWQHQ29ubmVjdAdQcmVzZW50BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50Ikd1YXJkVHV0b3JpYWxQcmVzZW50YXRpb25Db21wb25lbnQGc2NyaXB0BlBhcmVudAlTdGVwVXRpbHMFVHlwZXMJSW50ZXJmYWNlBkNvbG9yMwdmcm9tUkdCBlN0ZXBJZAhQbGFjZVBldAAGAwEAAAAABLwBADUAAAAAnwECAIIBAAABAwEAGAIBGAAAAAAZAAAAAAYCAgAABwQAAAUCDwUK+wIAAE0CAkcAAAAAUgMAAPsEAQBNBAQHAQAAAFIFAQCfAgQAggIAAAIDAwMCABwEARgAAAAAAAAAAAAAHQAAAAAEAAQAAAAf+wAAAE0AAAcAAAAA+wEBAJ8AAgIrAAUA+wABALwAAGgBAAAAnwACAisABQD7AAIAvAAASwIAAACfAAIBggABAPsAAgBvAgMA+wMDALwAAI4EAAAAnwAEAfsAAgD7AgEAvAICPQUAAACfAgIAvAAAkwYAAACfAAABggABAAcDAgMFAwYDBwMIAwkDCgAkCwEYAAAAAAAAAAAAAAABAAAAAQMAAAAAAAEAAAAAAAAAASUAAAAAAgACAAAACfsAAAC8AAAaAAAAAJ8AAgH7AAEAvAAASwEAAACfAAIBggABAAIDDAMGADEAARgAAAAAAQAAAAEyAAAAAAYCAgAAABHZAgAAEgIAABIAAQASAAAAEgIBAE0DAYUAAAAAUgUCALwDA8cBAAAAnwMDAlIEAgCfBAEB2QQBABIAAwASAAAAggQCAAIDDQMOAgIDIA8BGAAAAAAACgAAAAAAAQACAAAAJAAAAAAIAAABAgA7owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgJNBwAAAE0CAuUIAAAAnwECAqQCBQAAAEBApAMKAAAAkEBNAwMkCwAAAE0DAyQLAAAATQMDzgwAAACfAgICpAMFAAAAQECkBAoAAACQQE0EBCQLAAAATQQE7w0AAABNBAQPDgAAAJ8DAgKkBBEAAEDwgIwF/wCMBv8AjAf/AJ8EBALiBRQAwAYVADAGBQcWAAAAwAYXABIAAgASAAUAMAYFihgAAADABhkAEgAFABIABAAwBgUCGgAAAIIFAgAbAxAEAAAAQAMRAxIDEwQAAEBAAxQDFQMWAxcEAACQQAMYAxkDGgMbAxwDHQQAQPCAAx4DHwgBEhMAAAAGAAMCBgEDBAYEAw8DAAEEAQABGAADAAAAAAADAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAwAAAAAACAQAAAQAAAAABAAAAAAXAQAAAAAFWHPf+H4bAs6lkimvVWgwmShryIxqt7X5

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Client.GuardTutorialPresentationComponent)

local StepUtils = require(script.Parent.Parent.StepUtils)

require(script.Parent.Types.Interface)

local color3 = Color3.fromRGB(255.0, 255.0, 255.0)
local t1 = {
	StepId = "PlacePet",
	IsSatisfied = function(p1) -- line: 24
		return p1:HasPlacedPet()
	end
}

function t1.Bind(p2, p3: ((...any) -> ...any)) -- line: 28
	-- upvalues: StepUtils (copy), t1 (copy)
	return StepUtils.BindOnAdapterChanged(p2, t1.IsSatisfied, p3)
end
function t1.Present(p4, p5) -- line: 32
	-- upvalues: t1 (copy), color3 (copy)
	local function refreshPresentation() -- line: 36
		-- upvalues: t1 (copy), p5 (copy), p4 (copy), color3 (copy)
		if t1.IsSatisfied(p5) or not p5:HasPetInInventory() then
			p4:ClearAll()

			return
		end

		p4:ShowAnimatedMessage("Place your Hero!", color3)
		p4:SetScreenClickVisible(p5:HasPetToolEquipped())
	end

	local connection = p5.Changed:Connect(refreshPresentation)

	refreshPresentation()

	return function() -- line: 49
		-- upvalues: connection (copy), p4 (copy)
		connection:Disconnect()
		p4:ClearAll()
	end
end

return t1

