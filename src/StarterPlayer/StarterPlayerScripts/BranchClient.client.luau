-- StarterPlayer.StarterPlayerScripts.BranchClient (LocalScript; injected by scripts/inject/branch.luau)
-- Starts the Branch framework's client segments (ReplicatedStorage.Packages.Branch, vendor/Branch): every *Controller
-- module in StarterPlayerScripts.BranchControllers runs Init (dependency order) then Start.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Branch = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Branch"))
Branch:Start(script.Parent:WaitForChild("BranchControllers"))
