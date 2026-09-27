-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMBXRhYmxlBG1vdmUGdW5wYWNrBGZ1bmMRV3JhcFNlbGZUb0Nvbm5lY3QNQ3JlYXRlV3JhcHBlcgdyZXF1aXJlBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdMaWJyYXJ5B0Fzc2VydHMABQgAAwEAACyjAAAA/wAAAAAAAADdAQAAxQABAAEAAAD/AQAAAAAAAPsDAAAcAgMADQITAAAAAACkAgMAAAgQgPsDAACMBAEA+wYAABwFBgCMBgEAUgcBAJ8CBgGkAgMAAAgQgFIDAACMBAEAHAUAABwHAQCVBgcEUgcBAJ8CBgH7AgEA+wMCABwGAQANBgMAAAAAAFIFAQArBQEAUgUAALs1BQKkBAYAAABQQJ8EAgCfAgAAggIAAAcCAAAAAAAAAAADAQMCBAAIEIACAAAAAAAA8D8DAwQAAFBAACkAARgAAQAAAAABAAIAAAABAAAAAAAAAAABAAAAAAAAAAADAAAAAAAAAAAAAAAAACkAAAAABAIBAQAHBAAABQIPBRWjAgAA+wIAAE0CAksAAAAAUgMAAJ8CAgH7AgAATQICZgEAAABSAwEAnwICAf8CAAAAAAAA3QMAAMUCAwABAAAA2QMAABIAAgASAAEAEgAAAIIDAgACAwEDBAEAIwUBGAABAAAAAAEAAAAAAgAAAAACAAAAACMAAAAABQECAQAGAwAABQEFB6MBAAD7AQAA+wIBAFIDAADdBAAAnwEAAIIBAAAAADcAARgAAQAAAAAANwAAAAACAQEAAAAE2QEAABICAAASAAAAggECAAABAjYGARgAAAAANwAAAAAEAAABAgAYowAAAKQAAQAAAABApAEDAAAAIEBvAwQAvAEBFgUAAACfAQMCTQEBagYAAABNAQGJBwAAAJ8AAgLAAQgAEgAAAMACCQASAAEA4gMMADABAy4KAAAAMAID9AsAAACCAwIADQMHBAAAAEADCAQAACBAAwkDCgMLAwwGAQYDAwUDBgUCCgsCAQMBAAEYAB8AAAAAAAAAAAAAAAADABMABgEAAQAAAQAAAAAEUkZX8HnG80CW1gd1NNLEVSJeQIRggj3x

-- decompilation:
local Asserts = require(game:GetService("ReplicatedStorage").Library.Asserts)

local function WrapSelfToConnect(p1, p2: ((...any) -> ...any), ...) -- line: 35
	-- upvalues: Asserts (copy)
	Asserts.table(p1)
	Asserts.func(p2)

	local t1 = { ... }

	return function(...) -- line: 41
		-- upvalues: t1 (copy), p2 (copy), p1 (copy)
		local t2 = { ... }
		local t3 = {}

		if #t1 ~= 0.0 then
			table.move(t1, 1.0, #t1, 1.0, t3)
			table.move(t2, 1.0, #t2, #t3 + 1.0, t3)
		end

		return p2(p1, unpack(#t3 ~= 0.0 and t3 or t2))
	end
end

return {
	WrapSelfToConnect = WrapSelfToConnect,
	CreateWrapper = function(p3) -- line: 54
		-- upvalues: WrapSelfToConnect (copy)
		return function(p4: ((...any) -> ...any), ...) -- line: 55
			-- upvalues: WrapSelfToConnect (copy), p3 (copy)
			return WrapSelfToConnect(p3, p4, ...)
		end
	end
}

