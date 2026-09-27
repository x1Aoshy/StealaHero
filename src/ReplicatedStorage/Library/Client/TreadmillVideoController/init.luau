-- ReplicatedStorage.Library.Client.TreadmillVideoController (TREADMILL owner, VISUAL_PASS_PLAN D4)
-- The TikTok-style treadmill video player (vertical video feed, comments, likes, friend likes, share and swap
-- buttons) is removed from Steal a Hero. Training now shows the SpeedPhone minigame
-- (StarterPlayerScripts.GUI.SpeedPhone) and the training HUD (StarterPlayerScripts.GUI.TreadmillTrainingHud).
--
-- This module keeps the public API the base-place callers still use (TreadmillUI calls Start/Stop on every
-- treadmill session and on the DisableVideos setting), as no-ops that never touch the GUI: the video
-- SurfaceGuis (TreadmillVideoSurfaceGui, TreadmillScreen*, StaticTreadmillImageSurfaceGui), the skins'
-- VideoFeedScreen / VideoDecorationPart / SwapLeft / SwapRight parts and this module's runtime children
-- (FeedSequencer, Media, VideoFramePool, LikeController, FriendLikesController, CommentsController) are
-- removed at build time by scripts/steps/ui_60_treadmill.luau and scripts/steps/treadmill.luau. Types
-- (Interface, Schema) stay: other modules require them for their type exports only.
-- The server's TreadmillMediaFeedState stays in the profile and in the ActiveTreadmillChanged payload; it is
-- simply not rendered any more. Injected by scripts/inject/uiaudio.luau and scripts/inject/treadmill.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- A signal that never fires (no media is ever shown). Library.Modules.Packages.Signal when available, so
-- callers keep the usual :Connect / :Once / :Wait API; a tiny fallback otherwise.
local function newSignal()
	local ok, Signal = pcall(function()
		return require(ReplicatedStorage.Library.Modules.Packages.Signal)
	end)
	if ok and type(Signal) == "table" and type(Signal.new) == "function" then
		local created, signal = pcall(Signal.new)
		if created and signal ~= nil then
			return signal
		end
	end
	local connection = {
		Connected = false,
		Disconnect = function() end,
	}
	return {
		Connect = function()
			return connection
		end,
		Once = function()
			return connection
		end,
		Fire = function() end,
		Wait = function()
			return nil
		end,
	}
end

local TreadmillVideoController = {
	MediaChanged = newSignal(),
	Stopped = newSignal(),
}

-- Called by TreadmillUI when a treadmill session starts (treadmillId, mediaFeedState): nothing to play.
function TreadmillVideoController.Start(_treadmillId: string?, _mediaFeedState: any?) end

-- Called by TreadmillUI when a session ends and on the DisableVideos setting: nothing to stop.
function TreadmillVideoController.Stop() end

function TreadmillVideoController.GetStoppedIconImage(): string
	return ""
end

function TreadmillVideoController.ResolveCoverImage(_mediaEntry: any?): string
	return ""
end

function TreadmillVideoController.GetCurrentMediaEntry(_mediaFeedState: any?): any?
	return nil
end

function TreadmillVideoController.SuppressScreenTap() end

function TreadmillVideoController.SetShareButtonVisible(_visible: boolean) end

return TreadmillVideoController
