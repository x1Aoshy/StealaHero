-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOCG9wdGlvbmFsBXRhYmxlBnN0cmluZwlSZWNvbmNpbGUUUGF0Y2hSZXBsaWNhdGVkUHJvcHMEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzB01vZHVsZXMIUGFja2FnZXMJVGFibGVVdGlsAAIGAwIAAAgFAAAFAwQPDyL7AwAATQMDEQAAAABNAwNLAQAAAFIEAQCfAwIB+wMAAE0DAxEAAAAATQMDQQIAAABSBAIAnwMCAfsDAABNAwMRAAAAAE0DA0sBAAAAUgQAAJ8DAgEOAgoA+wMBAE0DA08DAAAAUgQBACsEAgD/BAAAAAAAAIcFAAKfAwMCKwMBAFIDAQCCAwIABAMBAwIDAwMEAA8FARgAAAAAAAAAAQAAAAAAAAEAAAAAAAACAAAAAAAAAAAAAAEAEAAAAAAEAAABAgAdowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD6AgAAABNAwPmCQAAAE0DA84KAAAAnwICAsADCwASAAEAEgACAIIDAgAMAwYEAAAAQAMHAwgDCQQAAEBAAwoDCwMMAw0DDgYAAQABAAEYAAEAAAAAAAMAAAAAAAABAAAAAAAAAAAAAAkAAAkBAAAAAAHHMapNZqK5w+r2EYoKuzmvtym9OfX1wEw=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local TableUtil = require(ReplicatedStorage.Library.Modules.Packages.TableUtil)

local function PatchReplicatedProps(t1: {[any]: any}, p1, p2) -- line: 15
	-- upvalues: Asserts (copy), TableUtil (copy)
	Asserts.optional.table(p1)
	Asserts.optional.string(p2)
	Asserts.optional.table(t1)

	return p2 and TableUtil.Reconcile(p1 or {}, t1[p2]) or p1
end

return PatchReplicatedProps

