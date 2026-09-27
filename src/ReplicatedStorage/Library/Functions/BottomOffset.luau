-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Bytecode (Base64):
-- CQMIC1ByaW1hcnlQYXJ0BFNpemUBWQhIdW1hbm9pZBVGaW5kRmlyc3RDaGlsZE9mQ2xhc3MJSGlwSGVpZ2h0BkNGcmFtZQNuZXcAAggBAAAAABmMAQAATQIAmwAAAAAOAgYATQQCLwIAAABNBAR4AwAAAD4DBAEmAQEDbwUEALwDALgFAAAAnwMDAg4DAwBNBAMXBgAAACYBAQSkBAkAACBwgIwFAABSBgEAjAcAAJ8EBACCBAAACgMBAgAAAAAAAABAAwIDAwMEAwUDBgMHAwgEACBwgAABAAEYAAEAAQEAAAAAAAIAAAABAQAAAgAAAAAAAAIAAAAAAQAAAQIAA6MAAADAAAAAggACAAEGAAEAAQABGAAAAAEAAAAAAbBstM70xe8MF62spkfIs/rAdKO6gqjezw==

-- decompilation:
return function(p1) -- line: 1
	local n1 = 0.0
	local PrimaryPart = p1.PrimaryPart

	if PrimaryPart then
		n1 -= PrimaryPart.Size.Y / 2.0
	end

	local Humanoid = p1:FindFirstChildOfClass("Humanoid")

	if Humanoid then
		n1 -= Humanoid.HipHeight
	end

	return CFrame.new(0.0, n1, 0.0)
end

