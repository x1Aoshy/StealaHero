-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMGCHRvS2VsdmluDHRvRmFocmVuaGVpdAl0b0NlbHNpdXMGS2VsdmluB0NlbHNpdXMKRmFocmVuaGVpdAAHAgEAAAAGAwAABQECApUBAACCAQIAAQIAAAAAABBxQAAVAQEYAAAWAAAAAAMBAAAABgMAAAUBAgNbAgABlQECAIIBAgACAgAAAAAAAEBAAs3MzMzMzPw/ABgCARgAAAAZAAAAAAIBAAAABgMAAAUBAgJ4AQAAggECAAECAAAAAAAQcUAAHQMBGAAAHgAAAAAEAQIAAAYDAAAFAQIK+wEAAE0BAXIAAAAA+wIBAE0CAgwBAAAAUgMAAJ8CAgCfAQAAggEAAAIDAgMDACACARgAAAAAAAAAAAAAIQAAAAADAQAAAAYDAAAFAQIDeAIAAT4BAgCCAQIAAgLNzMzMzMz8PwIAAAAAAABAQAAlAwEYAAAAJgAAAAAEAQIAAAYDAAAFAQIK+wEAAE0BAXEAAAAA+wIBAE0CAgwBAAAAUgMAAJ8CAgCfAQAAggEAAAIDAQMDACgBARgAAAAAAAAAAAAAKQAAAAAEAAABAgAlowAAAP8AAgAAAAAAwAEAADABAHEBAAAAwAECADABAHIDAAAA/wECAAAAAADAAgQAMAIBDAUAAADAAgYAEgAAABIAAQAwAgFyAwAAAP8CAgAAAAAAwAMHADADAgwFAAAAwAMIABIAAAASAAIAMAMCcQEAAADiAwwAMAEDKgkAAAAwAAOUCgAAADACA48LAAAAggMCAA0GAAMBBgEDAgYCAwMGAwYEBgUDBAMFAwYFAwkKCwYAAQIDBAUBAAEYABMAAQAAAwAABAABAAADAAAAAAQAAQAAAwAAAAAEAQABAAEAAAEAAAAABo4YPwgfCxu6F1M00x8xrtX+ACh8vNxVCQ==

-- decompilation:
local t1 = {
	toKelvin = function(n1: number) -- line: 21
		return n1 + 273.0
	end,
	toFahrenheit = function(n2: number) -- line: 24
		return n2 * 1.8 + 32.0
	end
}
local t2 = {
	toCelsius = function(n3: number) -- line: 29
		return n3 - 273.0
	end
}

function t2.toFahrenheit(n4: number) -- line: 32
	-- upvalues: t1 (copy), t2 (copy)
	return t1.toFahrenheit(t2.toCelsius(n4))
end

local t3 = {
	toCelsius = function(n5: number) -- line: 37
		return (n5 - 32.0) / 1.8
	end
}

function t3.toKelvin(n6: number) -- line: 40
	-- upvalues: t1 (copy), t3 (copy)
	return t1.toKelvin(t3.toCelsius(n6))
end

return {
	Kelvin = t2,
	Celsius = t1,
	Fahrenheit = t3
}

