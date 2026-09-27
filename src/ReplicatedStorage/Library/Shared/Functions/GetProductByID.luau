-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMQBXBhaXJzCURpcmVjdG9yeQlQcm9kdWN0SWQFZXJyb3IaRHVwbGljYXRlIFByb2R1Y3Q6ICUqIC8gJSoGZm9ybWF0BmFzc2VydANfaWQOR2V0UHJvZHVjdEJ5SUQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUIUHJvZHVjdHMFVHlwZXMJSW50ZXJmYWNlAAIMAQIAAAoDAAEFAQIDCBYCLvsBAABHAR4AAAAAgP8BAAAAAAAApAIBAAAAAED7AwEATQMDkQIAAACfAgIEFwIRAE0IBgsDAAAAhwcBCA4HCgCkBwUAAABAQG8IBgBSCgUATQsGCwMAAAC8CAiNBwAAAJ8IBACfBwABTQcGCwMAAABqBgEHbgLu/wIAAADeAQAA+wMAALsBAwKkAgkAAACAQJ8CAgKHAQIADgEEAFICAQBNAwHTCgAAAIICAwDGAgAAxgMAAIICAwALAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHBAAAgEADCAARCQEYAAAAAQABAAAAAAAAAQAAAAEAAAAAAAAAAAACAAD8AAYDAAAAAAABAQAAAAMAABIAAAAABQAAAQIAH6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQUAAABAQE0CAJEGAAAATQICQQcAAACfAQICpAIFAAAAQEBNAwCRBgAAAE0DA0EHAAAATQMD7wgAAABNAwMPCQAAAJ8CAgLGAwAA2QQAABIBA/8SAAEAwQMAAIIEAgAKAwoEAAAAQAMLAwwDDQQAAEBAAwIDDgMPAxABAAEAARgAAwAAAAAAAwAAAAAAAAEAAAAAAAAAAAAAAwYAABQAAQAAAAABlIl3oePYARdEay9jGEvXMOSRYNWmTR2g

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicatedStorage.Directory.Products)

require(ReplicatedStorage.Directory.Products.Types.Interface)

local u3 = nil

local function GetProductByID(n1: number) -- line: 17
	-- upvalues: u3 (ref), Products (copy)
	if u3 == nil then
		local t1 = {}

		for k, v in pairs(Products.Directory) do
			if t1[v.ProductId] then
				error(`Duplicate Product: { k } / { v.ProductId }`)
			end

			t1[v.ProductId] = v
		end

		u3 = t1
	end

	local v9 = assert(u3)[n1]

	if v9 then
		return v9, v9._id
	end

	return nil, nil
end

return GetProductByID

