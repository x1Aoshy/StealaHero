-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMSCEluc3RhbmNlA25ldwlBbmltYXRpb24NcmJ4YXNzZXRpZDovLwJpZAh0b3N0cmluZwtBbmltYXRpb25JZA1Mb2FkQW5pbWF0aW9uCFByaW9yaXR5Bmxvb3BlZAZMb29wZWQETmFtZQRhbmltBndlaWdodAhmYWRlVGltZQVzcGVlZBBwcmVsb2FkQW5pbUFycmF5D3ByZWxvYWRBbmltTGlzdAADDwQAAAAJBgAABQQPDwMPO/8EAAAAAAAAUgUBAMYGAADGBwAAZAUyAKQKAgAABACAbwsDAJ8KAgJvDAQATQ4J9AUAAAC7Pw4CpA0HAAAAYECfDQICcwsMDTALCrYIAAAAUg0KALwLAJQJAAAAnwsDAjADC80KAAAATQ0JlQsAAABHDQQAAAAAAE0MCZULAAAAZQABAKkMAQAwDAu1DAAAADACC7oNAAAAHA0EAJUMDQ7iDRMAMAsNLg8AAABNDgnLEAAAADAODcsQAAAATQ4JtREAAAAwDg21EQAAAE0OCcwSAAAAMA4NzBIAAABqDQQMbgXN/wIAAACCBAIAFAMBAwIEAAQAgAMDAwQDBQMGBAAAYEADBwMIAwkDCgMLAwwCAAAAAAAA8D8DDQMOAw8DEAUEDxAREgAFEQEYAAABAAAAAQAAAAEAAAAAAAAAAAACAAAAAQABAAAAAAAAAAAAAQACAAABAAEAAAABAAAAAQAAAPz3ABEGAAAAAA8EAQAACQYAAAUEDw8DDxL/BAAAAAAAAFIFAQDGBgAAxgcAAGQFCQD7CgAATQoKwQAAAABSCwAAUgwJAFINAgBSDgMAnwoFAmoKBAhuBfb/AgAAAIIEAgABAxEAGxIBGAAAAQAAAAEAAAAAAAAAAP8ABBwAAAAAAgAAAQIAC6MAAAD/AAIAAAAAAMABAAAwAQDBAQAAAMABAgASAAAAMAEA1QMAAACCAAIABAYAAxEGAQMSAgABAQABGAACAAIAABYAAAAJAQAAAAAC0QYg4IJq5EijdVdHNQtjtaEeN5Tjwkrh

-- decompilation:
local t2 = {
	preloadAnimArray = function(p1, p2, s1: string, p3) -- line: 5
		local t1 = {}

		for _, v8 in p2 do
			local Animation = Instance.new("Animation")

			Animation.AnimationId = "rbxassetid://" .. tostring(v8.id)

			local track = p1:LoadAnimation(Animation)

			track.Priority = p3
			track.Looped = v8.looped == nil or v8.looped
			track.Name = s1
			t1[#t1 + 1.0] = {
				anim = track,
				weight = v8.weight,
				fadeTime = v8.fadeTime,
				speed = v8.speed
			}
		end

		return t1
	end
}

function t2.preloadAnimList(p4, p5, s2: string, p6) -- line: 27
	-- upvalues: t2 (copy)
	local t3 = {}

	for v16, v17 in p5 do
		t3[v16] = t2.preloadAnimArray(p4, v17, s2, p6)
	end

	return t3
end

return t2

