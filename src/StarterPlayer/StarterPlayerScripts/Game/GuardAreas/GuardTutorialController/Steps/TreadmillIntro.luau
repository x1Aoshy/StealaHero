-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZGUhhc0ZpbmlzaGVkVHJlYWRtaWxsSW50cm8LSXNTYXRpc2ZpZWQaTWFya1RyZWFkbWlsbEludHJvRmluaXNoZWQEdGFzawVkZWxheQRCaW5kCENsZWFyQWxsJFVzZSB5b3VyIHRyZWFkbWlsbCB0byBiZWNvbWUgZmFzdGVyIRNTaG93QW5pbWF0ZWRNZXNzYWdlB1ByZXNlbnQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQZDbGllbnQiR3VhcmRUdXRvcmlhbFByZXNlbnRhdGlvbkNvbXBvbmVudAZzY3JpcHQGUGFyZW50BVR5cGVzCUludGVyZmFjZQZDb2xvcjMHZnJvbVJHQgZTdGVwSWQOVHJlYWRtaWxsSW50cm8ABwMBAAAAAAS8AQDxAAAAAJ8BAgCCAQAAAQMBABgCARgAAAAAGQAAAAACAAMAAAAK+wAAAA4AAQCCAAEA+wABALwAAFwAAAAAnwACAfsAAgCfAAEBggABAAEDAwAeAAEYAAABAgAAAAEAAR8AAAAAAQABAAAAA6kAAQDeAAAAggABAAAAJgABGAAAAScAAAAABgIAAAAHBAAABQIPBQ2pAgAApAMCAAAEAICMBAcA2QUAABIBAv8SAAAAEgABAJ8DAwHZAwEAEgEC/8ECAACCAwIAAwMEAwUEAAQAgAIBAhwGARgAAQAAAAAAAAAIAAAAHQAAAAACAAEAAAAF+wAAALwAAEsAAAAAnwACAYIAAQABAwcAMQABGAAAAAABMgAAAAAGAgEAAAAIbwQAAPsFAAC8AgCOAQAAAJ8CBAHZAgAAEgAAAIICAgACAwgDCQEEKwoBGAAAAAAAAgAALwAAAAAHAAABAgAtowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgJNBwAAAE0CAuUIAAAAnwECAqQCBQAAAEBApAMKAAAAkEBNAwMkCwAAAE0DA+8MAAAATQMDDw0AAACfAgICpAMQAAA84ICMBP8AjAX/AIwG/wCfAwQC4gQTAMAFFAAwBQQHFQAAAMAFFgAwBQSKFwAAAMAFGAASAAMAMAUEAhkAAACCBAIAGgMLBAAAAEADDAMNAw4EAABAQAMPAxADEQMSBAAAkEADEwMUAxUDFgMXBAA84IADGAMZCAEREgAAAAYAAwIGAwMGBgUDCgMAAwUBAAEYAAMAAAAAAAMAAAAAAAAAAAEAAAAAAAAAAAAABAAAAAAACAQAAAQAAA8AAAALAQAAAAAGb4oaaDFsc5mQphvTbeQg2B+SDRxdTnBp

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Library.Client.GuardTutorialPresentationComponent)
require(script.Parent.Types.Interface)

local color3 = Color3.fromRGB(255.0, 255.0, 255.0)

return {
	StepId = "TreadmillIntro",
	IsSatisfied = function(p1) -- line: 24
		return p1:HasFinishedTreadmillIntro()
	end,
	Bind = function(p2, p3: ((...any) -> ...any)) -- line: 28
		local u6 = false

		task.delay(7.0, function() -- line: 30
			-- upvalues: u6 (ref), p2 (copy), p3 (copy)
			if u6 then
				return
			end

			p2:MarkTreadmillIntroFinished()
			p3()
		end)

		return function() -- line: 38
			-- upvalues: u6 (ref)
			u6 = true
		end
	end,
	Present = function(p4, _) -- line: 43
		-- upvalues: color3 (copy)
		p4:ShowAnimatedMessage("Use your treadmill to become faster!", color3)

		return function() -- line: 49
			-- upvalues: p4 (copy)
			p4:ClearAll()
		end
	end
}

