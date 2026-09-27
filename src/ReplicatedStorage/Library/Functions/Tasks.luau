-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMPBXRyYWNrBXBhaXJzCWNvcm91dGluZQZzdGF0dXMEZGVhZAdjbGVhbnVwBHRhc2sFc3Bhd24FZGVmZXIFZGVsYXkGaXNEb25lBHdhaXQCb3MFY2xvY2sHd2FpdEZvcgAKAwEBAAAABPsBAACpAgEAagIBAIIAAQAAAAUBARgAAAABBgAAAAAHAAEAAAARpAABAAAAAED7AQAAnwACBBcACQCkBQQAAAwggFIGAwCfBQIC8AUEAAUAAID7BQAAxgYAAGoGBQNuAPb/AQAAAIIAAQAGAwIEAAAAQAMDAwQEAAwggAMFAAkGARgAAAAAAAEAAAAAAAEAAP4ABQoAAAAABQEBAQAAC6MBAAD7AQAATQEBwAAAAACkAgMAAAgQgFIDAADdBAAAnwIAAJ8BAAGCAAEABAMBAwcDCAQACBCAABEIARgAAQAAAAAAAAAAAREAAAAABQEBAQAAC6MBAAD7AQAATQEBwAAAAACkAgMAAAgQgFIDAADdBAAAnwIAAJ8BAAGCAAEABAMBAwcDCQQACBCAABUJARgAAQAAAAAAAAAAARUAAAAABwIBAQAADKMCAAD7AgAATQICwAAAAACkAwMAAAgQgFIEAABSBQEA3QYAAJ8DAACfAgABggABAAQDAQMHAwoEAAgQgAAZCgEYAAEAAAAAAAAAAAABGQAAAAAHAAEAAAARpAABAAAAAED7AQAAnwACBBcACACkBQQAAAwggFIGAwCfBQIC8AUDAAUAAACpBQAAggUCAG4A9/8BAAAAqQABAIIAAgAGAwIEAAAAQAMDAwQEAAwggAMFAB0LARgAAAAAAAEAAAAAAAEA/gAFAB4AAAAAAQABAAAACvsAAABNAACDAAAAAJ8AAQIrAAQApAADAAAIEICfAAEBSAD3/4IAAQAEAwsDBwMMBAAIEIAAJgwBGAAAAAAAAQAA/wMnAAAAAAQBAQAAABekAQIAAAQAgJ8BAQL7AgAATQICgwMAAACfAgECDgICAKkCAQCCAgIApAMCAAAEAICfAwECJgIDAX0AAwACAAAAqQIAAIICAgCkAgYAABRAgJ8CAQFIAO3/ggABAAcDDQMOBAAEAIADCwMHAwwEABRAgAAsDwEYAAAAAgAAAAABAAIAAAAAAAEAAgAA+QktAAAAAAMAAAAAACX/AAQAAAAAAP8BAAAAAAAA2QIAABIAAQAwAgDAAAAAANkCAQASAAEAMAIAkQEAAADZAgIAEgAAADACAD8CAAAA2QIDABIAAAAwAgBoAwAAANkCBAASAAAAMAIAvgQAAADZAgUAEgABADACAIMFAAAA2QIGABIAAAAwAgCXBgAAANkCBwASAAAAMAIAkQcAAACCAAIACAMBAwYDCAMJAwoDCwMMAw8IAAECAwQFBgcBAAEYAAABAAIAAAAEAAAACAAAAAQAAAAEAAAABAAAAAkAAAAGAAAADQIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGCAEIAQABGAAAAAEAAAAACcdZH8uuxcwNF99P3grMxX63QQi/9Z11yg==

-- decompilation:
return function() -- line: 1
	local t1 = {}
	local t2 = {}

	function t1.track(p1) -- line: 5
		-- upvalues: t2 (copy)
		t2[p1] = true
	end
	function t1.cleanup() -- line: 9
		-- upvalues: t2 (copy)
		for k in pairs(t2) do
			if coroutine.status(k) == "dead" then
				t2[k] = nil
			end
		end
	end
	function t1.spawn(p2, ...) -- line: 17
		-- upvalues: t1 (copy)
		t1.track(task.spawn(p2, ...))
	end
	function t1.defer(p3, ...) -- line: 21
		-- upvalues: t1 (copy)
		t1.track(task.defer(p3, ...))
	end
	function t1.delay(p4, p5, ...) -- line: 25
		-- upvalues: t1 (copy)
		t1.track(task.delay(p4, p5, ...))
	end
	function t1.isDone() -- line: 29
		-- upvalues: t2 (copy)
		for k in pairs(t2) do
			if coroutine.status(k) ~= "dead" then
				return false
			end
		end

		return true
	end
	function t1.wait() -- line: 38
		-- upvalues: t1 (copy)
		while not t1.isDone() do
			task.wait()
		end
	end
	function t1.waitFor(p6) -- line: 44
		-- upvalues: t1 (copy)
		local elapsed = os.clock()

		while not t1.isDone() do
			if p6 <= os.clock() - elapsed then
				return false
			end

			task.wait()
		end

		return true
	end

	return t1
end

