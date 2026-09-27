-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMWA3J1bgNuZXcHdHJ5TG9jawZhc3NlcnQEdGFzawVzcGF3bgJvcwVjbG9jawd3YWl0ZXJzBHdhaXQGRXhwZWN0BFRvQmUGdW5sb2NrB0Rlc3Ryb3lBcmVsZWFzZXMgbWFueSBxdWV1ZWQgd2FpdGVycyB3aXRob3V0IHN5bmNocm9ub3VzIHdha2V1cCByZWN1cnNpb24EVGVzdAdyZXF1aXJlBnNjcmlwdAZQYXJlbnQFTXV0ZXgQTXV0ZXggY29udGVudGlvbghEZXNjcmliZQAGAQABAAAABPsAAACVAAAA3gAAAIIAAQABAgAAAAAAAPA/ABgAARgAAAABGQAAAAADAAIAAAAH+wAAANkCAAASAgEAvAAANgAAAACfAAMBggABAAEDAQEAFwABGAAAAAAAAAMYAAAAAAgAAgAAAFf7AAAATQAA7wAAAACfAAECvAIAuwEAAACfAgIATAEAAqQBAwAAACBAnwEAAowCAACMBQEAjAMAAYwEAQCoAwcApAYGAAAUQIDZBwAAEgAAABIBAv+fBgIBiwP5/6QECgAAJICAnwQBApUDBAdNBQBjCwAAABwEBQCMBQABYAQKAAUAAACkBAoAACSAgJ8EAQJgBAUAAwAAAKQEDQAAMECAnwQBAUgA8f/7BAEATQcAYwsAAAAcBgcAvAQEAQ4AAACfBAMCjAYAAbwEBHYPAAAAnwQDAVIGAQC8BACGEAAAAJ8EAwGkBQoAACSAgJ8FAQKVBAURjAUAAWACCgAFAAAApAUKAAAkgICfBQECYAUFAAQAAACkBQ0AADBAgJ8FAQFIAPT/+wUBAFIHAgC8BQUBDgAAAJ8FAwKMBwABvAUFdg8AAACfBQMBvAUAUBIAAACfBQIBwQIAAIIAAQATAwIDAwMEBAAAIEADBQMGBAAUQIACAAAAAAAAFEADBwMIBAAkgIADCQMKBAAwQIADCwMMAw0CAAAAAAAALkADDgEBEAABGAAAAAABAAAAAAAAAgIAAAABAAAAAAD/CAAAAAEAAAAAAAAAAAAAAQAA/wMAAAAAAAAAAAAAAgAAAAIAAAABAAAAAAAAAAEAAP8DAAAAAAAAAAABAAABABEAAAAABAACAAAACfsAAABvAgAA2QMAABICAQASAgAAvAAAfAEAAACfAAQBggABAAIDDwMQAQIPAAEYAAAAAAAAAAAdEAAAAAAGAQAAAAYDAAAFAQQRpAEBAAAAAECkAgMAAAAgQE0CAiQEAAAATQICnAUAAACfAQICbwQGANkFAAASAAAAEgABALwCAMwHAAAAnwIEAYIAAQAIAxEEAAAAQAMSBAAAIEADEwMUAxUDFgEDDAABGAAAAAAAAAAAAAIAAAAAAAAfDQAAAAABAAABAgADowAAAMAAAACCAAIAAQYEAQQBAAEYAAsAAQAAAAAFpfYSmIKOWslgIMz53iE7KNXuBeyXMniZ

-- decompilation:
return function(t1: {[any]: any}) -- line: 12
	local Mutex = require(script.Parent.Mutex)

	t1:Describe("Mutex contention", function() -- line: 15
		-- upvalues: t1 (copy), Mutex (copy)
		t1:Test("releases many queued waiters without synchronous wakeup recursion", function() -- line: 16
			-- upvalues: Mutex (copy), t1 (copy)
			local v3 = Mutex.new()
			local v4 = assert(v3:tryLock())
			local n1 = 0.0

			for _ = 1.0, 256.0 do
				task.spawn(function() -- line: 23
					-- upvalues: v3 (copy), n1 (ref)
					v3:run(function() -- line: 24
						-- upvalues: n1 (ref)
						n1 += 1.0
					end)
				end)
			end

			local v7 = os.clock() + 5.0

			while #v3.waiters < 256.0 and v7 > os.clock() do
				task.wait()
			end

			t1:Expect(#v3.waiters):ToBe(256.0)
			v3:unlock(v4)

			local v8 = os.clock() + 15.0

			while n1 < 256.0 and v8 > os.clock() do
				task.wait()
			end

			t1:Expect(n1):ToBe(256.0)
			v3:Destroy()
		end)
	end)
end

