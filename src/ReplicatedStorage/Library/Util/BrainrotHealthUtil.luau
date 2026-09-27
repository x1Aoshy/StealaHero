-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMUDEdldERpcmVjdG9yeQNHZXQGdHlwZW9mBm51bWJlcgRtYXRoA21heAVmbG9vcgRCYXNlEENvbXB1dGVNYXhIZWFsdGgEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUJRGlyZWN0b3J5BkFzc2V0cwVwYWlycwpCYXNlSGVhbHRoDkJhc2VNb2RlbFNjYWxlCUJhc2VTY2FsZQNNaW4ABAEAAQAAAAL7AAAAggACAAAAKgEBGAAAKwAAAAADAQEAAAYDAAAFAQMD+wIAAIcBAgCCAQIAAAAuAgEYAAAALwAAAAALAgEAAAcEAAAFAgOCKfsDAACHAgMAKwIdALssAQNSBQEApAQBAAAAAECfBAIC8AQDAAIAAIBSAwEAKwMBAIwDAQCMBQoAgRIDBQQAAABSCQMAbwoEAKQIBwAAGFCAnwgDAlsHCAO7DAcCpAYJAAAgUICfBgICnhIFAwYAAACkBAcAABhQgJ8EAwKCBAIAjAQBAE0FAi4KAAAAnhIEAwUAAACkAwcAABhQgJ8DAwKCAwIACwMDBAAAAEADBAIAAAAAAABZQAKamZmZmZm5PwMFAwYEABhQgAMHBAAgUIADCAAyCQEYAAADAQAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAADAAAAAAAAABEzAAAAABEAAAEAAF6jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgCRBgAAAE0CAoEHAAAAnwECAk0CAZEGAAAA/wMAAAAAAACkBAkAAACAQFIFAgCfBAIEFwQ2AE0JCI8KAAAAuywJA1ILCQCkCgwAAACwQJ8KAgLwCgIADQAAAIwJZABNCgjJDgAAALssCgNSDAoApAsMAAAAsECfCwIC8AsEAA0AAICMCwAAfQoCAAsAAACMCgEAjAwBAFsPCQ+VDg8PuwwOAqQNEgAARACBnw0CAp4SDAMNAAAApAsUAABMAIGfCwMC4gwYAIwOAQCVEAkPuwwQAqQPEgAARACBnw8CAp4SDgMPAAAApA0UAABMAIGfDQMCMA0MLhUAAAAwCgxvFgAAADALDNgXAAAAagwDB24Eyf8CAAAA/wQDAAAAAADABRkAEgADADAFBN0aAAAAwAUbABIAAwAwBQR/HAAAAMAFHQASAAMAMAUEtB4AAACCBAIAHwMKBAAAAEADCwMMAw0EAABAQAMOAw8DEAQAAIBAAxEDAwQAALBAAwQDEgIAAAAAAADgPwMFAwcEAEQAgQMGBABMAIEDCAMTAxQFAxUWFwYAAwEGAQMCBgIDCQMAAQIBAAEYAAIAAAAAAAIAAAAAAAAIAAUAAgAAAAABAAEAAAAAAAABAwABAAAAAAAAAAAAAQMAAAAAAAAAAAAAAAIBAAAAAAAAAAAAAAAAAQABAP3zABQAAgAAAAQAAAAEAAAAHQEAAAAAA2fn2T2+A84Co4h0aQ2Cgb8X/85JVSOzPA==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Directory = require(ReplicatedStorage.Directory.Assets).Directory
local t1 = {}

for k, v in pairs(Directory) do
	local BaseHealth = v.BaseHealth

	if typeof(BaseHealth) ~= "number" then
		BaseHealth = 100.0
	end

	local BaseModelScale = v.BaseModelScale

	if typeof(BaseModelScale) ~= "number" or BaseModelScale <= 0.0 then
		BaseModelScale = 1.0
	end

	local v8 = math.max(1.0, (math.floor(BaseHealth * 0.5 + 0.5)))

	t1[k] = {
		Base = math.max(1.0, (math.floor(BaseHealth + 0.5))),
		BaseScale = BaseModelScale,
		Min = v8
	}
end

return {
	GetDirectory = function() -- line: 42
		-- upvalues: t1 (copy)
		return t1
	end,
	Get = function(s1: string) -- line: 46
		-- upvalues: t1 (copy)
		return t1[s1]
	end,
	ComputeMaxHealth = function(s2: string, n1: number?) -- line: 50
		-- upvalues: t1 (copy)
		local v12 = t1[s2]

		if not v12 then
			return (math.max(10.0, (math.floor(math.max(typeof(n1) == "number" and n1 or 1.0, 0.1) * 100.0))))
		end

		return (math.max(1.0, v12.Base))
	end
}

