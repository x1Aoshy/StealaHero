-- ServerScriptService.BranchServices.ServerStatsService (Branch service; injected by scripts/inject/branch.luau)
-- Owner 2026-09-27: "server latency, its Hz, everything optimised". Measures the server's own health so it can be read
-- in Studio / a live server without a debugger: every REPORT_EVERY seconds it writes Workspace attributes
--   ServerHz        heartbeat frames per second over the window (60 = healthy)
--   ServerFrameMs   the slowest heartbeat step in the window (ms)
--   ServerMemoryMB  Stats:GetTotalMemoryUsageMb()
-- and warns once per minute if the heartbeat stays under LOW_HZ. Uses Branch's shared Heartbeat hook (one engine
-- connection for every segment).

local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local ServerStatsService = {}

ServerStatsService.REPORT_EVERY = 2
ServerStatsService.LOW_HZ = 45

local frames, window, worst, lastWarn = 0, 0, 0, -math.huge

function ServerStatsService:Heartbeat(dt)
	frames += 1
	window += dt
	if dt > worst then
		worst = dt
	end
	if window >= ServerStatsService.REPORT_EVERY then
		local hz = frames / window
		Workspace:SetAttribute("ServerHz", math.floor(hz * 10 + 0.5) / 10)
		Workspace:SetAttribute("ServerFrameMs", math.floor(worst * 10000 + 0.5) / 10)
		local ok, memory = pcall(function()
			return Stats:GetTotalMemoryUsageMb()
		end)
		if ok then
			Workspace:SetAttribute("ServerMemoryMB", math.floor(memory + 0.5))
		end
		if hz < ServerStatsService.LOW_HZ and os.clock() - lastWarn > 60 then
			lastWarn = os.clock()
			warn(string.format("[ServerStatsService] server heartbeat %.1f Hz (slowest step %.1f ms)", hz, worst * 1000))
		end
		frames, window, worst = 0, 0, 0
	end
end

return ServerStatsService
