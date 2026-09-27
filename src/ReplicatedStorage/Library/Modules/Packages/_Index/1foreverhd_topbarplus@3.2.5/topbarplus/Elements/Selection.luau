-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMpDVJvdGF0aW9uU3BlZWQMR2V0QXR0cmlidXRlDlNlbGVjdGVkT2JqZWN0Am9zBWNsb2NrCFJvdGF0aW9uCEluc3RhbmNlA25ldwVGcmFtZRJTZWxlY3Rpb25Db250YWluZXIETmFtZQdWaXNpYmxlCVNlbGVjdGlvbgZDb2xvcjMHZnJvbVJHQhBCYWNrZ3JvdW5kQ29sb3IzFkJhY2tncm91bmRUcmFuc3BhcmVuY3kMQm9yZGVyQ29sb3IzD0JvcmRlclNpemVQaXhlbAZQYXJlbnQIVUlTdHJva2UERW51bQ9BcHBseVN0cm9rZU1vZGUGQm9yZGVyBUNvbG9yCVRoaWNrbmVzcwpVSUdyYWRpZW50EVNlbGVjdGlvbkdyYWRpZW50CFVJQ29ybmVyCkNvbGxlY3RpdmULSWNvbkNvcm5lcnMMU2V0QXR0cmlidXRlBFVEaW0MQ29ybmVyUmFkaXVzBGdhbWUKUnVuU2VydmljZQpHZXRTZXJ2aWNlCkd1aVNlcnZpY2UZR2V0QXR0cmlidXRlQ2hhbmdlZFNpZ25hbAdDb25uZWN0CUhlYXJ0YmVhdAAEAwACAAAAB/sAAQBvAgAAvAAAEgEAAACfAAMC3gAAAIIAAQACAwEDAgAkAAEYAAAAAAAAASUAAAAABgADAAAAEPsAAABNAAAeAAAAACsAAQCCAAEA+wABAKQEBQAAEDCAnwQBAvsFAgAJAwQFWwIDAiEBAgEwAQA4BgAAAIIAAQAHAwMCAAAAAACAdkACAAAAAAAAWUADBAMFBAAQMIADBgAnAAEYAAAAAAECAAAAAAAAAAAAASgAAAAADAEAAAAAgQGkAQIAAAQAgG8CAwCfAQICbwIEADACAboFAAAAqQIAADACAYAGAAAApAICAAAEAIBvAwMAnwICAm8DBwAwAwK6BQAAAKQDCgAAJICAjAT/AIwF/wCMBv8AnwMEAjADAp8LAAAAjAMBADADAjoMAAAApAMKAAAkgICMBAAAjAUAAIwGAACfAwQCMAMCNA0AAACMAwAAMAMCjg4AAAAwAQIkDwAAAKQDAgAABACAbwQQAJ8DAgJvBBAAMAQDugUAAACkBBQAE0gQwTAEAygSAAAApAQKAAAkgICMBf8AjAb/AIwH/wCfBAQCMAQDpBUAAACMBAMAMAQDGBYAAAAwAgMkDwAAAKQEAgAABACAbwUXAJ8EAgJvBRgAMAUEugUAAAAwAwQkDwAAAKQFAgAABACAbwYZAJ8FAgJvCBoAbwkbALwGBS4cAAAAnwYEAW8GGQAwBgW6BQAAAKQGHgAABNCBjAcBAIwIAACfBgMCMAYFTx8AAAAwAgUkDwAAAKQGIQAAAABCbwgiALwGBhYjAAAAnwYDAqQHIQAAAABCbwkkALwHBxYjAAAAnwcDAowIAQBvCyUAvAkCFiYAAACfCQMC2QsAABIBCP8SAAIAvAkJxycAAACfCQMBTQkG/SgAAADZCwEAEgAHABIABAASAQj/vAkJxycAAACfCQMBwQgAAIIBAgApAwcDCAQABACAAwkDCgMLAwwDDQMOAw8EACSAgAMQAxEDEgMTAxQDFQMWAxcDGAQTSBDBAxkDGgMbAxwDHQMeAx8DIAMhBAAE0IEDIgMjBAAAAEIDJAMlAyYDAQMnAygDKQIAAQEAARgAAAAAAQAAAQAAAgAAAAEAAAEAAAAAAAAAAQAAAQAAAAAAAAABAAABAAIAAAABAAABAAAAAQAAAAAAAAABAAABAAIAAAABAAABAAIAAAABAAAAAAEAAAEAAAAAAAABAAIAAAAAAAEAAAAAAAEBAAAAAAAAAAAAAwAAAAAAAAAABwAEAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgIBAgEAARgAAAABAAAAAAPtaRgIMHjm0B5Sh+NgoExrnXEPfN+tcgk=

-- decompilation:
return function(_) -- line: 1
	local Frame = Instance.new("Frame")

	Frame.Name = "SelectionContainer"
	Frame.Visible = false

	local Frame2 = Instance.new("Frame")

	Frame2.Name = "Selection"
	Frame2.BackgroundColor3 = Color3.fromRGB(255.0, 255.0, 255.0)
	Frame2.BackgroundTransparency = 1.0
	Frame2.BorderColor3 = Color3.fromRGB(0.0, 0.0, 0.0)
	Frame2.BorderSizePixel = 0.0
	Frame2.Parent = Frame

	local UIStroke = Instance.new("UIStroke")

	UIStroke.Name = "UIStroke"
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Color = Color3.fromRGB(255.0, 255.0, 255.0)
	UIStroke.Thickness = 3.0
	UIStroke.Parent = Frame2

	local UIGradient = Instance.new("UIGradient")

	UIGradient.Name = "SelectionGradient"
	UIGradient.Parent = UIStroke

	local UICorner = Instance.new("UICorner")

	UICorner:SetAttribute("Collective", "IconCorners")
	UICorner.Name = "UICorner"
	UICorner.CornerRadius = UDim.new(1.0, 0.0)
	UICorner.Parent = Frame2

	local RunService = game:GetService("RunService")
	local GuiService = game:GetService("GuiService")
	local n1 = 1.0

	Frame2:GetAttributeChangedSignal("RotationSpeed"):Connect(function() -- line: 36
		-- upvalues: n1 (ref), Frame2 (copy)
		n1 = Frame2:GetAttribute("RotationSpeed")
	end)
	RunService.Heartbeat:Connect(function() -- line: 39
		-- upvalues: GuiService (copy), UIGradient (copy), n1 (ref)
		if not GuiService.SelectedObject then
			return
		end

		UIGradient.Rotation = os.clock() * n1 * 100.0 % 360.0
	end)

	return Frame
end

