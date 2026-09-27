-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVBGZ1bmMFZXZlbnQGcGFyZW50CEluc3RhbmNlA25ldw5SZW1vdGVGdW5jdGlvbgROYW1lBnNjcmlwdAZQYXJlbnQMV2FpdEZvckNoaWxkA0lzQRhleHBlY3RlZCByZW1vdGUgZnVuY3Rpb24GYXNzZXJ0C1JlbW90ZUV2ZW50FWV4cGVjdGVkIHJlbW90ZSBldmVudARnYW1lClJ1blNlcnZpY2UKR2V0U2VydmljZQhJc1NlcnZlcgV0YWJsZQZmcmVlemUABgQBAgAABgMAAAUBAwf7AQAATQEBZgAAAABSAgAA+wMBAJ8BAwCCAQAAAQMBAG0AARgAAAAAAAAAbgAAAAAEAQIAAAYDAAAFAQMH+wEAAE0BAdYAAAAAUgIAAPsDAQCfAQMAggEAAAEDAgBvAAEYAAAAAAAAAHAAAAAAAwEBAAAGAwAABQEHB9kBAAASAgAAEgAAANkCAQASAgAAEgAAAIIBAwAAAgABbAMBGAAAAAIAAABtAAAAAAcCAQAABwQAAAUCAwcnxgIAAPsDAAAOAw8ApAMCAAAEAIBvBAMAnwMCAlICAwAwAAK6BAAAAA4BAgBSAwEAZQACAKQDBgAAAFBAMAMCJAcAAACCAgIADgECAFIDAQBlAAIApAMGAAAAUEBSBQAAvAMD0wgAAACfAwMCUgIDAG8GAwC8BAL+CQAAAJ8EAwKBAQQECgAAAG8FCgCkAwwAAACwQJ8DAwGCAgIADQMEAwUEAAQAgAMGAwcDCAQAAFBAAwkDCgMLAwwDDQQAALBAAHoBARgAAQABAAAAAAEAAQAAAAAAAAACAAAAAAAAAAAAAQAAAAAAAAAAAAJ7AAAAAAcCAQAABwQAAAUCA4cnxgIAAPsDAAAOAw8ApAMCAAAEAIBvBAMAnwMCAlICAwAwAAK6BAAAAA4BAgBSAwEAZQACAKQDBgAAAFBAMAMCJAcAAACCAgIADgECAFIDAQBlAAIApAMGAAAAUEBSBQAAvAMD0wgAAACfAwMCUgIDAG8GAwC8BAL+CQAAAJ8EAwKBAQQECgAAAG8FCgCkAwwAAACwQJ8DAwGCAgIADQMEAwUEAAQAgAMOAwcDCAQAAFBAAwkDCgMLAw8DDQQAALBAAI0BAgEYAAEAAQAAAAABAAEAAAAAAAAAAgAAAAAAAAAAAAEAAAAAAAAAAAACjgAAAAAEAAABAgAdowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADArwAAAsEAAAAnwACAv8BAwAAAAAAwAIFABIAAQAwAgHEBgAAAMACBwASAAAAMAIBZggAAADAAgkAEgAAADACAdYKAAAApAINAAAwsIBSAwEAnwICAYIBAgAOAxAEAAAAQAMRAxIDEwYCAwMGAwMBBgQDAgMUAxUEADCwgAMCAwQBAAEYACwAAAAAAAAAADAADwAAAA4AAAATAAAADQAAAAIBAAAAAAXmcberLImEHs1NKfNG2y/Llmmg39S13ao=

-- decompilation:
local v1 = game:GetService("RunService"):IsServer()
local t1 = {}

function t1.parent(p1) -- line: 108
	-- upvalues: t1 (copy)
	return function(s1: string) -- line: 109
		-- upvalues: t1 (copy), p1 (copy)
		return t1.func(s1, p1)
	end, function(s2: string) -- line: 111
		-- upvalues: t1 (copy), p1 (copy)
		return t1.event(s2, p1)
	end
end
function t1.func(s3: string, p2) -- line: 122
	-- upvalues: v1 (copy)
	if v1 then
		local RemoteFunction = Instance.new("RemoteFunction")

		RemoteFunction.Name = s3
		RemoteFunction.Parent = p2 or script

		return RemoteFunction
	end

	local s3_2 = (p2 or script):WaitForChild(s3)

	assert(s3_2:IsA("RemoteFunction"), "expected remote function")

	return s3_2
end
function t1.event(s4: string, p3) -- line: 141
	-- upvalues: v1 (copy)
	if v1 then
		local RemoteEvent = Instance.new("RemoteEvent")

		RemoteEvent.Name = s4
		RemoteEvent.Parent = p3 or script

		return RemoteEvent
	end

	local s4_2 = (p3 or script):WaitForChild(s4)

	assert(s4_2:IsA("RemoteEvent"), "expected remote event")

	return s4_2
end

table.freeze(t1)

return t1

