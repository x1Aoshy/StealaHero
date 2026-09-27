-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOB1BlcmZvcm0MbWF0aE9wZXJhdG9yBENtZHIEVXRpbAxNYWtlRW51bVR5cGUNTWF0aCBPcGVyYXRvcgROYW1lASsBLQEqAS8CKioBJQxSZWdpc3RlclR5cGUACAMCAAAAAAJDAgABggICAAAABQEBGAAABgAAAAADAgAAAAACJgIAAYICAgAAAAsBARgAAAwAAAAAAwIAAAAAAgkCAAGCAgIAAAARAQEYAAASAAAAAAMCAAAAAALsAgABggICAAAAFwEBGAAAGAAAAAADAgAAAAACsgIAAYICAgAAAB0BARgAAB4AAAAAAwIAAAAAAs8CAAGCAgIAAAAjAQEYAAAkAAAAAA4BAAAAAClvAwAATQQAngEAAABNBASeAgAAAE0EBLIDAAAAbwUEAP8GAAAGAAAA4gcIAMAICQAwCAdcBwAAAOIICwDACQwAMAkIXAcAAADiCQ4AwAoPADAKCVwHAAAA4goRAMALEgAwCwpcBwAAAOILFADADBUAMAwLXAcAAADiDBcAwA0YADANDFwHAAAAxQYHBwEAAACfBAMAvAEA3RkAAACfAQABggABABoDAgMDAwQDBQMGAwcDCAMBCAIFBgAAAAf/////BgADCQgCBQoAAAAH/////wYBAwoIAgUNAAAAB/////8GAgMLCAIFEAAAAAf/////BgMDDAgCBRMAAAAH/////wYEAw0IAgUWAAAAB/////8GBQMOBgABAgMEBQEAARgAAAAAAAAAAAAAAQIAAAQCAAAEAgAABAIAAAQCAAAEAgAAAADfAAAAJgIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGBgEGAQABGAAAAAEAAAAAB1KTU6sFqxVWRiPfrqCBwJQii0TfYFc5qg==

-- decompilation:
return function(p1) -- line: 1
	p1:RegisterType("mathOperator", p1.Cmdr.Util.MakeEnumType("Math Operator", {
		{
			Name = "+",
			Perform = function(p2, p3) -- line: 5
				return p2 + p3
			end
		},
		{
			Name = "-",
			Perform = function(p4, p5) -- line: 11
				return p4 - p5
			end
		},
		{
			Name = "*",
			Perform = function(p6, p7) -- line: 17
				return p6 * p7
			end
		},
		{
			Name = "/",
			Perform = function(p8, p9) -- line: 23
				return p8 / p9
			end
		},
		{
			Name = "**",
			Perform = function(p10, p11) -- line: 29
				return p10 ^ p11
			end
		},
		{
			Name = "%",
			Perform = function(p12, p13) -- line: 35
				return p12 % p13
			end
		}
	}))
end

