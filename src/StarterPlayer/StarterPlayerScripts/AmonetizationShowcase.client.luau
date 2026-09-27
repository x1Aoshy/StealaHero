-- StarterPlayer.StarterPlayerScripts.AmonetizationShowcase
-- RECREATED (this script existed earlier this session and disappeared -- confirmed missing
-- entirely from StarterPlayerScripts, most likely an accidental Ctrl+Z mid-session, since this
-- exact bug pattern -- Ctrl+Z deleting recently-created script-made objects -- is a known,
-- documented GOTCHA on this project).
--
-- Hover (6 studs up/down, "super clean", not-mega-slow) + slow spin animation for every
-- Amonetization podium's inner creature model.
--
-- 🔴 BUG FOUND + FIXED (this pass): the hover math itself was fine (absolute os.clock()-based
-- CFrame, no per-frame drift) -- the actual cause of "se buguea, sale volando a veces" was that
-- the creature models' MeshParts were Anchored=false AND CanCollide=true: a player walking
-- through the showcase could physically shove them, and every Heartbeat this script would then
-- forcibly PivotTo them back to the "correct" hover position while residual physics velocity
-- from the shove (or, once CanCollide got fixed, plain gravity on an unanchored part with
-- nothing left to stand on) fought against it -- exactly the instability described. Fixed at
-- the source (Workspace.Amonetization parts are now Anchored=true, CanCollide=false), not here.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Sesion 12, cuarta vuelta: "Elephant2" ya no existe -- sacado de la lista. Agregados a3..a10
-- (los "a2" duplicados, renombrados por distancia a Plots.1) y D1/D2 (podios nuevos).
local PODIUM_NAMES = { "Elephant", "a", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "b", "b2", "b3", "c1", "c2", "c3", "D1", "D2" }

local BOB_HEIGHT = 6
local BOB_PERIOD = 3 -- seconds for one full up+down cycle
local SPIN_PERIOD = 6 -- seconds for one full rotation

local bobAngularSpeed = (2 * math.pi) / BOB_PERIOD
local spinAngularSpeed = (2 * math.pi) / SPIN_PERIOD

local Amonetization = Workspace:WaitForChild("Amonetization")
local entries = {}

for _, name in ipairs(PODIUM_NAMES) do
	local podium = Amonetization:FindFirstChild(name)
	if not podium then
		warn("[AmonetizationShowcase] Missing podium: " .. name)
	else
		local model = nil
		for _, child in ipairs(podium:GetChildren()) do
			if child:IsA("Model") then
				model = child
				break
			end
		end
		if not model then
			warn("[AmonetizationShowcase] No creature Model found inside podium: " .. name)
		else
			table.insert(entries, { model = model, basePosition = model:GetPivot().Position })
		end
	end
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, entry in ipairs(entries) do
		local yOffset = (BOB_HEIGHT / 2) - (BOB_HEIGHT / 2) * math.cos(t * bobAngularSpeed)
		local spin = CFrame.Angles(0, t * spinAngularSpeed, 0)
		entry.model:PivotTo(CFrame.new(entry.basePosition) * CFrame.new(0, yOffset, 0) * spin)
	end
end)
