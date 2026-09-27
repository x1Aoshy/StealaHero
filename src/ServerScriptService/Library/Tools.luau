-- ServerScriptService.Library.Tools (ModuleScript, injected by scripts/inject/gear.luau)
-- The base place's server tool framework was lost by the save-instance ripper (see GearService's header), but
-- ReplicatedStorage.Directory.Gears.Types.Schema still validates every gear's ToolController on the server with
-- `require(ServerScriptService.Library.Tools).Types.ControllerNameExists(name)`. Without this module the whole
-- Directory.Gears require failed on the server ("Tools is not a valid member of Folder
-- ServerScriptService.Library"). This is only that name check: the gear itself runs in GearService.

local KNOWN_CONTROLLERS = {
	None = true, -- plain tools (Bat, Trap, SubspaceMine, ...): GearService drives them
	Slap = true, -- the slap family
}

return {
	Types = {
		ControllerNameExists = function(name: string): (boolean, string?)
			if KNOWN_CONTROLLERS[name] then
				return true, nil
			end
			return false, `unknown ToolController "{tostring(name)}"`
		end,
	},
}
