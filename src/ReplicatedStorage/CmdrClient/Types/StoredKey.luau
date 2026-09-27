-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMYBENtZHIEVXRpbA9NYWtlRnV6enlGaW5kZXIORGljdGlvbmFyeUtleXMJdmFyc191c2VkCEdldFN0b3JlDEF1dG9jb21wbGV0ZQZpcGFpcnMFbWF0Y2hXS2V5IG5hbWVzIG11c3Qgc3RhcnQgd2l0aCBhbiBvcHRpb25hbCBtb2RpZmllcjogLiAkIG9yICQuIGFuZCBtdXN0IGJlZ2luIHdpdGggYSBsZXR0ZXIuCFZhbGlkYXRlBVBhcnNlCXN0b3JlZEtleQxSZWdpc3RlclR5cGUKc3RvcmVkS2V5cxBNYWtlTGlzdGFibGVUeXBlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAZTaGFyZWQKXiVhWyV3X10qJAxeJSQlYVsld19dKiQMXiUuJWFbJXdfXSokDl4lJCUuJWFbJXdfXSokAAUGAQEAAAAc+wEAAE0BAZ4AAAAATQEBngEAAABNAQE9AgAAAPsCAABNAgKeAAAAAE0CAp4BAAAATQIC4wMAAAD7AwAAbwUEALwDA1UFAAAAnwMDAisDAgD/AwAAAAAAAJ8CAgCfAQACUgIBAFIDAACfAgIAggIAAAYDAQMCAwMDBAMFAwYADAcBGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAANAAAAAAkBAQAAABGkAQEAAAAAQPsCAACfAQIEUQEHAFIIBQC8BgDnAgAAAJ8GAwIOBgIAqQYBAIIGAgBuAfj/AgAAgKkBAABvAgMAggEDAAQDCAQAAABAAwkDCgASCwEYAAAAAAABAAAAAAEA/gAGAAATAAAAAAEBAAAAAAGCAAIAAAAcDAEYAB0AAAAABwECAAAAG+IBAwDZAgAAEgAAADACAasAAAAAwAIEABICAAAwAgF2AQAAAMACBQAwAgGbAgAAAG8EBgBSBQEAvAIA3QcAAACfAgQBbwQIAPsFAQBNBQUkCQAAAFIGAQCfBQIAvAIA3QcAAACfAgABggABAAoDBwMLAwwFAwABAgYBBgIDDQMOAw8DEAMAAQIKAAEYAAEAAAAGAAAACgAABAAAAAABAAAAAAAAAAABCwAAAAAGAAABAgAaowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEBEgUAAABNAQGeBgAAAJ8AAgL/AQAABAAAAG8CBwBvAwgAbwQJAG8FCgDFAQIFAQAAAMACCwASAAEAEgAAAIICAgAMAxEEAAAAQAMSBAAAIEADEwMUAwIDFQMWAxcDGAYDAQMBAAEYAAAAAAAAAAAAAAAAAAACAAEBAQEAAAMAAAABAAAAAATkrqt1nsmFEU4IGZpTlZn7lLa8AdZqwXQ=

-- decompilation:
local Util = require(script.Parent.Parent.Shared.Util)
local t1 = {
	"^%a[%w_]*$",
	"^%$%a[%w_]*$",
	"^%.%a[%w_]*$",
	"^%$%.%a[%w_]*$"
}

return function(p1) -- line: 10
	-- upvalues: t1 (copy), Util (copy)
	local t2 = {
		Autocomplete = function(p2) -- line: 12
			-- upvalues: p1 (copy)
			return p1.Cmdr.Util.MakeFuzzyFinder(p1.Cmdr.Util.DictionaryKeys(p1:GetStore("vars_used") or {}))(p2)
		end,
		Validate = function(p3) -- line: 18
			-- upvalues: t1 (copy)
			for _, v in ipairs(t1) do
				if p3:match(v) then
					return true
				end
			end

			return false, "Key names must start with an optional modifier: . $ or $. and must begin with a letter."
		end,
		Parse = function(p4) -- line: 28
			return p4
		end
	}

	p1:RegisterType("storedKey", t2)
	p1:RegisterType("storedKeys", Util.MakeListableType(t2))
end

