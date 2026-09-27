local DataStoreService = game:GetService("DataStoreService")
local store = nil
local memoryGlobalStore = {}
local ok, ds = pcall(function()
	return DataStoreService:GetDataStore("GlobalStats_v1")
end)

if ok and ds then
	store = ds
else
	store = {
		GetAsync = function(self, key)
			return memoryGlobalStore[key] or 0
		end,
		UpdateAsync = function(self, key, fn)
			local res = fn(memoryGlobalStore[key] or 0)
			memoryGlobalStore[key] = res
			return res
		end,
	}
end

local GlobalStatsService = {}

local cache = {} 
local loaded = {} 

local function loadStat(statName)
	local ok, value = pcall(function()
		return store:GetAsync(statName)
	end)
	if ok then
		cache[statName] = value or 0
	else
		warn("[GlobalStatsService] GetAsync failed for '" .. statName .. "': " .. tostring(value))
		if cache[statName] == nil then
			cache[statName] = 0
		end
	end
	loaded[statName] = true
	return cache[statName]
end

function GlobalStatsService.Get(statName)
	if cache[statName] == nil then
		return loadStat(statName)
	end
	return cache[statName]
end

function GlobalStatsService._IsLoaded(statName)
	if statName then
		return loaded[statName] == true
	end
	return next(loaded) ~= nil
end

function GlobalStatsService.Increment(statName, delta)
	delta = delta or 1
	local ok, newValue = pcall(function()
		return store:UpdateAsync(statName, function(old)
			return (old or 0) + delta
		end)
	end)
	if ok then
		cache[statName] = newValue
		loaded[statName] = true
		return newValue
	end
	warn("[GlobalStatsService] UpdateAsync failed for '" .. statName .. "': " .. tostring(newValue))
	cache[statName] = (cache[statName] or 0) + delta
	return cache[statName]
end

return GlobalStatsService
