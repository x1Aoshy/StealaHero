-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcAS0Fc3BsaXQIdG9udW1iZXIZbWlzc2luZyB1c2VyaWQgZm9yIGtleSAlKgZmb3JtYXQGYXNzZXJ0BEVudW0NVGh1bWJuYWlsVHlwZR5taXNzaW5nIHRodW1ibmFpbCB0eXBlIGZvcjogJSoNVGh1bWJuYWlsU2l6ZR5taXNzaW5nIHRodW1ibmFpbCBzaXplIGZvcjogJSoVR2V0VXNlclRodW1ibmFpbEFzeW5jBHR5cGUGc3RyaW5nKHRodW1ibmFpbCB1cmwgaXMgbm90IGEgc3RyaW5nIGZvciBrZXkgJSoqdGh1bWJuYWlsIHVybCBsZW5ndGggaXMgaW52YWxpZCBmb3Iga2V5ICUqBE5hbWUDZ2V0BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdQbGF5ZXJzB0xpYnJhcnkMV2FpdEZvckNoaWxkB01vZHVsZXMHcmVxdWlyZQpTbWFydENhY2hlA25ldwADCwEBAAALAAACDwQXAQ8FJgFkbwMAALwBAOMBAAAAnwEDAhMDAQC7PgMCpAIDAAAAIECfAgICbwUEAFIHAAC8BQWNBQAAAJ8FAwKeAQIEBQAAAFIEAgCkAwcAAABgQJ8DAwGkBAoAACSAgBMFAQGHAwQFbwYLAFIIAAC8BgaNBQAAAJ8GAwKeAQMEBgAAAFIFAwCkBAcAAABgQJ8EAwGkBQ0AADCAgBMGAQKHBAUGbwcOAFIJAAC8BweNBQAAAJ8HAwKeAQQEBwAAAFIGBACkBQcAAABgQJ8FAwH7BQAAUgcCAFIIAwBSCQQAvAUFQw8AAACfBQUCuygFA1IJBQCkCBEAAAAAQZ8IAgLwCAIAEgAAAKkHAAGpBwEAbwgTAFIKAAC8CAiNBQAAAJ8IAwKeAQcDCAAAAKQGBwAAAGBAnwYDAakHAAAcCAUAjAkAAGAJBwAIAAAAHAgFAIwJZADUCAIACQAAAKkHAAGpBwEAbwgUAFIKAAC8CAiNBQAAAJ8IAwKeAQcDCAAAAKQGBwAAAGBAnwYDAakGAQBSBwUAggYDABUDAQMCAwMEAAAgQAMEAwUDBgQAAGBAAwcDCAQAJICAAwkDCgQAMICAAwsDDAMNBAAAAEEDDgMPAxAACQABGAAAAAABAAAAAAEAAAAAAAAAAAAAAQAAAAEAAAAAAAAAAAAAAQAAAAEAAAAAAAAAAAAAAQAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAKAAAAAAkDAQAACAUAAAUDAg8PFlIEAABvBQAATQYBugEAAABvBwAATQgCugEAAABzAwQI+wQAAE0EBF8CAAAAUgUDAMYGAACpBwEAnwQEAisEBQD7BAAATQQEXwIAAABSBQMAnwQCAoIEAgADAwEDEQMSABkAARgAAAAAAAAAAAEAAAAAAAAAAAAAAAAAGgAAAAAIAAABAgAlowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBAQAAAABAbwMEALwBARYDAAAAnwEDAm8EBQC8AgDTBgAAAJ8CAwJvBAcAvAIC0wYAAACfAgMCpAMJAAAAgEBNBAI5CgAAAJ8DAgJNAwPvCwAAAIwEDwCMBRAOjAY8AMAHDAASAAEAnwMFAsAEDQASAAMAggQCAA4DEwQAAABAAxQDFQMWAxcDGAMZAxoEAACAQAMbAxwGAAYBAgABAQABGAADAAAAAAABAAAAAAABAAAAAAAAAAMAAAAAAAAAAAAAAAAQAAABAAAAAAIYccqZVxn0mhl+Hi80a/FDaGnd7Sq1oJg=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = ReplicatedStorage:WaitForChild("Library"):WaitForChild("Modules")
local v4 = require(Modules.SmartCache).new(15.0, 3600.0, 60.0, function(p1) -- line: 9
	-- upvalues: Players (copy)
	local parts = p1:split("-")
	local num = tonumber(parts[1.0])

	assert(num, `missing userid for key { p1 }`)

	local v8 = Enum.ThumbnailType[parts[2.0]]

	assert(v8, `missing thumbnail type for: { p1 }`)

	local v9 = Enum.ThumbnailSize[parts[3.0]]

	assert(v9, `missing thumbnail size for: { p1 }`)

	local UserThumbnailAsync = Players:GetUserThumbnailAsync(num, v8, v9)

	assert(type(UserThumbnailAsync) == "string", `thumbnail url is not a string for key { p1 }`)
	assert(#UserThumbnailAsync > 0.0 and #UserThumbnailAsync <= 100.0, `thumbnail url length is invalid for key { p1 }`)

	return true, UserThumbnailAsync
end)

return function(n1: number, p2, p3) -- line: 25
	-- upvalues: v4 (copy)
	local v14 = n1 .. "-" .. p2.Name .. "-" .. p3.Name

	return v4.get(v14, nil, true) or v4.get(v14)
end

