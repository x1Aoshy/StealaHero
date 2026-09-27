-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMVEmludGVnZXJOb25OZWdhdGl2ZQZ0eXBlb2YGbnVtYmVyCmZyb21OdW1iZXIHR2V0Q29zdAdyZXF1aXJlCURpcmVjdG9yeQhQcm9kdWN0cw5DYXJyeVVwZ3JhZGVfMQlQcm9kdWN0SWQRR2V0Um9idXhQcm9kdWN0SWQMR2V0Um9idXhDb3N0BGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdMaWJyYXJ5B0Fzc2VydHMHTW9kdWxlcwtFdGVybml0eU51bQlGdW5jdGlvbnMIR2V0UHJpY2UABAQBAwAABgMAAAUBAhv7AQAATQEBxAAAAABSAgAAnwECAYwBAQBgAAMAAQAAAMYBAACCAQIA+wIBAIcBAgC7LAEDUgMBAKQCAgAAABBAnwICAvACAwADAAAAxgIAAIICAgD7AgIATQIChQQAAABSAwEAnwICAIICAAAFAwEDAgQAABBAAwMDBAAcBQEYAAAAAAACAAABAAMAAQAAAAAAAAEAAwAAAAAAHQAAAAAFAgMAAAcEAAAFAgICJfsCAABNAgLEAAAAAFIDAACfAgIB+wIAAE0CAsQAAAAAUgMBAJ8CAgENAQMAAQAAAMYCAACCAgIA+wIBAE0CAv8CAAAAUgMAAJ8CAgIrAgIAxgIAAIICAgCkAgQAAAAwQPsDAgBNAwORBQAAAE0DA0EGAAAAnwICAk0DApEFAAAATQMDEQcAAABNBAMLCAAAAIIEAgAJAwECAAAAAAAA8D8DBQMGBAAAMEADBwMIAwkDCgArCwEYAAAAAAABAAAAAAIAAQADAAAAAAABAAMAAAAAAAAAAQAAAAEAACwAAAAABgIDAAAHBAAABQICAhv7AgAATQICxAAAAABSAwAAnwICAfsCAABNAgLEAAAAAFIDAQCfAgIB+wIBAE0CAgMBAAAAUgMAAFIEAQCfAgMCKwICAMYDAACCAwIA+wMCAFIEAgCpBQEAnwMDAysEAgDGBQAAggUCAIIDAgACAwEDCwA8DAEYAAAAAAABAAAAAAIAAAAAAAEBAAMAAAABAQADPQAAAAALAAABAgA/owAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAqQBBQAAAEBATQIAagYAAABNAgKJBwAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMD6AgAAABNAwOTCQAAAJ8CAgKkAwUAAABAQE0EAGoGAAAATQQEUwoAAABNBAT5CwAAAJ8DAgL/BAAABgAAAIwFZABvBgwAbwcNAG8IDgBvCQ8AbwoQAMUEBQcBAAAA/wUDAAAAAADABhEAEgABABIABAASAAIAMAYF/xIAAADABhMAEgABABIABQASAAAAMAYFAxQAAADABhUAEgABABIABQASAAMAMAYFDhYAAACCBQIAFwMNBAAAAEADDgMPAwYEAABAQAMQAxEDEgMTAxQDFQIAAAAAgIQuQQIAAAAAZc29QQIAAADodkg3QgIAAJAexLzWQgIAgG2Bdt44QwYAAwUGAQMLBgIDDAMAAQIBAAEYAAMAAAAAAAMAAAAAAAABAAAAAAAAAAABAAAAAAAAAAAGAAEBAQEBAQAABAADAAAAAAAPAAAAAAARAAAAAAARAQAAAAADYb5vP7AmZniJrFbQxRH6/hGmeEtTegU+

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local EternityNum = require(ReplicatedStorage.Library.Modules.EternityNum)
local GetPrice = require(ReplicatedStorage.Library.Functions.GetPrice)
local t1 = {
	100.0,
	1000000.0,
	500000000.0,
	100000000000.0,
	100000000000000.0,
	7000000000000000.0
}
local t2 = {
	GetCost = function(n1: number) -- line: 28
		-- upvalues: Asserts (copy), t1 (copy), EternityNum (copy)
		Asserts.integerNonNegative(n1)

		if n1 < 1.0 then
			return nil
		end

		local v8 = t1[n1]

		if typeof(v8) ~= "number" then
			return nil
		end

		return EternityNum.fromNumber(v8)
	end
}

function t2.GetRobuxProductId(n2: number, n3: number) -- line: 43
	-- upvalues: Asserts (copy), t2 (copy), ReplicatedStorage (copy)
	Asserts.integerNonNegative(n2)
	Asserts.integerNonNegative(n3)

	if n3 ~= 1.0 then
		return nil
	end

	if not t2.GetCost(n2) then
		return nil
	end

	return require(ReplicatedStorage.Directory.Products).Directory.CarryUpgrade_1.ProductId
end
function t2.GetRobuxCost(n4: number, n5: number) -- line: 60
	-- upvalues: Asserts (copy), t2 (copy), GetPrice (copy)
	Asserts.integerNonNegative(n4)
	Asserts.integerNonNegative(n5)

	local v13 = t2.GetRobuxProductId(n4, n5)

	if not v13 then
		return nil
	end

	local v14, v15 = GetPrice(v13, true)

	if not v15 then
		return nil
	end

	return v14
end

return t2

