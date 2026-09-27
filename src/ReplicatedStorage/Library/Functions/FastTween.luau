-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJB0Rlc3Ryb3kGQ3JlYXRlCUNvbXBsZXRlZARPbmNlBFBsYXkJRmFzdFR3ZWVuBGdhbWUMVHdlZW5TZXJ2aWNlCkdldFNlcnZpY2UAAwIAAQAAAAX7AAAAvAAAUAAAAACfAAIBggABAAEDAQAGAAEYAAAAAAEHAAAAAAkEAQAACQYAAAUEBwcEgRcqAwIAAAAAgKkDAAGpAwEA+wQAAFIGAABSBwEAUggCALwEBJYAAAAAnwQFAk0FBBgBAAAA2QcAABIABAC8BQU9AgAAAJ8FAwEOAwMAvAUE7gMAAACfBQIBggQCAAQDAgMDAwQDBQEAAwYBGAAAAAABAAAAAAAAAQAAAAAAAAMBAAACBAAAAAADAAABAgAOowAAAKQAAQAAAABAbwICALwAABYDAAAAnwADAsABBAASAAAAGAEAZQUAAAA1AQBlBQAAAIIBAgAGAwcEAAAAQAMIAwkGAQMGAQEBAAEYAAAAAAAAAAIAAAAMAAABAAAAAAJntINe7vlyLqlDpKWFLaFjF6yUKlVw6V8=

-- decompilation:
local TweenService = game:GetService("TweenService")

function FastTween(p1, p2, t1: {[any]: any}, b1: boolean?) -- line: 3
	-- upvalues: TweenService (copy)
	local v6 = b1 ~= false
	local tween = TweenService:Create(p1, p2, t1)

	tween.Completed:Once(function() -- line: 6
		-- upvalues: tween (copy)
		tween:Destroy()
	end)

	if v6 then
		tween:Play()
	end

	return tween
end

return FastTween

