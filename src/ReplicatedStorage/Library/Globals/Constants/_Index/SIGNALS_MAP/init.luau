-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMYBnNjcmlwdAZTZXJ2ZXIGQ2xpZW50BlNoYXJlZAdyZXF1aXJlE0Fzc2V0R2VuZXJhdGlvblV0aWwMTW9uZXlTZXJ2aWNlDUdlYXJJbnZlbnRvcnkMRWdnSW52ZW50b3J5DlN3b3JkSW52ZW50b3J5DVNraW5JbnZlbnRvcnkJSW52ZW50b3J5B1JlYmlydGgGR3VhcmRzDEFyZWFCcmFpbnJvdAZLZXJuZWwNTXVyZGVyTXlzdGVyeRZBY3RpdmVBc3NldHNDb250cm9sbGVyDEJyYWlucm90SXRlbRBBY3RpdmVBc3NldEl0ZW1zBVBsb3RzD0NsaWVudENoYXJhY3RlchRUcmFkaW5nTm90aWZpY2F0aW9ucwtGdXNlTWFjaGluZQABCQAAAQIAoQGjAAAApAABAAAAAEBNAADvAgAAAKQBAQAAAABATQEBTQMAAACkAgEAAAAAQE0CAhIEAAAA/wMDAAAAAAD/BAUAAAAAAP8FBAAAAAAA/wYBAAAAAAAwBAPvAgAAADAFA00DAAAAMAYDEgQAAACkBwYAAABQQE0IArcHAAAAnwcCAjAHBrcHAAAApAcGAAAAUEBNCAAnCAAAAJ8HAgIwBwQnCAAAAKQHBgAAAFBATQgAAgkAAACfBwICMAcEAgkAAACkBwYAAABQQE0IAC8KAAAAnwcCAjAHBC8KAAAApAcGAAAAUEBNCABOCwAAAJ8HAgIwBwROCwAAAKQHBgAAAFBATQgANgwAAACfBwICMAcENgwAAACkBwYAAABQQE0IAGANAAAAnwcCAjAHBGANAAAApAcGAAAAUEBNCADWDgAAAJ8HAgIwBwTWDgAAAKQHBgAAAFBATQgAWQ8AAACfBwICMAcEWQ8AAACkBwYAAABQQE0IAFgQAAAAnwcCAjAHBFgQAAAApAcGAAAAUEBNCABGEQAAAJ8HAgIwBwRGEQAAAKQHBgAAAFBATQgAFBIAAACfBwICMAcEFBIAAACkBwYAAABQQE0IAI0TAAAAnwcCAjAHBI0TAAAApAcGAAAAUEBNCAAMFAAAAJ8HAgIwBwQMFAAAAKQHBgAAAFBATQgBaxUAAACfBwICMAcFaxUAAACkBwYAAABQQE0IAbsWAAAAnwcCAjAHBbsWAAAApAcGAAAAUEBNCAFEFwAAAJ8HAgIwBwVEFwAAAKQHBgAAAFBATQgB/RgAAACfBwICMAcF/RgAAACkBwYAAABQQE0IAawZAAAAnwcCAjAHBawZAAAAggMCABoDAQQAAABAAwIDAwMEAwUEAABQQAMGAwcDCAMJAwoDCwMMAw0DDgMPAxADEQMSAxMDFAMVAxYDFwMYAAEAARgAAwAAAAEAAAABAAAAAwABAAEAAQACAAEAAQADAAAAAAAAAwAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAACAAAAAAAAAgAAAAAAAAMAAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAABAAAAAAAAAgEAAAAAADpiX5q7Cr+OhTO4klCmAONKekjuCKY1mw==

-- decompilation:
local Server = script.Server
local Client = script.Client
local Shared = script.Shared
local t1 = {}
local t2 = {}
local t3 = {}
local t4 = {}

t1.Server = t2
t1.Client = t3
t1.Shared = t4
t4.AssetGenerationUtil = require(Shared.AssetGenerationUtil)
t2.MoneyService = require(Server.MoneyService)
t2.GearInventory = require(Server.GearInventory)
t2.EggInventory = require(Server.EggInventory)
t2.SwordInventory = require(Server.SwordInventory)
t2.SkinInventory = require(Server.SkinInventory)
t2.Inventory = require(Server.Inventory)
t2.Rebirth = require(Server.Rebirth)
t2.Guards = require(Server.Guards)
t2.AreaBrainrot = require(Server.AreaBrainrot)
t2.Kernel = require(Server.Kernel)
t2.MurderMystery = require(Server.MurderMystery)
t2.ActiveAssetsController = require(Server.ActiveAssetsController)
t2.BrainrotItem = require(Server.BrainrotItem)
t3.ActiveAssetItems = require(Client.ActiveAssetItems)
t3.Plots = require(Client.Plots)
t3.ClientCharacter = require(Client.ClientCharacter)
t3.TradingNotifications = require(Client.TradingNotifications)
t3.FuseMachine = require(Client.FuseMachine)

return t1

