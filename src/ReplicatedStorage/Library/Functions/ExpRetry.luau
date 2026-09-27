-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMZCk5leHROdW1iZXIEdGFzawR3YWl0BXRhYmxlBHBhY2sFcGNhbGwGdW5wYWNrIFRvbyBtYW55IHJldHJpZXMuIExhc3QgZXJyb3I6ICUqBmZvcm1hdARmdW5jCG9wdGlvbmFsBm51bWJlcjlSZXRyeSBkZWxheSBtaW5pbXVtIGFuZCBtYXhpbXVtIG11c3QgYmUgcHJvdmlkZWQgdG9nZXRoZXIGYXNzZXJ0BlJhbmRvbQNuZXcEZ2FtZRFSZXBsaWNhdGVkU3RvcmFnZQpHZXRTZXJ2aWNlB3JlcXVpcmUHTGlicmFyeQdNb2R1bGVzCFBhY2thZ2VzB1Byb21pc2UHQXNzZXJ0cwADDAIFAAAASMYCAACMBQEA+wMAAIwEAQCoAzsAjAYBAGAGFgAFAAAA+wYBAEcGEwAAAAAA+wYCAEcGEAAAAAAAjAcCAHgIBQCyBgcI+wcDAPsKAQAJCQoG+wsCAAkKCwa8BweFAQAAAJ8HBAKkCAQAAAwggFIJBwCfCAIBpAYHAAAYUICkBwkAAACAQPsIBACfBwIAnwYAAhMHBgAqBwsAAQAAgFIHAACBNQYFAAAAAFIJBgBvCgAApAgLAAAoUICfCAMAnwcAAIIHAACMBwEAYAcLAAUAAAD7BwEARwcIAAAAAICMCAIAeAkFDLIHCAmkCAQAAAwggFIJBwCfCAIBEwIGAYsDxf9SAwEAbwQNAFIGAgC8BASNDgAAAJ8EAwKfAwIAggMAAA8CAAAAAAAAAEADAQMCAwMEAAwggAMEAwUEABhQgAMGBAAAgEADBwQAKFCAAgAAAAAAAPA/AwgDCQAgAAEYAAEAAAABAAAAAAAAAAABAAABAQABAP4AAAQAAAADAAAAAAAAAQAAAQAAAAAAAAAAAAMAAAAAAAEAAAEAAAAD7BcAAAAAAAAAIQAAAAAIBAIAAAkGAAAFBAWCgoI7+wQAAE0EBGYAAAAAUgUAAJ8EAgH7BAAATQQEEQEAAABNBARgAgAAAFIFAQCfBAIB+wQAAE0EBBEBAAAATQQEYAIAAABSBQIAnwQCAfsEAABNBAQRAQAAAE0EBGACAAAAUgUDAJ8EAgFHAgIAAAAAAKkGAAGpBgEARwMCAAAAAACpBwABqQcBAPEGAgAHAAAAqQUAAakFAQCBAQUEAwAAAG8GAwCkBAUAAABAQJ8EAwGQBAEGpAUJAAAgcICfBQEC+wYBAE0GBu8IAAAA2QcAABIABAASAAIAEgADABIABQASAAAAnwYCAIIGAAAKAwoDCwMMAw0DDgQAAEBAAgAAAAAAABRAAw8DEAQAIHCAAQAOAAEYAAAAAAABAAAAAAAAAQAAAAAAAAEAAAAAAAACAAAAAAAAAAAAAAAAAAD/AAAFAQAAAgAAAAAAAAAAAAAUAAAAAAQAAAECAB2jAAAApAABAAAAAEBvAgIAvAAAFgMAAACfAAMCpAEFAAAAQEBNAgBqBgAAAE0CAugHAAAATQIC5ggAAABNAgJyCQAAAJ8BAgKkAgUAAABAQE0DAGoGAAAATQMDiQoAAACfAgICwAMLABIAAgASAAEAggMCAAwDEQQAAABAAxIDEwMUBAAAQEADFQMWAxcDGAMZBgEBAQEAARgAAwAAAAAAAwAAAAAAAAAAAAABAAAAAAAABgAAAAEAAAAAAoTEqOdasjIwT1xwqkMUdWD03L+TtgDC5g==

-- decompilation:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Library.Modules.Packages.Promise)
local Asserts = require(ReplicatedStorage.Library.Asserts)

return function(p1: ((...any) -> ...any), n1: number?, n2: number?, n3: number?) -- line: 14
	-- upvalues: Asserts (copy), Promise (copy)
	Asserts.func(p1)
	Asserts.optional.number(n1)
	Asserts.optional.number(n2)
	Asserts.optional.number(n3)
	assert(n2 == nil == (n3 == nil), "Retry delay minimum and maximum must be provided together")

	local v8 = n1 or 5.0
	local random = Random.new()

	return Promise.new(function(resolve, reject) -- line: 32
		-- upvalues: v8 (copy), n2 (copy), n3 (copy), random (copy), p1 (copy)
		local v12 = nil

		for i = 1.0, v8 do
			if i > 1.0 and n2 ~= nil and n3 ~= nil then
				local v14 = 2.0 ^ (i - 2.0)
				local v15 = random:NextNumber(n2 * v14, n3 * v14)

				task.wait(v15)
			end

			local v16 = table.pack(pcall(p1))

			if v16[1.0] == true then
				return resolve(table.unpack(v16, 2.0))
			end

			if i > 1.0 and n2 == nil then
				local v17 = 2.0 ^ (i - 1.0)

				task.wait(v17)
			end

			v12 = v16[2.0]
		end

		return reject(`Too many retries. Last error: { v12 }`)
	end)
end

