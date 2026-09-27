-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- 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

-- decompilation:
--!native
local HttpService = game:GetService("HttpService")
local Asserts = require(game.ReplicatedStorage.UserGenerated.Lang.Asserts)
local v3 = Asserts.Set({
	"GET",
	"HEAD",
	"POST",
	"PUT",
	"DELETE",
	"OPTIONS",
	"TRACE",
	"PATCH"
})
local v4 = Asserts.Optional(Asserts.Enum(Enum.HttpCompression))
local v5 = Asserts.Table({
	Url = Asserts.String,
	Method = v3,
	Headers = Asserts.Optional(Asserts.Map(Asserts.String, Asserts.String)),
	Body = Asserts.Optional(Asserts.RawString),
	Compress = v4,
	NoCache = Asserts.Optional(Asserts.Boolean)
})
local t3 = {
	AssertCompress = v4,
	AssertMethod = v3,
	AssertParams = v5,
	Execute = function(t1: {[any]: any}) -- line: 75
		-- upvalues: v5 (copy), HttpService (copy)
		v5(t1)

		local v8 = t1.Headers or {}

		if t1.NoCache then
			v8 = table.clone(v8)
			v8["Cache-Control"] = "no-cache, no-store, must-revalidate"
			v8.Pragma = "no-cache"
			v8.Expires = "0"
		end

		local t2 = {
			Url = t1.Url,
			Method = t1.Method,
			Headers = v8,
			Body = t1.Body,
			Compress = t1.Compress
		}
		local ok, result = pcall(HttpService.RequestAsync, HttpService, t2)

		if not ok then
			return {
				Success = false,
				StatusCode = 400.0,
				StatusMessage = tostring(result),
				Headers = {}
			}
		end

		return result
	end
}

return table.freeze(t3)

