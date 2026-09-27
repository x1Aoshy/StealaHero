--!nocheck
-- scripts/steps/ui_85_hero_park.luau (HUB LAYOUT pass 2026-09-26)
-- The "Hall of Heroes" card of the Hero Park (Workspace.Hub.HeroPark, scripts/steps/post_hub_zlayout.luau): a statue's
-- "View Hero" prompt opens it (StarterPlayerScripts.Game.HeroPark fills it at runtime: live portrait from
-- Library.Client.HeroPortrait, name, stage, rarity, a line about the hero).
-- Built in the owner's popup style (scripts/lib/ui_kit.luau: the Free Gift / Sell Heroes window recipe, theme "heroes"):
-- dark studded body with an ink rim, glossy header band with the title, the round red close, a dark portrait card and a
-- chunky glossy button. It runs in the ui_* pass after the window restyles (nothing restyles it again) and before
-- ui_90_terms / ui_99_textwrap.
--
-- StarterGui.HeroParkCard (ScreenGui, ResetOnSpawn false)
--   Card (Frame, hidden)     Close (TextButton + TextButton ImageLabel glyph: the Speedsters close contract)
--                            Portrait (square card; the client mounts the ViewportFrame inside it)
--                            HeroName, Stage, Bio (TextLabels), Rarity (pill Frame > Label), OkButton (glossy > Label)
-- Idempotent (the ScreenGui is rebuilt).

local roblox = require("@lune/roblox")
local UiKit = require("../lib/ui_kit")

local Kit = UiKit.Kit
local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local UDim2 = roblox.UDim2
local Enum = roblox.Enum

local Step = {}

Step.GUI_NAME = "HeroParkCard"
Step.THEME = "heroes"

function Step.Apply(place)
	local sg = place:GetService("StarterGui")
	local old = sg:FindFirstChild(Step.GUI_NAME)
	while old do
		old:Destroy()
		old = sg:FindFirstChild(Step.GUI_NAME)
	end
	local theme = UiKit.Themes[Step.THEME]

	local gui = Instance.new("ScreenGui")
	gui.Name = Step.GUI_NAME
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 15
	gui.Enabled = true
	gui.Parent = sg

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromScale(0.46, 0.46)
	card.BackgroundColor3 = theme.body
	card.BorderSizePixel = 0
	card.Active = true
	card.Visible = false
	card.Parent = gui
	UiKit.aspect(card, 1.7)

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Text = ""
	close.AutoButtonColor = false
	close.BackgroundTransparency = 1
	close.BorderSizePixel = 0
	close.Parent = card
	local glyph = Instance.new("ImageLabel")
	glyph.Name = "TextButton" -- the Speedsters close glyph (suite_ui Close contract); Kit.skinCloseButton arts it
	glyph.BackgroundTransparency = 1
	glyph.Parent = close

	UiKit.chrome(card, card, theme, { text = "HALL OF HEROES", close = close, bandPx = 56, corner = 0.05 })

	-- content (card scale): a square portrait card on the left, the hero's facts on the right
	local portrait = UiKit.layer(card, "Frame", "Portrait", 4)
	UiKit.setBox(portrait, Vector2.new(0, 0.5), UDim2.fromScale(0.035, 0.5), UDim2.fromScale(0.36, 0.86))
	UiKit.aspect(portrait, 1)
	UiKit.card(portrait, { color = theme.card, corner = 0.12, strokeColor = theme.cardStroke })
	Kit.addGradient(portrait, { { 0, "#ffffff" }, { 1, "#9a86d8" } }, 90, "SpCardFill")

	local left = Enum.TextXAlignment.Left
	UiKit.text(card, "HeroName", "HERO", "title", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.43, 0.06), size = UDim2.fromScale(0.53, 0.2), alignX = left, zIndex = 5,
		stroke = 0.07,
	})
	UiKit.text(card, "Stage", "STAGE 1", "body", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.43, 0.28), size = UDim2.fromScale(0.53, 0.12), alignX = left, zIndex = 5,
		color = Kit.hex("#ffe45c"),
	})
	local pill = UiKit.layer(card, "Frame", "Rarity", 5)
	UiKit.setBox(pill, Vector2.new(0, 0), UDim2.fromScale(0.43, 0.43), UDim2.fromScale(0.24, 0.12))
	pill.BackgroundColor3 = Kit.hex("#ff2850")
	pill.BackgroundTransparency = 0
	Kit.setCorner(pill, 0.5)
	Kit.addGradient(pill, UiKit.GLOSS_FILL, 90, "SpFill")
	Kit.addStroke(pill, { name = "SpStroke", color = UiKit.INK, thickness = 0.06, mode = "Border" })
	UiKit.text(pill, "Label", "MYTHIC", "button", {
		position = UDim2.fromScale(0.5, 0.5), size = UDim2.fromScale(0.86, 0.72), zIndex = 6,
	})
	UiKit.text(card, "Bio", "", "body", {
		anchor = Vector2.new(0, 0), position = UDim2.fromScale(0.43, 0.58), size = UDim2.fromScale(0.53, 0.2), alignX = left, zIndex = 5,
		color = Kit.hex("#dcd4ff"), stroke = 0.04,
	})
	UiKit.labelButton(card, "OkButton", "AWESOME!", {
		anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.695, 0.88), size = UDim2.fromScale(0.34, 0.16),
		color = theme.accent, zIndex = 5,
	})
	print(string.format("[ui_85_hero_park] StarterGui.%s: Hall of Heroes card (%s theme, hidden until a statue prompt opens it).",
		Step.GUI_NAME, Step.THEME))
end

return Step
