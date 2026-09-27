-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMTA0JveAhDdXJyZW5jeQNQZXQDRWdnB0xvb3Rib3gFQ2hhcm0IVWx0aW1hdGUHRW5jaGFudAhYUFBvdGlvbgZQb3Rpb24ETWlzYwpIb3ZlcmJvYXJkBUJvb3RoBUZydWl0BFNlZWQEUGFnZQZpcGFpcnMFT3JkZXIIT3JkZXJJbnYAAREAAAEAACWjAAAA/wAAABAAAABvAQAAbwIBAG8DAgBvBAMAbwUEAG8GBQBvBwYAbwgHAG8JCABvCgkAbwsKAG8MCwBvDQwAbw4NAG8PDgBvEA8AxQABEQEAAAD/AQAAAAAAAKQCEQAAAABBUgMAAJ8CAgRRAgEAagUBBm4C/v8CAACA4gIUADABAmQSAAAAMAACbxMAAACCAgIAFQMBAwIDAwMEAwUDBgMHAwgDCQMKAwsDDAMNAw4DDwMQAxEEAAAAQQMSAxMFAhITAAEAARgAAAABAQEBAQEBAQEBAQEBAQEBAAACAAEAAAAAAf8AAwEAAQAAAQAAAAAArH2VCaTcYudnI2gublSErNxlgn2euf8I

-- decompilation:
local t1 = {
	"Box",
	"Currency",
	"Pet",
	"Egg",
	"Lootbox",
	"Charm",
	"Ultimate",
	"Enchant",
	"XPPotion",
	"Potion",
	"Misc",
	"Hoverboard",
	"Booth",
	"Fruit",
	"Seed",
	"Page"
}
local t2 = {}

for i, v in ipairs(t1) do
	t2[v] = i
end

return {
	Order = t2,
	OrderInv = t1
}

