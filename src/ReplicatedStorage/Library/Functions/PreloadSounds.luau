-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMXBHR5cGUGc3RyaW5nBXRhYmxlBmluc2VydAZudW1iZXINcmJ4YXNzZXRpZDovLwh0b3N0cmluZwVwYWlycwVlcnJvchBVbmtub3duIHR5cGU6ICVzBmZvcm1hdAtpbnNlcnRBc3NldARwYWNrAW4GaXBhaXJzCEluc3RhbmNlA25ldwVTb3VuZAdTb3VuZElkDFByZWxvYWRBc3luYwRnYW1lD0NvbnRlbnRQcm92aWRlcgpHZXRTZXJ2aWNlAAMLAgEAAAsEAAEFAgQPAwQ0Ajm7KAEDUgMBAKQCAQAAAABAnwICAvACCgACAACAnjQABQEAAABSBAAAUgUBAKQDBQAAEDCAnwMDAcYDAACCAwIA8AIQAAYAAIBvBgcAuz8BA1IIAQCkBwkAAACAQJ8HAgJzBQYHnjQABAUAAABSBAAApAMFAAAQMICfAwMBxgMAAIIDAgDwAg4AAwAAgKQDCwAAAKBAUgQBAJ8DAgQXAwQA+wgAAFIJAABSCgcAnwgDAW4D+/8CAAAAxgMAAIIDAgCkAw0AAADAQG8EDgBSBgIAvAQEjQ8AAACfBAMAnwMAAYIAAQAQAwEEAAAAQAMCAwMDBAQAEDCAAwUDBgMHBAAAgEADCAQAAKBAAwkEAADAQAMKAwsABQwBGAAAAAAAAQABAAAAAAAAAQABAAEAAAAAAAAAAAAAAAABAAEAAQAAAAABAAAA/wADAAIAAAAAAAAAAgYAAAAADAACAQAALqMAAAD/AAAAAAAAAKQBAgAABACA3QIAAJ8BAAKMBAEATQIBjwMAAACMAwEAqAIFAPsFAABSBgAAhwcBBJ8FAwGLAvv//wIAAAAAAACkAwUAAABAQFIEAACfAwIEUQMNAKQICAAAHGCAbwkJAJ8IAgIwBwh8CgAAAJ40AgUIAAAAUgoCAFILCACkCQwAACwAgJ8JAwFuA/L/AgAAgPsDAQBSBQIAvAMDTw0AAACfAwMBxgMAAIIDAgAOAwMDDQQABACAAw4DDwQAAEBAAxADEQQAHGCAAxIDEwMEBAAsAIADFAAXAAEYAAEAAQAAAAEAAAAAAQAAAP8EAAEAAAAAAQAAAAEAAQAAAAAAAP0ABgAAAAABABcAAAAAAwAAAQIADaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwLAAQQAEgABAMACBQASAAEAEgAAAIICAgAGAxUEAAAAQAMWAxcGAAYBAgABAQABGAAAAAAAAAAEABIAAAABAAAAAALM6ay1XN6IxkRRzJmRTF/kvPG7wf4txrQ=

-- decompilation:
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Speedsters audio: only whitelisted ids are ever requested (Library.Audio.ResolveSoundUri); others stay silent.
-- Required lazily so this module never joins a require cycle with Library.Audio.
local SpeedstersAudio = nil

local function resolveSoundUri(soundId): string?
	if SpeedstersAudio == nil then
		local ok, result = pcall(require, ReplicatedStorage.Library.Audio)
		SpeedstersAudio = if ok and type(result) == "table" and type(result.ResolveSoundUri) == "function" then result else false
	end

	return if SpeedstersAudio then SpeedstersAudio.ResolveSoundUri(soundId) else nil
end

local function insertAsset(t1: {[any]: any}, p1) -- line: 5
	-- upvalues: insertAsset (copy)
	local v5 = type(p1)

	if v5 == "string" then
		table.insert(t1, p1)

		return nil
	end

	if v5 == "number" then
		table.insert(t1, "rbxassetid://" .. tostring(p1))

		return nil
	end

	if v5 == "table" then
		for _, v in pairs(p1) do
			insertAsset(t1, v)
		end

		return nil
	end

	error(("Unknown type: %s"):format(v5))
end

return function(...) -- line: 23
	-- upvalues: insertAsset (copy), ContentProvider (copy)
	local t2 = {}
	local v9 = table.pack(...)

	for i = 1.0, v9.n do
		insertAsset(t2, v9[i])
	end

	local t3 = {}

	for _, v in ipairs(t2) do
		local soundUri = resolveSoundUri(v)

		if soundUri then
			local Sound = Instance.new("Sound")

			Sound.SoundId = soundUri
			table.insert(t3, Sound)
		end
	end

	if #t3 > 0 then
		ContentProvider:PreloadAsync(t3)
	end

	return nil
end

