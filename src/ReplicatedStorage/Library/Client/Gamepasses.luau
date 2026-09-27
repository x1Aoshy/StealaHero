-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMcBHR5cGUGbnVtYmVyBnN0cmluZxRVbmtub3duIGdhbWVwYXNzOiAlKgZmb3JtYXQGYXNzZXJ0CVByb2R1Y3RJZANfaWQHaW50ZWdlcg9wYXJzZUdhbWVwYXNzSWQHR2V0QnlJZANHZXQKR2FtZXBhc3NlcwRPd25zC0xvY2FsUGxheWVyBkdldEFsbARnYW1lB1BsYXllcnMKR2V0U2VydmljZRFSZXBsaWNhdGVkU3RvcmFnZQdMaWJyYXJ5DFdhaXRGb3JDaGlsZAdyZXF1aXJlB0Fzc2VydHMJRGlyZWN0b3J5BkNsaWVudARTYXZlBXBhaXJzAAUIAQIAAAA7xgEAALsoAANSAwAApAIBAAAAAECfAgIC8AIDAAIAAIBSAQAAZQArALsoAANSAwAApAIBAAAAAECfAgIC8AIRAAMAAID7AwAAhwIDAG8FBABSBwAAvAUFjQUAAACfBQMCngECBAUAAABSBAIApAMHAAAAYECfAwMBTQECCwgAAABlABQA+wUAAE0GANMJAAAAhwQFBvEEAgAAAAAAqQMAAakDAQBvBAQAUgYAALwEBI0FAAAAnwQDAp4BAwMEAAAApAIHAAAAYECfAgMBTQEACwgAAAD7AgEATQICIwoAAABSAwEAnwICAYIBAgALAwEEAAAAQAMCAwMDBAMFAwYEAABgQAMHAwgDCQAYCgEYAAEAAAAAAAABAAEAAAAAAAABAAEAAAAAAAAAAAAAAQAAAgAAAAAAAAAAAAAAAAAAAAAAAQACAAAAAAEZAAAAAAMBAgAABgMAAAUBAgj7AQAATQEBIwAAAABSAgAAnwECAfsCAQCHAQIAggECAAEDCQAoCwEYAAAAAAABAAApAAAAAAkCAwAABwQAAAUCD4ci+wIAAFIDAACfAgIC+wQBAIcDBAJvBgAAUggAALwGBo0BAAAAnwYDAp4BAwQGAAAAUgUDAKQEAwAAACBAnwQDAfsEAgBNBAR/BAAAAFIFAQCfBAICKwQCAKkFAACCBQIATQcEPAUAAABNCAPTBgAAAIcGBwgqBgIAAQAAAKkFAAGpBQEAggUCAAcDBAMFAwYEAAAgQAMMAw0DCAAtDgEYAAAAAQABAAAAAAAAAAAAAAIAAAAAAQEAAgAAAAAAAAAAAC4AAAAAAwECAAAGAwAABQGHElIBAAArAQMA+wEAAE0BATEAAAAAUgABAPsBAQBNAQF/AQAAAFICAACfAQICDgEDAE0CATwCAAAAggICAP8CAAAAAAAAggICAAMDDwMMAw0AOhABGAAAAAAAAAEAAAAAAQEAAAIAADsAAAAADwAAAQAAT6MAAACkAAEAAAAAQG8CAgC8AAAWAwAAAJ8AAwKkAQEAAAAAQG8DBAC8AQEWAwAAAJ8BAwJvBAUAvAIB0wYAAACfAgMCpAMIAAAAcEBNBAKJCQAAAJ8DAgKkBAgAAABwQE0FAZEKAAAATQUFPAsAAACfBAICTQUEkQoAAACkBggAAABwQG8JDAC8BwLTBgAAAJ8HAwJvCQ0AvAcH0wYAAACfBwMAnwYAAv8HAAAAAAAApAgPAAAA4EBSCQUAnwgCBBcIBgBNDQwLEAAAAA4NAwCHDgcNKw4BAGoMBw1uCPn/AgAAAP8IAwAAAAAAwAkRABIABQASAAMAwAoSABIAAwASAAcAMAoIeBMAAADAChQAEgAJABIABwASAAYAMAoIYxUAAADAChYAEgAAABIABgAwCgjQFwAAAIIIAgAYAxEEAAAAQAMSAxMDFAMVAxYDFwQAAHBAAxgDGQMNAxoDGwMcBAAA4EADBwYABgEDCwYCAw4GAwMQBAABAgMBAAEYAAIAAAAAAAEAAAAAAAEAAAACAAAAAAEAAAAAAAABAAEAAAAAAAAAAAAAAgABAAAAAAEAAQAAAf0ACQACAAAQAAAAAAUAAAAAAA0AAAAACgEAAAAABJvQrGLqCucM0KsUmKqR+3/ryLsWqRTGYw==

-- decompilation:
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")
local Asserts = require(Library.Asserts)
local Directory = require(ReplicatedStorage.Directory.Gamepasses).Directory
local Save = require(Library:WaitForChild("Client"):WaitForChild("Save"))
local t1 = {}

for _, v in pairs(Directory) do
	local ProductId = v.ProductId

	if ProductId and not t1[ProductId] then
		t1[ProductId] = v
	end
end

local t2 = {}

local function parseGamepassId(p1) -- line: 24
	-- upvalues: Directory (copy), Asserts (copy)
	if type(p1) == "number" then
	elseif type(p1) == "string" then
		local v14 = Directory[p1]

		assert(v14, `Unknown gamepass: { p1 }`)
		p1 = v14.ProductId
	else
		assert(p1 == Directory[p1._id], `Unknown gamepass: { p1 }`)
		p1 = p1.ProductId
	end

	Asserts.integer(p1)

	return p1
end

function t2.GetById(n1: number) -- line: 40
	-- upvalues: Asserts (copy), t1 (copy)
	Asserts.integer(n1)

	return t1[n1]
end
function t2.Owns(p2, p3) -- line: 45
	-- upvalues: parseGamepassId (copy), t1 (copy), Save (copy)
	local v18 = t1[parseGamepassId(p2)]

	assert(v18, `Unknown gamepass: { p2 }`)

	local v19 = Save.Get(p3)

	if not v19 then
		return false
	end

	return v19.Gamepasses[v18._id] == true
end
function t2.GetAll(p4) -- line: 58
	-- upvalues: Players (copy), Save (copy)
	local v21 = p4 or Players.LocalPlayer
	local v22 = Save.Get(v21)

	if v22 then
		return v22.Gamepasses
	end

	return {}
end

return t2

