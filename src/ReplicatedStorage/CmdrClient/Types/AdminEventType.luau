-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMODmFkbWluRXZlbnRUeXBlBENtZHIEVXRpbAxNYWtlRW51bVR5cGUOQWRtaW5FdmVudFR5cGUMUmVnaXN0ZXJUeXBlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZRNTZXJ2ZXJTY3JpcHRTZXJ2aWNlDVJlY292ZXJ5RXZlbnQMRGVtb25pY0V2ZW50CUNvdW50ZG93bg5EcmFnb25FZ2dFdmVudAACBwEBAAAADm8DAABNBACeAQAAAE0EBJ4CAAAATQQEsgMAAABvBQQA+wYAAJ8EAwC8AQDdBQAAAJ8BAAGCAAEABgMBAwIDAwMEAwUDBgALAAEYAAAAAAAAAAAAAAAAAAEMAAAAAAcAAAECABijAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEBAAAAAEBvAwQAvAEBFgMAAACfAQMC/wIAAAQAAABvAwUAbwQGAG8FBwBvBggAxQIDBQEAAADAAwkAEgACAIIDAgAKAwcEAAAAQAMIAwkDCgMLAwwDDQMOBgABAAEAARgAAAAAAAAAAQAAAAAAAgABAQEBAAADAAABAAAAAAG6gVDF4XKpmI+GT2tTiKLsyplHsYhFOsQ=

-- decompilation:
game:GetService("ReplicatedStorage")
game:GetService("ServerScriptService")

local t1 = {
	"RecoveryEvent",
	"DemonicEvent",
	"Countdown",
	"DragonEggEvent"
}

return function(p1) -- line: 11
	-- upvalues: t1 (copy)
	p1:RegisterType("adminEventType", p1.Cmdr.Util.MakeEnumType("AdminEventType", t1))
end

