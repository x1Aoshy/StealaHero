--!nocheck
-- scripts/steps/post_leaderboards.luau (owner HEROBOARD 2026-09-26; was the four free-standing boards of owner batch
-- 2026-09-24 #6 / LEAD 2026-09-23)
-- Owner: "haz una sola y que sea un surface gui estilo steal a hero bonita y ahi que se pueda seleccionar cualquier
-- leaderboard". The four boards (Workspace.__OBJECTS.Leaderboards.Models.Leaderboard1..4: TOTAL NETWORTH / TOTAL
-- SPEED / IN-GAME TIME / EGGS HATCHED) are replaced by ONE wall-mounted HERO BOARD with selectable tabs and a top-3
-- podium, built by scripts/steps/post_x_hero_board.luau (Workspace.Hub.HeroBoard) once the hub walls are final.
--
-- This step only RETIRES the old content, and it must run where it does: after post_hub_remodel (which re-frames
-- Leaderboard1) and BEFORE post_world_sae, whose hub walls are pushed outward by any hub content (the old
-- __OBJECTS.Leaderboards root included) standing within a stud of their line. Removed:
--   * Workspace.__OBJECTS.Leaderboards (Models.Leaderboard1..N with their ripped rows of real players, and
--     UI.LiveAssets, a dead SurfaceGui no script reads).
-- The base place's StarterPlayerScripts.Game.Leaderboards client only tracks ScrollingFrames tagged "Leaderboard"
-- (none are left), so it idles. Idempotent.

local Step = {}

local LOG = "[leaderboards]"

function Step.Apply(place)
	local ws = place:GetService("Workspace")
	local objects = ws:FindFirstChild("__OBJECTS")
	local folder = objects and objects:FindFirstChild("Leaderboards")
	if folder == nil then
		print(LOG .. " __OBJECTS.Leaderboards already gone; nothing to retire (the HERO BOARD is built by post_x_hero_board)")
		return
	end
	local boards, rows = 0, 0
	local models = folder:FindFirstChild("Models")
	for _, child in ipairs(models and models:GetChildren() or {}) do
		if child:IsA("Model") then
			boards += 1
		end
	end
	for _, d in ipairs(folder:GetDescendants()) do
		if string.sub(d.Name, 1, 7) == "Player_" then
			rows += 1
		end
	end
	local parts = #folder:GetDescendants()
	folder:Destroy()
	print(string.format("%s retired __OBJECTS.Leaderboards: %d old board model(s), %d baked player row(s), %d instances "
		.. "(replaced by Workspace.Hub.HeroBoard, scripts/steps/post_x_hero_board.luau)", LOG, boards, rows, parts))
end

return Step
