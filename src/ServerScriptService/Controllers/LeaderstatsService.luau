-- ServerScriptService.Controllers.LeaderstatsService
-- Classic leaderstats folder (Money, Rebirth), driven off Database.
--
-- Owner 2026-09-27 ("no lag, server Hz, network"): the service used to register two new Database.OnFieldChanged
-- callbacks for EVERY player who ever joined (never removed), so after hours every Money change walked hundreds of dead
-- callbacks; and the Money StringValue (replicated to every player for the player list) was rewritten on every change
-- (twice a second per treadmill runner). Now one pair of callbacks serves everyone through a per-player table cleared on
-- leave, and the Money text is flushed at most MONEY_FLUSH_INTERVAL seconds apart (the latest value wins; only a changed
-- string replicates). Rebirth stays immediate (rare).

local Players = game:GetService("Players")

local Instance_new = Instance.new
local Database = require(game.ServerScriptService.Library.Database)

local LeaderstatsService = {}

LeaderstatsService.MONEY_FLUSH_INTERVAL = 1

local entries = {} -- [Player] = { money = StringValue, rebirth = IntValue, pendingMoney = number? }

local function formatNumber(n)
	n = math.floor(n or 0)
	if n < 1000 then
		return tostring(n)
	end
	local suffixes = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }
	local magnitude = 0
	local value = n
	while value >= 1000 and magnitude < #suffixes do
		value /= 1000
		magnitude += 1
	end
	return string.format("%.2f%s", value, suffixes[magnitude])
end
LeaderstatsService.FormatNumber = formatNumber

Database.OnLoaded(function(player, profile)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local folder = Instance_new("Folder")
	folder.Name = "leaderstats"

	local money = Instance_new("StringValue")
	money.Name = "Money"
	money.Value = formatNumber(profile.Money)
	money.Parent = folder

	local rebirth = Instance_new("IntValue")
	rebirth.Name = "Rebirth"
	rebirth.Value = profile.Rebirth or 0
	rebirth.Parent = folder

	folder.Parent = player
	entries[player] = { money = money, rebirth = rebirth, pendingMoney = nil }
end)

Database.OnFieldChanged("Money", function(player, value)
	local entry = entries[player]
	if entry then
		entry.pendingMoney = value
	end
end)

Database.OnFieldChanged("Rebirth", function(player, value)
	local entry = entries[player]
	if entry and entry.rebirth.Parent then
		entry.rebirth.Value = value
	end
end)

Players.PlayerRemoving:Connect(function(player)
	entries[player] = nil
end)

local function flush()
	for player, entry in pairs(entries) do
		local pending = entry.pendingMoney
		if pending ~= nil then
			entry.pendingMoney = nil
			if entry.money.Parent then
				local text = formatNumber(pending)
				if entry.money.Value ~= text then
					entry.money.Value = text
				end
			elseif player.Parent == nil then
				entries[player] = nil
			end
		end
	end
end
LeaderstatsService._flush = flush

task.spawn(function()
	while true do
		task.wait(LeaderstatsService.MONEY_FLUSH_INTERVAL)
		local ok, err = pcall(flush)
		if not ok then
			warn("[LeaderstatsService] " .. tostring(err))
		end
	end
end)

return LeaderstatsService
