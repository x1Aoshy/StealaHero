-- Offline checks for actual stage clearances, a full wind cycle, import pivots and compilation.
-- lune run scripts/tools/verify_sunny.luau [synthetic-import-build.rbxl]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local root = "assets/models/bases/Volcano/"
local layout = serde.decode("json", fs.readFile(root .. "SunnyPirateWharf.json"))
local obstacles = serde.decode("json", fs.readFile(root .. "reference/current-stage-obstacles.json")).plots
local paths = {
	"src/ReplicatedStorage/Library/Modules/SunnyWind.luau",
	"src/StarterPlayer/StarterPlayerScripts/Game/Plots/SunnyWindController.client.luau",
	"scripts/steps/post_zz_base_themes.luau", "scripts/inject/gekko_bases.luau",
}
for _, path in ipairs(paths) do luau.compile(fs.readFile(path)) end
local Wind = luau.load(fs.readFile(paths[1]), { environment = { CFrame = CFrame } })()
local function near(a, b)
	local delta = a:ToObjectSpace(b)
	local _, angle = delta:ToAxisAngle()
	return delta.Position.Magnitude < 1e-4 and math.abs(angle) < 1e-4
end
for _, phase in ipairs({ 0, 0.93, 4.7 }) do
	local first, last = Wind.Sample(0, phase, 1), Wind.Sample(12, phase, 1)
	for group, pose in pairs(first) do assert(near(pose, last[group]), group .. " loop seam") end
end
for group, pose in pairs(Wind.Sample(9, 2, 0)) do assert(near(pose, CFrame.new()), group .. " disabled pose") end
assert(Wind.Interval(10) == 1/30 and Wind.Interval(100) == 1/15 and Wind.Interval(181) == nil)
assert(not near(Wind.Sample(0, 0, 1).Main, Wind.Sample(1, 0, 1).Main), "sail does not move")

local count = 0
for name, variant in pairs(layout.variants) do
	assert(variant.total_tris <= 9000 and #variant.problems == 0 and #variant.plot_problems == 0, name .. " budget/fit")
	local D, W = variant.half_depth, variant.half_width
	local origin = CFrame.new(0, 8.3, -D - 0.88)
	for sample = 0, 240 do
		local poses = Wind.Sample(sample / 20, 0, 1)
		for _, piece in ipairs(variant.pieces) do
			local group = string.match(piece[1], "_Sunny(%a+)_")
			if not group then continue end
			local a, b = piece[2], piece[3]
			local mn, mx = {math.huge, math.huge, math.huge}, {-math.huge, -math.huge, -math.huge}
			for _, x in ipairs({a[1], b[1]}) do
				for _, y in ipairs({a[2], b[2]}) do
					for _, z in ipairs({a[3], b[3]}) do
						local p = origin * poses[group] * origin:PointToObjectSpace(Vector3.new(x, z, -y))
						local q = {p.X, -p.Z, p.Y}
						for k = 1, 3 do mn[k], mx[k] = math.min(mn[k], q[k]), math.max(mx[k], q[k]) end
					end
				end
			end
			assert(mn[2] >= D - 0.62 and mx[2] <= D + 2.4 and mx[3] <= 16 and mn[3] >= 7.5,
				name .. " animated ship exceeds gate envelope at " .. sample .. ": " .. piece[1])
			assert(mn[1] >= -W and mx[1] <= W, "ship exceeds width")
			for _, plot in ipairs(obstacles) do
				if math.abs(plot.half_depth - D) > 0.5 then continue end
				for _, obstacle in ipairs(plot.obstacles) do
					local lo, hi = obstacle[2], obstacle[3]
					assert(not (mn[1] < hi[1] and mx[1] > lo[1] and mn[2] < hi[2] and mx[2] > lo[2]
						and mn[3] < hi[3] and mx[3] > lo[3]), "animated overlap: " .. obstacle[1])
				end
			end
			count += 1
		end
	end
end

-- one MeshPart per animated role (the "_Sunny<Group>_" roles of the layout)
local expectedParts = 0
for role in pairs(layout.variants.Std.tris) do
	if string.match(role, "_Sunny%a+_") then expectedParts += 1 end
end
local checked = 0
if process.args[1] then
	local place = roblox.deserializePlace(fs.readFile(process.args[1]))
	local folder = place:GetService("ServerStorage"):FindFirstChild("BaseThemes"):FindFirstChild("Volcano")
	for _, plot in ipairs(folder:GetChildren()) do
		local model = plot:FindFirstChild("ThemeImportedPen")
		assert(model and model:HasTag(Wind.Tag), "imported wind rig missing on " .. plot.Name)
		local attachment = model:FindFirstChild("SunnyOrigin", true)
		assert(attachment, "missing origin")
		local world = attachment.Parent.CFrame * attachment.CFrame
		local groups, parts = {}, 0
		for _, part in ipairs(model:GetChildren()) do
			local group = part:GetAttribute("SunnyGroup")
			if group then
				assert(near(world * part:GetAttribute("SunnyRest"), part.CFrame), "imported rest pivot drift")
				assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
				groups[group], parts = true, parts + 1
			end
		end
		assert(groups.Hull and groups.Main and groups.Aft and groups.Flag and parts == expectedParts,
			"animation groups incomplete: " .. parts .. " / " .. expectedParts)
		checked += 1
	end
	assert(checked == 6, "six plot rigs expected")
end
local report = { compiled_scripts = #paths, animated_piece_samples = count, verified_plot_rigs = checked,
	cycle_seconds = 12, frames_sampled_per_variant = 241, current_stage_obstacles = true,
	studio_play_test = false, note = "Offline validation. Synthetic import meshes validate placement, not uploaded mesh rendering." }
fs.writeFile(root .. "reference/animation-validation.json", serde.encode("json", report, true))
-- Bake Blender's preview from the actual Roblox evaluator, avoiding two divergent animation implementations.
local samples = {}
for frame = 0, 360 do
	local poses = Wind.Sample(frame / 30, 0, 1)
	local row = {}
	for group, pose in pairs(poses) do row[group] = {pose:GetComponents()} end
	table.insert(samples, row)
end
fs.writeFile(root .. "reference/wind-samples.json", serde.encode("json", {fps = 30, samples = samples}))
print(string.format("Sunny OK: %d scripts compiled, %d animated bounds checked, %d placed rigs", #paths, count, checked))
