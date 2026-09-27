-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Signal = require(ReplicatedStorage.Library.Modules.Packages.Signal)
local GameAnalytics = require(ReplicatedStorage.Library.Modules.Packages.GameAnalytics)
local ABTestExperiments = require(ReplicatedStorage.Directory.ABTestExperiments)
local LocalPlayer = Players.LocalPlayer
local t7 = {
	_loaded = false,
	_loadedSignal = Signal.new(),
	_remoteConfigs = {},
	_runExperiments = function(t1: {[any]: any}) -- line: 27
		-- upvalues: ABTestExperiments (copy), LocalPlayer (copy)
		if not t1._remoteConfigs then
			return
		end

		for _, v11 in ABTestExperiments do
			if not v11.Disabled then
				local v12 = t1._remoteConfigs[v11.RemoteConfig] or v11.DefaultState
				local v13 = v11.States[v12]

				if v13 and v13.Client then
					task.defer(v13.Client, LocalPlayer, v12)
				end
			end
		end
	end,
	IsLoaded = function(t2: {[any]: any}) -- line: 43
		return t2._loaded
	end,
	OnLoad = function(t3: {[any]: any}, p1: ((...any) -> ...any)) -- line: 47
		return t3._loadedSignal:Connect(p1)
	end,
	GetRemoteConfig = function(t4: {[any]: any}, s1: string) -- line: 51
		return t4._remoteConfigs[s1], t4:IsLoaded()
	end,
	Start = function(t5: {[any]: any}) -- line: 55
		-- upvalues: GameAnalytics (copy), ReplicatedStorage (copy), HttpService (copy)
		GameAnalytics:initClient()
		ReplicatedStorage:WaitForChild("GameAnalyticsRemoteConfigs").OnClientEvent:Connect(function(p2) -- line: 57
			-- upvalues: HttpService (copy), t5 (copy)
			if typeof(p2) ~= "table" then
				return
			end

			local t6 = {}

			for k, v in pairs(p2) do
				local ok, result = pcall(HttpService.JSONDecode, HttpService, v)

				t6[k] = if not ok or result == nil then v else result
			end

			t5._remoteConfigs = t6

			if not t5._loaded then
				t5._loaded = true
				t5._loadedSignal:Fire(t6)
				t5:_runExperiments()
			end
		end)
	end
}

task.spawn(t7.Start, t7)

return t7

