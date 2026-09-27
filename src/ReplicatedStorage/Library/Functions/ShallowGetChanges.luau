-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBnR5cGVvZgV0YWJsZQhTa2lwS2V5cxBEZWVwRXF1YWxzVW5zYWZlBXBhaXJzB3JlcXVpcmUGc2NyaXB0BlBhcmVudApEZWVwRXF1YWxzAAIPAwIAAAgFAAAFAwQEBGi7LAADUgQAAKQDAQAAAABAnwMCAvADCAACAACAuywBA1IEAQCkAwEAAAAAQJ8DAgLwAwYAAgAAAP8DAAAAAAAA/wQAAAAAAACCAwMAuywCA1IFAgCkBAEAAAAAQJ8EAgLwBAMAAgAAgFIDAgArAwIA/wMAAAAAAABSAgMATQMCXAMAAAD/BAAAAAAAAFIFAQDGBgAAxgcAAGQFLQAOAwIAhwoDCCsKKgCHCgAI8QooAAkAAAC7LAkDUg0JAKQMAQAAAABAnwwCArssCgNSDgoApA0BAAAAAECfDQIC8QwDAA0AAACpCwEAZQAXALssCQNSDQkApAwBAAAAAECfDAIC8AwQAAIAAIBNDAIYBAAAAA4MBgD7DAAAUg0JAFIOCgCfDAMCVgsMAGUABwD7DAEAUg0JAFIOCgCfDAMCVgsMAGUAAQCpCwEADgsBAGoJBAhuBdL/AgAAAP8FAAAAAAAApAYGAAAAUEBSBwAAnwYCBBcGCAAOAwIAhwsDCSsLBQCHCwEJRwsDAAAAAICpCwEAagsFCW4G9/8BAAAAggQDAAcDAQQAAABAAwIDAwMEAwUEAABQQAAOAAEYAAAAAAAAAAAAAAAAAAABAAAAAAIAAAAAAAAAAAAAAAEAAgABAAAAAQAABAEABAAAAAAAAAAAAAAAAQABAAAAAAAAAAAAAQAAAAAAAQAAAAAAAQID7AAXAAEAAAAAAQAABAAAAQD6AAoPAAAAAAMAAAECABejAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBswUAAACfAAICpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICGAYAAACfAQICwAIHABIAAQASAAAAggICAAgDBgQAAABAAwcEAAAgQAMIAwkDBAYAAQABAAEYAAMAAAAAAAAAAAEAAAAAAAAAAAkAAAABAAAAAAH4R7VsQ1pZvB66uvmTB9/tiF+iGMqD320=

-- decompilation:
local DeepEquals = require(script.Parent.DeepEquals)
local DeepEqualsUnsafe = require(script.Parent.DeepEqualsUnsafe)

return function(t1: {[any]: any}, t2: {[any]: any}, t3: {[any]: any}) -- line: 14
	-- upvalues: DeepEqualsUnsafe (copy), DeepEquals (copy)
	if typeof(t1) ~= "table" or typeof(t2) ~= "table" then
		return {}, {}
	end

	local v6 = typeof(t3) == "table" and t3 or {}
	local SkipKeys = v6.SkipKeys
	local t4 = {}

	for v9, v10 in t2 do
		if not SkipKeys or not SkipKeys[v9] then
			local v11 = t1[v9]

			if v11 ~= v10 and (typeof(v10) ~= typeof(v11) or typeof(v10) ~= "table" or if not v6.DeepEqualsUnsafe then not DeepEquals(v10, v11) else not DeepEqualsUnsafe(v10, v11)) then
				t4[v9] = v10
			end
		end
	end

	local t5 = {}

	for k in pairs(t1) do
		if (not SkipKeys or not SkipKeys[k]) and t2[k] == nil then
			t5[k] = true
		end
	end

	return t4, t5
end

