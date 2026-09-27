-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMYBGdhbWURUmVwbGljYXRlZFN0b3JhZ2UKR2V0U2VydmljZQdMaWJyYXJ5B3JlcXVpcmUHTW9kdWxlcw9QaXBlbGluZUJ1aWxkZXIIUGFja2FnZXMBdAlpbnRlcmZhY2UEYW5pbQZ3ZWlnaHQGbG9vcGVkCHByb3RvY29sC2luc3RhbmNlSXNBCUFuaW1hdGlvbgZudW1iZXIIb3B0aW9uYWwHYm9vbGVhbgRTdG9wBFBsYXkFYXJyYXkTU2VyaWFsaXplZEFuaW1hdGlvbhhTZXJpYWxpemVkQW5pbWF0aW9uQXJyYXkAAQ0AAAECAFajAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCTQEAagQAAACkAgYAAABQQE0DAegHAAAATQMD6QgAAACfAgICpAMGAAAAUEBNBAHoBwAAAE0EBOYJAAAATQQElQoAAACfAwIC/wQCAAAAAABNBQMvCwAAAOIGEABNBwPdEQAAAG8IEgCfBwICMAcGLgwAAABNBwNgEwAAADAHBssNAAAATQcDERQAAABNCAM+FQAAAJ8HAgIwBwaVDgAAAE0HAxEUAAAATQgDLwsAAADiCRgATQoDERQAAABNCwMdGQAAAE0MA2ATAAAAnwsCAJ8KAAIwCgn6FgAAAE0KAxEUAAAATQsDHRkAAABNDANgEwAAAJ8LAgCfCgACMAoJ7hcAAACfCAIAnwcAAjAHBoIPAAAAnwUCAjAFBPAaAAAATQYDHRkAAABSBwUAnwYCAjAGBI0bAAAAggQCABwDAQQAAABAAwIDAwMEAwUEAABQQAMGAwcDCAMJAwoDCwMMAw0DDgUEDA0ODwMPAxADEQMSAxMDFAMVBQIWFwMWAxcDGAABAAEYAAEAAAAAAAMAAwAAAAAAAAEAAAAAAAAAAD8AAgAAAQAAAAAAAQAAAAEAAAAAAAABAAAAAAEAAAAAAAAAAAABAAAAAAAAAAAA/gAAAPwKAAEAAAAAAAIBAAAAAABNh8IGYhhde2lXArmYrb1ZPZ/Vcn9DqAc=

-- decompilation:
local Library = game:GetService("ReplicatedStorage").Library

require(Library.Modules.PipelineBuilder)

local t = require(Library.Modules.Packages.t)
local t1 = {}
local v4 = t.interface({
	anim = t.instanceIsA("Animation"),
	weight = t.number,
	looped = t.optional(t.boolean),
	protocol = t.optional(t.interface({
		Stop = t.optional(t.array(t.number)),
		Play = t.optional(t.array(t.number))
	}))
})

t1.SerializedAnimation = v4
t1.SerializedAnimationArray = t.array(v4)

return t1

