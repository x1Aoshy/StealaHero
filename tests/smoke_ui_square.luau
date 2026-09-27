--!nocheck
-- tests/smoke_ui_square.luau (owner 2026-09-27: "stud texture rbxassetid://6927295847 on the buttons and every UI, and
-- visible; no other texture; square corners with a separation, no more rounded UI; Shop / Hero Index separated, square,
-- minimalist"). Joins the "smoke" filter. Checks, against the built place:
--   1. no UICorner in StarterGui / the ReplicatedStorage UI / the world GUIs rounds anything (all four radii 0);
--   2. no visible non-stud background pattern overlay is left (the old theme patterns), every visible stud layer reads
--      (ImageTransparency <= 0.62);
--   3. the Shop / Index sidebar buttons are square tiles with a gap between them;
--   4. StarterPlayerScripts.GUI.SquareUi (runtime corners) is injected and compiles.

local place = H.place()
local UDim = H.roblox.UDim

local function digits(inst)
	local ok, content = pcall(function()
		return inst.ImageContent
	end)
	return string.match(tostring(if ok then content else ""), "(%d%d%d%d%d+)")
end

local roots = { place:GetService("StarterGui"), place:GetService("ReplicatedStorage") }
for _, d in ipairs(place:GetService("Workspace"):GetDescendants()) do
	if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
		table.insert(roots, d)
	end
end
local rounded, patterns, faintStuds, studLayers = {}, {}, {}, 0
local NON_STUD = { ["116054484875156"] = true, ["86655919544454"] = true, ["130029461460330"] = true, ["118133511364596"] = true,
	["123051839615959"] = true, ["117164658961906"] = true, ["125961309868308"] = true }
local zero = UDim.new(0, 0)
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("UICorner") then
			if d.TopLeftRadius ~= zero or d.TopRightRadius ~= zero or d.BottomLeftRadius ~= zero or d.BottomRightRadius ~= zero then
				table.insert(rounded, d:GetFullName())
			end
		elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
			local id = digits(d)
			if id == "6927295847" and d.ImageTransparency < 1 then
				studLayers += 1
				if d.ImageTransparency > 0.621 then -- float32: 0.62 reads 0.6200000048
					table.insert(faintStuds, d:GetFullName())
				end
			elseif id and NON_STUD[id] and d.ImageTransparency >= 0.3 and d.ImageTransparency < 1 then -- an overlay (icons / fills are art)
				table.insert(patterns, d:GetFullName())
			end
		end
	end
end
local function first(list)
	return table.concat(list, ", ", 1, math.min(#list, 4))
end
T.check(#rounded == 0, "%d rounded UICorner(s) left: %s", #rounded, first(rounded))
T.check(#patterns == 0, "%d non-stud background pattern(s) still visible: %s", #patterns, first(patterns))
T.check(studLayers >= 50 and #faintStuds == 0, "stud layers must read (<= 0.62 transparent): %d layers, faint: %s", studLayers, first(faintStuds))

local tools = H.path(place:GetService("StarterGui"), "Elements/Left/Tools")
if T.check(tools ~= nil, "StarterGui.Elements.Left.Tools missing") then
	for _, name in ipairs({ "Shop", "Index" }) do
		local wrapper = tools:FindFirstChild(name)
		local ratio = wrapper and wrapper:FindFirstChildOfClass("UIAspectRatioConstraint")
		T.check(ratio ~= nil and math.abs(ratio.AspectRatio - 1) < 1e-3, "Left.Tools.%s must be a square tile", name)
	end
	local layout = tools:FindFirstChildOfClass("UIListLayout")
	T.check(layout ~= nil and layout.Padding.Scale >= 0.04, "Left.Tools must keep a gap between the Shop and Index tiles (Padding %s)",
		tostring(layout and layout.Padding))
end

local sps = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local square = sps and H.path(sps, "GUI/SquareUi")
T.check(square ~= nil and square:IsA("LocalScript") and pcall(H.luau.compile, square.Source) and H.has(square.Source, "CornerRadius"),
	"StarterPlayerScripts.GUI.SquareUi (runtime square corners) must be injected and compile")
