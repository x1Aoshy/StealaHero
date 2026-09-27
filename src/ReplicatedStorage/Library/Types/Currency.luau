-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0EFNjaGVtYVZhbGlkYXRpb24FdW5pb24HbGl0ZXJhbAVNb25leRJTcGlubnlXaGVlbFRpY2tldHMQQWxsQ3VycmVuY3lUeXBlcxVBbGxDdXJyZW5jeVR5cGVzQXJyYXkAAQgAAAECADGjAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgKVCQAAAJ8BAgL/AgMAAAAAAP8DAQAAAAAAMAMC3woAAABNBAGYCwAAAE0FAXMMAAAAbwYNAJ8FAgJNBgFzDAAAAG8HDgCfBgIAnwQAAjAEA4YPAAAA4gQQADAEAoYPAAAA/wQAAAIAAABvBQ0AbwYOAMUEBQMBAAAAMAQCkBEAAACCAgIAEgMBBAAAAEADAgMDAwQEAABAQAMFAwYDBwMIAwkDCgMLAwwDDQMOCAINDQAAAA4OAAAAAw8AAQABGAADAAAAAAADAAAAAAAAAAAAAAMABgABAAIAAAAAAAAAAAAAAAADAAAFAAEBAAD+AAUBAAAAAAD7+3XVL1T0lX68FTLL3Gv2i+Niock/H9Q=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local t1 = {}
local t2 = {}

t1.SchemaValidation = t2
t2.AllCurrencyTypes = t.union(t.literal("Money"), t.literal("SpinnyWheelTickets"))
t1.AllCurrencyTypes = {
	Money = "Money",
	SpinnyWheelTickets = "SpinnyWheelTickets"
}
t1.AllCurrencyTypesArray = {
	"Money",
	"SpinnyWheelTickets"
}

return t1

