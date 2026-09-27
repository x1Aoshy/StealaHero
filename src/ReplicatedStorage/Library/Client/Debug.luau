-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMEBVRyYWNrBXBhaXJzBkNhbmNlbANHZXQABAUDAQAAAAz7BAAAhwMEAUcDBQAAAACA+wMAAP8EAAAAAAAAagQDAfsEAACHAwQBagIDAIIAAQAAAAQBARgAAAAAAQAAAAIAAAEFAAAAAAcCAQAAABT7AwAAhwIDAQ4CEAD7AwAAhwIDAcYDAABqAwIApAIBAAAAAED7BQAAhwMFAZ8CAgQXAgEAggABAG4C/v8CAAAA+wIAAMYDAABqAwIBggABAAIDAgQAAABAAAsDARgAAAABAAAAAQAAAAAAAf8AAwAAAgwAAAAAAQABAAAAAvsAAACCAAIAAAAVBAEYAAAWAAAAAAMAAAECABKjAAAA/wADAAAAAAD/AQAAAAAAAMACAAASAAEAMAIA4AEAAADAAgIAEgABADACAKEDAAAAwAIEABIAAQAwAgB/BQAAAIIAAgAGBgADAQYBAwMGAgMEAwABAgEAARgAAAABAAIAAAAHAAAACgAAAAQBAAAAAAOqhlFYOQ4yZRjAuFflyWW42p5GLJhCO1k=

-- decompilation:
local t1 = {}
local t2 = {}

function t1.Track(p1, p2, p3) -- line: 4
	-- upvalues: t2 (copy)
	if t2[p2] == nil then
		t2[p2] = {}
	end

	t2[p2][p1] = p3
end
function t1.Cancel(p4, p5) -- line: 11
	-- upvalues: t2 (copy)
	if t2[p5] then
		t2[p5][p4] = nil

		for _, _ in pairs(t2[p5]) do
			return
		end

		t2[p5] = nil
	end
end
function t1.Get() -- line: 21
	-- upvalues: t2 (copy)
	return t2
end

return t1

