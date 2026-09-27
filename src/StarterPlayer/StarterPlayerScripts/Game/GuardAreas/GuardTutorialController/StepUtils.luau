-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMLCkRpc2Nvbm5lY3QHQ2hhbmdlZAdDb25uZWN0BHRhc2sFZGVmZXIUQmluZE9uQWRhcHRlckNoYW5nZWQHcmVxdWlyZQZzY3JpcHQGUGFyZW50BVR5cGVzCUludGVyZmFjZQAFAgADAAAAB/sAAAD7AQEAnwACAg4AAgD7AAIAnwABAYIAAQAAABUAARgAAAAAAQACFgAAAAACAAMAAAAH+wAAAPsBAQCfAAICDgACAPsAAgCfAAEBggABAAAAGwABGAAAAAABAAIcAAAAAAIAAQAAAAX7AAAAvAAAGgAAAACfAAIBggABAAEDAQAhAAEYAAAAAAEiAAAAAAYDAAAACAUAAAUDDwUFE00DAIUAAAAA2QUAABIAAQASAAAAEgACALwDA8cBAAAAnwMDAqQEBAAADCCA2QUBABIAAQASAAAAEgACAJ8EAgHZBAIAEgADAIIEAgAFAwIDAwMEAwUEAAwggAMAAQIQBgEYAAAAAAAAAAAABgAAAAAAAAYAABUAAAAAAwAAAQIAEqMAAACkAAEAAAAAQKQBAwAAACBATQEBJAQAAABNAQHvBQAAAE0BAQ8GAAAAnwACAv8BAQAAAAAAwAIHADACAUcIAAAAggECAAkDBwQAAABAAwgEAAAgQAMJAwoDCwYDAwYBAwEAARgAAwAAAAAAAAAAAAAGAAYAABYBAAAAAARMtO1+hPkbT/Sno1/6/I2uPKz6Cn5wh38=

-- decompilation:
require(script.Parent.Types.Interface)

return {
	BindOnAdapterChanged = function(p1, p2: ((...any) -> ...any), p3: ((...any) -> ...any)) -- line: 16
		local connection = p1.Changed:Connect(function() -- line: 21
			-- upvalues: p2 (copy), p1 (copy), p3 (copy)
			if p2(p1) then
				p3()
			end
		end)

		task.defer(function() -- line: 27
			-- upvalues: p2 (copy), p1 (copy), p3 (copy)
			if p2(p1) then
				p3()
			end
		end)

		return function() -- line: 33
			-- upvalues: connection (copy)
			connection:Disconnect()
		end
	end
}

