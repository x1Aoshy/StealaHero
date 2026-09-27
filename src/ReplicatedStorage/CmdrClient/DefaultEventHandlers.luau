-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTFUNoYXRNYWtlU3lzdGVtTWVzc2FnZQRUZXh0BUNvbG9yEVtBbm5vdW5jZW1lbnRdICVzBmZvcm1hdAZDb2xvcjMHZnJvbVJHQgdTZXRDb3JlB0FkZExpbmUHTWVzc2FnZQtIYW5kbGVFdmVudARnYW1lClN0YXJ0ZXJHdWkKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQNQ21kckludGVyZmFjZQZXaW5kb3cABAkBAQAABwAAAQMFBQIW+wEAAG8DAADiBAMAbwUEAFIHAAC8BQWNBQAAAJ8FAwIwBQT1AQAAAKQFCAAAHGCAjAb5AIwH2QCMCDgAnwUEAjAFBKQCAAAAvAEBvwkAAACfAQQBggABAAoDAQMCAwMFAgECAwQDBQMGAwcEABxggAMIAAUAARgAAAABAAAAAAAAAQAAAAAAAAD+AAAEBgAAAAADAAEBAAAHowAAAPsAAADdAgAAvAAAaAAAAACfAAABggABAAEDCQAMAAEYAAEAAAAAAQwAAAAABQECAAAADW8DAADABAEAEgIAALwBAJQCAAAAnwEEAW8DAwDABAQAEgIBALwBAJQCAAAAnwEEAYIAAQAFAwoGAAMLAwkGAQIAAQQAARgAAAAAAAAHAAAAAAADBQAAAAADAAABAgAWowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAuwJAAAATQICZQoAAACfAQICwAILABIAAAASAAEAggICAAwDDAQAAABAAw0DDgMPBAAAQEADEAQAAGBAAxEDEgMTBgIBAgEAARgAAAAAAAAAAQAAAAAAAAAAAAACAAAAAQAAAAADpFYkylEf8NfeAx694zCaXNROM76Wkk7L

-- decompilation:
local StarterGui = game:GetService("StarterGui")
local Window = require(script.Parent.CmdrInterface.Window)

return function(p1) -- line: 4
	-- upvalues: StarterGui (copy), Window (copy)
	p1:HandleEvent("Message", function(p2) -- line: 5
		-- upvalues: StarterGui (copy)
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = ("[Announcement] %s"):format(p2),
			Color = Color3.fromRGB(249.0, 217.0, 56.0)
		})
	end)
	p1:HandleEvent("AddLine", function(...) -- line: 12
		-- upvalues: Window (copy)
		Window:AddLine(...)
	end)
end

