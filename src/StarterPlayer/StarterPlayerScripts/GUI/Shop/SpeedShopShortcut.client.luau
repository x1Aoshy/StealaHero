-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Asserts = require(ReplicatedStorage.Library.Asserts)
local ButtonFX = require(ReplicatedStorage.Library.Client.GUIFX.ButtonFX)
local GUI = require(ReplicatedStorage.Library.Client.GUI)
local TabController = require(ReplicatedStorage.Library.Client.TabController)
local v6 = GUI.Shop()
local v7 = GUI.Money()
local ScrollingFrame = v6.Frame.Main.ScrollingFrame
local SpeedTop = ScrollingFrame.SpeedTop
local ImageButton = v7.Bottom.Frame.SpeedValue.ImageLabel.ImageButton

assert(ImageButton:IsA("GuiButton"), "Expected Money.Bottom.Frame.SpeedValue.ImageLabel.ImageButton to be a GuiButton")

local function centerShopScrollingFrameAt(p1, n1: number) -- line: 31
	-- upvalues: Asserts (copy), ScrollingFrame (copy)
	Asserts.number(n1)

	local v16 = p1.AbsolutePosition.Y - ScrollingFrame.AbsolutePosition.Y + ScrollingFrame.CanvasPosition.Y + n1 - ScrollingFrame.AbsoluteWindowSize.Y / 2.0
	local v17 = math.max(0.0, ScrollingFrame.AbsoluteCanvasSize.Y - ScrollingFrame.AbsoluteWindowSize.Y)

	ScrollingFrame.CanvasPosition = Vector2.new(ScrollingFrame.CanvasPosition.X, (math.clamp(v16, 0.0, v17)))
end
local function centerSpeedTopBottom() -- line: 45
	-- upvalues: centerShopScrollingFrameAt (copy), SpeedTop (copy)
	centerShopScrollingFrameAt(SpeedTop, SpeedTop.AbsoluteSize.Y)
end
local function openShopThenCenter(p2: ((...any) -> ...any)) -- line: 49
	-- upvalues: TabController (copy)
	task.spawn(function() -- line: 50
		-- upvalues: TabController (copy), p2 (copy)
		TabController.OpenTab("Shop")
		task.wait()
		task.wait()
		p2()
	end)
end

ButtonFX(ImageButton, nil, function() -- line: 62
	-- upvalues: centerSpeedTopBottom (copy), TabController (copy)
	local v19 = centerSpeedTopBottom

	task.spawn(function() -- line: 50
		-- upvalues: TabController (copy), v19 (copy)
		TabController.OpenTab("Shop")
		task.wait()
		task.wait()
		v19()
	end)
end)

