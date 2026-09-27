-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBnR5cGVvZghJbnN0YW5jZQVNb2RlbANJc0EEVG9vbCpFeHBlY3RlZCBhcmd1bWVudCAjMSB0byBiZSBhIE1vZGVsIG9yIFRvb2wGYXNzZXJ0EUN1c3RvbUJvdW5kaW5nQm94DkZpbmRGaXJzdENoaWxkCEJhc2VQYXJ0BkNGcmFtZQRTaXplBmlwYWlycw5HZXREZXNjZW5kYW50cwxUcmFuc3BhcmVuY3kFdGFibGUGaW5zZXJ0CEdldFBpdm90CFBvc2l0aW9uB3JlcXVpcmUGc2NyaXB0BlBhcmVudAtCQkZyb21BcnJheQACCwEBAAAGAwAABQEHV6kCAAC7LAADUgQAAKQDAQAAAABAnwMCAvADCgACAACAbwQDALwCAP4EAAAAnwIDAisCBABvBAUAvAIA/gQAAACfAgMCgQECBAYAAABvAwYApAEIAAAAcECfAQMBbwMJAKkEAQC8AQADCgAAAJ8BBAIOAQoAbwQLALwCAf4EAAAAnwIDAg4CBQBNAgGFDAAAAE0DAS8NAAAAggIDAP8CAAAAAAAApAMPAAAA4EC8BABHEAAAAJ8EAgCfAwAEUQMRAG8KCwC8CAf+BAAAAJ8IAwIOCAwATQgH2REAAACMCQEAYAgIAAkAAACeNAIFBwAAAFIJAgBSCgcApAgUAABMIIGfCAMBbgPu/wIAAIAcAwIADQMHABUAAIC8AwBSFgAAAJ8DAgJSBAMAbwUXAIIEAwC8AwBSFgAAAJ8DAgJNBQM7GAAAACYEAwX7BQAAUgYCAFIHBACfBQMAggUAABkDAQQAAABAAwIDAwMEAwUDBgMHBAAAcEADCAMJAwoDCwMMAw0EAADgQAMOAw8DEAMRBABMIIECAAAAAAAAAAADEgcAAAAAAAAAAAAAAAAAAAAAAxMABwABGAEAAAAAAAAAAAAAAAAAAAAAAAAA/wAABQAAAAABAAAAAAABAAAAAAMAAQAAAAAAAAEAAAAAAAAAAAABAAAAAAAA/gAGAAABAAABAAADAAABAAABAAAAAAgAAAAAAgAAAQIADaMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQH0BQAAAJ8AAgLAAQYAEgAAAIIBAgAHAxQEAAAAQAMVBAAAIEADFgMXBgABAAEAARgAAwAAAAAAAAAAAwAAAQAAAAAB8a5BEq08HMJ0bG2MJmnw7YG2VmbDaisT

-- decompilation:
local BBFromArray = require(script.Parent.BBFromArray)

return function(p1) -- line: 7
	-- upvalues: BBFromArray (copy)
	assert(typeof(p1) == "Instance" and (p1:IsA("Model") or p1:IsA("Tool")), "Expected argument #1 to be a Model or Tool")

	local CustomBoundingBox = p1:FindFirstChild("CustomBoundingBox", true)

	if CustomBoundingBox and CustomBoundingBox:IsA("BasePart") then
		return CustomBoundingBox.CFrame, CustomBoundingBox.Size
	end

	local t1 = {}

	for _, descendant in ipairs(p1:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Transparency < 1.0 then
			table.insert(t1, descendant)
		end
	end

	if #t1 == 0.0 then
		return p1:GetPivot(), (Vector3.new(0.0, 0.0, 0.0))
	end

	local Pivot = p1:GetPivot()
	local v8 = Pivot - Pivot.Position

	return BBFromArray(t1, v8)
end

