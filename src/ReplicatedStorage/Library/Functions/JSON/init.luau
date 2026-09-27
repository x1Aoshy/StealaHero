-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJA25ldwRqc29uCHRvU3RyaW5nCXN0cmluZ2lmeQdyZXF1aXJlBnNjcmlwdAhDb25zdGFudApTZXJpYWxpemVyBE5VTEwAAgwEAQAAABKQBAIA+wUAAE0FBe8BAAAAxgYAAFIHAwCfBQMCUggAAFIJAQBSCgQAUgsEALwGBaUCAAAAnwYGAbwGBRcDAAAAnwYCAIIGAAAEAgAAAAAAAABAAwEDAgMDAAgEARgAAQAAAAAAAQAAAAAAAAEAAAAJAAAAAAQAAAECABqjAAAA/wACAAAAAACkAQEAAAAAQKQCAwAAACBATQICCwQAAACfAQICpAIBAAAAAECkAwMAAAAgQE0DA6IFAAAAnwICAk0DAfgGAAAAMAMA+AYAAADAAwcAEgACADADAB4IAAAAggACAAkDBQQAAABAAwYEAAAgQAMHAwgDCQYAAwQBAAEAARgAAAACAAAAAAAAAQAAAAAAAAIAAAACAAAABwEAAAAAAf7/zy6mEbhVSEMF3gF5ZeGO59hazDulLw==

-- decompilation:
local t1 = {}
local Constant = require(script.Constant)
local Serializer = require(script.Serializer)

t1.NULL = Constant.NULL

function t1.stringify(p1, p2, p3, p4) -- line: 8
	-- upvalues: Serializer (copy)
	local v8 = p3 or 2.0
	local v9 = Serializer.new(nil, p4)

	v9:json(p1, p2, v8, v8)

	return v9:toString()
end

return t1

