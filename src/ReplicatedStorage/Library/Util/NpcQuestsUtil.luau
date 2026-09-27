-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSBnR5cGVvZgV0YWJsZQZUZW5zb3IKX19kYXRhYmFzZQ9NZXJnZWRfUGFja2FnZXMHX19TcG9vZgRmaW5kBVRva2VuDEVycm9yX1Rva2VucwxJTlZBTElEX05PREUITW9kaWZpZXIRSW5jcmVtZW50UHJvZ3Jlc3MFU3RhdGUGQWN0aXZlCFByb2dyZXNzD0ZpbHRlcl9Qcm9ncmVzcwpIYXZlI1N0YXJzFEludGVyYWN0I1BlYWNoX1N0YXJzAAIIAgEAAABCuywBA1IEAQCkAwEAAAAAQJ8DAgLwAwQAAgAAgE0CAeIDAAAAKwIBAFICAQD7BAAATQQEeQQAAABNBARiBQAAAIcDBALwAgIABgAAAKkEAAGpBAEAUgUDAA4FBgCkBQgAABwggFIGAwBNBwDaCQAAAJ8FAwJNBgDaCQAAACsEAQAOBQMATQcA2gkAAAArBwEAUgcCAPEGCQAHAAAA+wYAAE0GBnkEAAAATQYGRQoAAABNBgbhCwAAAIIGAgC7LAADUgcAAKQGAQAAAABAnwYCAvAGCQACAACATQYAqwwAAADwBgUADQAAgE0GADgOAAAA8AYCAA8AAACCAAEATQYA5BAAAACCBgIAEQMBBAAAAEADAgMDAwQDBQMGAwcEABwggAMIAwkDCgMLAwwDDQMOAw8ADhABGAAAAAAAAAAAAAAAAQAAAAAAAgAAAAEAAAAAAAAAAgAAAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAQIAAA8AAAAABAAAAQIAGKMAAADiAAIA/wEBAAAAAAD/AgAAAQAAAG8DAwDFAgMCAQAAADACAYUEAAAAMAEAYgAAAADiAQcAMAEARQEAAADiAQkAMAABeQgAAADAAgoAEgABADACAdELAAAAggECAAwDBQMJBQIAAQMRAxIDCgIAAAAAAADwPwgBBQYAAAADBAUBCAYAAxABAAEAARgAAAEAAQABAAD/AP8ABQAABQAAAgAAABABAAAAAAHktnurLU0JBkDjhPk6IAvClK5s39ZyEao=

-- decompilation:
local t1 = {
	__database = {
		Merged_Packages = {
			["Interact#Peach_Stars"] = { "Have#Stars" }
		},
		Error_Tokens = {
			INVALID_NODE = 1.0
		}
	}
}

function t1.Filter_Progress(p1, p2) -- line: 14
	-- upvalues: t1 (copy)
	local v4 = typeof(p2) == "table" and p2.Tensor or p2
	local v5 = t1.__database.Merged_Packages[v4]
	local v6 = v4 == "__Spoof"
	local v7 = v5 and table.find(v5, p1.Token)

	if p1.Token ~= (not (not v6 and not v7) and p1.Token or v4) then
		return t1.__database.Error_Tokens.INVALID_NODE
	end

	if typeof(p1) ~= "table" or p1.Modifier ~= "IncrementProgress" or p1.State ~= "Active" then
		return
	end

	return p1.Progress
end

return t1

