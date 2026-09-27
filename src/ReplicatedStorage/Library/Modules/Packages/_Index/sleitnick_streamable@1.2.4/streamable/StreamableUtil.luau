-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMOBXBhaXJzCEluc3RhbmNlBUNoZWNrBUNsZWFuB0NsZWFudXADQWRkA25ldwdPYnNlcnZlCENvbXBvdW5kB3JlcXVpcmUGc2NyaXB0BlBhcmVudAVUcm92ZQpTdHJlYW1hYmxlAAUGAAQAAAAV+wAAAA4AAQCCAAEApAABAAAAAED7AQEAnwACBBcABABNBQT0AgAAACsFAQCCAAEAbgD7/wIAAACpAAEA3gAAAPsAAgD7AQEA+wIDAJ8AAwGCAAEAAwMBBAAAAEADAgAzAwEYAAABAgAAAAABAAAB/gAFAAEAAAABNAAAAAACAAIAAAAK+wAAACsAAQCCAAEAqQAAAN4AAAD7AAEAvAAATwAAAACfAAIBggABAAEDBAA/BQEYAAABAgABAAAAAUAAAAAACAIFAAAAGfsCAAAOAgEAZQARAKQCAQAAAABA+wMBAJ8CAgQXAgQATQcG9AIAAAArBwEAZQAIAG4C+/8CAAAAqQIBAN4CAAD7AgIA+wMBAPsEAwCfAgMB+wQEALwCAV8DAAAAnwIDAYIAAQAEAwEEAAAAQAMCAwYARwABGAAAAQIAAAAAAQAAAf4ABQABAAAADAAAAAE0AAAAABECAQAABwQAAAUCBAUq+wIAAE0CAu8AAAAAnwIBAvsDAABNAwPvAAAAAJ8DAQKpBAAA2QUAABIBBP8SAAAAEgABABIAAwDZBgEAEgEE/xIAAwCkBwIAAAAQQFIIAACfBwIEFwcMANkQAgASAQT/EgAAABIAAQASAAMAEgAGALwOC1QDAAAAnw4DALwMAl8EAAAAnwwAAW4H8/8CAAAAUgkGALwHAl8EAAAAnwcDAcEEAACCAgIABQMHAwEEAAAQQAMIAwYDAAECLwkBGAAAAAABAAAAAQEAAAAADAAABwAAAAABAAAAAAAAAAAAAAD/AAYAAAABADAAAAAABAAAAQIAHKMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQEkBAAAAE0BAZsFAAAAnwACAqQBAQAAAABApAIDAAAAIEBNAgIkBAAAAE0CAtMGAAAAnwECAv8CAQAAAAAAwAMHABIAAAAwAwIHCAAAAIICAgAJAwoEAAAAQAMLBAAAIEADDAMNAw4GAwMJAQMBAAEYAAYAAAAAAAAAAAAAAQAAAAAAAAAADgAZAAAAIQEAAAAABH2oeYbG/loPGp5YfghelEcNsG7yT2wThw==

-- decompilation:
local Trove = require(script.Parent.Parent.Trove)

require(script.Parent.Streamable)

return {
	Compound = function(t1: {[any]: any}, p1: ((...any) -> ...any)) -- line: 47
		-- upvalues: Trove (copy)
		local v4 = Trove.new()
		local v5 = Trove.new()
		local u6 = false

		local function Check() -- line: 51
			-- upvalues: u6 (ref), t1 (copy), p1 (copy), v5 (copy)
			if u6 then
				return
			end

			for _, v in pairs(t1) do
				if not v.Instance then
					return
				end
			end

			u6 = true
			p1(t1, v5)
		end
		local function Cleanup() -- line: 63
			-- upvalues: u6 (ref), v5 (copy)
			if not u6 then
				return
			end

			u6 = false
			v5:Clean()
		end

		for _, v in pairs(t1) do
			v4:Add(v:Observe(function(_, p3) -- line: 71
				-- upvalues: u6 (ref), t1 (copy), p1 (copy), v5 (copy), Cleanup (copy)
				local g17

				if not u6 then
					g17 = nil

					for _, v2 in pairs(t1) do
						if not v2.Instance then
							g17 = true
						end

						if g17 then
							break
						end
					end

					if not g17 then
						u6 = true
						p1(t1, v5)
					end
				end

				g17 = false
				p3:Add(Cleanup)
			end))
		end

		v4:Add(Cleanup)

		return v4
	end
}

