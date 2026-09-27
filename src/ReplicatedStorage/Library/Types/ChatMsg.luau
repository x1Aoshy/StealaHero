-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0CWludGVyZmFjZQdtZXNzYWdlBWNvbG9yBGZvbnQIZm9udFNpemUJb21pdENvbG9yCG1ldGFkYXRhBnN0cmluZwhvcHRpb25hbAZDb2xvcjMIRW51bUl0ZW0HYm9vbGVhbgxBbm5vdW5jZURhdGEAAQcAAAECAEKjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgKVCQAAAJ8BAgL/AgEAAAAAAE0DAS8KAAAA4gQRAE0FAUESAAAAMAUEmAsAAABNBQEREwAAAE0GAZoUAAAAnwUCAjAFBEQMAAAATQUBERMAAABNBgF1FQAAAJ8FAgIwBQQZDQAAAE0FARETAAAATQYBdRUAAACfBQICMAUEYQ4AAABNBQEREwAAAE0GAT4WAAAAnwUCAjAFBBMPAAAATQUBERMAAABNBgFBEgAAAJ8FAgIwBQS3EAAAAJ8DAgIwAwIdFwAAAIICAgAYAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwUGCwwNDg8QAxADEQMSAxMDFAMVAAEAARgAAwAAAAAAAwAAAAAAAAAAAAANAAIAAAEAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAPoAAAkBAAAAAADozyijH9lG/o/x9HvYhmRzmNc/19oLQqI=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)

return {
	AnnounceData = t.interface({
		message = t.string,
		color = t.optional(t.Color3),
		font = t.optional(t.EnumItem),
		fontSize = t.optional(t.EnumItem),
		omitColor = t.optional(t.boolean),
		metadata = t.optional(t.string)
	})
}

