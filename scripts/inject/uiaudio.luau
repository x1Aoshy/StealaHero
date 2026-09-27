-- scripts/inject/uiaudio.luau
-- UI-AUDIO injection manifest (see scripts/build_stealahero.luau step 13b). Library.Audio (init),
-- BUTTON_FX are already injected by the build itself; this lists the base-place scripts it does not inject.
return {
	{
		-- Base-place Source (verified identical to the mirror apart from CRLF line endings) + Speedsters whitelist gate.
		target = "ReplicatedStorage/Library/Audio/CreateMusicSound",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Audio/CreateMusicSound.luau",
		create = false,
	},
	-- Scripts that set Sound.SoundId directly (bypassing Library.Audio): base-place Source + a lazy
	-- Library.Audio.ResolveSoundUri gate, so only whitelisted Speedsters ids are ever requested (no 403s).
	-- Directory.Sounds.Pipeline is not listed: the build destroys ReplicatedStorage.Directory.Sounds.
	{
		target = "ReplicatedStorage/Library/Functions/PreloadSounds",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Functions/PreloadSounds.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Library/Client/Eggs/EggPlaceAnimation",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/Eggs/EggPlaceAnimation.luau",
		create = false,
	},
	{
		target = "ReplicatedStorage/Library/Client/TreadmillVideoController",
		class = "ModuleScript",
		source = "src/ReplicatedStorage/Library/Client/TreadmillVideoController/init.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/ObbyStages/BreakableBlocks/Sounds",
		class = "ModuleScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/ObbyStages/BreakableBlocks/Sounds.luau",
		create = false,
	},
	{
		target = "StarterPlayer/StarterPlayerScripts/Game/Tools/Megaphone",
		class = "LocalScript",
		source = "src/StarterPlayer/StarterPlayerScripts/Game/Tools/Megaphone.client.luau",
		create = false,
	},
}
