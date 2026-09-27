-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMbBXRhYmxlBGZpbmQFZXJyb3IbZnVuY3Rpb24gYWxyZWFkeSBzdWJzY3JpYmVkBmluc2VydAR0YXNrBXNwYXduB0N1cnJlbnQHT2JzZXJ2ZQxTZXRQcmVmZXJyZWQFVG91Y2gETmFtZQZzdHJpbmcDc3ViBU1vdXNlDU1vdXNlS2V5Ym9hcmQHR2FtZXBhZBJEZXRlcm1pbmVQcmVmZXJyZWQEZ2FtZRBVc2VySW5wdXRTZXJ2aWNlCkdldFNlcnZpY2UERW51bQ1Vc2VySW5wdXRUeXBlCEtleWJvYXJkEEdldExhc3RJbnB1dFR5cGUUTGFzdElucHV0VHlwZUNoYW5nZWQHQ29ubmVjdAAFBgACAAAAEKQAAgAABACA+wEAAPsCAQCfAAMCDgAJAPsCAAAcAQIA+wIAAPsDAAD7BQAAhwQFAcYFAABqBAIAagUDAYIAAQADAwEDAgQABACAAFsAARgAAAAAAAEBAAEAAAAAAAACXAAAAAAEAQIAAAYDAAAFAQUdpAECAAAEAID7AgAAUgMAAJ8BAwIOAQUApAEEAAAAMEBvAgUAjAMCAJ8BAwH7AgAAnjQCBAAAAABSAwAApAEHAAAYAICfAQMBpAEKAAAkgIBSAgAA+wMBAE0DA4ELAAAAnwEDAdkBAAASAgAAEgAAAIIBAgAMAwEDAgQABACAAwMEAAAwQAMEAwUEABgAgAMGAwcEACSAgAMIAQBTCQEYAAAAAAAAAQAAAAACAAAAAAAAAgAAAAAAAAIAAABUAAAAAAkBAgAABgMAAAUBAxX7AQAATQEBgQAAAACaAAIAAQAAAIIAAQD7AQAAMAABgQAAAAD7AQEAxgIAAMYDAABkAQUApAYDAAAIEIBSBwUAUggAAJ8GAwFuAfr/AgAAAIIAAQAEAwgDBgMHBAAIEIAAZQoBGAAAAAAAAQIAAAIAAAABAAAAAP8AA2YAAAAABQEDAAAAJvsBAACaAAUAAQAAAPsBAQBvAgAAnwECAYIAAQD7AQIA8QALAAEAAABNAgC6AQAAAIwDAQCMBAUATC0AAqQBBAAADCCAnwEEAvABBQAFAACA+wEBAG8CBgCfAQIBggABAE0CALoBAAAAjAMBAIwEBwBMLQACpAEEAAAMIICfAQQC8AEEAAcAAID7AQEAbwIHAJ8BAgGCAAEACAMLAwwDDQMOBAAMIIADDwMQAxEAcBIBGAAAAAEAAAABAAAAAAAAAAAAAAAAAQAAAAEAAAAAAAAAAAABAAACcQAAAAAMAAABAgBKowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBwAGFEDApAIJAAgUQMDGAwAA/wQAAAAAAADiBQ0A2QYAABIABAASAQP/MAYFVAwAAABSAwUA2QUBABIBA/8SAAQAwAYOABIAAQASAAUAEgACALwHAG8PAAAAnwcCApoHBQABAAAAUggFAG8JBgCfCAIBZQAdAPEHCwACAAAATQkHuhAAAACMCgEAjAsFAEwtAAKkCBMAAEgQgZ8IBALwCAUAFAAAgFIIBQBvCQsAnwgCAWUADQBNCQe6EAAAAIwKAQCMCwcATC0AAqQIEwAASBCBnwgEAvAIBAAVAACAUggFAG8JFQCfCAIBTQcAixYAAABSCQYAvAcHxxcAAACfBwMBwQMAAIIDAgAYAxMEAAAAQAMUAxUDFgMXAwsEBhRAwAMYBAgUQMADCAMQAwkIAgoLAAAADP////8GAwMZAwwDDQMOBABIEIEDDwMRAxoDGwMBAgMBAAEYAA8AAAAAAAIAAQA4AgACBAAAAAAAEgAACwAAAAoAAPcAAQAAAAEAAAAAAAAAAAAAAAEAAAABAAAAAAAAAAAAAQAABQAAAAAAAgABAAAAAASHxJAlZ6tbUlTGgkBhkcOn99yHUbUA+iQ=

-- decompilation:
local UserInputService = game:GetService("UserInputService")
local Touch = Enum.UserInputType.Touch
local Keyboard = Enum.UserInputType.Keyboard
local t2 = nil
local t1 = {}

t2 = {
	Current = "MouseKeyboard",
	Observe = function(p1: ((...any) -> ...any)) -- line: 83
		-- upvalues: t1 (copy), t2 (ref)
		if table.find(t1, p1) then
			error("function already subscribed", 2.0)
		end

		table.insert(t1, p1)
		task.spawn(p1, t2.Current)

		return function() -- line: 91
			-- upvalues: t1 (copy), p1 (copy)
			local v14 = table.find(t1, p1)

			if v14 then
				local v15 = #t1
				local v16 = t1
				local v17 = t1

				v16[v14] = t1[v15]
				v17[v15] = nil
			end
		end
	end
}

local function SetPreferred(s1: string) -- line: 101
	-- upvalues: t2 (ref), t1 (copy)
	if s1 == t2.Current then
		return
	end

	t2.Current = s1

	for _, v12 in t1 do
		task.spawn(v12, s1)
	end
end
local function DeterminePreferred(p2) -- line: 112
	-- upvalues: Touch (copy), SetPreferred (copy), Keyboard (copy)
	if p2 == Touch then
		SetPreferred("Touch")

		return
	end

	if p2 == Keyboard or string.sub(p2.Name, 1.0, 5.0) == "Mouse" then
		SetPreferred("MouseKeyboard")

		return
	end

	if string.sub(p2.Name, 1.0, 7.0) == "Gamepad" then
		SetPreferred("Gamepad")
	end
end

local LastInputType = UserInputService:GetLastInputType()

if LastInputType == Touch then
	SetPreferred("Touch")
elseif LastInputType == Keyboard or string.sub(LastInputType.Name, 1.0, 5.0) == "Mouse" then
	SetPreferred("MouseKeyboard")
elseif string.sub(LastInputType.Name, 1.0, 7.0) == "Gamepad" then
	SetPreferred("Gamepad")
end

UserInputService.LastInputTypeChanged:Connect(DeterminePreferred)

return t2

