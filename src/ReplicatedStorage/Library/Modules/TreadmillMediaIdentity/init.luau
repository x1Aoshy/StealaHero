-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)

require(ReplicatedStorage.Library.Modules.TreadmillMediaIdentity.Types.Interface)
require(ReplicatedStorage.Library.Client.TreadmillVideoController.Types.Interface)

local t1 = {}

local function extractAssetId(s1: string) -- line: 22
	local match = string.match(s1, "%d+")

	assert(match ~= nil and match ~= "", `Invalid treadmill media asset id "{ s1 }"`)

	return match
end

function t1.GetMediaKey(p1) -- line: 32
	-- upvalues: Asserts (copy)
	Asserts.table(p1)

	if p1.Kind == "Video" then
		local Video = p1.Video
		local match = string.match(Video, "%d+")

		assert(match ~= nil and match ~= "", `Invalid treadmill media asset id "{ Video }"`)

		return `Video:{ match }`
	end

	local p1Image = p1.Image
	local match = string.match(p1Image, "%d+")

	assert(match ~= nil and match ~= "", `Invalid treadmill media asset id "{ p1Image }"`)

	return `Image:{ match }`
end
function t1.BuildMediaKeys(t2: {[any]: any}) -- line: 42
	-- upvalues: Asserts (copy), t1 (copy)
	Asserts.table(t2)

	local t3 = {}
	local t4 = {}

	for _, v in ipairs(t2) do
		local v17 = t1.GetMediaKey(v)

		if not t4[v17] then
			t4[v17] = true
			table.insert(t3, v17)
		end
	end

	return t3, t4
end
function t1.GetMediaKeyShardIndex(p2, n1: number) -- line: 63
	-- upvalues: Asserts (copy)
	Asserts.string(p2)
	Asserts.positiveInteger(n1)

	local n2 = 0.0

	for i = 1.0, #p2 do
		n2 = (n2 * 33.0 + string.byte(p2, i)) % n1
	end

	return n2
end

return t1

