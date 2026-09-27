-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMhBWNsYXNzCnRyeV9jb2VyY2UURGVjaW1hbEZvcm1hdFN5bWJvbHMPdHJ5X2NvZXJjZV9lbnVtBWVudW1zFEVOdW1iZXJGb3JtYXRTeW1ib2xzCUdldFN5bWJvbAZzdHJpbmcJU2V0U3ltYm9sF2tEZWNpbWFsU2VwYXJhdG9yU3ltYm9sAS4Ya0dyb3VwaW5nU2VwYXJhdG9yU3ltYm9sABBrTWludXNTaWduU3ltYm9sAS0Pa1BsdXNTaWduU3ltYm9sASsSa0V4cG9uZW50aWFsU3ltYm9sAUUPa0luZmluaXR5U3ltYm9sA+KIngprTmFOU3ltYm9sA++/vRhjcmVhdGVXaXRoTGFzdFJlc29ydERhdGEHcmVxdWlyZQZzY3JpcHQGUGFyZW50CV9pbnRlcm5hbBRjcmVhdGVfaW5pdF9mdW5jdGlvbhBJbW11dGFiaWxpdHlUeXBlB1NZTUJPTFMFdGFibGUGZnJlZXplAAQHAgEAAAcEAAAFAgQCGfsCAABNAgIFAAAAAE0CAkMBAAAAjAMBAFIEAABvBQIAnwIEAvsDAABNAwMFAAAAAE0DA9EDAAAAjAQCAFIFAQD7BgAATQYGewQAAABNBgZfBQAAAJ8DBAJSAQMAhwMCAYIDAgAGAwEDAgMDAwQDBQMGAA0HARgAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAIADgAAAAAIAwEAAAgFAAAFAwQCAyP7AwAATQMDBQAAAABNAwNDAQAAAIwEAQBSBQAAbwYCAJ8DBAL7BAAATQQEBQAAAABNBATRAwAAAIwFAgBSBgEA+wcAAE0HB3sEAAAATQcHXwUAAACfBAQCUgEEAPsEAABNBAQFAAAAAE0EBEMBAAAAjAUDAFIGAgBvBwYAnwQEAlICBABqAgMBggABAAcDAQMCAwMDBAMFAwYDCAAUCQEYAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAgEVAAAAAAQAAgAAAET7AAAA/wEEAAAAAAD7AgEATQICewAAAABNAgJfAQAAAE0CAtcCAAAAbwMDAGoDAQL7AgEATQICewAAAABNAgJfAQAAAE0CAjoEAAAAbwMFAGoDAQL7AgEATQICewAAAABNAgJfAQAAAE0CAl0GAAAAbwMHAGoDAQL7AgEATQICewAAAABNAgJfAQAAAE0CAqIIAAAAbwMJAGoDAQL7AgEATQICewAAAABNAgJfAQAAAE0CAhEKAAAAbwMLAGoDAQL7AgEATQICewAAAABNAgJfAQAAAE0CAqQMAAAAbwMNAGoDAQL7AgEATQICewAAAABNAgJfAQAAAE0CAuoOAAAAbwMPAGoDAQKfAAIAggAAABADBQMGAwoDCwMMAw0DDgMPAxADEQMSAxMDFAMVAxYDFwAcGAEYAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAAAQAAAAAAAAAA+QAdAAAAAAkAAAECADGjAAAApAABAAAAAECkAQMAAAAgQE0BASQEAAAATQEBJAQAAABNAQEUBQAAAJ8AAgL/AQEAAAAAAP8CAgAAAAAATQMABQYAAABNAwMdBwAAAG8ECADGBQAAUgYCAMYHAABNCAAFBgAAAE0ICM8JAAAATQgIjAoAAACfAwYCwAQLABIAAAAwBALtDAAAAMAEDQASAAAAMAQC2Q4AAADABA8AEgADABIAAAAwBAEtEAAAAKQEEwAASBCBUgUBAJ8EAgCCBAAAFAMZBAAAAEADGgQAACBAAxsDHAMBAx0DAwMeAx8GAAMHBgEDCQYCAxgDIAMhBABIEIEDAAECAQABGAAAAAAAAAAAAAAAAAIAAQABAAAAAQEBAQEAAAAAAPsIAAAABwAAAAgAAAAAEAAAAAABAAAAAAOgI5RK7wIgtXSi/imAFOev0DuDPpLn/ks=

-- decompilation:
local _internal = require(script.Parent.Parent._internal)
local t1 = {}
local t2 = {}
local v4 = _internal.class.create_init_function("DecimalFormatSymbols", nil, t2, nil, _internal.class.ImmutabilityType.SYMBOLS)

function t2.GetSymbol(t3: {[any]: any}, n1: number) -- line: 13
	-- upvalues: _internal (copy)
	return _internal.class.try_coerce(1.0, t3, "DecimalFormatSymbols")[_internal.class.try_coerce_enum(2.0, n1, _internal.enums.ENumberFormatSymbols)]
end
function t2.SetSymbol(t4: {[any]: any}, n2: number, s1: string) -- line: 20
	-- upvalues: _internal (copy)
	_internal.class.try_coerce(1.0, t4, "DecimalFormatSymbols")[_internal.class.try_coerce_enum(2.0, n2, _internal.enums.ENumberFormatSymbols)] = _internal.class.try_coerce(3.0, s1, "string")
end
function t1.createWithLastResortData() -- line: 28
	-- upvalues: v4 (copy), _internal (copy)
	return v4({
		[_internal.enums.ENumberFormatSymbols.kDecimalSeparatorSymbol] = ".",
		[_internal.enums.ENumberFormatSymbols.kGroupingSeparatorSymbol] = "",
		[_internal.enums.ENumberFormatSymbols.kMinusSignSymbol] = "-",
		[_internal.enums.ENumberFormatSymbols.kPlusSignSymbol] = "+",
		[_internal.enums.ENumberFormatSymbols.kExponentialSymbol] = "E",
		[_internal.enums.ENumberFormatSymbols.kInfinitySymbol] = "∞",
		[_internal.enums.ENumberFormatSymbols.kNaNSymbol] = "\239\191\189"
	})
end

return table.freeze(t1)

