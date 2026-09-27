-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMMB1ZlY3RvcjIDbmV3DUltYWdlUmVjdFNpemUGUGFyZW50BUltYWdlD0ltYWdlUmVjdE9mZnNldAR0YXNrBHdhaXQGdW5wYWNrCWNvcm91dGluZQR3cmFwBkNyZWF0ZQAEDAAKAAAAOfsAAACkAQIAAAQAgPsCAQD7AwIAnwEDAjABAOsDAAAAjAAAAIwDAAD7BAMAeAEEBIwCAQCoAScAjAYAAPsHBAB4BAcEjAUBAKgEIQD7BwUAKwcLAPsHAABNBwckBQAAAEcHBwAAAAAA+wcAAE0HB6kGAAAA+wgGAPEHAgAIAAAAggABAPsHBwDUBxEAAAAAAJUAAAT7BwAApAgCAAAEAID7CgEACQkGCvsLAgAJCgMLnwgDAjAIB/kHAAAApAcKAAAkgID7CAgAnwcCAYsE3/+LAdn/+wEJAA4BAQBIAND/ggABAAsDAQMCBAAEAIADAwIAAAAAAADwPwMEAwUDBgMHAwgEACSAgAAaAAEYAAAAAAAAAAAEAgAAAAABAAAAAAEAAAAAAAAAAAAAAAAAAgAAAgEAAAAAAAAAAAABAAAA+f8LAAABGwAAAAABAAEAAAADqQABAN4AAACCAAEAAAAxAAEYAAAAMQAAAAARBgAAAAsIAAAFBgcEBIKCgSu7NQEDUgcBAKQGAQAAAABAnwYCA7s1AgNSCQIApAgBAAAAAECfCAIDTQoAqQIAAACpCwAAUgwDACsMAQAJDAgJkA4EBNgNAw5HBQMAAAAAgKkOAQBlAAEAUg4FAKQPBwAAGFCA2RAAABIAAAASAAYAEgAHABIACQASAAgAEgEL/xIACgASAAwAEgANABIADgCfDwICUhAPAJ8QAQHZEAEAEgEL/8ELAACCEAIACAMJBAAAAEADBQIRERERERGRPwIAAAAAAADwPwMKAwsEABhQgAIAAQkMARgAAAAAAAEAAAAAAQABAQAAAQABAAAAAAMAAAAAAAAAAAAAAAAAFQACAAAAEQAAAAACAAABAgAHowAAAP8AAQAAAAAAwAEAADABAJYBAAAAggACAAIGAgMMAQIBAAEYAAIABgAAKwEAAAAAA9Z0DU9laGzMClK005AJd2WmbBo75LBnTg==

-- decompilation:
return {
	Create = function(p1, t1: {[any]: any}, t2: {[any]: any}, n1: number?, n2: number?, b1: boolean?) -- line: 9
		local v7, v8 = unpack(t1)
		local v9, v10 = unpack(t2)
		local p1Image = p1.Image
		local u12 = false
		local v13 = n1 or v9 * v10
		local v14 = 0.016666666666666666 / (n2 or 1.0)
		local v15 = b1 == nil or b1

		coroutine.wrap(function() -- line: 26
			-- upvalues: p1 (copy), v7 (copy), v8 (copy), v10 (copy), v9 (copy), u12 (ref), p1Image (copy), v13 (copy), v14 (copy), v15 (copy)
			p1.ImageRectSize = Vector2.new(v7, v8)

			repeat
				local n3 = 0.0

				for i = 0.0, v10 - 1.0 do
					for j = 0.0, v9 - 1.0 do
						if u12 or p1.Parent == nil or p1.Image ~= p1Image then
							return
						end

						if n3 >= v13 then
							break
						end

						n3 += 1.0
						p1.ImageRectOffset = Vector2.new(j * v7, i * v8)
						task.wait(v14)
					end
				end
			until not v15
		end)()

		return function() -- line: 49
			-- upvalues: u12 (ref)
			u12 = true
		end
	end
}

