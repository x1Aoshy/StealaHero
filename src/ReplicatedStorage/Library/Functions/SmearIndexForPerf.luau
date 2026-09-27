-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNBm51bWJlcghvcHRpb25hbAR0YXNrBHdhaXQEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdBc3NlcnRzB0dsb2JhbHMJQ29uc3RhbnRzCUlTX01PQklMRQACBAICAAAHBAAABQICghn7AgAATQICYAAAAABSAwAAnwICAfsCAABNAgIRAQAAAE0CAmAAAAAAUgMBAJ8CAgFSAgEAKwIBAPsCAQBSAQIAzwIAAQ0CAgACAAAAggABAKQCBQAAEDCAjAMAAJ8CAgGCAAEABgMBAwICAAAAAAAAAAADAwMEBAAQMIAADQABGAAAAAAAAQAAAAAAAAIAAAACAAABAgAAAAEOAAAAAAUAAAECACGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwNLCAAAAE0DAwcJAAAAnwICAk0EAisKAAAADgQCAIwDZABlAAEAjAMsAcAECwASAAEAEgADAIIEAgAMAwUEAAAAQAMGAwcDCAQAAEBAAwkDCgMLAwwDDQYAAQABAAEYAAEAAAAAAAMAAAAAAAABAAAAAAAAAAAEAAAAAAADAAAAAQAAAAABkW7jX+0CDnd9SUpCkXQDKuF29Cujqole

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local v3 = not require(ReplicatedStorage.Library.Globals.Constants).IS_MOBILE and 300.0 or 100.0

return function(n1: number, n2: number?) -- line: 13
	-- upvalues: Asserts (copy), v3 (copy)
	Asserts.number(n1)
	Asserts.optional.number(n2)

	if n1 % (n2 or v3) ~= 0.0 then
		return
	end

	task.wait(0.0)
end

