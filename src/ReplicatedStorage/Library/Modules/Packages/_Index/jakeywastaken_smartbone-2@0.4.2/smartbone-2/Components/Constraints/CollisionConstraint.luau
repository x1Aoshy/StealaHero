-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMJBlJhZGl1cw1HZXRDb2xsaXNpb25zCUdldE9iamVjdAV0YWJsZQZpbnNlcnQMQ2xvc2VzdFBvaW50Bk5vcm1hbA5Db2xsaXNpb25zRGF0YQ1Db2xsaXNpb25IaXRzAAITAwAAAAA8/wMAAAAAAAD/BAAAAAAAAFIFAgDGBgAAxgcAAGQFHwBSDAEATQ0AcQAAAAC8CglEAQAAAJ8KBAIcCwoAjAwAAGAMCQALAAAAUgwEALwNCfkCAAAAnw0CAEw0AAKkCwUAABAwgJ8LAAFSCwoAxgwAAMYNAABkCwcAnjQDBQ8AAABSEQMAUhIPAKQQBQAAEDCAnxADAW4L+P8CAAAAbgXg/wIAAABSBQMAxgYAAMYHAABkBQgATQoJYQYAAABNDAkQBwAAAE0NAHEAAAAACQsMDUMBCgtuBff/AgAAADADAKcIAAAAMAQAiQkAAACCAQIACgMBAwIDAwMEAwUEABAwgAMGAwcDCAMJAAEAARgAAAEAAgAAAAEAAAAAAAIAAAABAAAAAAAAAAMAAAABAAAAAAAA/wD5AAwAAAABAAAAAAAAAP8ABQABAAQEAAAAAAEAAAECAAOjAAAAwAAAAIIAAgABBgABAAEAARgAAAABAAAAAAFcEi7DvGLxSAEjL2piVR7ALAo5t27WRMI=

-- decompilation:
return function(p1, p2, p3) -- line: 1
	local t1 = {}
	local t2 = {}

	for _, v7 in p3 do
		local Collisions = v7:GetCollisions(p2, p1.Radius)

		if #Collisions > 0.0 then
			table.insert(t2, v7:GetObject())
		end

		for _, v10 in Collisions do
			table.insert(t1, v10)
		end
	end

	for _, v12 in t1 do
		p2 = v12.ClosestPoint + v12.Normal * p1.Radius
	end

	p1.CollisionsData = t1
	p1.CollisionHits = t2

	return p2
end

