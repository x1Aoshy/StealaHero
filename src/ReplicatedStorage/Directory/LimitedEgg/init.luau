-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(script.Types.Interface)

local v3 = table.freeze({
	table.freeze({
		"Tung Tung Sahur",
		39.0
	}),
	table.freeze({
		"Bananita Dolphinita",
		25.0
	}),
	table.freeze({
		"Belula Beluga",
		20.0
	}),
	table.freeze({
		"Mangolini Parrochini",
		10.0
	}),
	table.freeze({
		"Bomboclat Crocolat",
		5.0
	}),
	table.freeze({
		"Strawberry Elephant",
		1.0
	})
})

assert(#v3 == 6.0, "Limited egg presentation requires exactly six drop entries")

local t1 = {}

for i, v in ipairs(v3) do
	local v7 = v[1.0]
	local v8 = v[2.0]

	Asserts.string(v7)
	Asserts.number(v8)
	assert(v8 > 0.0, `Limited egg drop entry { i } requires positive weight`)
	table.insert(t1, table.freeze({
		AssetId = v7,
		Weight = v8
	}))
end

return (table.freeze({
	DropTable = v3,
	Entries = table.freeze(t1),
	Offers = table.freeze({
		table.freeze({
			Amount = 1.0,
			ProductName = "Limited Egg"
		}),
		table.freeze({
			Amount = 3.0,
			ProductName = "Limited Egg x3"
		}),
		table.freeze({
			Amount = 10.0,
			ProductName = "Limited Egg x10"
		}),
		table.freeze({
			Amount = 50.0,
			ProductName = "Limited Egg x50"
		})
	})
}))

