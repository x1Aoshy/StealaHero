-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlDVVzZXJHZW5lcmF0ZWQLQ29uY3VycmVuY3kIQmluZGFibGUJRmFzdEZsYWdzBExhbmcHQXNzZXJ0cwpSZXBsaWNhdGVkHFVzZXJHZW5lcmF0ZWQuQUJUZXN0RGVmYXVsdHMDTWFwBlN0cmluZwNBbnkFdGFibGUGZnJlZXplDFVwZGF0ZVJlbW90ZQ5BQlRlc3REZWZhdWx0cwZzY3JpcHQGVXBkYXRlDFdhaXRGb3JDaGlsZAABCgAAAQMXAAAFDwABOw8BBzUPAhAsDwMXJQ8EIBw8owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIA4AYAAABNAgJmBwAAAE0CAqIIAAAAnwECAqQCBQAAAEBATQMA4AYAAABNAwP/CQAAAJ8CAgKkAwUAAABAQE0EAOAGAAAATQQEvgoAAABNBASJCwAAAJ8DAgJNBAKvDAAAAG8FDQBNBgOwDgAAAE0HA6EPAAAATQgD7hAAAACfBgMC/wcAAAAAAACfBAQCpAUTAABIEIHiBhYApAcYAAAAcEFvCRkAvAcH0xoAAACfBwMCMAcGyxQAAAAwBAY+FQAAAJ8FAgCCBQAAGwMBBAAAAEADAgMDAwQEAABAQAMFAwYDBwMIAwkDCgMLAwwDDQMOAw8DEAMRBABIEIEDEgMTBQIUFQMUBAAAcEEDFQMWAAEAARgAEwAAAAAAAgAAAAAAAAAAAQAAAAAAAAEAAAAAAAAAAAIAAQEAAAAAAAABAP0bAAABAAAAAAAAAAEA/gABAAAAAABKp2H+q4/+mfimdWej0dTjOr92inhjC/8=

-- decompilation:
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.UserGenerated.Concurrency.Bindable)

local FastFlags = require(ReplicatedStorage.UserGenerated.FastFlags)
local Asserts = require(ReplicatedStorage.UserGenerated.Lang.Asserts)
local v4 = FastFlags.Replicated("UserGenerated.ABTestDefaults", Asserts.Map(Asserts.String, Asserts.Any), {})

return table.freeze({
	UpdateRemote = script:WaitForChild("Update"),
	ABTestDefaults = v4
})

