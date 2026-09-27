-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMeDEhhc1BsYWNlZEVnZwtJc1NhdGlzZmllZBRCaW5kT25BZGFwdGVyQ2hhbmdlZARCaW5kCENsZWFyQWxsD1BsYWNlIHlvdXIgRWdnIRNTaG93QW5pbWF0ZWRNZXNzYWdlHkdldEVnZ1BsYWNlbWVudEJpbGxib2FyZENGcmFtZRJTaG93QmlsbGJvYXJkQ2xpY2sTcmVmcmVzaFByZXNlbnRhdGlvbgpEaXNjb25uZWN0B0NoYW5nZWQHQ29ubmVjdAdQcmVzZW50BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkGQ2xpZW50Ikd1YXJkVHV0b3JpYWxQcmVzZW50YXRpb25Db21wb25lbnQGc2NyaXB0BlBhcmVudAlTdGVwVXRpbHMFVHlwZXMJSW50ZXJmYWNlBkNvbG9yMwdmcm9tUkdCBlN0ZXBJZAhQbGFjZUVnZwAGAwEAAAAABLwBAAgAAAAAnwECAIIBAAABAwEAGAIBGAAAAAAZAAAAAAYCAgAABwQAAAUCDwUK+wIAAE0CAkcAAAAAUgMAAPsEAQBNBAQHAQAAAFIFAQCfAgQAggIAAAIDAwMCABwEARgAAAAAAAAAAAAAHQAAAAAEAAQAAAAd+wAAAE0AAAcAAAAA+wEBAJ8AAgIOAAUA+wACALwAAEsBAAAAnwACAYIAAQD7AAIAbwICAPsDAwC8AACOAwAAAJ8ABAH7AAEAvAAAlgQAAACfAAICRwAGAAAAAAD7AQIAUgMAALwBAVoFAAAAnwEDAYIAAQAGAwIDBQMGAwcDCAMJACQKARgAAAAAAAABAAAAAQMAAAAAAAEAAAABAAEAAAAAAiUAAAAAAgACAAAACfsAAAC8AAAaAAAAAJ8AAgH7AAEAvAAASwEAAACfAAIBggABAAIDCwMFADQAARgAAAAAAQAAAAE1AAAAAAgCAgAAACfZAgAAEgIAABIAAQASAAAAEgIBAE0DAYUAAAAAUgUCALwDA8cBAAAAnwMDAvsEAABNBAQHAgAAAFIFAQCfBAICDgQEALwEAEsDAAAAnwQCAWUADgBvBgQA+wcBALwEAI4FAAAAnwQEAbwEAZYGAAAAnwQCAkcEBQAAAAAAUgcEALwFAFoHAAAAnwUDAdkEAQASAAMAEgAAAIIEAgAIAwwDDQMCAwUDBgMHAwgDCQICAyAOARgAAAAAAA0AAAAAAPQAAAAAAAEAAAEDAAAAAAEAAAEAAQAAAAcAAAAkAAAAAAgAAAECADujAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAk0HAAAATQIC5QgAAACfAQICpAIFAAAAQECkAwoAAACQQE0DAyQLAAAATQMDJAsAAABNAwPODAAAAJ8CAgKkAwUAAABAQKQECgAAAJBATQQEJAsAAABNBATvDQAAAE0EBA8OAAAAnwMCAqQEEQAAQPCAjAX/AIwG/wCMB/8AnwQEAuIFFADABhUAMAYFBxYAAADABhcAEgACABIABQAwBgWKGAAAAMAGGQASAAUAEgAEADAGBQIaAAAAggUCABsDDwQAAABAAxADEQMSBAAAQEADEwMUAxUDFgQAAJBAAxcDGAMZAxoDGwMcBABA8IADHQMeCAESEwAAAAYAAwIGAQMEBgQDDgMAAQQBAAEYAAMAAAAAAAMAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAADAAAAAAAIBAAABAAAAAAEAAAAABoBAAAAAAWoW0V6oouFCbAM/mn/wgQR2ENSDpqfL3s=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Client.GuardTutorialPresentationComponent)

local StepUtils = require(script.Parent.Parent.StepUtils)

require(script.Parent.Types.Interface)

local color3 = Color3.fromRGB(255.0, 255.0, 255.0)
local t1 = {
	StepId = "PlaceEgg",
	IsSatisfied = function(p1) -- line: 24
		return p1:HasPlacedEgg()
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
		if t1.IsSatisfied(p5) then
			p4:ClearAll()

			return
		end

		p4:ShowAnimatedMessage("Place your Egg!", color3)

		local EggPlacementBillboardCFrame = p5:GetEggPlacementBillboardCFrame()

		if EggPlacementBillboardCFrame ~= nil then
			p4:ShowBillboardClick(EggPlacementBillboardCFrame)
		end
	end

	local connection = p5.Changed:Connect(refreshPresentation)

	if t1.IsSatisfied(p5) then
		p4:ClearAll()
	else
		p4:ShowAnimatedMessage("Place your Egg!", color3)

		local EggPlacementBillboardCFrame = p5:GetEggPlacementBillboardCFrame()

		if EggPlacementBillboardCFrame ~= nil then
			p4:ShowBillboardClick(EggPlacementBillboardCFrame)
		end
	end

	return function() -- line: 52
		-- upvalues: connection (copy), p4 (copy)
		connection:Disconnect()
		p4:ClearAll()
	end
end

return t1

