-- ServerScriptService.BranchServer (Script; injected by scripts/inject/branch.luau)
-- Starts the Branch framework's server segments (ReplicatedStorage.Packages.Branch, vendor/Branch): every *Service
-- module in ServerScriptService.BranchServices runs Init (dependency order) then Start.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Branch = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Branch"))
Branch:Start(script.Parent:WaitForChild("BranchServices"))
