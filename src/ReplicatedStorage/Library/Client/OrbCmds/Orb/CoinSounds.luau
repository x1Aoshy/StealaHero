-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMaBUNvdW50DUxvb3RUaWVySW5kZXgFUXVldWUEbmV4dAVwYWlycwZTb3VuZHMFTXVsdGkGU2luZ2xlBERhdGEEUGxheQNJZHMGc2NyaXB0BVNwZWVkBlZvbHVtZQRnYW1lClJ1blNlcnZpY2UKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdMaWJyYXJ5DFdhaXRGb3JDaGlsZAdyZXF1aXJlBUF1ZGlvCURpcmVjdG9yeQhDdXJyZW5jeQlIZWFydGJlYXQHQ29ubmVjdAADBAIBAAAHBAAABQIDgg77AwAAhwIDACsCAwDiAgMAMAECGwIAAABNAwI6AAAAAJUDAwQwAwI6AAAAAPsDAABqAgMAggABAAUDAQIAAAAAAAAAAAMCCAIAAQAAAAL/////AgAAAAAAAPA/ABYDARgAAAAAAgADAAAAAAEAARcAAAAAEQAEAAAAM/sAAACkAQEAAAAAQFICAACfAQICDgEsAP8BAAAAAAAA3gEAAKQBAwAAACBAUgIAAJ8BAgQXASIA+wcBAIcGBwRNBwYoBAAAAE0IBToFAAAAjAoCAH0KBAAIAAAATQkH5QYAAAArCQIATQkHgAcAAABNCgnGCAAAACsKAgD/CgAAAAAAAPsLAgBNCwvuCQAAAE0MCZMKAAAApA0MAAAAsEBNDgosDQAAACsOAQD7DgMATRAKSw8AAACQDxAOnwsFAW4B3f8CAAAAggABABADBAQAAABAAwUEAAAgQAMGAwEDBwMIAwkDCgMLAwwEAACwQAMNAgAAAAAAAOA/Aw4AIAABGAABAAAAAAEAAAEAAAAAAQABAAIAAQAAAAAAAAACAAAAAAIAAAAAAAAAAAAAAAAAAPcADCEAAAAACwAAAQIAOaMAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwJvBAUAvAIB0wYAAACfAgMCpAMIAAAAcEBNBALSCQAAAJ8DAgKkBAgAAABwQE0FAZEKAAAATQUFCQsAAACfBAICTQQEkQoAAAD/BQEAAAAAAP8GAAACAAAAbwcMAG8IDQDFBgcDAQAAAP8HAAAAAAAA2QgAABIBB/8wCAU3DgAAAE0IAP0PAAAA2QoBABIBB/8SAAQAEgADABIABgC8CAjHEAAAAJ8IAwHBBwAAggUCABEDDwQAAABAAxADEQMSAxMDFAMVBAAAcEADFgMXAxgCZmZmZmZm7j8CzczMzMzM8D8DAwMZAxoCAAEBAAEYAAAAAAAAAAEAAAAAAAEAAAACAAAAAAEAAAAAAAAAAAIAAgAAAAAACgACAAAACgAAAAAAAAAAABIAAQAAAAACAdp1CWDuZQJcmguKtI4P93HCYn0zHh8I

-- decompilation:
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local Audio = require(Library.Audio)
local Directory = require(ReplicatedStorage.Directory.Currency).Directory
local t1 = {}
local t2 = {
	0.95,
	1.05
}
local t3 = {}

function t1.Queue(s1: string, n1: number?) -- line: 22
	-- upvalues: t3 (ref)
	local v11 = t3[s1] or {
		Count = 0.0,
		LootTierIndex = n1
	}

	v11.Count = v11.Count + 1.0
	t3[s1] = v11
end

RunService.Heartbeat:Connect(function() -- line: 32
	-- upvalues: t3 (ref), Directory (copy), Audio (copy), t2 (copy)
	local v12 = t3

	if next(v12) then
		t3 = {}

		for k, v in pairs(v12) do
			local Sounds = Directory[k].Sounds
			local v16 = v.Count >= 2.0 and Sounds.Multi or Sounds.Single
			local v17 = v16.Data or {}

			Audio.Play(v16.Ids, script, v17.Speed or t2, v17.Volume or 0.5)
		end
	end
end)

return t1

