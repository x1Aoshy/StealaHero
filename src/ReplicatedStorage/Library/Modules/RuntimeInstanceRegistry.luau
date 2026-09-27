-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBnN0cmluZwhJbnN0YW5jZQdDaGFuZ2VkBEZpcmUDU2V0BlBhcmVudANHZXQgTWlzc2luZyBydW50aW1lIGluc3RhbmNlICIlKi8lKiIGZm9ybWF0BmFzc2VydAdSZXF1aXJlCG9wdGlvbmFsBUNsZWFyBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdyZXF1aXJlB0xpYnJhcnkHQXNzZXJ0cwdNb2R1bGVzCFBhY2thZ2VzBlNpZ25hbANuZXcABQkDAwAACAUAAAUDAwMHIvsDAABNAwNBAAAAAFIEAACfAwIB+wMAAE0DA0EAAAAAUgQBAJ8DAgH7AwAATQMD9AEAAABSBAIAnwMCAfsEAQCHAwQARwMFAAAAAID/AwAAAAAAAPsEAQBqAwQAagIDAfsEAgBNBASFAgAAAFIGAABSBwEAUggCALwEBN0DAAAAnwQFAYIAAQAEAwEDAgMDAwQAFQUBGAAAAAAAAQAAAAABAAAAAAEAAQABAAEAAgEAAAAAAAAAAAEWAAAAAAYCAgAABwQAAAUCAwMb+wIAAE0CAkEAAAAAUgMAAJ8CAgH7AgAATQICQQAAAABSAwEAnwICAfsDAQCHAgMARwIDAAAAAIDGAwAAZQABAIcDAgFHAwcAAAAAAE0FAyQBAAAARwUDAAAAAABSBAMAggQCAMYEAACCBAIAAgMBAwYAIgcBGAAAAAAAAQAAAAABAAEAAAAAAQAAAAAAAAAAACMAAAAACQIBAAAHBAAABQIDAxb7AgAATQICfwAAAABSAwAAUgQBAJ8CAwJHAgIAAAAAgKkEAAGpBAEAbwUBAFIHAABSCAEAvAUFjQIAAACfBQQCngEEAwUAAACkAwQAAAAwQJ8DAwGCAgIABQMHAwgDCQMKBAAAMEAAKgsBGAAAAAAAAAEAAAAAAAAAAAAAAAAAAAErAAAAAAgCAwAABwQAAAUCA4Mz+wIAAE0CAkEAAAAAUgMAAJ8CAgH7AgAATQICEQEAAABNAgJBAAAAAFIDAQCfAgIBRwETAAAAAID7AwEAhwIDAEcCAgAAAACAggABAPsCAQDGAwAAagMCAPsCAgBNAgKFAgAAAFIEAADGBQAAxgYAALwCAt0DAAAAnwIFAYIAAQD7AwEAhwIDAEcCDwAAAAAAhwMCAUcDDAAAAAAAxgMAAGoDAgH7AwIATQMDhQIAAABSBQAAUgYBAMYHAAC8AwPdAwAAAJ8DBQGCAAEABAMBAwwDAwMEADANARgAAAAAAAEAAAAAAAABAAEAAAABAgAAAQAAAAAAAAAAAQIAAQAAAAABAAEAAAAAAAAAAAIxAAAAAAYAAAECADijAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAokHAAAAnwECAqQCBQAAAEBATQMAagYAAABNAwPoCAAAAE0DA+YJAAAATQMDHwoAAACfAgIC/wMAAAAAAAD/BAQAAAAAAE0FAu8LAAAAnwUBAjAFBIUMAAAAwAUNABIAAQASAAMAEgAEADAFBHMOAAAAwAUPABIAAQASAAMAMAUEfxAAAADABREAEgAEADAFBO4SAAAAwAUTABIAAQASAAMAEgAEADAFBJAUAAAAggQCABUDDgQAAABAAw8DEAMRBAAAQEADEgMTAxQDFQMWAxcDAwYAAwUGAQMHBgIDCwYDAw0EAAECAwEAARgAAwAAAAAAAwAAAAAAAAEAAAAAAAAAAAAAAwADAAEAAAAABgAAAAAADQAAAAAIAAAABgAAAAAAEgEAAAAABJ24a2cXI5ICODz0IDa5927toHwTr3wBZg==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local t1 = {}
local t2 = {
	Changed = require(ReplicatedStorage.Library.Modules.Packages.Signal).new()
}

function t2.Set(s1: string, s2: string, p1) -- line: 21
	-- upvalues: Asserts (copy), t1 (copy), t2 (copy)
	Asserts.string(s1)
	Asserts.string(s2)
	Asserts.Instance(p1)

	local v8 = t1[s1]

	if v8 == nil then
		v8 = {}
		t1[s1] = v8
	end

	v8[s2] = p1
	t2.Changed:Fire(s1, s2, p1)
end
function t2.Get(s3: string, s4: string) -- line: 34
	-- upvalues: Asserts (copy), t1 (copy)
	Asserts.string(s3)
	Asserts.string(s4)

	local v11 = t1[s3]
	local v12 = if v11 ~= nil then v11[s4] else nil

	if v12 ~= nil and v12.Parent ~= nil then
		return v12
	end

	return nil
end
function t2.Require(s5: string, s6: string) -- line: 42
	-- upvalues: t2 (copy)
	local v15 = t2.Get(s5, s6)

	assert(v15 ~= nil, `Missing runtime instance "{ s5 }/{ s6 }"`)

	return v15
end
function t2.Clear(s7: string, s8: string?) -- line: 48
	-- upvalues: Asserts (copy), t1 (copy), t2 (copy)
	Asserts.string(s7)
	Asserts.optional.string(s8)

	if s8 == nil then
		if t1[s7] == nil then
			return
		end

		t1[s7] = nil
		t2.Changed:Fire(s7, nil, nil)

		return
	end

	local v18 = t1[s7]

	if v18 ~= nil and v18[s8] ~= nil then
		v18[s8] = nil
		t2.Changed:Fire(s7, s8, nil)
	end
end

return t2

