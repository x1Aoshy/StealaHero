-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBnNjcmlwdAZTdHlsZXMMV2FpdEZvckNoaWxkG3JieGFzc2V0aWQ6Ly85MDc5NjAyNDU1NjYwMxtyYnhhc3NldGlkOi8vODEyMDM1NTE4MTY2NzIccmJ4YXNzZXRpZDovLzEyNzA4ODIzOTQzMDAzMgdhdGxhc2VzC2luZm9ybWF0aW9uBnN0eWxlcwZmYW1pbHkOU3VwZXIgTWFyaW8gNjQFc2l6ZXMIdXNlRW51bXMHUmVndWxhcgRmb250B3JlcXVpcmUAARQAAAEAAFGjAAAA/wACAAAAAACkAQEAAAAAQG8DAgC8AQHTAwAAAJ8BAwL/AgAAAwAAAG8DBAD2AwIAbwMFAPYDAgFvAwYA9gMCAjACANYHAAAA4gIKAOIDEAD/BAAAAQAAAG8FEQDFBAUCAQAAADAEA4EJAAAA/wQAAA8AAACMBWAAjAY8AIwHMACMCCoAjAkkAIwKIACMCxwAjAwYAIwNEgCMDg4AjA8MAIwQCwCMEQoAjBIJAIwTCADFBAUQAQAAADAEA+oNAAAAMAMCfggAAAD/AwAAAAAAADADAoEJAAAAMAIAGRIAAABNAgAZEgAAAE0CAn4IAAAATQICgQkAAADGAwAAxgQAAGQCDABNBwAZEgAAAE0HB4EJAAAApAgUAAAAMEFSCwYAvAkB0wMAAACfCQMAnwgAAmoIBwZuAvP/AgAAAIIAAgAVAwEEAAAAQAMCAwMDBAMFAwYDBwMIAwkFAggJAwoDCwMMAw0BAQgECwwAAAAJ/////w3/////Dg8AAAADDgMPAxAEAAAwQQABAAEYAAcAAQAAAAAAAgABAAEAAQD9AAYBAgAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAP0ABgAAAPkACgAAAAAAAAAAAQAAAAAAAAAAAAAA/wAEAQAAAAAA8ueETyU7Vw1I5qn7YsP8eYL/kzvAI+5O

-- decompilation:
local t1 = {}
local Styles = script:WaitForChild("Styles")

t1.atlases = {
	[1.0] = "rbxassetid://90796024556603",
	[2.0] = "rbxassetid://81203551816672",
	[3.0] = "rbxassetid://127088239430032"
}
t1.font = {
	information = {
		family = "Super Mario 64",
		useEnums = true,
		styles = { "Regular" },
		sizes = {
			96.0,
			60.0,
			48.0,
			42.0,
			36.0,
			32.0,
			28.0,
			24.0,
			18.0,
			14.0,
			12.0,
			11.0,
			10.0,
			9.0,
			8.0
		}
	},
	styles = {}
}

for _, v4 in t1.font.information.styles do
	t1.font.styles[v4] = require(Styles:WaitForChild(v4))
end

return t1

