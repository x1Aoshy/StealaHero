-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ContentProvider = game:GetService("ContentProvider")

local function insertAsset(t1: {[any]: any}, p1) -- line: 8
	-- upvalues: insertAsset (copy)
	if typeof(p1) == "Instance" or type(p1) == "string" then
		table.insert(t1, p1)

		return
	end

	if type(p1) == "number" then
		table.insert(t1, (("rbxassetid://%d"):format(p1)))

		return
	end

	if type(p1) == "table" then
		for _, v in pairs(p1) do
			insertAsset(t1, v)
		end

		return
	end

	error(("Unknown type: %s"):format((type(p1))))
end
local function preloadWithRetry(t2: {[any]: any}, s1: string) -- line: 25
	-- upvalues: ContentProvider (copy)
	local v10 = table.clone(t2)

	for i = 1.0, 3.0 do
		local t3 = {}

		local function onStatus(p2, p3) -- line: 32
			-- upvalues: t3 (ref)
			if p3 ~= Enum.AssetFetchStatus.Success then
				table.insert(t3, p2)
			end
		end

		local ok, result = pcall(ContentProvider.PreloadAsync, ContentProvider, v10, onStatus)

		if not ok then
			warn(("PreloadAsync threw on attempt %d: %s"):format(i, result), s1)
			t3 = v10
		end

		if #t3 == 0.0 then
			return true
		end

		v10 = t3
		task.wait(i * 0.5)
	end

	return false, v10
end

return function(...) -- line: 55
	-- upvalues: insertAsset (copy), preloadWithRetry (copy)
	local t4 = {}
	local v17 = table.pack(...)

	for i = 1.0, v17.n do
		insertAsset(t4, v17[i])
	end

	local trace = debug.traceback()
	local v20, v21 = preloadWithRetry(t4, trace)

	if not v20 then
		warn(("still failing after %d retries:"):format(3.0), v21, trace)
	end

	return t4
end

