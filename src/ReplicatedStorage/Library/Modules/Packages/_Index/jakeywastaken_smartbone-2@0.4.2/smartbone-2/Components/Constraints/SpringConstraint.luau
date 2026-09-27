-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNCFNldHRpbmdzCVN0aWZmbmVzcwpFbGFzdGljaXR5BUJvbmVzC1BhcmVudEluZGV4CkZyZWVMZW5ndGgGQ0ZyYW1lA25ldwhQb3NpdGlvbg9UcmFuc2Zvcm1PZmZzZXQIUm90YXRpb24UTG9jYWxUcmFuc2Zvcm1PZmZzZXQJTWFnbml0dWRlAAISBQAAADMAAAwPDDIMDw0zCw8ONQkPChQqDwsrEw8JDD4PCj4MDwtBCQ8FAEsPBgJJDwcERw8IBkVLTQUDygAAAABNBgX8AQAAAE0HBRgCAAAATQkDeAMAAABNCgDNBAAAAIcICQoOCD4ATQkAfgUAAACMCgAAtwoEAAYAAACMCgAAYAorAAcAAACkCwgAABxggE0MCDsJAAAAnwsCAk0MCKYKAAAATQwMOAsAAAAJCgsMUgsCACsLCgCkDAgAABxggE0NAI0MAAAATQ0NOwkAAACfDAICCQsKDE0LCzsJAAAAUgILACYLAgEJDQcECQwLDUMBAQyMDAAAYAwNAAYAAAAmDAIBTQ0Mqg0AAAD1EA8GCQ8JEFsODw5gDgUADQAAACYRDQ7sEBENCQ8MEEMBAQ9NCwg7CQAAACYKCwFNCwqqDQAAAIwMAABgDAUACwAAACYOCwnsDQ4LCQwKDUMBAQyCAQIAEAMBAwIDAwMEAwUDBgMHAwgEABxggAMJAwoDCwMMAw0CAAAAAAAAAEACAAAAAAAA8D8AAgABGAAAAQABAAIAAAAAAgEAAgAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAAAAAACAQAAAgAAAQEAAQAAAQABAAAABQAAAQABAAABAAAABgYAAAAAAQAAAQMAA6MAAADAAAAAggACAAEGAAEAAQABGAABAAEAAAAAATuhwu6vSCxQXnyakqiql9NLudWaCWWo7w==

-- decompilation:
--!native
return function(p1, p2, p3, p4, p5) -- line: 2
	local Settings = p4.Settings
	local Stiffness = Settings.Stiffness
	local Elasticity = Settings.Elasticity
	local v9 = p4.Bones[p1.ParentIndex]

	if v9 then
		local FreeLength = p1.FreeLength

		if Stiffness > 0.0 or Elasticity > 0.0 then
			local v11 = CFrame.new(v9.Position) * v9.TransformOffset.Rotation
			local v12 = p3 or (v11 * CFrame.new(p1.LocalTransformOffset.Position)).Position

			p2 += (v12 - p2) * (Elasticity * p5)

			if Stiffness > 0.0 then
				local v13 = v12 - p2
				local Magnitude = v13.Magnitude
				local v15 = FreeLength * (1.0 - Stiffness) * 2.0

				if v15 < Magnitude then
					p2 += v13 * ((Magnitude - v15) / Magnitude)
				end
			end
		end

		local v16 = v9.Position - p2
		local Magnitude = v16.Magnitude

		if Magnitude > 0.0 then
			p2 += v16 * ((Magnitude - FreeLength) / Magnitude)
		end
	end

	return p2
end

