-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHTW9kdWxlcwhQYWNrYWdlcwF0CWludGVyZmFjZQhEdXJhdGlvbgVGb3JjZQ5CcmFpbnJvdERhbWFnZRJNYXhCcmFpbnJvdFRhcmdldHMGbnVtYmVyCG9wdGlvbmFsFVNsYXBDb250cm9sbGVyUHJvZmlsZQZQbGF5ZXIIQnJhaW5yb3QOUGxheWVyQ29vbGRvd24LTW9iQ29vbGRvd24SU2xhcENvbnRyb2xsZXJEYXRhAAEHAAABAgBKowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgLoBwAAAE0CAuYIAAAATQIClQkAAACfAQIC/wICAAAAAABNAwEvCgAAAOIEDwBNBQFgEAAAADAFBOULAAAATQUBYBAAAAAwBQQtDAAAAE0FAWAQAAAAMAUEow0AAABNBQEREQAAAE0GAWAQAAAAnwUCAjAFBG0OAAAAnwMCAjADAmMSAAAATQMBLwoAAADiBBcATQUCYxIAAAAwBQT5EwAAAE0FAmMSAAAAMAUEXRQAAABNBQEREQAAAE0GAWAQAAAAnwUCAjAFBPQVAAAATQUBEREAAABNBgFgEAAAAJ8FAgIwBQSdFgAAAJ8DAgIwAwLwGAAAAIICAgAZAwEEAAAAQAMCAwMDBAQAAEBAAwUDBgMHAwgDCQMKAwsDDAMNBQQLDA0OAw4DDwMQAxEDEgMTAxQFBBMUFRYDFQABAAEYAAMAAAAAAAMAAAAAAAAAAAAAEQACAAABAAAAAQAAAAEAAAABAAAAAAAA/AAABwAAAQAAAAEAAAABAAAAAAAAAQAAAAAAAPwAAAcBAAAAAACB4oU5IMkgj5FOnbIgC6ZH8fqSTbMm7zg=

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Library.Modules.Packages.t)
local t1 = {
	SlapControllerProfile = t.interface({
		Duration = t.number,
		Force = t.number,
		BrainrotDamage = t.number,
		MaxBrainrotTargets = t.optional(t.number)
	})
}

t1.SlapControllerData = t.interface({
	Player = t1.SlapControllerProfile,
	Brainrot = t1.SlapControllerProfile,
	PlayerCooldown = t.optional(t.number),
	MobCooldown = t.optional(t.number)
})

return t1

