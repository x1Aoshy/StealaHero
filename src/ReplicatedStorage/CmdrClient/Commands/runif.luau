-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMfA3N1YgpzdGFydHNXaXRoGkNvbmRpdGlvbiAlcSBpcyBub3QgdmFsaWQuBmZvcm1hdApEaXNwYXRjaGVyBENtZHIEVXRpbBNSdW5FbWJlZGRlZENvbW1hbmRzDkV2YWx1YXRlQW5kUnVuAANSdW4ETmFtZQVydW5pZgdBbGlhc2VzC0Rlc2NyaXB0aW9uOlJ1bnMgYSBnaXZlbiBjb21tYW5kIHN0cmluZyBpZiBhIGNlcnRhaW4gY29uZGl0aW9uIGlzIG1ldC4FR3JvdXALRGVmYXVsdFV0aWwEQXJncwRUeXBlEWNvbmRpdGlvbkZ1bmN0aW9uCUNvbmRpdGlvbhZUaGUgY29uZGl0aW9uIGZ1bmN0aW9uBnN0cmluZwhBcmd1bWVudCZUaGUgYXJndW1lbnQgdG8gdGhlIGNvbmRpdGlvbiBmdW5jdGlvbgxUZXN0IGFnYWluc3QZVGhlIHRleHQgdG8gdGVzdCBhZ2FpbnN0LgdDb21tYW5kbFRoZSBjb21tYW5kIHN0cmluZyB0byBydW4gaWYgcmVxdWlyZW1lbnRzIGFyZSBtZXQuIElmIG9taXR0ZWQsIHJldHVybiB2YWx1ZSBmcm9tIGNvbmRpdGlvbiBmdW5jdGlvbiBpcyB1c2VkLghPcHRpb25hbAADBgIAAAAADowEAQAcBQEAvAIA8AAAAACfAgQCmgIHAAEAAAAcBQEAlQQFAbwCAPAAAAAAnwIDAIICAACCAAEAAgMBAgAAAAAAAPA/AAICARgAAAAAAAAAAQAAAAAAAgMAAAAADAUBAAAHAAABAwYFAiD7BgAAhwUGASsFBgBvBgAAUggBALwGBo0BAAAAnwYDAIIGAABSBgUAUgcDAFIIAgCfBgMCDgYQAE0HAAoCAAAATQkAngMAAABNCQmeBAAAAE0JCWIFAAAATQoACgIAAADKCwQGnwkDALwHB14GAAAAnwcAAIIHAABvBwcAggcCAAgDAwMEAwUDBgMHAwgDCQMKACYLARgAAAIBAAAAAAADAAAAAgEAAAAAAAAAAAAAAAAAAAADACcAAAAABwAAAQIAGaMAAADiAAEAwAECADABADoAAAAA4gEMAP8CAAAAAAAAMAIBJwUAAAD/AgAABAAAAOIDEQDiBBUA4gUYAOIGHQDFAgMFAQAAADACAdsKAAAAwAIeABIAAAAwAgEWCwAAAIIBAgAfAwIFAQAGAAMMAw0DDgMPAxADEQMSAxMDCwgGAwQAAAAF/////wYHAAAACAkAAAAK/////wv/////AxQDFQMWAxcIAw0OAAAAAw8AAAAGEAAAAAMYAxkDGggDDRIAAAADEwAAAAYUAAAAAxsDHAgDDRIAAAADFgAAAAYXAAAAAx0DHgMfAQEIBA0SAAAAAxkAAAAGGgAAABscAAAABgECAAEBAAEYAAABAAAHAgAAAAMAAQUFBQAA8AAYAAAAAAEAAAAAAq2p/LPeGFT7lWOI61EOZA7dsevHn22Wsg==

-- decompilation:
local t1 = {
	startsWith = function(p1, p2) -- line: 2
		if p2 == p1:sub(1.0, #p2) then
			return p1:sub(#p2 + 1.0)
		end
	end
}

return {
	Name = "runif",
	Description = "Runs a given command string if a certain condition is met.",
	Group = "DefaultUtil",
	Aliases = {},
	Args = {
		{
			Type = "conditionFunction",
			Name = "Condition",
			Description = "The condition function"
		},
		{
			Type = "string",
			Name = "Argument",
			Description = "The argument to the condition function"
		},
		{
			Type = "string",
			Name = "Test against",
			Description = "The text to test against."
		},
		{
			Type = "string",
			Name = "Command",
			Description = "The command string to run if requirements are met. If omitted, return value from condition function is used.",
			Optional = true
		}
	},
	Run = function(p3, p4, p5, p6, p7) -- line: 38
		-- upvalues: t1 (copy)
		local v9 = t1[p4]

		if not v9 then
			return ("Condition %q is not valid."):format(p4)
		end

		local v10 = v9(p6, p5)

		if v10 then
			return p3.Dispatcher:EvaluateAndRun(p3.Cmdr.Util.RunEmbeddedCommands(p3.Dispatcher, p7 or v10))
		end

		return ""
	end
}

