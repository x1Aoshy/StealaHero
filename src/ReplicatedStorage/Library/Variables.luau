-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQM8B3JlcXVpcmUEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQdMaWJyYXJ5B01vZHVsZXMLQ291bnRlZExvY2sRQnJhaW5yb3RFZ2dBY3RpdmUfQWN0aXZlQXNzZXRzSW5pdGlhbExvYWRDb21wbGV0ZQ5IYW1tZXJFcXVpcHBlZBJTZWxlY3RlZEFjdGl2ZUl0ZW0XRmlyc3RTdHJlYW1pbmdTdGF0dXNTZXQJU3RyZWFtaW5nDVNlcnZlckNsb3NpbmcOSGlkZVByb2dyZXNzVUkLSGlkZUdvYWxzVUkKR2FtZUxvYWRlZBJEaXNhYmxlSW5mb092ZXJsYXkUSXNJbnRlcmFjdGluZ1dpdGhOcGMOSXNVc2luZ0ZyZWVjYW0LSXNVc2luZ1Rvb2wHVHJhZGluZwpQb3RhdG9Nb2RlDkRpc2FibGVCb29zdFVJDkFyZWFFZ2dSdW5CYWNrFEd1YXJkZWRHYW1lcGxheU11c2ljBkhpZGVVSRhIaWRlVUlBbGxvd05vdGlmaWNhdGlvbnMURGlzYWJsZU5vdGlmaWNhdGlvbnMQRGlzYWJsZVNoaWZ0TG9jaxREaXNhYmxlVG91Y2hDb250cm9scxFBZGRTY3JlZW5DdXJyZW5jeQNuZXcFTG9ja3MHRGVza3RvcAZNb2JpbGUHQ29uc29sZQJWUghQbGF0Zm9ybQhDaGF0dGluZwZUeXBpbmcERW51bRFTY3JlZW5PcmllbnRhdGlvbg9MYW5kc2NhcGVTZW5zb3ILT3JpZW50YXRpb24IUG9ydHJhaXQJTGFuZHNjYXBlBGxlZnQDdG9wBXJpZ2h0BmJvdHRvbQ5TYWZlQXJlYUluc2V0cwROb25lBExlZnQFUmlnaHQJTm90Y2hTaWRlC01lc3NhZ2VPcGVuEUd1aVRoYXRXYXNFbmFibGVkCkdpZnRVc2VySWQMR2lmdFVzZXJOYW1lC0dpZnRNZXNzYWdlAAEEAAABAgClAaMAAACkAAEAAAAAQKQBAwAAACBATQEBPwQAAABNAQFqBQAAAE0BAegGAAAATQEB7gcAAACfAAIC/wEHAAAAAACMAgAAMAIBFQgAAACpAgAAMAIBZQkAAACpAgAAMAIBgQoAAADGAgAAMAIBZwsAAACpAgAAMAIBCAwAAACpAgAAMAIBsQ0AAACpAgAAMAIBjQ4AAACpAgAAMAIBLw8AAACpAgAAMAIBKRAAAACpAgEAMAIBSBEAAACpAgAAMAIBSxIAAACpAgAAMAIBExMAAACpAgAAMAIBFhQAAACpAgAAMAIBFBUAAACpAgAAMAIB1xYAAACpAgAAMAIBGBcAAADiAiEATQMA7yIAAACfAwECMAMCcRgAAABNAwDvIgAAAJ8DAQIwAwIqGQAAAE0DAO8iAAAAnwMBAjADAuYaAAAATQMA7yIAAACfAwECMAMCWxsAAABNAwDvIgAAAJ8DAQIwAwJiHAAAAE0DAO8iAAAAnwMBAjADAgQdAAAATQMA7yIAAACfAwECMAMCcR4AAABNAwDvIgAAAJ8DAQIwAwIcHwAAAE0DAO8iAAAAnwMBAjADAnggAAAAMAIBgSMAAACpAgEAMAIBMSQAAACpAgAAMAIBWSUAAACpAgAAMAIBgSYAAACpAgAAMAIB6icAAABvAiQAMAIBkSgAAACpAgAAMAIBGykAAACpAgAAMAIB4ioAAACkAi4ALbCwwjACAVwvAAAAqQIAADACAWIwAAAAqQIBADACAcQxAAAA4gI3ADACAew4AAAA4gI+ADACAdA/AAAAqQIAADACAehAAAAAxgIAADACAbNBAAAAxgIAADACAd1CAAAAxgIAADACATFDAAAAxgIAADACAVVEAAAAggECAEUDAQQAAABAAwIEAAAgQAMDAwQDBQMGAwcDCAMJAwoDCwMMAw0DDgMPAxADEQMSAxMDFAMVAxYDFwMYAxkDGgMbAxwDHQMeAx8FCRgZGhscHR4fIAMgAyEDIgMjAyQDJQMmAycDKAMpAyoDKwQtsLDCAywDLQMuAy8CAAAAAAAAAAADMAMxAzIIBDIzAAAANDMAAAA1MwAAADYzAAAAAzMDNAEBAzUBAAM2CAM5OgAAADs8AAAAPTwAAAADNwM4AzkDOgM7AzwAAQABGAABAAAAAAAAAAAAAAAAAgABAAABAAABAAABAAABAAABAAABAAABAAABAAABAAABAAABAAABAAABAAABAAABAAABAQAAAAABAAAAAAEAAAAAAQAAAAABAAAAAAEAAAAAAQAAAAABAAAAAAEAAAAA9wALAAABAAABAAABAAABAAABAAABAAABAAAAAQAAAQAAAQAABgAABQAAAQAAAQAAAQAAAQAAAgEAAAAAALHKsVnGXHlpJt20+lYEAFDB0qYtgw7bWA==

-- decompilation:
local CountedLock = require(game.ReplicatedStorage.Library.Modules.CountedLock)

return {
	BrainrotEggActive = 0.0,
	ActiveAssetsInitialLoadComplete = false,
	HammerEquipped = false,
	SelectedActiveItem = nil,
	FirstStreamingStatusSet = false,
	Streaming = false,
	ServerClosing = false,
	HideProgressUI = false,
	HideGoalsUI = false,
	GameLoaded = true,
	DisableInfoOverlay = false,
	IsInteractingWithNpc = false,
	IsUsingFreecam = false,
	IsUsingTool = false,
	Trading = false,
	PotatoMode = false,
	Locks = {
		DisableBoostUI = CountedLock.new(),
		AreaEggRunBack = CountedLock.new(),
		GuardedGameplayMusic = CountedLock.new(),
		HideUI = CountedLock.new(),
		HideUIAllowNotifications = CountedLock.new(),
		DisableNotifications = CountedLock.new(),
		DisableShiftLock = CountedLock.new(),
		DisableTouchControls = CountedLock.new(),
		AddScreenCurrency = CountedLock.new()
	},
	Desktop = true,
	Mobile = false,
	Console = false,
	VR = false,
	Platform = "Desktop",
	Chatting = false,
	Typing = false,
	Orientation = Enum.ScreenOrientation.LandscapeSensor,
	Portrait = false,
	Landscape = true,
	SafeAreaInsets = {
		left = 0.0,
		top = 0.0,
		right = 0.0,
		bottom = 0.0
	},
	NotchSide = {
		None = true,
		Left = false,
		Right = false
	},
	MessageOpen = false,
	GuiThatWasEnabled = nil,
	GiftUserId = nil,
	GiftUserName = nil,
	GiftMessage = nil
}

