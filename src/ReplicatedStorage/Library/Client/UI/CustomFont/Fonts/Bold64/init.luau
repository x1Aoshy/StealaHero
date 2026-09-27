-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBnNjcmlwdAZTdHlsZXMMV2FpdEZvckNoaWxkHHJieGFzc2V0aWQ6Ly8xMDgzMDUxNTc3MjAyNjUccmJ4YXNzZXRpZDovLzExODU2MzYzNjU1NzY4MhxyYnhhc3NldGlkOi8vMTE2MjA5MDMxMDk3MjcwB2F0bGFzZXMLaW5mb3JtYXRpb24Gc3R5bGVzBmZhbWlseQZCb2xkNjQFc2l6ZXMIdXNlRW51bXMHUmVndWxhcgRmb250B3JlcXVpcmUAARQAAAEAAFGjAAAA/wACAAAAAACkAQEAAAAAQG8DAgC8AQHTAwAAAJ8BAwL/AgAAAwAAAG8DBAD2AwIAbwMFAPYDAgFvAwYA9gMCAjACANYHAAAA4gIKAOIDEAD/BAAAAQAAAG8FEQDFBAUCAQAAADAEA4EJAAAA/wQAAA8AAACMBWAAjAY8AIwHMACMCCoAjAkkAIwKIACMCxwAjAwYAIwNEgCMDg4AjA8MAIwQCwCMEQoAjBIJAIwTCADFBAUQAQAAADAEA+oNAAAAMAMCfggAAAD/AwAAAAAAADADAoEJAAAAMAIAGRIAAABNAgAZEgAAAE0CAn4IAAAATQICgQkAAADGAwAAxgQAAGQCDABNBwAZEgAAAE0HB4EJAAAApAgUAAAAMEFSCwYAvAkB0wMAAACfCQMAnwgAAmoIBwZuAvP/AgAAAIIAAgAVAwEEAAAAQAMCAwMDBAMFAwYDBwMIAwkFAggJAwoDCwMMAw0BAQgECwwAAAAJ/////w3/////Dg8AAAADDgMPAxAEAAAwQQABAAEYAAcAAQAAAAAAAgABAAEAAQD9AAYBAgAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAP0ABgAAAPkACgAAAAAAAAAAAQAAAAAAAAAAAAAA/wAEAQAAAAAAMMMJeeHEaHU25s/YPCt5BkDbHg0CB2N4

-- decompilation:
local t1 = {}
local Styles = script:WaitForChild("Styles")

t1.atlases = {
	[1.0] = "rbxassetid://108305157720265",
	[2.0] = "rbxassetid://118563636557682",
	[3.0] = "rbxassetid://116209031097270"
}
t1.font = {
	information = {
		family = "Bold64",
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

