-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMNBmJ1ZmZlcgdyZWFkdTE2BXRhYmxlBmNyZWF0ZQRyZWFkBXdyaXRlB3JlcXVpcmUGc2NyaXB0BlBhcmVudAdwcm9jZXNzDGJ1ZmZlcldyaXRlcgV0eXBlcwh3cml0ZXUxNgAECwIBAAAHBAAABQIJAhqeRQAFAQAAAFIDAABSBAEApAICAAAEAICfAgMClQMBA6QEBgAAFECAUgUCAJ8EAgKMBwEAUgUCAIwGAQCoBQcA+wgAAFIJAABSCgMAnwgDA2oIBAdDAwMJiwX5/1IFBAAmBgMBggUDAAcDAQMCBAAEAIACAAAAAAAAAEADAwMEBAAUQIAADwUBGAAAAAAAAAABAgAAAAIAAAABAAAAAQL8BwAAEAAAAAAHAQIAAAANHAEAAPsCAABSAwEAnwICAYwEAQBSAgEAjAMBAKgCBAD7BQEAhwYABJ8FAgGLAvz/ggABAAAAHgYBGAABAAADAAAAAQAA/wMfAAAAAAUBAQAAAA9NAQDSAAAAAE0CAHkBAAAA4gMCANkEAAASAAIAMAQDeQEAAADZBAEAEgIAABIAAQAwBAPSAAAAAIIDAgADAwYDBQUCAQACAAEKAAEYAAABAAIBAAAADwAAAAAACwAAAAAEAAABAgAeowAAAKQAAQAAAABApAEDAAAAIEBNAQEkBAAAAE0BASQEAAAATQEB6wUAAABNAQHeBgAAAJ8AAgKkAQEAAAAAQKQCAwAAACBATQICJAQAAABNAgIkBAAAAE0CAg8HAAAAnwECAk0CAG8IAAAAwAMJABIAAgCCAwIACgMHBAAAAEADCAQAACBAAwkDCgMLAwwDDQYCAQIBAAEYAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAIABQAAAQAAAAADoNaCOW994nHZVipkV7cl9tDOlU2SEug4

-- decompilation:
local bufferWriter = require(script.Parent.Parent.process.bufferWriter)

require(script.Parent.Parent.types)

local writeu16 = bufferWriter.writeu16

return function(p1) -- line: 10
	-- upvalues: writeu16 (copy)
	local write = p1.write
	local read = p1.read

	return {
		read = function(p2: buffer, n1: number) -- line: 15
			-- upvalues: read (copy)
			local v8 = buffer.readu16(p2, n1)
			local v9 = n1 + 2.0
			local t1 = table.create(v8)

			for i = 1.0, v8 do
				local v12, v13 = read(p2, v9)

				t1[i] = v12
				v9 += v13
			end

			return t1, v9 - n1
		end,
		write = function(p3) -- line: 30
			-- upvalues: writeu16 (copy), write (copy)
			local v15 = #p3

			writeu16(v15)

			for i = 1.0, v15 do
				write(p3[i])
			end
		end
	}
end

