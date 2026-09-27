-- ServerScriptService.Controllers.LeaderstatsService
-- Classic leaderstats folder (Money, Rebirth), driven off Database.

local Instance_new = Instance.new
local Database = require(game.ServerScriptService.Library.Database)

local LeaderstatsService = {}

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

	Database.OnFieldChanged("Money", function(changedPlayer, value)
		if changedPlayer == player and money.Parent then
			money.Value = formatNumber(value)
		end
	end)
	Database.OnFieldChanged("Rebirth", function(changedPlayer, value)
		if changedPlayer == player and rebirth.Parent then
			rebirth.Value = value
		end
	end)
end)

return LeaderstatsService
