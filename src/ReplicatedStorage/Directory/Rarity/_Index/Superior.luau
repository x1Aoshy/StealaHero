-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlBnNjcmlwdAZQYXJlbnQHUHJpdmF0ZQtCYXNlQ29uZmlncwdTeXN0ZW1zDEZvcm1hdFJhcml0eQdEZWZhdWx0BE5hbWUGQXNzZXRzAlVJBlJhcml0eQtEaXNwbGF5TmFtZQxSYXJpdHlOdW1iZXISRGVmYXVsdFJhcml0eVZhbHVlDDEgaW4gMTAwLDAwMAhJdGVtU2xvdAhHcmFkaWVudAVDb2xvcgdNZXNzYWdlCEFubm91bmNlBkNvbG9yMwdmcm9tUkdCAAEJAAABAgA+owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBApAIHAAAAYEBNAgIkCAAAAE0CAiQIAAAATQICDAkAAABNAgI6CgAAAE0CAiYLAAAATQICOAwAAABNAgI6DQAAAJ8BAgKkAgcAAABgQE0CAroOAAAATQQAgQ8AAABNBARcEAAAAE0EBPIRAAAAhwMEAuIEHQAwAgRXEgAAAE0FA4kXAAAAMAUEiRcAAABNBQM9GAAAADAFBD0YAAAApAUgAAB84IGMBsMAjAf/AIwI/wCfBQQCMAUEpBkAAABSBQEAbwYWAJ8FAgIwBQT4GgAAAIIEAgAhAwEEAAAAQAMCAwMDBAQAAEBAAwUEAABgQAMGAwcDCAMJAwoDCwMMAw0DDgMPAxADEQIAAAAAAAAkQAMSAxMDFAMVAxYDFwMYAQEICBL/////ExQAAAAVFgAAABf/////GP////8Z/////xr/////GxwAAAADGQMaBAB84IEAAQABGAABAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAIAAAAAAAADAQAEAAAAAQAAAAEAAAAAAAAAAgAAAAAAAQAAAAAAktXEfy0PMl9aLG40MoAQk+LN0wugEa5+

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Default = require(script.Parent.Parent.Private.BaseConfigs.Systems.FormatRarity.Default)
local scriptName = script.Name
local v4 = ReplicatedStorage.Assets.UI.Rarity[scriptName]

return {
	RarityNumber = 10.0,
	DefaultRarityValue = "1 in 100,000",
	Announce = true,
	DisplayName = scriptName,
	ItemSlot = v4.ItemSlot,
	Gradient = v4.Gradient,
	Color = Color3.fromRGB(195.0, 255.0, 255.0),
	Message = Default("1 in 100,000")
}

