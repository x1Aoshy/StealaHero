-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMnCUludmVudG9yeQhTZXR0aW5ncwdQb3Rpb25zCkF1dG9UYXBwZXINVmVuZGluZ1N0b2NrcwxUcmFkZUhpc3RvcnkMQm9vdGhIaXN0b3J5B01haWxMb2cJSXRlbUluZGV4DVBldEhhdGNoQ291bnQLR2xpdGNoRXZlbnQMQWNoaWV2ZW1lbnRzE01hc3RlcnlQZXJrc0VuYWJsZWQHTWFzdGVyeQxFcXVpcHBlZFBldHMFQnVmZnMGQm9vc3RzBkZydWl0cwpab25lUXVlc3RzDUZyZWVHaWZ0c1RpbWULUHJpc29uRXZlbnQPRGlub1R5Y29vbkV2ZW50BmlwYWlycxBDb2luR3JhYkRpc3RhbmNlC011c2ljVm9sdW1lDFNvdW5kc1ZvbHVtZQpTdXBwb3J0c1ZSEFN1cHBvcnRzUG9ydHJhaXQORm9yY2VkUG9ydHJhaXQLU2NhbGU5U2xpY2UMU2NhbGVTdHJva2VzDFNjYWxlUGFkZGluZwpTY2FsZUxpc3RzClNjYWxlR3JpZHMNU2NhbGVSaWNoVGV4dA9TY2FsZVNjcm9sbGJhcnMNVUlFYXNpbmdTdHlsZQRTaW5lDVN0YXRzTm9GcmVlemUAAREAAAEAAC2jAAAA/wAAABcAAABvAQAAbwIBAG8DAgBvBAMAbwUEAG8GBQBvBwYAbwgHAG8JCABvCgkAbwsKAG8MCwBvDQwAbw4NAG8PDgBvEA8AxQABEQEAAABvARAAbwICAG8DEQBvBBIAbwUTAG8GFABvBxUAxQABCBEAAAD/AQAAAAAAAKQCFwAAAGBBUgMAAJ8CAgRRAgIAqQcBAGoHAQZuAv3/AgAAgOICLAAwAQL5KwAAAIICAgAtAwEDAgMDAwQDBQMGAwcDCAMJAwoDCwMMAw0DDgMPAxADEQMSAxMDFAMVAxYDFwQAAGBBAxgCAAAAAADAckADGQIAAAAAAADgPwMaAxsBAAMcAx0DHgEBAx8DIAMhAyIDIwMkAyUDJgMnCA8YGQAAABobAAAAHBsAAAAdHgAAAB8eAAAAIB4AAAAhIgAAACMiAAAAJB4AAAAlHgAAACYeAAAAJyIAAAAoHgAAACkqAAAAK/////8AAQABGAACAAEBAQEBAQEBAQEBAQEBAQEBAAABAQEBAQEAAAMAAQAAAAABAP8ABA8AAAEAAAAAAGF1lv+/WcSuwdhuDgWiXzERbYGLU7H8/g==

-- decompilation:
local t1 = {}

for _, v in ipairs({
	"Inventory",
	"Settings",
	"Potions",
	"AutoTapper",
	"VendingStocks",
	"TradeHistory",
	"BoothHistory",
	"MailLog",
	"ItemIndex",
	"PetHatchCount",
	"GlitchEvent",
	"Achievements",
	"MasteryPerksEnabled",
	"Mastery",
	"EquippedPets",
	"Buffs",
	"Boosts",
	"Potions",
	"Fruits",
	"ZoneQuests",
	"FreeGiftsTime",
	"PrisonEvent",
	"DinoTycoonEvent"
}) do
	t1[v] = true
end

return {
	CoinGrabDistance = 300.0,
	MusicVolume = 0.5,
	SoundsVolume = 0.5,
	SupportsVR = false,
	SupportsPortrait = false,
	ForcedPortrait = false,
	Scale9Slice = true,
	ScaleStrokes = true,
	ScalePadding = false,
	ScaleLists = false,
	ScaleGrids = false,
	ScaleRichText = true,
	ScaleScrollbars = false,
	UIEasingStyle = "Sine",
	StatsNoFreeze = t1
}

