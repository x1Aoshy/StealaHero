-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMRCEFuY2hvcmVkCEluc3RhbmNlA25ldwdNb3RvcjZEBVBhcnQwBVBhcnQxBkNGcmFtZQdJbnZlcnNlAkMwBlBhcmVudApNYW51YWxXZWxkDldlbGRDb25zdHJhaW50BkNyZWF0ZQNJc0EFU2V0QzAGX19jYWxsDHNldG1ldGF0YWJsZQEHAAQHAwAAAAgFAAAFAwcHgTxNAwBFAAAAACsDAwBNAwFFAAAAAA4DFQCkAwMAAAgQgG8EBACfAwICMAADPAUAAAAwAQOxBgAAAE0FAIUHAAAAvAUF2ggAAACfBQICTQYBhQcAAAAJBAUGMAQD7QkAAAAwAAMkCgAAAIIDAgAOAhUApAMDAAAIEIBvBAsAnwMCAjAAAzwFAAAAMAEDsQYAAABNBQCFBwAAALwFBdoIAAAAnwUCAk0GAYUHAAAACQQFBjAEA+0JAAAAMAADJAoAAACCAwIApAMDAAAIEIBvBAwAnwMCAjAAAzwFAAAAMAEDsQYAAAAwAAMkCgAAAIIDAgANAwEDAgMDBAAIEIADBAMFAwYDBwMIAwkDCgMLAwwABQ0BGAAAAAAAAAEAAAABAAEAAQAAAAAAAAAAAAEAAQMBAAAAAQABAAEAAAAAAAAAAAABAAEDAAAAAQABAAEAAQoAAAAABQIAAAAHBAAABQIHQAtvBAAAvAIA/gEAAACfAgMCDgIDADABAO0CAAAAggABADABAO0CAAAAggABAAMDCwMOAwkAIw8BGAAAAAAAAQABAwABJAAAAAADAQEBAAAHowEAAPsBAABNAQGWAAAAAN0CAACfAQAAggEAAAEDDQAtEAEYAAEAAAAAAC0AAAAABQAAAQIAFaMAAAD/AAIAAAAAAMABAAAwAQCWAQAAAMABAgAwAQAfAwAAAOIDBQDABAYAEgAAADAEA+8EAAAAnj0ABAMAAABSAgAApAEIAAAAcECfAQMCggECAAkGAAMNBgEDDwMQBQEEBgIDEQQAAHBAAwABAgEAARgAAgACAAAeAAAJAQAAAAAAAP8AAAABAAAAAAPnbLABNBdRJ2p0qakbetekl3SnddWo2gA=

-- decompilation:
local t1 = {
	Create = function(p1, p2, b1: boolean?) -- line: 5
		if p1.Anchored or p2.Anchored then
			local Motor6D = Instance.new("Motor6D")

			Motor6D.Part0 = p1
			Motor6D.Part1 = p2
			Motor6D.C0 = p1.CFrame:Inverse() * p2.CFrame
			Motor6D.Parent = p1

			return Motor6D
		end

		if b1 then
			local ManualWeld = Instance.new("ManualWeld")

			ManualWeld.Part0 = p1
			ManualWeld.Part1 = p2
			ManualWeld.C0 = p1.CFrame:Inverse() * p2.CFrame
			ManualWeld.Parent = p1

			return ManualWeld
		end

		local WeldConstraint = Instance.new("WeldConstraint")

		WeldConstraint.Part0 = p1
		WeldConstraint.Part1 = p2
		WeldConstraint.Parent = p1

		return WeldConstraint
	end,
	SetC0 = function(p3, cFrame: CFrame) -- line: 35
		if p3:IsA("ManualWeld") then
			p3.C0 = cFrame

			return
		end

		p3.C0 = cFrame
	end
}

return (setmetatable(t1, {
	__call = function(_, ...) -- line: 45
		-- upvalues: t1 (copy)
		return t1.Create(...)
	end
}))

